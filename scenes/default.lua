return LightningActor {
    __init = function(self)
        print('default scene Actor init')
        CursorActor()
        self.tests = 0
    end,
    __keydown = function(self, k, sc, r)
        if k == 'g' then
            self.tests = self.tests + 1
            L.cprint('test '..self.tests)
        end
    end
}