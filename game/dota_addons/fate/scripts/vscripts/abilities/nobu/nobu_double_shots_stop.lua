nobu_double_shots_stop = class({})
 
function nobu_double_shots_stop:OnSpellStart()
    local hCaster = self:GetCaster()
    Timers:RemoveTimer("nobu_shoots")
    EndAnimation(hCaster)
    hCaster:SetBodygroup(0,0)
    hCaster:RemoveModifierByName("modifier_nobu_turnlock")
    if  hCaster:GetAbilityByIndex(2):GetName() ~= "nobu_double_shots" then
        hCaster:SwapAbilities("nobu_double_shots", "nobu_double_shots_stop", true, false)    
    end

end