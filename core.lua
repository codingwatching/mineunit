local noop = mineunit.utils.noop
local noop_object = {
	__call = function(self) return self end,
	__index = function() return noop end,
}
local engine_version = mineunit:config("engine_version")
local engine_version_minor = tonumber(engine_version:sub(3,3)) or -1

mineunit("craft")
mineunit("world")

_G.core.notify_authentication_modified = noop

_G.core.set_node = world.set_node
_G.core.add_node = world.set_node
_G.core.swap_node = world.swap_node

_G.core.get_translator = function(...) return function(...) mineunit:debug(...) end end
_G.core.set_http_api_lua = noop
_G.core.inventorycube = function(img1, img2, img3)
	img2 = img2 or img1
	img3 = img3 or img1
	return "[inventorycube"
			.. "{" .. img1:gsub("%^", "&")
			.. "{" .. img2:gsub("%^", "&")
			.. "{" .. img3:gsub("%^", "&")
end
_G.minetest = _G.core

mineunit("settings")
_G.core.settings = _G.Settings(fixture_path("minetest.conf"))
mineunit:apply_default_settings(_G.core.settings)

_G.core.register_on_joinplayer = noop
_G.core.register_on_leaveplayer = noop

_G.core.register_on_player_receive_fields = noop

mineunit("game/constants")
mineunit("common/vector")
mineunit("game/item")
if engine_version_minor > 5 then
	mineunit("game/misc_s")
end
mineunit("game/misc")
mineunit("game/register")
mineunit("common/misc_helpers")
mineunit("game/privileges")
mineunit("game/features")
mineunit("common/serialize")
mineunit("fs")

assert(core.registered_nodes["air"])
assert(core.registered_nodes["ignore"])
assert(core.registered_items[""])
assert(core.registered_items["unknown"])

mineunit("metadata")
mineunit("itemstack")

local mod_storage = {}
_G.core.get_mod_storage = function()
	local modname = core.get_current_modname()
	if not mod_storage[modname] then
		mineunit:debugf("Initializing mod storage for %s", modname)
		mod_storage[modname] = MetaDataRef()
	end
	return mod_storage[modname]
end

-- Detached inventories
local inv_storage = {}
_G.core.get_inventory = function(where)
	assert.is_hashed(where)
	assert.is_string(where.name)
	if where.type == "detached" then
		return inv_storage[where.name]
	elseif where.type == "node" then
		assert.is_coordinate(where.pos)
		local meta = core.get_meta(where.pos)
		return meta and meta:get_inventory() or nil
	elseif where.type == "player" then
		local player = core.get_player_by_name(where.name)
		return player and player:get_inventory() or nil
	end
	error("core.get_inventory(): Invalid inventory type")
end
_G.core.create_detached_inventory = function(name, callbacks, player_name)
	assert.is_string(name)
	mineunit:debugf("Initializing detached inventory '%s'", name)
	if player_name then
		mineunit:warningf("core.create_detached_inventory(...): ignored player name '%s'", player_name)
	end
	inv_storage[name] = InvRef()
	return inv_storage[name]
end
_G.core.remove_detached_inventory = function(name)
	assert.is_string(name)
	if inv_storage[name] then
		inv_storage[name] = nil
		return true
	end
	return false
end

_G.core.sound_play = noop
_G.core.sound_stop = noop
_G.core.sound_fade = noop
_G.core.add_particlespawner = noop

_G.core.registered_chatcommands = {}
_G.core.register_chatcommand = noop
_G.core.chat_send_player = function(...) print(unpack({...})) end
_G.core.chat_send_all = function(...) print(unpack({...})) end
_G.core.register_on_placenode = noop
_G.core.register_on_dignode = noop
_G.core.register_on_mods_loaded = function(func) mineunit:register_on_mods_loaded(func) end

_G.core.item_drop = noop
_G.core.add_item = noop
_G.core.check_for_falling = noop
_G.core.get_objects_inside_radius = function(...) return {} end

_G.core.register_biome = noop
_G.core.clear_registered_biomes = function(...) error("MINEUNIT UNSUPPORTED CORE METHOD") end
_G.core.register_ore = noop
_G.core.clear_registered_ores = function(...) error("MINEUNIT UNSUPPORTED CORE METHOD") end
_G.core.register_decoration = noop
_G.core.clear_registered_decorations = function(...) error("MINEUNIT UNSUPPORTED CORE METHOD") end

do
	local time_step = tonumber(mineunit:config("time_step"))
	assert(time_step, "Invalid configuration value for time_step. Number expected.")
	if time_step < 0 then
		mineunit:info("Running default core.get_us_time using real world wall clock.")
		_G.core.get_us_time = function()
			local socket = require 'socket'
			-- FIXME: Returns the time in seconds, relative to the origin of the universe.
			return socket.gettime() * 1000 * 1000
		end
	else
		mineunit:info("Running custom core.get_us_time with step increment: "..tostring(time_step))
		local time_now = 0
		_G.core.get_us_time = function()
			time_now = time_now + time_step
			return time_now
		end
	end
end

_G.core.after = noop

_G.core.find_nodes_with_meta = _G.world.find_nodes_with_meta
_G.core.find_nodes_in_area = _G.world.find_nodes_in_area
_G.core.get_node_or_nil = _G.world.get_node
_G.core.get_node = function(pos) return core.get_node_or_nil(pos) or {name="ignore",param1=0,param2=0} end
_G.core.dig_node = function(pos) return world.on_dig(pos) and true or false end
_G.core.remove_node = _G.world.remove_node
_G.core.load_area = noop

_G.core.get_node_timer = {}
setmetatable(_G.core.get_node_timer, noop_object)

local content_name2id = {}
local content_id2name = {}
_G.core.get_content_id = function(name)
	-- check if the node exists
	assert(core.registered_nodes[name], "node " .. name .. " is not registered")

	-- create and increment
	if not content_name2id[name] then
		content_name2id[name] = #content_id2name
		table.insert(content_id2name, name)
	end
	return content_name2id[name]
end

_G.core.get_name_from_content_id = function(cid)
	assert(content_id2name[cid+1], "Unknown content id")
	return content_id2name[cid+1]
end

--
-- Minetest default noop table
-- FIXME: default should not be here, it should be separate file and not loaded with core
--
_G.default = {
	LIGHT_MAX = 14,
	get_translator = string.format,
}
setmetatable(_G.default, noop_object)
