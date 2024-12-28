modifier_attributes_mr = class({})


function modifier_attributes_mr:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_attributes_mr:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DIRECT_MODIFICATION,
  }
  return funcs
end

function modifier_attributes_mr:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_attributes_mr:OnIntervalThink()
  if not IsServer() then return end
  local parent = self:GetParent()
  self:SetStackCount(parent.STRgained * parent.additional_mr_adjustment * 10)
end

function modifier_attributes_mr:GetModifierMagicalResistanceDirectModification()
--strength * Attributes.hp_adjustment
  local parent = self:GetParent()

    --end    
 return (-0.1 * parent:GetIntellect() + self:GetStackCount()/10) + 0.1
end


function modifier_attributes_mr:IsHidden()
  return true
end

function modifier_attributes_mr:IsDebuff()
  return false
end

function modifier_attributes_mr:RemoveOnDeath()
  return false
end
