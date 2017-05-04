class = require "libs.30log"
tiny = require "libs.tiny"
bump = require "libs.bump"
tween = require "libs.tween"
debugGraph = require "libs.debugGraph"
anim8 = require "libs.anim8"
Camera = require "libs.camera"
Events = require "libs.events"

require "src.define"
require "src.system"
require "src.utils"

aabb = bump.newWorld(64)
drawList = SortFunc()
events = Events:new()

------------------------------------
-- TEST
------------------------------------
local hg = anim8.newGrid(28, 48, 84, 48, 0, 0, 0, 0)

local animRunLeft = anim8.newAnimation(hg('1-3', 1), 0.26)
local animRunRight = anim8.newAnimation(hg('1-3', 1), 0.26)
local animRunUp = anim8.newAnimation(hg('1-3', 1), 0.26)
local animRunDown = anim8.newAnimation(hg('1-3', 1), 0.26)

local animStandLeft = anim8.newAnimation(hg('1-3', 1), 0.26)
local animStandRight = anim8.newAnimation(hg('1-3', 1), 0.26)
local animStandUp = anim8.newAnimation(hg('1-3', 1), 0.26)
local animStandDown = anim8.newAnimation(hg('1-3', 1), 0.26)

animRunLeft:flipH()
animRunDown:flipH()
animStandLeft:flipH()
animStandDown:flipH()

local hero = {
	cols = { -- 碰撞组件
		type = ColsType.Hero,
		mask = {"hero", "hero"},
		w = 90,
		h = 40
	},
	move = { -- 移动组件
		mask = function()end,
		speed = {
			x = 0,
			y = 0
		}
	},
	pos = { -- 坐标组件
		x = 100,
		y = 200
	},
    offset = { -- 偏移量(主要用于sprite的位置)
        x = 10,
        y = -60
    },
    dir = { -- 方向组件
        curDir = DirType.Left
    },
    melee = { -- 近战组件
        key = 'j',
        cd = 1, -- CD冷却1秒
        x = 0,
        y = -10,
        w = 30,
        h = 60
    },
	health = { -- 生命组件
		hp = 3,
		maxHp = 3
	},
	sprite = love.graphics.newImage("res/lipo.png"), -- 精灵组件 也就是图片
	anim = { -- 动画配置
        curAnim = nil,

        runLeft = animRunLeft,
        runRight = animRunRight,
        runUp = animRunUp,
        runDown = animRunDown,
        standLeft = animStandLeft,
        standRight = animStandRight,
        standUp = animStandUp,
        standDown = animStandDown,
        -- todo
    },
	controlable = { -- 控制组件
		up = 'w',
		down = 's',
		left = 'a',
		right = 'd'
	},
	coreLayer = true, -- 渲染层级
	state = {
		curState = StateType.Stand
	}
}

local heroB = {
	cols = {
		type = ColsType.Monster,
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
    sprite = love.graphics.newImage("res/hero/Run__001.png"),
	bgLayer = true,
    health = {
        hp = 2,
        maxHp = 2
    }
}

local colsSys = CollisionSystem()

world = tiny.world(
	MoveSystem(colsSys),
	CollisionSystem(),
	MeleeSystem(colsSys),
    HealthSystem(),
	CameraSystem(),
	RenderSystem("bgLayer"),
	RenderSystem("coreLayer"),
	RenderSystem("lightLayer"),
	ControllerSystem(),
	hero,
	heroB
)

function love.load()
	camera = Camera(0, 0)
	if SHOW_FPS then
		fpsGraph = debugGraph:new('fps', 0, 0)
		memGraph = debugGraph:new('mem', 0, 30)
	end
end

function love.update(dt)
	if SHOW_FPS then
		fpsGraph:update(dt)
		memGraph:update(dt)
	end
end

function love.draw()
	local dt = love.timer.getDelta()

	camera:draw(function()
		world:update(dt)
		drawList:sort()
		drawList:call()
		drawList:clear()
	end)

	if SHOW_FPS then
		fpsGraph:draw()
		memGraph:draw()
	end
end
