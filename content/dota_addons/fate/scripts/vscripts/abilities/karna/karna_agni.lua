karna_agni = class({})

LinkLuaModifier("modifier_agni_karna", "abilities/karna/modifiers/modifier_agni_karna", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_armor_returned", "abilities/karna/modifiers/modifier_armor_returned", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_karna_combo_window", "abilities/karna/modifiers/modifier_karna_combo_window", LUA_MODIFIER_MOTION_NONE)

function karna_agni:OnSpellStart()
	local caster = self:GetCaster()

	caster:EmitSound("karna_skill_" .. math.random(1,4))

	caster:AddNewModifier(caster, self, "modifier_agni_karna", { Duration = self:GetSpecialValueFor("duration"),
																 OnHitDamage = self:GetSpecialValueFor("on_hit_damage"),
																 BurnDamage = self:GetSpecialValueFor("burn_damage"),
																 BurnDuration = self:GetSpecialValueFor("burn_duration"),
																 BurnAOE = self:GetSpecialValueFor("burn_aoe"),
																 ExplodeAOE = self:GetSpecialValueFor("explode_aoe"),
																 ExplodeDamage = self:GetSpecialValueFor("explode_damage")})

	self:CheckCombo()
end

function karna_agni:CheckCombo()
	local caster = self:GetCaster()

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then		
		if caster:FindAbilityByName("karna_vasavi_shakti"):IsCooldownReady() 
		and caster:FindAbilityByName("karna_combo_vasavi"):IsCooldownReady() 
		and caster:HasModifier("modifier_armor_returned")		
		then
			caster:AddNewModifier(caster, self, "modifier_karna_combo_window", { Duration = 5 })
		end
	end
end