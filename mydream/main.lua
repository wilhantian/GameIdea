class = require "libs.30log"
tiny = require "libs.tiny"
bump = require "libs.bump"
require "src.system"
require "src.utils"

aabb = bump.newWorld(64)

local hero = {
	cols = {
		type = {"hero", "hero"},
		mask = {"hero", "hero"},
		w = 100,
		h = 100,
		x = 0,
		y = 0
	},
	move = {
		mask = function()end,
		speed = {
			x = 20,
			y = 20
		}
	},
	pos = {
		x = 100, 
		y = 100 
	},
	sprite = {
		drawable = love.graphics.newImage("res/5.png")
	},
	dir = 1
}

local heroB = {
	cols = {
		type = {"hero", "hero"},
		mask = {"hero", "hero"},
		w = 100,
		h = 100,
		x = 0,
		y = 0
	},
	move = {
		mask = function()end,
		speed = {
			x = 0,
			y = 0
		}
	},
	pos = {
		x = 200, 
		y = 200 
	},
	sprite = {
		drawable = love.graphics.newImage("res/5.png")
	},
	dir = 1
}

world = tiny.world(CollisionSystem, MoveSystem, SpriteSystem, hero, heroB)
-- tiny.setSystemIndex (world, system, index)

function love.load()
	print("init")
end

function love.update(dt)
end

function love.draw()
	local dt = love.timer.getDelta()
	world:update(dt)
end
