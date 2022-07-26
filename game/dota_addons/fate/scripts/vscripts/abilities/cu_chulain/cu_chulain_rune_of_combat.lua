cu_chulain_rune_of_combat = class({})

LinkLuaModifier("modifier_rune_of_combat", "abilities/cu_chulain/modifiers/modifier_rune_of_combat", LUA_MODIFIER_MOTION_NONE)

function cu_chulain_rune_of_combat:GetManaCost(iLevel)
	if self:GetCaster():HasModifier("modifier_celtic_rune_attribute") then
		return 0
	else
		return 100
	end
end

function cu_chulain_rune_of_combat:GetCooldown(iLevel)
	local cooldown = self:GetSpecialValueFor("cooldown")

	if self:GetCaster():HasModifier("modifier_celtic_rune_attribute") then
		cooldown = cooldown - (cooldown * 0.75)
	end

	return cooldown
end

function cu_chulain_rune_of_combat:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_rune_of_combat", { Duration = self:GetSpecialValueFor("duration"),
																	 BonusAtkPct = self:GetSpecialValueFor("bonus_atk"),
																	 StunDuration = self:GetSpecialValueFor("stun_dur") })

	if not caster:HasModifier("modifier_celtic_rune_attribute") then
		local ability = caster:FindAbilityByName("cu_chulain_rune_magic")
		ability:CloseSpellbook(self:GetCooldown(self:GetLevel()))		
	end
end