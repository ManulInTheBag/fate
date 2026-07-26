-- legacy_shared.lua — остатки монолитов *_ability.lua.
--
-- Сами монолиты больше не грузятся: их datadriven-блоки переписаны в
-- ability_lua, а require на них нет. Но живой код (включая перенесённый
-- конвертером) читает эти глобали и зовёт эти функции, поэтому они лежат
-- здесь одним явным местом; require идёт из addon_game_mode.
-- По мере переписывания потребителей файл должен таять.

-- OnRidingAcquired ← astolfo_ability.lua
function OnRidingAcquired(keys)
    local caster = keys.caster
    local hero = PlayerResource:GetSelectedHeroEntity(caster:GetPlayerOwnerID())
    hero.bIsRidingAcquired = true
    -- Set master 1's mana
    local master = hero.MasterUnit
    local master2 = hero.MasterUnit2
    master:SetMana(master2:GetMana())
end

-- OnBerserkStart ← berserker_ability.lua
function OnBerserkStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local hplock = keys.Health
	local duration = keys.Duration
	local damageTaken = keys.DamageTaken
	local ply = caster:GetPlayerOwner()
	local berserkCounter = 0
	caster.BerserkDamageTaken = 0

	--ability:ApplyDataDrivenModifier(caster, caster, "modifier_berserk_self_buff", {})
	caster:AddNewModifier(caster, ability, "modifier_heracles_berserk", { LockedHealth = hplock,
																		  Duration = duration })

	local casterHealth = caster:GetHealth()
	if casterHealth - hplock > 0 then
		local berserkDamage = math.min((casterHealth - hplock), hplock * 0.6)  
		caster:EmitSound("Hero_Centaur.HoofStomp")

		local berserkExp = ParticleManager:CreateParticle("particles/custom/berserker/berserk/eternal_rage_shockwave.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(berserkExp, 1, Vector(radius,0,radius))

		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 400, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		for k,v in pairs(targets) do
	        DoDamage(caster, v, berserkDamage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
		end
	end

	if caster.IsEternalRageAcquired then 
		local explosionCounter = 0
		local manaregenCounter = 0

		Timers:CreateTimer(function()
			if caster:HasModifier("modifier_heracles_berserk") == false then return end
			if explosionCounter == duration then return end

			local radius = 300
			local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			for k,v in pairs(targets) do
		        DoDamage(caster, v, caster.BerserkDamageTaken/5, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
			end
			caster.BerserkDamageTaken = 0
			local berserkExp = ParticleManager:CreateParticle("particles/custom/berserker/berserk/eternal_rage_shockwave.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(berserkExp, 1, Vector(radius,0,radius))
			-- DebugDrawCircle(caster:GetAbsOrigin(), Vector(255,0,0), 0.5, radius, true, 0.5)

			explosionCounter = explosionCounter + 1.0
			return 1.0
			end
		)
	end

	BerCheckCombo(caster, keys.ability)
	--prevents double sound on combo
	if caster:HasModifier("modifier_madmans_roar_silence") == false then
		EmitGlobalSound("Berserker.Roar")
	end

	-- hi i'm definitely not a hacky replacement for not being able to get status effect particles to work
	--caster:SetRenderColor(255, 127, 127)
end

-- OnReincarnationDamageTaken ← berserker_ability.lua
function OnReincarnationDamageTaken(keys)
	--[[
	local caster = keys.caster
	local ability = keys.ability
	local damageTaken = keys.DamageTaken
	local damageThreshold = 100000

	--[[if damageTaken > 100 then
		GainReincarnationRegenStack(caster, ability)
	end

	if damageTaken > 4000 then
		return
	end

	if caster.IsGodHandAcquired ~= true then return end -- To prevent reincanationdamagetaken from incrementing when GH is not taken.

	if caster:HasModifier("modifier_heracles_berserk") then 
		caster.ReincarnationDamageTaken = caster.ReincarnationDamageTaken+damageTaken--*3
	else
		caster.ReincarnationDamageTaken = caster.ReincarnationDamageTaken+damageTaken
	end
	
	print(caster.ReincarnationDamageTaken)
	if caster.ReincarnationDamageTaken > damageThreshold and caster.IsGodHandAcquired then
		caster.ReincarnationDamageTaken = 0
		caster.GodHandStock = caster.GodHandStock + 1
		caster:RemoveModifierByName("modifier_god_hand_stock")
		caster:FindAbilityByName("berserker_5th_god_hand"):ApplyDataDrivenModifier(caster, caster, "modifier_god_hand_stock", {})
		caster:SetModifierStackCount("modifier_god_hand_stock", caster, caster.GodHandStock)
	end
	]]
	--UpdateGodhandProgress(caster)
end

-- QTime ← berserker_ability.lua
QTime = 0

-- QUsed ← berserker_ability.lua
QUsed = false

-- LeaveFireTrail ← gawain_ability.lua
function LeaveFireTrail(keys, location, duration)
	local caster = keys.caster
	local ability = keys.ability
	local damage = keys.BurnDamage

	local fireFx = ParticleManager:CreateParticle("particles/custom/gawain/gawain_galetine_flametrail_parent.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(fireFx, 0, location)
	ParticleManager:SetParticleControl(fireFx, 1, Vector(duration,0,0))

	local counter = 0
	local period = 0.5
	Timers:CreateTimer(function()
		counter = counter + period
		if counter > duration then return end
		local targets = FindUnitsInRadius(caster:GetTeam(), location, nil, 350, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
		for k,v in pairs(targets) do
			--caster:RemoveModifierByName("modifier_excalibur_galatine_burn")
			v:AddNewModifier(caster, ability, "modifier_excalibur_galatine_burnk", {})
		end
		return period
	end)
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------------------------------------

--========================================================================================================
--												Attributes
--========================================================================================================

--========================================================================================================
--										Unused Skill codes (mostly legacy)
--========================================================================================================

--========================================================================================================
--										Unused Attributes
--========================================================================================================

-- aotkCasterPos ← iskander_ability.lua
aotkCasterPos = nil

-- aotkCenter ← iskander_ability.lua
aotkCenter = Vector(288,-4504, 261)

-- aotkTargets ← iskander_ability.lua
aotkTargets = nil

-- modName ← iskander_ability.lua
modName = "modifier_charisma_movespeed"

-- ubwCenter ← iskander_ability.lua
ubwCenter = Vector(5926, -4837, 222)

-- ATTR_HEARTSEEKER_AD_RATIO ← lancer_ability.lua
ATTR_HEARTSEEKER_AD_RATIO = 2

-- ATTR_HEARTSEEKER_COMBO_AD_RATIO ← lancer_ability.lua
ATTR_HEARTSEEKER_COMBO_AD_RATIO = 2

-- GBAttachEffect ← lancer_ability.lua
function GBAttachEffect(keys)
	local caster = keys.caster
	local GBCastFx = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(GBCastFx, 1, caster:GetAbsOrigin()) -- target effect location
	ParticleManager:SetParticleControl(GBCastFx, 2, caster:GetAbsOrigin()) -- circle effect location
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( GBCastFx, false )
	end)

	if keys.ability == caster:FindAbilityByName("lancer_5th_gae_bolg") then
		caster:EmitSound("Lancer.GaeBolg")
	elseif keys.ability == caster:FindAbilityByName("lancelot_gae_bolg") then 
		caster:EmitSound("Lancelot.Growl_Local" )
	end
	if keys.caster:GetName() == "npc_dota_hero_sven" then
		EmitZlodemonTrueSoundEveryone("moskes_lanc_gae")
	end
end

-- OnGBTargetHit ← lancer_ability.lua
function OnGBTargetHit(keys)
	ArsenalReturnMana(keys.caster)
	if IsSpellBlocked(keys.target, keys.caster) then return end -- Linken effect checker
	if keys.caster:GetAbilityByIndex(2):GetAbilityName() == "lancer_5th_wesen_gae_bolg" then return end -- laziest fix of my lyfe

	local caster = keys.caster
	local casterName = caster:GetName()
	local target = keys.target
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	if caster.IsHeartSeekerAcquired == true then keys.HBThreshold = keys.HBThreshold + caster:GetAttackDamage()*ATTR_HEARTSEEKER_AD_RATIO end

	-- Check if caster is lancer(not lancelot)
	if casterName == "npc_dota_hero_phantom_lancer" then
		local runeAbil = caster:FindAbilityByName("lancer_5th_rune_of_flame")
		local healthDamagePct = runeAbil:GetLevelSpecialValueFor("ability_bonus_damage", runeAbil:GetLevel()-1)
		if caster.IsGaeBolgImproved == true then
		healthDamagePct = healthDamagePct * 2
		end
		keys.Damage = keys.Damage + target:GetHealth()*healthDamagePct/100
	else
		if keys.caster:GetName() ~= "npc_dota_hero_sven" then
			StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_CAST_ABILITY_1, rate=3})
		end
	end

	giveUnitDataDrivenModifier(caster, target, "can_be_executed", 0.033)
	if caster.ImproveKnightOfOwner then 
		DoDamage(caster, target, keys.Damage, DAMAGE_TYPE_PURE, 0, keys.ability, false)
	else
		DoDamage(caster, target, keys.Damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	end

	--target:AddNewModifier(caster, target, "modifier_stunned", {Duration = 1.0})
	if target:GetHealth() < keys.HBThreshold then
		PlayHeartBreakEffect(ability, caster, target)
	end  -- check for HB

	-- if Gae Bolg is improved, do 3 second dot over time
	--[[if caster.IsGaeBolgImproved == true then 
		local dotCount = 0
		Timers:CreateTimer(function() 
			if dotCount == 3 then return end
			DoDamage(caster, target, target:GetMaxHealth()/30, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
			dotCount = dotCount + 1
			return 1.0 
		end)
	end]]

	--[[
	-- if Heart Seeker attribute is acquired, check for HB condition every 0.3 seconds
	if caster.IsHeartSeekerAcquired == true then
		local dotCount = 0
		Timers:CreateTimer(function() 
			if dotCount == 10 then return end
			if target:GetHealth() < keys.HBThreshold then 
				if target:GetHealth() ~= 0 then 
					PlayHeartBreakEffect(target)

				end 
				target:Kill(keys.ability, caster) 
			end 
			dotCount = dotCount + 1
			return 0.3
		end)
	end]]
	if ability:GetAbilityName() == "lancer_5th_gae_bolg" then
		StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_ATTACK, rate=3})
	end
	-- Add dagon particle
	local dagon_particle = ParticleManager:CreateParticle("particles/items_fx/dagon.vpcf",  PATTACH_ABSORIGIN_FOLLOW, keys.caster)
	ParticleManager:SetParticleControlEnt(dagon_particle, 1, keys.target, PATTACH_POINT_FOLLOW, "attach_hitloc", keys.target:GetAbsOrigin(), false)
	local particle_effect_intensity = 600
	ParticleManager:SetParticleControl(dagon_particle, 2, Vector(particle_effect_intensity))
	target:EmitSound("Hero_Lion.Impale")
	PlayNormalGBEffect(target)
	-- Blood splat
	local splat = ParticleManager:CreateParticle("particles/generic_gameplay/screen_blood_splatter.vpcf", PATTACH_EYES_FOLLOW, target)

	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( dagon_particle, false )
		ParticleManager:DestroyParticle( splat, false )
	end)
end

-- PlayHeartBreakEffect ← lancer_ability.lua
function PlayHeartBreakEffect(ability, killer, target)
	if target:HasModifier("modifier_avalon") then return end
	local culling_kill_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 2, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 4, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 8, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(culling_kill_particle)

	local hb = ParticleManager:CreateParticle("particles/custom/lancer/lancer_heart_break_txt.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl( hb, 0, target:GetAbsOrigin())

	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( culling_kill_particle, false )
		ParticleManager:DestroyParticle( hb, false )
	end)
	target:Execute(ability, killer, { bExecution = true })
end

-- PlayNormalGBEffect ← lancer_ability.lua
function PlayNormalGBEffect(target)
	local culling_kill_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 2, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 4, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 8, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(culling_kill_particle)
	
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( culling_kill_particle, false )
	end)
end

-- TPOnAttack ← nero_ability.lua
function TPOnAttack(keys)
	local caster = keys.caster
	if caster:HasModifier("modifier_aestus_domus_aurea") and caster:HasModifier("modifier_tres_fontaine_ardent") and caster.IsGloryAcquired == true and math.random(100) <= caster:FindAbilityByName("nero_tres_fontaine_ardent"):GetSpecialValueFor("chance") then
		local target = caster:GetAttackTarget()
		caster:SetAbsOrigin(target:GetAbsOrigin() + Vector(RandomFloat(-100, 100),RandomFloat(-100, 100),RandomFloat(-100, 100) ))
		ProjectileManager:ProjectileDodge(caster)		
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	end
end

-- vortigernCount ← saber_alter_ability.lua
vortigernCount = 0

-- ← archer_ability.lua
chainTargetsTable = nil
ubwTargets = nil
ubwTargetLoc = nil
ubwCasterPos = nil
ubwCenter = Vector(5600, -4398, 200)
aotkCenter = Vector(500, -4800, 208)
ATTR_PROJECTION_PASSIVE_WEAPON_DAMAGE = 150
LinkLuaModifier("modifier_aestus_domus_aurea_enemy", "abilities/nero/modifiers/modifier_aestus_domus_aurea_enemy", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aestus_domus_aurea_ally", "abilities/nero/modifiers/modifier_aestus_domus_aurea_ally", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aestus_domus_aurea_nero", "abilities/nero/modifiers/modifier_aestus_domus_aurea_nero", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eagle_eye", "abilities/emiya/modifiers/modifier_eagle_eye", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_overedge_attribute", "abilities/emiya/modifiers/modifier_overedge_attribute", LUA_MODIFIER_MOTION_NONE)
rhoTarget = nil
ubwdummies = nil
ARROWRAIN_BP_DAMAGE_RATE = 0.66

-- ← lancelot_ability.lua
LinkLuaModifier("modifier_eternal_arms_attribute", "abilities/lancelot/modifiers/modifier_eternal_arms_attribute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_excalibur_galatine_burnk", "abilities/gawain/gawain_excalibur_galatine", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heracles_berserk", "abilities/heracles/modifiers/modifier_heracles_berserk", LUA_MODIFIER_MOTION_NONE)
function ArsenalReturnMana(caster)
    if caster:GetName() == "npc_dota_hero_sven" and caster.ArsenalLevel == 2 then
        caster:GiveMana(caster:FindAbilityByName("lancelot_knight_of_honor_arsenal"):GetSpecialValueFor("mana_return"))
    end
end
lastPos = Vector(0,0,0)


-- CharmModifierList ← tamamo_ability.lua (монолит больше не загружается:
-- нет require и не осталось живого datadriven ScriptFile)
CharmModifierList = {
	"modifier_fiery_heaven_indicator",
	"modifier_frigid_heaven_indicator",
	"modifier_gust_heaven_indicator",
	"modifier_void_heaven_indicator"
}
