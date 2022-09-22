gawain_heat = class({})

LinkLuaModifier("modifier_gawain_heat", "abilities/gawain/modifiers/modifier_gawain_heat", LUA_MODIFIER_MOTION_NONE)

function gawain_heat:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function gawain_heat:GetAbilityDamageType()
	return DAMAGE_TYPE_MAGICAL
end

function gawain_heat:OnSpellStart()
	local caster = self:GetCaster()
	local stack_damage = self:GetSpecialValueFor("stack_damage")

	--[[if caster.IsBeltAcquired then
		stack_damage = stack_damage + 8
	end]]

	caster:EmitSound("Gawain_Skill1")
	caster:AddNewModifier(caster, self, "modifier_gawain_heat", { Duration = self:GetSpecialValueFor("duration"),
																  BurnDamage = self:GetSpecialValueFor("burn_damage"),
																  AttackSpeed = self:GetSpecialValueFor("attack_speed"),
																  StackDamage = stack_damage,
																  Radius = self:GetSpecialValueFor("radius")

	})

	self:CheckCombo()
end

function gawain_heat:CheckCombo()
	local caster = self:GetCaster()

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then		
		if caster:FindAbilityByName("gawain_excalibur_galatine"):IsCooldownReady() 
		and caster:FindAbilityByName("gawain_excalibur_galatine_combo"):IsCooldownReady() 
		and caster:GetAbilityByIndex(5):GetName() ~= "gawain_excalibur_galatine_combo" 
		and caster:GetAbilityByIndex(5):GetName() ~= "gawain_excalibur_galatine_detonate_combo" 
		and caster:HasModifier("modifier_blade_devoted_self")
		then
			caster:SwapAbilities("gawain_excalibur_galatine", "gawain_excalibur_galatine_combo", false, true) 

			Timers:CreateTimer(5.0, function()
				local ability = caster:GetAbilityByIndex(5)
				if (ability:GetName() ~= "gawain_excalibur_galatine" 
					and not caster.IsGalatineActive) or not caster:IsAlive() then
					caster:SwapAbilities("gawain_excalibur_galatine", ability:GetName(), true, false) 
				end				
			end)
		end
	end
end



--[[function StartHeat(keys)
	local caster = keys.caster
	local ability = keys.ability

	ability:ApplyDataDrivenModifier(caster,caster,"modifier_gawain_heat_radiance",{})

	GawainCheckCombo(caster, ability)
end

function StopSound(keys)
	StopSoundEvent( "Hero_EmberSpirit.FlameGuard.Loop", keys.target )
end

function StackHeatDamage(keys)
	local caster = keys.caster
	local target = keys.target
	local stacks = 0
	local damage = keys.Damage

	if caster.IsBeltAcquired then
		--keys.ability:ApplyDataDrivenModifier(caster,target,"modifier_gawain_heat_slow",{duration=3.0})
		damage = damage + 12
	end

	if target:HasModifier("modifier_gawain_heat_stack_damage") then
		stacks = target:GetModifierStackCount("modifier_gawain_heat_stack_damage", keys.ability)
		target:RemoveModifierByName("modifier_gawain_heat_stack_damage") 		
	end

	keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_gawain_heat_stack_damage", {duration=3.0}) 
	target:SetModifierStackCount("modifier_gawain_heat_stack_damage", keys.ability, stacks + 1)

	DoDamage(caster, target, damage * (stacks + 1), DAMAGE_TYPE_PHYSICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, keys.ability, false)
	--target:EmitSound("Hero_Phoenix.ColdSnap")
end

function RadianceBurnEnemiesThink(keys)
	local caster = keys.caster
	local target = keys.target
	local damage = keys.Damage

	--print(damage)
	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetOrigin(), nil, keys.Radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
        DoDamage(caster, v, damage * 0.1, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
    end
end


function GawainCheckCombo(caster, ability)
	if caster:GetStrength() >= 19.1 and caster:GetAgility() >= 19.1 and caster:GetIntellect() >= 19.1 then
		if ability == caster:FindAbilityByName("gawain_heat") 
			and caster:FindAbilityByName("gawain_excalibur_galatine"):IsCooldownReady() 
			and caster:FindAbilityByName("gawain_excalibur_galatine_combo"):IsCooldownReady() 
			and caster:HasModifier("modifier_blade_of_the_devoted")
			then

			--EmitGlobalSound("Hero_Enigma.Black_Hole")
			EmitGlobalSound("gawain_kill_02")

			caster:FindAbilityByName("gawain_excalibur_galatine_combo"):StartCooldown(2)
			caster:SwapAbilities("gawain_excalibur_galatine", "gawain_excalibur_galatine_combo", false, true) 

			Timers:CreateTimer(5.0, function()
				local ability = caster:GetAbilityByIndex(5)
				if (ability:GetName() ~= "gawain_excalibur_galatine" and not caster.IsGalatineActive) or not caster:IsAlive() then
					caster:SwapAbilities("gawain_excalibur_galatine", ability:GetName(), true, false) 
				end				
			end)	
		end
	end
end
]]