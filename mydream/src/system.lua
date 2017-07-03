----------------------------------------------------
-- 闪烁
-- flash = {
--     isShow = boolean,
--     time = number,
--     curShowTime = number,
--     lastShowTime = number
-- }
----------------------------------------------------
-- 近战
-- melee = {
--     x = number,
--     y = number,
--     w = number,
--     h = number,
--     key = string or number,
--     cd = number
-- }
----------------------------------------------------
-- 玩家控制
-- controlable = {
--     up = 'w',
--     down = 's',
--     left = 'a',
--     right = 'd'
-- }
----------------------------------------------------
-- 方向组件
-- dir = {
--     lastDir = '',
--     dir = ''
-- }
----------------------------------------------------
-- 击飞特效
-- effectHitFly = { -- 击飞特效
-- 	maxDis = number
-- }
----------------------------------------------------
-- 移动系统
----------------------------------------------------
MoveSystem = tiny.processingSystem(class "MoveSystem")

function MoveSystem:init(colsSys)
    self.filter = tiny.requireAll("pos", "move")
    self.colsSys = colsSys

    events:on("stateChanged", bind(self.onStateChanged, self))
    events:on("dirChanged", bind(self.onDirChanged, self))
end

function MoveSystem:process(e, dt)
    local ehf = e.effectHitFly -- 击飞特效
    if ehf and ehf.isActive then
        e.pos.x = ehf.targerPos.x
        e.pos.y = ehf.targerPos.y
    else
        e.pos.x = e.pos.x + dt * e.move.speed.x
        e.pos.y = e.pos.y + dt * e.move.speed.y
    end

    if e.cols then --如实体含有碰撞组件
        local x, y, cols, len = aabb:move(e, e.pos.x, e.pos.y, e.mask)
        e.pos.x = x
        e.pos.y = y

        if len > 0 then
            events:emit("moveCollision", e, cols, len)
        end
    end
end

function MoveSystem:onStateChanged(e)
    local move = e.move
    if move then
        move.speed.x, move.speed.y = self:getSpeed(e)
    end
end

function MoveSystem:onDirChanged(e)
    local move = e.move
    if move then
        move.speed.x, move.speed.y = self:getSpeed(e)
    end
end

function MoveSystem:getSpeed(e)
    local st = e.state.curState
    local dir = e.dir.curDir
    
    if st == StateType.Run then
        if dir == DirType.Up then return 0, -60 elseif
        dir == DirType.Down then return 0, 60 elseif
        dir == DirType.Left then return -60, 0 elseif
        dir == DirType.Right then return 60, 0 elseif
        dir == DirType.LeftUp then return -40, -40 elseif
        dir == DirType.LeftDown then return -40, 40 elseif
        dir == DirType.RightUp then return 40, -40 elseif
        dir == DirType.RightDown then return 40, 40 end
    end

    return 0, 0
end
----------------------------------------------------
-- 渲染系统
----------------------------------------------------
RenderSystem = tiny.processingSystem(class "RenderSystem")

function RenderSystem:init()
    self.filter = tiny.requireAll("pos", tiny.requireAny("sprite", "cols"))

    events:on("stateChanged", bind(self.onStateChanged, self))
    events:on("dirChanged", bind(self.onDirChanged, self))
end

