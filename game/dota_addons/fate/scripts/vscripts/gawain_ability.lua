--list and related Dota KV file must be updated upon new hero release!!!
modifierList = {"modifier_max_mana_burst_cooldown","modifier_delusional_illusion_cooldown","modifier_max_excalibur_cooldown",
"modifier_wesen_gae_bolg_cooldown","modifier_arrow_rain_cooldown","modifier_bellerophon_2_cooldown",
"modifier_hecatic_graea_powered_cooldown","modifier_tsubame_mai_cooldown","modifier_madmans_roar_cooldown",
"modifier_max_enuma_elish_cooldown","modifier_endless_loop_cooldown","modifier_rampant_warrior_cooldown","modifier_nuke_cooldown",
"modifier_larret_de_mort_cooldown","modifier_annihilate_cooldown","modifier_fiery_finale_cooldown",
"modifier_polygamist_cooldown","modifier_raging_dragon_strike_cooldown","modifier_la_pucelle_cooldown","modifier_hippogriff_ride_cooldown","modifier_story_for_someones_sake_cooldown",
"modifier_phoebus_catastrophe_cooldown","modifier_lord_of_execution_cd",
"modifier_strike_air_cooldown","modifier_instinct_cooldown","modifier_battle_continuation_cooldown","modifier_hrunting_cooldown",
"modifier_overedge_cooldown","modifier_blood_mark_cooldown","modifier_quickdraw_cooldown","modifier_eternal_arms_mastership_cooldown","modifier_mystic_shackle_cooldown",
"modifier_golden_apple_cooldown","modifier_protection_of_faith_proc_cd"} --last 3 lines are non-combos.

--------------------------------------------------------------------------------------------------------------------------------------------------------------

function OnDevoteStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_blade_of_the_devoted", {})

	caster:EmitSound("Hero_EmberSpirit.FireRemnant.Cast")
	local lightFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_sun_strike_beam.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( lightFx1, 0, caster:GetAbsOrigin())
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( lightFx1, false )
		ParticleManager:ReleaseParticleIndex( lightFx1 )
	end)
end

