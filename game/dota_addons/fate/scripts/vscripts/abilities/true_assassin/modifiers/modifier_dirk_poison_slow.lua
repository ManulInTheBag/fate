modifier_dirk_poison_slow = class({})

LinkLuaModifier("modifier_weakening_venom", "abilities/true_assassin/modifiers/modifier_weakening_venom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dirk_poison_slow", "abilities/true_assassin/modifiers/modifier_dirk_poison_slow", LUA_MODIFIER_MOTION_NONE)

function modifier_dirk_poison_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_dirk_poison_slow:GetModifierMoveSpeedBonus_Percentage()
	local ability = self:GetAbility()
	if not ability then return 0 end

	return -1 * ability:GetSpecialValueFor("poison_slow") * self:GetStackCount()
end

function modifier_dirk_poison_slow:GetAttributes()
  return MODIFIER_ATTRIBUTE_NONE
end

function modifier_dirk_poison_slow:IsDebuff()
	return true 
end

function modifier_dirk_poison_slow:RemoveOnDeath()
	return true 
end

function modifier_dirk_poison_slow:GetEffectName()
	return "particles/units/heroes/hero_dazzle/dazzle_poison_debuff.vpcf"
end

function modifier_dirk_poison_slow:GetTexture()
    return "custom/true_assassin_dirk"
end

function modifier_dirk_poison_slow:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end