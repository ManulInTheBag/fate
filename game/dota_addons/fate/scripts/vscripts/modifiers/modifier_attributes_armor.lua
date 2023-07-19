modifier_attributes_armor = class({})


function modifier_attributes_armor:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_attributes_armor:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS_UNIQUE,
  }
  return funcs
end


function modifier_attributes_armor:GetModifierPhysicalArmorBonusUnique(keys)
  return self:GetStackCount()*0.55
end


function modifier_attributes_armor:IsHidden()
  return true
end

function modifier_attributes_armor:IsDebuff()
  return false
end

function modifier_attributes_armor:RemoveOnDeath()
  return false
end