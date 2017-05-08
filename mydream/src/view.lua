local view = {}

-- 获取缩放因子
-- 实际分辨率/设计分辨率
function view:getScaleFactor()
    if self.windowSize == nil then
        self.windowSize = {
            width = love.graphics.getWidth(),
            height = love.graphics.getHeight()
        }
    end
    local fw = self.windowSize.width / DESIGN_WIDTH
    local fh = self.windowSize.height / DESIGN_HEIGHT
    if fw < fh then
        return fh
    end
    return fw
end

function view:getLogicSize()
    return DESIGN_WIDTH, DESIGN_HEIGHT
end

return view