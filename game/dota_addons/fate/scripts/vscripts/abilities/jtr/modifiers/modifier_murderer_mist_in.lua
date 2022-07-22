modifier_murderer_mist_in = class({})
LinkLuaModifier("modifier_murderer_mist_armor", "abilities/jtr/modifiers/modifier_murderer_mist_armor", LUA_MODIFIER_MOTION_NONE)
function modifier_murderer_mist_in:IsHidden() return true end
function modifier_murderer_mist_in:IsDebuff() return false end

function modifier_murderer_mist_in:OnCreated()
	--self:StartIntervalThink(0.5)
end

function modifier_murderer_mist_in:OnIntervalThink()
	--[[local stacks = 1
	if not self:GetParent():HasModifier("modifier_murderer_mist_armor") then
		--print("kappa1")
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_murderer_mist_armor", {Duration = 1})
		self:GetParent():SetModifierStackCount("modifier_murderer_mist_armor", ability, stacks)
	else
		--print("kappa1")
		stacks = self:GetParent():GetModifierStackCount("modifier_murderer_mist_armor", ability)
		self:GetParent():SetModifierStackCount("modifier_murderer_mist_armor", ability, stacks + 1)
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_murderer_mist_armor", {Duration = 1})
	end]]
end