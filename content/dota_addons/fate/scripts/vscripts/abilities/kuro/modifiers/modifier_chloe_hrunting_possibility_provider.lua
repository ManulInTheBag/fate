LinkLuaModifier("modifier_chloe_hrunting_possible_target", "abilities/kuro/modifiers/modifier_chloe_hrunting_possible_target", LUA_MODIFIER_MOTION_NONE)

modifier_chloe_hrunting_possibility_provider = class({})

function modifier_chloe_hrunting_possibility_provider:IsAura() return true end

function modifier_chloe_hrunting_possibility_provider:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_chloe_hrunting_possibility_provider:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_chloe_hrunting_possibility_provider:OnCreated(args)
	self.aura_radius = args.radius
end

function modifier_chloe_hrunting_possibility_provider:GetAuraRadius()
	return self.aura_radius
end

function modifier_chloe_hrunting_possibility_provider:GetModifierAura()
	return "modifier_chloe_hrunting_possible_target"
end