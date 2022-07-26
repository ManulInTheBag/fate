cu_chulain_rune_of_protection = class({})

LinkLuaModifier("modifier_rune_of_protection", "abilities/cu_chulain/modifiers/modifier_rune_of_protection", LUA_MODIFIER_MOTION_NONE)

function cu_chulain_rune_of_protection:GetManaCost(iLevel)
	if self:GetCaster():HasModifier("modifier_celtic_rune_attribute") then
		return 0
	else
		return 100
	end
end

function cu_chulain_rune_of_protection:GetCooldown(iLevel)
	local cooldown = self:GetSpecialValueFor("cooldown")

	if self:GetCaster():HasModifier("modifier_celtic_rune_attribute") then
		cooldown = cooldown - (cooldown * 0.75)
	end

	return cooldown
end

function cu_chulain_rune_of_protection:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_rune_of_protection", { Duration = self:GetSpecialValueFor("duration") })

	if not caster:HasModifier("modifier_celtic_rune_attribute") then
		local ability = caster:FindAbilityByName("cu_chulain_rune_magic")
		ability:CloseSpellbook(self:GetCooldown(self:GetLevel()))		
	end
end