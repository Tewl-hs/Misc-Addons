--[[
    Only Command changes the name of the person to assist. (assist_target) Default is 'Tewl' change to w/e you like  (Line:25)
    Command:
        Change the name of playerr to assist: //qas target playername 
    Note:
        You must be running lua on all characters, the assisted character and the characters doing the assisting. (on the same machine)
        Currently testing: Auto-target assisting and forcing character to face target.
--]]

_addon.name = 'QuickAssist'
_addon.author = 'Tewl'
_addon.version = '0.5'
_addon.commands = {'qas'}

require('tables')
require('logger')
require('functions')
packets = require('packets')

config = require 'config'
file = require 'files'
res = require 'resources'

settings = T{}
defaults = T{assist_target='Tewl'} -- Tewl is the default name set when no value exists in the settings.xml Feel free to change it.

current_target = nil

windower.register_event('load',function()
	if debugging then windower.debug('load') end
    initialize()
    log('Currently assisting: '..settings.assist_target)
end)

windower.register_event('login',function (name)
	if debugging then windower.debug('login') end
end)

function initialize()
	settings = config.load(defaults)
	config.save(settings, 'global')
end

windower.register_event('addon command', function(input, ...)
    local args = {...}
    local cmd = string.lower(input)
    if cmd == 'target' then
        if args ~= nil then
            settings.assist_target = args[1]
            config.save(settings, 'global')
            log('Assist target set to: '..settings.assist_target)
            windower.send_ipc_message('reloadqas')
        else
            log('Missing target parameter! Example: //qas assist '..windower.ffxi.get_player().name)
        end
    else
        log('Unknown Command - '..cmd)
    end
end)

windower.register_event('outgoing chunk',function(id,data,modified,injected,blocked)
    if id == 0x01A then
        local p = packets.parse('outgoing', data)
        local player = windower.ffxi.get_player()
        if p["Category"] then
            if p["Category"] == 2 and player.name == settings.assist_target then -- Engaged Target
                windower.send_ipc_message('engage '..p["Target"])
                current_target = p["Target"]
            elseif p["Category"] == 4 and player.name == settings.assist_target then -- Disengaged Target
                windower.send_ipc_message('disengage')
                current_target = nil
            elseif p["Category"] == 15 and player.name == settings.assist_target then -- Manual Switch Target
                windower.send_ipc_message('changetarget '..p["Target"])
                current_target = p["Target"]
            end
        end
    end
end)
windower.register_event('incoming chunk',function(id,data,modified,injected,blocked)
    local player = windower.ffxi.get_player()
    if id == 0x058 then
        local p = packets.parse('incoming', data)
        local player = windower.ffxi.get_mob_by_id(p["Player"]) or nil
        if player and player.name == settings.assist_target and p["Target"] ~= current_target then
            windower.send_ipc_message('autotarget '..p["Target"])
            current_target = p["Target"]
        end
    end
end)

windower.register_event('ipc message', function(msg)
    local args = T(msg:split(' '))
    local cmd = args[1] or nil
    local player = windower.ffxi.get_player()

    if cmd == "reloadqas" then
        windower.send_command('input //lua r quickassist')
        return
    end

    if player.name ~= settings.assist_target then
        if cmd == 'disengage' then
            if player then
                local packet = packets.new('outgoing', 0x01A, {
                    ['Target']=player.id,
                    ['Target Index']=player.index,
                    ['Category']=4
                })
                packets.inject(packet)
                current_target = nil
            end
        elseif cmd == 'engage' then
            if args[2] then
                local target = windower.ffxi.get_mob_by_id(args[2])
                if target then 
                    face_target(target)
                    local packet = packets.new('outgoing', 0x01A, {
                        ['Target']=target.id,
                        ['Target Index']=target.index,
                        ['Category']=2
                    })
                    packets.inject(packet)
                end
            else
                log('Engaged - Missing Parameter')
            end
        elseif cmd == 'changetarget' then
            if args[2] then
                local target = windower.ffxi.get_mob_by_id(args[2])
                if target then 
                    face_target(target)
                    local packet = packets.new('outgoing', 0x01A, {
                        ['Target']=target.id,
                        ['Target Index']=target.index,
                        ['Category']=15
                    })
                    packets.inject(packet)
                end
            else
                log('Switch target - Missing Parameter')
            end
        elseif cmd == 'autotarget' then
            if args[2] then
                local target = windower.ffxi.get_mob_by_id(args[2])
                log('Autotarget: '..target.name..' ('..target.id..')')
                if target then 
                    face_target(target)
                    local packet = packets.new('outgoing', 0x01A, {
                        ['Target']=target.id,
                        ['Target Index']=target.index,
                        ['Category']=15
                    })
                    packets.inject(packet)
                end
            end
        else
            log('Unknown Command - '..cmd)
        end
    end
end)

function face_target(target)
    local vector = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().index or 0)
    local direction = (math.atan2((target.y - vector.y), (target.x - vector.x)) * 180/math.pi) * -1
    windower.ffxi.turn((direction):radian())
end