function RenderSystem:process(e, dt)
    local anim = e.anim
    local sprite = e.sprite

    local x,y,
        rotate,
        scaleX,scaleY,
        offsetX,offsetY = self:getRenderInfo(e)

    if e.flash then -- 闪烁组件
        e.flash.curShowTime = e.flash.curShowTime + dt
        if e.flash.curShowTime > e.flash.time then
            e.flash.curShowTime = 0
            e.flash.isShow = not e.flash.isShow
        end

        if not e.flash.isShow then
            return
        end
    end

    local w, h
    if anim then -- 动画组件
        w, h = anim.curAnim:getDimensions()
        drawList[e.layer]:add(function()
            if anim.curAnim then
                anim.curAnim:update(dt)
                anim.curAnim:draw(sprite, x, y, rotate, scaleX, scaleY, offsetX, offsetY)
            end
        end, y + (h + offsetY) * scaleY) -- fixme 性能问题

        if e.layer == LayerType.Core then -- 动态层添加到睡眠反射阴影
            drawList[LayerType.Reflect]:add(function()
                if anim.curAnim then
                    local r, g, b, a = love.graphics.getColor()
                    love.graphics.setColor(255,255,255,120)
                    anim.curAnim:draw(sprite, x, y + (h - offsetY)*scaleY*2, rotate, scaleX, -scaleY, offsetX, offsetY)
                    love.graphics.setColor(r, g, b, a)
                end
            end, y + (h + offsetY) * scaleY)
        end

    elseif sprite then
        w, h = sprite:getDimensions()
        drawList[e.layer]:add(function()
            love.graphics.draw(sprite, x, y, rotate, scaleX, scaleY, offsetX, offsetY)
        end, y + (h + offsetY) * scaleY) -- fixme 性能问题

        if e.layer == LayerType.Core then -- 动态层添加到睡眠反射阴影
            drawList[LayerType.Reflect]:add(function()
                love.graphics.draw(sprite, x, y + (h - offsetY)*scaleY*2, rotate, scaleX, -scaleY, offsetX, offsetY)
            end, y + (h + offsetY) * scaleY)
        end
    end



    if DEBUG_AABB then -- 碰撞区域调试
        drawList[e.layer]:add(function()
            if e.cols then
                drawRect("line", x, y, e.cols.w, e.cols.h, {r = 0, g = 255, b = 0, a = 120})
            end

            if e.melee and e.melee.clock < e.melee.cd and e.melee._debug then -- 近战调试
                local melee = e.melee
                local mx, my, w, h = x + melee._debug.x, y + melee._debug.y, melee._debug.w, melee._debug.h
                drawRect("fill", mx, my, w, h, {r = 20, g = 20, b = 205, a = 255 - 255 * e.melee.clock / e.melee.cd})
            end
        end, 0)
    end
end

-- 实体状态发生改变
function RenderSystem:onStateChanged(e)
    self:onStateOrDirChanged(e)
end

-- 实体方向发生改变
function RenderSystem:onDirChanged(e)
    self:onStateOrDirChanged(e)
end

-- 实体的方向或状态发生改变
function RenderSystem:onStateOrDirChanged(e)
    local st = e.state
    local dir = e.dir
    local anim = e.anim

    if st == nil or dir == nil or anim == nil then
        return
    end

    if st.curState == StateType.Run then
        if dir.curDir == DirType.Up then
            anim.curAnim = anim.runUp
        elseif dir.curDir == DirType.Down then
            anim.curAnim = anim.runDown
        elseif dir.curDir == DirType.Right or dir.curDir == DirType.RightUp or dir.curDir == DirType.RightDown then
            anim.curAnim = anim.runRight
        elseif dir.curDir == DirType.Left or dir.curDir == DirType.LeftUp or dir.curDir == DirType.LeftDown then
            anim.curAnim = anim.runLeft
        end
    elseif st.curState == StateType.Stand then
        if dir.curDir == DirType.Up then
            anim.curAnim = anim.standUp
        elseif dir.curDir == DirType.Down then
            anim.curAnim = anim.standDown
        elseif dir.curDir == DirType.Right or dir.curDir == DirType.RightUp or dir.curDir == DirType.RightDown then
            anim.curAnim = anim.standRight
        elseif dir.curDir == DirType.Left or dir.curDir == DirType.LeftUp or dir.curDir == DirType.LeftDown then
            anim.curAnim = anim.standLeft
        end
    end
end

function RenderSystem:onAdd(e)
    self:onStateOrDirChanged(e)
end

-- 获取渲染信息
-- x,y,rotate,scaleX,scaleY,offsetX,offsetY
function RenderSystem:getRenderInfo(e)
    local x, y = e.pos.x, e.pos.y
    local offset = e.offset or {}
    local rotate = e.rotate or 0
    local scaleX, scaleY = e.scale and e.scale.x or 1, e.scale and e.scale.y or 1
    local offsetX, offsetY = e.offset and e.offset.x or 0, e.offset and e.offset.y or 0
    offsetX = -offsetX
    offsetY = -offsetY
    return x, y,
           rotate,
           scaleX, scaleY,
           offsetX, offsetY
end
----------------------------------------------------
-- 反射系统
----------------------------------------------------
ReflectSystem = tiny.processingSystem(class "ReflectSystem")

