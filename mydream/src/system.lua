local DEBUG_AABB = true
local DEBUG_FPS = true
----------------------------------------------------
-- flash = {
--     isShow = boolean,
--     time = number,
--     curShowTime = number,
--     lastShowTime = number
-- }
----------------------------------------------------
-- melee = {
--     x = number,
--     y = number,
--     w = number,
--     h = number,
--     key = string or number,
--     cd = number
-- }
----------------------------------------------------

----------------------------------------------------
-- MoveSystem
----------------------------------------------------
MoveSystem = tiny.processingSystem()
MoveSystem.filter = tiny.requireAll("move", "pos")

function MoveSystem:process(e, dt)
    e.pos.x = e.pos.x + dt * e.move.speed.x
    e.pos.y = e.pos.y + dt * e.move.speed.y

    if e.cols then --如实体含有碰撞组件
        local x, y, cols, len = aabb:move(e, e.pos.x, e.pos.y, e.mask)
        e.pos.x = x
        e.pos.y = y

        if len > 0 then
            onCollsionHandler(cols, len)
        end
    end
end
----------------------------------------------------
-- RenderSystem
----------------------------------------------------
RenderSystem = tiny.processingSystem()
RenderSystem.filter = tiny.requireAll("pos", tiny.requireAny("sprite", "cols"))
RenderSystem.fpsGraph = nil
RenderSystem.memGraph = nil

function RenderSystem:process(e, dt)
    local pos = e.pos
    local anim = e.anim
    local sprite = e.sprite
    local offset = e.offset or {}

    local x, y = pos.x + (offset.x or 0), pos.y + (offset.y or 0)

    if e.flash then
        e.flash.curShowTime = e.flash.curShowTime + dt
        if e.flash.curShowTime > e.flash.time then
            e.flash.curShowTime = 0
            e.flash.isShow = not e.flash.isShow
        end

        if not e.flash.isShow then
            return
        end
    end

    if anim then
        anim:update(dt)
        anim:draw(sprite, x, y)
    elseif sprite then
        love.graphics.draw(sprite, x, y)
    end

    if DEBUG_AABB then -- 碰撞区域调试
        if e.cols then
            drawRect("line", e.pos.x, e.pos.y, e.cols.w, e.cols.h, {r = 0, g = 255, b = 0, a = 120})
        end
    end

    if DEBUG_FPS then -- FPS信息
        if RenderSystem.fpsGraph == nil then
            RenderSystem.fpsGraph = debugGraph:new('fps', 0, 0)
            RenderSystem.memGraph = debugGraph:new('mem', 0, 30)
        end
        RenderSystem.fpsGraph:update(dt)
        RenderSystem.memGraph:update(dt)
        RenderSystem.fpsGraph:draw()
        RenderSystem.memGraph:draw()
    end
end

function RenderSystem:onAdd(e)
end
----------------------------------------------------
-- CollisionSystem
----------------------------------------------------
CollisionSystem = tiny.processingSystem()
CollisionSystem.filter = tiny.requireAll("cols", "pos")

function CollisionSystem:process(e, dt)
    local x = CollisionSystem._curColsX
    local y = CollisionSystem._curColsY
    local e = CollisionSystem._curColsE
    local o = CollisionSystem._curColsOthers
    local l = CollisionSystem._curColsLen
end

function CollisionSystem:onCollision()
    -- TODO
end

function CollisionSystem:onAdd(e)
    aabb:add(e, e.pos.x, e.pos.y, e.cols.w, e.cols.h)
end
----------------------------------------------------
-- ControllerSystem
----------------------------------------------------
ControllerSystem = tiny.processingSystem()
ControllerSystem.filter = tiny.requireAll("move")

function ControllerSystem:process(e, dt)
    if e.cols.type ~= define.COLS_TYPE.Hero then
        return
    end

    if love.keyboard.isDown('w') then
        e.move.speed.y = -76
    elseif love.keyboard.isDown('s') then
        e.move.speed.y = 76
    else
        e.move.speed.y = 0
    end

    if love.keyboard.isDown('a') then
        e.move.speed.x = -76
    elseif love.keyboard.isDown('d') then
        e.move.speed.x = 76
    else
        e.move.speed.x = 0
    end
end
----------------------------------------------------
-- MeleeSystem
----------------------------------------------------
MeleeSystem = tiny.processingSystem()
MeleeSystem.filter = tiny.requireAll("melee", "pos")

function MeleeSystem:process(e, dt)
    local pos = e.pos
    local melee = e.melee

    melee._cd = (melee._cd or 0) + dt
    if not love.keyboard.isDown(melee.key) then return end
    if melee.cd > melee._cd then return end
    melee._cd = 0

    local x, y, w, h = melee.x, melee.y, melee.w, melee.h
    x = x + pos.x -- TODO
    y = y + pos.y -- TODO

    local items, len = aabb:queryRect(x, y, w, h, nil)
    -- TODO
    print('与' .. len .. '个物体发生碰撞')
end
----------------------------------------------------
-- Collision Handler
----------------------------------------------------
function onCollsionHandler(cols, len)
    -- TODO
    for i=1, len do
        printt(cols[i])
        addFlash(cols[i].other, 0.4)
    end
end