cu_chulain_rune_of_ferocity = class({})

LinkLuaModifier("modifier_rune_of_ferocity", "abilities/cu_chulain/modifiers/modifier_rune_of_ferocity", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rune_of_ferocity_progress", "abilities/cu_chulain/modifiers/modifier_rune_of_ferocity", LUA_MODIFIER_MOTION_NONE)

function cu_chulain_rune_of_ferocity:OnUpgrade()
	if not self:GetCaster():HasModifier("modifier_rune_of_ferocity_progress") then 
		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_rune_of_ferocity_progress", {})
	end
end

function cu_chulain_rune_of_ferocity:GetIntrinsicModifierName()
	return "modifier_rune_of_ferocity"
end