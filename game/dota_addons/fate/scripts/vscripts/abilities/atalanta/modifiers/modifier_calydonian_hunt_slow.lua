modifier_calydonian_hunt_slow = class({})

function modifier_calydonian_hunt_slow:GetModifierMoveSpeedBonus_Percentage()
    if IsServer() then
        local ability = self:GetAbility()

        CustomNetTables:SetTableValue("sync","calydonian_slow", {slow = ability:GetSpecialValueFor("slow_amount")})
        return ability:GetSpecialValueFor("slow_amount")
    elseif IsClient() then
        local calydonian_slow = CustomNetTables:GetTableValue("sync","calydonian_slow").slow
        return calydonian_slow 
    end
end

function modifier_calydonian_hunt_slow:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
 
    return funcs
end

--[[function modifier_calydonian_hunt_slow:GetModifierProvidesFOWVision()
    return 1
end]]

function modifier_calydonian_hunt_slow:IsDebuff()
    return true
end

function modifier_calydonian_hunt_slow:RemoveOnDeath()
    return true
end

function modifier_calydonian_hunt_slow:GetTexture()
    return "custom/atalanta_calydonian_hunt"
end