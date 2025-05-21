
-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("Mineunit assert", function()

	require("mineunit")
	mineunit:config_set("silence_global_export_overrides", true)
	sourcefile("player")
	sourcefile("itemstack")
	sourcefile("metadata")

	-- Player

	describe("is_Player", function()
		it("rejects table",           function() assert.error(function() assert.is_Player( {}   )end)end)
		it("rejects string",          function() assert.error(function() assert.is_Player( "SX" )end)end)
		it("rejects empty arguments", function() assert.error(function() assert.is_Player(      )end)end)
		it("rejects nil",             function() assert.error(function() assert.is_Player( nil  )end)end)
		it("accepts Player",          function() assert.is_Player(Player()) end)
	end)

	describe("not_Player", function()
		it("accepts table",           function() assert.not_Player( {}   )end)
		it("accepts string",          function() assert.not_Player( "SX" )end)
		it("accepts empty arguments", function() assert.not_Player(      )end)
		it("accepts nil",             function() assert.not_Player( nil  )end)
		it("rejects Player",          function() assert.error(function() assert.not_Player(Player()) end)end)
	end)

	-- ItemStack

	describe("is_ItemStack", function()
		it("rejects table",           function() assert.error(function() assert.is_ItemStack( {}   )end)end)
		it("rejects string",          function() assert.error(function() assert.is_ItemStack( "SX" )end)end)
		it("rejects empty arguments", function() assert.error(function() assert.is_ItemStack(      )end)end)
		it("rejects nil",             function() assert.error(function() assert.is_ItemStack( nil  )end)end)
		it("accepts ItemStack",       function() assert.is_ItemStack(ItemStack(nil)) end)
	end)

	-- InvRef

	describe("is_InvRef", function()
		it("rejects table",           function() assert.error(function() assert.is_InvRef( {}   )end)end)
		it("rejects string",          function() assert.error(function() assert.is_InvRef( "SX" )end)end)
		it("rejects empty arguments", function() assert.error(function() assert.is_InvRef(      )end)end)
		it("rejects nil",             function() assert.error(function() assert.is_InvRef( nil  )end)end)
		it("accepts InvRef",          function() assert.is_InvRef(InvRef()) end)
	end)

	-- MetaDataRef

	describe("is_MetaDataRef", function()
		it("rejects table",           function() assert.error(function() assert.is_MetaDataRef( {}       )end)end)
		it("rejects string",          function() assert.error(function() assert.is_MetaDataRef( "SX"     )end)end)
		it("rejects empty arguments", function() assert.error(function() assert.is_MetaDataRef(          )end)end)
		it("rejects nil",             function() assert.error(function() assert.is_MetaDataRef( nil      )end)end)
		it("rejects InvRef",          function() assert.error(function() assert.is_MetaDataRef( InvRef() )end)end)
		it("accepts MetaDataRef",     function() assert.is_MetaDataRef(MetaDataRef()) end)
	end)

	-- NodeMetaRef

	describe("is_NodeMetaRef", function()
		it("rejects table",           function() assert.error(function() assert.is_NodeMetaRef( {}       )end)end)
		it("rejects string",          function() assert.error(function() assert.is_NodeMetaRef( "SX"     )end)end)
		it("rejects empty arguments", function() assert.error(function() assert.is_NodeMetaRef(          )end)end)
		it("rejects nil",             function() assert.error(function() assert.is_NodeMetaRef( nil      )end)end)
		it("rejects InvRef",          function() assert.error(function() assert.is_NodeMetaRef( InvRef() )end)end)
		it("accepts NodeMetaRef",     function() assert.is_NodeMetaRef( NodeMetaRef() )end)
	end)

	describe("not_NodeMetaRef", function()
		it("accepts table",           function() assert.not_NodeMetaRef( {}       )end)
		it("accepts string",          function() assert.not_NodeMetaRef( "SX"     )end)
		it("accepts empty arguments", function() assert.not_NodeMetaRef(          )end)
		it("accepts nil",             function() assert.not_NodeMetaRef( nil      )end)
		it("accepts InvRef",          function() assert.not_NodeMetaRef( InvRef() )end)
		it("rejects NodeMetaRef",     function() assert.error(function() assert.not_NodeMetaRef(NodeMetaRef())end)end)
	end)

	-- Correct type

	describe("type override", function()
		it("returns Player as userdata",    function() assert.equals("userdata", type( Player()       ))end)
		it("returns ItemStack as userdata", function() assert.equals("userdata", type( ItemStack(nil) ))end)
		it("returns InvRef as userdata",    function() assert.equals("userdata", type( InvRef()       ))end)
		it("returns InvList as table", function()
			local inv = InvRef()
			inv:set_size("mylist", 1)
			assert.equals("table", type(inv:get_list("mylist")))
		end)
	end)

	-- Greter than / less than

	describe("gt/lt", function()
		-- Passing tests
		it("2 > 1 is true",  function() assert.gt(      2,  1 )end)
		it("2 > -1 is true", function() assert.gt(      2, -1 )end)
		it("1 > 2 is false", function() assert.not_gt(  1,  2 )end)
		it("2 > 2 is false", function() assert.not_gt(  2,  2 )end)
		it("1 < 2 is true",  function() assert.lt(      1,  2 )end)
		it("-1 < 2 is true", function() assert.lt(     -1,  2 )end)
		it("3 < 2 is false", function() assert.not_lt(  3,  2 )end)
		it("2 < 2 is false", function() assert.not_lt(  2,  2 )end)
		-- Failing tests
		it("fails 1 > 2 is true",  function() assert.error(function() assert.gt(      1,  2 )end)end)
		it("fails -1 > 2 is true", function() assert.error(function() assert.gt(     -1,  2 )end)end)
		it("fails 2 > 1 is false", function() assert.error(function() assert.not_gt(  2,  1 )end)end)
		it("fails 2 > 2 is true",  function() assert.error(function() assert.gt(      2,  2 )end)end)
		it("fails 2 < 1 is true",  function() assert.error(function() assert.lt(      2,  1 )end)end)
		it("fails 2 < -1 is true", function() assert.error(function() assert.lt(      2, -1 )end)end)
		it("fails 2 < 3 is false", function() assert.error(function() assert.not_lt(  2,  3 )end)end)
		it("fails 2 < 2 is true",  function() assert.error(function() assert.lt(      2,  2 )end)end)
		-- Failure message
		it("has expected error message", function()
			assert.error_matches(function()
				assert.lt(2, 2, "there was a problem")
			end, "there was a problem")
		end)
	end)

	-- table

	describe("not_table", function()
		it("rejects table",           function() assert.error(function() assert.not_table( {} )end)end)
		it("accepts string",          function() assert.not_table( "SX"     )end)
		it("accepts empty arguments", function() assert.not_table(          )end)
		it("accepts nil",             function() assert.not_table( nil      )end)
		-- Failure message
		it("has expected error message", function()
			assert.error_matches(function()
				assert.not_table({}, "there was a problem")
			end, "there was a problem")
		end)
	end)

	-- indexed table

	describe("not_indexed", function()
		it("rejects empty table",     function() assert.error(function() assert.not_indexed( {}    )end)end)
		it("rejects indexed table",   function() assert.error(function() assert.not_indexed( { 1 } )end)end)
		it("accepts hash table",      function() assert.not_indexed( { a = 1 } )end)
		it("accepts string",          function() assert.not_indexed( "SX"      )end)
		it("accepts empty arguments", function() assert.not_indexed(           )end)
		it("accepts nil",             function() assert.not_indexed( nil       )end)
	end)

	-- hash table

	describe("not_hashed", function()
		it("rejects hash table",      function() assert.error(function() assert.not_hashed( { a = 1 } )end)end)
		it("accepts empty table",     function() assert.not_hashed( {}    )end)
		it("accepts indexed table",   function() assert.not_hashed( { 1 } )end)
		it("accepts string",          function() assert.not_hashed( "SX"  )end)
		it("accepts empty arguments", function() assert.not_hashed(       )end)
		it("accepts nil",             function() assert.not_hashed( nil   )end)
	end)

	-- integer

	describe("not_integer", function()
		it("rejects integer",         function() assert.error(function() assert.not_integer( 2 )end)end)
		it("accepts float",           function() assert.not_integer( 1.2      )end)
		it("accepts table",           function() assert.not_integer( {}       )end)
		it("accepts string",          function() assert.not_integer( "SX"     )end)
		it("accepts empty arguments", function() assert.not_integer(          )end)
		it("accepts nil",             function() assert.not_integer( nil      )end)
	end)

	-- in_array

	describe("not_in_array", function()
		it("accepts table",         function() assert.not_in_array( {}  , {} )end)
		it("accepts string",        function() assert.not_in_array( "SX", {} )end)
		it("accepts nil",           function() assert.not_in_array( nil , {} )end)
		it("fails empty arguments", function() assert.error(function() assert.not_in_array() end)end)
		-- Failures
		it("fails invalid second argument with nil", function()
			assert.error_matches(function()
				assert.not_in_array({}, nil)
			end, "second argument.*got nil")
		end)
		it("fails invalid second argument", function()
			assert.error_matches(function()
				assert.not_in_array({}, "")
			end, "second argument.*got string")
		end)
		-- Failure message
		it("has expected error message", function()
			assert.error_matches(function()
				assert.not_in_array("", {""}, "there was a problem")
			end, "there was a problem")
		end)
	end)

end)
