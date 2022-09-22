modifier_heart_of_harmony_linger = class({})

function modifier_heart_of_harmony_linger:OnCreated(table)
    self.DamageReduc = table.DamageReduc

    if IsServer() then
        CustomNetTables:SetTableValue("sync","heart_of_harmony", { damage_reduc = self.DamageReduc })
    end
end

function modifier_heart_of_harmony_linger:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }
 
    return funcs
end

function modifier_heart_of_harmony_linger:GetModifierIncomingDamage_Percentage() 
    if IsServer() then       
        return self.DamageReduc
    elseif IsClient() then
        local damage_reduc = CustomNetTables:GetTableValue("sync","heart_of_harmony").damage_reduc
        return damage_reduc 
    end
end

-----------------------------------------------------------------------------------

function modifier_heart_of_harmony_linger:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_heart_of_harmony_linger:IsHidden()
    return true
end

function modifier_heart_of_harmony_linger:IsPurgable()
    return false
end

function modifier_heart_of_harmony_linger:IsDebuff()
    return false
end

function modifier_heart_of_harmony_linger:RemoveOnDeath()
    return true
end

function modifier_heart_of_harmony_linger:GetTexture()
    return "custom/false_assassin_heart_of_harmony"
end
-----------------------------------------------------------------------------------
