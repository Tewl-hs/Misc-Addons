--[[
	So this was made just as a joke to leaden people in Dynamis when they got charmed but I mainly use it to just call out when someone does get charmed.
	Read lines 33 and 53 if you wish for this to do more than just announce someone being charmed.
--]]
_addon.name     = "CharmSniper"
_addon.author   = "Tewl"
_addon.version  = "0.5"
_addon.command  = "csnipe"

local res     = require("resources")
local packets = require("packets")
                require("strings")
                require("lists")
                require("tables")
                require("logger")

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
				if ability == 'Charm' and target.name ~= self.name then -- if enemy uses charm ability on anyone but you
					-- Need to add check to make sure charm successful (Only works for party members)
					windower.send_command('input /p ['..ability..'] '..target.name..' <call21>')
					
					if self.vitals.tp > 999 and self.vitals.hpp > 0 then -- Make sure alive and enough tp
						-- Uncomment and edit the line below to face the target that has been charmed
						--face_target(target) -- Look at the target

						-- This part really isnt necessary. Just swaps to the target
						if self.status == 'Engaged' then -- Switch target
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
						
						-- Uncomment and edit the line below to the skill you wish to use on the target. If you are going to use this be sure to uncomment line 34 as well
						--windower.send_command('wait 1.0;input /ws "Namas Arrow" '..target.id)
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