function OnDevoteHit(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local target = keys.target

	DoDamage(caster, target, keys.Damage, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
	caster:RemoveModifierByName("modifier_blade_of_the_devoted")
	target:AddNewModifier(caster, caster, "modifier_stunned", {Duration = 0.5})
	
	local knockBackUnits = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, 250, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false )
	local kbDistance = 200

	if caster.IsBeltAcquired then
		kbDistance = 300
		keys.ability:ApplyDataDrivenModifier(caster,target,"modifier_blade_of_the_devoted_slow",{duration=3.0})
	end

	local modifierKnockback = {	center_x = target:GetAbsOrigin().x,
								center_y = target:GetAbsOrigin().y,
								center_z = target:GetAbsOrigin().z,
								duration = 0.5,
								knockback_duration = 0.5,
								knockback_distance = kbDistance,
								knockback_height = kbDistance,
							}

	for _,unit in pairs(knockBackUnits) do
		if unit ~= target then
			if caster.IsBeltAcquired then
				DoDamage(caster, unit, keys.Damage * 0.5, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
			end
			unit:AddNewModifier( unit, nil, "modifier_knockback", modifierKnockback )
		end
	end	

	target:EmitSound("Hero_Invoker.ColdSnap")
	local lightFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_sun_strike_beam.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( lightFx1, 0, target:GetAbsOrigin())
	local flameFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_fire_spirit_ground.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
	
	ParticleManager:SetParticleControl( flameFx1, 0, target:GetAbsOrigin())
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( lightFx1, false )
		ParticleManager:ReleaseParticleIndex( lightFx1 )
		ParticleManager:DestroyParticle( flameFx1, false )
		ParticleManager:ReleaseParticleIndex( flameFx1 )
	end)	
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------

function OnGalatineStart(keys)
	-- Declaring a bunch of stuffs
	local caster = keys.caster
	local ability = keys.ability
	--local ply = caster:GetPlayerOwner()
	local casterLoc = caster:GetAbsOrigin()
	local targetPoint = keys.target_points[1]
	local dist = keys.Max_range    --(targetPoint - casterLoc):Length2D()
	local orbLoc = caster:GetAbsOrigin()
	local diff = caster:GetForwardVector()
	local timeElapsed = 0
	local flyingDist = 0
	local orbVelocity = 90
	local fireTrailDuration = 3
	local damage = keys.Damage
	local InFirstLoop = true
	caster.IsGalatineActive = true

	-- Stops Gawain from doing anything else essentially and play the Galatine animation
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_excalibur_galatine_vfx", {})	
	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 2.0)
	StartAnimation(caster, {duration=2.0, activity=ACT_DOTA_CAST_ABILITY_4, rate=1.3})
	-- Need the dank voice. 
	EmitGlobalSound("Gawain_Galatine_1")

	-- Make dem particles and the Galatine ball
	local castFx1 = ParticleManager:CreateParticle("particles/custom/saber_excalibur_circle.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( castFx1, 0, caster:GetAbsOrigin())

	local castFx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( castFx2, 0, caster:GetAbsOrigin())

	local galatineDummy = CreateUnitByName("gawain_galatine_dummy", Vector(20000,20000,0), true, nil, nil, caster:GetTeamNumber())
	local flameFx1 = ParticleManager:CreateParticle("particles/custom/gawain/gawain_excalibur_galatine_orb.vpcf", PATTACH_ABSORIGIN_FOLLOW, galatineDummy )
	ParticleManager:SetParticleControl( flameFx1, 0, galatineDummy:GetAbsOrigin())

	galatineDummy:SetDayTimeVisionRange(300)
	galatineDummy:SetNightTimeVisionRange(300)
	galatineDummy:AddNewModifier(caster, nil, "modifier_kill", {duration = 5.0})

	if caster.IsSoVAcquired then
		damage = damage + 250
		fireTrailDuration = fireTrailDuration + 3
	end

	-- Checks if Gawain is still alive as well as whether or not it overshot where the player intended it to flew.. or it flew for too long
	Timers:CreateTimer(1.4, function()
		if caster:IsAlive() and timeElapsed < 1.4 and caster.IsGalatineActive and flyingDist < dist then
			-- Need to initialize the variables and put in Gawain's detonate Galatine ability
			if InFirstLoop then
				casterLoc = caster:GetAbsOrigin()
				orbLoc = caster:GetAbsOrigin()
				diff = caster:GetForwardVector()
				caster:SwapAbilities("gawain_excalibur_galatine", "gawain_excalibur_galatine_detonate", false, true)
				InFirstLoop = false
				EmitGlobalSound("Gawain_Galatine_2")
			end
			-- Move the ball, reduce the remaining flight distance, reduce the remaining timer and increase the AoE gradually
			orbLoc = orbLoc + diff * orbVelocity
			galatineDummy:SetAbsOrigin(orbLoc)
			flyingDist = (casterLoc - orbLoc):Length2D()
			timeElapsed = timeElapsed + 0.05

			-- Get all nearby enemies and give them Galatine burn debuff if they don't have it
			local burnTargets = FindUnitsInRadius(caster:GetTeam(), galatineDummy:GetAbsOrigin(), nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)			
			for i,j in pairs(burnTargets) do
				ability:ApplyDataDrivenModifier(caster, j, "modifier_excalibur_galatine_burnk", {}) 				
			end

			--Hacky way to leave a fire trail 
			if (math.ceil(flyingDist) % 300 < 5) then
				LeaveFireTrail(keys, GetGroundPosition(galatineDummy:GetAbsOrigin(), nil), fireTrailDuration)
			end
			
			return 0.05
		else 
			LeaveFireTrail(keys, GetGroundPosition(galatineDummy:GetAbsOrigin(), nil), fireTrailDuration)

			-- Give Gawain back his Galatine
			GiveGawainGalatine(caster)

			-- Explosion on enemies
			local targets = FindUnitsInRadius(caster:GetTeam(), galatineDummy:GetAbsOrigin(), nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 

			for k,v in pairs(targets) do	
				keys.ability:ApplyDataDrivenModifier(caster, v, "modifier_excalibur_galatine_burnk", {})
				DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)				
			end

			local explodeFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_hit.vpcf", PATTACH_ABSORIGIN, galatineDummy )
			ParticleManager:SetParticleControl( explodeFx1, 0, galatineDummy:GetAbsOrigin())			

			local explodeFx2 = ParticleManager:CreateParticle("particles/custom/gawain/gawain_galetine_explosion_parent.vpcf", PATTACH_ABSORIGIN_FOLLOW, galatineDummy )
			ParticleManager:SetParticleControl( explodeFx2, 0, galatineDummy:GetAbsOrigin())

			galatineDummy:EmitSound("Ability.LightStrikeArray")
			local sunAbility = caster:FindAbilityByName("gawain_artificial_sun")
			sunAbility:GenerateArtificialSun(caster, galatineDummy:GetAbsOrigin(), false, "gawain_excalibur_galatine")
			galatineDummy:ForceKill(true) 
		
			ParticleManager:DestroyParticle( flameFx1, false )
			ParticleManager:ReleaseParticleIndex( flameFx1 )
			ParticleManager:DestroyParticle( castFx1, false )
			ParticleManager:ReleaseParticleIndex( castFx1 )

			Timers:CreateTimer( 2.0, function()
				ParticleManager:DestroyParticle( explodeFx1, false )
				ParticleManager:ReleaseParticleIndex( explodeFx1 )
				ParticleManager:DestroyParticle( explodeFx2, false )
				ParticleManager:ReleaseParticleIndex( explodeFx2 )
			end)
			return
		end
	end)
end

function OnGalatineDetonate(keys)
	local caster = keys.caster
	caster.IsGalatineActive = false
	GiveGawainGalatine(caster)
	--[[local skillname = caster:GetAbilityByIndex(5):GetAbilityName() ]]


	--[[if skillname == "gawain_excalibur_galatine_detonate" then
		caster:SwapAbilities("gawain_excalibur_galatine", "gawain_excalibur_galatine_detonate", true, false)
	end]]
end

function GiveGawainGalatine(caster)
	local galatineSlot = caster:GetAbilityByIndex(5)

	caster.IsGalatineActive = false

	if galatineSlot:GetAbilityName() ~= "gawain_excalibur_galatine" then
		caster:SwapAbilities("gawain_excalibur_galatine", galatineSlot:GetAbilityName(), true, false)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------

--Copied from Jeanne's kek
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
			ability:ApplyDataDrivenModifier(caster, v, "modifier_excalibur_galatine_burnk", {})
		end
		return period
	end)
