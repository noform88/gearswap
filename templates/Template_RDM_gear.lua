--------------------------------------------------------------------------------
--[[
	Author: Ragnarok.Lorand
--]]
--------------------------------------------------------------------------------

function init_gear_sets()
	--============================================================
	--			Precast sets
	--============================================================
	sets.precast.JA['Chainspell'] = {}
	sets.precast.JA['Saboteur'] = {}
	
	sets.precast.Waltz = {}
	sets.precast.Waltz['Healing Waltz'] = {}
	
	-- Fast Cast caps at 80%; RDM JT: 30%
	sets.precast.FC = {}
	
	sets.precast.FC.HealingMagic = {}
	sets.precast.FC.EnhancingMagic = {}
	
	--============================================================
	
	sets.wsBase = {}
	sets.wsBase.Magic = {}
	
	--============================================================
	--			Midcast sets
	--============================================================
	
	sets.midcast.FastRecast = {}

	sets.midcast.HealingMagic = {}
	sets.midcast.Cursna = {}
	
	sets.midcast.Cure = {}
	sets.midcast.Curaga = sets.midcast.Cure
	sets.midcast.Cure.Engaged = {}
	
	sets.midcast.Cure.with_buff = {}
	sets.midcast.Cure.with_buff['reive mark'] = {}
	
	sets.midcast.EnhancingMagic = {}
	sets.midcast.EnhancingMagic.Duration = {}
	sets.midcast.EnhancingMagic.Duration.ComposureOther = {}
	
	sets.midcast['Aquaveil'] =	{}
	sets.midcast['Phalanx II'] =	{}
	sets.midcast['Refresh'] =	{}
	sets.midcast['Stoneskin'] =	{}
	
	--============================================================
	
	sets.midcast.MagicAccuracy = {}
	
	sets.midcast.EnfeeblingMagic = {}
	sets.midcast.EnfeeblingMagic.Saboteur = {}
	
	sets.midcast.EnfeeblingMagic.Potency = {}
	sets.midcast.EnfeeblingMagic.Potency.Resistant = {}
	sets.midcast.EnfeeblingMagic.Potency.Normal = {}
	
	sets.midcast['Dia III'] = {}
	sets.midcast['Slow II'] = {}
	
	--============================================================
	
	sets.midcast.ElementalMagic = {}
	sets.midcast.ElementalMagic.LowTier = {}
	sets.midcast.ElementalMagic.HighTier = {}
	sets.midcast.ElementalMagic.Earth = {}
	
	sets.midcast.ElementalMagic.with_buff = {}
	sets.midcast.ElementalMagic.with_buff['reive mark'] = {}
	
	sets.midcast.ElementalEnfeeble = {}

	sets.midcast.DarkMagic = {}
	sets.midcast.Stun = {}
	
	sets.midcast.DivineMagic = {}
	sets.midcast.DivineMagic.Nuke = {}
	sets.midcast.DivineMagic.Nuke.with_buff = {}
	sets.midcast.DivineMagic.Nuke.with_buff['reive mark'] = {}
	
	--============================================================
	--			Other sets
	--============================================================
	
	sets.maxMP = {}
	
	sets.resting = combineSets(sets.maxMP, {})
	
	sets.idle = {}
	sets.idle.CapFarm = {}
	
	sets.idle.with_buff = {}
	sets.idle.with_buff['reive mark'] = {}
	
	sets.idle.Melee = {}
	sets.idle.lowMP = {}
	sets.idle.lowMP_night =	{}
	sets.idle.lowMP_day = {}
	
	sets.minHp = combineSets(sets.naked, {})
	sets.maxHp = combineSets(sets.naked, {})

	sets.defense.DT = {}
	sets.defense.PDT = combineSets(sets.defense.DT, {})
	sets.defense.MDT = combineSets(sets.defense.DT, {})

	sets.engaged = {}
	sets.engaged.with_buff = {}
	
	sets.engaged.Skillup = {}
end
