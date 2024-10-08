item_blink_scroll = class({})
function item_blink_scroll:GetAOERadius()
    return self:GetSpecialValueFor("distance")
end
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
    "modifier_robin_yew_bow_combo_lock",
    "modifier_robin_tools_its_a_trap",
}
function item_blink_scroll:GetBehavior()
    if self:GetCaster():HasModifier("modifier_nobu_turnlock") then
        return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
    else
        return DOTA_ABILITY_BEHAVIOR_POINT
    end
end

function item_blink_scroll:OnSpellStart()
    local currentHeroPos = self:GetCaster():GetAbsOrigin()
    local afterBlinkPos =  AbilityBlink(self:GetCaster(), self:GetCursorPosition(), self:GetAOERadius())
    if self:GetCaster():GetName() == "npc_dota_hero_spirit_breaker" then
        local modifier = self:GetCaster():FindModifierByName("modifier_hijikata_laws")
        modifier:CheckBlinkCondition(currentHeroPos, afterBlinkPos)
    end

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