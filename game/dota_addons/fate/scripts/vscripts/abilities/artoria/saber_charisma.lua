-- Saber: Charisma — friendly aura granting attack speed and move speed.
-- Lua port of the old datadriven saber_charisma (pilot of the DD->lua migration).
saber_charisma = class({})

LinkLuaModifier("modifier_charisma_aura", "abilities/artoria/saber_charisma", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_charisma_aura_buff", "abilities/artoria/saber_charisma", LUA_MODIFIER_MOTION_NONE)

function saber_charisma:GetIntrinsicModifierName()
	return "modifier_charisma_aura"
end

-- ---------------------------------------------------------------- aura source
modifier_charisma_aura = class({})

function modifier_charisma_aura:IsHidden() return true end
function modifier_charisma_aura:IsPurgable() return false end
function modifier_charisma_aura:IsAura() return true end

function modifier_charisma_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("Range")
end

function modifier_charisma_aura:GetAuraSearchTeam()  return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_charisma_aura:GetAuraSearchType()  return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP end
function modifier_charisma_aura:GetModifierAura()    return "modifier_charisma_aura_buff" end

-- ---------------------------------------------------------------- aura buff
modifier_charisma_aura_buff = class({})

function modifier_charisma_aura_buff:IsPurgable() return false end

function modifier_charisma_aura_buff:OnCreated()
	if not IsServer() then return end
	local hParent = self:GetParent()
	local glow = ParticleManager:CreateParticle("particles/items2_fx/rod_of_atos_debuff_glow.vpcf", PATTACH_ABSORIGIN_FOLLOW, hParent)
	self:AddParticle(glow, false, false, -1, false, false)
	local ground = ParticleManager:CreateParticle("particles/items2_fx/rod_of_atos_debuff_ground.vpcf", PATTACH_ABSORIGIN_FOLLOW, hParent)
	self:AddParticle(ground, false, false, -1, false, false)
end

function modifier_charisma_aura_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			 MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_charisma_aura_buff:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("speed_modifier")
end

function modifier_charisma_aura_buff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("speed_modifier")
end
