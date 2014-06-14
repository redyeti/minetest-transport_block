
-- Non-sticky:
-- Moves in indicated direction
-- Pushes all blocks in front of it
--
-- Sticky one
-- Moves in indicated direction
-- Pushes all block in front of it
-- Pull all blocks in its back

local function get_transport_block_direction(pos)
	local node = minetest.get_node(pos)
	return minetest.facedir_to_dir(node.param2)
end

minetest.register_node("transport_block:transport_block", {
	tiles = {"transport_block_arrows.png^[transformR90", "transport_block_arrows.png^[transformR270", "transport_block_arrows.png", "transport_block_arrows.png^[transformR180", "transport_block_side.png", "transport_block_side.png"},
	paramtype2 = "facedir",
	legacy_facedir_simple = true,
	groups = {cracky=3},
    	description="Transport Block",
	sounds = default.node_sound_stone_defaults(),
	mesecons = {effector = {
		action_on = function (pos, node)
			local direction=get_transport_block_direction(pos)
			if not direction then return end
			minetest.remove_node(pos)
			mesecon:update_autoconnect(pos)
			local ent = minetest.add_entity(pos, "transport_block:transport_block_entity")
			print("Nodedir: "..dump(direction))
			ent:get_luaentity().direction = direction
		end
	}}
})

minetest.register_entity("transport_block:transport_block_entity", {
	physical = false,
	visual = "sprite",
	textures = {"transport_block_arrows.png^[transformR90", "transport_block_arrows.png^[transformR270", "transport_block_arrows.png", "transport_block_arrows.png^[transformR180", "transport_block_side.png", "transport_block_side.png"},
	collisionbox = {-0.5,-0.5,-0.5, 0.5, 0.5, 0.5},
	visual = "cube",
	lastdir = {x=0, y=0, z=0},
	lastpos = nil,

	on_punch = function(self, hitter)
		self.object:remove()
		hitter:get_inventory():add_item("main", "transport_block:transport_block")
	end,

	on_step = function(self, dtime)
		local pos = self.object:getpos()

		if self.lastpos == nil then
			self.lastpos =  {x=pos.x, y=pos.y, z=pos.z}
		end

		local finished = false
		if math.abs(self.lastpos.x - pos.x) + math.abs(self.lastpos.y - pos.y) + math.abs(self.lastpos.z - pos.z) >= 1 then
			finished = true
		end

		pos.x, pos.y, pos.z = math.floor(pos.x+0.5), math.floor(pos.y+0.5), math.floor(pos.z+0.5)
		local direction = self.direction

		print("entdir: "..dump(direction))

		if finished then -- no mesecon power
			--push only solid nodes
			local name = minetest.get_node(pos).name
			if  name ~= "air" and name ~= "ignore"
			and ((not minetest.registered_nodes[name])
			or minetest.registered_nodes[name].liquidtype == "none") then
				mesecon:mvps_push(pos, direction, MOVESTONE_MAXIMUM_PUSH)
			end
			minetest.add_node(pos, {name="transport_block:transport_block", param2=minetest.dir_to_facedir(self.direction, true)})
			self.object:remove()
			return
		end

		local success, stack, oldstack =
			mesecon:mvps_push(pos, direction, MOVESTONE_MAXIMUM_PUSH)
		if finished or not success then -- Too large stack/stopper in the way
			minetest.add_node(pos, {name="transport_block:transport_block", param2=minetest.dir_to_facedir(self.direction, true)})
			self.object:remove()
			return
		else
			mesecon:mvps_process_stack (stack)
			mesecon:mvps_move_objects  (pos, direction, oldstack)
			self.lastdir = direction
		end

		self.object:setvelocity({x=direction.x*2, y=direction.y*2, z=direction.z*2})
	end,
})

