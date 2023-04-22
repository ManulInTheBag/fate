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

function modifier_attributes_mr:GetModifierMagicalResistanceDirectModification()
--strength * Attributes.hp_adjustment
  --[[if IsServer() then
    local parent = self:GetParent()
    self:SetStackCount(math.abs(math.floor(parent:GetStrength() + 0.5) * parent.hp_adjustment))
  end
  return self:GetStackCount()]]

local parent = self:GetParent()
    --end    
 return (-0.1 * parent:GetIntellect()) + 0.1
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
