--======================================================================================================================
--[[
    Author: Ragnarok.Lorand
    GearSwap utility functions that are related to gear set building and manipulation
    
    
    TODO:
    
    - coroutine for keeping inventory table up to date 
        - run every 5-30 seconds (decide later)
        - keep mapping of item name or id to bag # & slot in that bag
            - if any changes were made to inventory, refresh table
            - store list of augments
        - should improve performance when combining sets while gear swapping
        - what's in inventory should not change very often in the field
    - improve error handling so that typos in item names don't cause an incomplete load
    
    
--]]
--======================================================================================================================

lor_gs_versions.set_operations = '2016-09-24.0'

setops = setops or {}
setops._set_res = {}
setops._item_res = S{}

local all_bag_names = S{'case','inventory','locker','sack','safe','safe2','satchel','storage','wardrobe','wardrobe2'}
local equip_bag_names = {'inventory', 'wardrobe', 'wardrobe2','wardrobe3','wardrobe4'}
--local bags = {[0]='inventory',[8]='wardrobe',[10]='wardrobe2',[11]='wardrobe3',[12]='wardrobe4'}
local bags_nonequippable = {'case','locker','sack','safe','safe2','satchel','storage'}
local aug_cache = {}
local nil_aug = string.parse_hex('00':rep(24))

_slots = {}
_slots.names = {
    ['main']       = {'main'},
    ['sub']        = {'sub'},
    ['range']      = {'range','ranged'},
    ['ammo']       = {'ammo'},
    ['head']       = {'head'},
    ['body']       = {'body'},
    ['hands']      = {'hands'},
    ['legs']       = {'legs'},
    ['feet']       = {'feet'},
    ['neck']       = {'neck'},
    ['waist']      = {'waist'},
    ['left_ear']   = {'ear1','left_ear','learring','lear'},
    ['right_ear']  = {'ear2','right_ear','rearring','rear'},
    ['left_ring']  = {'left_ring','lring','ring1'},
    ['right_ring'] = {'right_ring','rring','ring2'},
    ['back']       = {'back'},
    ['ammo2']      = {'ammo2'}  -- Not really valid, but core_components will pick this for weaponskills if it exists
}
_slots.name_list = comp('k for k,v in _slots.names')
_slots.variations_to_proper = table.expanded_invert(_slots.names)
_slots.improper_to_proper = comp('k:v for k,v in table.expanded_invert(_slots.names) if k ~= v')
_slots.all_name_variations = comp('k:true for k,v in table.expanded_invert(_slots.names)')


local function refresh_bag_contentsA(bag, index, id, count)
    atcfs('Inventory changed. Bag: %s, Index: %s, ID: %s, Count: %s':format(bag, index, id, count))
end


local function refresh_bag_contentsR(bag, index, id, count)
    atcfs('Inventory changed. Bag: %s, Index: %s, ID: %s, Count: %s':format(bag, index, id, count))
end


local function _res_for_item_name(name)
    if not name then return nil end
    return res.items:with('en', name) or res.items:with('enl', name:lower()) or setops._item_res:with('en_l',name:lower()) or setops._item_res:with('enl_l',name:lower())
end
local res_for_item_name = traceable(_res_for_item_name)


