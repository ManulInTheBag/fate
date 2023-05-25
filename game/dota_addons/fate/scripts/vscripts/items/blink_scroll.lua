item_blink_scroll = class({})

local locks = {
    "modifier_sex_scroll_root",
    "locked",
    "dragged",
    "jump_pause_postlock",
    --"modifier_aestus_domus_aurea_enemy",
    --"modifier_aestus_domus_aurea_ally",
    --"modifier_aestus_domus_aurea_nero",
    "modifier_rho_aias",
    "modifier_rho_aias_emiya",
    "modifier_story_for_someones_sake",
    "jump_pause_nosilence",
    "modifier_gordius_wheel",
    --"modifier_whitechapel_murderer",
    --"modifier_whitechapel_murderer_ally",
    --"modifier_whitechapel_murderer_enemy",
    "modifier_jeanne_health_lock",
    "modifier_nero_tres_new",
    "modifier_nero_performance",
    "modifier_arcueid_melty",
    "modifier_altera_dash",
    "modifier_jeanne_gods_resolution_active_buff",
}

function item_blink_scroll:OnSpellStart()
	AbilityBlink(self:GetCaster(), self:GetCursorPosition(), self:GetSpecialValueFor("distance"))
end

function item_blink_scroll:IsResettable()
	return true
end

function item_blink_scroll:CastFilterResultLocation( vLocation )
	local caster = self:GetCaster()

	if self:CheckLocks(caster) then
		return UF_FAIL_CUSTOM
	end

	return UF_SUCCESS


	--if IsServer() then return AbilityBlinkCastError(self:GetCaster(), vLocation) end
end

function item_blink_scroll:CheckLocks(caster)
    for i=1, #locks do
        if caster:HasModifier(locks[i]) then return true end
    end
    return false
end

function item_blink_scroll:GetCustomCastErrorLocation( vLocation )
	return "#Cannot_Blink"
end