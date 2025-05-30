
-- Simple mesecons fixture that allows many node registrations requiring mesecons

mineunit:set_modpath("mesecons", "spec/fixtures")
mineunit:set_modpath("mesecons_mvps", "spec/fixtures")

_G.mesecon = setmetatable(
	-- mesecon data and functions
	{
		state = {},
		rules = {
			default = {
				{x =  0, y =  0, z = -1},
				{x =  1, y =  0, z =  0},
				{x = -1, y =  0, z =  0},
				{x =  0, y =  0, z =  1},
				{x =  1, y =  1, z =  0},
				{x =  1, y = -1, z =  0},
				{x = -1, y =  1, z =  0},
				{x = -1, y = -1, z =  0},
				{x =  0, y =  1, z =  1},
				{x =  0, y = -1, z =  1},
				{x =  0, y =  1, z = -1},
				{x =  0, y = -1, z = -1},
			}
		}
	},
	-- mesecon metatable
	{
	__call = function(self,...) return self end,
	__index = function(...) return function(...)end end,
	}
)