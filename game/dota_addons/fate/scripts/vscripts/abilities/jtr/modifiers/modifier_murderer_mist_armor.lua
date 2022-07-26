modifier_murderer_mist_armor = class({})

function modifier_murderer_mist_armor:DeclareFunctions()
	local func = { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
	return func
end

function modifier_murderer_mist_armor:OnCreated()
	self:StartIntervalThink(1)
end

function modifier_murderer_mist_armor:OnIntervalThink()
	--print(self:GetParent():GetModifierStackCount("modifier_murderer_mist_armor"), self:GetAbility())
end

function modifier_murderer_mist_armor:OnRefresh()
	self:OnCreated()
end

function modifier_murderer_mist_armor:GetAttributes()
  return MODIFIER_ATTRIBUTE_NONE
end

function modifier_murderer_mist_armor:IsDebuff()
	return true 
end

function modifier_murderer_mist_armor:RemoveOnDeath()
	return true 
end

function modifier_murderer_mist_armor:IsHidden() return false end

function modifier_murderer_mist_armor:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("armor_reduction")*-1
end