LinkLuaModifier("modifier_weakening_venom", "abilities/true_assassin/modifiers/modifier_weakening_venom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_perfect_agony_penalty", "abilities/true_assassin/modifiers/modifier_perfect_agony_penalty", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zabaniya_curse", "abilities/true_assassin/modifiers/modifier_zabaniya_curse", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_prot_wind_resist", "abilities/true_assassin/modifiers/modifier_prot_wind_resist", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shadow_strike_upgrade", "abilities/true_assassin/modifiers/modifier_shadow_strike_upgrade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shaytan_arm_attribute", "abilities/true_assassin/modifiers/modifier_shaytan_arm_attribute", LUA_MODIFIER_MOTION_NONE)


function OnDirkStart(keys)
	local caster = keys.caster
	local target = keys.target
	local maxTarget = keys.MaxTarget
	if IsSpellBlocked(keys.target) then return end
	local range = caster:GetRangeToUnit(target)
	if keys.Range > range then
		range =  keys.Range
	end
	range = range + 100 -- buffer
	local info = {
		Target = target,
		Source = caster, 
		Ability = keys.ability,
		EffectName = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		iMoveSpeed = 1800
	}
	ProjectileManager:CreateTrackingProjectile(info) 
	local targetCount = 1
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, range
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)
	for k,v in pairs(targets) do
		--if v:CanEntityBeSeenByMyTeam(caster) then
		if v ~= target then
			targetCount = targetCount + 1
	        info.Target = v
	        ProjectileManager:CreateTrackingProjectile(info)
	    end 
	    --end
        if targetCount == maxTarget then return end
    end
end

