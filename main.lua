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

local scenes = {}

L = {}

L.actors = {}
L.scene = nil

L.maxFPS = 0

require 'console'

L.screen = {}
local w, h, m = love.window.getMode()
L.screen.w = w
L.screen.h = h

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

function L.getActorById(id)
    for i, v in ipairs(L.actors) do
        if v.__id == id then
            return v, i
        end
    end
    return nil
end

function L.destroyActor(id)
    local act, ind = L.getActorById(id)

    if act == nil then
        error(string.format('Actor %s is not in actor list. This actor may not exist! Are you trying to destroy the scene?', id))
    end

    if act.__destroy then
        act:__destroy()
    end

    table.remove(L.actors, ind)
end

function L.printf(fmt, ...)
    local va = {...}
    local text = string.format(fmt, unpack(va))
    L.cprint(text)
end

function L.switchScene(sceneName)
    if L.scene then
        if L.scene.__unload then
            L.scene:__unload(sceneName)
        end
    end

    if not scenes[sceneName] then
        error(string.format('No scene named %s!', sceneName))
    end

    L.actors = {}

    local sc = scenes[sceneName]
    sc.__noregister = true

    local e = sc()
    L.scene = e

    L.printf('Entered scene %s - %s', sceneName, e.__id)
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

    if L.scene and L.scene[event] then
        L.scene[event](L.scene, unpack(va))
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
        L.console.draw()
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
        L.console.buffer = L.console.buffer .. t
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
        L.console.buffer = ''
        return
    end

    if L.console.active then
        L.console.keypress(k)
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
        L.console.scrollback = math.clamp(L.console.scrollback + y, 0, L.console.scrollbackClamp)
    end
end

function love.resize(w, h)
    L.screen.w = w
    L.screen.h = h
end