-- Skin-specific particle / sound overrides.
-- SkinParticle(unit, path) / SkinSound(unit, event) / SkinAttachment(unit, name) /
-- SkinValue(unit, key, default) return the skin's replacement when <unit> is the
-- configured hero wearing that skin, otherwise the original. Safe on the client too: there the skin
-- number comes from the hidden modifier's stack count (skinNumber is server-only).
-- Required by every ability/modifier file that uses it (modifier callbacks also run on the client).
-- Skin SOUNDS are not emitted directly: SkinEmitSound & co (for SKIN_OVERRIDES.sounds) and
-- SkinSoundPair* / SkinSoundSplit (for skin branches written in the ability code) let each
-- player choose whose skin sounds to hear (Effects tab), see the block below SkinSound.

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


-- ---------------------------------------------------------------------------
-- Who hears a skin's sounds. Each player picks it in the Effects tab
-- (effect_bars.js -> player_skin_sounds -> fate_settings.lua -> SkinSoundSetPrefs):
-- own = my hero's skin, allies, enemies. Spectators are on no hero's team, so the
-- enemies switch is theirs. No entry = hears every skin (the default).
--
-- Skin sound code goes through SkinSoundSplit(caster, skinFn, baseFn): skinFn makes
-- the calls the skin branch made before, baseFn the calls the hero makes without
-- the skin (nil = silent), each through the emitter S it gets:
--   S.EmitSound(unit, ev)  S.EmitSoundOn(ev, unit)  S.EmitGlobalSound(ev)
--   S.EmitSoundOnLocationWithCaster(pos, ev, caster)
-- so a unit sound stays on the unit, a point sound at the point and a global one
-- global, in either branch. While nobody listening opted out, skinFn gets the plain
-- emitter and the engine sees exactly the old calls. Otherwise each branch is played
-- to its own listeners one by one (and if nobody is left on the skin side, the base
-- branch gets the plain emitter again).
-- ---------------------------------------------------------------------------
SKIN_SOUND_PREFS = SKIN_SOUND_PREFS or {}   -- playerID -> { own, allies, enemies } (0/1); only players who turned something off

function SkinSoundSetPrefs(playerID, own, allies, enemies)
	local p = { own = own == 0 and 0 or 1, allies = allies == 0 and 0 or 1, enemies = enemies == 0 and 0 or 1 }
	if p.own == 1 and p.allies == 1 and p.enemies == 1 then
		SKIN_SOUND_PREFS[playerID] = nil
	else
		SKIN_SOUND_PREFS[playerID] = p
	end
end

-- Does <playerID> hear the skin sounds of <caster> (the hero wearing the skin)?
-- Also for code that already sends a sound to each player itself (LoopOverPlayers + emit_horn_sound).
function SkinSoundHeard(caster, playerID)
	local p = SKIN_SOUND_PREFS[playerID]
	if not p then return true end
	if not caster or (caster.IsNull and caster:IsNull()) or not caster.GetTeamNumber then return true end
	if caster.GetPlayerOwnerID and caster:GetPlayerOwnerID() == playerID then
		return p.own == 1
	end
	if PlayerResource:GetTeam(playerID) == caster:GetTeamNumber() then
		return p.allies == 1
	end
	return p.enemies == 1
end

SKIN_SOUND_PLAIN = {
	EmitSound = function(unit, event) unit:EmitSound(event) end,
	EmitSoundOn = function(event, unit) EmitSoundOn(event, unit) end,
	EmitGlobalSound = function(event) EmitGlobalSound(event) end,
	EmitSoundOnLocationWithCaster = function(pos, event, caster) EmitSoundOnLocationWithCaster(pos, event, caster) end,
}

-- A global sound for one player. The server has no call for it that sounds like
-- EmitGlobalSound: EmitAnnouncerSoundForPlayer and EmitSoundOnClient play the same event
-- ~30 dB quieter (measured in game 20.10.2026). So the client plays it itself, as the
-- addon's horn sounds do (sounds.js: emit_presence_sound -> Game.EmitSound): measured as
-- loud and as long, and StopGlobalSound cuts it the same way.
local function emitGlobalForPlayer(event, playerID)
	local player = PlayerResource:GetPlayer(playerID)
	if player then
		CustomGameEventManager:Send_ServerToPlayer(player, "emit_presence_sound", { sound = event })
	end
end

