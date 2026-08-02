nobu_double_shots_stop = class({})
 
function nobu_double_shots_stop:OnSpellStart()
    local hCaster = self:GetCaster()
    local double_shots = hCaster:FindAbilityByName("nobu_double_shots")
    if double_shots then
        double_shots:StopShooting()
    end
end