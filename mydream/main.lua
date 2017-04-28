class = require "libs.30log"
tiny = require "libs.tiny"
bump = require "libs.bump"
tween = require "libs.tween"
debugGraph = require "libs.debugGraph"
anim8 = require 'libs.anim8'

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
	sprite = love.graphics.newImage("res/1.png"),
	-- anim = anim8.newAnim
}

local heroB = {
	cols = {
		type = nil,
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
	}
}

world = tiny.world(CollisionSystem, MoveSystem, RenderSystem, ControllerSystem, hero, heroB)
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