end

function OnBurnDamageTick(keys)
	local caster = keys.caster
	local target = keys.target
	local damage = keys.Damage/4

	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------

function OnFairyDamageTaken(keys)
	local caster = keys.caster
	local ability = keys.ability
	local currentHealth = caster:GetHealth()

	if currentHealth < 333 and keys.ability:IsCooldownReady() and IsRevivePossible(caster) then
		RemoveDebuffsForRevival(caster)
		caster:SetHealth(333)
		keys.ability:StartCooldown(99) 

		HardCleanse(caster)

		local proxy = caster:FindAbilityByName("gawain_blessing_proxy")

		proxy:StartCooldown(99)

		ability:ApplyDataDrivenModifier(caster, caster, "modifier_gawain_blessing_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_gawain_revive_regen", {duration = 5})
		local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(particle, 3, caster:GetAbsOrigin())
		Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( particle, false )
			ParticleManager:ReleaseParticleIndex( particle )
		end)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------

function GawainCheckCombo(caster, ability)
	if caster:GetStrength() >= 19.1 and caster:GetAgility() >= 19.1 and caster:GetIntellect() >= 19.1 then
		if ability == caster:FindAbilityByName("gawain_heat") 
			and caster:FindAbilityByName("gawain_excalibur_galatine"):IsCooldownReady() 
			and caster:FindAbilityByName("gawain_excalibur_galatine_combo"):IsCooldownReady() 
			and caster:HasModifier("modifier_blade_of_the_devoted")
			then

			caster:EmitSound("gawain_kill_02")
			caster:FindAbilityByName("gawain_excalibur_galatine_combo"):StartCooldown(2)
			caster:SwapAbilities("gawain_excalibur_galatine", "gawain_excalibur_galatine_combo", false, true) 

			Timers:CreateTimer(7.0, function()
				local ability = caster:GetAbilityByIndex(5)
				print(ability:GetName())
				if ability:GetName() ~= "gawain_excalibur_galatine" and not caster.IsGalatineComboActive then
					caster:SwapAbilities("gawain_excalibur_galatine", ability:GetName(), true, false) 
				end				
			end)
			--[[Timers:CreateTimer({
				endTime = 3,
				callback = function()
				caster:SwapAbilities("gawain_excalibur_galatine", "gawain_excalibur_galatine_combo", true, false) 
			end
			})	]]		
		end
	end
