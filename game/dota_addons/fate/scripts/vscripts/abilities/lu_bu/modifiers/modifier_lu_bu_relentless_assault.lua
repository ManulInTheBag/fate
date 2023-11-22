modifier_lu_bu_relentless_assault = class({})

function modifier_lu_bu_relentless_assault:DeclareFunctions()
    return { MODIFIER_EVENT_ON_RESPAWN }
end

function modifier_lu_bu_relentless_assault:OnRespawn()
    self:SetStackCount(1)
end

function modifier_lu_bu_relentless_assault:IsDebuff()
    return false
end

function modifier_lu_bu_relentless_assault:RemoveOnDeath()
    return false
end

function modifier_lu_bu_relentless_assault:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_lu_bu_relentless_assault:IsHidden()
    return false
end

function modifier_lu_bu_relentless_assault:GetTexture()
    return "custom/lu_bu/lu_bu_insurmountable_assault_attribute"
end