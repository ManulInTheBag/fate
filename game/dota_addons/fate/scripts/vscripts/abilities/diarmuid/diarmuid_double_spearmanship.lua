diarmuid_double_spearmanship = class({})

LinkLuaModifier("modifier_double_spearmanship_passive", "abilities/diarmuid/modifiers/modifier_double_spearmanship_passive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_double_spearmanship_active", "abilities/diarmuid/modifiers/modifier_double_spearmanship_active", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rampant_warrior", "abilities/diarmuid/modifiers/modifier_rampant_warrior", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rampant_warrior_cooldown", "abilities/diarmuid/modifiers/modifier_rampant_warrior_cooldown", LUA_MODIFIER_MOTION_NONE)

function diarmuid_double_spearmanship:CastFilterResult()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_rampant_warrior") then
		return UF_FAIL_CUSTOM
	end

	return UF_SUCCESS
end

function diarmuid_double_spearmanship:GetCustomCastError()
	return "#Rampant_Warrior_Active"
end

function diarmuid_double_spearmanship:OnSpellStart()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_rampant_warrior_window") then
		caster:AddNewModifier(caster, self, "modifier_rampant_warrior", { Duration = self:GetSpecialValueFor("combo_duration"),
																		  AttackSpeed = self:GetSpecialValueFor("combo_aspd"),
																		  HitDamage = self:GetSpecialValueFor("combo_damage") })

		caster:RemoveModifierByName("modifier_rampant_warrior_window")
		caster:AddNewModifier(caster, self, "modifier_rampant_warrior_cooldown", { Duration = self:GetSpecialValueFor("combo_cooldown") })

		local masterCombo = caster.MasterUnit2:FindAbilityByName("diarmuid_rampant_warrior_proxy")
		masterCombo:EndCooldown()
		masterCombo:StartCooldown(masterCombo:GetCooldown(1))

		caster:EmitSound("Diarmuid_Combo_" .. math.random(1,2))
		
	else
		local attack_speed = 0
		if caster:HasModifier("modifier_doublespear_attribute") then
			attack_speed = self:GetSpecialValueFor("attribute_attack_speed")
		end
		caster:AddNewModifier(caster, self, "modifier_double_spearmanship_active", { Duration = self:GetSpecialValueFor("duration"),
																					 AttackSpeed = attack_speed,
																					 OnHit = self:GetSpecialValueFor("on_hit") })
		caster:EmitSound("Diarmuid_Skill_1")
	end	
end

function diarmuid_double_spearmanship:OnUpgrade()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_double_spearmanship_passive", { DoubleAttackChance = self:GetSpecialValueFor("proc_chance") })
end

function diarmuid_double_spearmanship:GetAbilityTextureName()
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_rampant_warrior_window") then 
		return "custom/diarmuid_rampant_warrior"
	else
		return "custom/diarmuid_double_spearsmanship"
	end
end