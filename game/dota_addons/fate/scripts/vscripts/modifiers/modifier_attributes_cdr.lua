modifier_attributes_cdr = class({})

function modifier_attributes_cdr:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_attributes_cdr:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
  }
  return funcs
end

function modifier_attributes_cdr:UpdateValues()
  if IsServer() then
    local parent = self:GetParent()
    self:SetStackCount(parent.INTgained * parent.additional_cdr_adjustment)
  end
end

function modifier_attributes_cdr:GetModifierPercentageCooldown(args)
--hero.BaseMS + agility * Attributes.ms_adjustment + hero.MSgained * Attributes.additional_movespeed_adjustment
  if IsServer() then
    local parent = self:GetParent()
    self:SetStackCount(parent.INTgained * parent.additional_cdr_adjustment)
  end
  if args.ability ~= nil then
    if args.ability.IsCombo or args.ability.IsResetable == false or args.ability:IsItem() then
      return 0
    end
  end
  return self:GetStackCount()
end


function modifier_attributes_cdr:IsHidden()
  return true
end

function modifier_attributes_cdr:IsDebuff()
  return false
end

function modifier_attributes_cdr:RemoveOnDeath()
  return false
end
