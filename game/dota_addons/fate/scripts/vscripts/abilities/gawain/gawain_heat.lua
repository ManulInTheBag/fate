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

	local direction = caster:GetForwardVector()

 
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


 