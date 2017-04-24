local DEBUG_AABB = true

----------------------------------------------------
-- MoveSystem
----------------------------------------------------
MoveSystem = tiny.processingSystem()
MoveSystem.filter = tiny.requireAll("move", "pos")

function MoveSystem:process(e, dt)
    e.pos.x = e.pos.x + dt * e.move.speed.x
    e.pos.y = e.pos.y + dt * e.move.speed.y

    if e.cols then --如实体含有碰撞组件
        local x, y, cols, len = aabb:move(e, e.pos.x + e.cols.x, e.pos.y + e.cols.y, e.mask)
        e.pos.x = x
        e.pos.y = y

        if len > 0 then
            -- TODO
            -- print("发生了碰撞")
        end

        if DEBUG_AABB then
            drawRect("line", e.pos.x + e.cols.x, e.pos.y + e.cols.y, e.cols.w, e.cols.h, {r = 0, g = 255, b = 0, a = 120})
        end
    end
end
----------------------------------------------------
-- SpriteSystem
----------------------------------------------------
SpriteSystem = tiny.processingSystem()
SpriteSystem.filter = tiny.requireAll("sprite", "pos")

function SpriteSystem:process(e, dt)
    love.graphics.draw(e.sprite.drawable, e.pos.x, e.pos.y)
end
----------------------------------------------------
-- CollisionSystem
----------------------------------------------------
CollisionSystem = tiny.processingSystem()
CollisionSystem.filter = tiny.requireAll("cols", "pos")

function CollisionSystem:process(e, dt)
    if not e.cols.isInit then --如碰撞组件未初始化
        e.cols.isInit = true
        aabb:add(e, e.pos.x + e.cols.x, e.pos.y + e.cols.y, e.cols.w, e.cols.h)
    end
end