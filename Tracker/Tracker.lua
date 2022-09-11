--[[
--  Scans for a specific monster to spawn then plays and alerts when pops/found.
--  Simply edit the name of the target on line 47 then (re)load this lua
--]]
_addon.name = 'Tracker'
_addon.author = 'Tewl'
_addon.version = '0.1'
_addon.language = 'English'
_addon.commands = {'track'}

require('luau')
texts = require('texts')

require('tables')
require('logger')
require('functions')
packets = require('packets')

config = require 'config'
file = require 'files'
res = require 'resources'

mob_id = nil

defaults = {}
defaults.display = {}
defaults.display.pos = {}
defaults.display.pos.x = 0
defaults.display.pos.y = 0
defaults.display.bg = {}
defaults.display.bg.alpha = 0
defaults.display.flags = {}
defaults.display.flags.bold = true
defaults.display.flags.right = false
defaults.display.text = {}
defaults.display.text.font = 'Arial'
defaults.display.text.size = 15
defaults.display.text.stroke = {}
defaults.display.text.stroke.width = 2
defaults.display.text.stroke.transparency = 192

settings = config.load(defaults)
settings:save()

TargetBox = texts.new(settings.display, settings)

Target = 'Sisyphus'

Colors = {
    Yellow = '\\cs(255,192,0)',
    Red = '\\cs(255,80,80)',
    Green = '\\cs(110,255,110)',
    Blue = '\\cs(140,160,255)',
    Gray = '\\cs(96,96,96)',
    White = '\\cs(255,255,255)'
}

initialize = function(text, settings)
    local mob = windower.ffxi.get_mob_by_name(Target) or nil
    local ftext = L{}

    ftext:append('[${color}${target_name} : ${target_distance||%.2f}'..Colors.White..']')

    TargetBox:clear()
    TargetBox:append(ftext:concat('\n'))
    TargetBox:hide()
end

TargetBox:register_event('reload', initialize)

windower.register_event('prerender', function (...) 
    local mob = windower.ffxi.get_mob_by_name(Target) or nil
    local ftext = {}

    if mob ~= nil and mob.hpp > 0 then
        ftext.color = Colors.Green
        ftext.target_name = mob.name
        ftext.target_distance = mob.distance:sqrt()
        TargetBox:update(ftext)
        if mob_id ~= mob.id then
            mob_id = mob.id
            windower.add_to_chat(55,'==> '..mob.name..' POP!')
            windower.play_sound(windower.addon_path .. 'chime.wav')
            face_target(mob) -- Face the mob
            if math.sqrt(mob.distance) <= 40 then -- Target the mob
                local player = windower.ffxi.get_player()
		        packets.inject(packets.new('incoming', 0x058, {
			        ['Player'] = player.id,
			        ['Target'] = mob.id,
			        ['Player Index'] = player.index,
		        }))

                if math.sqrt(mob.distance) <= 16 then
                    --windower.send_command('wait 0.5;input /ja Provoke <t>')
                end
            end
        end
        TargetBox:show()
    else
        mob_id = nil
        TargetBox:hide()
    end
end)

windower.register_event('load', function()
    log('Scanning for '..Target)
end)

windower.register_event('zone change',function(new, old)
    mob_id = nil
    TargetBox:hide()  
end)

function face_target(target)
    local vector = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().index or 0)
    local direction = (math.atan2((target.y - vector.y), (target.x - vector.x)) * 180/math.pi) * -1
    windower.ffxi.turn((direction):radian())
end