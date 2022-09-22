modifier_vajra_slow = class({})

function modifier_vajra_slow:OnCreated(table)
    self.slowPerc = table.slowPerc
    self.slowDur = self:GetDuration()

    self:StartIntervalThink(0.1)
end

function modifier_vajra_slow:OnRefresh()
    self:OnCreated()
end

function modifier_vajra_slow:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
 
    return funcs
end

function modifier_vajra_slow:GetModifierMoveSpeedBonus_Percentage()
    return self.slowPerc
end

function modifier_vajra_slow:OnIntervalThink()
    if self:GetDuration() > 0 then        
        self.slowPerc = self.slowPerc + ((self.slowPerc * -1) / self.slowDur * 0.1)
    else  
        self:StartIntervalThink(-1)
        self:Destroy()
    end
end

-----------------------------------------------------------------------------------
function modifier_vajra_slow:GetEffectName()
    return "particles/items_fx/diffusal_slow.vpcf"
end

function modifier_vajra_slow:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_vajra_slow:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_vajra_slow:IsPurgable()
    return false
end

function modifier_vajra_slow:IsDebuff()
    return true
end

function modifier_vajra_slow:RemoveOnDeath()
    return true
end

function modifier_vajra_slow:GetTexture()
    return "custom/s_scroll"
end
-----------------------------------------------------------------------------------
