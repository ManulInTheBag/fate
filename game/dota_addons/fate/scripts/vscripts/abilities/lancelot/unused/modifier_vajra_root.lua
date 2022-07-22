modifier_vajra_root = class({})

function modifier_vajra_root:OnCreated(args)
    self.state = {
        [MODIFIER_STATE_ROOTED] = true,
    } 
end

function modifier_vajra_root:OnRefresh(args)
    self:OnCreated(args)
end

function modifier_vajra_root:CheckState()   
    return self.state
end

-----------------------------------------------------------------------------------
function modifier_vajra_root:GetEffectName()
    return "particles/items_fx/diffusal_slow.vpcf"
end

function modifier_vajra_root:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_vajra_root:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_vajra_root:IsPurgable()
    return false
end

function modifier_vajra_root:IsDebuff()
    return true
end

function modifier_vajra_root:RemoveOnDeath()
    return true
end

function modifier_vajra_root:GetTexture()
    return "custom/s_scroll"
end
-----------------------------------------------------------------------------------
