return LightningActor {
    __init = function(self)
        L.cprint('default scene Actor init')

        UILabelActor(100, 105, 'This is a UIButtonActor -->')

        UIButtonActor(430, 100, 100, 40, 'testing', function()
            L.cprint('h')
        end)

        UILabelActor(100, 200, string.format('You can open the LFW console by pressing [%s]!', string.upper(_CONSOLE_KEY)))

        CursorActor()
    end
}