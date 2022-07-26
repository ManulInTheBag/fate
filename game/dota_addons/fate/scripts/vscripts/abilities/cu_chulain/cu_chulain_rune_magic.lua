cu_chulain_rune_magic = class({})
cu_chulain_close_runes = class({})

local tNormalSkills = {
    "cu_chulain_rune_magic",
    "cu_chulain_relentless_spear",
    "cu_chulain_gae_bolg",
    "cu_chulain_protection_from_arrows",
    "cu_chulain_battle_continuation",
    "cu_chulain_gae_bolg_jump",
    "attribute_bonus_custom"
}

local tRunes = {
    "cu_chulain_rune_of_disengage",
    "cu_chulain_rune_of_combat",
    "cu_chulain_rune_of_ferocity",
    "cu_chulain_rune_of_protection",
    "cu_chulain_close_runes",
    "cu_chulain_rune_of_flame",
    "attribute_bonus_custom"
}

function cu_chulain_rune_magic:OnUpgrade()
    local hCaster = self:GetCaster()
    local abilityLevel = self:GetLevel()

    hCaster:FindAbilityByName("cu_chulain_rune_of_disengage"):SetLevel(abilityLevel)
    hCaster:FindAbilityByName("cu_chulain_rune_of_combat"):SetLevel(abilityLevel)
    hCaster:FindAbilityByName("cu_chulain_rune_of_ferocity"):SetLevel(abilityLevel)
    hCaster:FindAbilityByName("cu_chulain_rune_of_protection"):SetLevel(abilityLevel)
    hCaster:FindAbilityByName("cu_chulain_rune_of_flame"):SetLevel(abilityLevel)
end

function cu_chulain_rune_magic:OnSpellStart()
	local hCaster = self:GetCaster()

	UpdateAbilityLayout(hCaster, tRunes)
end

function cu_chulain_rune_magic:CloseSpellbook(flCooldown)
	local hCaster = self:GetCaster()

	UpdateAbilityLayout(hCaster, tNormalSkills)

    if hCaster:HasModifier("modifier_wesen_window") then
        hCaster:SwapAbilities("cu_chulain_gae_bolg", "cu_chulain_gae_bolg_combo", false, true)
    end

	if not hCaster:HasModifier("modifier_celtic_rune_attribute") then
		self:StartCooldown(flCooldown)
	end
end

function cu_chulain_close_runes:OnSpellStart()
	local caster = self:GetCaster()
	caster:FindAbilityByName("cu_chulain_rune_magic"):CloseSpellbook(1)
end