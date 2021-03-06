class = require "libs.30log"
tiny = require "libs.tiny"
bump = require "libs.bump"
tween = require "libs.tween"
debugGraph = require "libs.debugGraph"
anim8 = require "libs.anim8"
gamera = require "libs.gamera"
Events = require "libs.events"
push = require "libs.push"
-- require "libs.lovedebug"

require "src.define"
require "src.system"
require "src.utils"

aabb = bump.newWorld(64)
events = Events:new()

drawList = {}
drawList[LayerType.Floor] = SortFunc()
drawList[LayerType.Water] = SortFunc()
drawList[LayerType.Reflect] = SortFunc()
drawList[LayerType.Core] = SortFunc()
drawList[LayerType.Light] = SortFunc()
drawList[LayerType.Debug] = SortFunc()

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

animRunRight:flipH()
animRunUp:flipH()
animStandRight:flipH()
animStandUp:flipH()

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
		x = 200,
		y = 200
	},
    offset = { -- 偏移量(主要用于sprite的位置)
        x = 5,
        y = -35
    },
	scale = {
		x = 2.4,
		y = 2.4
	},
    dir = { -- 方向组件
        curDir = DirType.Left
    },
    melee = { -- 近战组件
        key = 'j',
        cd = 1, -- CD冷却1秒
        left = {
            x = 0,
            y = -10,
            w = 30,
            h = 60
        },
        right = {
            x = 90-30,
            y = -10,
            w = 30,
            h = 60
        },
        up = {
            x = 0,
            y = -30,
            w = 90,
            h = 30
        },
        down = {
            x = 0,
            y = 40,
            w = 90,
            h = 30
        }
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
	-- coreLayer = true, -- 渲染层级
    layer = LayerType.Core, -- 层级
	state = { -- 状态
		curState = StateType.Stand
	},
	effectHitFly = { -- 可以被击飞
		maxDis = 20 -- 最大击飞距离
	},
	lights = {
		x = 0,
		y = 0,
		w = 400,
		h = 30,
		r = 0.2,
		g = 0.6,
		b = 0.2,
		a = 1
	},

}

local heroB = {
	cols = {
		type = ColsType.Monster,
		mask = {"hero", "hero"},
		w = 100,
		h = 30
	},
	move = {
		mask = function()end,
		speed = {
			x = 0,
			y = 0
		}
	},
	pos = {
		x = 250, 
		y = 300 
	},
	offset = { -- 偏移量(主要用于sprite的位置)
        x = 5,
        y = -75
    },
    sprite = newImage("res/hero/Run__001.png"),
    layer = LayerType.Core,
    health = {
        hp = 2,
        maxHp = 2
    },
	effectHitFly = { -- 可以被击飞
		maxDis = 20 -- 最大击飞距离
	}, 
	lights = {
		x = 40,
		y = -10,
		w = 120,
		h = 100,
		r = 0,
		g = 0,
		b = 1,
		a = 1,

		blink = {
			lightRatio = {0.8, 1}, -- 闪烁宽度因子
			darkRatio = {0.8, 1}, -- 闪烁高度因子(暂未使用)
			lightTime = {0.1, 0.5}, -- 亮度时间
			darkTime = {0.1, 0.5}, -- 暗度时间
		}
	}
}

local waterEntity = {
	pos = {x=240, y=320},
	sprite = newImage("res/water.png"),
	layer = LayerType.Water,
	reflect = {
		mask = newImage("res/water_mask.png")
	}
}

local waterEntityB = {
	pos = {x=280, y=460},
	sprite = newImage("res/water.png"),
	layer = LayerType.Water,
	reflect = {
		mask = newImage("res/water_mask.png")
	}
}

local bg = {
	pos = {x=0, y=0},
	sprite = newImage("res/timg.jpg"),
	lightLayer = true,
    layer = LayerType.Floor
}

local canvas = love.graphics.newCanvas()
local reflectCanvas = love.graphics.newCanvas()

