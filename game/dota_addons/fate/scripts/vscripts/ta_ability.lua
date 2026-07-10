LinkLuaModifier("modifier_perfect_agony_penalty", "abilities/true_assassin/modifiers/modifier_perfect_agony_penalty", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shadow_strike_upgrade", "abilities/true_assassin/modifiers/modifier_shadow_strike_upgrade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shaytan_arm_attribute", "abilities/true_assassin/modifiers/modifier_shaytan_arm_attribute", LUA_MODIFIER_MOTION_NONE)


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

	EmitGlobalSound("Hassan_Combo")

	Timers:CreateTimer(function()
		if DICount > ability:GetSpecialValueFor("duration") or not caster:IsAlive() then return end
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, ability:GetSpecialValueFor("search_radius")
	            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			if v.IsDIOnCooldown ~= true then
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

	local info = {
		Target = target,
		Source = caster,
		Ability = keys.ability,
		EffectName = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf",
		vSpawnOrigin = caster,
		iMoveSpeed = 700
	}
	ProjectileManager:CreateTrackingProjectile(info)
	local smokeFx = ParticleManager:CreateParticle("particles/custom/ta/zabaniya_ulti_smoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(smokeFx, 0, caster:GetAbsOrigin())
	local smokeFx3 = ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_loadout.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(smokeFx3, 0, caster:GetAbsOrigin())

	EmitGlobalSound("TA.Darkness")
	caster:EmitSound("Hero_PhantomAssassin.Dagger.Cast")

	-- Destroy particle after delay
	Timers:CreateTimer( 2.0, function()
			ParticleManager:DestroyParticle( smokeFx, false )
			ParticleManager:ReleaseParticleIndex( smokeFx )
			ParticleManager:DestroyParticle( smokeFx3, false )
			ParticleManager:ReleaseParticleIndex( smokeFx3 )
			return nil
	end)
end

function OnDIZabHit(keys)
	local caster = keys.caster
	local ply = keys.caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()
	local comboAbility = hero:FindAbilityByName("true_assassin_combo")
	local damage = hero:FindAbilityByName("true_assassin_zabaniya"):GetLevel() * comboAbility:GetSpecialValueFor("bonus_damage")
				 + comboAbility:GetSpecialValueFor("base_damage")
	if hero.IsShadowStrikeAcquired then
		damage = damage + 100
	end
	keys.target:EmitSound("Hero_PhantomAssassin.Dagger.Target")
	DoDamage(hero, keys.target, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
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

function OnWeakeningVenomAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local ability = keys.ability
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsWeakeningVenomAcquired = true

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
