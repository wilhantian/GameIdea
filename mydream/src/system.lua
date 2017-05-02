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
-- direction = {
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
end

function MoveSystem:process(e, dt)
    e.pos.x = e.pos.x + dt * e.move.speed.x
    e.pos.y = e.pos.y + dt * e.move.speed.y

    if e.cols then --如实体含有碰撞组件
        local x, y, cols, len = aabb:move(e, e.pos.x, e.pos.y, e.mask)
        e.pos.x = x
        e.pos.y = y

        if len > 0 then
            self.colsSys:onMoveCollision(e, cols, len)
        end
    end
end
----------------------------------------------------
-- 渲染系统
----------------------------------------------------
RenderSystem = tiny.processingSystem(class "RenderSystem")

function RenderSystem:init(layer)
    self.filter = tiny.requireAll("pos", layer, tiny.requireAny("sprite", "cols"))
end

function RenderSystem:process(e, dt)
    local pos = e.pos
    local anim = e.anim
    local sprite = e.sprite
    local offset = e.offset or {}
    -- local direction = e.direction -- TODO

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
        anim:update(dt)
        drawList:add(function()
            anim:draw(sprite, x, y)
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

----------------------------------------------------
-- 碰撞系统
----------------------------------------------------
CollisionSystem = tiny.system(class "CollisionSystem")

function CollisionSystem:init()
    self.filter = tiny.requireAll("pos", "cols")
end

function CollisionSystem:onMoveCollision(e, cols, len)
    for i=1, len do
        printt(cols[i])
        addFlash(cols[i].other, 0.4)
    end
end

function CollisionSystem:onMeleeCollision(e, cols, len)
    for i=1, len do
        if cols[i] ~= e then
            print('发生武器碰撞')
            if cols[i].health then
                print('-hp')
                cols[i].health.hp = cols[i].health.hp - 1
            end
        end
    end
end

function CollisionSystem:onAdd(e)
    aabb:add(e, e.pos.x, e.pos.y, e.cols.w, e.cols.h)
end

function CollisionSystem:onRemove(e)
    aabb:remove(e)
    printt(e)
end
----------------------------------------------------
-- 控制系统
----------------------------------------------------
ControllerSystem = tiny.processingSystem(class "ControllerSystem")

function ControllerSystem:init()
    self.filter = tiny.requireAll("controlable")
end

function ControllerSystem:process(e, dt)
    local ctrl = e.controlable
    local move = e.move
    local direction = e.direction
    local anim = e.anim

    if love.keyboard.isDown(ctrl.up) then
        move.speed.y = -76
        if direction.dir ~= "up" then
            direction.dir = "up"
        end
    elseif love.keyboard.isDown(ctrl.down) then
        move.speed.y = 76
        if direction.dir ~= "down" then
            direction.dir = "down"
        end
    else
        move.speed.y = 0
    end

    if love.keyboard.isDown(ctrl.left) then
        move.speed.x = -76
        if direction.dir ~= "left" then
            direction.dir = "left"
            anim:flipH()
        end
    elseif love.keyboard.isDown(ctrl.right) then
        move.speed.x = 76
        if direction.dir ~= "right" then
            direction.dir = "right"
            anim:flipH()
        end
    else
        move.speed.x = 0
    end
end
----------------------------------------------------
-- 近战系统
----------------------------------------------------
MeleeSystem = tiny.processingSystem(class "MeleeSystem")

function MeleeSystem:init(colsSys)
    self.filter = tiny.requireAll("melee", "pos", "direction")
    self.colsSys = colsSys
end

function MeleeSystem:process(e, dt)
    local pos = e.pos
    local melee = e.melee
    local direction = e.direction

    melee._cd = (melee._cd or 0) + dt
    if not love.keyboard.isDown(melee.key) then return end
    if melee.cd > melee._cd then return end
    melee._cd = 0

    local x, y, w, h = pos.x + melee.x, pos.y + melee.y, melee.w, melee.h
    local cols, len = aabb:queryRect(x, y, w, h, nil)

    if direction.dir == "right" then
        x = 2*pos.x + melee.x
    end

    if len > 0 then
        self.colsSys:onMeleeCollision(e, cols, len)
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