-- 灯光Shader
local pixelcode = love.filesystem.read("res/lights.fsh")
local vertexcode = love.filesystem.read("res/lights.vfx")
local sceneShader = love.graphics.newShader(pixelcode, vertexcode)

-- maskShader
local mask_shader = love.graphics.newShader[[
   vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      if (Texel(texture, texture_coords).rgb == vec3(0.0)) {
         // a discarded pixel wont be applied as the stencil.
         discard;
      }
      return vec4(1.0);
   }
]]

-- 镜头
local camera = gamera.new(0, 0, 1500, 1500)

local colsSys = CollisionSystem()
local stateSys = StateSystem()
local renderSys = RenderSystem()

world = tiny.world(
	LightsSystem(sceneShader, camera),
    EffectHitFlySystem(),
	stateSys,
	MoveSystem(colsSys),
	CollisionSystem(),
	MeleeSystem(colsSys),
    HealthSystem(),
	CameraSystem(camera),
	renderSys,
	ControllerSystem(stateSys),
	ReflectSystem(renderSys, camera, reflectCanvas),
	bg,
	hero,
	heroB,
	waterEntity,waterEntityB
)

push:setupScreen(DESIGN_WIDTH, DESIGN_HEIGHT, love.graphics.getWidth(), love.graphics.getHeight(), {
    fullscreen = false,
    resizable = true,
    -- pixelperfect = true,
    stretched = false,
    highdpi = true
})

function love.load()
    if FULL_SCREEN then
        love.window.setFullscreen(true)
    end
	
	if SHOW_FPS then
		fpsGraph = debugGraph:new('fps', 0, 0)
		memGraph = debugGraph:new('mem', 0, 30)
	end
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setLineStyle("rough")
end

function love.update(dt)
	if SHOW_FPS then
		fpsGraph:update(dt)
		memGraph:update(dt)
	end
end

function love.draw()
    local dt = love.timer.getDelta()
	
	push:start()
		local ca = love.graphics.getCanvas()
		love.graphics.setCanvas(canvas)
		love.graphics.clear()
        camera:draw(function(l,t,w,h)
            world:update(dt)
            render(l,t,w,h)
        end)
		love.graphics.setCanvas(ca)
		
		love.graphics.setShader(sceneShader)
		love.graphics.draw(canvas)
		love.graphics.setShader()

        drawGrid() -- 绘制相机调试网格
        drawFPS() -- 绘制FPS
    push:finish()
end

function love.resize(w, h)
    push:resize(w, h)
end

-- 绘制FPS
function drawFPS()
	if SHOW_FPS then
		fpsGraph:draw()
		memGraph:draw()
	end
end

-- 绘制反射mask层
function drawReflectMask()
	local lastShader = love.graphics.getShader()
	love.graphics.setShader(mask_shader)
	love.graphics.draw(reflectCanvas)
	love.graphics.setShader(lastShader)
end

-- 渲染所有层
function render(l,t,w,h)
    renderLayer(drawList[LayerType.Floor])
	renderLayer(drawList[LayerType.Water])
	love.graphics.stencil(drawReflectMask, "replace", 1)
	love.graphics.setStencilTest("greater", 0)
		renderLayer(drawList[LayerType.Reflect])
	love.graphics.setStencilTest()
    renderLayer(drawList[LayerType.Core])
    renderLayer(drawList[LayerType.Light])
    renderLayer(drawList[LayerType.Debug])

	-- love.graphics.draw(reflectCanvas)
end

-- 渲染单个层
function renderLayer(dl)
    dl:sort()
    dl:call()
    dl:clear()
end

-- 绘制网格
function drawGrid()
	if SHOW_GRID then
		local lw, lh = push:getWidth(), push:getHeight()
		local r, g, b, a = love.graphics.getColor()
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.line(lw/2, 0, lw/2, lh)
		love.graphics.line(0, lh/2, lw, lh/2)
		love.graphics.setColor(r, g, b, a)
	end
end