-- The per-player calls ignore the fog of war (measured in game 20.10.2026: a unit in the
-- fog is heard through EmitSoundOnEntityForPlayer, not through EmitSound), so it is checked
-- here by the broadcast's rules, also measured: a unit sound is heard while the unit is
-- seen; a point sound (EmitSoundOnLocationWithCaster) while the point OR the caster is seen.
-- Own team and players without a hero (spectators) hear everything.
SKIN_SOUND_FOG_CHECK = true

-- Debug, console command fate_skin_sounds (cheats only). The per-player calls are used
-- only while the listeners disagree, which a lone client never makes happen: FORCE_SPLIT
-- sends every skin sound through them anyway (the client gets its side one by one), LOG
-- prints where each skin sound went.
SKIN_SOUND_FORCE_SPLIT = SKIN_SOUND_FORCE_SPLIT or false
SKIN_SOUND_LOG = SKIN_SOUND_LOG or false

local function debugLog(text)
	if SKIN_SOUND_LOG then print("[SkinSound] " .. text) end
end

local function unitLabel(unit)
	if not unit or (unit.IsNull and unit:IsNull()) then return "nil" end
	return unit.GetUnitName and unit:GetUnitName() or tostring(unit)
end

local function listenerHero(playerID, team)
	if not SKIN_SOUND_FOG_CHECK or PlayerResource:GetTeam(playerID) == team then return nil end
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	if not hero or hero:IsNull() or not hero.CanEntityBeSeenByMyTeam then return nil end
	return hero
end

local function unitHeardBy(playerID, unit)
	if not unit or (unit.IsNull and unit:IsNull()) or not unit.GetTeamNumber then return true end
	local hero = listenerHero(playerID, unit:GetTeamNumber())
	return not hero or hero:CanEntityBeSeenByMyTeam(unit)
end

local function pointHeardBy(playerID, pos, caster)
	if caster and ((caster.IsNull and caster:IsNull()) or not caster.GetTeamNumber) then caster = nil end
	local hero = listenerHero(playerID, caster and caster:GetTeamNumber())
	if not hero then return true end
	return IsLocationVisible(PlayerResource:GetTeam(playerID), pos)
		or (caster ~= nil and hero:CanEntityBeSeenByMyTeam(caster))
end

local function playersEmitter(playerIDs)
	local function onUnit(event, unit)
		for _, pid in ipairs(playerIDs) do
			if unitHeardBy(pid, unit) then
				EmitSoundOnEntityForPlayer(event, unit, pid)
				debugLog("P" .. pid .. " unit " .. event .. " @" .. unitLabel(unit))
			else
				debugLog("P" .. pid .. " fog, skipped unit " .. event .. " @" .. unitLabel(unit))
			end
		end
	end
	return {
		EmitSound = function(unit, event) onUnit(event, unit) end,
		EmitSoundOn = onUnit,
		EmitGlobalSound = function(event)
			for _, pid in ipairs(playerIDs) do
				emitGlobalForPlayer(event, pid)
				debugLog("P" .. pid .. " global " .. event)
			end
		end,
		EmitSoundOnLocationWithCaster = function(pos, event, caster)
			for _, pid in ipairs(playerIDs) do
				if pointHeardBy(pid, pos, caster) then
					EmitSoundOnLocationForPlayer(event, pos, pid)
					debugLog("P" .. pid .. " point " .. event)
				else
					debugLog("P" .. pid .. " fog, skipped point " .. event)
				end
			end
		end,
	}
end

