class = require "libs.30log"
tiny = require "libs.tiny"
bump = require "libs.bump"
tween = require "libs.tween"
debugGraph = require "libs.debugGraph"
anim8 = require 'libs.anim8'

define = require "src.define"

require "src.system"
require "src.utils"

aabb = bump.newWorld(64)

------------------------------------
-- TEST
------------------------------------
local hg = anim8.newGrid(80, 100, 640, 740, 0, 0, 0, 0)
local heroAnim = anim8.newAnimation(hg('1-6', 3), 0.14)

local hero = {
	cols = { -- 碰撞组件
		type = define.COLS_TYPE.Hero,
		mask = {"hero", "hero"},
		w = 90,
		h = 40
	},
	move = { -- 移动组件
		mask = function()end,
		speed = {
			x = 20,
			y = 20
		}
	},
	pos = { -- 坐标组件
		x = 100, 
		y = 200
	},
    offset = { -- 偏移量(主要用于sprite和碰撞体配合调整动画坐标)
        x = 10,
        y = -60
    },
    melee = {
        key = 'j',
        cd = 1, -- CD冷却1秒
        x = 0,
        y = 0,
        w = 40,
        h = 40
    },
	sprite = love.graphics.newImage("res/hero.png"), -- 精灵组件 也就是图片
	anim = heroAnim -- 动画配置
}

local heroB = {
	cols = {
		type = define.COLS_TYPE.Monster,
		mask = {"hero", "hero"},
		w = 100,
		h = 100
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
    sprite = love.graphics.newImage("res/hero/Run__001.png")
}

world = tiny.world(MoveSystem, CollisionSystem, MeleeSystem, RenderSystem, ControllerSystem, hero, heroB)
-- tiny.setSystemIndex (world, system, index)

function love.load()
	print("init")
end

function love.update(dt)
end

function love.draw()
	local dt = love.timer.getDelta()
	world:update(dt)
    print('-----------------------')
end