local function _add_to_set_res(name, augments)
    local iname,ires = name,{}
    if name ~= 'empty' then
        ires = res_for_item_name(name)
        if not ires then
            atc(123, 'ERROR Adding \'%s\' to setops._set_res':format(name))
            return
        end
        iname = ires.en
    end
    setops._set_res[iname] = setops._set_res[iname] or {}
    setops._set_res[iname].res = ires
    setops._set_res[iname].versions = setops._set_res[iname].versions or {}
    if (augments ~= nil) and (#augments > 0) then
        local found_match = false
        for _,version in pairs(setops._set_res[iname].versions) do
            if table.equals(augments, version) then
                found_match = true
                break
            end
        end
        if not found_match then
            table.insert(setops._set_res[iname].versions, augments)
        end
    end
end
--local _add_to_set_res = traceable(__add_to_set_res)


--[[
    For each key in set_table that is a valid slot name, move the value to be associated with the proper slot name key
    if it wasn't already, and make all items in the set formatted as a table with 'name' and 'augments' keys.
    For each key that is not a valid slot name, recurse using the table at that key.
--]]
local function _normalize(set_table)
    if set_table == nil then return end
    if type(set_table) == 'string' then atcfs(123,'Invalid arg to _normalize: %s',set_table) end
    local nested_keys = {}
    local slot_keys = {}
    --Build key lists - the table can't be modified while iterating through it
    for k, v in pairs(set_table) do
        local slot = _slots.variations_to_proper[k]
        if slot then
            if (type(v) == 'table') and table.intersects(_slots.name_list, table.keys(v)) then
                nested_keys[k] = true
            else
                slot_keys[k] = slot
            end
        else
            nested_keys[k] = true
        end
    end
    
    for vslot, cslot in pairs(slot_keys) do  --Variation name, correct name
        set_table[cslot] = set_table[cslot] or set_table[vslot]
        if cslot ~= vslot then
            set_table[vslot] = nil  --Remove entry for slot name variation
        end
        if type(set_table[cslot]) == 'string' then
            set_table[cslot] = {name=set_table[cslot], augments={}}
            _add_to_set_res(set_table[cslot].name, {})
        elseif type(set_table[cslot]) == 'table' then
            --If the value at a key that is a slot name is a table, and that table has a "name" key, then treat it as
            --an item, otherwise treat it as a list of options for that slot
            if set_table[cslot].name then
                set_table[cslot].augments = set_table[cslot].augments or {}
                _add_to_set_res(set_table[cslot].name, set_table[cslot].augments)
            else
                for i = 1, #set_table[cslot] do
                    if type(set_table[cslot][i]) == 'string' then
                        set_table[cslot][i] = {name=set_table[cslot][i], augments={}}
                    elseif type(set_table[cslot][i]) == 'table' then
                        if not set_table[cslot][i].name then
                            atcfs(123, 'ERROR: Invalid nested item in slot \'%s\' @ index %s', cslot, i)
                        end
                        set_table[cslot][i].augments = set_table[cslot][i].augments or {}
                    end
                    _add_to_set_res(set_table[cslot][i].name, set_table[cslot][i].augments)
                end
            end
        end
    end
    
    --Recurse for nested sets
    for nested_set,_ in pairs(nested_keys) do
        _normalize(set_table[nested_set])
    end
end
--local _normalize = traceable(__normalize)


function setops.init()
    if sets == nil then
        atc(123, 'ERROR: Unable to find any defined gear sets!')
        return
    end
    for id,tbl in pairs(res.items) do
        setops._item_res[id] = {id=id,en=tbl.en,enl=tbl.enl,en_l=tbl.en:lower(),enl_l=tbl.enl:lower()}
    end
    --Transform all sets to be uniform - this is an optimization to prevent lag-inducing operations on each gear swap
    _normalize(sets)
    
    --Register events that trigger on inventory change
    --winraw.register_event('add item', refresh_bag_contentsA)
    --winraw.register_event('remove item item', refresh_bag_contentsR)
end


--[[
    Overwrites the contents of the slots in set1 with the contents of the slots in set2.  Safe to use for setting the 
    contents of a parent set (such as sets.precast.FC) without affecting child sets (sets.precast.FC.Ninjutsu).  This
    function does not consider the usability/possession of items.  By default, if a slot in set2 is empty, the item in
    set1 will be retained.  Making strict true will cause empty slots in set2 to overwrite occupied slots in set1.
--]]
function safe_set(set1, set2, strict)
    if any_eq(nil, set1, set2) then return end
    _normalize(set1)
    _normalize(set2)
    for slot,_ in pairs(_slots.names) do
        if strict then
            set1[slot] = set2[slot]
        else
            set1[slot] = set2[slot] or set1[slot]
        end
    end
end


--local _expand_augments = function(item)
function setops.expand_augments(item)
    if item then
        item.augments = {}
        if item.extdata ~= nil_aug then
            local iaugs = extdata.decode(item).augments or {}
            for _,aug in pairs(iaugs) do
                if (#aug > 0) and (aug ~= 'none') then
                    local esc_aug = aug:gsub("'","\\'")
                    table.insert(item.augments, esc_aug)
                end
            end
        end
    end
    return item
end
--setops.expand_augments = traceable(_expand_augments)


function setops.expand_augments_in_bags(bag_list)
    local witems = windower.ffxi.get_items()
    local equippable = {}
    for _,bag_name in pairs(bag_list) do
        if witems[bag_name] then    --Assert player has bag unlocked
            for _,bagged_item in ipairs(witems[bag_name]) do
                if bagged_item then
                    bagged_item = setops.expand_augments(bagged_item)
                    bagged_item.bag_name = bag_name
                    equippable[bagged_item.id] = equippable[bagged_item.id] or {}
                    table.insert(equippable[bagged_item.id], bagged_item)
                end
            end
        end
    end
    return equippable
end


local function get_items_with_augments(bag_name, item_id)
    local _time = os.clock()
    if (not aug_cache._time) or ((_time - aug_cache._time) > 5) then
        aug_cache = {}
        aug_cache._time = _time
    end
    if not aug_cache[bag_name] then
        aug_cache[bag_name] = {}
        for _,item in ipairs(windower.ffxi.get_items()[bag_name]) do
            aug_cache[bag_name][item.id] = aug_cache[bag_name][item.id] or {}
            item = setops.expand_augments(item)
            table.insert(aug_cache[bag_name][item.id], item)
        end
    end
    return aug_cache[bag_name][item_id] or {}
end


--[[
    Combines equipment verified as available from set1 and set2.  Supports slots having more than one option each,
    contained in a table ordered by preference.  If a specific item slot's contents is defined in both set1 and
    set2, then that slot in the resulting set will contain the item defined in set2.  It is safe for set1 and/or
    set2 to be empty (nil).  Any subsets of either set will NOT be included in the resulting set.  Optionally, a
    subset may be provided for set2 that will be used if set2 exists.
--]]
function combineSets(set1, set2, ...)
    local newSet = {}
    local subsets = {...}
    local numsub = sizeof(subsets)
    if numsub > 0 then
        for i = 1, numsub do
            if set2 then
                local subset = set2[subsets[i]]
                if not subset then
                    if i >= numsub then set2 = subset end
                else
                    set2 = subset
                end
            end
        end
    end
    
    local current_item
    for itemSlot,variations in pairs(_slots.names) do
        for _,variation in pairs(variations) do
            if (set2 ~= nil) and (set2[variation] ~= nil) then
                current_item = set2[variation]
                if (type(current_item) == 'string') or current_item.name then
                    if setops.isAvailable(current_item, itemSlot) then
                        newSet[itemSlot] = current_item
                    end
                else
                    newSet[itemSlot] = setops.chooseAvailablePiece(current_item, itemSlot)
                end
            end
            
            --If the slot was not defined in set2, or if the item(s) defined for that slot
            --in set2 was unavailable, then use what was defined in set1
            if not newSet[itemSlot] then
                if (set1 ~= nil) and (set1[variation] ~= nil) then
                    current_item = set1[variation]
                    if (type(current_item) == 'string') or current_item.name then
                        if setops.isAvailable(current_item, itemSlot) then
                            newSet[itemSlot] = current_item
                        end
                    else
                        newSet[itemSlot] = setops.chooseAvailablePiece(current_item, itemSlot)
                    end
                end
            end
        end
    end
    return newSet
end


function canDW()
    local dwJobs = S{'NIN','DNC','BLU','THF'}
    return dwJobs:contains(player.main_job) or dwJobs:contains(player.sub_job)
end


function setops.in_equippable_bag(item)
    item = (type(item) == 'table') and item or {name=item}
    for _,bname in pairs(equip_bag_names) do
        if player[bname] then   --Assert player has bag unlocked
            local itbl = player[bname][item.name]
            if itbl then
                if (not item.augments) or (#item.augments == 0) then
                    return itbl
                end
                for _,aitem in pairs(get_items_with_augments(bname, itbl.id)) do
                    if table.equals(item.augments, aitem.augments) then
                        return itbl
                    end
                end
            end
        end
    end
    return nil
end


--[[
    Returns the name of the first item that is available in the player's inventory from a list that is ordered from
    most desirable to least desirable.
--]]
function setops.chooseAvailablePiece(gearTable, slot)
    if gearTable == nil then return nil end
    for _,i in pairs(gearTable) do
        if setops.isAvailable(i, slot) then
            return i
        end
    end
    return nil
end


--[[
    Returns true if the given item is in the player's inventory, false otherwise.
--]]
function setops.isAvailable(item, slot)
    local itable = setops.in_equippable_bag(item)
    if (itable ~= nil) then
        local iinfo = res.items[itable.id]
        local lvl_ok = iinfo.level <= player.main_job_level
        local race_ok = iinfo.races:contains(player.race_id)
        local job_ok = iinfo.jobs:contains(player.main_job_id)
        local i_su = iinfo.superior_level or 0
        local p_su = player.superior_level or 0
        local su_ok = i_su <= p_su
        
        local dw_ok = true
        if (iinfo.category == 'Weapon') and (slot == 'sub') and (iinfo.skill ~= 0) then
            dw_ok = canDW()
        end
        return lazy_and(lvl_ok, race_ok, job_ok, su_ok, dw_ok)
    end
    return false
end


--[[
    Returns a set containing the ftp pieces for the given ws.
--]]
function setops.get_ftp_set(ws)
    local ftpSet = {}
    if options.use_ftp_neck then
        ftpSet = combineSets(ftpSet, setops.get_ftp_gear('neck', ws))
    end
    if options.use_ftp_waist then
        ftpSet = combineSets(ftpSet, setops.get_ftp_gear('waist', ws))
    end
    return ftpSet
end


--[[
    Returns a set containing the ftp piece for the given slot and ws.
--]]
function setops.get_ftp_gear(slot, ws)
    if (slot == 'waist') and setops.in_equippable_bag(gear.ftp.all_waist) then
        return {[slot] = gear.ftp.all_waist}
    elseif (slot == 'neck') and setops.in_equippable_bag(gear.ftp.all_neck) then
        return {[slot] = gear.ftp.all_neck}
    end
    
    local ws_elements = S{}:
        union(skillchain_elements[ws.skillchain_a]):
        union(skillchain_elements[ws.skillchain_b]):
        union(skillchain_elements[ws.skillchain_c])
    
    for ele,i in pairs(ws_elements) do
        if setops.isAvailable(gear_map.ftp[slot][ele]) then
            return {[slot] = gear_map.ftp[slot][ele]}
        end
    end
    return {}
end


function setops.getObi(element)
    if setops.in_equippable_bag(gear.all_ele_obi) then
        return gear.all_ele_obi
    else
        return gear_map.Obi[element]
    end
end


--==============================================================================
--          Set Information
--==============================================================================


--[[
    Compiles a list of all items that are in the player's normal storages.
--]]
function setops.get_player_items(bagname)
    local searchbags = all_bag_names
    if bagname and all_bag_names:contains(bagname:lower()) then
        searchbags = S{bagname}
    end
    local items = winraw.ffxi.get_items()
    local gear = {}
    for bname,_ in pairs(searchbags) do
        if items[bname] then    --Assert player has bag unlocked
            for i = 1, 80 do
                local item = res.items[items[bname][i].id]
                if item then
                    table.insert(gear, item)
                end
            end
        end
    end
    return gear
end


--[[
    Print the the items you have in any inventory location that could be stored
    with a porter moogle, and the slip they would go in
    //gs c storable
--]]
function setops.determine_storable(args)
    local inv_contents = setops.get_player_items(args[1])
    local slippable = {}
    local c = 0
    for _,item in pairs(inv_contents) do
        if not setops._set_res[item.en] then
            local slip = _libs.slips.get_slip_id_by_item_id(item.id)
            if (slip ~= nil) then
                slippable[slip] = slippable[slip] or S{}
                slippable[slip]:add(item.enl:capitalize())
                c = c + 1
            end
        end
    end
    local output = {}
    for sid,sitems in pairs(slippable) do
        local sname = res.items[sid].en
        output[tonumber(sname:sub(-2))] = '[':colorize(263)..tostring(sizeof(sitems)):colorize(4,263)..']'..sname:colorize(326,263)..': '..sitems:format('list')
    end
    if sizeof(output) > 0 then
        atc('Items that you can store with the Porter Moogle (':colorize(262)..tostring(c):colorize(123,262)..'):')
        for k,v in opairs(output) do
            atc(v)
        end
    else
        atc("You don't have anything that's storable with the Porter Moogle":colorize(258))
    end
end


--[[
    Compares the gear specified in the currently active Player_JOB_gear.lua with the gear present in inventory.
    Reports which items are not necessary so that they can be moved to make room.
    //gs c inv_check
--]]
function setops.find_movable()
    local extras = S{}
    for _,itbl in pairs(player.inventory) do
        local ires = setops._item_res[itbl.id]
        if not setops._set_res[ires.en] then
            local item = res.items[itbl.id]
            if not (ignore_items:contains(item.enl)) then
                extras:add(item.enl:capitalize())
            end
        end
    end
    if (sizeof(extras) > 0) then
        atc('Items you do not need in your inventory (':colorize(262)..tostring(sizeof(extras)):colorize(123,262)..'):')
        for iname,_ in opairs(extras) do
            atc(iname:colorize(329))
        end
    else
        atc('Everything in your inventory is necessary!':colorize(258))
    end
end


--[[
    Returns a mapping of item_id:slip_name for all items currently stored with a porter moogle.
--]]
function setops.map_slipped_to_slip()
    local slipped = {}
    for sid,sitems in pairs(_libs.slips.get_player_items()) do
        for _,id in pairs(sitems) do
            slipped[id] = res.items[sid].en
        end
    end
    return slipped
end


--[[
    Compares the gear specified in the currently active Player_JOB_gear.lua with the gear that is stored with the
    Porter Moogle.  Reports which slips are necessary to retrieve gear from, and which pieces are stored with each
    of those slips. Automatically runs when a player change jobs.
    Can be run at any time via:
    //gs c slips
--]]
function setops.find_slipped()
    local slipped2slip = setops.map_slipped_to_slip()   --Mapping of items stored in slips to slip names
    local slipped = {}
    for iname,set_res in pairs(setops._set_res) do
        if not setops.in_equippable_bag({name=iname}) then
            local slip = slipped2slip[set_res.res.id]
            if slip then
                slipped[slip] = slipped[slip] or {}
                table.insert(slipped[slip], iname)
            end
        end
    end
    if (sizeof(slipped) > 0) then
        atc('Items you need to retrieve from the Porter Moogle:':colorize(262))
        local output = {}
        for slip,stbl in pairs(slipped) do
            local item_list = ", ":join(stbl)
            output[tonumber(slip:sub(-2))] = '[':colorize(263)..tostring(sizeof(stbl)):colorize(4,263)..']'..slip:colorize(326,263)..': '..item_list 
        end
        for k,v in opairs(output) do
            atc(v)
        end
    else
        atc('You have everything that you need from the Porter Moogle!':colorize(258))
    end
end


--[[
    Prints a list of items that are specified in the current player sets, but
    are in inventory locations from which those items cannot be equipped.
    //gs c misplaced
--]]
function setops.find_misplaced()
    local non_equippable = setops.expand_augments_in_bags(bags_nonequippable)
    local slipped2slip = setops.map_slipped_to_slip()
    local misplaced = comp('v:S{} for k,v in bag_list', {bag_list=bags_nonequippable})
    misplaced.missing = S{}
    for name, set_res in pairs(setops._set_res) do
        if name ~= 'empty' then
            if set_res.res == nil then
                atcfs(123,'find_misplaced unable to locate resource table for %s',name)
            end
            local non_equippable_items = non_equippable[set_res.res.id] or {}
            if not slipped2slip[set_res.res.id] then
                local versions = (#set_res.versions == 0) and {{}} or set_res.versions
                for _,aug_set in pairs(versions) do
                    if not setops.in_equippable_bag({name=name,augments=aug_set}) then
                        local mname = (#aug_set == 0) and name or '%s%s%s':format(string.char(239,40),name,string.char(239,39))
                        local found_match = false
                        for _,item in pairs(non_equippable_items) do
                            if (#aug_set == 0) or table.equals(aug_set, item.augments) then
                                misplaced[item.bag_name]:add(mname)
                                found_match = true
                                break
                            end
                        end
                        if not found_match then misplaced.missing:add(mname) end
                    end
                end
            end
        end
    end
    
    local output = {}
    for bname,btbl in pairs(misplaced) do
        if sizeof(btbl) > 0 then
            local item_list = ", ":join(btbl:sort())
            output[bname] = '[':colorize(263)..tostring(sizeof(btbl)):colorize(4,263)..']'..bname:colorize(326,263)..': '..item_list
        end
    end
    if (sizeof(output) > 0) then
        atc('Items you need to move to bags from which items can be equipped:':colorize(262))
        for k,v in opairs(output) do
            atcns(v)
        end
    else
        atc('All of your required items are equippable!':colorize(258))
    end
end


--[[
    Usage: //gs c augs2chat
--]]
function setops.augs_to_chat(args)
    if not S{'/l','/p','/t'}:contains(args[1]) then
        atc(123,'Invalid target for printing set info: \'%s\' - Valid: /l, /p, /t':format(args[1]))
        return
    end
    local arg_name = nil
    local targ = args[1]
    if (targ == '/t') then
        if (args[2] == nil) then
            atc(123,'Error: No argument provided for /t for printing set info.')
            return
        end
        targ = targ..' '..args[2]
        arg_name = args[3] and " ":join(table.slice(args, 3)) or nil
    else
        arg_name = args[2] and " ":join(table.slice(args, 2)) or nil
    end
    
    local bags = {[0]='inventory',[8]='wardrobe',[10]='wardrobe2',[11]='wardrobe3',[12]='wardrobe4'}
    local witems = windower.ffxi.get_items()
    local equipped = witems.equipment
    local enquote = customized(string.format, "'%s'")
    local fmt = 'input %s %s {%s}'
    local output = {}
    
    if arg_name then
        for bag_name,_ in pairs(all_bag_names) do
            local arg_item = res_for_item_name(arg_name)
            local augged = get_items_with_augments(bag_name, arg_item.id)
            for _,aitem in pairs(augged) do
                local ires = res.items[arg_item.id]
                table.insert(output, fmt:format(targ, ires.enl:capitalize(), ',':join(map(enquote, aitem.augments))))
            end
        end
    else
        for _,slot in pairs(_slots.name_list) do
            if slot ~= 'ammo2' then
                local index = equipped[slot]
                local bagid = equipped[slot..'_bag']
                local item = witems[bags[bagid]][index]
                if item then
                    local ires = setops._item_res[item.id]
                    item = setops.expand_augments(item)
                    if #item.augments > 0 then
                        table.insert(output, fmt:format(targ, ires.enl:capitalize(), ',':join(map(enquote, item.augments))))
                    end
                end
            end
        end
    end
    if #output > 0 then
        windower.send_command(';wait 1.1;':join(output))
    end
end


--[[
    Prints the currently equipped set to the specified chat channel.
    Valid chat channels: /t name, /p, /l
    Usage:  //gs c set2chat /t playername
--]]
function setops.set_to_chat(args)
    if not S{'/l','/p','/t'}:contains(args[1]) then
        atc(123,'Invalid target for printing set info: \'%s\' - Valid: /l, /p, /t':format(args[1]))
        return
    end
    local targ = args[1]
    if (targ == '/t') then
        if (args[2] == nil) then
            atc(123,'Error: No argument provided for /t for printing set info.')
            return
        end
        targ = targ..' '..args[2]
    end
    local pe = player.equipment
    local fmt = 'input %s %s, %s, %s, %s'
    local olines = {
        fmt:format(targ, pe.main, pe.sub, pe.range, pe.ammo),
        fmt:format(targ, pe.head, pe.neck, pe.ear1, pe.ear2),
        fmt:format(targ, pe.body, pe.hands, pe.ring1, pe.ring2),
        fmt:format(targ, pe.back, pe.waist, pe.legs, pe.feet)
    }
    windower.send_command(';wait 1.1;':join(olines))
end
