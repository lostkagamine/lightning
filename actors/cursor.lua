CursorActor = PositionalActor {
    __init = function(self, col, rad)
        love.mouse.setVisible(false)
        self.col = col or {1, 1, 1, 1}
        self.rad = rad or 10
    end,
    __draw = function(self)
        love.graphics.setColor(unpack(self.col))
        love.graphics.circle('fill', self.x, self.y, self.rad)
    end,
    __mousemoved = function(self, x, y, dx, dy, t)
        self:move(x, y)
    end,
    __destroy = function(self)
        L.printf('cursor destroyed')
        love.mouse.setVisible(true)
    end
}