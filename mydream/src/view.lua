local view = {}

-- 获取缩放因子
-- 实际分辨率/设计分辨率
-- TODO 缓存起来 防止大量运算
function view:getScaleFactor(ismax)
    local fw = love.graphics.getWidth() / DESIGN_WIDTH
    local fh = love.graphics.getHeight() / DESIGN_HEIGHT
    if fw < fh then
        return isMax and fh or fw
    end
    return isMax and fw or fh
end

function view:getLogicSize()
    return DESIGN_WIDTH, DESIGN_HEIGHT
end

-- TODO 缓存起来 防止大量运算
function view:getTranslatePosition()
    local factor = self:getScaleFactor()
    local w, h = DESIGN_WIDTH * factor, DESIGN_HEIGHT * factor
    return (love.graphics.getWidth() - w) / 2, (love.graphics.getHeight() - h)/2
end

return view