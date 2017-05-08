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
view = require "src.view"

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
	scale = {
		x = 5,
		y = 2
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
	sprite = newImage("res/lipo.png"), -- 精灵组件 也就是图片
	anim = { -- 动画配置
        -- curAnim = nil,
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
	state = { -- 状态
		curState = StateType.Stand
	},
	-- effectHitFly = { -- 击飞特效
	-- 	duration = 1.1,
	-- 	x = -100,
	-- 	y = 10
	-- }
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
    sprite = newImage("res/hero/Run__001.png"),
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
    if FULL_SCREEN then
        love.window.setFullscreen(true)
    end

	camera = Camera(0, 0)
	if SHOW_FPS then
		fpsGraph = debugGraph:new('fps', 0, 0)
		memGraph = debugGraph:new('mem', 0, 30)
	end
	love.graphics.setDefaultFilter("nearest", "nearest")
end

function love.update(dt)
	if SHOW_FPS then
		fpsGraph:update(dt)
		memGraph:update(dt)
	end
end

local testImg = newImage("res/heroTest.png")
-- testImg:setFilter("nearest")

function love.draw()
    -- 分辨率适配
    local factor = view:getScaleFactor()
    love.graphics.scale(factor)

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

    love.graphics.draw(testImg, 100, 100, 0, 3, 3)
end
