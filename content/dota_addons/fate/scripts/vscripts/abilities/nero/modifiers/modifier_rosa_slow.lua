modifier_rosa_slow = class({})

function modifier_rosa_slow:OnCreated()    
    if IsServer() then
        self.slowPerc = -30.0
        CustomNetTables:SetTableValue("sync","rosa_slow", {slow_perc = self.slowPerc})
    end
end

--[[function modifier_rosa_slow:OnRefresh()
    self:OnCreated()
end]]

function modifier_rosa_slow:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
 
    return funcs
end

function modifier_rosa_slow:GetModifierMoveSpeedBonus_Percentage()
    if IsServer() then        
        return self.slowPerc
    elseif IsClient() then
        local slow_perc = CustomNetTables:GetTableValue("sync","rosa_slow").slow_perc
        return slow_perc 
    end
end

-----------------------------------------------------------------------------------
--[[function modifier_rosa_slow:GetEffectName()
    return "particles/items_fx/diffusal_slow.vpcf"
end

function modifier_rosa_slow:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end]]

function modifier_rosa_slow:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_rosa_slow:IsPurgable()
    return false
end

function modifier_rosa_slow:IsDebuff()
    return true
end


function modifier_rosa_slow:RemoveOnDeath()
    return true
end

function modifier_rosa_slow:GetTexture()
    return "custom/nero_rosa_ichthys"
end
-----------------------------------------------------------------------------------
