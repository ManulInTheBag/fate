-- Skin-specific particle / sound overrides.
-- SkinParticle(unit, path) / SkinSound(unit, event) / SkinAttachment(unit, name) /
-- SkinValue(unit, key, default) return the skin's replacement when <unit> is the
-- configured hero wearing that skin, otherwise the original. Safe on the client too: there the skin
-- number comes from the hidden modifier's stack count (skinNumber is server-only).
-- Required by every ability/modifier file that uses it (modifier callbacks also run on the client).

-- this file is loaded in the client VM too (ability/modifier files require it): register the skin
-- modifier there, the server-side link in hero_replacer.lua never reaches the client
LinkLuaModifier("modifier_hero_selection_skin", "modules/hero_selection/modifier_hero_selection_skin.lua", LUA_MODIFIER_MOTION_NONE)

SKIN_OVERRIDES = {
	-- Cu Chulainn (override_hero npc_dota_hero_phantom_lancer)
	npc_dota_hero_phantom_lancer = {
		[1] = { -- Vespa: yellow copies of every Cu particle + harpoon Gae Bolg projectile
			particles = {
				["particles/cu_chulain/combo_gb_targetted.vpcf"] = "particles/custom/vespa/cu_chulain/combo_gb_targetted.vpcf",
				["particles/cu_chulain/combo_gb_targetted_explosion.vpcf"] = "particles/custom/vespa/cu_chulain/combo_gb_targetted_explosion.vpcf",
				["particles/cu_chulain/combo_gb_targetted_jumo.vpcf"] = "particles/custom/vespa/cu_chulain/combo_gb_targetted_jumo.vpcf",
				["particles/cu_chulain/cu_combo_status.vpcf"] = "particles/custom/vespa/cu_chulain/cu_combo_status.vpcf",
				["particles/cu_chulain/cu_rune_of_frost.vpcf"] = "particles/custom/vespa/cu_chulain/cu_rune_of_frost.vpcf",
				["particles/cu_chulain/gae_bolg_pierce.vpcf"] = "particles/custom/vespa/cu_chulain/gae_bolg_pierce.vpcf",
				["particles/cu_chulain/gae_bolg_proj.vpcf"] = "particles/custom/vespa/cu_chulain/gae_bolg_proj.vpcf",
				["particles/cu_chulain/gae_bolg_proj_outline_2.vpcf"] = "particles/custom/vespa/cu_chulain/gae_bolg_proj_outline_2.vpcf",
				["particles/custom/archer/archer_hrunting_orb.vpcf"] = "particles/custom/vespa/custom/archer/archer_hrunting_orb.vpcf",
				["particles/custom/diarmuid/gae_dearg_slash.vpcf"] = "particles/custom/vespa/custom/diarmuid/gae_dearg_slash.vpcf",
				["particles/custom/lancer/lancer_culling_blade_kill.vpcf"] = "particles/custom/vespa/custom/lancer/lancer_culling_blade_kill.vpcf",
				["particles/custom/lancer/lancer_gae_bolg_hit.vpcf"] = "particles/custom/vespa/custom/lancer/lancer_gae_bolg_hit.vpcf",
				["particles/custom/lancer/lancer_heart_break_txt.vpcf"] = "particles/custom/vespa/custom/lancer/lancer_heart_break_txt.vpcf",
				["particles/custom/lancer/lancer_relentless_spear/lancer_relentless_spear.vpcf"] = "particles/custom/vespa/custom/lancer/lancer_relentless_spear/lancer_relentless_spear.vpcf",
				["particles/custom/lancer/soaring/spear.vpcf"] = "particles/custom/vespa/custom/lancer/soaring/spear.vpcf",
				["particles/econ/items/centaur/centaur_ti6_gold/centaur_ti6_ambient_gold_eyes.vpcf"] = "particles/custom/vespa/econ/items/centaur/centaur_ti6_gold/centaur_ti6_ambient_gold_eyes.vpcf",
				["particles/econ/items/void_spirit/void_spirit_immortal_2021/void_spirit_immortal_2021_astral_step_dmg_blood.vpcf"] = "particles/custom/vespa/econ/items/void_spirit/void_spirit_immortal_2021/void_spirit_immortal_2021_astral_step_dmg_blood.vpcf",
				["particles/generic_gameplay/screen_blood_splatter.vpcf"] = "particles/custom/vespa/generic_gameplay/screen_blood_splatter.vpcf",
				["particles/hijikata/hijikata_run_test.vpcf"] = "particles/custom/vespa/hijikata/hijikata_run_test.vpcf",
				["particles/items4_fx/cyclonic_barrier.vpcf"] = "particles/custom/vespa/items4_fx/cyclonic_barrier.vpcf",
				["particles/status_fx/status_effect_beserkers_call.vpcf"] = "particles/custom/vespa/status_fx/status_effect_beserkers_call.vpcf",
				["particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf"] = "particles/custom/vespa/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf",
				["particles/units/heroes/hero_elder_titan/elder_titan_echo_stomp_cracks.vpcf"] = "particles/custom/vespa/units/heroes/hero_elder_titan/elder_titan_echo_stomp_cracks.vpcf",
				["particles/units/heroes/hero_phantom_assassin/phantom_assassin_phantom_strike_end.vpcf"] = "particles/custom/vespa/units/heroes/hero_phantom_assassin/phantom_assassin_phantom_strike_end.vpcf",
				["particles/units/heroes/hero_templar_assassin/templar_assassin_trap_explode.vpcf"] = "particles/custom/vespa/units/heroes/hero_templar_assassin/templar_assassin_trap_explode.vpcf",
				["particles/units/heroes/hero_warlock/warlock_rainofchaos_start_breakout_fallback_mid.vpcf"] = "particles/custom/vespa/units/heroes/hero_warlock/warlock_rainofchaos_start_breakout_fallback_mid.vpcf",
				["particles/zlodemon/immunity_sphere_buff_red.vpcf"] = "particles/custom/vespa/zlodemon/immunity_sphere_buff_red.vpcf",
				["particles/zlodemon/zlodemon_basic_circle.vpcf"] = "particles/custom/vespa/zlodemon/zlodemon_basic_circle.vpcf",
			},
			-- the model's 'weapon' bone is the harpoon; in sword clips it hangs on the belt
			-- colours/numbers the Lua passes into particles (CP colour etc.)
			values = {
				rune_of_combat_ring_color = Vector(1, 0.75, 0.05), -- Cu: Vector(1, 0.1, 0.1)
				-- W3 (relentless spear): gold Okada-style slashes on every hit instead of the trail on the blade.
				-- Trial: delete this line to get the trail back.
				w3_slash_fx = "particles/custom/vespa/okada/vespa_w3_slashes.vpcf",
			},
			attachments = {
				attach_spear_end = "attach_katana_end",
			},
			-- base event -> Vespa event (soundevents/hero_vespa.vsndevts, built by retarget_tools/vespa_sounds.py)
			sounds = {
				["cu_chulain_gae_bolg_voice"] = "vespa_gae_bolg_voice",
				["lancer_gae_bolg_2"] = "vespa_gae_bolg_jump_voice",
				["Cu_Combo_1"] = "vespa_combo_voice_1",
				["Cu_Combo_2"] = "vespa_combo_voice_2",
				["Cu_Combo_3"] = "vespa_combo_voice_3",
				["Lancer.Heartbreak"] = "vespa_combo_voice_4",
				["cu_dash_w_1"] = "vespa_dash_1",
				["cu_dash_w_2"] = "vespa_dash_2",
				["cu_skill_1"] = "vespa_flurry_1",
				["cu_skill_2"] = "vespa_flurry_2",
				["cu_skill_3"] = "vespa_flurry_3",
				["cu_skill_4"] = "vespa_flurry_4",
				["cu_rune_of_frost_cast_1"] = "vespa_frost_cast_1",
				["cu_rune_of_frost_cast_2"] = "vespa_frost_cast_2",
				["cu_protection_1"] = "vespa_protection_1",
				["cu_protection_2"] = "vespa_protection_2",
				["Cu_Battlecont"] = "vespa_battlecont",
				["cu_pierce_new"] = "vespa_pierce_1",
				["cu_pierce_new_2"] = "vespa_pierce_2",
				["Hero_PhantomLancer.Attack"] = "vespa_flurry_hit",   -- W3 hits, trial (user may roll back to stock)
				["Hero_PhantomLancer.Doppelwalk"] = "vespa_disengage",
				["Hero_TemplarAssassin.Trap.Explode"] = "vespa_rune_of_flame",
				["cu_chulain_gae_bolg_retrieve"] = "vespa_retrieve",
				["Misc.Crash"] = "vespa_jump_crash",
				["cu_new_combo_1"] = "vespa_combo_channel",
				["cu_new_combo_2"] = "vespa_combo_hit_1",
				["cu_new_combo_3"] = "vespa_combo_hit_2",
			},
		},
	},
}

