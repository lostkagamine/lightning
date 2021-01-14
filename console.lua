local utf8 = require 'utf8'
local inspect = require 'lib/inspect'

L.console = {}
L.console.active = false
L.console.font = love.graphics.newFont('resource/font.ttf', 32)

L.console.height = 250
L.console.cursor = true
L.console.cursorTimer = 0
L.console.blinkInterval = 0.5

L.console.buffer = ''
L.console.history = {}
L.console.scrollback = 0
L.console.scrollbackClamp = 0

L.console.argumentTransformers = {
    string = function(arg) return arg end,
    number = function(arg) return tonumber(arg) end
}

L.console.commands = {
    help = {
        description = 'Lists and provides help with commands.',
        arguments = {
            command = 'string?'
        },
        execute = function(command)
            local function formatArgumentInfo(name, type)
                if string.ends(type, '?') then
                    return '[' .. name .. ':' .. utf8.sub(type, 1, #type - 1) .. ']'
                else
                    return '<' .. name .. ':' .. type .. '>'
                end
            end

            if command == nil then
                local commandList = 'Commands:\n'

                for command, commandObj in pairs(L.console.commands) do
                    commandList = commandList .. command
                    if commandObj.arguments ~= nil then
                        commandList = commandList .. ' %[ddddddff]('
                        local formattedArgs = {}
                        for n, t in pairs(commandObj.arguments) do
                            table.insert(formattedArgs, formatArgumentInfo(n, t))
                        end
                        commandList = commandList .. table.concat(formattedArgs, ' ') .. ')'
                    end
                    commandList = commandList .. ' -> ' .. commandObj.description
                end

                L.cprint(commandList)
            else
                local cmd = L.console.commands[command]
                if cmd ~= nil then
                    local formattedArgs = {}
                    for n, t in pairs(cmd.arguments) do
                        table.insert(formattedArgs, formatArgumentInfo(n, t))
                    end
                    syntax = table.concat(formattedArgs, ' ')
                    L.cprint('Help for ' .. command .. ':\n' .. cmd.description .. '\nUsage: :' .. command .. ' ' .. syntax)
                else
                    L.cprint('Cannot retrieve help for non-existent command ' .. command .. '.')
                end
            end
        end
    }
}

function L.cprint(t)
    if type(t) ~= 'string' then
        t = inspect(t)
    end

    table.insert(L.console.history, t)
    print(t)
end

function L.console.clear()
    L.console.history = {}
end

function L.console.keypress(k)
    if k == 'backspace' then
        local byteoffset = utf8.offset(L.console.buffer, -1)

        if byteoffset then
            L.console.buffer = string.sub(L.console.buffer, 1, byteoffset - 1)
        end
    end

    if k == 'return' then
        L.cprint('] '..L.console.buffer)

        if string.starts(L.console.buffer, ':') then
            -- process as command
            local raw = utf8.sub(L.console.buffer, 2)
            local args = {}
            for i in raw:gmatch('%S+') do
                table.insert(args, i)
            end
            local command = table.remove(args, 1)

            local commandObj = L.console.commands[command]
            if commandObj then
                if commandObj.arguments then
                    local transformedArguments = {}
                    local argumentPointer = 1
                    for name, type in pairs(commandObj.arguments) do
                        if string.ends(type, '?') then
                            if not args[argumentPointer] then break end -- stop after first unfulfilled optional

                            type = string.sub(type, 1, #type - 1)
                        end

                        if not L.console.argumentTransformers[type] then
                            L.cprint('unknown argument transformer: ' .. type)
                            goto continue
                        end

                        ok, res = pcall(function() return L.console.argumentTransformers[type](args[argumentPointer]) end)

                        if not ok then
                            L.cprint('failed to transform argument for ' .. name .. ':' .. type)
                            break
                        end

                        table.insert(transformedArguments, res)
                        ::continue::
                        argumentPointer = argumentPointer + 1
                    end

                    xpcall(function() commandObj.execute(unpack(transformedArguments)) end, function(err)
                        L.cprint(debug.traceback(err))
                    end)
                else
                    xpcall(function() commandObj.execute() end, function(err)
                        L.cprint(debug.traceback(err))
                    end)
                end
            else
                L.cprint('Unknown command: ' .. command)
            end
            L.console.buffer = ''
            return
        end

        local fn, ler = loadstring(L.console.buffer)
        if not fn then
            L.cprint(ler)
        else
            local ok, er = pcall(function()
                local res = fn()
                if res then
                    L.cprint(res)
                end
            end)
            if not ok then
                L.cprint(er)
            end
        end

        L.console.buffer = ''
    end
    return
end

function L.console.draw()
    love.graphics.setFont(L.console.font)

    local conspad = 30
    local bw, bh = L.screen.w-(conspad*2), L.console.height-(conspad*2)

    local baseheight = L.console.font:getHeight("a")
    local basewidth = L.console.font:getWidth("a")
    local maxchars = math.floor(bh/baseheight)

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle('fill', 0, 0, L.screen.w, L.screen.h)
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle('fill', 0, 0, L.screen.w, L.console.height)

    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.print(string.format('Lightning Framework Developer Console v. %s - %dfps', _LIGHTNING_VERSION, love.timer.getFPS()), conspad, L.screen.h - (conspad*1.5))

    local alllines = {}
    for i, j in ipairs(L.console.history) do
        local _, wt = L.console.font:getWrap(j, bw)
        for k, l in ipairs(wt) do
            table.insert(alllines, l)
        end
    end
    local linecount = #alllines
    local constart = math.max(1, ((linecount-maxchars)+2)-math.max(L.console.scrollback, 0))
    L.console.scrollbackClamp = math.max(0, linecount-(maxchars-2))

    love.graphics.setColor(1, 1, 1, 1)

    local m = 0
    local conend = constart+(maxchars-2)
    for i, j in ipairs(table.trim(alllines, constart, conend)) do
        love.graphics.print(j, conspad, baseheight*i)
    end

    local append = ''
    if L.console.cursor then
        append = '_'
    end

    love.graphics.print('] '..L.console.buffer..append, conspad, bh)
end