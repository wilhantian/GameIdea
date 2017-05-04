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

----------------------------------------------------
-- 移动系统
----------------------------------------------------
MoveSystem = tiny.processingSystem(class "MoveSystem")

function MoveSystem:init(colsSys)
    self.filter = tiny.requireAll("move", "pos")
    self.colsSys = colsSys

    events:on("stateChanged", bind(self.onStateChanged, self))
    events:on("dirChanged", bind(self.onDirChanged, self))
end

function MoveSystem:process(e, dt)
    e.pos.x = e.pos.x + dt * e.move.speed.x
    e.pos.y = e.pos.y + dt * e.move.speed.y

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
        move.speed.x, move.speed.y = self:_getSpeed(e)
    end
end

function MoveSystem:onDirChanged(e)
    local move = e.move
    if move then
        move.speed.x, move.speed.y = self:_getSpeed(e)
    end
end

function MoveSystem:_getSpeed(e)
    local st = e.state.curState
    local dir = e.dir.curDir
    
    if st == StateType.Stand then
        return 0, 0
    end
    
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
end
----------------------------------------------------
-- 渲染系统
----------------------------------------------------
RenderSystem = tiny.processingSystem(class "RenderSystem")

function RenderSystem:init(layer)
    self.filter = tiny.requireAll("pos", layer, tiny.requireAny("sprite", "cols"))

    events:on("stateChanged", bind(self.onStateChanged, self))
    events:on("dirChanged", bind(self.onDirChanged, self))
end

function RenderSystem:process(e, dt)
    local pos = e.pos
    local anim = e.anim
    local sprite = e.sprite
    local offset = e.offset or {}

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

    local x, y = pos.x + (offset.x or 0), pos.y + (offset.y or 0)

    if anim then -- 动画组件
        drawList:add(function()
            if anim.curAnim then
                anim.curAnim:update(dt)
                anim.curAnim:draw(sprite, x, y, 0, 6, 6)
            end
        end, y)
    elseif sprite then
        drawList:add(function()
            love.graphics.draw(sprite, x, y)
        end, y)
    end

    if DEBUG_AABB then -- 碰撞区域调试
        if e.cols then
            drawRect("line", e.pos.x, e.pos.y, e.cols.w, e.cols.h, {r = 0, g = 255, b = 0, a = 120})
        end

        if e.melee and e.melee._cd < e.melee.cd then -- 近战调试
            local melee = e.melee
            local x, y, w, h = e.pos.x + melee.x, e.pos.y + melee.y, melee.w, melee.h
            drawRect("fill", x, y, w, h, {r = 20, g = 20, b = 205, a = 255 - 255 * e.melee._cd / e.melee.cd})
        end
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

function ControllerSystem:init()
    self.filter = tiny.requireAll("controlable")
end

function ControllerSystem:process(e, dt)
    local ctrl = e.controlable or {}

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
        self:setState(e, StateType.Run)
    else
        self:setState(e, StateType.Stand)
    end

    if dir then
        self:setDir(e, dir)
    end
end

-- 切换组件状态
function ControllerSystem:setState(e, state)
    if e.state == nil or e.state.curState == state then 
        return
    end
    
    e.state.lastState = e.state.curState
    e.state.curState = state
    events:emit("stateChanged", e)
end

-- 切换组件方向
function ControllerSystem:setDir(e, dir)
    if e.dir == nil or e.dir.curDir == dir then 
        return
    end
    
    e.dir.lastDir = e.dir.curDir
    e.dir.curDir = dir
    events:emit("dirChanged", e)
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

    melee._cd = (melee._cd or 0) + dt
    if not love.keyboard.isDown(melee.key) then return end
    if melee.cd > melee._cd then return end
    melee._cd = 0

    local x, y, w, h = pos.x + melee.x, pos.y + melee.y, melee.w, melee.h
    local cols, len = aabb:queryRect(x, y, w, h, nil)

    if dir.curDir == "right" then
        x = 2*pos.x + melee.x
    end

    if len > 0 then
        events:emit("meleeCollision", e, cols, len)
    end
end
----------------------------------------------------
-- 相机系统
----------------------------------------------------
CameraSystem = tiny.processingSystem(class "CameraSystem")

function CameraSystem:init()
    self.filter = tiny.requireAll("pos", tiny.requireAny("controlable"))
end

function CameraSystem:process(e, dt)
    local dx, dy = e.pos.x, e.pos.y
    camera:lookAt(dx, dy)
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
        
        if e == other then return end

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

function HealthSystem:onMeleeCollision(e, cols, len)
end