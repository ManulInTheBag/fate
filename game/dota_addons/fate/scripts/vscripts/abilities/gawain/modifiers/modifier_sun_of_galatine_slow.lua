modifier_sun_of_galatine_slow = class({})

function modifier_sun_of_galatine_slow:OnCreated(args)
    self.SlowPerc = args.SlowPerc
end

function modifier_sun_of_galatine_slow:OnRefresh(args)
    self:OnCreated(args)
end

function modifier_sun_of_galatine_slow:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
 
    return funcs
end

function modifier_sun_of_galatine_slow:GetModifierMoveSpeedBonus_Percentage() 
    if IsServer() then
        CustomNetTables:SetTableValue("sync","sun_of_Galatine", { slow = self.SlowPerc })
        return self.SlowPerc
    elseif IsClient() then
        local slow = CustomNetTables:GetTableValue("sync","sun_of_Galatine").slow
        return slow 
    end
end

function modifier_sun_of_galatine_slow:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_sun_of_galatine_slow:IsPurgable()
    return false
end

function modifier_sun_of_galatine_slow:IsDebuff()
    return true
end

function modifier_sun_of_galatine_slow:RemoveOnDeath()
    return true
end

function modifier_sun_of_galatine_slow:GetTexture()
    return "custom/gawain_suns_embrace"
end
-----------------------------------------------------------------------------------
