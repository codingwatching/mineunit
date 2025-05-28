
mineunit("core")

local protected_nodes = {}

function mineunit:protect(pos, name_or_player)
	assert(type(name_or_player) == "string" or type(name_or_player) == "userdata",
		"mineunit:protect name_or_player should be string or userdata")
	local name = type(name_or_player) == "userdata" and name_or_player:get_player_name() or name_or_player
	protected_nodes[core.hash_node_position(pos)] = name
end

core.is_protected = function(pos, name)
	local nodeid = core.hash_node_position(pos)
	if protected_nodes[nodeid] == nil or protected_nodes[nodeid] == name then
		return false
	end
	return true
end

core.record_protection_violation = function(...)
	print("core.record_protection_violation", ...)
end
