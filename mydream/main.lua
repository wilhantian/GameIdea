class = require "libs.30log"
tiny = require "libs.tiny"
bump = require "libs.bump"
tween = require "libs.tween"
debugGraph = require "libs.debugGraph"
animator = require "libs.animator"

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
	image = {
		filename = '',
	},
	animate = {
		filename = 'res/%d.png',--可以通过%d匹配
		frameSize = 3,--几个帧
		duration = 1,--可以是纯数字哦
	}
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
	image = {
		filename = ''
	}
}

world = tiny.world(CollisionSystem, MoveSystem, RenderSystem, hero, heroB)
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
