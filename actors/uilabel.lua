UILabelActor = PositionalActor {
    __init = function(self, x, y, text)
        self:move(x, y)
        self.text = text
    end,
    __draw = function(self)
        local font = L.console.font
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(self.text, self.x, self.y)
    end
}