function ReflectSystem:init(renderSys, camera, canvas)
    self.filter = tiny.requireAll("reflect")
    self.renderSys = renderSys
    self.camera = camera
    self.canvas = canvas
end

function ReflectSystem:preProcess(dt)
    self.lastCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 255)
    print('begin')
end

function ReflectSystem:postProcess(dt)
    love.graphics.setCanvas(self.lastCanvas)
    print('end')
end

function ReflectSystem:process(e, dt)
    local reflect = e.reflect
    local x,y,r,sx,sy,ox,oy = self.renderSys:getRenderInfo(e)
    x, y = self.camera:toWorld(x, y)
    love.graphics.draw(reflect.mask,x,y,r,sx,sy,ox,oy)
end

----------------------------------------------------
-- 碰撞系统
----------------------------------------------------
CollisionSystem = tiny.system(class "CollisionSystem")

function CollisionSystem:init()
    self.filter = tiny.requireAll("pos", "cols")
end

function CollisionSystem:onAdd(e)
    aabb:add(e, e.pos.x, e.pos.y, e.cols.w, e.cols.h)
end

function CollisionSystem:onRemove(e)
    aabb:remove(e)
end
----------------------------------------------------
-- 控制系统
----------------------------------------------------
ControllerSystem = tiny.processingSystem(class "ControllerSystem")

function ControllerSystem:init(stateSys)
    self.filter = tiny.requireAll("controlable")
    self.stateSys = stateSys
    events:on("effectHitFlyDeActive", bind(self.onEffectHitFlyDeActive, self))
end

function ControllerSystem:process(e, dt)
    local ctrl = e.controlable

    if e.effectHitFly and e.effectHitFly.isActive then --含有击飞特效则不受控制
        self.stateSys:setState(e, StateType.HitFly)
        return
    end

    local l = love.keyboard.isDown(ctrl.left)
    local r = love.keyboard.isDown(ctrl.right)
    local u = love.keyboard.isDown(ctrl.up)
    local d = love.keyboard.isDown(ctrl.down)

    local dir = nil

    if u then dir = DirType.Up end
    if d then dir = DirType.Down end
    if l then dir = DirType.Left end
    if r then dir = DirType.Right end
    if r and u then dir = DirType.RightUp end
    if l and u then dir = DirType.LeftUp end
    if r and d then dir = DirType.RightDown end
    if l and d then dir = DirType.LeftDown end

    if l or r or u or d then
        self.stateSys:setState(e, StateType.Run)
    else
        self.stateSys:setState(e, StateType.Stand)
    end

    if dir then
        self.stateSys:setDir(e, dir)
    end
end

-- 击飞效果移除
function ControllerSystem:onEffectHitFlyDeActive(e)
    self.stateSys:setState(e, StateType.HitFly)
end
----------------------------------------------------
-- 近战系统
----------------------------------------------------
MeleeSystem = tiny.processingSystem(class "MeleeSystem")

function MeleeSystem:init(colsSys)
    self.filter = tiny.requireAll("melee", "pos", "dir")
    self.colsSys = colsSys
end

function MeleeSystem:process(e, dt)
    local pos = e.pos
    local melee = e.melee
    local dir = e.dir

    melee.clock = melee.clock + dt
    if not love.keyboard.isDown(melee.key) then return end
    if melee.cd > melee.clock then return end
    melee.clock = 0

    local meleeData = melee[dir.curDir]
    if meleeData == nil then
        return print("近战未识别当前打击方向")
    end

    local x, y, w, h = pos.x + meleeData.x, pos.y + meleeData.y, meleeData.w, meleeData.h
    melee._debug = {x=meleeData.x, y=meleeData.y, w=w, h=h}

    local cols, len = aabb:queryRect(x, y, w, h, nil)

    if len > 0 then
        events:emit("meleeCollision", e, cols, len)
    end
end

function MeleeSystem:onAdd(e)
    e.melee.clock = e.melee.cd + 0.001
end
----------------------------------------------------
-- 相机系统
----------------------------------------------------
CameraSystem = tiny.processingSystem(class "CameraSystem")

function CameraSystem:init(camera)
    self.filter = tiny.requireAll("pos", tiny.requireAny("controlable"))
    self.camera = camera
end

function CameraSystem:process(e, dt)
    local dx, dy = e.pos.x, e.pos.y
    self.camera:setPosition(dx, dy)
