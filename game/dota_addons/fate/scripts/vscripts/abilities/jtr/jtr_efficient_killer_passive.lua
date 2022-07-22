jtr_efficient_killer_passive = class({})

LinkLuaModifier("modifier_efficient_killer", "abilities/jtr/jtr_efficient_killer_passive", LUA_MODIFIER_MOTION_NONE)

modifier_efficient_killer = class({})

--function modifier_efficient_killer:DeclareFunctions()
--	return { MODIFIER_PROPERTY_STATS_AGILITY_BONUS }
--end

--function modifier_efficient_killer:GetModifierBonusStats_Agility()
--	return self:GetAbility():GetSpecialValueFor("bonus_agi")
--end

function modifier_efficient_killer:IsHidden()
	return true
end

function modifier_efficient_killer:IsPermanent()
	return true
end

function modifier_efficient_killer:RemoveOnDeath()
	return false
end

function modifier_efficient_killer:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function jtr_efficient_killer_passive:GetIntrinsicModifierName()
	return "modifier_efficient_killer"
end