function OnDirkHit(keys)
	local caster = keys.caster
	local target = keys.target
	local ply = caster:GetPlayerOwner()
	if IsSpellBlocked(keys.target) then return end -- Linken effect checker

	--[[if caster.IsWeakeningVenomAcquired then
		keys.ability:ApplyDataDrivenModifier(keys.caster, keys.target, "modifier_dirk_poison_empowered", {}) 
		if not IsImmuneToSlow(keys.target) then 
			keys.ability:ApplyDataDrivenModifier(keys.caster, keys.target, "modifier_dirk_poison_empowered_slow", {}) 
		end
	else
	end]]

	if not IsImmuneToSlow(keys.target) then 
		keys.ability:ApplyDataDrivenModifier(keys.caster, keys.target, "modifier_dirk_poison", {}) 
	end	 

	local damage = caster:GetAverageTrueAttackDamage(caster)
	if damage > keys.Damage then keys.Damage = damage end

	if caster.IsWeakeningVenomAcquired then
		local stacks = 0
		if target:HasModifier("modifier_weakening_venom_debuff") then 
			stacks = target:GetModifierStackCount("modifier_weakening_venom_debuff", keys.ability)
		end		

		target:RemoveModifierByName("modifier_weakening_venom_debuff") 
		keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_weakening_venom_debuff", {}) 
		target:SetModifierStackCount("modifier_weakening_venom_debuff", keys.ability, stacks + 4)

		DoDamage(keys.caster, keys.target, keys.Damage, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
	else
		DoDamage(keys.caster, keys.target, keys.Damage, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
	end
end

function OnDirkPoisonTick(keys)
	local caster = keys.caster
	local target = keys.target
	local dmg = keys.Damage * 0.5
	local currentStack = 0
	local damage_type = DAMAGE_TYPE_MAGICAL

	if caster.IsWeakeningVenomAcquired then
		damage_type = DAMAGE_TYPE_PURE
	end

	--print(target:HasModifier("modifier_weakening_venom_debuff"))
	if target:HasModifier("modifier_weakening_venom_debuff") then 
		currentStack = target:GetModifierStackCount("modifier_weakening_venom_debuff", keys.ability)
		--print(currentStack)
	end

	dmg = dmg + (dmg * currentStack)

	DoDamage(keys.caster, keys.target, dmg, damage_type, 0, keys.ability, false)
end

function OnVenomHit(keys)
	local caster = keys.caster
	local target = keys.target 
	local ability = keys.ability

	--[[if caster:GetMana() > 50 then
		local stacks = 0
		if target:HasModifier("modifier_weakening_venom") then 
			stacks = target:GetModifierStackCount("modifier_weakening_venom", ability)
		end		

		target:RemoveModifierByName("modifier_weakening_venom") 
		target:AddNewModifier(caster, ability, "modifier_weakening_venom", { duration = 12 })
		target:SetModifierStackCount("modifier_weakening_venom", ability, stacks + 1)

		local dirkAbility = caster:FindAbilityByName("true_assassin_dirk")

		if not dirkAbility:IsCooldownReady() then
			local dirkCooldown = dirkAbility:GetCooldownTimeRemaining()
			dirkAbility:EndCooldown()

			if dirkCooldown > 1 then
				dirkAbility:StartCooldown(dirkCooldown - 1)
			end
		end

		caster:SetMana(caster:GetMana() - 50)
	end

	if target:HasModifier("modifier_weakening_venom") then 
		currentStack = target:GetModifierStackCount("modifier_weakening_venom", keys.ability)
	end

	target:RemoveModifierByName("modifier_weakening_venom") 
	keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_weakening_venom_debuff", {}) 
	target:SetModifierStackCount("modifier_weakening_venom_debuff", keys.ability, currentStack + 1)]]
end


function OnPCStart(keys)
end

function OnPCAbilityUsed(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	caster.LastActionTime = GameRules:GetGameTime() 
	caster:RemoveModifierByName("modifier_ta_invis")
	Timers:CreateTimer(keys.CastDelay, function() 
		if GameRules:GetGameTime() >= caster.LastActionTime + keys.CastDelay then
			keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_ta_invis", {}) 
			if not caster.IsPCImproved then PCStopOrder(keys) return end
		end
	end)
end

function OnStealAbilityStart(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	caster.bIsVisibleToEnemy = false
	LoopOverPlayers(function(player, playerID, playerHero)
		-- if enemy hero can see astolfo, set visibility to true
		if playerHero:GetTeamNumber() ~= caster:GetTeamNumber() then
			if playerHero:CanEntityBeSeenByMyTeam(caster) then
				caster.bIsVisibleToEnemy = true
				return
			end
		end
	end)
end

function OnPCAttacked(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	caster.LastActionTime = GameRules:GetGameTime() 

	caster:RemoveModifierByName("modifier_ta_invis")
	Timers:CreateTimer(keys.CastDelay, function() 
		if GameRules:GetGameTime() >= caster.LastActionTime + keys.CastDelay then
			keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_ta_invis", {}) 
			if not caster.IsPCImproved then PCStopOrder(keys) return end
		end
	end)
end

function OnPCMoved(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	if caster.IsPCImproved then return end
	caster.LastActionTime = GameRules:GetGameTime() 

	caster:RemoveModifierByName("modifier_ta_invis")
	Timers:CreateTimer(keys.CastDelay, function() 
		if GameRules:GetGameTime() >= caster.LastActionTime + keys.CastDelay then
			keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_ta_invis", {}) 
			if not caster.IsPCImproved then PCStopOrder(keys) return end
		end
	end)
end

function OnPCRespawn(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	caster.LastActionTime = GameRules:GetGameTime() 
	caster:RemoveModifierByName("modifier_ta_invis")
	Timers:CreateTimer(keys.CastDelay, function() 
		if GameRules:GetGameTime() >= caster.LastActionTime + keys.CastDelay then
			keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_ta_invis", {}) 
			if not caster.IsPCImproved then PCStopOrder(keys) return end
		end
	end)
end

function OnPCDamageTaken(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	caster.LastActionTime = GameRules:GetGameTime() 
	caster:RemoveModifierByName("modifier_ta_invis")
	Timers:CreateTimer(keys.CastDelay, function() 
		if GameRules:GetGameTime() >= caster.LastActionTime + keys.CastDelay then
			keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_ta_invis", {}) 
			if not caster.IsPCImproved then PCStopOrder(keys) return end
		end
	end)
end

function PCStopOrder(keys)
	--keys.caster:Stop() 
	local stopOrder = {
		UnitIndex = keys.caster:entindex(),
		OrderType = DOTA_UNIT_ORDER_HOLD_POSITION
	}
	ExecuteOrderFromTable(stopOrder) 
end


function OnDIStart(keys)
	local caster = keys.caster
	local pid = caster:GetPlayerID()
	local ability = keys.ability
	local DICount = 0
	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(keys.ability:GetCooldown(1))
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_delusional_illusion_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})
	
	--caster:EmitSound("TA.Darkness")
	EmitGlobalSound("Hassan_Combo")

	Timers:CreateTimer(function()
		if DICount > 8.0 or not caster:IsAlive() then return end 
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 650
	            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			if v.IsDIOnCooldown ~= true then 
				--print("Target " .. v:GetName() .. " detected")
				--for ilu = 0, 2 do
				
				--end
				CreateDIDummies(caster, v)
			end
		end
		DICount = DICount + 0.33
		return 0.33
	end)
end

function CreateDIDummies(caster, target)
	target.IsDIOnCooldown = true

	local origin = target:GetAbsOrigin() + RandomVector(650) 
	local illusion = CreateUnitByName("ta_combo_dummy", origin, false, caster, caster, caster:GetTeamNumber()) 
	local illusionskill = illusion:FindAbilityByName("true_assassin_combo_zab") 
	illusionskill:SetLevel(1)
	illusion:SetForwardVector(target:GetAbsOrigin() - illusion:GetAbsOrigin())
	illusion:CastAbilityOnTarget(target, illusionskill, 1)
	StartAnimation(illusion, {duration = 5, activity = ACT_DOTA_ATTACK, rate = 1}) --maybe take this out

	local origin = target:GetAbsOrigin() + RandomVector(550) 
	local illusion2 = CreateUnitByName("ta_combo_dummy_2", origin, false, caster, caster, caster:GetTeamNumber()) 
	local illusionskill2 = illusion2:FindAbilityByName("true_assassin_combo_zab") 
	illusionskill2:SetLevel(1)
	illusion2:SetForwardVector(target:GetAbsOrigin() - illusion2:GetAbsOrigin())
	illusion2:CastAbilityOnTarget(target, illusionskill2, 1)
	StartAnimation(illusion2, {duration = 5, activity = ACT_DOTA_ATTACK, rate = 1}) --maybe take this out

	local origin = target:GetAbsOrigin() + RandomVector(450) 
	local illusion3 = CreateUnitByName("ta_combo_dummy_3", origin, false, caster, caster, caster:GetTeamNumber()) 
	local illusionskill3 = illusion3:FindAbilityByName("true_assassin_combo_zab") 
	illusionskill3:SetLevel(1)
	illusion3:SetForwardVector(target:GetAbsOrigin() - illusion3:GetAbsOrigin())
	illusion3:CastAbilityOnTarget(target, illusionskill3, 1)
	StartAnimation(illusion3, {duration = 5, activity = ACT_DOTA_ATTACK, rate = 2}) --maybe take this out

	Timers:CreateTimer(3.0, function() 
		illusion:RemoveSelf()
		illusion2:RemoveSelf()
		illusion3:RemoveSelf()
		target.IsDIOnCooldown = false 
	return end)
end

function OnDIZabStart(keys)
	local caster = keys.caster
	local target = keys.target
	local ply = caster:GetPlayerOwner()
	local ability = keys.ability

	local speed = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()

	local info = {
		Target = target,
		Source = caster, 
		Ability = keys.ability,
		EffectName = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf",
		vSpawnOrigin = caster,
		iMoveSpeed = 700
	}
	ProjectileManager:CreateTrackingProjectile(info) 
	--local particle = ParticleManager:CreateParticle("particles/custom/ta/zabaniya_fiendsgrip_hands_combo.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	--ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin()) -- target effect location
	--ParticleManager:SetParticleControl(particle, 2, target:GetAbsOrigin()) -- circle effect location
	local smokeFx = ParticleManager:CreateParticle("particles/custom/ta/zabaniya_ulti_smoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(smokeFx, 0, caster:GetAbsOrigin())
	--local smokeFx2 = ParticleManager:CreateParticle("particles/custom/ta/zabaniya_ulti_smoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	--ParticleManager:SetParticleControl(smokeFx2, 0, target:GetAbsOrigin())
	local smokeFx3 = ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_loadout.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(smokeFx3, 0, caster:GetAbsOrigin())
	
	EmitGlobalSound("TA.Darkness") 
	caster:EmitSound("Hero_PhantomAssassin.Dagger.Cast") 

	-- Destroy particle after delay
	Timers:CreateTimer( 2.0, function()
			--ParticleManager:DestroyParticle( particle, false )
			--ParticleManager:ReleaseParticleIndex( particle )
			ParticleManager:DestroyParticle( smokeFx, false )
			ParticleManager:ReleaseParticleIndex( smokeFx )
			--ParticleManager:DestroyParticle( smokeFx2, false )
			--ParticleManager:ReleaseParticleIndex( smokeFx2 )
			ParticleManager:DestroyParticle( smokeFx3, false )
			ParticleManager:ReleaseParticleIndex( smokeFx3 )
			return nil
	end)
end

function OnDIZabHit(keys)
	print("Projectile hit")
	local caster = keys.caster
	local ply = keys.caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()
	local damage = hero:FindAbilityByName("true_assassin_zabaniya"):GetLevel() * 25 + 500
	if caster.IsShadowStrikeAcquired then 
		damage = damage + 100
	end
	keys.target:EmitSound("Hero_PhantomAssassin.Dagger.Target")
	DoDamage(hero, keys.target, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
end

function DIBleed(keys)
	local caster = keys.caster
	local ply = keys.caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()
	local damage = hero:FindAbilityByName("true_assassin_zabaniya"):GetLevel() * 10 + 10
	local bleedCounter = 0

	Timers:CreateTimer(function() 
		if bleedCounter == 5 then return end
		DoDamage(hero, keys.target, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
		bleedCounter = bleedCounter + 1
		return 1.0
	end)	
end

function OnAmbushStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	--caster:AddNewModifier(caster, caster, "modifier_invisible", {Duration = 12.0})
	if caster.IsPCImproved then
		--[[local team = 0
		if caster:GetTeam() == DOTA_TEAM_GOODGUYS then 
			team = DOTA_TEAM_BADGUYS 
		else 
			team = DOTA_TEAM_GOODGUYS
		end]]
		--local units = FindUnitsInRadius(enemyTeamNumber, caster:GetAbsOrigin(), nil, 2500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
		local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 1600, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
		for i=1, #units do
			print(units[i]:GetUnitName())
			if units[i]:GetUnitName() == "ward_familiar" then
				local visiondummy = CreateUnitByName("sight_dummy_unit", units[i]:GetAbsOrigin(), false, keys.caster, keys.caster, keys.caster:GetTeamNumber())
				visiondummy:SetDayTimeVisionRange(500)
				visiondummy:SetNightTimeVisionRange(500)
				AddFOWViewer(caster:GetTeamNumber(), visiondummy:GetAbsOrigin(), 500, 5.0, false)
				visiondummy:AddNewModifier(caster, caster, "modifier_item_ward_true_sight", {true_sight_range = 100}) 
				local unseen = visiondummy:FindAbilityByName("dummy_unit_passive")
				unseen:SetLevel(1)
				Timers:CreateTimer(5.0, function()
					if IsValidEntity(visiondummy) and not visiondummy:IsNull() then
						visiondummy:RemoveSelf()
					end 
				end)
				break
			end
		end 
	end

	Timers:CreateTimer(0.3, function()
		if caster:IsAlive() then
			if caster.IsPCImproved then
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_ambush_empowered", {})
			else
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_ambush", {})
			end			
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_first_hit", {})
		end
	end)
	TACheckCombo(caster, keys.ability)
end

function OnAmbushBroken(keys)
	keys.caster:RemoveModifierByName("modifier_ambush")
end

function OnFirstHitStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:RemoveModifierByName("modifier_ambush")
	caster:RemoveModifierByName("modifier_first_hit")
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_thrown", {}) 
end

function OnFirstHitLanded(keys)
	local hero = keys.caster:GetPlayerOwner():GetAssignedHero()
	if IsSpellBlocked(keys.target) then keys.caster:RemoveModifierByName("modifier_thrown") return end -- Linken effect checker

	if keys.target:GetName() == "npc_dota_ward_base" then
		DoDamage(keys.caster, keys.target, 2, DAMAGE_TYPE_PURE, 0, keys.ability, false)
	else
		DoDamage(keys.caster, keys.target, keys.Damage, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
	end
	keys.caster:EmitSound("Hero_TemplarAssassin.Meld.Attack")
	keys.caster:RemoveModifierByName("modifier_thrown")
	keys.caster:RemoveModifierByName("modifier_ambush")
end

function OnAbilityCast(keys)
	Timers:CreateTimer({
		endTime = 0.033,
		callback = function()
		keys.caster:RemoveModifierByName("modifier_ambush")
	end
	})
	keys.caster:RemoveModifierByName("modifier_first_hit")
end

function OnModStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local fHeal = keys.HealAmount

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_ta_self_mod", {})
	caster:ApplyHeal(fHeal, caster)

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_bane/bane_fiendsgrip_ground_rubble.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin())
	-- Destroy particle after delay
	Timers:CreateTimer( 2.0, function()
			ParticleManager:DestroyParticle( particle, false )
			ParticleManager:ReleaseParticleIndex( particle )
			return nil
	end)
	TACheckCombo(caster, keys.ability) 
	--increase stat
end

function SelfModRefresh(keys)
	local caster = keys.caster
	caster:RemoveModifierByName("modifier_ta_agi_bonus")
	caster:FindAbilityByName("true_assassin_self_modification"):ApplyDataDrivenModifier(caster, caster, "modifier_ta_agi_bonus", {}) 
	caster:SetModifierStackCount("modifier_ta_agi_bonus", caster, caster:GetKills())
end

function OnStealStart(keys)
	if IsSpellBlocked(keys.target) then return end -- Linken effect checker
	local caster = keys.caster
	local ply = caster:GetPlayerOwner() 
	local target = keys.target
	local ability = keys.ability
	local damage = keys.Damage

	damage = damage * target:GetHealth() / 100 

	local attackRatio = ability:GetSpecialValueFor("attack_ratio") * caster:GetAverageTrueAttackDamage(caster) / 100

	damage = damage + attackRatio
	--print(damage)

	--ability:ApplyDataDrivenModifier(caster, target, "modifier_steal_str_reduction", {})
	--ability:ApplyDataDrivenModifier(caster, caster, "modifier_steal_str_increase", {})	--It increases agi now

	--[[if not caster.IsShadowStrikeAcquired then
		local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
		caster:SetAbsOrigin(target:GetAbsOrigin() - diff*100)
		FindClearSpaceForUnit( caster, caster:GetAbsOrigin(), true )
	end]]

	--[[if caster.IsShadowStrikeAcquired then
		damage = damage 
	end]]

	--print(caster.bIsVisibleToEnemy)
	--[[if (caster:HasModifier("modifier_ambush") or not caster.bIsVisibleToEnemy) and caster.IsShadowStrikeAcquired then
		damage = damage + 300
		ability:ApplyDataDrivenModifier(caster, target, "modifier_steal_vision", {})
	end]]
	DoDamage(caster, target, damage, DAMAGE_TYPE_PHYSICAL, 0, ability, false)

	caster:Heal(damage / 2, caster)
end

function OnZabCastStart(keys)
	local caster = keys.caster
	local target = keys.target
	local smokeFx = ParticleManager:CreateParticleForTeam("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_loadout.vpcf", PATTACH_CUSTOMORIGIN, target, caster:GetTeamNumber())
	ParticleManager:SetParticleControl(smokeFx, 0, caster:GetAbsOrigin())
	caster.LastActionTime = GameRules:GetGameTime()  -- Zab cast should be classified as an action that resets 2s timer for Presence Concealment.
	caster.bIsVisibleToEnemy = false
	LoopOverPlayers(function(player, playerID, playerHero)
		-- if enemy hero can see astolfo, set visibility to true
		if playerHero:GetTeamNumber() ~= caster:GetTeamNumber() then
			if playerHero:CanEntityBeSeenByMyTeam(caster) then
				caster.bIsVisibleToEnemy = true
				return
			end
		end
	end)
end

function OnZabStart(keys)
	local caster = keys.caster
	local target = keys.target
	local projectileSpeed = 950

	if caster.IsShadowStrikeAcquired then
		projectileSpeed = 750
	end


	local info = {
		Target = keys.target,
		Source = caster, 
		Ability = keys.ability,
		EffectName = "particles/custom/ta/zabaniya_projectile.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		iMoveSpeed = projectileSpeed
	}

	--print(caster.bIsVisibleToEnemy)
	--if (caster:HasModifier("modifier_ambush") or not caster.bIsVisibleToEnemy) then caster.IsShadowStrikeActivated = true end
	--if caster:HasModifier("modifier_ambush") then caster.IsShadowStrikeActivated = true end

	ProjectileManager:CreateTrackingProjectile(info) 
	Timers:CreateTimer({
		endTime = 0.033,
		callback = function()
		local smokeFx = ParticleManager:CreateParticle("particles/custom/ta/zabaniya_ulti_smoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(smokeFx, 0, caster:GetAbsOrigin())
		local smokeFx2 = ParticleManager:CreateParticle("particles/custom/ta/zabaniya_ulti_smoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:SetParticleControl(smokeFx2, 0, target:GetAbsOrigin())
		local smokeFx3 = ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_loadout.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(smokeFx3, 0, target:GetAbsOrigin())

		-- Destroy particle after delay
		Timers:CreateTimer( 2.0, function()
				ParticleManager:DestroyParticle( smokeFx, false )
				ParticleManager:ReleaseParticleIndex( smokeFx )
				ParticleManager:DestroyParticle( smokeFx2, false )
				ParticleManager:ReleaseParticleIndex( smokeFx2 )
				ParticleManager:DestroyParticle( smokeFx3, false )
				ParticleManager:ReleaseParticleIndex( smokeFx3 )
				return nil
		end)

		EmitGlobalSound("TA.Zabaniya") 
		target:EmitSound("TA.Darkness") 
	end
	})
end

function OnZabHit(keys)
	if IsSpellBlocked(keys.target) then return end -- Linken effect checker
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local target = keys.target
	local stunduration = keys.StunDuration

	local blood = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_culling_blade_kill_b.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(blood, 4, target:GetAbsOrigin())
	ParticleManager:SetParticleControlEnt(blood, 1, target , 0, "attach_hitloc", target:GetAbsOrigin(), false)

	local shadowFx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(shadowFx, 0, target:GetAbsOrigin())
	local smokeFx3 = ParticleManager:CreateParticle("particles/custom/ta/zabaniya_fiendsgrip_hands.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl(smokeFx3, 0, target:GetAbsOrigin())

	-- Destroy particle after delay
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( blood, false )
		ParticleManager:ReleaseParticleIndex( blood )
		ParticleManager:DestroyParticle( shadowFx, false )
		ParticleManager:ReleaseParticleIndex( shadowFx )
		return nil
	end)

	local curseDuration = 1.5
	local damage_type = DAMAGE_TYPE_MAGICAL

	if caster.IsShadowStrikeAcquired then
		curseDuration = 2.5
		damage_type = DAMAGE_TYPE_PURE
		keys.Damage = keys.Damage - keys.damage * 0.25
	end
	
	--if not keys.target:IsMagicImmune() then
	DoDamage(keys.caster, keys.target, keys.Damage, damage_type, 0, keys.ability, false)
	target:AddNewModifier(caster, keys.ability, "modifier_zabaniya_curse", { Duration = curseDuration })
	local cursedHealth = target:GetHealth()

	Timers:CreateTimer(function()
		if not target:HasModifier("modifier_zabaniya_curse") or not caster:IsAlive() then return end
			
  		if target:GetHealth() <= 0 then
			target:Execute(keys.ability, caster)
		elseif target:GetHealth() > cursedHealth then
			target:SetHealth(cursedHealth)
		end

		cursedHealth = target:GetHealth()

		return 0.033
	end)
	--end

	--keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_zabaniya_curse", {duration = curseDuration})

	
end

AmbushUsed = false

function TACheckCombo(caster, ability)
	if caster:GetStrength() >= 19.1 and caster:GetAgility() >= 19.1 and caster:GetIntellect() >= 19.1 then
		if ability == caster:FindAbilityByName("true_assassin_self_modification") then
			AmbushUsed = true
			Timers:CreateTimer({
				endTime = 5,
				callback = function()
				AmbushUsed = false
			end
			})
		elseif ability == caster:FindAbilityByName("true_assassin_ambush") and caster:FindAbilityByName("true_assassin_combo"):IsCooldownReady()  then
			if AmbushUsed == true then 
				caster:SwapAbilities("true_assassin_ambush", "true_assassin_combo", false, true)
				Timers:CreateTimer({
					endTime = 8,
					callback = function()
					caster:SwapAbilities("true_assassin_ambush", "true_assassin_combo", true, false)
				end
				})
			end
		end
	end
end

--requires presence detect mechanism
function OnImprovePresenceConcealmentAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsPCImproved = true
	hero:FindAbilityByName("true_assassin_ambush"):SetLevel(2) 

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnProtectionFromWindAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local ability = keys.ability
	hero.IsPFWAcquired = true
	hero:FindAbilityByName("true_assassin_protection_from_wind"):SetLevel(1) 	

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    hero:AddNewModifier(hero, ability, "modifier_prot_wind_resist",	{})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnWeakeningVenomAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local ability = keys.ability
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsWeakeningVenomAcquired = true
	hero:FindAbilityByName("true_assassin_weakening_venom_passive"):SetLevel(1)
	--hero:FindAbilityByName("true_assassin_dirk"):SetLevel(2)
	--hero:SwapAbilities("true_assassin_dirk", "true_assassin_dirk_attr_temp", true, true) 

	--local penalty = ability:GetSpecialValueFor("attack_penalty")

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    hero:AddNewModifier(hero, ability, "modifier_perfect_agony_penalty", {} )
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnShaytanArmAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local ability = keys.ability
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.ShaytanArmAcquired = true
	
	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    hero:AddNewModifier(hero, ability, "modifier_shaytan_arm_attribute", {} )
			return nil
		else
			return 1
		end
	end)
	
	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnShadowStrikeAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsShadowStrikeAcquired = true

	hero:AddNewModifier(caster, keys.ability, "modifier_shadow_strike_upgrade", {})

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function ReduceVision( keys )
	local target = keys.target
	local ability = keys.ability
	local blind = ability:GetSpecialValueFor("set_vision")

	target.ori_day_vision = target:GetBaseDayTimeVisionRange()
	target.ori_night_vision = target:GetBaseNightTimeVisionRange()
	print(target:GetBaseDayTimeVisionRange(),target:GetBaseNightTimeVisionRange())

	target:SetDayTimeVisionRange(blind)
	target:SetNightTimeVisionRange(blind)
end

function RevertVision( keys )
	local target = keys.target
	target:SetDayTimeVisionRange(target.ori_day_vision)
	target:SetNightTimeVisionRange(target.ori_night_vision)
end