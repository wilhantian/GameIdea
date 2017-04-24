function drawRect(mode, x, y, width, height, color)
    local r, g, b, a = love.graphics.getColor()
    color = color or {r=255, g=255, b=255, a=255}
    love.graphics.setColor(color.r, color.g, color.b, color.a)
    love.graphics.rectangle( mode, x, y, width, height, rx, ry)
    love.graphics.setColor(r, g, b, a)
end