end
----------------------------------------------------
-- 生命系统
----------------------------------------------------
HealthSystem = tiny.processingSystem(class "HealthSystem")

function HealthSystem:init()
    self.filter = tiny.requireAll("health")

    -- 移动碰撞
    events:on("moveCollision", bind(self.onMoveCollision, self))
    -- 近战碰撞
    events:on("meleeCollision", bind(self.onMeleeCollision, self))
end

function HealthSystem:process(e, dt)
    local health = e.health

    if health.hp <= 0 and not health.isDied then
        health.isDied = true
        -- TODO 死亡
        world:removeEntity(e)
        print('实体死亡')
    end
end

function HealthSystem:onMoveCollision(e, others, len)
    local cols = e.cols
    local health = e.health

    for i=1, len do
        local other = others[i].other
        
        if cols.type == ColsType.Hero and other.cols.type == ColsType.Monster then
            local curTime = love.timer.getTime()
            if health and curTime - (health.lastHitTime or 0) > 0.5 then
                health.hp = health.hp - 1
                health.lastHitTime = curTime
                events:emit("healthChanged", e)
            end
        end
    end
end

function HealthSystem:onMeleeCollision(e, others, len)
    local cols = e.cols

    for i=1, len do
        local other = others[i]

        if e ~= other then
            if other.health then
                other.health.hp = other.health.hp - 1
            end
        end
    end
end
----------------------------------------------------
-- 击飞系统
----------------------------------------------------
EffectHitFlySystem = tiny.processingSystem(class "EffectHitFlySystem")

function EffectHitFlySystem:init()
    self.filter = tiny.requireAll("effectHitFly", "pos")

    -- 移动碰撞
    events:on("moveCollision", bind(self.onMoveCollision, self))
    -- 近战碰撞
    events:on("meleeCollision", bind(self.onMeleeCollision, self))
end

function EffectHitFlySystem:process(e, dt)
    local ehf = e.effectHitFly
    local pos = e.pos

    if not ehf.isActive then
        return
    end

    if not ehf.tween then
        local x, y = pos.x, pos.y
        local ox, oy = ehf.x, ehf.y
        ehf.startPos = {x = pos.x, y = pos.y}
        ehf.targerPos = {x = pos.x, y = pos.y}
        ehf.tween = tween.new(ehf.duration, ehf.targerPos, {x = x + ox, y = y + oy}, 'linear')
    end

    ehf.clock = ehf.clock + dt

    if ehf.duration <= ehf.clock then
        ehf.clock = 0
        ehf.duration = 0
        ehf.tween = nil
        ehf.isActive = false
        events:emit("effectHitFlyDeActive", e) -- 派发击飞特效移出事件
        return
    end

    ehf.tween:update(dt)
end

function EffectHitFlySystem:onAdd(e)
    local ehf = e.effectHitFly
    ehf.duration = 0
    ehf.clock = 0
    ehf.isActive = false
end

function EffectHitFlySystem:onMoveCollision(e, others, len)
    for i=1, len do
        local other = others[i].other

        if e.effectHitFly then 
            e.effectHitFly.x = -1 * e.effectHitFly.maxDis
            e.effectHitFly.y = -1 * e.effectHitFly.maxDis
            e.effectHitFly.duration = 0.16
            e.effectHitFly.isActive = true
        end
    end
end

function EffectHitFlySystem:onMeleeCollision(e, others, len)
    for i=1, len do
        local other = others[i]

        if e ~= other then
            if other.effectHitFly then
                other.effectHitFly.x = -1 * other.effectHitFly.maxDis
                other.effectHitFly.y = -1 * other.effectHitFly.maxDis
                other.effectHitFly.duration = 0.16
                other.effectHitFly.isActive = true
            end
        end
    end
end
----------------------------------------------------
-- 状态系统 or 方向系统
-- 目前看来 方位(方向)组件仅仅属于状态的扩展
-- 故将方向组件作为一种状态
----------------------------------------------------
StateSystem = tiny.processingSystem(class "StateSystem")

function StateSystem:init()
    self.filter = tiny.requireAll("state")
end

function StateSystem:process(e, dt)
end

function StateSystem:setState(e, state)
    if e.state == nil or e.state.curState == state then 
        return
    end
    
    e.state.lastState = e.state.curState
    e.state.curState = state
    events:emit("stateChanged", e)
