cu_chulain_rune_of_flame = class({})

LinkLuaModifier("modifier_rune_of_flame", "abilities/cu_chulain/modifiers/modifier_rune_of_flame", LUA_MODIFIER_MOTION_NONE)

function cu_chulain_rune_of_flame:GetManaCost(iLevel)
	if self:GetCaster():HasModifier("modifier_celtic_rune_attribute") then
		return 0
	else
		return 100
	end
end

function cu_chulain_rune_of_flame:GetCooldown(iLevel)
	local cooldown = self:GetSpecialValueFor("cooldown")

	if self:GetCaster():HasModifier("modifier_celtic_rune_attribute") then
		cooldown = cooldown - (cooldown * 0.75)
	end

	return cooldown
end

function cu_chulain_rune_of_flame:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local stunDuration = self:GetSpecialValueFor("stun_duration")
	local trapDuration = 0

	local lancertrap = CreateUnitByName("lancer_trap", targetPoint, true, caster, caster, caster:GetTeamNumber())
	Timers:CreateTimer(1.0, function()
		LevelAllAbility(lancertrap)
		lancertrap:AddNewModifier(caster, self, "modifier_rune_of_flame", { Duration = self:GetSpecialValueFor("duration"),
																			Radius = self:GetSpecialValueFor("radius"),
																			Damage = self:GetSpecialValueFor("damage"),
																			StunDuration = self:GetSpecialValueFor("stun_duration") })
		return
	end)

	if not caster:HasModifier("modifier_celtic_rune_attribute") then
		local ability = caster:FindAbilityByName("cu_chulain_rune_magic")
		ability:CloseSpellbook(self:GetCooldown(self:GetLevel()))		
	end
end
