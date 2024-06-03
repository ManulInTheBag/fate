modifier_replenishment_armor = class({})


function modifier_replenishment_armor:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS
	}
	return funcs
end

function modifier_replenishment_armor:GetModifierPhysicalArmorBonus()
	return 50--self:GetAbility():GetSpecialValueFor("armorbonus")
end

function modifier_replenishment_armor:GetModifierHealthBonus()
	return 1000--self:GetAbility():GetSpecialValueFor("hpbonus")
end

function modifier_replenishment_armor:GetModifierManaBonus()
	return 500--self:GetAbility():GetSpecialValueFor("manabonus")
end

function modifier_replenishment_armor:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_replenishment_armor:GetEffectName()
	return "particles/neutral_fx/ogre_magi_frost_armor.vpcf"
end
function modifier_replenishment_armor:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_replenishment_armor:GetTexture()
	return "custom/shard_of_replenishment"
end
