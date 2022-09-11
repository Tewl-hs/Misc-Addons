_addon.name = 'Auto Ward (Beta)'
_addon.author = 'Tewl'
_addon.version = '1.0'
_addon.description = 'Cycles through a list of SMN bloodpact wards'
_addon.commands = {'aw'}

autoward = false; -- off by default
use_apogee = true; -- use apogee if its up?

delay = os.clock(); -- don't change
busy = false; -- don't change
pet_busy = false; -- don't change
last_bp = nil; -- don't change
next_bp = 1; -- don't change

wards = {
    -- Feel free to edit existing or 
    -- to add more folow the format below
    -- {"Avatar Name", "BloodPactWard"}, 
    {"Garuda", "Hastega II"},
    {"Ifrit", "Crimson Howl"},
    {"Shiva", "Crystal Blessing"},
    {"Fenrir", "Ecliptic Growl"},
    {"Fenrir", "Ecliptic Howl"},
};

windower.register_event('addon command', function(command, ...)
    if command:lower() == "on" then
        autoward = true;
        windower.add_to_chat(7, 'AutoWard: Enabled')
    elseif command:lower() == "off" then
        autoward = false;
        windower.add_to_chat(7, 'AutoWard: Disabled')
    end
end)

function ProcessNextWard()
    delay = os.clock() + 3; 
    if not busy then
        local pet = nil;
        if windower.ffxi.get_mob_by_target('pet') then
            pet = windower.ffxi.get_mob_by_target('pet').name;
        end
        if wards[next_bp][1] == pet then
            local apo = windower.ffxi.get_ability_recasts()[108];
            if use_apogee and apo == 0 then
                windower.chat.input('/ja Apogee <me>');
                delay = os.clock() + 1.2;
            else
                local r = windower.ffxi.get_ability_recasts()[174];
                if r == 0 then
                    windower.chat.input('/ja "'..wards[next_bp][2]..'" <me>');
                else
                    delay = os.clock() + r;
                end
            end
        elseif pet == nil then
            delay = os.clock() + 10;
            windower.chat.input('/ma "'..wards[next_bp][1]..'" <me>');
        else
            windower.chat.input('/ja "Release" <me>');
        end
    end
end

windower.register_event('action', function (data)
    if autoward == true then
        local playerID = windower.ffxi.get_player().id;
        local petIndex = windower.ffxi.get_mob_by_id(playerID).pet_index;
        local mob = windower.ffxi.get_mob_by_id(data.actor_id);
        if data.actor_id == playerID then
            if data.category == 12 then -- ranged attack begin
                busy = true;
                if data.param == 28787 then -- interrupted
                    busy = false;
                end
            elseif data.category == 2 then --  ranged attack end
                busy = false;
            elseif data.category == 4 then -- casting magic end
                busy = false;
                delay = os.clock() + 3;
            elseif data.category == 6 then -- job ability
                busy = false;
            elseif data.category == 7 then -- weaponskill begin
                busy = true;
                if data.param == 28787 then
                    busy = false; -- interrupted
                end
            elseif data.category == 3 then -- weaponskill end
                busy = false;
            elseif data.category == 9 then -- using item begin
                busy = true;
                if data.param == 28787 then
                    busy = false; -- interrupted
                end
            elseif data.category == 5 then -- using item end
                busy = false;
            elseif data.category == 8 then -- casting magic begin
                busy = true;
                if data.param == 28787 then
                    busy = false; -- interrupted
                end
            end
        elseif mob.index == petIndex then
            if data.category == 7 then -- pet ability
                pet_busy = true;
                if data.param == 28787 then
                    pet_busy = false; -- interrupted
                end
            elseif data.category == 13 then -- pet ability finished  
                pet_busy = false;
                last_bp = next_bp;
                next_bp = last_bp + 1;
                if next_bp > table.getn(wards) then next_bp = 1; end
                if pet ~= wards[next_bp][1] then
                    windower.chat.input('/ja "Release" <me>');
                end
                delay = os.clock() +  windower.ffxi.get_ability_recasts()[174];
            end
        end
    end
end)

windower.register_event('prerender', function()
    if not (os.clock() > delay) then return end
    if autoward == true and busy ~= true then ProcessNextWard() end
end)