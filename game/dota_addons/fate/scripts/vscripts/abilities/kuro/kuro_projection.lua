kuro_projection = class({})

LinkLuaModifier("modifier_projection_active", "abilities/kuro/modifiers/modifier_projection_active", LUA_MODIFIER_MOTION_NONE)
function kuro_projection:GetCooldown(iLevel)
	local cooldown = self:GetSpecialValueFor("cooldown")

	if self:GetCaster():HasModifier("modifier_kuro_projection") then
		cooldown = cooldown - (cooldown * 35 / 100)
	end

	return cooldown
end
function kuro_projection:OnSpellStart()
	local hCaster = self:GetCaster()
	local modifier = hCaster:FindModifierByName("modifier_projection_active")
	if not modifier then
		hCaster:AddNewModifier(hCaster, self, "modifier_projection_active", { Duration = self:GetSpecialValueFor("duration") })
		modifier = hCaster:FindModifierByName("modifier_projection_active")
		modifier:SetStackCount(1)
	else
		modifier:SetStackCount(modifier:GetStackCount()+1)
		hCaster:AddNewModifier(hCaster, self, "modifier_projection_active", { Duration = self:GetSpecialValueFor("duration") })
	end
end