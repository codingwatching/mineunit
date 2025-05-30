-- FIXME: Sorry, not exactly nice in its current state
-- Have extra time and energy? Feel free to clean it a bit

local pl = {
	path = require 'pl.path',
	--dir = require 'pl.dir',
}

local lua_dofile = dofile
function _G.dofile(path, ...)
	return lua_dofile(pl.path.normpath(path), ...)
end

local default_config = {
	verbose = 2,
	print = true,
	modname = "mineunit",
	root = ".",
	mineunit_path = debug.getinfo(1).source:match("@?(.*)/"),
	spec_path = "spec",
	fixture_paths = {
		"spec/fixtures"
	},
	source_path = ".",
	time_step = -1,
	engine_version = "mineunit",
	deprecated = "throw",
	deprecated_mineunit = "error",
	singleplayer = true
}

mineunit = mineunit or {}
local mineunit_conf_override = rawget(mineunit, "mineunit_conf_override") or {}
for k,v in pairs(rawget(mineunit, "mineunit_conf_defaults") or {}) do
	default_config[k] = v
end
rawset(mineunit, "mineunit_conf_defaults", nil)

mineunit._config = {
	modpaths = {},
}
mineunit._on_mods_loaded = {}
mineunit._on_mods_loaded_exec_count = 0

local tagged_paths = {
	["common"] = true,
	["game"] = true
}

require("mineunit.print")
require("mineunit.globals")

local function require_mineunit(name, root, tag)
	mineunit:debugf("Loading mineunit module %s", name)
	local modulename = name:gsub("/", ".")
	if root and tag and tag ~= "mineunit" then
		local path = name:match("^([^/]+)/")
		if path and tagged_paths[path] then
			local oldpath = package.path
			local module
			package.path = root.."/"..tag.."/?.lua;"
			mineunit:debugf("Loading %s from %s", name, tag)
			local success, err = pcall(function() module = require(modulename) end)
			package.path = oldpath
			if success then
				mineunit:debugf("Loaded %s from %s", name, tag)
				return module
			else
				mineunit:debug(err)
				mineunit:errorf("Loading %s from %s failed, trying builtin", name, tag)
			end
		end
	end
	return require("mineunit." .. modulename)
end

mineunit.__index = mineunit
local _mineunits = {}
setmetatable(mineunit, {
	__call = function(self, name)
		if _mineunits[name] == nil then
			_mineunits[name] = {require_mineunit(name, mineunit:config("core_root"), mineunit:config("engine_version"))}
		end
		return unpack(_mineunits[name])
	end,
})

function mineunit:has_module(name)
	return _mineunits[name] and true
end

function mineunit:config_set(key, value)
	self:debugf("Updating configuration '%s' from '%s' to '%s'", key, self._config[key], value)
	self._config[key] = value
end

function mineunit:config(key)
	if self._config[key] ~= nil then
		return self._config[key]
	end
	return default_config[key]
end

mineunit._config.source_path = pl.path.normpath(
	("%s/%s"):format(mineunit:config("root"), mineunit:config("source_path"))
)

function mineunit:set_modpath(name, path)
	path = pl.path.normpath(path)
	mineunit:infof("Setting modpath of '%s' to '%s'", name, path)
	self._config.modpaths[name] = path
end

function mineunit:get_modpath(name)
	return self._config.modpaths[name]
end

function mineunit:get_current_modname()
	return self:config("modname")
end

function mineunit:set_current_modname(name)
	self._config.modname = name
end

function mineunit:restore_current_modname()
	self._config.modname = self:config("original_modname")
end

function mineunit:get_worldpath()
	return self:config("fixture_paths")[1]
end

function mineunit:register_on_mods_loaded(func)
	if self._on_mods_loaded_exec_count > 0 then
		mineunit:warning("mineunit:register_on_mods_loaded: Registering after registered_on_mods_loaded executed")
	end
	assert(type(func) == "function", "register_on_mods_loaded requires function, got "..type(func))
	table.insert(self._on_mods_loaded, func)
