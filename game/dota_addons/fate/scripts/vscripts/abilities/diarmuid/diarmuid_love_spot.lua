diarmuid_love_spot = class({})

LinkLuaModifier("modifier_love_spot", "abilities/diarmuid/modifiers/modifier_love_spot", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rampant_warrior_window", "abilities/diarmuid/modifiers/modifier_rampant_warrior_window", LUA_MODIFIER_MOTION_NONE)

function diarmuid_love_spot:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_love_spot", { Duration = self:GetSpecialValueFor("duration"),
																Radius = self:GetSpecialValueFor("radius") })

	self:CheckCombo()
end

function diarmuid_love_spot:CheckCombo()
	local caster = self:GetCaster()

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if caster:FindAbilityByName("diarmuid_double_spearmanship"):IsCooldownReady() and not caster:HasModifier("modifier_rampant_warrior_cooldown") then
			caster:AddNewModifier(caster, self, "modifier_rampant_warrior_window", { Duration = 3 })
		end
	end
end