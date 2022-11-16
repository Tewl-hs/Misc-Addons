--[[
        Currency.lua - Displays specified currency values across top of game.
        Currently currencies must be manually specific starting at line: 111
        Uncomment a currency to add it display or comment out the line to take it out. (Comments are the two dashes preceeding the line)
        I only added the currencies I felt were important but if there is something you want added you can ask me or check the fields.lua
--]]
_addon.name     = "Currency"
_addon.author   = "Tewl"
_addon.version  = "0.3.3"
_addon.command  = "cur"

require 'tables'
require 'actions'
require 'pack'

res         = require 'resources'
packets     = require 'packets'
config      = require 'config'
              require 'lists'
texts       = require('texts')

currencies = { }

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
    if curBox then curBox:destroy() end
    curBox = texts.new({flags = {draggable=false}}) -- If you want to be able to move the text change this line to: curBox = texts.new()
	curBox:pos(0,0) -- X,Y coordinates for where the text will appear on load, default 0,0 is top left
	curBox:font('Arial')
    curBox:size(10)
	curBox:bold(true)
    curBox:bg_alpha(0)
	curBox:right_justified(false)
	curBox:stroke_width(2)
    curBox:stroke_transparency(192)
    if player then
      windower.packets.inject_outgoing(0x10F, '0000') -- Request Currencies 1
    end
end)

windower.register_event('login', function()
    local player = windower.ffxi.get_player()
    if player then
        windower.packets.inject_outgoing(0x10F, '0000') -- Request Currencies 1
    end
end)

windower.register_event('zone change', function(new, old)
    windower.packets.inject_outgoing(0x10F, '0000') -- Request Currencies 1
end)

windower.register_event('incoming chunk',function (id,original,modified,is_injected,is_blocked)
    if id == 0x61 then
        currencies["Accolades"] = math.floor(original:byte(0x5A)/4) + original:byte(0x5B)*2^6 + original:byte(0x5C)*2^14
        update_currency()
    end

    if id == 0x110 then
        local p = packets.parse('incoming', original)
        currencies["Sparks"]  = p['Sparks Total']
        if p['_unknown1'] == 1 then currencies["Sparks"] = currencies["Sparks"] + 65536  end
        update_currency()
    end

    if id == 0x2D then
        local am = {}
        am.actor_id = original:unpack("I",0x05)
        am.target_id = original:unpack("I",0x09)
        am.param_1 = original:unpack("I",0x0D)
        am.param_2 = original:unpack("H",0x11)%2^9 -- First 7 bits
        am.param_3 = math.floor(original:unpack("I",0x11)/2^5) -- Rest
        am.actor_index = original:unpack("H",0x15)
        am.target_index = original:unpack("H",0x17)
        am.message_id = original:unpack("H",0x19)%2^15 -- Cut off the most significant bit
        
        if T{692,694,707,741}:contains(am.message_id) then
            if am.message_id == 692 then currencies["Sparks"] = currencies["Sparks"] + am.param_2 end
            if am.message_id == 694 then currencies["Sparks"] = currencies["Sparks"] + am.param_2 end
            if am.message_id == 707 then currencies["Sparks"] = currencies["Sparks"] + am.param_2 end
            if am.message_id == 741 then currencies["Accolades"] = currencies["Accolades"] + am.param_2 end
            if currencies["Sparks"] > 99999 then currencies["Sparks"] = 99999 end
            if currencies["Accolades"] > 99999 then currencies["Accolades"] = 99999 end
            update_currency()
        end
    end

    if id == 0x113 then -- Currencies 1
        local p = packets.parse('incoming', original)
        currencies["Sparks"]            		        = p["Sparks of Eminence"]
        currencies["Deeds"]				                = p["Deeds"]
        currencies["Tokens"]				            = p["Nyzul Tokens"]
        currencies["Zeni"]				                = p["Zeni"]
        currencies["Ichor"]     			            = p["Therion Ichor"]
        currencies["Accolades"]     			        = p["Unity Accolades"]
        currencies["Login Points"]			            = p["Login Points"]
        windower.packets.inject_outgoing(0x115, '0000') -- Request Currencies 2
    end

    if id == 0x118 then -- Currencies 2
        local p = packets.parse('incoming', original)
        currencies["Imprimaturs"]				        = p['Coalition Imprimaturs']
        currencies["Canteens"]          		        = p['Mystical Canteens']
        currencies["Plasm"]					            = p['Mweya Plasm Corpuscles'] 
        currencies["Beads"]					            = p['Escha Beads'] 
        currencies["Hallmarks"]				            = p['Hallmarks']
        currencies["Gallantry"]				            = p['Badges of Gallantry']
        currencies["Silver Voucher"]			        = p['Silver A.M.A.N. Vouchers Stored'] 
        currencies["Segments"]				            = p['Mog Segments']
        currencies["Gallimaufry"]				        = p['Gallimaufry'] 
        --------------------------------------------------------------------------
        -- Calculate difference in segments after leaving odyssey. 
        -- Same for Gallimaufry when zoning back into Kamihr Drifts 
        --------------------------------------------------------------------------        
        if last_segs == nil then last_segs = currencies["Segments"] end -- On load set to first detected value
        if last_galli == nil then last_galli = currencies["Gallimaufry"] end -- On load set to first detected value

        local zone = windower.ffxi.get_info().zone -- Current zone
        if zone == 247 and (last_zone == 298 or last_zone == 279) then -- If zoning into Rabao from Odyssey
            local segs = currencies["Segments"] - last_segs
            windower.add_to_chat(7,"Segment gain: "..segs.." | Total: "..currencies["Segments"]) -- Report Total Segments
        end
        if zone == 267 and (last_zone ==  275 or last_zone == 133) then
            local galli = currencies["Gallimaufry"] - last_galli 
            windower.add_to_chat(7,"Gallimaufry gain: "..galli.." | Total: "..currencies["Gallimaufry"]) -- Difference/Report Total Gallimaufry
        end
        last_zone = zone -- Record zone for tracking
        if zone ~= 275 or zone ~= 133 then last_galli = currencies["Gallimaufry"] end
        if zone ~= 298 or zone ~= 279 then last_segs = currencies["Segments"] end -- Update segment total if not inside Odyssey
        --------------------------------------------------------------------------
        update_currency()
    end

    if id == 0x00A and curBox then
        curBox:show()
    end
end)

windower.register_event('outgoing chunk', function(id, data)
    if id == 0x00D and curBox then
        curBox:hide()
    end
end)

function update_currency()
	local spc = '    '
    curBox:clear()
    curBox:append(spc)
    table.sort(currencies)
    for k,v in pairsByKeys(currencies) do
        curBox:append(string.format("%s %s:%s %s", '\\cs(255,255,255)', k, '\\cs(140,160,255)', v))
        curBox:append(spc)
    end
	curBox:append(spc)
    curBox:show()
end

function pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0 
    local iter = function ()
      i = i + 1
      if a[i] == nil then return nil
      else return a[i], t[a[i]]
      end
    end
    return iter
end