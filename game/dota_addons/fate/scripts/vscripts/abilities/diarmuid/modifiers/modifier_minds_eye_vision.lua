modifier_minds_eye_vision = class({})

local tCannotDetect = {
    "npc_dota_hero_juggernaut",
    "npc_dota_hero_bounty_hunter",
    "npc_dota_hero_bloodseeker",
    "npc_dota_hero_riki"
}

function modifier_minds_eye_vision:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    }
 
    return funcs
end

function modifier_minds_eye_vision:GetModifierProvidesFOWVision()
	return self:CanBeDetected(self:GetParent())
end

function modifier_minds_eye_vision:IsHidden()
	return false
end

function modifier_minds_eye_vision:IsDebuff()
    return true
end

function modifier_minds_eye_vision:RemoveOnDeath()
    return true
end

function modifier_minds_eye_vision:CanBeDetected(hHero)
    for i=1, #tCannotDetect do
        if hHero:GetName() == tCannotDetect[i] or hHero:HasModifier("modifier_murderer_mist_in") then
            return 0
        end
    end
    
    return 1
end