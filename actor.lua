local inspect = require 'lib/inspect'

function LightningActor(tbl)
    local t = deepcopy(tbl)

    setmetatable(t, {
        __call = function(self, ...)
            local va = {...}
            local ns = deepcopy(self)

            if ns.__super then
                ns.__super(ns, unpack(va))
            end
            if ns.__init then
                ns.__init(ns, unpack(va))
            end

            L.registerActor(ns)
        end
    })

    return t
end

function ActorDefinition(tbl)
    return function(innertbl)
        local e = tbl.__init
        local v = mergetables(tbl, innertbl)
        if e then
            v.__super = e
        end
        if innertbl.__init then
            v.__init = innertbl.__init
        end
        local a = LightningActor(v)
        return a
    end
end

PositionalActor = ActorDefinition {
    __init = function(self)
        self.x = 0
        self.y = 0
    end,
    __draw = function(self)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle('fill', self.x, self.y, 50, 50)
    end,
    move = function(self, x, y)
        self.x = x
        self.y = y
    end
}