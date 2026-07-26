-- caster_5th_dragon_chilling_breath — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_dragon_chilling_breath = class({})

LinkLuaModifier("modifier_chilling_breath", "abilities/medea/caster_5th_dragon_chilling_breath", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("chilling_breath_slow", "abilities/medea/caster_5th_dragon_chilling_breath", LUA_MODIFIER_MOTION_NONE)

function caster_5th_dragon_chilling_breath:GetIntrinsicModifierName()
	return "modifier_chilling_breath"
end

modifier_chilling_breath = class({})

function modifier_chilling_breath:IsHidden() return true end

function modifier_chilling_breath:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_chilling_breath:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	params.target:AddNewModifier(self:GetCaster(), self:GetAbility(), "chilling_breath_slow", {})
end

chilling_breath_slow = class({})

function chilling_breath_slow:IsDebuff() return true end
function chilling_breath_slow:GetStatusEffectName() return "particles/status_fx/status_effect_frost.vpcf" end
function chilling_breath_slow:StatusEffectPriority() return 10 end

function chilling_breath_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function chilling_breath_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow")
end
function chilling_breath_slow:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("slow")
end

function chilling_breath_slow:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function chilling_breath_slow:OnRefresh(kv)
	self:OnCreated(kv)
end
