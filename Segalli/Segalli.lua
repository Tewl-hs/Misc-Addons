--[[
--      !!! DON'T USE THIS WITH THE CURRENCY ADDON - IT DOES THE SAME THING !!! 
--      Install:
--          Put in Windower/Addons/Segalli then in game: //lua load segalli
--      Description:
--          Will report Gains to Segments and Gallimaufry
--          when exiting to Rabao and Kamhir Drifts respectively
--]] 
_addon.name     = "Segalli"
_addon.author   = "Tewl"
_addon.version  = "1.0"

packets     = require 'packets'

last_segs = nil
last_galli = nil
last_zone = nil

windower.register_event('addon command', function(command, ...)
    if command:lower() == "update" then
        windower.packets.inject_outgoing(0x10F, '0000') -- Request Currencies 1
    end
end)

windower.register_event('load', function()
    local player = windower.ffxi.get_player()
    if player then
        windower.packets.inject_outgoing(0x115, '0000') -- Request Currencies 2
    end
end)

windower.register_event('login', function()
    local player = windower.ffxi.get_player()
    if player then
        windower.packets.inject_outgoing(0x115, '0000') -- Request Currencies 2
    end
end)

windower.register_event('zone change', function(new, old)
    windower.packets.inject_outgoing(0x115, '0000') -- Request Currencies 2
end)

windower.register_event('incoming chunk',function (id,original,modified,is_injected,is_blocked)
    if id == 0x118 then -- Currencies 2
        local seg = math.floor(original:unpack("i",0x8C)/2^8)
        local gal = math.floor(original:unpack("i",0x90)/2^8)
        local zone = windower.ffxi.get_info().zone -- Current zone
        if last_segs == nil then last_segs = seg end -- On load set to first detected value
        if last_galli == nil then last_galli = gal end -- On load set to first detected value
        if zone == 247 and (last_zone == 298 or last_zone == 279) then -- If zoning into Rabao from Odyssey
            local segs = seg - last_segs
            windower.add_to_chat(7,"Segment gain: "..segs.." | Total: "..seg) -- Report Total Segments
        end
        if zone == 267 and last_zone ==  275 then
            local galli = gal - last_galli 
            windower.add_to_chat(7,"Gallimaufry gain: "..galli.." | Total: "..gal) -- Difference/Report Total Gallimaufry
        end
        last_zone = zone -- Record zone for tracking
        if zone ~= 275 then last_galli = gal end
        if zone ~= 298 or zone ~= 279 then last_segs = seg end -- Update segment total if not inside Odyssey
    end
end)