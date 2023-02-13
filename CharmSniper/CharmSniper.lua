--
-- This is a very basic script, I did not add in checks for status effects on self or if you have access to the weaponsklill
-- It was written mostly for a laugh to kill people who get charmed in dynamis.
--   
_addon.name     = "CharmSniper"
_addon.author   = "Tewl"
_addon.version  = "0.5"
_addon.command  = "csnipe"

local res     = require("resources")
local packets = require("packets")
                require("strings")
                require("lists")
                require("tables")

local weaponskill = 'Namas Arrow'
local range = 12

windower.register_event('action',function (act)
	local actor = windower.ffxi.get_mob_by_id(act.actor_id)		
	local self = windower.ffxi.get_player()
	local category = act.category  
	local param = act.param 
	local targets = act.targets
	local target = windower.ffxi.get_mob_by_id(targets[1].id)
	if actor and actor.is_npc then 
		if category == 11 then
			if res.monster_abilities[param] then
				ability = res.monster_abilities[param].en
				if ability == 'Charm' and target.name ~= self.name then
					if target.charmed == true then
						windower.send_command('input /p ['..ability..'] '..target.name..' <call21>')
						
						if self.vitals.tp > 999 and self.vitals.hpp > 0 and target.distance <= range then -- Make sure alive and enough tp and target is within the range value
							face_target(target) -- Look at the target

							-- Engage target -- This part really isnt necessary. Just engages/swaps to the target.
							if self.status == 'Engaged' then -- Switch to target
								local packet = packets.new('outgoing', 0x01A, {
									['Target']=target.id,
									['Target Index']=target.index,
									['Category']=15
								})
								packets.inject(packet)
							else -- Engaged target
								local packet = packets.new('outgoing', 0x01A, {
									['Target']=target.id,
									['Target Index']=target.index,
									['Category']=2
								})
								packets.inject(packet)
							end
							--- End of Engaged --

							-- Have a 1 second delay on weaponskill for latency in dynamis
							-- You can try changing it if you feel its too long or not long enough
							windower.send_command('wait 1.0;input /ws "'..weaponskill..'" '..target.id)
						end
					end
				end
			end
		end
	end
end)

function face_target(target)
    local vector = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().index or 0)
    local direction = (math.atan2((target.y - vector.y), (target.x - vector.x)) * 180/math.pi) * -1
    windower.ffxi.turn((direction):radian())
end