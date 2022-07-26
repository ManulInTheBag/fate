LinkLuaModifier("modifier_khsn_presence_aura", "abilities/kinghassan/khsn_presence", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_presence", "abilities/kinghassan/khsn_presence", LUA_MODIFIER_MOTION_NONE)

khsn_presence = class({})

--function khsn_presence:GeIntrinsicModifierName() return "modifier_khsn_presence_aura" end

modifier_khsn_presence_aura = class({})

function modifier_khsn_presence_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_khsn_presence_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_khsn_presence_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_khsn_presence_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_khsn_presence_aura:GetModifierAura()
	return "modifier_khsn_presence"
end

function modifier_khsn_presence_aura:IsHidden()
	return true 
end

function modifier_khsn_presence_aura:RemoveOnDeath()
	return false
end

function modifier_khsn_presence_aura:IsDebuff()
	return false 
end

function modifier_khsn_presence_aura:IsAura()
	return true 
end

function modifier_khsn_presence_aura:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

modifier_khsn_presence = class({})

function modifier_khsn_presence:IsHidden() return false end
function modifier_khsn_presence:IsDebuff() return true end
function modifier_khsn_presence:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE}
end
function modifier_khsn_presence:GetModifierTotalDamageOutgoing_Percentage()
	print(-self:GetAbility():GetSpecialValueFor("damage_reduction"))
	return -self:GetAbility():GetSpecialValueFor("damage_reduction")
end
function modifier_khsn_presence:GetTexture()
    return "custom/kinghassan/khsn_presence"
end