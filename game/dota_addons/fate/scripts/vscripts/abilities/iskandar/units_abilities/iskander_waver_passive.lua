iskander_waver_passive = class({})
modifier_iskander_waver_passive = class({})
modifier_iskander_waver_passive_aura = class({})

LinkLuaModifier("modifier_iskander_waver_passive", "abilities/iskandar/units_abilities/iskander_waver_passive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_iskander_waver_passive_aura", "abilities/iskandar/units_abilities/iskander_waver_passive", LUA_MODIFIER_MOTION_NONE)

-- Passive
function iskander_waver_passive:GetIntrinsicModifierName()
	return "modifier_iskander_waver_passive_aura"
end

-- Vision provider buff
function modifier_iskander_waver_passive:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS  }
end

function modifier_iskander_waver_passive:GetModifierMagicalResistanceBonus()	
	return self:GetAbility():GetSpecialValueFor("bonus_mr")
end


function modifier_iskander_waver_passive:IsHidden()
	return false
end

function modifier_iskander_waver_passive:IsDebuff()
    return false
end

function modifier_iskander_waver_passive:RemoveOnDeath()
    return true
end

function modifier_iskander_waver_passive:GetTexture()
	return "custom/iskander_phalanx"
end

-- Aura
function modifier_iskander_waver_passive_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_iskander_waver_passive_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_iskander_waver_passive_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_iskander_waver_passive_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_iskander_waver_passive_aura:GetModifierAura()
	return "modifier_iskander_waver_passive"
end

function modifier_iskander_waver_passive_aura:IsHidden()
	return true 
end

function modifier_iskander_waver_passive_aura:IsPermanent()
	return false
end

function modifier_iskander_waver_passive_aura:IsDebuff()
	return false 
end

function modifier_iskander_waver_passive_aura:IsAura()
	return true 
end