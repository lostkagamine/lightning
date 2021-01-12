UIButtonActor = PositionalActor {
    __init = function(self, x, y, w, h, text, callback)
        self:move(x, y)
        self.w, self.h = w, h
        self.text = text
        self.callback = callback
        self.pressTimer = 0
    end,
    __draw = function(self)
        local font = L.console.font

        love.graphics.setFont(font)
        if self.pressTimer > 0 then
            love.graphics.setColor(0.1, 0.1, 0.1, 1)
        else
            love.graphics.setColor(0.25, 0.25, 0.25, 1)
        end
        love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
        love.graphics.setColor(1, 1, 1, 1)
        local tx = (self.x + (self.w / 2)) - (font:getWidth(self.text)/2)
        local ty = (self.y + (self.h / 2)) - (font:getHeight(self.text)/2)
        love.graphics.print(self.text, tx, ty)
    end,
    __mousedown = function(self, x, y, btn, t, p)
        local right = self.x + self.w
        local down = self.y + self.h
        if x >= self.x and y >= self.y and
           x <= right and y <= down then
            self.callback()
            self.pressTimer = 0.25
        end
    end,
    __update = function(self, dt)
        self.pressTimer = math.max(self.pressTimer-dt, 0)
    end
}