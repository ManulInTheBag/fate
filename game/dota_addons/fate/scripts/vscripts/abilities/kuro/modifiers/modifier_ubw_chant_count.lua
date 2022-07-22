modifier_ubw_chant_count = class({})

function modifier_ubw_chant_count:OnCreated(args)
    if IsServer() then
        --self.MsBonus = args.MsBonus
        self:SetStackCount(math.min(args.Charges or 1, 6))
        self.MsBonus = args.MsBonus * self:GetStackCount()
        CustomNetTables:SetTableValue("sync","ubw_chant_buff", { ms_bonus = self.MsBonus})
    end
end

function modifier_ubw_chant_count:OnRefresh(args)
    if IsServer() then
        args.Charges = self:GetStackCount() + 1
        self:OnCreated(args)
    end
end

function modifier_ubw_chant_count:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    }
 
    return funcs
end

function modifier_ubw_chant_count:GetModifierMoveSpeedBonus_Constant()
    if IsServer() then
        CustomNetTables:SetTableValue("sync","ubw_chant_buff", { ms_bonus = self.MsBonus})
        return self.MsBonus 
    elseif IsClient() then
        local ms_bonus = CustomNetTables:GetTableValue("sync","ubw_chant_buff").ms_bonus
        return ms_bonus 
    end
end

function modifier_ubw_chant_count:OnDestroy()
    if IsServer() then
        local hero = self:GetCaster()

        if hero ~= nil then
            if hero:GetName() ~= "npc_dota_hero_ember_spirit" then return end
            local ability = hero:GetAbilityByIndex(5)
            if ability:GetName() == "archer_5th_ubw" then
                hero:SwapAbilities("archer_5th_ubw", "emiya_chant_ubw", false, true)
            end
        end
    end
end

-----------------------------------------------------------------------------------

function modifier_ubw_chant_count:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_ubw_chant_count:IsPurgable()
    return false
end

function modifier_ubw_chant_count:IsDebuff()
    return false
end

function modifier_ubw_chant_count:RemoveOnDeath()
    return true
end

function modifier_ubw_chant_count:GetTexture()
    return "custom/archer_5th_ubw"
end

-----------------------------------------------------------------------------------
