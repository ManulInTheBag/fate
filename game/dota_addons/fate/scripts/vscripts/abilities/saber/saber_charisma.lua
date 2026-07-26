-- saber_charisma — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/saber/saber_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

saber_charisma = class({})

LinkLuaModifier("modifier_charisma_aura", "abilities/saber/saber_charisma", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_charisma_aura_buff", "abilities/saber/saber_charisma", LUA_MODIFIER_MOTION_NONE)

function saber_charisma:GetIntrinsicModifierName()
	return "modifier_charisma_aura"
end

modifier_charisma_aura = class({})

function modifier_charisma_aura:IsHidden() return true end

function modifier_charisma_aura:IsAura() return true end
function modifier_charisma_aura:GetModifierAura() return "modifier_charisma_aura_buff" end
function modifier_charisma_aura:GetAuraRadius() return 1000 end
function modifier_charisma_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_charisma_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP end

modifier_charisma_aura_buff = class({})


function modifier_charisma_aura_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_charisma_aura_buff:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("speed_modifier")
end
function modifier_charisma_aura_buff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("speed_modifier")
end

function modifier_charisma_aura_buff:OnCreated(kv)
	if not IsServer() then return end
	local fx = ParticleManager:CreateParticle("particles/items2_fx/rod_of_atos_debuff_glow.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	self:AddParticle(fx, false, false, -1, false, false)
	local fx = ParticleManager:CreateParticle("particles/items2_fx/rod_of_atos_debuff_ground.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	self:AddParticle(fx, false, false, -1, false, false)
end

function modifier_charisma_aura_buff:OnRefresh(kv)
	self:OnCreated(kv)
end
