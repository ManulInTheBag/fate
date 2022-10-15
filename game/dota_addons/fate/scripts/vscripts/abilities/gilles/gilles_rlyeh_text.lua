gilles_rlyeh_text_open = class({})
gilles_rlyeh_text_close = class({})

local tStandardAbilities = {
    "gilles_summon_jellyfish",
    "gilles_rlyeh_text_open",
    "gilles_cthulhu_favour",
    "gilles_prelati_spellbook",
    "gilles_eye_for_art_passive",
    "gilles_abyssal_contract",
    "attribute_bonus_custom"
}

local tStandardAbilitiesCombo = {
    "gilles_summon_jellyfish",
    "gilles_rlyeh_text_open",
    "gilles_cthulhu_favour",
    "gilles_prelati_spellbook",
    "gilles_eye_for_art_passive",
    "gille_larret_de_mort",
    "attribute_bonus_custom"
}

local tRlyehSkills = {
    "gilles_torment",
    "gilles_smother",
    "gilles_hysteria",
    "gilles_grief",
    "gilles_rlyeh_text_close",
    "gilles_misery",
    "attribute_bonus_custom"
}

function gilles_rlyeh_text_open:OnUpgrade()
    local hCaster = self:GetCaster()
    
    hCaster:FindAbilityByName("gilles_torment"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("gilles_smother"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("gilles_hysteria"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("gilles_grief"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("gilles_misery"):SetLevel(self:GetLevel())
end

function gilles_rlyeh_text_open:OnSpellStart()
    local hCaster = self:GetCaster()
    UpdateAbilityLayout(hCaster, tRlyehSkills)
end

function gilles_rlyeh_text_close:OnSpellStart()
    local hCaster = self:GetCaster()
    if(hCaster:HasModifier("modifier_gilles_combo_window")) then
        UpdateAbilityLayout(hCaster, tStandardAbilitiesCombo)
    else
        UpdateAbilityLayout(hCaster, tStandardAbilities)
    end
end