end

function mineunit:mods_loaded()
	if self._on_mods_loaded then
		mineunit:info("Executing register_on_mods_loaded functions")
		if self._on_mods_loaded_exec_count > 0 then
			mineunit:warningf("mineunit:mods_loaded: Callbacks already executed %d times", self._on_mods_loaded_exec_count)
		end
		if core.registered_on_mods_loaded then
			for index, func in ipairs(core.registered_on_mods_loaded) do
				if self._on_mods_loaded[index] ~= func then
					mineunit:warning("Unsupported registration overrides detected for core.registered_on_mods_loaded")
					local swap_index = mineunit.utils.in_array(self._on_mods_loaded, func)
					if swap_index then
						self._on_mods_loaded[swap_index], self._on_mods_loaded[index] =
							self._on_mods_loaded[index], self._on_mods_loaded[swap_index]
					else
						table.insert(self._on_mods_loaded, index, func)
					end
				end
			end
		end
		for _,func in ipairs(self._on_mods_loaded) do func() end
		self._on_mods_loaded_exec_count = self._on_mods_loaded_exec_count + 1
	end
end

local function spec_path(name)
	local path = pl.path.normpath(("%s/%s/%s"):format(mineunit:config("root"), mineunit:config("spec_path"), name))
	if pl.path.isfile(path) then
		mineunit:debugf("spec_path('%s') -> '%s'", name, path)
		return path
	end
	mineunit:debugf("spec_path, file not found: '%s'", path)
end

