modifier_attributes_gps = class({})

function modifier_attributes_gps:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end


function modifier_attributes_gps:UpdateValues()
  if IsServer() then
    local parent = self:GetParent()
    self:SetStackCount(parent.GpsGained * parent.additional_gps_adjustment)
    self:StartIntervalThink(1)
  end
end

function modifier_attributes_gps:OnIntervalThink()
  self:GetParent():ModifyGold(self:GetStackCount(), false, 0)

end


function modifier_attributes_gps:IsHidden()
  return true
end

function modifier_attributes_gps:IsDebuff()
  return false
end

function modifier_attributes_gps:RemoveOnDeath()
  return false
end
