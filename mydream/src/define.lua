-- 常量宏定义
SHOW_FPS = true
SHOW_GRID = true
DEBUG_AABB = true
FULL_SCREEN = false
DESIGN_WIDTH = 800
DESIGN_HEIGHT = 600

-- 碰撞类型
ColsType = {
    None = 0,
    Hero = 1,
    Monster = 2,
    Wall = 3
}

-- 状态类型
StateType = {
    None = "none",
    Run = "run",
    Stand = "stand",
    Died = "died",

    Hurt = "hurt", -- 受伤
    HitFly = "hitFly", -- 击飞
}

-- 方向类型
DirType = {
    None = "none",
    Up = "up",
    RightUp = "rightUp",
    Right = "right",
    RightDown = "rightDown",
    Down = "down",
    LeftDown = "leftDown",
    Left = "left",
    LeftUp = "leftUp"
}

-- 层级类型
LayerType = {
    Floor = 1,
    Core = 2,
    Light = 3
}