function GetSkinNumber(unit)
	if not unit or (unit.IsNull and unit:IsNull()) then return 0 end
	if type(unit.FindModifierByName) == "function" then
		local mod = unit:FindModifierByName("modifier_hero_selection_skin")
		if not mod then return 0 end
		return mod.skinNumber or mod:GetStackCount() or 0
	end
	-- client VM: no FindModifierByName (GetEffectName / GetStatusEffectName run there), and the
	-- skin modifier may be unknown to it -> the server mirrors the number into the 'sync' nettable
	if unit.entindex then
		local t = CustomNetTables:GetTableValue("sync", "hero_skin_" .. unit:entindex())
		if t and t.skin then return tonumber(t.skin) or 0 end
	end
	if type(unit.GetModifierStackCount) == "function" then
		return unit:GetModifierStackCount("modifier_hero_selection_skin", unit) or 0
	end
	return 0
end

local function skinConfig(unit)
	if not unit or (unit.IsNull and unit:IsNull()) or not unit.GetUnitName then return nil end
	local hero = SKIN_OVERRIDES[unit:GetUnitName()]
	if not hero then return nil end
	local n = GetSkinNumber(unit)
	return n ~= 0 and hero[n] or nil
end

function SkinParticle(unit, path)
	local cfg = skinConfig(unit)
	return (cfg and cfg.particles and cfg.particles[path]) or path
end

function SkinAttachment(unit, name)
	local cfg = skinConfig(unit)
	return (cfg and cfg.attachments and cfg.attachments[name]) or name
end

function SkinValue(unit, key, default)
	local cfg = skinConfig(unit)
	local v = cfg and cfg.values and cfg.values[key]
	if v == nil then return default end
	return v
end

function SkinSound(unit, event)
	local cfg = skinConfig(unit)
	return (cfg and cfg.sounds and cfg.sounds[event]) or event
end