end

function StateSystem:setDir(e, dir)
    if e.dir == nil or e.dir.curDir == dir then 
        return
    end
    
    e.dir.lastDir = e.dir.curDir
    e.dir.curDir = dir
    events:emit("dirChanged", e)
end
----------------------------------------------------
-- 灯光系统
-- TODO 目前仅支持正圆形灯光, 随着游戏发展可能需要椭圆形灯光
----------------------------------------------------
LightsSystem = tiny.processingSystem(class "LightsSystem")

function LightsSystem:init(shader, camera)
    self.filter = tiny.requireAll("lights", "pos")
	self.shader = shader
    self.camera = camera

    self.lightsList = {"lights"}
    self.numLights = 0
end

function LightsSystem:preProcess(dt)
    self.lightsList = {"lights"}
    self.numLights = 0
end

function LightsSystem:postProcess(dt)
    table.insert(self.lightsList, 'nil')

    local shader = self.shader
    shader:sendInt("numLights", self.numLights)
	shader:send(unpack(self.lightsList))
	shader:send("minDarkness", 0)
	shader:send("maxBrightness", 1)
end

function LightsSystem:process(e, dt)
    local lights = e.lights
    local pos = e.pos

    local x, y = self.camera:toScreen(pos.x + lights.x, pos.y + lights.y)

    -- 是否闪烁
    if lights.blink then
        local blink = lights.blink
        -- if blink.clock == nil then
        --     blink.startW = lights.w
        --     blink.startH = lights.h
        --     blink.clock = 0
        --     blink.isLight = true
        --     blink.duration = 
        --     lights.w = blink.startW * utils.random(blink.darkRatio[1], blink.darkRatio[2])
        -- end
        
        -- blink.clock = dt + blink.clock

        -- if blink.clock >= blink.duration then
        --     blink.clock = 0
        --     blink.isLight = not blink.isLight

        --     if blink.isLight then
        --         lights.w = blink.startW * utils.random(blink.darkRatio[1], blink.darkRatio[2])
        --         blink.duration = utils.random(blink.lightTime[1], blink.lightTime[2])
        --     else
        --         lights.w = blink.startW * utils.random(blink.lightRatio[1], blink.lightRatio[2])
        --         blink.duration = utils.random(blink.darkTime[1], blink.darkTime[2])
        --     end
        -- end
        -----------------------------------------------------------------------------------------
        if blink.tween == nil then
            blink.isLight = true
            blink.startW = lights.w
            blink.startH = lights.h
            lights.w = blink.startW * utils.random(blink.lightRatio[1], blink.lightRatio[2])
            lights.h = blink.startH * utils.random(blink.lightRatio[1], blink.lightRatio[2])
            local duration = utils.random(blink.lightTime[1], blink.lightTime[2])
            local targer = {w=blink.startW * utils.random(blink.darkRatio[1], blink.darkRatio[2]), h=blink.startH * utils.random(blink.darkRatio[1], blink.darkRatio[2])}
            blink.tween = tween.new(duration, lights, targer, 'linear')
        end

        if blink.tween:update(dt) then
            local duration, targer
            blink.isLight = not blink.isLight
            if blink.isLight then
                duration = utils.random(blink.lightTime[1], blink.lightTime[2])
                targer = {w=blink.startW * utils.random(blink.darkRatio[1], blink.darkRatio[2]), h=blink.startH * utils.random(blink.darkRatio[1], blink.darkRatio[2])}
            else
                duration = utils.random(blink.darkTime[1], blink.darkTime[2])
                targer = {w=blink.startW * utils.random(blink.lightRatio[1], blink.lightRatio[2]), h=blink.startH * utils.random(blink.lightRatio[1], blink.lightRatio[2])}
            end
            blink.tween = tween.new(duration, lights, targer, 'linear')
        end
    end

    -- x y w h r g b a
    table.insert(self.lightsList, x)
    table.insert(self.lightsList, y)
    table.insert(self.lightsList, lights.w)
    table.insert(self.lightsList, lights.h)
    table.insert(self.lightsList, lights.r)
    table.insert(self.lightsList, lights.g)
    table.insert(self.lightsList, lights.b)
    table.insert(self.lightsList, lights.a)

    self.numLights = self.numLights + 1
end