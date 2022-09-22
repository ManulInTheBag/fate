semiramis_sikera_usum = class({})
semiramis_sikera_usum_close = class({})

local tSpellBook = {
    "lancelot_vortigern",
    "lancelot_gae_bolg",
    "lancelot_nine_lives",
    "lancelot_rule_breaker",
    "lancelot_knight_of_honor_close",
    "lancelot_tsubame_gaeshi",
    "attribute_bonus_custom"
}

function semiramis_sikera_usum:OnUpgrade()
    local hCaster = self:GetCaster()
    local hAbility = self
    local abilityLevel = self:GetLevel()

    hCaster:FindAbilityByName("semiramis_poisonous_bite"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("semiramis_poisonous_air"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("semiramis_summon_basmu"):SetLevel(self:GetLevel())
end

function semiramis_sikera_usum:OnSpellStart()
    local hCaster = self:GetCaster()
    local abilityLevel = self:GetLevel()

    UpdateAbilityLayout(hCaster, tSpellBook)
end

function semiramis_sikera_usum_close:OnSpellStart()
    local hCaster = self:GetCaster()

    local tAbilities = {
        "lancelot_smg_barrage",
        "lancelot_double_edge",
        "lancelot_knight_of_honor",
        "fate_empty1",
        "lancelot_arms_mastership",
        "lancelot_arondite",
        "attribute_bonus_custom",
    }

    if hCaster.nukeAvail then
        tAbilities[4] = "lancelot_nuke"
    elseif hCaster:HasAbility("lancelot_blessing_of_fairy") then
        tAbilities[4] = "lancelot_blessing_of_fairy"
    end

    UpdateAbilityLayout(hCaster, tAbilities)
end