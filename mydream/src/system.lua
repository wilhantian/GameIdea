local DEBUG_AABB = true
local DEBUG_FPS = true

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
-- RenderSystem
----------------------------------------------------
RenderSystem = tiny.processingSystem()
RenderSystem.filter = tiny.requireAll("pos", tiny.requireAny("image", "animate"))
RenderSystem.fpsGraph = nil
RenderSystem.memGraph = nil

function RenderSystem:process(e, dt)
    local image = e.image
    local animate = e.animate

    if animate then
        animate.anim:update(dt)
        animate.anim:draw(e.pos.x, e.pos.y)
    else
        love.graphics.draw(image.drawable, e.pos.x, e.pos.y)
    end

    if DEBUG_FPS then
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
    local image = e.image
    local animate = e.animate
    
    if animate then
        local frames = {}
        for i=1, animate.frameSize do
            frames[i] = love.graphics.newImage(string.format(animate.filename, i))
        end
        animate.anim = animator.newAnimation(frames, animate.duration)
        animate.anim:setLooping()
    else
        image.drawable = love.graphics.newImage(image.filename)
    end
end
----------------------------------------------------
-- CollisionSystem
----------------------------------------------------
CollisionSystem = tiny.processingSystem()
CollisionSystem.filter = tiny.requireAll("cols", "pos")

function CollisionSystem:process(e, dt)
    --TODO
end

function CollisionSystem:onAdd(e)
    aabb:add(e, e.pos.x + e.cols.x, e.pos.y + e.cols.y, e.cols.w, e.cols.h)
end
----------------------------------------------------
-- ControllerSystem
----------------------------------------------------
ControllerSystem = tiny.processingSystem()
ControllerSystem.filter = tiny.requireAll("move")

function ControllerSystem:process(e, dt)
    if e.cols.type == nil then
        return
    end

    if love.keyboard.isDown('w') then
        e.move.speed.y = -60
    elseif love.keyboard.isDown('s') then
        e.move.speed.y = 60
    else
        e.move.speed.y = 0
    end

    if love.keyboard.isDown('a') then
        e.move.speed.x = -60
    elseif love.keyboard.isDown('d') then
        e.move.speed.x = 60
    else
        e.move.speed.x = 0
    end
end