-----------------------------------------------------------------------------------------------------------
--[[
	Author: Ragnarok.Lorand
	GearSwap defaults
--]]
-----------------------------------------------------------------------------------------------------------

function define_defaults()
	sets = {}
	sets.precast = {}
	sets.precast.FC = {}
	sets.precast.JA = {}
	
	sets.midcast = {}
	sets.midcast.pet = {}
	sets.midcast.FastRecast = {}
	sets.midcast.BardSong = {}
	sets.midcast.DarkMagic = {}
	sets.midcast.DivineMagic = {}
	sets.midcast.DivineMagic.Nuke = {}
	sets.midcast.EnfeeblingMagic = {}
	sets.midcast.EnhancingMagic = {}
	sets.midcast.ElementalMagic = {}
	sets.midcast.HealingMagic = {}
	
	sets.idle = {}
	sets.engaged = {}
	sets.defense = {}
	sets.defense.PDT = {}
	sets.defense.MDT = {}
	sets.buffs = {}
	sets.buffs.doom = {ring1="Saida Ring", ring2="Saida Ring"}
	sets.naked = {main=empty,sub=empty,range=empty,ammo=empty,head=empty,neck=empty,ear1=empty,ear2=empty,body=empty,hands=empty,ring1=empty,ring2=empty,back=empty,waist=empty,legs=empty,feet=empty}
	sets.weapons = {}
	
	state = {}
	
	setMode('ConserveMP', true)
	setMode('autoPenury', false)
	setMode('noIdle', false)
	setMode('autoCaress', false)
	
	options = {}
	options.use_ftp_neck = true
	options.use_ftp_waist = false
	options.useTwilightCape = false
	options.useObi = true

	gear = {}
	gear.instruments = {}
	gear.instruments.default = 'Eminent Flute'
	gear.instruments.multiSong = 'Terpander'
	
	weapSwapJobs = S{'WHM','BLM','RDM','SCH','GEO','BRD','BLU'}
	noWeapSwapSets = S{'Melee','Skillup','Learn'}
	usesRanged = S{'RNG','COR','THF','SAM'}
	
	--addModeOption(mode, option)
	
	vars = {}
	vars.CurePotency = {[1]=87, [2]=199, [3]=438, [4]=816, [5]=1056, [6]=1311}
	
	state.warned = false
	options.ammo_warning_limit = 15
	timer_reg = {}
end

function clear_binds()
	windower.send_command('unbind @1;unbind @2;unbind @3;unbind @4;unbind @5')
	windower.send_command('unbind @6;unbind @7;unbind @8;unbind @9;unbind @0')
	windower.send_command('unbind ^=;unbind !=')
	windower.send_command('unbind ^`;unbind !`;unbind @`')
	windower.send_command('unbind @F1;unbind @F2;unbind @F3;unbind @F4')
	windower.send_command('unbind !a;unbind ^a;unbind !s;unbind ^s;unbind @m')
end