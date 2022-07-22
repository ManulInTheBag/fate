modifier_calydonian_hunt_root_block = class({})

function modifier_calydonian_hunt_root_block:IsDebuff()
    return true
end

function modifier_calydonian_hunt_root_block:RemoveOnDeath()
    return true
end

function modifier_calydonian_hunt_root_block:GetTexture()
    return "custom/atalanta_calydonian_hunt_x"
end