-- nil = everybody hears the skin (play it the old way); else the two lists of player IDs
local function splitListeners(caster)
	if not IsServer() or (next(SKIN_SOUND_PREFS) == nil and not SKIN_SOUND_FORCE_SPLIT) then return nil end
	local skin, base = {}, {}
	for pid = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		if PlayerResource:GetPlayer(pid) then
			if SkinSoundHeard(caster, pid) then
				skin[#skin + 1] = pid
			else
				base[#base + 1] = pid
			end
		end
	end
	if #base == 0 and not SKIN_SOUND_FORCE_SPLIT then return nil end
	return skin, base
end

function SkinSoundSplit(caster, skinFn, baseFn)
	local skin, base = splitListeners(caster)
	if not skin then
		debugLog("plain skin, " .. unitLabel(caster))
		if skinFn then skinFn(SKIN_SOUND_PLAIN) end
	elseif #skin == 0 and not SKIN_SOUND_FORCE_SPLIT then
		debugLog("plain base, " .. unitLabel(caster))
		if baseFn then baseFn(SKIN_SOUND_PLAIN) end
	else
		debugLog("split skin={" .. table.concat(skin, ",") .. "} base={" .. table.concat(base, ",") .. "}, " .. unitLabel(caster))
		if skinFn then skinFn(playersEmitter(skin)) end
		if baseFn then baseFn(playersEmitter(base)) end
	end
end

-- The same for one event on each side (nil = nothing on that side). Equal events
-- (no skin, or the skin keeps this sound) are just the plain call.
function SkinSoundPair(unit, caster, skinEvent, baseEvent)
	if skinEvent == baseEvent then
		if skinEvent then unit:EmitSound(skinEvent) end
		return
	end
	SkinSoundSplit(caster,
		skinEvent and function(S) S.EmitSound(unit, skinEvent) end,
		baseEvent and function(S) S.EmitSound(unit, baseEvent) end)
end

function SkinSoundPairGlobal(caster, skinEvent, baseEvent)
	if skinEvent == baseEvent then
		if skinEvent then EmitGlobalSound(skinEvent) end
		return
	end
	SkinSoundSplit(caster,
		skinEvent and function(S) S.EmitGlobalSound(skinEvent) end,
		baseEvent and function(S) S.EmitGlobalSound(baseEvent) end)
end

function SkinSoundPairAt(pos, caster, skinEvent, baseEvent)
	if skinEvent == baseEvent then
		if skinEvent then EmitSoundOnLocationWithCaster(pos, skinEvent, caster) end
		return
	end
	SkinSoundSplit(caster,
		skinEvent and function(S) S.EmitSoundOnLocationWithCaster(pos, skinEvent, caster) end,
		baseEvent and function(S) S.EmitSoundOnLocationWithCaster(pos, baseEvent, caster) end)
end

-- Stop for a pair: listeners who opted out got the base event.
function SkinSoundPairStop(unit, skinEvent, baseEvent)
	if skinEvent then unit:StopSound(skinEvent) end
	if baseEvent and baseEvent ~= skinEvent then unit:StopSound(baseEvent) end
end

-- SKIN_OVERRIDES.sounds (SkinSound) versions: <event> is the base hero's event.
function SkinEmitSound(unit, caster, event)
	local skinEvent = SkinSound(caster, event)
	if skinEvent == event then
		unit:EmitSound(event)
	else
		SkinSoundPair(unit, caster, skinEvent, event)
	end
end

function SkinEmitGlobalSound(caster, event)
	local skinEvent = SkinSound(caster, event)
	if skinEvent == event then
		EmitGlobalSound(event)
	else
		SkinSoundPairGlobal(caster, skinEvent, event)
	end
end

function SkinEmitSoundOnLocationWithCaster(pos, event, caster)
	local skinEvent = SkinSound(caster, event)
	if skinEvent == event then
		EmitSoundOnLocationWithCaster(pos, event, caster)
	else
		SkinSoundPairAt(pos, caster, skinEvent, event)
	end
end

-- Stops whichever of the two the listeners got.
function SkinStopSound(unit, caster, event)
	local skinEvent = SkinSound(caster, event)
	unit:StopSound(skinEvent)
	if skinEvent ~= event then
		unit:StopSound(event)
	end
end


-- fate_skin_sounds split 0|1 | log 0|1 | me <own> <allies> <enemies> | status
-- "me" sets the switches of whoever typed it, as the Effects tab does.
function SkinSoundDebugCommand(sub, a, b, c)
	if sub == "split" then
		SKIN_SOUND_FORCE_SPLIT = a == "1"
	elseif sub == "log" then
		SKIN_SOUND_LOG = a == "1"
	elseif sub == "me" then
		-- the host's console has no command client with a PlayerID: then it is player 0
		local player = Convars:GetCommandClient()
		local pid = player and player.GetPlayerID and player:GetPlayerID() or 0
		SkinSoundSetPrefs(pid, tonumber(a), tonumber(b), tonumber(c))
	end
	local prefs = {}
	for pid, p in pairs(SKIN_SOUND_PREFS) do
		prefs[#prefs + 1] = pid .. "=" .. p.own .. p.allies .. p.enemies
	end
	print("[SkinSound] split=" .. tostring(SKIN_SOUND_FORCE_SPLIT) .. " log=" .. tostring(SKIN_SOUND_LOG)
		.. " prefs(own,allies,enemies): " .. (#prefs > 0 and table.concat(prefs, " ") or "none"))
end

if IsServer() and Convars and not SKIN_SOUND_CMD_REGISTERED then
	SKIN_SOUND_CMD_REGISTERED = true
	Convars:RegisterCommand("fate_skin_sounds", function(_, ...) SkinSoundDebugCommand(...) end,
		"skin sounds debug: split 0|1, log 0|1, me <own> <allies> <enemies>, status", FCVAR_CHEAT)
end