minetest.register_craft({
	output = "transport_block:transport_block 2",
	recipe = {
		{"moreores:tin_ingot", "moreores:tin_ingot", "moreores:tin_ingot"},
		{"group:mesecon_conductor_craftable", "group:mesecon_conductor_craftable", "group:mesecon_conductor_craftable"},
		{"moreores:tin_ingot", "moreores:tin_ingot", "moreores:tin_ingot"},
	}
})



-- STICKY_MOVESTONE

minetest.register_node("transport_block:sticky_transport_block", {
	tiles = {"sticky_transport_block.png^[transformR90", "sticky_transport_block.png^[transformR270", "sticky_transport_block.png", "sticky_transport_block.png^[transformR180", "transport_block_side.png", "transport_block_side.png"},
	paramtype2 = "facedir",
	legacy_facedir_simple = true,
	groups = {cracky=3},
    	description="Sticky Transport Block",
	sounds = default.node_sound_stone_defaults(),
	mesecons = {effector = {
		action_on = function (pos, node)
			local direction=get_transport_block_direction(pos)
			if not direction then return end
			minetest.remove_node(pos)
			mesecon:update_autoconnect(pos)
			local ent = minetest.add_entity(pos, "transport_block:sticky_transport_block_entity")
			ent:get_luaentity().direction = direction
		end
	}}
})

minetest.register_craft({
	output = "transport_block:sticky_transport_block 2",
	recipe = {
		{"mesecons_materials:glue", "transport_block:transport_block", "mesecons_materials:glue"},
	}
})

minetest.register_entity("transport_block:sticky_transport_block_entity", {
	physical = false,
	visual = "sprite",
	textures = {"sticky_transport_block.png^[transformR90", "sticky_transport_block.png^[transformR270", "sticky_transport_block.png", "sticky_transport_block.png^[transformR180", "transport_block_side.png", "transport_block_side.png"},
	collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
	visual = "cube",
	lastdir = {x=0, y=0, z=0},

	on_punch = function(self, hitter)
		self.object:remove()
		hitter:get_inventory():add_item("main", 'transport_block:sticky_transport_block')
	end,

	on_step = function(self, dtime)
		local pos = self.object:getpos()

		if self.lastpos == nil then
			self.lastpos =  {x=pos.x, y=pos.y, z=pos.z}
		end

		local finished = false
		if math.abs(self.lastpos.x - pos.x) + math.abs(self.lastpos.y - pos.y) + math.abs(self.lastpos.z - pos.z) >= 1 then
			finished = true
		end

		pos.x, pos.y, pos.z = math.floor(pos.x+0.5), math.floor(pos.y+0.5), math.floor(pos.z+0.5)
		local direction = self.direction

		print("entdir: "..dump(direction))

		if finished then -- no mesecon power
			--push only solid nodes
			local name = minetest.get_node(pos).name
			if  name ~= "air" and name ~= "ignore"
			and ((not minetest.registered_nodes[name])
			or minetest.registered_nodes[name].liquidtype == "none") then
				mesecon:mvps_push(pos, direction, MOVESTONE_MAXIMUM_PUSH)
			end
			minetest.add_node(pos, {name="transport_block:sticky_transport_block", param2=minetest.dir_to_facedir(self.direction, true)})
			self.object:remove()
			return
		end

		local success, stack, oldstack =
			mesecon:mvps_push(pos, direction, MOVESTONE_MAXIMUM_PUSH)
		if finished or not success then -- Too large stack/stopper in the way
			minetest.add_node(pos, {name="transport_block:sticky_transport_block", param2=minetest.dir_to_facedir(self.direction, true)})
			self.object:remove()
			return
		else
			mesecon:mvps_process_stack (stack)
			mesecon:mvps_move_objects  (pos, direction, oldstack)
			self.lastdir = direction
		end

		self.object:setvelocity({x=direction.x*2, y=direction.y*2, z=direction.z*2})

		--STICKY
		mesecon:mvps_pull_all(pos, direction)
	end,
})


mesecon:register_mvps_unmov("transport_block:transport_block_entity")
mesecon:register_mvps_unmov("transport_block:sticky_transport_block_entity")