function fixture_path(name)
	local index = name:find(mineunit:get_worldpath(), nil, true)
	if index then
		-- Remove worldpath from name, worldpath should be in search_paths.
		-- This is to allow using search_paths when mod creates Settings object from worldpath.
		name = name:sub(1, index - 1) .. name:sub(index + #mineunit:get_worldpath())
	end
	local root = mineunit:config("root")
	local search_paths = mineunit:config("fixture_paths")
	for _,search_path in ipairs(search_paths) do
		local path = pl.path.normpath(("%s/%s/%s"):format(root, search_path, name))
		if pl.path.isfile(path) then
			return path
		else
			mineunit:debugf("fixture_path, file not found: '%s'", path)
		end
	end
	local path = pl.path.normpath(("%s/%s/%s"):format(root, search_paths[1], name))
	mineunit:infof("File not found: '%s'", path)
	return path
end

local _fixtures = {}
function fixture(name)
	local path = fixture_path(name .. ".lua")
	if not _fixtures[name] then
		mineunit:infof("Loading fixture %s", path)
		assert(pl.path.isfile(path), "Fixture not found: " .. path)
		local result = {dofile(path)}
		_fixtures[name] = result
		return unpack(result)
	else
		mineunit:debugf("Fixture already loaded: %s", path)
		return unpack(_fixtures[name])
	end
end

local function source_path(name)
	local cfg_source_path = mineunit:config("source_path")
	local path = pl.path.normpath(("%s/%s"):format(cfg_source_path, name))
	mineunit:debugf("source_path('%s') -> '%s'", name, path)
	return path
end

function sourcefile(name)
	local path = source_path(name .. ".lua")
	mineunit:infof("Loading source %s", path)
	assert(pl.path.isfile(path), "Source file not found: " .. path)
	return dofile(path)
end

local function DEPRECATED(instance, action, msg)
	if action == "ignore" then
		return
	elseif action == "throw" then
		error(msg or "Attempted to use deprecated method")
	elseif ({debug=1,info=1,warning=1,error=1})[action] then
		instance[action](instance, msg or "Calling deprecated engine method")
	else
		error("Config: invalid value for 'deprecated'. Allowed values: throw, error, warning, info, debug, ignore.")
	end
end

function mineunit:DEPRECATED(msg)
	return DEPRECATED(self, self:config("deprecated"), msg)
end

function mineunit.export_object(obj, def)
	if not def.private and _G[def.name] ~= nil and not mineunit:config("silence_global_export_overrides") then
		mineunit:errorf("mineunit.export_object overriding already reserved global name: %s", (def.name or "?"))
	end
	if not obj.__index then
		obj.__index = obj
	end
	setmetatable(obj, {
		__call = function(...)
			local ins = def.constructor(...)
			ins._mineunit_typename = def.typename or def.name
			return ins
		end
	})
	if not def.private then
		_G[def.name] = obj
	end
end

local sequential = mineunit.utils.sequential

function mineunit.deep_merge(data, target, defaults)
	if sequential(data) and #data > 0 then
		assert(sequential(defaults), "Configuration: attempt to merge indexed table with hash table")
		-- Indexed arrays merge strategy: discard keys, add unique values
		local seen = {}
		for _,value in ipairs(defaults) do
			table.insert(target, value)
			seen[value] = true
		end
		for _,value in ipairs(data) do
			assert(type(value) ~= "table", "Configuration: tables not supported in indexed arrays")
			if not seen[value] then
				table.insert(target, value)
				mineunit:debugf("\t%d\t=\t'%s'", #target, value)
			else
				mineunit:debugf("\tSkipping duplicate value: %s", value)
			end
		end
	else
		-- Hash tables merge strategy: preserve keys, override values
		for key,value in pairs(data) do
			if defaults[key] then
				assert(type(value) == type(defaults[key]), "Configuration: invalid data type for key", key)
				if type(value) == "table" then
					target[key] = {}
					mineunit:debugf("Configuration: merging indexed array at '%s'", key)
					mineunit.deep_merge(value, target[key], defaults[key])
				else
					target[key] = value
				end
				mineunit:debugf("Configuration: '%s' = '%s'", key, value)
			elseif key ~= "exclude" then
				-- Excluding "exclude" is hack and on todo list, mineunit cli runner uses this configuration key
				mineunit:warningf("Configuration: invalid key '%s'", key)
			end
		end
	end
end

do -- Read mineunit config file
	local configpath = spec_path("mineunit.conf")
	if not configpath then
		mineunit:infof("configpath, file not found: '%s'", configpath)
	end
	if configpath then
		local configfile, err = loadfile(configpath)
		if configfile then
			local configenv = {}
			setfenv(configfile, configenv)
			configfile()
			mineunit.deep_merge(configenv, mineunit._config, default_config)
			-- Override config
			if mineunit_conf_override then
				for k, v in pairs(mineunit_conf_override) do
					mineunit._config[k] = v
				end
			end
			mineunit:infof("Mineunit configuration loaded from '%s'", configpath)
		else
			mineunit:warningf("Mineunit configuration failed: %s", err)
		end
	else
		mineunit:warning("Mineunit configuration file not found")
	end
end

do -- Read mod.conf config file
	local modconfpath = source_path("mod.conf")
	if not modconfpath then
		mineunit:infof("mod.conf not found: '%s'", modconfpath)
		return
	end
	local configfile = io.open(modconfpath, "r")
	if configfile then
		for line in configfile:lines() do
			local key, value = string.gmatch(line, "([^=%s]+)%s*=%s*(.-)%s*$")()
			if key == "name" then
				if mineunit._config["modname"] then
					mineunit:warning("Mod name defined in both mod.conf and mineunit.conf, using mineunit.conf")
				else
					mineunit._config["modname"] = value
				end
			end
		end
		mineunit:infof("Mod configuration loaded from '%s'", modconfpath)
	else
		mineunit:warning("Loading file mod.conf failed")
	end
end

-- Save original modname and set modpath
mineunit._config["original_modname"] = mineunit:config("modname")
mineunit:set_modpath(mineunit:config("modname"), mineunit:config("root"))

mineunit("deprecation")(function(msg)
	return DEPRECATED(mineunit, mineunit:config("deprecated_mineunit"), msg)
end)

mineunit:infof("Mineunit initialized, current modname is %s", mineunit:get_current_modname())
