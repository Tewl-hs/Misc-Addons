--[[
    I think there is a better version out that someone else release.
    This one is pretty basic just text percentages instead of a hp bar
    To use, target something then press WIN+F to set the focus target, to change focus just do the same while targeting new target
    The foucs target will clear if you press WIN+F while not targeting anything or run 50 yalms from the target
]]
_addon.name = 'FocusTarget'
_addon.author = 'Tewl'
_addon.version = '1.0'
_addon.language = 'English'
_addon.commands = {'focustarget','ft'}

require('luau')
texts = require('texts')

ftarget = nil

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

FocusBox = texts.new(settings.display, settings)

Colors = {
    Yellow = '\\cs(255,192,0)',
    Red = '\\cs(255,80,80)',
    Green = '\\cs(110,255,110)',
    Blue = '\\cs(140,160,255)',
    Gray = '\\cs(96,96,96)',
    White = '\\cs(255,255,255)'
}

initialize = function(text, settings)
    local mob = nil
    if ftarget ~= nil then mob = windower.ffxi.get_mob_by_id(ftarget) or nil end
    local ftext = L{}

    ftext:append('[${color}${target_name} : ${target_hpp}'..Colors.White..'][${dcolor}${target_distance||%.2f}'..Colors.White..']')

    FocusBox:clear()
    FocusBox:append(ftext:concat('\n'))
    FocusBox:hide()
end

FocusBox:register_event('reload', initialize)

windower.register_event('load', function()
    windower.send_command("bind @f focustarget")
end)

windower.register_event('unload',function()
	windower.send_command('unbind @f')
end)

windower.register_event('prerender', function (...) 
    local mob = nil
    if ftarget ~= nil then mob = windower.ffxi.get_mob_by_id(ftarget) or nil end
    local ftext = {}

    if mob and mob.id > 0 then
        if mob.hpp > 0 and mob.distance:sqrt() < 50 then
            ftext.color = Colors.Green
            ftext.dcolor = Colors.Blue
            if mob.hpp < 76 then ftext.color = Colors.Yellow end
            if mob.hpp < 11 then ftext.color = Colors.Red end
            ftext.target_name = mob.name
            ftext.target_hpp = mob.hpp.."%"
            ftext.target_distance = mob.distance:sqrt()
            FocusBox:update(ftext)
            FocusBox:show()
        else
            ftarget = nil
            FocusBox:hide()
        end
    end
end)

windower.register_event('addon command', function(...)
    local ftext = {}
    local mob = windower.ffxi.get_mob_by_target('t')
    if mob and mob.id > 0 then
        if mob.hpp > 0 and mob.distance:sqrt() < 50 then
            ftarget = mob.id
            ftext.color = Colors.Green
            ftext.dcolor = Colors.Blue
            if mob.hpp < 76 then ftext.color = Colors.Yellow end
            if mob.hpp < 11 then ftext.color = Colors.Red end
            ftext.target_name = mob.name
            ftext.target_hpp = mob.hpp.."%"
            ftext.target_distance = mob.distance:sqrt()
            windower.add_to_chat(8,'Focus target set to: '..mob.name)
            FocusBox:update(ftext)
            FocusBox:show()
        else
            ftarget = nil
            FocusBox:hide()
        end
    else
        windower.add_to_chat(8,'Focus target cleared!')
        ftarget = nil
        FocusBox:hide()
    end
end)

windower.register_event('zone change',function(new, old)
    ftarget = nil
    FocusBox:hide()   
end)