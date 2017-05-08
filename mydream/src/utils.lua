-------------------------------------------------------
-- 绘制矩形
-------------------------------------------------------
function drawRect(mode, x, y, width, height, color)
    local r, g, b, a = love.graphics.getColor()
    color = color or {r=255, g=255, b=255, a=255}
    love.graphics.setColor(color.r, color.g, color.b, color.a)
    love.graphics.rectangle( mode, x, y, width, height, rx, ry)
    love.graphics.setColor(r, g, b, a)
end

-------------------------------------------------------
-- @function: 打印table的内容，递归
-- @param: tbl 要打印的table
-- @param: level 递归的层数，默认不用传值进来
-- @param: filteDefault 是否过滤打印构造函数，默认为是
-- @return: return
-------------------------------------------------------
function printt( tbl , level, filteDefault)
  local msg = ""
  filteDefault = filteDefault or true --默认过滤关键字（DeleteMe, _class_type）
  level = level or 1
  local indent_str = ""
  for i = 1, level do
    indent_str = indent_str.."  "
  end

  print(indent_str .. "{")
  for k,v in pairs(tbl) do
    if filteDefault then
      if k ~= "_class_type" and k ~= "DeleteMe" then
        local item_str = string.format("%s%s = %s", indent_str .. " ",tostring(k), tostring(v))
        print(item_str)
        if type(v) == "table" then
          printt(v, level + 1)
        end
      end
    else
      local item_str = string.format("%s%s = %s", indent_str .. " ",tostring(k), tostring(v))
      print(item_str)
      if type(v) == "table" then
        printt(v, level + 1)
      end
    end
  end
  print(indent_str .. "}")
end

-------------------------------------------------------
-- 添加闪烁组件
-- 应当废弃此方法，废弃后使用class关键字手动添加
-------------------------------------------------------
function addFlash(e, time)
    if not e then
        print('fuck! the entity is null!')
        return
    end
    
    if e['flash'] then
        print('you have a flash component')
    end

    e['flash'] = {
        isShow = true,
        curShowTime = 0,
        time = time
    }
end

-------------------------------------------------------
-- 排序对象
-------------------------------------------------------
SortFunc = class("SortFunc")
function SortFunc:init()
  self.list = {}
end

function SortFunc:add(func, index)
  table.insert(self.list, {
    index = index,
    func = func
  })
end

function SortFunc:clear()
  self.list = {}
end

function SortFunc:sort(isUp)
  table.sort(self.list, function(a, b)
    if isUp then
      return a.index > b.index
    else
      return a.index < b.index
    end
  end)
end

function SortFunc:call()
  for i=1, #(self.list) do
    self.list[i].func()
  end
end

-------------------------------------------------------
-- 类似js中bind函数
-------------------------------------------------------
function bind(func, targer)
  return function(...)
    func(targer, ...)
  end
end

function newImage(...)
    local img = love.graphics.newImage(...)
    img:setFilter("nearest")
    return img
end