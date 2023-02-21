iskandar_charisma = class({})
modifier_iskandar_charisma = class({})
modifier_iskandar_charisma_aura = class({})

LinkLuaModifier("modifier_iskandar_charisma", "abilities/iskandar/iskandar_charisma", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_iskandar_charisma_aura", "abilities/iskandar/iskandar_charisma", LUA_MODIFIER_MOTION_NONE)

-- Passive
function iskandar_charisma:GetIntrinsicModifierName()
	return "modifier_iskandar_charisma_aura"
end

-- Vision provider buff
function modifier_iskandar_charisma:DeclareFunctions()
	return { MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
			 MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_iskandar_charisma:GetModifierMoveSpeedBonus_Percentage()	
	if self:GetParent() ~= self:GetCaster() then 
		return self:GetAbility():GetSpecialValueFor("bonus_ms")
	else
		return 0
	end
end

function modifier_iskandar_charisma:GetModifierDamageOutgoing_Percentage()
	if self:GetParent() ~= self:GetCaster() then 
		return self:GetAbility():GetSpecialValueFor("bonus_damage")
	else
		return 0
	end
end

function modifier_iskandar_charisma:IsHidden()
	if self:GetParent() ~= self:GetCaster() then
		return false
	else
		return true
	end
end

function modifier_iskandar_charisma:IsDebuff()
    return false
end

function modifier_iskandar_charisma:RemoveOnDeath()
    return true
end

function modifier_iskandar_charisma:GetTexture()
	return "custom/iskander_charisma"
end

-- Aura
function modifier_iskandar_charisma_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_iskandar_charisma_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP
end

function modifier_iskandar_charisma_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_iskandar_charisma_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_iskandar_charisma_aura:GetModifierAura()
	return "modifier_iskandar_charisma"
end

function modifier_iskandar_charisma_aura:IsHidden()
	return true 
end

function modifier_iskandar_charisma_aura:IsPermanent()
	return false
end

function modifier_iskandar_charisma_aura:IsDebuff()
	return false 
end

function modifier_iskandar_charisma_aura:IsAura()
	return true 
end