end

--========================================================================================================
--												Attributes
--========================================================================================================

function OnFairyAcquired(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsFairyAcquired = true

    hero:AddAbility("gawain_blessing_of_fairy")
    hero:FindAbilityByName("gawain_blessing_of_fairy"):SetLevel(1)
    --hero:SwapAbilities("fate_empty8", "gawain_blessing_of_fairy", false, true)

  	--hero:FindAbilityByName("gawain_blessing_of_fairy"):SetHidden(false)
    hero:SwapAbilities(hero:GetAbilityByIndex(4):GetName(), "gawain_blessing_proxy", false, true)
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnSoVAcquired(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsSoVAcquired = true

    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnNoSAcquired(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsNoSAcquired = true

    hero:SetBaseMagicalResistanceValue(23)
    hero:SwapAbilities("fate_empty1", "gawain_saint", false, true)
    hero:FindAbilityByName("gawain_saint"):SetLevel(1)

    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnBeltAcquired(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsBeltAcquired = true

    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

--========================================================================================================
--										Unused Skill codes (mostly legacy)
--========================================================================================================

function OnMeltdownStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 20000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false) 
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_meltdown_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})
	for k,v in pairs(targets) do
		if v:GetUnitName() == "gawain_artificial_sun" then
			keys.ability:ApplyDataDrivenModifier(caster, v, "modifier_divine_meltdown", {})

			 v:EmitSound("Hero_DoomBringer.ScorchedEarthAura")
			--v:EmitSound("Hero_Warlock.RainOfChaos_buildup" )
			v.metldownFx = ParticleManager:CreateParticle("particles/custom/gawain/gawain_meltdown.vpcf", PATTACH_ABSORIGIN_FOLLOW, v )
			ParticleManager:SetParticleControl( v.metldownFx, 0, v:GetAbsOrigin())
			Timers:CreateTimer(5.0, function()
				if IsValidEntity(v) and v:IsAlive() then
					ParticleManager:DestroyParticle( v.metldownFx, false )
					ParticleManager:ReleaseParticleIndex( v.metldownFx )
				
				end
				StopSoundOn("Hero_DoomBringer.ScorchedEarthAura", v)
			end)
			--print("found sun")
		end
	end
end

function OnMeltdownThink(keys)
	local caster = keys.caster
	local target = keys.target
	if target.MeltdownCounter == nil then 
		target.MeltdownCounter = 8
	else
		target.MeltdownCounter = target.MeltdownCounter - 0.5
	end
	print(target.MeltdownCounter)
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
		DoDamage(caster, v, v:GetHealth() * target.MeltdownCounter/100, DAMAGE_TYPE_PURE, 0, keys.ability, false)
	end

end

function OnSunCleanup(keys)
	local caster = keys.caster
	local target = keys.target
	if target.metldownFx ~= nil then
		ParticleManager:DestroyParticle( target.metldownFx, false )
		ParticleManager:ReleaseParticleIndex( target.metldownFx )
		StopSoundOn("Hero_DoomBringer.ScorchedEarthAura", target)
	end
end

function GenerateArtificialSun(caster, location)
	local ply = caster:GetPlayerOwner()
	local IsSunActive = true
	local radius = 666
	local artSun = CreateUnitByName("gawain_artificial_sun", location, true, nil, nil, caster:GetTeamNumber())
	caster:FindAbilityByName("gawain_solar_embodiment"):ApplyDataDrivenModifier(caster, artSun, "modifier_artificial_sun_aura", {})
	if caster.IsDawnAcquired then
		--radius = 999
		artSun:AddNewModifier(caster, caster, "modifier_item_ward_true_sight", {true_sight_range = 333}) 
	end
	artSun:SetDayTimeVisionRange(radius)
	artSun:SetNightTimeVisionRange(radius)
	artSun:AddNewModifier(caster, caster, "modifier_kill", {duration = 15})
	artSun:SetAbsOrigin(artSun:GetAbsOrigin() + Vector(0,0, 500))


	if caster.IsDawnAcquired then
		artSun.IsAttached = true

		local targets = FindUnitsInRadius(caster:GetTeam(), location, nil, 666, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false) 
		--print("finding targets")
		if #targets == 0 then
			artSun.IsAttached = false
		else
			--print("found target " .. targets[1]:GetUnitName())
			artSun.AttachTarget = targets[1]
		end
	end

	Timers:CreateTimer(9, function()
		if IsValidEntity(artSun) and not artSun:IsNull() and artSun:IsAlive() and caster.IsComboActive ~= true then
			artSun:ForceKill(true)
		end
	end)
end

function OnSunPassiveThink(keys)
	local target = keys.target
	if target.IsAttached and target.AttachTarget ~= nil then
		target:SetAbsOrigin(target.AttachTarget:GetAbsOrigin() + Vector(0,0,500))
	end
end

function OnEmbraceStart(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local target = keys.caster --keys.target

	GenerateArtificialSun(caster, target:GetAbsOrigin())

	if caster.IsSunlightAcquired then
		keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_suns_embrace_sunlight",{})		
	elseif caster.IsEclipseAcquired then
		keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_suns_embrace_eclipse",{})
	else
		keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_suns_embrace_standard",{})
	end

	target:EmitSound("Hero_EmberSpirit.FlameGuard.Cast")
	target:EmitSound("Hero_EmberSpirit.FlameGuard.Loop")
	target:EmitSound("Hero_Chen.HandOfGodHealHero")
end

function OnEmbraceTickAlly(keys)
	local caster = keys.caster
	local target = keys.target
	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	
	if caster.IsSunlightAcquired then
		caster.EmbraceRampDamagePerTick = (keys.Damage / 32)
	end

	for k,v in pairs(targets) do
		keys.ability:ApplyDataDrivenModifier(keys.caster, v, "modifier_suns_embrace_burn",{})
	end
end

function OnEmbraceTickEnemy(keys)
	local caster = keys.caster
	local target = keys.target
	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
		keys.ability:ApplyDataDrivenModifier(keys.caster, v, "modifier_suns_embrace_burn",{})
	end
end

function OnEmbraceDamageTick(keys)
	local caster = keys.caster
	local target = keys.target
	local damage = (keys.Damage/32)

	if caster.IsSunlightAcquired then
		caster.EmbraceRampDamagePerTick = caster.EmbraceRampDamagePerTick + (keys.Damage/128)
		damage = damage + caster.EmbraceRampDamagePerTick
	end

	--[[if caster.IsDawnAcquired then
		damage = damage + (target:GetMaxHealth() / 200)
	end]]

	DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
end

function OnEmbraceEnd(keys)
	local caster = keys.caster
	local target = keys.target
	print("ended")
	StopSoundEvent("Hero_EmberSpirit.FlameGuard.Loop", caster)
end

function OnSupernovaStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = caster --keys.target --hacky way to get this thing working first
	--[[if target:HasModifier("modifier_invigorating_ray_ally") or target:HasModifier("modifier_invigorating_ray_enemy") then
	else
		FireGameEvent( 'custom_error_show', { player_ID = caster:GetPlayerOwnerID(), _error = "Must Cast Both Q and R on Same Target" } )
		keys.ability:EndCooldown()
		return
	end]]

	keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_supernova", {})
	caster.IsComboActive = true
	caster.SunTable = {}

	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(keys.ability:GetCooldown(1))
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_supernova_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})


	Timers:CreateTimer(4.0, function()
		if target:IsAlive() then
			local particle = ParticleManager:CreateParticle("particles/custom/gawain/gawain_combo.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle, 1, Vector(400, 400, 400))
			Timers:CreateTimer( 3.0, function()
				ParticleManager:DestroyParticle( particle, false )
				ParticleManager:ReleaseParticleIndex( particle )
			end)
			EmitGlobalSound("Hero_Wisp.Relocate")
		end
	end)
	Timers:CreateTimer(5.0, function()
		if target:IsAlive() then
			local particle = ParticleManager:CreateParticle("particles/custom/gawain/gawain_combo.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle, 1, Vector(550, 550, 550))
			Timers:CreateTimer( 3.0, function()
				ParticleManager:DestroyParticle( particle, false )
				ParticleManager:ReleaseParticleIndex( particle )
			end)
		end
	end)
	Timers:CreateTimer(6.0, function()
		if target:IsAlive() then
			local particle = ParticleManager:CreateParticle("particles/custom/gawain/gawain_combo.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle, 1, Vector(700, 700, 700))
			Timers:CreateTimer( 3.0, function()
				ParticleManager:DestroyParticle( particle, false )
				ParticleManager:ReleaseParticleIndex( particle )
			end)
		end
	end)
	Timers:CreateTimer(7.0, function()
		if target:IsAlive() then
			local particle = ParticleManager:CreateParticle("particles/custom/gawain/gawain_combo.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle, 1, Vector(850, 850, 850))
			Timers:CreateTimer( 3.0, function()
				ParticleManager:DestroyParticle( particle, false )
				ParticleManager:ReleaseParticleIndex( particle )
			end)
		end
	end) 
	Timers:CreateTimer(8.0, function()
		if target:IsAlive() then
			local particle = ParticleManager:CreateParticle("particles/custom/gawain/gawain_combo.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle, 1, Vector(1000, 1000, 1000))
			Timers:CreateTimer( 3.0, function()
				ParticleManager:DestroyParticle( particle, false )
				ParticleManager:ReleaseParticleIndex( particle )
			end)
		end
	end) 
	target:EmitSound("Hero_Enigma.Black_Hole")
	Timers:CreateTimer(8.0, function()
		StopSoundEvent("Hero_Enigma.Black_Hole", target)
	end)
	target:EmitSound("DOTA_Item.BlackKingBar.Activate")
end

function OnSupernovaTick(keys)
	local caster = keys.caster
	local target = keys.target

	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, 700, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
		if v:GetUnitName() == "gawain_artificial_sun" then
			if v.IsAddedToTable ~= true then
				table.insert(caster.SunTable, v)
				v.IsAddedToTable = true
				v.IsAttached = true
				v.AttachTarget = target
			end
		end
	end
end

function OnSupernovaEnd(keys)
	local caster = keys.caster
	local target = keys.target
	local sunCount = #caster.SunTable
	local dmg = keys.Damage
	caster.IsComboActive = false

	for i=1, sunCount do
		caster.SunTable[i]:ForceKill(true)
		if i-1 ~= 0 then
			dmg = dmg + keys.Damage * (0.67 ^ (i-1))
		end
	end

	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
		DoDamage(caster, v, dmg, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
		v:AddNewModifier(caster, caster, "modifier_stunned", {Duration = 2.0})
	end

	local lightFx1 = ParticleManager:CreateParticle("particles/custom/gawain/gawain_supernova_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( lightFx1, 0, target:GetAbsOrigin())
	local splashFx = ParticleManager:CreateParticle("particles/custom/screen_yellow_splash_gawain.vpcf", PATTACH_EYES_FOLLOW, caster)
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( lightFx1, false )
		ParticleManager:ReleaseParticleIndex( lightFx1 )
		ParticleManager:DestroyParticle( splashFx, false )
		ParticleManager:ReleaseParticleIndex( splashFx )
	end)
	EmitGlobalSound("Hero_Phoenix.SuperNova.Explode")
	StopSoundEvent("Hero_Enigma.Black_Hole", target)
end

function OnDevoteConsecutiveHit(keys)
	local caster = keys.caster
	local target = keys.target
	local damage = keys.Damage

	if caster.IsEclipseAcquired then
		damage = damage + caster.BonusDevoteDamage
		caster.BonusDevoteDamage = caster.BonusDevoteDamage + (keys.Damage)
	end		 

	DoDamage(caster, target, damage, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)

	target:EmitSound("Hero_Invoker.ColdSnap")
	local lightFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_sun_strike_beam.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( lightFx1, 0, target:GetAbsOrigin())
	local flameFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_fire_spirit_ground.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( flameFx1, 0, target:GetAbsOrigin())
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( lightFx1, false )
		ParticleManager:ReleaseParticleIndex( lightFx1 )
		ParticleManager:DestroyParticle( flameFx1, false )
		ParticleManager:ReleaseParticleIndex( flameFx1 )
	end)
end

function OnIRStart(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local target = keys.target

	if target:GetName() == "npc_dota_ward_base" then 
		keys.ability:EndCooldown()
		caster:GiveMana(keys.ability:GetManaCost(1))
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Be_Cast_Now")
		return
	end

	GawainCheckCombo(caster, keys.ability)
	GenerateArtificialSun(caster, target:GetAbsOrigin())

	if caster.IsSunlightAcquired then
		caster.BonusSolarRayDamage = 0
	end

	if target:GetTeamNumber() == caster:GetTeamNumber() then
		target:EmitSound("Hero_Omniknight.Purification")
		keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_invigorating_ray_ally", {})
		if caster.IsSunlightAcquired then
			keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_invigorating_ray_armor_buff", {})
		end
	else
		if IsSpellBlocked(keys.target) then return end
		target:EmitSound("Hero_Omniknight.Purification")
		keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_invigorating_ray_enemy", {})
	end
	local lightFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_sun_strike_beam.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( lightFx1, 0, target:GetAbsOrigin())
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( lightFx1, false )
		ParticleManager:ReleaseParticleIndex( lightFx1 )
	end)
end

function OnIRTickAlly(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local target = keys.target

	target:ApplyHeal(keys.Damage/10 * 0.5, caster)
end

function OnIRTickEnemy(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local target = keys.target
	local damage = (keys.Damage/10)	
	
	if caster.IsSunlightAcquired then
		damage = damage + caster.BonusSolarRayDamage
		caster.BonusSolarRayDamage = caster.BonusSolarRayDamage + (keys.Damage / 40)		
	end

	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, keys.ability, false)
end


--========================================================================================================
--										Unused Attributes
--========================================================================================================


function OnDawnAcquired(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsDawnAcquired = true
    hero:FindAbilityByName("gawain_solar_embodiment"):SetLevel(2)
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function OnMeltdownAcquired(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsMeltdownAcquired = true
    hero:SwapAbilities(hero:GetAbilityByIndex(4):GetName(), "gawain_divine_meltdown", false, true)
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnSunlightAcquired(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()

    hero.IsSunlightAcquired = true
    caster:FindAbilityByName("gawain_attribute_eclipse"):StartCooldown(9999)
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnEclipseAcquired(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()

    hero.IsEclipseAcquired = true
    caster:FindAbilityByName("gawain_attribute_sunlight"):StartCooldown(9999)
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

