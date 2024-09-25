modifier_minds_eye_aura = class({})

LinkLuaModifier("modifier_minds_eye_vision", "abilities/diarmuid/modifiers/modifier_minds_eye_vision", LUA_MODIFIER_MOTION_NONE)

function modifier_minds_eye_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_minds_eye_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_minds_eye_aura:GetAuraRadius()
	return 1500
end

function modifier_minds_eye_aura:GetModifierAura()
	return "modifier_minds_eye_vision"
end

function modifier_minds_eye_aura:IsHidden()
	return false 
end

function modifier_minds_eye_aura:RemoveOnDeath()
	return false
end

function modifier_minds_eye_aura:IsDebuff()
	return false 
end

function modifier_minds_eye_aura:IsAura()
	return true 
end