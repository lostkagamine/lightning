--[[
    Lightning Framework
    - a simple framework for Love2D applications -

    (c) 2021 Rin
]]

require 'util'
require 'actor'

_LIGHTNING_VERSION = "0.0.1"
_CONSOLE_ENABLED = true
_CONSOLE_KEY = 'f1'

local inspect = require 'lib/inspect'
local utf8 = require 'utf8'

local scenes = {}

L = {}

L.actors = {}
L.activeScene = nil

L.maxFPS = 0

L.console = {}
L.console.active = false
L.console.font = love.graphics.newFont('resource/font.ttf', 32)

L.console.height = 250
L.console.cursor = true
L.console.cursorTimer = 0
L.console.blinkInterval = 0.5

L.console.scrollback = 0

L.screen = {}
local w, h, m = love.window.getMode()
L.screen.w = w
L.screen.h = h

local consoleHistory = {}
local consoleBuffer = ''
local scrollbackClamp = 0
local previousMouseState = true

local next_time = 0

function L.screen.setResolution(w, h)
    local _, _, m = love.window.getMode()
    love.window.setMode(w, h, m)
    L.screen.w = w
    L.screen.h = h
end

function L.registerActor(act)
    table.insert(L.actors, act)
end

function L.printf(fmt, ...)
    local va = {...}
    local text = string.format(fmt, unpack(va))
    L.cprint(text)
end

function L.switchScene(sceneName)
    if L.activeScene then
        if L.activeScene.__unload then
            L.activeScene:__unload(sceneName)
        end
    end

    if not scenes[sceneName] then
        error(string.format('No scene named %s!', sceneName))
    end

    L.actors = {}

    local sc = scenes[sceneName]

    L.activeScene = sc()

    L.printf('Entered scene %s', sceneName)
end

function L.cprint(t)
    if type(t) ~= 'string' then
        t = inspect(t)
    end

    table.insert(consoleHistory, t)
    print(t)
end

function L.console.clear()
    consoleHistory = {}
end

function love.load()
    L.printf("-- Lightning Framework --\nVersion %s\nCreated by Rin, 2021", _LIGHTNING_VERSION)

    love.window.setTitle('Lightning Framework')

    local e = love.filesystem.getDirectoryItems('actors/')
    for _, i in ipairs(e) do
        if (love.filesystem.getInfo('actors/'..i, {type='file'})).type == 'file' then
            local h = i:sub(0, #i-4 --[[.lua]])
            require("./actors/"..h)
        end
    end

    local e = love.filesystem.getDirectoryItems('scenes/')
    for _, i in ipairs(e) do
        if (love.filesystem.getInfo('scenes/'..i, {type='file'})).type == 'file' then
            local h = i:sub(0, #i-4 --[[.lua]])
            scenes[h] = require("./scenes/"..h)
        end
    end



    L.switchScene('default')
end

local function dispatchToActors(event, ...)
    local va = {...}
    for k, v in ipairs(L.actors) do
        if v[event] then
            v[event](v, unpack(va))
        end
    end
end

function love.update(dt)
    dispatchToActors('__update', dt)

    if L.console.active then
        L.console.cursorTimer = L.console.cursorTimer + dt
        if L.console.cursorTimer > L.console.blinkInterval then
            L.console.cursor = not L.console.cursor
            L.console.cursorTimer = 0
        end
    end

    if L.maxFPS > 0 then
        next_time = next_time + 1/L.maxFPS
    end
end

function love.draw()
    dispatchToActors('__draw')

    if L.console.active then
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
        for i, j in ipairs(consoleHistory) do
            local _, wt = L.console.font:getWrap(j, bw)
            for k, l in ipairs(wt) do
                table.insert(alllines, l)
            end
        end
        local linecount = #alllines
        local constart = math.max(1, ((linecount-maxchars)+2)-math.max(L.console.scrollback, 0))
        scrollbackClamp = math.max(0, linecount-(maxchars-2))

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

        love.graphics.print('] '..consoleBuffer..append, conspad, bh)
    end

    if L.maxFPS > 0 then
        local current_time = love.timer.getTime()
        if next_time <= current_time then
            next_time = current_time
            return
        end
        love.timer.sleep(next_time - current_time)
    end
end

function love.textinput(t)
    if L.console.active then
        consoleBuffer = consoleBuffer .. t
    end
end

function love.keypressed(k, sc, r)
    if k == _CONSOLE_KEY and _CONSOLE_ENABLED then
        L.console.active = not L.console.active
        love.keyboard.setKeyRepeat(L.console.active)
        L.console.cursor = true
        L.console.cursorTimer = 0
        if not L.console.active then
            love.mouse.setVisible(previousMouseState)
        else
            previousMouseState = love.mouse.isVisible()
            love.mouse.setVisible(true)
        end
        consoleBuffer = ''
        return
    end

    if L.console.active then
        if k == 'backspace' then
            local byteoffset = utf8.offset(consoleBuffer, -1)
     
            if byteoffset then
                consoleBuffer = string.sub(consoleBuffer, 1, byteoffset - 1)
            end
        end

        if k == 'return' then
            L.cprint('] '..consoleBuffer)

            local fn, ler = loadstring(consoleBuffer)
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

            consoleBuffer = ''
        end
        return
    end

    dispatchToActors('__keydown', k, sc, r)
end

function love.keyreleased(k, sc)
    dispatchToActors('__keyup', k, sc)
end

function love.mousemoved(x, y, dx, dy)
    dispatchToActors('__mousemoved', x, y, dx, dy)
end

function love.mousepressed(x, y, b, t, p)
    dispatchToActors('__mousedown', x, y, b, t, p)
end

function love.mousereleased(x, y, b, t, p)
    dispatchToActors('__mouseup', x, y, b, t, p)
end

function love.wheelmoved(x, y)
    if L.console.active then
        L.console.scrollback = math.clamp(L.console.scrollback + y, 0, scrollbackClamp)
    end
end

function love.resize(w, h)
    L.screen.w = w
    L.screen.h = h
end