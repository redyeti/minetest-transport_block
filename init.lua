
-- Non-sticky:
-- Moves along mesecon lines
-- Pushes all blocks in front of it
--
-- Sticky one
-- Moves along mesecon lines
-- Pushes all block in front of it
-- Pull all blocks in its back

local function get_pushstone_direction(pos)
	local node = minetest.get_node(pos)
	return minetest.facedir_to_dir(node.param2)
end

minetest.register_node("pushstone:pushstone", {
	tiles = {"pushstone_arrows.png^[transformR90", "pushstone_arrows.png^[transformR270", "pushstone_arrows.png", "pushstone_arrows.png^[transformR180", "pushstone_side.png", "pushstone_side.png"},
	paramtype2 = "facedir",
	legacy_facedir_simple = true,
	groups = {cracky=3},
    	description="Pushstone",
	sounds = default.node_sound_stone_defaults(),
	mesecons = {effector = {
		action_on = function (pos, node)
			local direction=get_pushstone_direction(pos)
			if not direction then return end
			minetest.remove_node(pos)
			mesecon:update_autoconnect(pos)
			local ent = minetest.add_entity(pos, "pushstone:pushstone_entity")
			print("Nodedir: "..dump(direction))
			ent:get_luaentity().direction = direction
		end
	}}
})

minetest.register_entity("pushstone:pushstone_entity", {
	physical = false,
	visual = "sprite",
	textures = {"pushstone_arrows.png^[transformR90", "pushstone_arrows.png^[transformR270", "pushstone_arrows.png", "pushstone_arrows.png^[transformR180", "pushstone_side.png", "pushstone_side.png"},
	collisionbox = {-0.5,-0.5,-0.5, 0.5, 0.5, 0.5},
	visual = "cube",
	lastdir = {x=0, y=0, z=0},
	lastpos = nil,

	on_punch = function(self, hitter)
		self.object:remove()
		hitter:get_inventory():add_item("main", "pushstone:pushstone")
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
			minetest.add_node(pos, {name="pushstone:pushstone", param2=minetest.dir_to_facedir(self.direction, true)})
			self.object:remove()
			return
		end

		local success, stack, oldstack =
			mesecon:mvps_push(pos, direction, MOVESTONE_MAXIMUM_PUSH)
		if finished or not success then -- Too large stack/stopper in the way
			minetest.add_node(pos, {name="pushstone:pushstone", param2=minetest.dir_to_facedir(self.direction, true)})
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
	output = "pushstone:pushstone 2",
	recipe = {
		{"moreores:tin_ingot", "moreores:tin_ingot", "moreores:tin_ingot"},
		{"group:mesecon_conductor_craftable", "group:mesecon_conductor_craftable", "group:mesecon_conductor_craftable"},
		{"moreores:tin_ingot", "moreores:tin_ingot", "moreores:tin_ingot"},
	}
})



-- STICKY_MOVESTONE

minetest.register_node("pushstone:sticky_pushstone", {
	tiles = {"sticky_pushstone.png^[transformR90", "sticky_pushstone.png^[transformR270", "sticky_pushstone.png", "sticky_pushstone.png^[transformR180", "pushstone_side.png", "pushstone_side.png"},
	paramtype2 = "facedir",
	legacy_facedir_simple = true,
	groups = {cracky=3},
    	description="Sticky Pushstone",
	sounds = default.node_sound_stone_defaults(),
	mesecons = {effector = {
		action_on = function (pos, node)
			local direction=get_pushstone_direction(pos)
			if not direction then return end
			minetest.remove_node(pos)
			mesecon:update_autoconnect(pos)
			local ent = minetest.add_entity(pos, "pushstone:sticky_pushstone_entity")
			ent:get_luaentity().direction = direction
		end
	}}
})

minetest.register_craft({
	output = "pushstone:sticky_pushstone 2",
	recipe = {
		{"mesecons_materials:glue", "pushstone:pushstone", "mesecons_materials:glue"},
	}
})

minetest.register_entity("pushstone:sticky_pushstone_entity", {
	physical = false,
	visual = "sprite",
	textures = {"sticky_pushstone.png^[transformR90", "sticky_pushstone.png^[transformR270", "sticky_pushstone.png", "sticky_pushstone.png^[transformR180", "pushstone_side.png", "pushstone_side.png"},
	collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
	visual = "cube",
	lastdir = {x=0, y=0, z=0},

	on_punch = function(self, hitter)
		self.object:remove()
		hitter:get_inventory():add_item("main", 'pushstone:sticky_pushstone')
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
			minetest.add_node(pos, {name="pushstone:sticky_pushstone", param2=minetest.dir_to_facedir(self.direction, true)})
			self.object:remove()
			return
		end

		local success, stack, oldstack =
			mesecon:mvps_push(pos, direction, MOVESTONE_MAXIMUM_PUSH)
		if finished or not success then -- Too large stack/stopper in the way
			minetest.add_node(pos, {name="pushstone:sticky_pushstone", param2=minetest.dir_to_facedir(self.direction, true)})
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


mesecon:register_mvps_unmov("pushstone:pushstone_entity")
mesecon:register_mvps_unmov("pushstone:sticky_pushstone_entity")
