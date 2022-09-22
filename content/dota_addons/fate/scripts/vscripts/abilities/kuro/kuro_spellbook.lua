kuro_spellbook_open = class({})
kuro_spellbook_close = class({})

local tStandardAbilities = {
    "kuro_kanshou_byakuya",
    "kuro_spellbook_open",
    "kuro_broken_phantasm",
    "kuro_clairvoyance",
    "fate_empty1",
    "kuro_projection",
    "attribute_bonus_custom"
}

local tProjections = {
    "kuro_rho_aias",
    "kuro_gae_bolg",
    "kuro_nine_lives",
    "kuro_excalibur_image",
    "kuro_spellbook_close",
    "kuro_rosa_ichthys",
    "attribute_bonus_custom"
}

function kuro_spellbook_open:OnUpgrade()
    local hCaster = self:GetCaster()
    
    hCaster:FindAbilityByName("kuro_rho_aias"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("kuro_gae_bolg"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("kuro_excalibur_image"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("kuro_nine_lives"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("kuro_rosa_ichthys"):SetLevel(self:GetLevel())
end

function kuro_spellbook_open:OnSpellStart()
    local hCaster = self:GetCaster()
    
    hCaster:RemoveModifierByName("modifier_kuro_crane_tracker")
    UpdateAbilityLayout(hCaster, tProjections)
end

function kuro_spellbook_close:OnSpellStart()
    local hCaster = self:GetCaster()
    UpdateAbilityLayout(hCaster, tStandardAbilities)

    hCaster:FindAbilityByName("kuro_spellbook_open"):EndCooldown()
end

function kuro_spellbook_close:OnSpellCalled(ability)
    local hCaster = self:GetCaster()

    if hCaster:HasModifier("modifier_kuro_projection_overpower") then
        hCaster:FindAbilityByName("kuro_spellbook_open"):EndCooldown()
    else
        hCaster:FindAbilityByName("kuro_spellbook_open"):EndCooldown()
        UpdateAbilityLayout(hCaster, tStandardAbilities)
        hCaster:FindAbilityByName("kuro_spellbook_open"):StartCooldown(ability:GetCooldown())
    end
end