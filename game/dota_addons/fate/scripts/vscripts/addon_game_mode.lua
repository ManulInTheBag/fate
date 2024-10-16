AllPlayersInterval = {0,1,2,3,4,5,6,7,8,9,10,11,12,13}

require("eyeherodemo/demo_core") --TEST HERO MOD



require("statcollection/init")
require('lishuwen_ability')
require('archer_ability')
require('master_ability')
require('gille_ability')
require('lancelot_ability')
require('nursery_rhyme_ability')
require('libraries/notifications')
require('items')
require('modifiers/attributes')
require('libraries/util' )
require('libraries/timers')
require('libraries/fate_projectile_manager_test')
require('libraries/popups')
require('libraries/animations')
require("util/playerresource")
require("libraries/playertables")
require('libraries/crowdcontrol')
require('libraries/physics')
require('libraries/attachments')
require('libraries/anime_vector_targeting')
--require('libraries/vector_target')
--require('hero_selection')
require('libraries/servantstats')
require('libraries/alternateparticle')
require("util/other")
require("util/table")
require("util/string")
require("util/ability")
require("util/units")
require("modules/index")
require("data/kv_data")
require("data/globals")
require("libraries/keyvalues")
require('libraries/cameramodule')

require('blink')
--require('unit_voice')
require('wrappers')

_G.IsPickPhase = true
_G.IsPreRound = true
_G.RoundStartTime = 0
_G.nCountdown = 0
_G.CurrentGameState = "FATE_PRE_GAME"
_G.GameMap = ""
_G.LaPucelleActivated = false
_G.FIRST_BLOOD_TRIGGERED = false
_G.ClownActive = false
_G.AllNpcTable = {}
_G.projfix = false

ENABLE_HERO_RESPAWN = false -- Should the heroes automatically respawn on a timer or stay dead until manually respawned
UNIVERSAL_SHOP_MODE = true -- Should the main shop contain Secret Shop items as well as regular items
ALLOW_SAME_HERO_SELECTION = false -- Should we let people select the same hero as each other
HERO_SELECTION_TIME = 60.0 -- How long should we let people select their hero?
PRE_GAME_TIME = 0 -- How long after people select their heroes should the horn blow and the game start?
POST_GAME_TIME = 10.0 -- How long should we let people look at the scoreboard before closing the server automatically?
TREE_REGROW_TIME = 60.0 -- How long should it take individual trees to respawn after being cut down/destroyed?
GOLD_PER_TICK = 0 -- How much gold should players get per tick?
GOLD_TICK_TIME = 0 -- How long should we wait in seconds between gold ticks?
RECOMMENDED_BUILDS_DISABLED = false -- Should we disable the recommened builds for heroes (Note: this is not working currently I believe)
CAMERA_DISTANCE_OVERRIDE = 1250.0 -- How far out should we allow the camera to go? 1134 is the default in Dota
MINIMAP_ICON_SIZE = 1 -- What icon size should we use for our heroes?
MINIMAP_CREEP_ICON_SIZE = 1 -- What icon size should we use for creeps?
MINIMAP_RUNE_ICON_SIZE = 1 -- What icon size should we use for runes?
RUNE_SPAWN_TIME = 120 -- How long in seconds should we wait between rune spawns?
CUSTOM_BUYBACK_COST_ENABLED = true -- Should we use a custom buyback cost setting?
CUSTOM_BUYBACK_COOLDOWN_ENABLED = true -- Should we use a custom buyback time?
BUYBACK_ENABLED = false -- Should we allow people to buyback when they die?
DISABLE_FOG_OF_WAR_ENTIRELY = false -- Should we disable fog of war entirely for both teams?
--USE_STANDARD_DOTA_BOT_THINKING = false -- Should we have bots act like they would in Dota? (This requires 3 lanes, normal items, etc)
USE_STANDARD_HERO_GOLD_BOUNTY = false -- Should we give gold for hero kills the same as in Dota, or allow those values to be changed?
USE_CUSTOM_TOP_BAR_VALUES = true -- Should we do customized top bar values or use the default kill count per team?
TOP_BAR_VISIBLE = true -- Should we display the top bar score/count at all?
SHOW_KILLS_ON_TOPBAR = true -- Should we display kills only on the top bar? (No denies, suicides, kills by neutrals) Requires USE_CUSTOM_TOP_BAR_VALUES
ENABLE_TOWER_BACKDOOR_PROTECTION = false-- Should we enable backdoor protection for our towers?
REMOVE_ILLUSIONS_ON_DEATH = false -- Should we remove all illusions if the main hero dies?
DISABLE_GOLD_SOUNDS = false -- Should we disable the gold sound when players get gold?
END_GAME_ON_KILLS = false -- Should the game end after a certain number of kills?
KILLS_TO_END_GAME_FOR_TEAM = 9999 -- How many kills for a team should signify an end of game?
USE_CUSTOM_HERO_LEVELS = true -- Should we allow heroes to have custom levels?
MAX_LEVEL = 24 -- What level should we let heroes get to?
USE_CUSTOM_XP_VALUES = true -- Should we use custom XP values to level up heroes, or the default Dota numbers?
DISABLE_ANNOUNCER = true               -- Should we disable the announcer from working in the game?
LOSE_GOLD_ON_DEATH = false               -- Should we have players lose the normal amount of dota gold on death?
VICTORY_CONDITION = 12 -- Round required for win



XP_TABLE = {}
_G.XP_PER_LEVEL_TABLE = {}
BOUNTY_PER_LEVEL_TABLE = {}
XP_BOUNTY_PER_LEVEL_TABLE = {}
PRE_ROUND_DURATION = 12
PRESENCE_ALERT_DURATION = 60
ROUND_DURATION = 120
FIRST_BLESSING_PERIOD = 300
BLESSING_PERIOD = 480
BLESSING_MANA_REWARD = 15
SPAWN_POSITION_RADIANT_DM = Vector(-5300, 650, 376)
SPAWN_POSITION_DIRE_DM = Vector(7230, 4400, 755)
SPAWN_POSITION_T1_TRIO = Vector(-796,7032,512)
SPAWN_POSITION_T2_TRIO = Vector(5676,6800,512)
SPAWN_POSITION_T3_TRIO = Vector(5780,2504,512)
SPAWN_POSITION_T4_TRIO = Vector(-888,1748,512)
TRIO_RUMBLE_CENTER = Vector(2436,4132,1000)
FFA_CENTER = Vector(368,3868,1000)
mode = nil
FATE_VERSION = "v13.37"
roundQuest = nil
IsGameStarted = false

-- XP and XP Bounty stuffs
XP_TABLE[0] = 0
XP_TABLE[1] = 200
for i=2,(MAX_LEVEL-1) do
    XP_TABLE[i] = XP_TABLE[i-1] + i * 100 -- XP required per level formula : Previous level XP requirement + Level * 100
end

-- EXP required to reach next level
_G.XP_PER_LEVEL_TABLE[0] = 0
_G.XP_PER_LEVEL_TABLE[1] = 200
_G.XP_PER_LEVEL_TABLE[24] = 0
for i=2,MAX_LEVEL-2 do
    _G.XP_PER_LEVEL_TABLE[i] = XP_TABLE[i+1] - XP_TABLE[i] -- XP required per level formula : Previous level XP requirement + Level * 100
end


_G.XP_PER_LEVEL_TABLE[MAX_LEVEL-1] = _G.XP_PER_LEVEL_TABLE[MAX_LEVEL-2] + 2400

for i=1, MAX_LEVEL do
    --BOUNTY_PER_LEVEL_TABLE[i] = 1050 + i * 50
    BOUNTY_PER_LEVEL_TABLE[i] = 1800
end

XP_BOUNTY_PER_LEVEL_TABLE[1] = 100
XP_BOUNTY_PER_LEVEL_TABLE[2] = 100 * 0.85 + 8 + 100
for i=3, MAX_LEVEL do
    XP_BOUNTY_PER_LEVEL_TABLE[i] = XP_BOUNTY_PER_LEVEL_TABLE[i-1] * 0.85 + i * 4 + 120 
    -- Bounty XP formula : Previous level XP + Current Level * 4 + 120(constant)
end

-- Client to Server message data tables
local winnerEventData = {
    winnerTeam = 3, -- 0: Radiant, 1: Dire, 2: Draw
    radiantScore = 0,
    direScore = 0
}
local victoryConditionData = {
    victoryCondition = 12
}

Options:Preload()

Convars:SetInt("sv_forcepreload", 1)
 

model_lookup = {}
model_lookup["npc_dota_hero_legion_commander"] = "models/saber/saber.vmdl"
model_lookup["npc_dota_hero_phantom_lancer"] = "models/lancer/lancer2.vmdl"
model_lookup["npc_dota_hero_spectre"] = "models/saber_alter/sbr_alter.vmdl"
model_lookup["npc_dota_hero_ember_spirit"] = "models/archer/archertest.vmdl"
model_lookup["npc_dota_hero_templar_assassin"] = "models/rider/rider.vmdl"
model_lookup["npc_dota_hero_doom_bringer"] = "models/berserker/berserker.vmdl"
model_lookup["npc_dota_hero_juggernaut"] = "models/assassin/asn.vmdl"
model_lookup["npc_dota_hero_bounty_hunter"] = "models/true_assassin/ta.vmdl"
model_lookup["npc_dota_hero_crystal_maiden"] = "models/caster/caster.vmdl"
model_lookup["npc_dota_hero_skywrath_mage"] = "models/gilgamesh/gilgamesh.vmdl"
model_lookup["npc_dota_hero_sven"] = "models/lancelot/lancelot.vmdl"
model_lookup["npc_dota_hero_vengefulspirit"] = "models/avenger/avenger.vmdl"
model_lookup["npc_dota_hero_huskar"] = "models/diarmuid/diarmuid2.vmdl"
model_lookup["npc_dota_hero_chen"] = "models/iskander/iskander.vmdl"
model_lookup["npc_dota_hero_shadow_shaman"] = "models/zc/gille.vmdl"
model_lookup["npc_dota_hero_lina"] = "models/nero/nero.vmdl"
model_lookup["npc_dota_hero_omniknight"] = "models/gawain/gawain.vmdl"
model_lookup["npc_dota_hero_enchantress"] = "models/tamamo/tamamo.vmdl"
model_lookup["npc_dota_hero_bloodseeker"] = "models/lishuen/lishuen.vmdl"
model_lookup["npc_dota_hero_mirana"] = "models/jeanne/jeanne.vmdl"
model_lookup["npc_dota_hero_queenofpain"] = "models/astolfo/astolfo.vmdl"
model_lookup["npc_dota_hero_phantom_assassin"] = "models/semi/semi.vmdl"
model_lookup["npc_dota_hero_beastmaster"] = "models/karna/karna.vmdl"
model_lookup["npc_dota_hero_naga_siren"] = "models/kuro/kuro.vmdl"
model_lookup["npc_dota_hero_dark_willow"] = "models/okita/okita_new.vmdl"
model_lookup["npc_dota_hero_riki"] = "models/jtr/jtr.vmdl"
model_lookup["npc_dota_hero_centaur"] = "models/lu_bu/lu_bu.vmdl"

DoNotKillAtTheEndOfRound = {
    "tamamo_charm",
    "jeanne_banner"
}
voteResultTable = {
    0, -- 12 kills
    0,  -- 10
    0, -- 8
    0,  -- 6
    0  -- 4
}
--[[voteResultTable = {
    v_OPTION_1 = 0, -- 12 kills
    v_OPTION_2 = 0,  -- 10
    v_OPTION_3 = 0, -- 8
    v_OPTION_4 = 0,  -- 6
    v_OPTION_5 = 0  -- 4
}]]--
voteResults_DM = {
    16, 14, 12, 10, 8
}

voteResults_TRIO = {
    45, 40, 35, 30, 25
}

voteResults_FFA = {
    30, 27, 24, 21, 18
}

gameState = {
    "FATE_PRE_GAME",
    "FATE_PRE_ROUND",
    "FATE_ROUND_ONGOING",
    "FATE_POST_ROUND"
}

gameMaps = {
    "fate_elim_6v6",
    "fate_elim_7v7",
    "anime_fate_7vs7_beta",
    "fate_ffa",
    "fate_trio_rumble_3v3v3v3",
    "7vs7_common",
    "7vs7_draft"
}


if FateGameMode == nil then
    FateGameMode = class({})
end

-- Create the game mode when we activate
function Activate()
    GameRules.AddonTemplate = FateGameMode()
    GameRules.AddonTemplate:InitGameMode()
end


function Precache( context )
    print("Starting precache")
    --PrecacheUnitByNameSync("npc_precache_everything", context)

    --PrecacheResource("soundfile", "soundevents/music/*.vsndevts", context)
    --[[Kill the default sound files
    PrecacheResource("soundfile", "soundevents/music/valve_dota_001/soundevents_stingers.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/music/valve_dota_001/soundevents_music.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/music/valve_dota_001/game_sounds_music.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/music/valve_dota_001/music/game_sounds_music.vsndevts", context)

    PrecacheResource("soundfile", "soundevents/bgm.vsndevts", context)]]
    -- Sound files
    PrecacheResource("soundfile", "soundevents/hero_chocolate.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/announcer.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/clown.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/ally_sounds.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/enemy_sounds.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/bgm.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/misc_sound.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_archer.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_avenger.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_caster.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_berserker.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_fa.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_gilg.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_iskander.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_lancelot.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_lancer.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_rider.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_saber.vsndevts", context)
    --PrecacheResource("sounfile", "soundevents/saber_oath.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/haru_yo.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_saber_alter.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/gay_power.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_ta.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_zc.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_zl.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_nero.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_gawain.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/devil_trigger.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_tamamo.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/jtr_rework.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/hero_lishuwen.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_ruler.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_astolfo.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/hero_nursery_rhyme.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/leroy_jenkins.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/gachi.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/piano.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/magich.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/combo_gawain_jojo.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/killer_queen.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_atalanta.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/hero_vlad.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/hero_karna.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/hero_okita.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/hero_jtr.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/hero_saito_hajime.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/hero_merlin.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/hero_muramasa.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/hero_oda_nobunaga.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/sounds_test.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/soundevents_conquest.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/hero_nanaya.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/a_negri.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/zlodemon_true.vsndevts", context )
    PrecacheResource("soundfile", "soundevents/moskes_sasaki.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/pepeg_razgovor.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/heroes/saito.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/heroes/arash.vsndevts", context)
    
	PrecacheResource("soundfile", "soundevents/hero_lu_bu.vsndevts", context )
	PrecacheResource("model", "models/lu_bu/lu_bu.vmdl", context)
    
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_silencer.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_enigma.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_bane.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_gyrocopter.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_necrolyte.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_leshrac.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_windrunner.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sound_pudge.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_earthshaker.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_doombringer.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_phoenix.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_razor.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_dragon_knight.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_earth_spirit.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_lion.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_void_spirit.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_ogre_magi.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_life_stealer.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_phantom_assassin.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_treant.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_drowranger.vsndevts", context)
    
    PrecacheResource("soundfile", "soundevents/game_sounds_items.vsndevts", context)

    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_abaddon.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_beastmaster.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_bloodseeker.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_bounty_hunter.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_chen.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_crystalmaiden.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_doom_bringer.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_drowranger.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_ember_spirit.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_enchantress.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_faceless_void.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_gyrocopter.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_huskar.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_juggernaut.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_legion_commander.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_lina.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_mirana.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_omniknight.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_phantom_lancer.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_queenofpain.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_razor.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_night_stalker.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_riki.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_shadowshaman.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_skeleton_king.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_skywrath_mage.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_spectre.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_sven.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_templar_assassin.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_tidehunter.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_treant.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_dark_willow.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_ursa.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_vengefulspirit.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_windrunner.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_pugna.vsndevts", context )
    PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_clinkz.vsndevts", context )

    -- Items
    PrecacheItemByNameSync("item_apply_modifiers", context)
    PrecacheItemByNameSync("item_mana_essence", context)
    PrecacheItemByNameSync("item_condensed_mana_essence", context)
    PrecacheItemByNameSync("item_teleport_scroll", context)
    PrecacheItemByNameSync("item_gem_of_speed", context)
    PrecacheItemByNameSync("item_scout_familiar", context)
    PrecacheItemByNameSync("item_berserk_scroll", context)
    PrecacheItemByNameSync("item_ward_familiar", context)
    PrecacheItemByNameSync("item_mass_teleport_scroll", context)
    PrecacheItemByNameSync("item_gem_of_resonance", context)
    PrecacheItemByNameSync("item_blink_scroll", context)
    PrecacheItemByNameSync("item_spirit_link" , context)
    PrecacheItemByNameSync("item_c_scroll", context)
    PrecacheItemByNameSync("item_b_scroll", context)
    PrecacheItemByNameSync("item_a_scroll", context)
    PrecacheItemByNameSync("item_a_plus_scroll", context)
    PrecacheItemByNameSync("item_s_scroll", context)
    PrecacheItemByNameSync("item_ex_scroll", context)
    PrecacheItemByNameSync("item_summon_skeleton_warrior", context)
    PrecacheItemByNameSync("item_summon_skeleton_archer", context)
    PrecacheItemByNameSync("item_summon_ancient_dragon", context)
    PrecacheItemByNameSync("item_all_seeing_orb", context)
    PrecacheItemByNameSync("item_shard_of_anti_magic", context)
    PrecacheItemByNameSync("item_shard_of_replenishment", context)

    -- Master, Stash, and System stuffs
    PrecacheResource("model", "models/shirou/shirou.vmdl", context)
    PrecacheResource("model", "models/items/courier/catakeet/catakeet_boxes.vmdl", context)
    PrecacheResource("model", "models/konomama_hassan/konomama_hassan.vmdl", context)
    PrecacheResource("model", "models/femalehassan/femalehassan.vmdl", context)
    PrecacheResource("model", "models/rin/rin.vmdl", context)
    PrecacheResource("model", "models/altera/altera.vmdl", context)
    PrecacheResource("model", "models/okita/okita.vmdl", context)    

    PrecacheResource( "particle", "particles/units/heroes/hero_silencer/silencer_global_silence_sparks.vpcf", context)
    PrecacheResource( "particle", "particles/custom/system/damage_popup.vpcf", context)
    PrecacheResource( "particle", "particles/custom/system/damage_popup_magical.vpcf", context)
    PrecacheResource( "particle", "particles/custom/system/damage_popup_physical.vpcf", context)
    PrecacheResource( "particle", "particles/custom/system/damage_popup_pure.vpcf", context)
    PrecacheResource( "particle", "particles/custom/system/gold_popup.vpcf", context)

    PrecacheResource("particle", "particles/custom/gilles/gilles_summon_jellyfish.vpcf", context)
    PrecacheResource("particle", "particles/custom/tamamo/frigid_heaven.vpcf", context)
    PrecacheResource("particle", "particles/custom/tamamo/gust_heaven_static.vpcf", context)
    PrecacheResource("particle", "particles/custom/atalanta/rainbow_arrow.vpcf", context)
    PrecacheResource("particle", "particles/custom/atalanta/normal_arrow.vpcf", context)

    PrecacheResource( "particle_folder", "particles/econ/items/juggernaut", context )
    --PrecacheResource( "particle_folder", "particles/econ/items/windrunner", context )

--[[
    PrecacheResource("particle", "particles/custom/gilgamesh/gilgamesh_sword_barrage_model.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_gyrocopter/gyro_guided_missile_explosion.vpcf", context)
    PrecacheResource("particle", "particles/custom/archer/archer_sword_barrage_impact_circle.vpcf", context)
    PrecacheResource("particle", "particles/custom/diarmuid/gae_dearg_slash.vpcf", context)
    PrecacheResource("particle", "particles/custom/diarmuid/gae_dearg_slash_flash.vpcf", context)
    PrecacheResource("particle", "particles/custom/diarmuid/diarmuid_yellow_trail.vpcf", context)
    PrecacheResource("particle", "particles/custom/diarmuid/diarmuid_red_trail.vpcf", context)
]]

    -- AOTK Soldier assets
    PrecacheResource("model_folder", "models/heroes/chen", context)
    PrecacheResource("model_folder", "models/items/chen", context)
    PrecacheResource("model_folder", "models/heroes/dragon_knight", context)
    PrecacheResource("model_folder", "models/items/dragon_knight", context)
    PrecacheResource("model_folder", "models/heroes/chaos_knight", context)
    PrecacheResource("model_folder", "models/items/chaos_knight", context)
    PrecacheResource("model_folder", "models/heroes/silencer", context)
    PrecacheResource("model_folder", "models/items/silencer", context)
    PrecacheResource("model_folder", "models/heroes/windrunner", context)
    PrecacheResource("model_folder", "models/items/windrunner", context)

    -- Vector target
    --VectorTarget:Precache( context )

    print("precache complete")

    local tUnitsList = LoadKeyValues("scripts/npc/npc_units_custom.txt")
    for sKeyName, sUnitName in pairs(tUnitsList) do
        --print(sKeyName, sUnitName, "pogchamp")
        PrecacheUnitByNameSync(sKeyName, context)
    end
end

function FateGameMode:PostLoadPrecache()
  --  print("[BAREBONES] Performing Post-Load precache")
end

--[[
This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
    It can be used to initialize state that isn't initializeable in InitFateGameMode() but needs to be done before everyone loads in.
    ]]
function FateGameMode:OnFirstPlayerLoaded()
  --  print("[BAREBONES] First Player has loaded")
  --local DEDICATE_KEY = GetDedicatedServerKeyV2("1.0")
  --print(DEDICATE_KEY)
end

--[[
This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
    It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
    ]]
function FateGameMode:OnAllPlayersLoaded()
   -- print("[BAREBONES] All Players have loaded into the game")
    GameRules:SendCustomMessage("Fate/Balance " .. FATE_VERSION .. " by Balance Department", 0, 0)
    GameRules:SendCustomMessage("Game is currently and forever in beta, so you may run into minor and major issues that nobody cares about. You've been warned.", 0, 0)
    --GameRules:SendCustomMessage("#Fate_Choose_Hero_Alert_60", 0, 0)
    --FireGameEvent('cgm_timer_display', { timerMsg = "Hero Select", timerSeconds = 61, timerEnd = true, timerPosition = 100})

    -- initialize vector targeting
    --VectorTarget:Init({noOrderFilter = true })
    -- Send KV to fatepedia
    -- Announce the goal of game
    -- Reveal the vote winner
    local maxval = voteResultTable[1]
    local maxkey = 1
    local votePool = nil
    if _G.GameMap == "fate_elim_6v6" or _G.GameMap == "fate_elim_7v7" or _G.GameMap == "fate_elim_7v7_test"  or _G.GameMap =="anime_fate_7vs7_beta" or _G.GameMap =="7vs7_common" or _G.GameMap =="7vs7_draft" then
        votePool = voteResults_DM
        maxkey = voteResults_DM[1]
    elseif _G.GameMap == "fate_trio_rumble_3v3v3v3" then
        votePool = voteResults_TRIO
        maxkey = voteResults_TRIO[1]
    elseif _G.GameMap == "fate_ffa" then
        votePool = voteResults_FFA
        maxkey = voteResults_FFA[1]
    end

    for i=1, 5 do
        if voteResultTable[i] > maxval then
            maxval = i
            maxkey = votePool[i]
        end
    end  
    
    
    local particleDummyOrigin
    if _G.GameMap == "fate_elim_6v6" or _G.GameMap == "fate_elim_7v7" or _G.GameMap == "fate_elim_7v7_test"  or _G.GameMap =="anime_fate_7vs7_beta" or _G.GameMap =="7vs7_common" or _G.GameMap =="7vs7_draft" then
        particleDummyOrigin = Vector(-7900,-8000, 200)--Vector(6250,-7200, 200)
    elseif _G.GameMap == "fate_trio_rumble_3v3v3v3" or "fate_ffa" then
        particleDummyOrigin = Vector(6250,-7200, 200)
    end    
    --add global particle dummy in master's territory along with vision for both teams

    local particleDummy = CreateUnitByName("visible_dummy_unit", particleDummyOrigin, true, nil, nil, 4)
    particleDummy:FindAbilityByName("dummy_visible_unit_passive"):SetLevel(1)
    AddFOWViewer(2, particleDummyOrigin, 500, 99999, false) -- duration -1 doesnt work lols
    AddFOWViewer(3, particleDummyOrigin, 500, 99999, false)
    _G.ParticleDummy = particleDummy

    local easterEggloc = Vector(6911, 6325, 384)
    local easterEggDummy = CreateUnitByName("altera_dummy", easterEggloc, true, nil, nil, 4)
    easterEggDummy:SetForwardVector(Vector(6915, 5540, 384) * -1)

    local easterEggloc2 = Vector(-7795, 7112, 512)
    local easterEggDummy2 = CreateUnitByName("okita_dummy", easterEggloc2, true, nil, nil, 4)
    easterEggDummy2:SetForwardVector(Vector(-7781, 6684, 512) * -1)
    
    -- CUSTOM COLOURS
    badGuyColorIndex = 1
    goodGuyColorIndex = 1
    badColorTable = {{164,105,0},{254,134,194},{0,131,33},{101,217,247},{161,180,71},{244,164,96},{176,196,222}}
    goodColorTable = {{51,117,255},{102,255,191},{255,107,0},{191,0,191},{243,240,11},{255,20,147},{220,20,60}}
    for i=0, 13 do
        if PlayerResource:GetPlayer(i) ~= nil then
            local playerID = i
            local player = PlayerResource:GetPlayer(i)
            print(playerID)
            print(player:GetTeam())

            if player:GetTeam() == 2 then
                print("GOOD GUY COLOR")
                PlayerResource:SetCustomPlayerColor(i, goodColorTable[goodGuyColorIndex][1], goodColorTable[goodGuyColorIndex][2], goodColorTable[goodGuyColorIndex][3])
                goodGuyColorIndex = goodGuyColorIndex + 1
            else
                print("BAD GUY COLOR")
                PlayerResource:SetCustomPlayerColor(i, badColorTable[badGuyColorIndex][1], badColorTable[badGuyColorIndex][2], badColorTable[badGuyColorIndex][3])
                badGuyColorIndex = badGuyColorIndex + 1
            end
        end
    end

    VICTORY_CONDITION = maxkey
    victoryConditionData.victoryCondition = VICTORY_CONDITION
    --VICTORY_CONDITION = 1
    --GameRules:SendCustomMessage("<font color='#FF3399'>Vote Result:</font> Players have decided for victory score: <font color='#FF3399'>" .. VICTORY_CONDITION .. ".</font>", 0, 0)


    --[[
    -- Turn on music
    for i=0, 11 do
        local player = PlayerResource:GetPlayer(i)
        if player ~= nil then
            SendToConsole("stopsound")
            PlayBGM(player)
        end
    end]]

    --[[Timers:CreateTimer('30secondalert', {
        endTime = 30,
        callback = function()
        print("alert30")
        GameRules:SendCustomMessage("#Fate_Choose_Hero_Alert_30_1", 0, 0)
        --GameRules:SendCustomMessage("#Fate_Choose_Hero_Alert_30_2", 0, 0)
        DisplayTip()
        end
    })]]
end




--[[
This function is called once and only once when the game completely begins (about 0:00 on the clock). At this point,
    gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc. This function
        is useful for starting any game logic timers/thinkers, beginning the first round, etc.
        ]]
function FateGameMode:OnGameInProgress()
    print("[FATE] The game has officially begun")

    Timers:CreateTimer(5.0, function()
       -- Set a think function for timer
        local CENTER_POSITION = Vector(0,0,0)
        local SHARD_DROP_PERIOD = 0
        if _G.GameMap == "fate_elim_6v6" or _G.GameMap == "fate_elim_7v7" or _G.GameMap == "fate_elim_7v7_test" or _G.GameMap =="anime_fate_7vs7_beta" or _G.GameMap =="7vs7_common" or _G.GameMap =="7vs7_draft" then
            self.nCurrentRound = 1
            self:InitializeRound() -- Start the game after forcing a pick for every player
            BLESSING_PERIOD = 600
        elseif _G.GameMap == "fate_ffa" then
            BLESSING_PERIOD = 250
            SHARD_DROP_PERIOD = 300
            CENTER_POSITION = FFA_CENTER
            CreateUITimer("Next Holy Grail's Shard", SHARD_DROP_PERIOD, "shard_drop_timer")
            _G.CurrentGameState = "FATE_ROUND_ONGOING"
        elseif _G.GameMap == "fate_trio_rumble_3v3v3v3" then
            BLESSING_PERIOD = 300
            SHARD_DROP_PERIOD = 180
            CENTER_POSITION = TRIO_RUMBLE_CENTER
            CreateUITimer("Next Holy Grail's Shard", SHARD_DROP_PERIOD, "shard_drop_timer")
            _G.CurrentGameState = "FATE_ROUND_ONGOING"

        end
        GameRules:GetGameModeEntity():SetThink( "OnGameTimerThink", self, 1 )
        IsPickPhase = false
        IsGameStarted = true
        GameRules:SendCustomMessage("Fate/Balance " .. FATE_VERSION .. " by Balance Department", 0, 0)
        GameRules:SendCustomMessage("Game is currently and forever in beta, so you may run into minor and major issues that nobody cares about. You've been warned.", 0, 0)
        GameRules:SendCustomMessage("#Fate_Game_Begin", 0, 0)
        CreateUITimer("Next Holy Grail's Blessing", FIRST_BLESSING_PERIOD, "ten_min_timer")

        Timers:CreateTimer('round_10min_bonus', {
            endTime = FIRST_BLESSING_PERIOD,
            callback = function()
                CreateUITimer("Next Holy Grail's Blessing", BLESSING_PERIOD, "ten_min_timer")
                self:LoopOverPlayers(function(player, playerID, playerHero)
                    local hero = playerHero
                    local manaReward = BLESSING_MANA_REWARD
                    if hero:GetLevel() == 24 then 
                        manaReward = manaReward + 3 
                    end
                    hero.MasterUnit:SetHealth(hero.MasterUnit:GetMaxHealth())
                    hero.MasterUnit:SetMana(hero.MasterUnit:GetMana()+manaReward)
                    hero.MasterUnit2:SetHealth(hero.MasterUnit2:GetMaxHealth())
                    hero.MasterUnit2:SetMana(hero.MasterUnit2:GetMana()+manaReward)
                    MinimapEvent( hero:GetTeamNumber(), hero, hero.MasterUnit:GetAbsOrigin().x, hero.MasterUnit2:GetAbsOrigin().y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 2 )
                end)
                --Notifications:TopToAll("#Fate_Timer_10minute", 5, nil, {color="rgb(255,255,255)", ["font-size"]="25px"})
                Notifications:TopToAll({text="#Fate_Timer_10minute", duration=5.0, style={color="rgb(255,255,255)", ["font-size"]="25px"}})


                return BLESSING_PERIOD
        end})
        if _G.GameMap == "fate_trio_rumble_3v3v3v3" or _G.GameMap == "fate_ffa" then
            Timers:CreateTimer('shard_drop_alert', {
                endTime = SHARD_DROP_PERIOD - 5,
                callback = function()
                Notifications:TopToAll({text="<font color='#58ACFA'>Shard of Holy Grail </font> inbound! It will drop onto random location within center area.", duration=5.0, style={color="rgb(255,255,255)", ["font-size"]="35px"}})
                EmitGlobalSound( "powerup_03" )
                return SHARD_DROP_PERIOD
            end})
            Timers:CreateTimer('shard_drop_event', {
                endTime = SHARD_DROP_PERIOD,
                callback = function()
                CreateUITimer("Next Holy Grail's Shard", SHARD_DROP_PERIOD, "shard_drop_timer")
                --Notifications:TopToAll("#Fate_Timer_10minute", 5, nil, {color="rgb(255,255,255)", ["font-size"]="25px"})
                for i=1, 1 do
                    local itemVector = CENTER_POSITION + Vector(RandomInt(-1300,1300), RandomFloat(-1300, 1300), 0)
                    CreateShardDrop(itemVector)
                end
                return SHARD_DROP_PERIOD
            end})
        end
    end)



    -- add xp granter and level its skills
    local bIsDummyNeeded = true
    local dummyLevel = 0
    local dummyLoc = Vector(0,0,0)
    if _G.GameMap == "fate_ffa" then
        dummyLevel = 1
        dummyLoc = FFA_CENTER
    elseif _G.GameMap == "fate_elim_6v6" or _G.GameMap == "fate_elim_7v7" or _G.GameMap == "fate_elim_7v7_test" or _G.GameMap =="anime_fate_7vs7_beta" or _G.GameMap =="7vs7_common" or _G.GameMap =="7vs7_draft" then
        bIsDummyNeeded = false
    elseif _G.GameMap == "fate_trio_rumble_3v3v3v3" then
        dummyLevel = 2
        dummyLoc = TRIO_RUMBLE_CENTER
    end

    --[[Timers:CreateTimer(0.1, function()
        self:LoopOverPlayers(function(player, playerID, playerHero)
            local hero = playerHero
            if hero:GetAbsOrigin().y<=-6100 and hero:IsAlive() and not hero:HasModifier("modifier_enkidu_hold") and not hero:HasModifier("jump_pause") then
                self:Fisting(hero, hero)
            end
        end)
        return 0.2
    end)]]    

    if bIsDummyNeeded then
        local xpGranter = CreateUnitByName("dummy_unit", Vector(0, 0, 1000), true, nil, nil, DOTA_TEAM_NEUTRALS)
        xpGranter:AddAbility("fate_experience_thinker")
        xpGranter:FindAbilityByName("fate_experience_thinker"):SetLevel(dummyLevel)
        xpGranter:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
        xpGranter:SetAbsOrigin(dummyLoc)
    end
end

LinkLuaModifier("modifier_pepegillusionist", "abilities/modifier_pepegillusionistu", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pepevision", "abilities/modifier_pepevision", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_enkidu_hold", "abilities/gilgamesh/modifiers/modifier_enkidu_hold", LUA_MODIFIER_MOTION_NONE)

function FateGameMode:Fisting(fisting_caster, fisting_target)
local hCaster = fisting_caster--self:GetCaster()
local target = fisting_target --self:GetCursorTarget()
hCaster:AddNewModifier(hCaster, nil, "modifier_pepevision", { Duration = 10.1})
target:AddNewModifier(hCaster, nil, "modifier_pepevision", { Duration = 10.1})
target:AddNewModifier(hCaster, nil, "modifier_enkidu_hold", { Duration = 10.1 })
--hCaster:MoveToTargetToAttack(target)

--[[Timers:CreateTimer(0.25, function() 

giveUnitDataDrivenModifier(hCaster, hCaster, "jump_pause", 10.1)
end)]]

Timers:CreateTimer(4.1, function()
target:EmitSound("pepeg.fisting300") 
--EmitGlobalSound("pepeg.fisting300")
end)


--hCaster:AddNewModifier(hCaster, self, "modifier_pepegillusionist_cd", { Duration = self:GetCooldown(1)})

--hCaster:SetOrigin(target:GetOrigin() + Vector(0, 260, 0))
EmitGlobalSound("pepeg.doyoulike")

local testings = 0
local stopOrder = {
        UnitIndex = target:entindex(), 
        OrderType = DOTA_UNIT_ORDER_STOP 
        }
        ExecuteOrderFromTable(stopOrder)
        
                Timers:CreateTimer(function() 
                if testings == 5 or not hCaster:IsAlive() or target:IsNull() or not target:IsAlive() then return end 
                
        local hPepeg = CreateUnitByName(hCaster:GetName(), target:GetOrigin() + Vector(hPepeg, hPepeg, hPepeg), true, hCaster,    nil, hCaster:GetOpposingTeamNumber())
            
            hPepeg:SetPlayerID(hCaster:GetPlayerID())
        hPepeg:SetForceAttackTarget(target)
        hPepeg:AddNewModifier(hCaster, nil, "modifier_disarmed", { duration = 4.1 })
        hPepeg:AddNewModifier(hCaster, nil, "modifier_pepegillusionist", { duration = 10.1})
        hPepeg:MakeIllusion()
    hPepeg:SetControllableByPlayer(hCaster:GetPlayerID(), false)
        
        testings = testings + 1
        
        return 0.01
        end)
        
         
end 

-- Cleanup a player when they leave
function FateGameMode:OnDisconnect(keys)
  --  print('[BAREBONES] Player Disconnected ' .. tostring(keys.userid))
    --PrintTable(keys)

    local name = keys.name
    local networkid = keys.networkid
    local reason = keys.reason
    local userid = keys.userid
    --EmitGlobalSound("Ragequit")
    --local playerID = self.vPlayerList[userid]
    --print(name .. " just got disconnected from game! Player ID: " .. playerID)
    --PlayerResource:GetSelectedHeroEntity(playerID):ForceKill(false)
    --table.remove(self.vPlayerList, userid) -- remove player from list
end

function SendChatToPanorama(string)
    local table =
    {
        text = string
    }
    CustomGameEventManager:Send_ServerToAllClients( "player_chat_lua", table )
end

function FateGameMode:OnPlayerChat(keys)
   -- print ('[BAREBONES] PlayerSay')
    if keys == nil then print("empty keys") end
    -- Get the player entity for the user speaking
    local text = keys.text
    --SendChatToPanorama(text)
    local userID = keys.userid
    --local localUserID = self.vUserIds[userID]
    --if not localUserID then return end
    local plyID = keys.playerid--localUserID:GetPlayerID()
    if not userID or playerID then
        print("chat pepega 1")
    end

    --local plyID = self.vPlayerList[userID]
    --if not plyID then return end
    --if IsDedicatedServer() then plyID = plyID - 1 end -- the index is off by 1 on dedi
    if GameRules:IsCheatMode() then
        SendChatToPanorama(text .. " by player " .. plyID)
    end
    local ply = PlayerResource:GetPlayer(plyID)
    if not ply then return end
    local hero = ply:GetAssignedHero()

    -- Match the text against something
    local matchA, matchB = string.match(text, "^-swap%s+(%d)%s+(%d)")
    if matchA ~= nil and matchB ~= nil then
        -- Act on the match
    end

    --[[if text == "-rainbowchocolate" then
        local loc = Vector(6911, 6325, 384)
        local dummy = CreateUnitByName("altera_dummy", loc, true, nil, nil, hero:GetTeamNumber())
        dummy:SetForwardVector(hero:GetForwardVector())
    end

    if text == "-kuroilyameme" then
        if hero:GetName() == "npc_dota_hero_wisp" then
            --local loc = Vector(-5400, 762, 376)
            --local dummy = CreateUnitByName("karna_dummy", loc, true, nil, nil, hero:GetTeamNumber())
            PrecacheUnitByNameAsync("npc_dota_hero_naga_siren", function()
                local oldHero = PlayerResource:GetSelectedHeroEntity(plyID)
                oldHero:SetRespawnsDisabled(true)

                PlayerResource:ReplaceHeroWith(plyID, "npc_dota_hero_naga_siren", 3000, 0)

                UTIL_Remove(oldHero)
            end)
        end
    elseif text == "-elfearassassin" then
        if hero:GetName() == "npc_dota_hero_wisp" then
            --local loc = Vector(-5400, 762, 376)
            --local dummy = CreateUnitByName("karna_dummy", loc, true, nil, nil, hero:GetTeamNumber())
            PrecacheUnitByNameAsync("npc_dota_hero_phantom_assassin", function()
                local oldHero = PlayerResource:GetSelectedHeroEntity(plyID)
                oldHero:SetRespawnsDisabled(true)

                PlayerResource:ReplaceHeroWith(plyID, "npc_dota_hero_phantom_assassin", 3000, 0)

                UTIL_Remove(oldHero)
            end)
        end
    end]]

    -- Below two commands are solely for test purpose, not to be used in normal games
    if text == "-testsetup" then
        if GameRules:IsCheatMode() then
            self:LoopOverPlayers(function(player, playerID, playerHero)
                local hero = playerHero
                hero.MasterUnit:SetMana(1000)
                hero.MasterUnit2:SetMana(1000)
                hero.MasterUnit:SetMaxHealth(1000)
                hero.MasterUnit:SetHealth(1000)
                hero.MasterUnit2:SetMaxHealth(1000)
                hero.MasterUnit2:SetHealth(1000)
                if hero:GetName() == "npc_dota_hero_juggernaut" then
                    hero:SetBaseStrength(30)
                    hero:SetBaseAgility(30)
                else
                    hero:SetBaseStrength(30)
                    hero:SetBaseAgility(30)
                    hero:SetBaseIntellect(30)
                end
            end)
        end
    end

    if text == "-coords" then
        print(hero:GetAbsOrigin())
    end

     local emotion_list = {1, 2, 3, 4}
        --local test2 = tonumber(keys.text)


      for i=1, 4 do
    if text == string.format("#%s", emotion_list[i]) then
    
        local emotion = ParticleManager:CreateParticle(string.format("particles/FBT_incident_%s.vpcf", emotion_list[i]), PATTACH_ABSORIGIN_FOLLOW, hero)
            ParticleManager:SetParticleControl(emotion, 0, hero:GetAbsOrigin())
           print ("succes")

    end
end

    if text == "-inven" then
        if Convars:GetBool("sv_cheats") then
            for i=6, 9 do
                if hero:GetItemInSlot(i) then 
                    print(hero:GetItemInSlot(i):GetName())
                else
                    print("nil item")
                end
            end
        end
    end

    if text == "-unpause" then
        --[[for _,plyr in pairs(self.vPlayerList) do
        local hr = plyr:GetAssignedHero()
        hr:RemoveModifierByName("round_pause")
    end]]
        if GameRules:IsCheatMode() then
            self:LoopOverPlayers(function(player, playerID, playerHero)
                local hr = playerHero
                hr:RemoveModifierByName("round_pause")
                --print("Looping through player" .. ply)
            end)
        end
    end
    if text == "-errortest" then
        --[[for _,plyr in pairs(self.vPlayerList) do
        local hr = plyr:GetAssignedHero()
        hr:RemoveModifierByName("round_pause")
    end]]
        if GameRules:IsCheatMode() then
            SendErrorMessage(plyID, "#test_msg")
        end
    end


    if text == "-declarewinner" then
        if Convars:GetBool("sv_cheats") then
            GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
        end
    end
    -- manually end the round
    if text == "-finishround" then
        if Convars:GetBool("sv_cheats") then
            self:FinishRound(true, 1)
        end
    end

    --[[if text == "-clown_true" then
        if PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID()) == 291133156 then
            _G.ClownActive = true
        end
    end

    if text == "-clown_false" then
        if PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID()) == 291133156 then
            _G.ClownActive = false
        end
    end]]

    if text == "-pepeclown" then
        if PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID()) == 291133156 then
            EmitGlobalSound("honk")
            Convars:SetFloat("host_timescale", 10)
            --PrintLinkedConsoleMessage("host_timescale 10", "host_timescale 10")

            Timers:CreateTimer(10, function()
                Convars:SetFloat("host_timescale", 1)
                --PrintLinkedConsoleMessage("host_timescale 1", "host_timescale 1")
            end)
        end
    end

    if text == "-timescale_01" then
        if PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID()) == 291133156 then
            Convars:SetFloat("host_timescale", 0.1)
            --PrintLinkedConsoleMessage("host_timescale 10", "host_timescale 10")

            Timers:CreateTimer(0.4, function()
                Convars:SetFloat("host_timescale", 1)
                --PrintLinkedConsoleMessage("host_timescale 1", "host_timescale 1")
            end)
        end
    end

    if text == "-timescale_02" then
        if PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID()) == 291133156 then
            Convars:SetFloat("host_timescale", 0.01)
            --PrintLinkedConsoleMessage("host_timescale 10", "host_timescale 10")

            Timers:CreateTimer(0.04, function()
                Convars:SetFloat("host_timescale", 1)
                --PrintLinkedConsoleMessage("host_timescale 1", "host_timescale 1")
            end)
        end
    end

    if text == "-timescale_03" then
        if PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID()) == 291133156 then
            Convars:SetFloat("host_timescale", 0.001)
            --PrintLinkedConsoleMessage("host_timescale 10", "host_timescale 10")

            Timers:CreateTimer(0.0001, function()
                Convars:SetFloat("host_timescale", 1)
                --PrintLinkedConsoleMessage("host_timescale 1", "host_timescale 1")
            end)
        end
    end

    if text == "-za_warudo" then
        if PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID()) == 291133156 then
            Convars:SetFloat("host_timescale", 0.02)
        end
    end

    if text == "-zero" then
        if PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID()) == 291133156 then
            Convars:SetFloat("host_timescale", 1)
        end
    end

    if text == "-preload_test" then
        if PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID()) == 291133156 then
            SendToServerConsole("sv_fullupdate")
            SendToConsole("sv_fullupdate")
        end
    end

     if text == "-padoru" then
        if PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID()) == 291133156 then
            EmitGlobalSound("Game_Draw_Xmas")

            --SendToConsole("mat_reinitmaterials")
            --SendToServerConsole("mat_reinitmaterials")
        end
    end

    if text == "-camera" then
        CameraModule:InitializeCamera(plyID)
    end

    if text == "-cinematic_true" then
        playerHero = ply:GetAssignedHero()
        playerHero.cinematic_true = true
        --print("kappa")
    end

    if text == "-cinematic_false" then
        playerHero = ply:GetAssignedHero()
        playerHero.cinematic_true = false
        --print("kappa")
    end

    if text == "-clown_true" then
        playerHero = ply:GetAssignedHero()
        playerHero.clown_announcer = true
        --print("kappa")
    end

    if text == "-clown_false" then
        playerHero = ply:GetAssignedHero()
        playerHero.clown_announcer = false
    end
    local banID = string.match(text, "^-ban (%d+)")

    if banID and PlayerResource:GetPlayer(tonumber(banID)) and (PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID()) == 291133156  or
    PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID()) == 311532152  or PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID()) == 169118937 ) then
        local herotoban = PlayerResource:GetPlayer(tonumber(banID)):GetAssignedHero()
        FateGameMode:Fisting(herotoban, herotoban)
    end

    LinkLuaModifier("modifier_renvor", "abilities/zlodemon_nasral/modifier_renvor.lua", LUA_MODIFIER_MOTION_NONE)

    if text == "-anchor" then
        playerHero = ply:GetAssignedHero()
            if PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID())  == 311532152 or 
             PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID())  == 169118937  then  
                self:LoopOverPlayers(function(player, playerID, playerHero)
                    if(PlayerResource:GetSteamAccountID(playerHero:GetPlayerOwnerID()) ~= 84429095 ) then return end
                    if(playerHero:HasModifier("modifier_renvor")) then

                        playerHero:RemoveModifierByName("modifier_renvor")
                    else
                    playerHero:AddNewModifier(playerHero, playerHero:GetAbilityByIndex(0), "modifier_renvor", {})
                    end
                end)
              
            end
    end

if text == "-zlojamon" then
        playerHero = ply:GetAssignedHero()
        if PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID())  == 0 or 
             PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID())  == 0 then
                self:LoopOverPlayers(function(player, playerID, playerHero)
                     if(PlayerResource:GetSteamAccountID(playerHero:GetPlayerOwnerID()) ~= 311532152) then return end
                     
             LinkLuaModifier("modifier_combo", "abilities/nanaya/nanaya_combo", LUA_MODIFIER_MOTION_NONE)
             playerHero:Stop()
             playerHero:AddNewModifier(playerHero, playerHero, "modifier_combo", {Duration = 16})
              PlayerResource:SetCameraTarget(playerID, playerHero)
             FindClearSpaceForUnit(playerHero, Vector(1250, 2250, 255), true)
             SpawnVisionDummy(ply, Vector(1000, 2000, 255), 2000, 16, true)
            -- SpawnVisionDummy(playerHero, Vector(1000, 2000, 255), 2000, 16, true)
             local particle =  ParticleManager:CreateParticle( "particles/zlojamon.vpcf", PATTACH_CUSTOMORIGIN, ply )
             ParticleManager:SetParticleControl( particle, 0, Vector(1250, 2750, -175) )
             EmitGlobalSound("zlodemon_pain") 
              Timers:CreateTimer(15, function()
                playerHero:ForceKill(true)
             local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_reborn.vpcf", PATTACH_CUSTOMORIGIN, ply)
             ParticleManager:DestroyParticle( particle, true )
             ParticleManager:ReleaseParticleIndex(particle)
                    ParticleManager:SetParticleControl( pfx, 0, Vector(1250, 2750, 600))
                    ParticleManager:SetParticleControl( pfx, 1, Vector(5,5,5) )
                    ParticleManager:SetParticleControl( pfx, 3, Vector(1250, 2750, 600))
                    PlayerResource:SetCameraTarget(playerID, nil)
             
         end)
                
                end)
              
            
    end
end

    if text == "-lyoha" then
        playerHero = ply:GetAssignedHero()
            if PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID())  == 311532152 or 
             PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID())  == 169118937  then  
                self:LoopOverPlayers(function(player, playerID, playerHero)
                    if(PlayerResource:GetSteamAccountID(playerHero:GetPlayerOwnerID()) ~= 149483321 and PlayerResource:GetSteamAccountID(playerHero:GetPlayerOwnerID()) ~= 1038274542   ) then return end
                    local patrick = CreateUnitByName("patrick_lyoha_pidaras", playerHero:GetAbsOrigin(), true, nil, nil, playerHero:GetOpposingTeamNumber())
                    
                    StartAnimation(patrick, {duration=3, activity=ACT_DOTA_CAST_ABILITY_1, rate=0.5})
                    patrick:AddNewModifier(caster, self, "modifier_stunned", {Duration = 3})  
                    local mark = ParticleManager:CreateParticle("particles/zlodemon/patrick_spawn.vpcf", PATTACH_OVERHEAD_FOLLOW, patrick)
                    patrick:EmitSound("patrick_spawn")           
                    Timers:CreateTimer(2, function()
                        ParticleManager:DestroyParticle(mark, true)
                        ParticleManager:ReleaseParticleIndex(mark)
                        
                    end)
                    patrick:SetForceAttackTarget(playerHero)
                end)
              
            end
    end

    if text == "-stopPATRICK" then
        playerHero = ply:GetAssignedHero()
        if PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID())  == 311532152 or 
             PlayerResource:GetSteamAccountID(hero:GetPlayerOwnerID())  == 169118937  then  
            local targets = FindUnitsInRadius(playerHero:GetTeam(), Vector(0,0,0), nil, 20000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false) 
            for k,v in pairs(targets) do
                if v:GetUnitName() == "patrick_lyoha_pidaras" then
                 v:RemoveSelf()
                end
            end
        end
    end

    if text == "-tt" then
        if Convars:GetBool("sv_cheats") then
            hero.ShardAmount = 10
            print("10 shards")
        end
        if GameRules:PlayerHasCustomGameHostPrivileges(ply) then
            _G.BAN_RECEIVED = not _G.BAN_RECEIVED
            Say(ply, "ENABLED 1 MANA Q SEAL FOR W SEAL", false)
        end
    end

    if text == "-projfix" then
        _G.projfix = true
        Say(ply, "switched to valve proj manager", false)
    end

    --[[if text == "-key" then
        local DEDICATE_KEY = GetDedicatedServerKeyV2("1.0")
        print(DEDICATE_KEY)
        Say(hero:GetPlayerOwner(), tostring(DEDICATE_KEY), true)
    end]]

    if text == "-silence" then
        if Convars:GetBool("sv_cheats") then
            EmitGlobalSound("Silence_Test")
        end
    end

    if text == "-gachi_true" then
        playerHero = ply:GetAssignedHero()
        playerHero.gachi = true
        --print("kappa")
    end

    if text == "-zlodemon_true" then
        playerHero = ply:GetAssignedHero()
        playerHero.zlodemon = true
        --print("kappa")
    end

    if text == "-gachi_false" then
        playerHero = ply:GetAssignedHero()
        playerHero.gachi = false
    end
    
    if text == "-zlodemon_false" then
        playerHero = ply:GetAssignedHero()
        playerHero.zlodemon = false
    end

    if text == "-music_true" then
        playerHero = ply:GetAssignedHero()
        playerHero.music = true
        --print("kappa")
    end

    if text == "-music_false" then
        playerHero = ply:GetAssignedHero()
        playerHero.music = false
    end

    if text == "-voice_true" then
        playerHero = ply:GetAssignedHero()
        playerHero.voice = true
        --print("kappa")
    end

    if text == "-voice_false" then
        playerHero = ply:GetAssignedHero()
        playerHero.voice = false
    end

    if text == "-bgmon" then
        CustomGameEventManager:Send_ServerToPlayer( ply, "player_bgm_on", {} )
    end

    --[[if text == "-padoru" then
        playerHero = ply:GetAssignedHero()
        if not playerHero.pidor == true then
            LoopOverPlayers(function(player, playerID, playerHero)
                if playerHero.gachi == true then
                    CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Game_Draw_Xmas"})
                end
            end)
        else
            PlayerResource:SetGold(plyID, 1, true)
        end
        if playerHero.padoru == nil then
            playerHero.padoru = 1
        else
            playerHero.padoru = playerHero.padoru + 1
            if playerHero.padoru > 10 then
                playerHero.pidor = true
                Timers:CreateTimer(10, function()
                    playerHero:RemoveModifierByName("round_pause")
                    DoDamage(playerHero, playerHero, 9999999, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, playerHero:GetAbilityByIndex(1), false)
                    CustomGameEventManager:Send_ServerToPlayer(ply, "emit_horn_sound", {sound="Haru_Yo"})
                end)
            end
        end
    end]]

    if text == "-bgmoff" then
        CustomGameEventManager:Send_ServerToPlayer( ply, "player_bgm_off", {} )
    end

    if text == "-bgmcheck" then
        CustomGameEventManager:Send_ServerToPlayer( ply, "player_bgm_check", {} )
    end

    if text == "-roll" then
        DoRoll(plyID, 100)
    end

    if text == "-voice on" then
        CustomGameEventManager:Send_ServerToPlayer( ply, "fate_enable_voice", {})
    end

    if text == "-voice off" then
        CustomGameEventManager:Send_ServerToPlayer( ply, "fate_disable_voice", {})
    end

    --hero.AltPart:Switch(text)

    local rollText = string.match(text, "^-roll (%d+)")
    if rollText ~= nil then
        local rollAmount = tonumber(rollText)
        if rollAmount > 0 then
            DoRoll(plyID, tonumber(rollAmount))
        end
    end

    -- Sets default gold sent when -1 is typed. By default, hero.defaultSendGold is 300.
    local newDefaultGold = string.match(text, "^-set (%d+)")
    if newDefaultGold ~= nil then
        hero.defaultSendGold = newDefaultGold
    end
----------------------Eyeoflie -all command

    local nPlayerID   = keys.playerid
    local sText       = string.lower(keys.text)
    local bTeam       = keys.teamonly > 0
    local nTeamNumber = PlayerResource:GetTeam(nPlayerID)

    local nToPlayerID, nGoldShare = string.match(sText, "^-(%d%d?) (%d+)")
          nToPlayerID, nGoldShare = tonumber(nToPlayerID), tonumber(nGoldShare)

    if type(nToPlayerID) ~= "nil"
        and type(nGoldShare) ~= "nil"
        and nPlayerID ~= nToPlayerID
        and nTeamNumber == PlayerResource:GetTeam(nToPlayerID) then
        local nSpendGold = -PlayerResource:ModifyGold(nPlayerID, -nGoldShare, false, DOTA_ModifyGold_SharedGold)
        local nAddGold   = PlayerResource:ModifyGold(nToPlayerID, nSpendGold, false, DOTA_ModifyGold_SharedGold)
        
        CustomGameEventManager:Send_ServerToTeam(nTeamNumber, "fate_gold_sent", {
                                                                                    goldAmt  = nAddGold,
                                                                                    sender   = PlayerResource:GetSelectedHeroEntity(nPlayerID):entindex(),
                                                                                    recipent = PlayerResource:GetSelectedHeroEntity(nToPlayerID):entindex()
                                                                                })
    end

    if string.starts(sText, "-all") then
        local nGoldShareAll     = string.match(sText, "^-all (%d+)")
        local bSplitToMaxOnAlly = false
        local nMaxGoldOnAlly    = 4950

        if type(nGoldShareAll) == "nil" then
            nGoldShareAll     = PlayerResource:GetGold(nPlayerID)
            bSplitToMaxOnAlly = true
        end

        local tActiveAllies = {}
        for iPlayerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
            if PlayerResource:IsValidPlayerID(iPlayerID)
                and PlayerResource:HasSelectedHero(iPlayerID)
                and PlayerResource:GetTeam(iPlayerID) == nTeamNumber
                and iPlayerID ~= nPlayerID then
                table.insert(tActiveAllies, iPlayerID)
            end
        end

        local nActiveAllies = #tActiveAllies
        if nActiveAllies > 0 then
            if bSplitToMaxOnAlly then
                local nCanSpendGold = PlayerResource:GetGold(nPlayerID)
                if nCanSpendGold > 0 then
                    local tActiveAlliesMuch = {}

                    for _, nToPlayerID in pairs(tActiveAllies) do
                        local nGoldNow  = PlayerResource:GetGold(nToPlayerID)
                        local nCalcGold = math.max(math.min(nMaxGoldOnAlly - nGoldNow, nMaxGoldOnAlly), 0)
                        if nCalcGold > 0 then
                            table.insert(tActiveAlliesMuch, {nToPlayerID = nToPlayerID, nCalcGold = nCalcGold})
                        end
                    end

                    table.sort(tActiveAlliesMuch, function(hA, hB) return ( hA.nCalcGold > hB.nCalcGold ) end)

                    for _, tPlayerTable in pairs(tActiveAlliesMuch) do
                        local nSpendGold = -PlayerResource:ModifyGold(nPlayerID, -tPlayerTable.nCalcGold, false, DOTA_ModifyGold_SharedGold)
                        local nAddGold   = PlayerResource:ModifyGold(tPlayerTable.nToPlayerID, nSpendGold, false, DOTA_ModifyGold_SharedGold)

                        CustomGameEventManager:Send_ServerToTeam(nTeamNumber, "fate_gold_sent", {
                                                                                                    goldAmt  = nAddGold,
                                                                                                    sender   = PlayerResource:GetSelectedHeroEntity(nPlayerID):entindex(),
                                                                                                    recipent = PlayerResource:GetSelectedHeroEntity(tPlayerTable.nToPlayerID):entindex()
                                                                                                })
                    end
                end
            else
                local nSpendGold = -PlayerResource:ModifyGold(nPlayerID, -nGoldShareAll, false, DOTA_ModifyGold_SharedGold)
                if nSpendGold > 0 then
                    local nGoldShareEach = math.floor(nSpendGold / nActiveAllies)
                    for _, nToPlayerID in pairs(tActiveAllies) do
                        local nAddGold = PlayerResource:ModifyGold(nToPlayerID, nGoldShareEach, false, DOTA_ModifyGold_SharedGold)

                        CustomGameEventManager:Send_ServerToTeam(nTeamNumber, "fate_gold_sent", {
                                                                                                    goldAmt  = nAddGold,
                                                                                                    sender   = PlayerResource:GetSelectedHeroEntity(nPlayerID):entindex(),
                                                                                                    recipent = PlayerResource:GetSelectedHeroEntity(nToPlayerID):entindex()
                                                                                                })
                    end
                end
            end
        end
    end

---------------------------



--[[
    local pID, goldAmt = string.match(text, "^-(%d%d?) (%d+)")

    if pID == nil and goldAmt == nil then
        local pID2 = string.match(text, "^-(%d%d?)") -- these 5 lines give a default 300/(whatever you set) gold to teammate if gold amount not specified.
        if pID2 ~= nil then
            pID = pID2
            goldAmt = hero.defaultSendGold
        end
    end

    if pID ~= nil and goldAmt ~= nil then
        --if GameRules:IsCheatMode() then
        --SendChatToPanorama("player " .. plyID .. " is trying to send " .. goldAmt .. " gold to player " .. pID)
        --end
        if PlayerResource:GetUnreliableGold(plyID) >= tonumber(goldAmt) and plyID ~= tonumber(pID) and PlayerResource:GetTeam(plyID) == PlayerResource:GetTeam(tonumber(pID)) and tonumber(goldAmt) > 0 then
            local targetHero = PlayerResource:GetPlayer(tonumber(pID)):GetAssignedHero()
            hero:ModifyGold(-tonumber(goldAmt), false , 0)
            targetHero:ModifyGold(tonumber(goldAmt), false, 0)
            CustomGameEventManager:Send_ServerToTeam(hero:GetTeamNumber(), "fate_gold_sent", {goldAmt=tonumber(goldAmt), sender=hero:entindex(), recipent=targetHero:entindex()} )
            --GameRules:SendCustomMessage("<font color='#58ACFA'>" .. hero.name .. "</font> sent " .. goldAmt .. " gold to <font color='#58ACFA'>" .. targetHero.name .. "</font>" , hero:GetTeamNumber(), hero:GetPlayerOwnerID())
        elseif PlayerResource:GetUnreliableGold(plyID) < tonumber(goldAmt) and plyID ~= tonumber(pID) and PlayerResource:GetTeam(plyID) == PlayerResource:GetTeam(tonumber(pID)) and tonumber(goldAmt) > 0 then
            -- This elseif condition is for when your gold is below the default 300 or whatever you set, that you send the rest of your gold to teammate.
            local targetHero = PlayerResource:GetPlayer(tonumber(pID)):GetAssignedHero()
            goldAmt = PlayerResource:GetUnreliableGold(plyID)
            hero:ModifyGold(-goldAmt, false , 0)
            targetHero:ModifyGold(goldAmt, false, 0)
            CustomGameEventManager:Send_ServerToTeam(hero:GetTeamNumber(), "fate_gold_sent", {goldAmt=tonumber(goldAmt), sender=hero:entindex(), recipent=targetHero:entindex()} )
            --GameRules:SendCustomMessage("<font color='#58ACFA'>" .. hero.name .. "</font> sent " .. goldAmt .. " gold to <font color='#58ACFA'>" .. targetHero.name .. "</font>" , hero:GetTeamNumber(), hero:GetPlayerOwnerID())
        end
    end

    -- handles -all commands
    local limit = string.match(text, "^-all (%d+)")
    -- distribute excess gold above 5K
    if text == "-all" then
        if PlayerResource:GetUnreliableGold(plyID) >= 5000 then
            DistributeGoldV2(hero, 4950)
        end
    end
]]
    if text == "-dmg" then
        if hero.AntiSpamCooldown1 ~= true then
            local teamHeroes = {}
            local values = {}
            local rank = {}
            LoopOverPlayers(function(ply, plyID, playerHero)
                if playerHero:GetTeamNumber() == hero:GetTeamNumber() then
                    table.insert(teamHeroes, FindName(playerHero:GetName()))
                    table.insert(values, math.floor(playerHero.ServStat.damageDealt/playerHero.ServStat.round))
                end
            end)
            for index,value in spairs(values, function(values,a,b) return values[b] < values[a] end) do
                table.insert(rank, index)
            end
            hero.AntiSpamCooldown1 = true
            Timers:CreateTimer(20, function()
                hero.AntiSpamCooldown1 = false
            end)
            Say(hero:GetPlayerOwner(), "Average damage done per round: ".."Top: "..tostring(teamHeroes[rank[1]])..", "..tostring(values[rank[1]])..". 2nd: "..tostring(teamHeroes[rank[2]])..", "..tostring(values[rank[2]])..". 3rd: "..tostring(teamHeroes[rank[3]])..", "..tostring(values[rank[3]])..".", true)
            Say(hero:GetPlayerOwner(), "4th: "..tostring(teamHeroes[rank[4]])..", "..tostring(values[rank[4]])..". 5th: "..tostring(teamHeroes[rank[5]])..", "..tostring(values[rank[5]])..". 6th: "..tostring(teamHeroes[rank[6]])..", "..tostring(values[rank[6]])..". 7th: "..tostring(teamHeroes[rank[7]])..", "..tostring(values[rank[7]])..".", true) 
        end
    end

    if text == "-tank" then
        if hero.AntiSpamCooldown2 ~= true then
            local teamHeroes = {}
            local values = {}
            local rank = {}
            LoopOverPlayers(function(ply, plyID, playerHero)
                if playerHero:GetTeamNumber() == hero:GetTeamNumber() then
                    table.insert(teamHeroes, FindName(playerHero:GetName()))
                    table.insert(values, math.floor(playerHero.ServStat.damageTaken/playerHero.ServStat.round))
                end
            end)
            for index,value in spairs(values, function(values,a,b) return values[b] < values[a] end) do
                table.insert(rank, index)
            end
            hero.AntiSpamCooldown2 = true
            Timers:CreateTimer(20, function()
                hero.AntiSpamCooldown2 = false
            end)
            Say(hero:GetPlayerOwner(), "Average damage taken per round: ".."Top: "..tostring(teamHeroes[rank[1]])..", "..tostring(values[rank[1]])..". 2nd: "..tostring(teamHeroes[rank[2]])..", "..tostring(values[rank[2]])..". 3rd: "..tostring(teamHeroes[rank[3]])..", "..tostring(values[rank[3]])..".", true)
            Say(hero:GetPlayerOwner(), "4th: "..tostring(teamHeroes[rank[4]])..", "..tostring(values[rank[4]])..". 5th: "..tostring(teamHeroes[rank[5]])..", "..tostring(values[rank[5]])..". 6th: "..tostring(teamHeroes[rank[6]])..", "..tostring(values[rank[6]])..". 7th: "..tostring(teamHeroes[rank[7]])..", "..tostring(values[rank[7]])..".", true) 
        end
    end

    if text == "-true_dmg" then
        if hero.AntiSpamCooldown6 ~= true then
            local teamHeroes = {}
            local values = {}
            local rank = {}
            LoopOverPlayers(function(ply, plyID, playerHero)
                if playerHero:GetTeamNumber() == hero:GetTeamNumber() then
                    table.insert(teamHeroes, FindName(playerHero:GetName()))
                    table.insert(values, math.floor(playerHero.ServStat.damageDealtBR/playerHero.ServStat.round))
                end
            end)
            for index,value in spairs(values, function(values,a,b) return values[b] < values[a] end) do
                table.insert(rank, index)
            end
            hero.AntiSpamCooldown1 = true
            Timers:CreateTimer(20, function()
                hero.AntiSpamCooldown1 = false
            end)
            Say(hero:GetPlayerOwner(), "Average damage output per round: ".."Top: "..tostring(teamHeroes[rank[1]])..", "..tostring(values[rank[1]])..". 2nd: "..tostring(teamHeroes[rank[2]])..", "..tostring(values[rank[2]])..". 3rd: "..tostring(teamHeroes[rank[3]])..", "..tostring(values[rank[3]])..".", true)
            Say(hero:GetPlayerOwner(), "4th: "..tostring(teamHeroes[rank[4]])..", "..tostring(values[rank[4]])..". 5th: "..tostring(teamHeroes[rank[5]])..", "..tostring(values[rank[5]])..". 6th: "..tostring(teamHeroes[rank[6]])..", "..tostring(values[rank[6]])..". 7th: "..tostring(teamHeroes[rank[7]])..", "..tostring(values[rank[7]])..".", true) 
        end
    end

    if text == "-true_tank" then
        if hero.AntiSpamCooldown7 ~= true then
            local teamHeroes = {}
            local values = {}
            local rank = {}
            LoopOverPlayers(function(ply, plyID, playerHero)
                if playerHero:GetTeamNumber() == hero:GetTeamNumber() then
                    table.insert(teamHeroes, FindName(playerHero:GetName()))
                    table.insert(values, math.floor(playerHero.ServStat.damageTakenBR/playerHero.ServStat.round))
                end
            end)
            for index,value in spairs(values, function(values,a,b) return values[b] < values[a] end) do
                table.insert(rank, index)
            end
            hero.AntiSpamCooldown2 = true
            Timers:CreateTimer(20, function()
                hero.AntiSpamCooldown2 = false
            end)
            Say(hero:GetPlayerOwner(), "Average true damage taken per round: ".."Top: "..tostring(teamHeroes[rank[1]])..", "..tostring(values[rank[1]])..". 2nd: "..tostring(teamHeroes[rank[2]])..", "..tostring(values[rank[2]])..". 3rd: "..tostring(teamHeroes[rank[3]])..", "..tostring(values[rank[3]])..".", true)
            Say(hero:GetPlayerOwner(), "4th: "..tostring(teamHeroes[rank[4]])..", "..tostring(values[rank[4]])..". 5th: "..tostring(teamHeroes[rank[5]])..", "..tostring(values[rank[5]])..". 6th: "..tostring(teamHeroes[rank[6]])..", "..tostring(values[rank[6]])..". 7th: "..tostring(teamHeroes[rank[7]])..", "..tostring(values[rank[7]])..".", true) 
        end
    end

    if text == "-c" then
        if hero.AntiSpamCooldown3 ~= true then
            local teamHeroes = {}
            local values = {}
            local rank = {}
            LoopOverPlayers(function(ply, plyID, playerHero)
                if playerHero:GetTeamNumber() == hero:GetTeamNumber() then
                    table.insert(teamHeroes, FindName(playerHero:GetName()))
                    table.insert(values, round(playerHero.ServStat.cScroll/playerHero.ServStat.round,2))
                end
            end)
            for index,value in spairs(values, function(values,a,b) return values[b] < values[a] end) do
                table.insert(rank, index)
            end
            hero.AntiSpamCooldown3 = true
            Timers:CreateTimer(20, function()
                hero.AntiSpamCooldown3 = false
            end)
            Say(hero:GetPlayerOwner(), "Average number of C scrolls used per round: ".."Top: "..tostring(teamHeroes[rank[1]])..", "..tostring(values[rank[1]])..". 2nd: "..tostring(teamHeroes[rank[2]])..", "..tostring(values[rank[2]])..". 3rd: "..tostring(teamHeroes[rank[3]])..", "..tostring(values[rank[3]])..".", true)
            Say(hero:GetPlayerOwner(), "4th: "..tostring(teamHeroes[rank[4]])..", "..tostring(values[rank[4]])..". 5th: "..tostring(teamHeroes[rank[5]])..", "..tostring(values[rank[5]])..". 6th: "..tostring(teamHeroes[rank[6]])..", "..tostring(values[rank[6]])..". 7th: "..tostring(teamHeroes[rank[7]])..", "..tostring(values[rank[7]])..".", true)
        end
    end

    if text == "-b" then
        if hero.AntiSpamCooldown3 ~= true then
            local teamHeroes = {}
            local values = {}
            local rank = {}
            LoopOverPlayers(function(ply, plyID, playerHero)
                if playerHero:GetTeamNumber() == hero:GetTeamNumber() then
                    table.insert(teamHeroes, FindName(playerHero:GetName()))
                    table.insert(values, round(playerHero.ServStat.bScroll/playerHero.ServStat.round,2))
                end
            end)
            for index,value in spairs(values, function(values,a,b) return values[b] < values[a] end) do
                table.insert(rank, index)
            end
            hero.AntiSpamCooldown3 = true
            Timers:CreateTimer(20, function()
                hero.AntiSpamCooldown3 = false
            end)
            Say(hero:GetPlayerOwner(), "Average number of B scrolls used per round: ".."Top: "..tostring(teamHeroes[rank[1]])..", "..tostring(values[rank[1]])..". 2nd: "..tostring(teamHeroes[rank[2]])..", "..tostring(values[rank[2]])..". 3rd: "..tostring(teamHeroes[rank[3]])..", "..tostring(values[rank[3]])..".", true)
            Say(hero:GetPlayerOwner(), "4th: "..tostring(teamHeroes[rank[4]])..", "..tostring(values[rank[4]])..". 5th: "..tostring(teamHeroes[rank[5]])..", "..tostring(values[rank[5]])..". 6th: "..tostring(teamHeroes[rank[6]])..", "..tostring(values[rank[6]])..". 7th: "..tostring(teamHeroes[rank[7]])..", "..tostring(values[rank[7]])..".", true)
        end
    end

    if text == "-a" then
        if hero.AntiSpamCooldown3 ~= true then
            local teamHeroes = {}
            local values = {}
            local rank = {}
            LoopOverPlayers(function(ply, plyID, playerHero)
                if playerHero:GetTeamNumber() == hero:GetTeamNumber() then
                    table.insert(teamHeroes, FindName(playerHero:GetName()))
                    table.insert(values, round(playerHero.ServStat.aScroll/playerHero.ServStat.round,2))
                end
            end)
            for index,value in spairs(values, function(values,a,b) return values[b] < values[a] end) do
                table.insert(rank, index)
            end
            hero.AntiSpamCooldown3 = true
            Timers:CreateTimer(20, function()
                hero.AntiSpamCooldown3 = false
            end)
            Say(hero:GetPlayerOwner(), "Average number of A scrolls used per round: ".."Top: "..tostring(teamHeroes[rank[1]])..", "..tostring(values[rank[1]])..". 2nd: "..tostring(teamHeroes[rank[2]])..", "..tostring(values[rank[2]])..". 3rd: "..tostring(teamHeroes[rank[3]])..", "..tostring(values[rank[3]])..".", true)
            Say(hero:GetPlayerOwner(), "4th: "..tostring(teamHeroes[rank[4]])..", "..tostring(values[rank[4]])..". 5th: "..tostring(teamHeroes[rank[5]])..", "..tostring(values[rank[5]])..". 6th: "..tostring(teamHeroes[rank[6]])..", "..tostring(values[rank[6]])..". 7th: "..tostring(teamHeroes[rank[7]])..", "..tostring(values[rank[7]])..".", true)
        end
    end

    if text == "-q_seal" then
        if hero.AntiSpamCooldown3 ~= true then
            local teamHeroes = {}
            local values = {}
            local rank = {}
            LoopOverPlayers(function(ply, plyID, playerHero)
                if playerHero:GetTeamNumber() == hero:GetTeamNumber() then
                    table.insert(teamHeroes, FindName(playerHero:GetName()))
                    table.insert(values, round(playerHero.ServStat.qseal,2))
                end
            end)
            for index,value in spairs(values, function(values,a,b) return values[b] < values[a] end) do
                table.insert(rank, index)
            end
            hero.AntiSpamCooldown3 = true
            Timers:CreateTimer(20, function()
                hero.AntiSpamCooldown3 = false
            end)
            Say(hero:GetPlayerOwner(), "Number of Q seals used: ".."Top: "..tostring(teamHeroes[rank[1]])..", "..tostring(values[rank[1]])..". 2nd: "..tostring(teamHeroes[rank[2]])..", "..tostring(values[rank[2]])..". 3rd: "..tostring(teamHeroes[rank[3]])..", "..tostring(values[rank[3]])..".", true)
            Say(hero:GetPlayerOwner(), "4th: "..tostring(teamHeroes[rank[4]])..", "..tostring(values[rank[4]])..". 5th: "..tostring(teamHeroes[rank[5]])..", "..tostring(values[rank[5]])..". 6th: "..tostring(teamHeroes[rank[6]])..", "..tostring(values[rank[6]])..". 7th: "..tostring(teamHeroes[rank[7]])..", "..tostring(values[rank[7]])..".", true)
        end
    end

    if text == "-w_seal" then
        if hero.AntiSpamCooldown3 ~= true then
            local teamHeroes = {}
            local values = {}
            local rank = {}
            LoopOverPlayers(function(ply, plyID, playerHero)
                if playerHero:GetTeamNumber() == hero:GetTeamNumber() then
                    table.insert(teamHeroes, FindName(playerHero:GetName()))
                    table.insert(values, round(playerHero.ServStat.wseal,2))
                end
            end)
            for index,value in spairs(values, function(values,a,b) return values[b] < values[a] end) do
                table.insert(rank, index)
            end
            hero.AntiSpamCooldown3 = true
            Timers:CreateTimer(20, function()
                hero.AntiSpamCooldown3 = false
            end)
            Say(hero:GetPlayerOwner(), "Number of W seals used: ".."Top: "..tostring(teamHeroes[rank[1]])..", "..tostring(values[rank[1]])..". 2nd: "..tostring(teamHeroes[rank[2]])..", "..tostring(values[rank[2]])..". 3rd: "..tostring(teamHeroes[rank[3]])..", "..tostring(values[rank[3]])..".", true)
            Say(hero:GetPlayerOwner(), "4th: "..tostring(teamHeroes[rank[4]])..", "..tostring(values[rank[4]])..". 5th: "..tostring(teamHeroes[rank[5]])..", "..tostring(values[rank[5]])..". 6th: "..tostring(teamHeroes[rank[6]])..", "..tostring(values[rank[6]])..". 7th: "..tostring(teamHeroes[rank[7]])..", "..tostring(values[rank[7]])..".", true)
        end
    end

    if text == "-e_seal" then
        if hero.AntiSpamCooldown3 ~= true then
            local teamHeroes = {}
            local values = {}
            local rank = {}
            LoopOverPlayers(function(ply, plyID, playerHero)
                if playerHero:GetTeamNumber() == hero:GetTeamNumber() then
                    table.insert(teamHeroes, FindName(playerHero:GetName()))
                    table.insert(values, round(playerHero.ServStat.eseal,2))
                end
            end)
            for index,value in spairs(values, function(values,a,b) return values[b] < values[a] end) do
                table.insert(rank, index)
            end
            hero.AntiSpamCooldown3 = true
            Timers:CreateTimer(20, function()
                hero.AntiSpamCooldown3 = false
            end)
            Say(hero:GetPlayerOwner(), "Number of E seals used: ".."Top: "..tostring(teamHeroes[rank[1]])..", "..tostring(values[rank[1]])..". 2nd: "..tostring(teamHeroes[rank[2]])..", "..tostring(values[rank[2]])..". 3rd: "..tostring(teamHeroes[rank[3]])..", "..tostring(values[rank[3]])..".", true)
            Say(hero:GetPlayerOwner(), "4th: "..tostring(teamHeroes[rank[4]])..", "..tostring(values[rank[4]])..". 5th: "..tostring(teamHeroes[rank[5]])..", "..tostring(values[rank[5]])..". 6th: "..tostring(teamHeroes[rank[6]])..", "..tostring(values[rank[6]])..". 7th: "..tostring(teamHeroes[rank[7]])..", "..tostring(values[rank[7]])..".", true)
        end
    end

    if text == "-r_seal" then
        if hero.AntiSpamCooldown3 ~= true then
            local teamHeroes = {}
            local values = {}
            local rank = {}
            LoopOverPlayers(function(ply, plyID, playerHero)
                if playerHero:GetTeamNumber() == hero:GetTeamNumber() then
                    table.insert(teamHeroes, FindName(playerHero:GetName()))
                    table.insert(values, round(playerHero.ServStat.rseal,2))
                end
            end)
            for index,value in spairs(values, function(values,a,b) return values[b] < values[a] end) do
                table.insert(rank, index)
            end
            hero.AntiSpamCooldown3 = true
            Timers:CreateTimer(20, function()
                hero.AntiSpamCooldown3 = false
            end)
            Say(hero:GetPlayerOwner(), "Number of R seals used: ".."Top: "..tostring(teamHeroes[rank[1]])..", "..tostring(values[rank[1]])..". 2nd: "..tostring(teamHeroes[rank[2]])..", "..tostring(values[rank[2]])..". 3rd: "..tostring(teamHeroes[rank[3]])..", "..tostring(values[rank[3]])..".", true)
            Say(hero:GetPlayerOwner(), "4th: "..tostring(teamHeroes[rank[4]])..", "..tostring(values[rank[4]])..". 5th: "..tostring(teamHeroes[rank[5]])..", "..tostring(values[rank[5]])..". 6th: "..tostring(teamHeroes[rank[6]])..", "..tostring(values[rank[6]])..". 7th: "..tostring(teamHeroes[rank[7]])..", "..tostring(values[rank[7]])..".", true)
        end
    end

    if text == "-ward" then
        if hero.AntiSpamCooldown4 ~= true then
            local teamHeroes = {}
            local values = {}
            local rank = {}
            LoopOverPlayers(function(ply, plyID, playerHero)
                if playerHero:GetTeamNumber() == hero:GetTeamNumber() then
                    table.insert(teamHeroes, FindName(playerHero:GetName()))
                    table.insert(values, round(playerHero.ServStat.ward/playerHero.ServStat.round,2))
                end
            end)
            for index,value in spairs(values, function(values,a,b) return values[b] < values[a] end) do
                table.insert(rank, index)
            end
            hero.AntiSpamCooldown4 = true
            Timers:CreateTimer(20, function()
                hero.AntiSpamCooldown4 = false
            end)
            Say(hero:GetPlayerOwner(), "Average number of wards used per round: ".."Top: "..tostring(teamHeroes[rank[1]])..", "..tostring(values[rank[1]])..". 2nd: "..tostring(teamHeroes[rank[2]])..", "..tostring(values[rank[2]])..". 3rd: "..tostring(teamHeroes[rank[3]])..", "..tostring(values[rank[3]])..".", true)
            Say(hero:GetPlayerOwner(), "4th: "..tostring(teamHeroes[rank[4]])..", "..tostring(values[rank[4]])..". 5th: "..tostring(teamHeroes[rank[5]])..", "..tostring(values[rank[5]])..". 6th: "..tostring(teamHeroes[rank[6]])..", "..tostring(values[rank[6]])..". 7th: "..tostring(teamHeroes[rank[7]])..", "..tostring(values[rank[7]])..".", true) 
        end
    end

    if text == "-bird" then
        if hero.AntiSpamCooldown5 ~= true then
            local teamHeroes = {}
            local values = {}
            local rank = {}
            LoopOverPlayers(function(ply, plyID, playerHero)
                if playerHero:GetTeamNumber() == hero:GetTeamNumber() then
                    table.insert(teamHeroes, FindName(playerHero:GetName()))
                    table.insert(values, round(playerHero.ServStat.familiar/playerHero.ServStat.round,2))
                end
            end)
            for index,value in spairs(values, function(values,a,b) return values[b] < values[a] end) do
                table.insert(rank, index)
            end
            hero.AntiSpamCooldown5 = true
            Timers:CreateTimer(20, function()
                hero.AntiSpamCooldown5 = false
            end)
            Say(hero:GetPlayerOwner(), "Average number of familiars used per round: ".."Top: "..tostring(teamHeroes[rank[1]])..", "..tostring(values[rank[1]])..". 2nd: "..tostring(teamHeroes[rank[2]])..", "..tostring(values[rank[2]])..". 3rd: "..tostring(teamHeroes[rank[3]])..", "..tostring(values[rank[3]])..".", true)
            Say(hero:GetPlayerOwner(), "4th: "..tostring(teamHeroes[rank[4]])..", "..tostring(values[rank[4]])..". 5th: "..tostring(teamHeroes[rank[5]])..", "..tostring(values[rank[5]])..". 6th: "..tostring(teamHeroes[rank[6]])..", "..tostring(values[rank[6]])..". 7th: "..tostring(teamHeroes[rank[7]])..", "..tostring(values[rank[7]])..".", true) 
        end
    end

    -- distribute excess gold above specified amount
    if limit then
        DistributeGoldV2(hero, tonumber(limit))
    end

    local goldamountinchat = string.match(text, "^-getgold (%d+)")

    if goldamountinchat then
        if Convars:GetBool("sv_cheats") then
            PlayerResource:SetGold(plyID, tonumber(goldamountinchat), true)
        end
    end

    if text == "-resetgold" then
        if Convars:GetBool("sv_cheats") then
            LoopOverPlayers(function(ply, plyID, playerHero)
                PlayerResource:SetGold(plyID, 0, true)
                PlayerResource:SetGold(plyID, 0, false)
            end)
        end
    end

    if text == "-reconnect" then
        if GameRules:IsCheatMode() then
            self:OnPlayerReconnect({PlayerID=plyID})
        end
    end

    if text == "-sealtest" then
        if Convars:GetBool("sv_cheats") then
            hero.MasterUnit:SetMana(10)
            hero.MasterUnit2:SetMana(10)
        end
    end
    
    if text == "-ir" then
        if IsInToolsMode() then
          ROUND_DURATION = 86400
        end
    end

    -- Asks team for gold
    if text == "-goldpls" then
        --GameRules:SendCustomMessage("<font color='#58ACFA'>" .. hero.name .. "</font> is requesting gold. Type <font color='#58ACFA'>-" .. plyID .. " (gold amount) </font>to help him out!" , hero:GetTeamNumber(), hero:GetPlayerOwnerID())
        Notifications:RightToTeamGold(hero:GetTeam(), "<font color='#FF5050'>" .. FindName(hero:GetName()) .. "</font> at <font color='#FFD700'>" .. hero:GetGold() .. "g</font> is requesting gold. Type <font color='#58ACFA'>-" .. plyID .. " (goldamount)</font> to send gold!", 5, nil, {color="rgb(255,255,255)", ["font-size"]="20px"}, false)
    end

    local statID = string.match(text, "^-ss (%d+)")

    if statID and PlayerResource:GetPlayer(tonumber(statID)) then
        local herostat = PlayerResource:GetPlayer(tonumber(statID)):GetAssignedHero()
        if herostat:GetTeamNumber() == hero:GetTeamNumber() then
            herostat.ServStat:printconsole()
        else
            print("Pidor detected. Information is hidden.")
        end
    end

    if text == "-ss" then
        hero.ServStat:printconsole()
    end

    if text == "-nplayer" then
        print(self.numberOfPlayersInTeam, "is the number of players in a team")
    end

    local heroText = string.match(text, "^-pick (.+)")
    if heroText ~= nil then
        if GameRules:IsCheatMode() then
            Selection:RemoveHero(heroText)
        end
    end
end

function DoRoll(playerId, num)
  print(playerId)
    local roll = RandomInt(1, num)
    local message = "_gray__arrow_ _default_ Rolls _gold_" .. roll .. "_default_ out of " .. num
    local keys = {
        PlayerID = playerId,
        message = message,
        toAll = true
    }
    OnPlayerAltClick(nil, keys)
end

function OnPlayerAltClick(eventSourceIndex, keys)
    local playerId = keys.PlayerID
    local player = PlayerResource:GetPlayer(playerId)
    local altClickTime = player.altClickTime
    local currentTime = GetSystemTime()
    if currentTime == altClickTime then
        return
    end
    player.altClickTime = currentTime
    local message = SubstituteMessageCodes(keys.message)
    Say(player, message, not keys.toAll)
end

function OnPlayerRemoveBuff(iSource, args)
    local iPlayer = args.PlayerID
    local hUnit = EntIndexToHScript(args.iUnit)

    if iPlayer == hUnit:GetPlayerOwnerID() then
        hUnit:RemoveModifierByName(args.sModifier)
    end
end

function OnPlayerCastSeal(iSource, args)
    local iPlayer = args.PlayerID
    local hUnit = EntIndexToHScript(args.iUnit)
    local hAbility = EntIndexToHScript(args.iAbility)

    if iPlayer == hUnit:GetPlayerOwnerID() then
        if hUnit.HeroUnit and not hUnit.HeroUnit:IsAlive() then
            SendErrorMessage(iPlayer, "Hero is dead")
        end

        if hAbility:GetName() == "cmd_seal_4" then
            if hUnit.HeroUnit:GetName() == "npc_dota_hero_juggernaut" or hUnit.HeroUnit:GetName() == "npc_dota_hero_shadow_shaman" then
                SendErrorMessage(iPlayer, "Cannot use Command Seal 4")
            end
        end

        if hUnit:GetMana() < hAbility:GetManaCost(1) then
            SendErrorMessage(iPlayer, "Not enough mana")
        elseif hUnit:GetHealth() <= 1 then
            SendErrorMessage(iPlayer, "Not enough master health")
        else
            --For some reason this thing ignores the cast filter SeemsGood
            hUnit:CastAbilityNoTarget(hAbility, iPlayer)
        end
    end
end

function OnPlayerCastSeal(iSource, args)
    local iPlayer = args.PlayerID
    local hUnit = EntIndexToHScript(args.iUnit)
    local hAbility = EntIndexToHScript(args.iAbility)

    if iPlayer == hUnit:GetPlayerOwnerID() then
        if hUnit.HeroUnit and not hUnit.HeroUnit:IsAlive() then
            SendErrorMessage(iPlayer, "Hero is dead")
        end

        if hAbility:GetName() == "cmd_seal_4" then
            if IsManaLess(hUnit.HeroUnit) --[[hUnit.HeroUnit:GetName() == "npc_dota_hero_juggernaut" or hUnit.HeroUnit:GetName() == "npc_dota_hero_shadow_shaman"]] then
                SendErrorMessage(iPlayer, "Cannot use Command Seal 4")
            end
        end

        if hUnit:GetMana() < hAbility:GetManaCost(1) then
            SendErrorMessage(iPlayer, "Not enough mana")
        elseif hUnit:GetHealth() <= 1 then
            SendErrorMessage(iPlayer, "Not enough master health")
        else
            --For some reason this thing ignores the cast filter SeemsGood
            hUnit:CastAbilityNoTarget(hAbility, iPlayer)
        end
    end
end

function OnPlayerCastSeal1(index, keys) 
    local playerID = EntIndexToHScript(keys.player)
    local hero = PlayerResource:GetPlayer(keys.player):GetAssignedHero()
    local master = hero.MasterUnit
    local hAbility = master:GetAbilityByIndex(0)

    if master:GetMana() < hAbility:GetManaCost(1) then
    elseif master:GetHealth() <= 1 then
    else
        --For some reason this thing ignores the cast filter SeemsGood
        master:CastAbilityNoTarget(hAbility, master:GetPlayerOwnerID())
    end
end

function OnPlayerCastSeal2(index, keys) 
    local playerID = EntIndexToHScript(keys.player)
    local hero = PlayerResource:GetPlayer(keys.player):GetAssignedHero()
    local master = hero.MasterUnit
    local hAbility = master:GetAbilityByIndex(1)

    if master:GetMana() < hAbility:GetManaCost(1) then
    elseif master:GetHealth() <= 1 then
    else
        --For some reason this thing ignores the cast filter SeemsGood
        master:CastAbilityNoTarget(hAbility, master:GetPlayerOwnerID())
    end
end

function OnPlayerCastSeal3(index, keys) 
    local playerID = EntIndexToHScript(keys.player)
    local hero = PlayerResource:GetPlayer(keys.player):GetAssignedHero()
    local master = hero.MasterUnit
    local hAbility = master:GetAbilityByIndex(2)

    if master:GetMana() < hAbility:GetManaCost(1) then
    elseif master:GetHealth() <= 1 then
    else
        --For some reason this thing ignores the cast filter SeemsGood
        master:CastAbilityNoTarget(hAbility, master:GetPlayerOwnerID())
    end
end

function OnPlayerCastSeal4(index, keys) 
    local playerID = EntIndexToHScript(keys.player)
    local hero = PlayerResource:GetPlayer(keys.player):GetAssignedHero()
    local master = hero.MasterUnit
    local hAbility = master:GetAbilityByIndex(5)

    if master:GetMana() < hAbility:GetManaCost(1) then
    elseif master:GetHealth() <= 1 then
    else
        --For some reason this thing ignores the cast filter SeemsGood
        master:CastAbilityNoTarget(hAbility, master:GetPlayerOwnerID())
    end
end

function OnPlayerCastSeal5(index, keys) 
    local playerID = EntIndexToHScript(keys.player)
    local hero = PlayerResource:GetPlayer(keys.player):GetAssignedHero()
    local master = hero.MasterUnit
    local hAbility = master:GetAbilityByIndex(3)

    if master:GetMana() < hAbility:GetManaCost(1) then
    elseif master:GetHealth() <= 1 then
    else
        --For some reason this thing ignores the cast filter SeemsGood
        master:CastAbilityNoTarget(hAbility, master:GetPlayerOwnerID())
    end
end

function OnPlayerCastSeal6(index, keys) 
    local playerID = EntIndexToHScript(keys.player)
    local hero = PlayerResource:GetPlayer(keys.player):GetAssignedHero()
    local master = hero.MasterUnit
    local hAbility = master:GetAbilityByIndex(4)

    if master:GetMana() < hAbility:GetManaCost(1) then
    elseif master:GetHealth() <= 1 then
    else
        --For some reason this thing ignores the cast filter SeemsGood
        master:CastAbilityNoTarget(hAbility, master:GetPlayerOwnerID())
    end
end

function DistributeGold(hero, cutoff)
    -- get gold amount of teammates
    -- exclude from table if more than stated amount
    -- sort them by amount of current gold
    local playerTable = {}
    local playerID = hero:GetPlayerID()
    if PlayerResource:GetUnreliableGold(playerID) < cutoff then return end
    LoopOverPlayers(function(ply, plyID, playerHero)
        if playerHero:GetTeamNumber() == hero:GetTeamNumber() and plyID ~= playerID then
            local pGold = PlayerResource:GetUnreliableGold(plyID)
            if pGold < 5000 then
                playerTable[plyID] = pGold
                print(playerHero:GetName())
            end
        end
    end)

    -- local sortedTable = spairs(playerTable, function(t,a,b) return t[b] < t[a] end)
    local residue = 0
    local goldPerPerson =  (PlayerResource:GetUnreliableGold(playerID)-cutoff)/#playerTable

    -- eligible players
    for pID,curGold in spairs(playerTable, function(t,a,b) return t[b] < t[a] end) do
        local eligibleGoldAmt = 5000 - PlayerResource:GetUnreliableGold(pID)
        -- only grant eligible amount of gold and save the rest on residue
        if goldPerPerson > eligibleGoldAmt then
            residue = residue + goldPerPerson - eligibleGoldAmt
            GiveGold(playerID, pID, eligibleGoldAmt)
        -- add residue up
        else
            if goldPerPerson + residue > eligibleGoldAmt then
                residue = goldPerPerson + residue - eligibleGoldAmt
                GiveGold(playerID, pID, eligibleGoldAmt)
            else
                GiveGold(playerID, pID, goldPerPerson+residue)
            end
        end
    end
end

function DistributeGoldV2(hero, cutoff)
    -- get gold amount of teammates
    -- exclude from table if more than 4950

    local goldTable = {}
    local plyIDTable = {}
    local playerID = hero:GetPlayerID()
    if PlayerResource:GetUnreliableGold(playerID) < cutoff then return end
    LoopOverPlayers(function(ply, plyID, playerHero)
        if playerHero:GetTeamNumber() == hero:GetTeamNumber() and plyID ~= playerID then
            local pGold = PlayerResource:GetUnreliableGold(plyID)
            if pGold < 4950 then
                table.insert(goldTable, pGold)
                table.insert(plyIDTable, plyID)
                print(plyID)
                print(pGold)
            end
        end
    end)

    -- quite hard to explain
    -- first attempt the scenario where u give everyone gold such that everyone reaches 4950 gold whereas you still have excess gold above cutoff, this is for the if statement
    -- else you start looking at the richest guy within the people who has less than 4950 gold. suppose the richest guy is 4400 gold, you will now attempt to give everyone gold such that
    -- everyone reaches 4400 or more. 
    -- If this is possible, the excess gold per person (assuming u have given everyone gold such that they reach 4400) can be computed, stored as moreGoldPerPerson. 
    -- The for loop proceeds to make everyone's gold (4400+moreGoldPerPerson). We then terminate the while loop by setting bRecurse = false
    -- However if this is still not possible, we kick the highest guy within the table out of plyIDTable, and also the associated 4400 gold within the goldTable. Because he is no longer eligible for gold
    -- The while loop condition is still satisfied, process repeats again but this time you look at 2nd richest guy among the people with <4950 gold.

    if (4950 * #plyIDTable - SumTable(goldTable)) <= (PlayerResource:GetUnreliableGold(playerID)-cutoff) then 
        for k,gold in spairs(goldTable) do
            local eligibleGoldAmt = 4950 - gold
            GiveGold(playerID, plyIDTable[k], eligibleGoldAmt)
            CustomGameEventManager:Send_ServerToTeam(hero:GetTeamNumber(), "fate_gold_sent", {goldAmt=tonumber(eligibleGoldAmt), sender=hero:entindex(), recipent=PlayerResource:GetPlayer(tonumber(plyIDTable[k])):GetAssignedHero():entindex()} )
        end
    else
        local bRecurse = true
        while (bRecurse == true) do
            local index, highestGold = MaxNumTable(goldTable)
            if (highestGold * #plyIDTable - SumTable(goldTable)) <= (PlayerResource:GetUnreliableGold(playerID)-cutoff) then 
                local moreGoldPerPerson = math.floor(((PlayerResource:GetUnreliableGold(playerID)-cutoff) - (highestGold * #plyIDTable - SumTable(goldTable)))/#plyIDTable)
                for k,gold in spairs(goldTable) do
                    local eligibleGoldAmt = highestGold - gold + moreGoldPerPerson
                    GiveGold(playerID, plyIDTable[k], eligibleGoldAmt)
                    CustomGameEventManager:Send_ServerToTeam(hero:GetTeamNumber(), "fate_gold_sent", {goldAmt=tonumber(eligibleGoldAmt), sender=hero:entindex(), recipent=PlayerResource:GetPlayer(tonumber(plyIDTable[k])):GetAssignedHero():entindex()} )
                end
                bRecurse = false
            else
                table.remove(goldTable,index)
                table.remove(plyIDTable,index)
            end
        end
    end
end

-- The overall game state has changed
function FateGameMode:OnGameRulesStateChange(keys)
   -- print("[BAREBONES] GameRules State Changed")

    local newState = GameRules:State_Get()
    print("OGRSC")
    print(newState)
    if newState == DOTA_GAMERULES_STATE_PRE_GAME then
        print("collectingPD")
        HeroSelection:CollectPD()
        CameraModule:CollectPD()
        HeroSelection:HeroSelectionStart()
        print("PDcollected")
        --GameMode:OnHeroSelectionStart()
    end
    if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
        self.bSeenWaitForPlayers = true
    elseif newState == DOTA_GAMERULES_STATE_INIT then
    elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
    --SendToConsole("r_farz 5000")
    --Convars:SetInt("r_farz", 3300)
        --[[Timers:CreateTimer(2, function()
            FateGameMode:OnAllPlayersLoaded()
        end)

        Selection = HeroSelection()
        Selection:UpdateTime()]]
    elseif newState == DOTA_GAMERULES_STATE_STRATEGY_TIME then
        -- screw 7.00
    elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        GameRules:SetSafeToLeave( true )
        FateGameMode:OnGameInProgress()
    end
end

-- An NPC has spawned somewhere in game. This includes heroes
function FateGameMode:OnNPCSpawned(keys)
   -- print("[BAREBONES] NPC Spawned")
    local hero = EntIndexToHScript(keys.entindex)
    if hero:GetName() == "npc_dota_base_additive" then
        LevelAllAbility(hero)
    end
    Wrappers.WrapUnit(hero)
    table.insert(_G.AllNpcTable, hero)

    if hero:IsRealHero() and hero.bFirstSpawned == nil then
        local playerID = hero:GetPlayerID()
        if playerID ~= nil and playerID ~= -1 then
            FateGameMode:OnHeroInGame(hero)
        end
    end
end

--[[
This function is called once and only once for every player when they spawn into the game for the first time. It is also called
    if the player's hero is replaced with a new hero for any reason. This function is useful for initializing heroes, such as adding
        levels, changing the starting gold, removing/adding abilities, adding physics, etc.
        The hero parameter is the hero entity that just spawned in
        ]]
local team2HeroesSpawned = 0
local team3HeroesSpawn = 0

LinkLuaModifier("modifier_rhyme_flying_book", "abilities/nursery_rhyme/modifiers/modifier_flying_book.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_courier_position", "modifiers/modifier_courier_position.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tp_cooldown", "modifiers/modifier_courier_position.lua", LUA_MODIFIER_MOTION_NONE)
function FateGameMode:OnHeroInGame(hero)
  --  print("[BAREBONES] Hero spawned in game for first time -- " .. hero:GetUnitName())
    --Add a non-player hero to player list if it's missing(i.e generated by -createhero)
    if self.vBots[hero:GetPlayerID()] == 1 then
        print((hero:GetPlayerID()) .." is a bot!")
        self.vPlayerList[hero:GetPlayerID()] = hero:GetPlayerID()
    end
    if hero:GetName() == "npc_dota_hero_wisp" then
        local dummyPause = hero:GetAbilityByIndex(0)
        dummyPause:SetLevel(1)
        dummyPause:ApplyDataDrivenModifier(hero, hero, "modifier_dummy_pause", {duration=9999})
        return
    end
    if hero:GetName() == "npc_dota_hero_target_dummy" then return end

    CameraModule:InitializeCamera(hero:GetPlayerID())

    -- Initialize stuffs
    hero:SetCustomDeathXP(0)
    hero.bFirstSpawned = true
    --UnitVoice(hero)
    hero.PresenceTable = {}
    hero.bIsDmgPopupDisabled = false
    hero.bIsAlertSoundDisabled = false
    hero:SetAbilityPoints(0)
    hero:SetGold(0, false)
    hero.OriginalModel = hero:GetModelName()
    LevelAllAbility(hero)
    hero:RemoveItem(hero:FindItemInInventory("item_tpscroll"))
    hero:AddItem(CreateItem("item_dummy_item_unusable", nil, nil))
    hero:SwapItems(DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_7)
    hero:AddItem(CreateItem("item_dummy_item_unusable", nil, nil))
    hero:SwapItems(DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_8) 
    hero:AddItem(CreateItem("item_dummy_item_unusable", nil, nil))
    hero:SwapItems(DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9)
    hero:AddItem(CreateItem("item_dummy_item_unusable", nil, nil))
    hero:SwapItems(DOTA_ITEM_SLOT_1, DOTA_ITEM_TP_SCROLL)
    --hero:AddItem(CreateItem("item_dummy_item_unusable", hero, hero))
    
    
    
    
     
        --hero:SwapItems(DOTA_ITEM_SLOT_4, DOTA_STASH_SLOT_1)
        hero:AddItem(CreateItem("item_blink_scroll", nil, nil) ) -- Give blink scroll
        --nahuy tpshku, ebuchiy generator bagov
        --[[local huynya = hero:FindItemInInventory('item_tpscroll')
        if huynya then
            hero:RemoveItem(huynya)
        end]]
  

    -- Removing Talents
    for i=0,23 do
        if hero:GetAbilityByIndex(i) ~= nil then
            local ability = hero:GetAbilityByIndex(i)
            if string.match(ability:GetName(),"special_bonus") then
                hero:RemoveAbility(ability:GetName())
            end
        end
    end
    --END

    -- Initialize Alternate Particles.
    hero.AltPart = AlternateParticle:initialise(hero)

    -- Initialize Servant Statistics, and related collection stuff
    hero.ServStat = ServantStatistics:initialise(hero)
    hero.ServStat:roundNumber(self.nCurrentRound) -- to properly initialise the current round number when player picks a hero late. 
    --giveUnitDataDrivenModifier(hero, hero, "modifier_damage_collection", {})
    -- END

    hero.defaultSendGold = 300
    hero.CStock = 10
    hero.ShardAmount = 0

    Timers:CreateTimer(1.0, function()
        local team = hero:GetTeam()
        local currentRound = self.nCurrentRound
        if team == 2 then
            if currentRound == 0 or currentRound == 1 then
                hero.RespawnPos = SPAWN_POSITION_RADIANT_DM
            elseif currentRound % 2 == 0 then
                hero.RespawnPos = SPAWN_POSITION_DIRE_DM
            end
        elseif team == 3 then
            if currentRound == 0 or currentRound == 1 then
                hero.RespawnPos = SPAWN_POSITION_DIRE_DM
            elseif currentRound % 2 == 0 then
                hero.RespawnPos = SPAWN_POSITION_RADIANT_DM
            end
        end
        --print("Respawn location registered : " .. hero.RespawnPos.x .. " BY " .. hero:GetName() )
            if _G.GameMap == "fate_elim_6v6" or _G.GameMap == "fate_elim_7v7" or _G.GameMap == "fate_elim_7v7_test" or _G.GameMap =="anime_fate_7vs7_beta" or _G.GameMap =="7vs7_common" or _G.GameMap =="7vs7_draft" then
            local index
            if team == 2 then
                index = team2HeroesSpawned
                team2HeroesSpawned = team2HeroesSpawned + 1
            else
                index = team3HeroesSpawn
                team3HeroesSpawn = team3HeroesSpawn + 1
            end
            local currentRound = self.nCurrentRound
            -- round 0 uses initial spawn position
            local spawnPos = GetRespawnPos(hero, currentRound == 0 and 1 or currentRound, index)
            -- hero seems to spawn in the air so we have to get ground position here
            hero:SetAbsOrigin(GetGroundPosition(spawnPos, nil))
        end
    end)
    hero.bIsDirectTransferEnabled = true -- True by default
    Attributes:ModifyBonuses(hero)

    -- Create Command Seal master for hero
    local master_area = -6540 + hero:GetPlayerID()*270
    master = CreateUnitByName("master_1", Vector(master_area,-6250,0), true, hero, hero, hero:GetTeamNumber())
    master:SetControllableByPlayer(hero:GetPlayerID(), true)
    master:SetMana(0)

    hero.MasterUnit = master
    master.HeroUnit = hero
    LevelAllAbility(master)

    if hero:GetName() == "npc_dota_hero_windrunner" then
        hero:AddNewModifier(hero, hero:FindAbilityByName("nursery_rhyme_queens_glass_game"), "modifier_rhyme_flying_book", {})
    end

    if hero:GetName() == "npc_dota_hero_skywrath_mage" then
        self.gilEntIndex = hero:GetEntityIndex()
    end
    if hero:GetName() == "npc_dota_hero_ember_spirit" then
        self.emiyaEntIndex = hero:GetEntityIndex()
    end
    if hero:GetName() == "npc_dota_hero_gyrocopter" then
         hero.ISDOW = false
         hero.isCharisma = false
    end

  
    if hero:GetName() == "npc_dota_hero_juggernaut" then -- or hero:GetName() == "npc_dota_hero_shadow_shaman" then
        hero:FindAbilityByName("attribute_bonus_custom_no_int"):SetHidden(false)
    else
        hero:FindAbilityByName("attribute_bonus_custom"):SetHidden(false)
    end
    master:AddItem(CreateItem("item_master_transfer_items1", nil, nil))
    master:AddItem(CreateItem("item_master_transfer_items2", nil, nil))
    master:AddItem(CreateItem("item_master_transfer_items3", nil, nil))
    master:AddItem(CreateItem("item_master_transfer_items4", nil, nil))
    master:AddItem(CreateItem("item_master_transfer_items5", nil, nil))
    master:AddItem(CreateItem("item_master_transfer_items6", nil, nil))
    MinimapEvent( hero:GetTeamNumber(), hero, master:GetAbsOrigin().x, master:GetAbsOrigin().y + 500, DOTA_MINIMAP_EVENT_HINT_LOCATION, 5 )

    -- Create attribute/stat master for hero
    master2 = CreateUnitByName("master_2", Vector(master_area,-6600,0), true, hero, hero, hero:GetTeamNumber())
    master2:SetControllableByPlayer(hero:GetPlayerID(), true)
    master2:SetMana(0)
    
    hero.MasterUnit2 = master2
    master2.HeroUnit = hero
    AddMasterAbility(master2, hero:GetName())
    LevelAllAbility(master2)
    local playerData = {
        masterUnit = master2:entindex(),
        shardUnit = master:entindex(),
        hero = hero:entindex()
    }
    --hero:AddNewModifier(hero, hero:GetAbilityByIndex(0), "modifier_tp_cooldown", {})
    --[[-- Create personal stash for hero
    masterStash = CreateUnitByName("master_stash", Vector(4500 + hero:GetPlayerID()*350,-7250,0), true, hero, hero, hero:GetTeamNumber())
    masterStash:SetControllableByPlayer(hero:GetPlayerID(), true)
    masterStash:SetAcquisitionRange(200)
    hero.MasterStash = masterStash
    LevelAllAbility(masterStash)]]
    -- Create item transfer master for hero
    Timers:CreateTimer(hero:GetPlayerID() + 1, function()
        master3 = CreateUnitByName("npc_dota_courier", hero:GetAbsOrigin(), true, hero, hero, hero:GetTeamNumber())
        master3:SetControllableByPlayer(hero:GetPlayerID(), true)

        master3:RemoveAbility("courier_return_to_base")
        master3:RemoveAbility("courier_go_to_secretshop")
        master3:RemoveAbility("courier_return_stash_items")
        master3:RemoveAbility("courier_take_stash_items")
        master3:RemoveAbility("courier_transfer_items")
        master3:RemoveAbility("courier_burst")
        master3:RemoveAbility("courier_shield")
        master3:RemoveAbility("courier_morph")
        master3:RemoveAbility("courier_take_stash_and_transfer_items")

        master3:AddAbility("master_item_transfer_1")
        master3:AddAbility("master_item_transfer_2")
        master3:AddAbility("master_item_transfer_3")
        master3:AddAbility("master_item_transfer_4")
        master3:AddAbility("master_item_transfer_5")
        master3:AddAbility("master_item_transfer_6")
        master3:AddAbility("master_passive")
        LevelAllAbility(master3)

        master3:AddNewModifier(master3, master3:GetAbilityByIndex(0), "modifier_courier_position", {vector_x = master_area, vector_y = -6400, vector_z = 0})

        master3:SetDayTimeVisionRange(150)
        master3:SetNightTimeVisionRange(150)
    end)


    -- Ping master location on minimap
    local pingsign = CreateUnitByName("ping_sign", Vector(0,0,0), true, hero, hero, hero:GetTeamNumber())
    pingsign:FindAbilityByName("ping_sign_passive"):SetLevel(1)
    pingsign:SetAbsOrigin(Vector(-6540 + hero:GetPlayerID()*270,-6500,0))
    -- Announce the summon
    local heroName = FindName(hero:GetName())
    hero.name = heroName
    --GameRules:SendCustomMessage("Servant <font color='#58ACFA'>" .. heroName .. "</font> has been summoned.", 0, 0)

    if _G.GameMap == "fate_elim_6v6" or _G.GameMap == "fate_elim_7v7" or _G.GameMap == "fate_elim_7v7_test" or _G.GameMap =="anime_fate_7vs7_beta" or _G.GameMap =="7vs7_common" or _G.GameMap =="7vs7_draft" then
        if self.nCurrentRound == 0 and _G.CurrentGameState == "FATE_PRE_GAME" then
            giveUnitDataDrivenModifier(hero, hero, "round_pause", 20)
        else
            giveUnitDataDrivenModifier(hero, hero, "round_pause", 10)
        end
    else
        -- This is timed such that you can start moving when pick screen times out. If you pick a hero late and that game already started, math.max(0,<some negative number>) == 0 thus no pause.
        if _G.CurrentGameState == "FATE_PRE_GAME" then
            SendChatToPanorama(tostring(math.max(0,73-math.ceil(GameRules:GetGameTime()))))
            giveUnitDataDrivenModifier(hero, hero, "round_pause", (math.max(0,73-math.ceil(GameRules:GetGameTime()))))
        end
    end

    if Convars:GetBool("sv_cheats") then
        -- hero:RemoveModifierByName("round_pause")
        hero.MasterUnit:SetMana(hero.MasterUnit:GetMaxMana())
        hero.MasterUnit2:SetMana(hero.MasterUnit2:GetMaxMana())

        if hero:GetName() ~= "npc_dota_hero_juggernaut" then
            --hero:SetBaseStrength(30)
            --hero:SetBaseAgility(30)
            --hero:SetBaseIntellect(30)
        else
            hero:SetBaseStrength(30)
            hero:SetBaseAgility(30)
        end
    end

    self:PlayTeamPickSound(hero)

    -- Wait 1 second for loadup
    Timers:CreateTimer(1.0, function()
        --[[Timers:CreateTimer(1 + 10*hero:GetPlayerID(), function()
            master3:SetAbsOrigin(Vector(master_area,-7225,0))
        end)]]
        if _G.GameMap == "fate_ffa" or _G.GameMap == "fate_trio_rumble_3v3v3v3" then
            hero:HeroLevelUp(false)
            hero:HeroLevelUp(false)
            VICTORY_CONDITION = 30
            victoryConditionData.victoryCondition = VICTORY_CONDITION
        end
        CustomGameEventManager:Send_ServerToAllClients( "victory_condition_set", victoryConditionData ) -- Display victory condition for player
        --SendKVToFatepedia(player) -- send KV to fatepedia

        if hero:GetName() == "npc_dota_hero_crystal_maiden" then
            --[[for i=6, 11 do
                hero:GetAbilityByIndex(i):SetHidden(false)
            end]]
        elseif hero:GetName() == "npc_dota_hero_queenofpain" then
            --Attachments:AttachProp(hero, "attach_sword", "models/astolfo/astolfo_sword.vmdl")
        end
        hero:ModifyGold(3050, false, 0)
        local player = hero:GetPlayerOwner()
        CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "player_selected_hero", playerData)
        CustomGameEventManager:Send_ServerToAllClients("player_register_master_unit", playerData)
        self:InitialiseMissingPanoramaData(hero:GetPlayerOwner())
        self:InitialiseMissingPanoramaData(hero:GetPlayerOwner(),hero,hero.MasterUnit2)
        --[[player:SetMusicStatus(5, 1)
        StopSoundEvent("DOTAMusic.Laning_02", hero)
        StopSoundEvent("DOTAMusic.Laning_01", hero)
        StopSoundEvent("DOTAMusic.Laning_03", hero)]]
    end)

    --[[CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "player_selected_hero", playerData)
    CustomGameEventManager:Send_ServerToAllClients("player_register_master_unit", playerData)]]

    --[[Timers:CreateTimer(12.0, function()
        local player = hero:GetPlayerOwner()
        player:SetMusicStatus(5, 1)
        StopSoundEvent("DOTAMusic.Laning_02", hero)
        StopSoundEvent("DOTAMusic.Laning_01", hero)
        StopSoundEvent("DOTAMusic.Laning_03", hero)

    end)]]

  

    -- Set music off
    SendToServerConsole("dota_music_battle_enable 0")
    SendToConsole("dota_music_battle_enable 0")  
end

function FateGameMode:PlayTeamPickSound(hero)
    for i=0, 13 do
        local player = PlayerResource:GetPlayer(i)
        local playerHero = PlayerResource:GetSelectedHeroEntity(i)            
        if playerHero ~= nil then
            if playerHero:GetTeam() == hero:GetTeam() then
                if playerHero:GetName() == "npc_dota_hero_phantom_lancer" and hero:GetName() == "npc_dota_hero_ember_spirit" then
                    playerHero:EmitSound("CuChulain_Ally_Emiya")
                    break
                elseif playerHero:GetName() == "npc_dota_hero_ember_spirit" and (hero:GetName() == "npc_dota_hero_skywrath_mage" or hero:GetName() == "npc_dota_hero_phantom_lancer") then
                    playerHero:EmitSound("Emiya_Ally_Gilgamesh_CuChulainn")
                    break
                elseif playerHero:GetName() == "npc_dota_hero_legion_commander" then
                    if hero:GetName() == "npc_dota_hero_omniknight" then
                        playerHero:EmitSound("Saber_Ally_Gawain")
                        break
                    elseif hero:GetName() == "npc_dota_hero_ember_spirit" then
                        playerHero:EmitSound("Saber_Ally_Emiya")
                        break
                    end                    
                elseif playerHero:GetName() == "npc_dota_hero_omniknight" then
                    if hero:GetName() == "npc_dota_hero_legion_commander" then
                        playerHero:EmitSound("Gawain_Ally_Saber")
                        break
                    elseif hero:GetName() == "npc_dota_hero_sven" then
                        playerHero:EmitSound("Gawain_Ally_Lancelot")
                        break
                    end                    
                elseif playerHero:GetName() == "npc_dota_hero_shadow_shaman" and hero:GetName() == "npc_dota_hero_legion_commander" then
                    playerHero:EmitSound("Gilles_Ally_Arturia")
                    break
                elseif playerHero:GetName() == "npc_dota_hero_chen" then
                    if hero:GetName() == "npc_dota_hero_legion_commander" then
                        playerHero:EmitSound("Iskandar_Ally_Arturia")
                        break
                    elseif hero:GetName() == "npc_dota_hero_skywrath_mage" then
                        playerHero:EmitSound("Iskandar_Ally_Gilgamesh")
                        break
                    end                    
                elseif playerHero:GetName() == "npc_dota_hero_crystal_maiden" then
                    if hero:GetName() == "npc_dota_hero_legion_commander" then
                        playerHero:EmitSound("Medea_Ally_Arturia")
                        break
                    elseif hero:GetName() == "npc_dota_hero_doom_bringer" then
                        playerHero:EmitSound("Medea_Ally_Heracles")
                        break
                    end                    
                elseif playerHero:GetName() == "npc_dota_hero_huskar" then
                    if hero:GetName() == "npc_dota_hero_legion_commander" then
                        playerHero:EmitSound("Diarmuid_Ally_Arthuria_" .. math.random(1,2))
                        break
                    elseif hero:GetName() == "npc_dota_hero_phantom_lancer" then
                        playerHero:EmitSound("Diarmuid_Ally_CuChulainn")
                        break
                    end
                elseif playerHero:GetName() == "npc_dota_hero_templar_assassin" and hero:GetName() == "npc_dota_hero_crystal_maiden" then
                    playerHero:EmitSound("Medusa_Ally_Medea")
                    break
                elseif playerHero:GetName() == "npc_dota_hero_skywrath_mage" and hero:GetName() == "npc_dota_hero_legion_commander" then
                    playerHero:EmitSound("Gilgamesh_Ally_Arturia")
                    break
                elseif playerHero:GetName() == "npc_dota_hero_lina" and hero:GetName() == "npc_dota_hero_enchantress" then
                    playerHero:EmitSound("Nero_Ally_Tamamo")
                    break
                elseif playerHero:GetName() == "npc_dota_hero_enchantress" and hero:GetName() == "npc_dota_hero_lina" then
                    playerHero:EmitSound("Tamamo_Ally_Nero")
                    break
                end
            else
                if playerHero:GetName() == "npc_dota_hero_shadow_shaman" then
                    if hero:GetName() == "npc_dota_hero_mirana" then
                        playerHero:EmitSound("Gilles_Enemy_Jeanne")
                        break
                    elseif hero:GetName() == "npc_dota_hero_legion_commander" then
                        playerHero:EmitSound("Gilles_Enemy_Arturia")
                        break
                    end
                elseif playerHero:GetName() == "npc_dota_hero_drow_ranger" and hero:GetName() == "npc_dota_hero_mirana" then
                    playerHero:EmitSound("Atalanta_Enemy_Jeanne")
                    break
                elseif playerHero:GetName() == "npc_dota_hero_huskar" and hero:GetName() == "npc_dota_hero_legion_commander" then
                    playerHero:EmitSound("Diarmuid_Enemy_Arthuria")
                    break
                elseif playerHero:GetName() == "npc_dota_hero_skywrath_mage" and hero:GetName() == "npc_dota_hero_ember_spirit" then
                    playerHero:EmitSound("Gilgamesh_Enemy_Emiya")
                    break
                elseif playerHero:GetName() == "npc_dota_hero_omniknight" and hero:GetName() == "npc_dota_hero_legion_commander" then
                    playerHero:EmitSound("Gawain_Enemy_Saber")
                    break
                elseif playerHero:GetName() == "npc_dota_hero_legion_commander" and hero:GetName() == "npc_dota_hero_omniknight" then
                    playerHero:EmitSound("Saber_Enemy_Gawain")
                    break
                end
            end

        end
    end
end

-- This is for swapping hero models in
function FateGameMode:OnHeroSpawned( keys )

end

-- An entity somewhere has been hurt. This event fires very often with many units so don't do too many expensive
-- operations here
function FateGameMode:OnEntityHurt(keys)
   -- print("[BAREBONES] Entity Hurt")
    --PrintTable(keys)
    local entCause = EntIndexToHScript(keys.entindex_attacker)
    local entVictim = EntIndexToHScript(keys.entindex_killed)
end

-- An item was picked up off the ground
function FateGameMode:OnItemPickedUp(keys)

   -- print("Item pickup")
    for k,v in pairs(keys) do print(k,v) end

    local heroEntity = nil
    local player = nil
    local item = EntIndexToHScript( keys.ItemEntityIndex )

    if keys.HeroEntityIndex ~= nil then
        heroEntity = EntIndexToHScript(keys.HeroEntityIndex)
        player = PlayerResource:GetPlayer(keys.PlayerID)
        CheckItemCombination(heroEntity)
    end

    local itemname = keys.itemname
    if itemname == "item_shard_drop" then
        -- add shard
        UTIL_Remove( item ) -- otherwise it pollutes the player inventory
        if heroEntity then AddRandomShard(heroEntity) end
    elseif itemName == "item_shard_of_replenishment" or itemname == "item_shard_of_anti_magic" then
        if item:GetPurchaser():entindex() ~= keys.HeroEntityIndex and heroEntity ~= nil then
            heroEntity:DropItemAtPositionImmediate(item, heroEntity:GetAbsOrigin())
        end
    end
end


function CreateShardDrop(location)
    --Spawn the treasure chest at the selected item spawn location
    local newItem = CreateItem( "item_shard_drop", nil, nil )
    local drop = CreateItemOnPositionForLaunch( location + Vector(0,0,1500), newItem )
    newItem:LaunchLootInitialHeight( false, 700, 50, 0.5, location )
end

function AddRandomShard(hero)
    local shardDropTable = {
        "master_shard_of_anti_magic",
        "master_shard_of_replenishment",
    }
    local shardRealNameTable = {
        "Shard of Anti-Magic",
        "Shard of Replenishment",
    }
    if not hero.ShardAmount then
        hero.ShardAmount = 1
    else
        hero.ShardAmount = hero.ShardAmount + 1
    end
    local masterUnit = hero.MasterUnit
    local choice = math.random(#shardDropTable)
    local ability = masterUnit:FindAbilityByName(shardDropTable[choice])
    masterUnit:CastAbilityImmediately(ability, hero:GetPlayerOwnerID())
    Notifications:TopToAll({text=FindName(hero:GetName()) .. " has acquired <font color='#FF6600'>" .. shardRealNameTable[choice] .. "</font>!", duration=5.0, style={color="rgb(255,255,255)", ["font-size"]="25px"}})

end

-- A player has reconnected to the game. This function can be used to repaint Player-based particles or change
-- state as necessary
function FateGameMode:OnPlayerReconnect(keys)
  --  print ( '[BAREBONES] OnPlayerReconnect' )
    --PrintTable(keys)
    Timers:CreateTimer(3.0, function()
        print("reinitiating the UI")
        local userid = keys.PlayerID
        local ply = PlayerResource:GetPlayer(keys.PlayerID)
        local hero = ply:GetAssignedHero()

        local playerData = {
            masterUnit = hero.MasterUnit2:entindex(),
            shardUnit = hero.MasterUnit:entindex()
        }
        CustomGameEventManager:Send_ServerToPlayer(ply, "player_selected_hero", playerData)
        --CustomGameEventManager:Send_ServerToAllClients( "victory_condition_set", victoryConditionData ) -- Send the winner to Javascript

        self:InitialiseMissingPanoramaData(ply)
    end)
end

function FateGameMode:InitialiseMissingPanoramaData(ply)
    local hero = ply:GetAssignedHero()

    local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer(ply, "servant_stats_updated", statTable)

    local winnerEventData = {}
    winnerEventData.radiantScore = self.nRadiantScore
    winnerEventData.direScore = self.nDireScore
    CustomGameEventManager:Send_ServerToPlayer(ply, "winner_decided", winnerEventData)

    local masterUnits = {}
    self:LoopOverPlayers(function(player, playerID, hero)
        if hero == nil then
          return
        end
        local masterUnit = hero.MasterUnit
        if masterUnit == nil then
          return
        end

        local masterEntIndex = masterUnit:entindex()
        local heroEntIndex = hero:entindex()
        masterUnits[heroEntIndex] = masterEntIndex
    end)
    CustomGameEventManager:Send_ServerToPlayer(ply, "player_register_all_master_units", masterUnits)

    RecreateUITimer(ply, "round_10min_bonus", "Next Holy Grail's Blessing", "ten_min_timer")
    RecreateUITimer(ply, "shard_drop_event", "Next Holy Grail's Shard", "shard_drop_timer")
    RecreateUITimer(ply, "beginround", "Pre-Round", "pregame_timer")
    RecreateUITimer(ply, "round_timer", "Round " .. self.nCurrentRound, "round_timer" .. self.nCurrentRound)
end

function RecreateUITimer(playerID, timerName, message, description)
    local timer = Timers.timers[timerName]
    if timer == nil then
      return
    end

    local endTime = timer.endTime
    if endTime == nil then
      return
    end

    local gameTime = GameRules:GetGameTime()
    local duration = endTime - gameTime

    local timerData = {
        timerMsg = message,
        timerDuration = duration,
        timerDescription = description
    }

    CustomGameEventManager:Send_ServerToPlayer(playerID, "display_timer", timerData)
end

-- An item was purchased by a player
function FateGameMode:OnItemPurchased( keys )
  --  print ( '[BAREBONES] OnItemPurchased : Purchased ' .. keys.itemname )
    --PrintTable(keys)

    -- The playerID of the hero who is buying something
    local plyID = keys.PlayerID
    local ply = PlayerResource:GetPlayer(plyID)
    if not plyID then return end

    -- The name of the item purchased
    local itemName = keys.itemname
    -- The cost of the item purchased
    local itemCost = keys.itemcost

    local hero = PlayerResource:GetPlayer(plyID):GetAssignedHero()

    local extraCost = 0
    local isScroll = false

    local isPriceIncreased = not hero.IsInBase
    local isCStockMessage = false

    --[[if hero.IsInBase then
        if itemName == "item_c_scroll" then
            if hero.CStock > 0 then
                hero.CStock = hero.CStock - 1
                --hero.ServStat:trueWorth(tonumber(itemCost))
                isPriceIncreased = false
            else
                SendErrorMessage(plyID, "#Out_Of_Stock_C_Scroll")
                isCStockMessage = true
                hero.CStock = hero.CStock - 1
            end
        --Lets just have this bandaid here ulu
        elseif itemName == "item_b_scroll" then
            hero.CStock = hero.CStock - 2
        elseif itemName == "item_a_scroll" then
            hero.CStock = hero.CStock - 4
        elseif itemName == "item_s_scroll" then
            hero.CStock = hero.CStock - 8
        elseif itemName == "item_ex_scroll" then
            hero.CStock = hero.CStock - 16
        else
            isPriceIncreased = false
        end

        if hero.CStock < 0 then
            while hero.CStock < 0 do
                extraCost = extraCost + 75
                hero.CStock = hero.CStock + 1
            end

            isPriceIncreased = true
            isScroll = true  
        else
            isPriceIncreased = false
        end
    end]]

    if isPriceIncreased then 
        if PlayerResource:GetGold(plyID) >= itemCost * 0.5 then
            local unreliableGold = PlayerResource:GetUnreliableGold(plyID)
            hero:ModifyGold(-itemCost * 0.5, false, 0)
            --local diff = math.max(itemCost * 0.5 - unreliableGold, 0)
            --hero:ModifyGold(-diff, true, 0)
        --[[elseif PlayerResource:GetGold(plyID) >= extraCost and isScroll == true then
            local unreliableGold = PlayerResource:GetUnreliableGold(plyID)
            hero:ModifyGold(-extraCost, false, 0)
            local diff = math.max(extraCost - unreliableGold, 0)
            hero:ModifyGold(-diff, true, 0)]]
        else
            SendErrorMessage(plyID,  "#Not_Enough_Gold_Item")
            
            hero:ModifyGold(itemCost, false, 0)
            local isItemDropped = true

            local stash = GetStashItems(hero)
            local oldStash = hero.stashState or {}
            for i = 1,6 do
                if stash[i] ~= oldStash[i] then
                    isItemDropped = false
                    break
                end
            end
            
            local itemsWithSameName = Entities:FindAllByName(itemName)
            local droppedItem
            local purchasedTime = -9999 

            for i = 1,#itemsWithSameName do
                print(itemsWithSameName[i])
                local item = itemsWithSameName[i]
                if item:GetPurchaser() == hero and item:GetPurchaseTime() > purchasedTime then
                    droppedItem = item
                    purchasedTime = item:GetPurchaseTime()
                end
            end

            if droppedItem == nil then
                print("Unexpected: Item was nil - " .. itemName)
            else

                if droppedItem:GetContainer() then
                    droppedItem:GetContainer():RemoveSelf()
                else
                    droppedItem:RemoveSelf()
                end
                GameRules:IncreaseItemStock(PlayerResource:GetTeam(plyID),itemName,1,plyID)
            end
        end
    end

    if (not ply.AutoTransferItemEnabled) or (not hero:IsAlive()) then
        CheckItemCombination(hero)
        CheckItemCombinationInStash(hero)
        SaveStashState(hero)
    else
        AutoTransferItem(hero, itemName)
    end

    if PlayerResource:GetGold(plyID) < 200 and hero.bIsAutoGoldRequestOn then
        Notifications:RightToTeamGold(hero:GetTeam(), "<font color='#FF5050'>" .. FindName(hero:GetName()) .. "</font> at <font color='#FFD700'>" .. hero:GetGold() .. "g</font> is requesting gold. Type <font color='#58ACFA'>-" .. plyID .. " (goldamount)</font> to send gold!", 7, nil, {color="rgb(255,255,255)", ["font-size"]="20px"}, true)
    end
end

function GetHeroItems(hero)
    local itemTable = {}
    for i=1,6 do
        local item = hero:GetItemInSlot(i)
        table.insert(itemTable, i, item and item:GetName())
    end
    return itemTable
end

function GetStashItems(hero)
    local stashTable = {}
    for i=1,6 do
        local item = hero:GetItemInSlot(i + 9)
        table.insert(stashTable, i, item and item:GetName())
    end
    return stashTable
end

function FindItemInStash(hero, itemname)
    for i=10, 15 do
        local heroItem = hero:GetItemInSlot(i)
        if heroItem == nil then return nil end
        if heroItem:GetName() == itemname then
            return heroItem
        end
    end
    return nil
end


-- stash1 : old stash
-- stash2 : new stash
function FindStashDifference(stash1, stash2)
    local addedItems = {}
    for i=1, #stash2 do
        local IsItemFound = false
        for j=1, #stash1 do
            if stash1[j] == stash2[i] then IsItemFound = true break end -- Set flag to true and break from inner loop if same item is found
        end
        -- If item was not found, add item to return table
        if IsItemFound == false then
            table.insert(addedItems, stash2[i])
        end
    end

    return addedItems
end

local spellBooks = {
    "cu_chulain_rune_magic",
    "cu_chulain_close_runes",
    "caster_5th_ancient_magic",
    "caster_5th_close_spellbook",
    "lancelot_knight_of_honor",
    "lancelot_knight_of_honor_close",
    "nero_imperial_privilege",
    "nero_close_spellbook",
    "tamamo_armed_up",
    "tamamo_close_spellbook",
    "gilles_rlyeh_text_open",
    "gilles_rlyeh_text_close",
    "nero_heat",
    "mordred_pedigree",
    "kuro_spellbook_open",
    "kuro_spellbook_close",
    "atalanta_celestial_arrow",
    "atalanta_priestess_of_the_hunt",
    "nero_imperial_open",
    "nero_imperial_close",
    "nero_imperial_activate"
}

-- An ability was used by a player
function FateGameMode:OnAbilityUsed(keys)
  --  print('[BAREBONES] AbilityUsed')
    local player = EntIndexToHScript(keys.PlayerID)
    local abilityname = keys.abilityname
    local hero = PlayerResource:GetPlayer(keys.PlayerID):GetAssignedHero()

    local hero2 = PlayerResource:GetSelectedHeroEntity(keys.PlayerID)
    --print(hero2)

    if (hero and hero:GetName() == "npc_dota_hero_windrunner") and (abilityname and abilityname == "nursery_rhyme_story_for_somebodys_sake") then
        local comboAbil = hero:FindAbilityByName("nursery_rhyme_story_for_somebodys_sake")
        --print( comboAbil:GetLevelSpecialValueFor("time_limit", 2) )
        Timers:CreateTimer(comboAbil:GetLevelSpecialValueFor("time_limit", 2), function()
            if hero.bIsNRComboSuccessful and hero:IsAlive() then
                self:FinishRound(false, 2)
            end
        end)
    end

--    if (hero and hero:GetName() == "npc_dota_hero_mirana") and (abilityname and abilityname == "jeanne_la_pucelle") then
--        local comboAbil = hero:FindAbilityByName("jeanne_la_pucelle")
--        Timers:CreateTimer(comboAbil:GetSpecialValueFor("delay") + 0.25, function()
 --           if hero.LaPucelleSuccess then
   --             local nRadiantAlive = 0
     --           local nDireAlive = 0
--
  --              if _G.CurrentGameState ~= "FATE_POST_ROUND" then
    --                print("From La Pucelle")
      --              -- Check how many people are alive in each team
        --            self:LoopOverPlayers(function(player, playerID, playerHero)
          --              if playerHero:IsAlive() then
                           -- if playerHero:GetTeam() == DOTA_TEAM_GOODGUYS then
                           --     nRadiantAlive = nRadiantAlive + 1
                         --   else
                         --       nDireAlive = nDireAlive + 1
                        --    end
            --            end
              --      end)
--
  --                  if nRadiantAlive == nDireAlive then
    --                    -- Default Radiant Win
      --                  if self.nRadiantScore + 1 < self.nDireScore                            
        --                    then self:FinishRound(true,3)
          --              -- Default Dire Win
            --            elseif self.nRadiantScore > self.nDireScore + 1
              --              then  self:FinishRound(true,4)
                --        -- Draw
                  --      else                    
                    --        self:FinishRound(true, 2)
                      --  end
                    -- if remaining players are not equal
 --                   elseif nRadiantAlive > nDireAlive then
   --                     self:FinishRound(true, 0)
     --               elseif nRadiantAlive < nDireAlive then
       --                 self:FinishRound(true, 1)
         --           end
           --     end
  --          end
    --    end)
   -- end
    -- Check whether ability is an item active or not
    if not string.match(abilityname,"item") then
        -- Check if hero is affected by Amaterasu
        --[[if hero:HasModifier("modifier_amaterasu_ally") and not (hero:GetName() == "npc_dota_hero_juggernaut" or hero:GetName() == "npc_dota_hero_shadow_shaman") then
            for i=1, #spellBooks do
                if abilityname == spellBooks[i] then return end
            end
            hero:SetMana(hero:GetMana()+200)
            hero:SetHealth(hero:GetHealth()+300)
            hero:EmitSound("DOTA_Item.ArcaneBoots.Activate")
            local particle = ParticleManager:CreateParticle("particles/items_fx/arcane_boots.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
            ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
        end]]

        -- Check if a hero with Martial Arts is nearby
        if hero:HasModifier("modifier_martial_arts_aura_enemy") then
            for i=1, #spellBooks do
                if abilityname == spellBooks[i] then return end
            end
            local targets = FindUnitsInRadius(hero:GetTeam(), hero:GetOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
            for k,v in pairs(targets) do
                if v:HasAbility("lishuwen_martial_arts") then
                    local abil = v:FindAbilityByName("lishuwen_martial_arts")
                    --abil:ApplyDataDrivenModifier(v, hero, "modifier_mark_of_fatality", {})
                    ApplyMarkOfFatality(v, hero)
                    SpawnAttachedVisionDummy(v, hero, abil:GetLevelSpecialValueFor("vision_radius", abil:GetLevel()-1 ), abil:GetLevelSpecialValueFor("duration", abil:GetLevel()-1 ), false)
                end
            end
        end
    end
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function FateGameMode:OnNonPlayerUsedAbility(keys)
  --  print('[BAREBONES] OnNonPlayerUsedAbility')
    --PrintTable(keys)

    local abilityname= keys.abilityname
end

-- A player changed their name
function FateGameMode:OnPlayerChangedName(keys)
  --  print('[BAREBONES] OnPlayerChangedName')
    --PrintTable(keys)

    local newName = keys.newname
    local oldName = keys.oldName
end

-- A player leveled up an ability
function FateGameMode:OnPlayerLearnedAbility( keys)
 --   print ('[BAREBONES] OnPlayerLearnedAbility')
    --PrintTable(keys)

    local player = EntIndexToHScript(keys.player)
    local abilityname = keys.abilityname
end

-- A channelled ability finished by either completing or being interrupted
function FateGameMode:OnAbilityChannelFinished(keys)
   -- print ('[BAREBONES] OnAbilityChannelFinished')
    --PrintTable(keys)

    local abilityname = keys.abilityname
    local interrupted = keys.interrupted == 1
end

-- A player leveled up
function FateGameMode:OnPlayerLevelUp(keys)
  --  print ('[BAREBONES] OnPlayerLevelUp')
    --PrintTable(keys)

    --local player = EntIndexToHScript(keys.player_id)
    local player = PlayerResource:GetPlayer(keys.player_id)
    --local hero = player:GetAssignedHero()
    local hero = EntIndexToHScript(keys.hero_entindex)
    local level = keys.level
    hero.ServStat:getLvl(hero)
    --fuck 7.0
    --if level == 17 or level == 19 or level == 21 or level == 22 or level == 23 or level == 24 then
    --    hero:SetAbilityPoints(hero:GetAbilityPoints()+1)
    --end

    hero.MasterUnit:SetMana(hero.MasterUnit:GetMana() + 3)
    hero.MasterUnit2:SetMana(hero.MasterUnit2:GetMana() + 3)
    --Notifications:Top(player, "<font color='#58ACFA'>" .. FindName(hero:GetName()) .. "</font> has gained a level. Master has received <font color='#58ACFA'>3 mana.</font>", 5, nil, {color="rgb(255,255,255)", ["font-size"]="20px"})

    Notifications:Top(player, {text= "<font color='#58ACFA'>" .. FindName(hero:GetName()) .. "</font> has gained a level. Master has received <font color='#58ACFA'>3 mana.</font>", duration=5, style={color="rgb(255,255,255)", ["font-size"]="20px"}, continue=true})
    if level == 24 then
        Notifications:Top(player, {text= "<font color='#58ACFA'>" .. FindName(hero:GetName()) .. "</font> has ascended to max level! Your Master's max health has been increased by 2.", duration=8, style={color="rgb(255,140,0)", ["font-size"]="35px"}, continue=true})
        Notifications:Top(player, {text= "Exalted by your ascension, Holy Grail's Blessing from now on will award 3 more mana.", duration=8, style={color="rgb(255,140,0)", ["font-size"]="35px"}, continue=true})
        hero.MasterUnit:SetMana(hero.MasterUnit:GetMana() + 3)
        hero.MasterUnit2:SetMana(hero.MasterUnit2:GetMana() + 3)
        hero.MasterUnit:SetMaxHealth(hero.MasterUnit:GetMaxHealth()+2)
        hero.MasterUnit2:SetMaxHealth(hero.MasterUnit2:GetMaxHealth() + 2)
        hero.Level24Acquired = true
    end
    MinimapEvent( hero:GetTeamNumber(), hero, hero.MasterUnit:GetAbsOrigin().x, hero.MasterUnit2:GetAbsOrigin().y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 2 )
end

-- A player last hit a creep, a tower, or a hero
function FateGameMode:OnLastHit(keys)
  --  print ('[BAREBONES] OnLastHit')
    --PrintTable(keys)

    local isFirstBlood = keys.FirstBlood == 1
    local isHeroKill = keys.HeroKill == 1
    local isTowerKill = keys.TowerKill == 1
    local player = PlayerResource:GetPlayer(keys.PlayerID)
end

-- A player picked a hero
function FateGameMode:OnPlayerPickHero(keys)
   -- print ('[BAREBONES] OnPlayerPickHero')
    PrintTable(keys)
    local heroClass = keys.hero
    local heroEntity = EntIndexToHScript(keys.heroindex)
    local player = EntIndexToHScript(keys.player)

end

-- A player killed another player in a multi-team context
function FateGameMode:OnTeamKillCredit(keys)
  --  print ('[BAREBONES] OnTeamKillCredit')
    --PrintTable(keys)
    local p = keys.splitscreenplayer
    local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
    local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
    local numKills = keys.herokills
    local killerTeamNumber = keys.teamnumber
end

-- An entity died
function FateGameMode:OnEntityKilled( keys )
  --  print( '[BAREBONES] OnEntityKilled Called' )
    --PrintTable( keys )

    -- The Unit that was Killed
    --SendChatToPanorama("OEC ZERO")
    local killedUnit = EntIndexToHScript( keys.entindex_killed )
    -- The Killing entity
    local killerEntity = nil

    if not self.teama then
        self.teama = 1
    end

    if not self.teamb then
        self.teamb = 1
    end

    --SendChatToPanorama("OEC1")

    if keys.entindex_attacker ~= nil then
        killerEntity = EntIndexToHScript( keys.entindex_attacker )
    end
    --SendChatToPanorama("OEC2")
    -- Check if Caster(4th) is around and grant him 1 Madness
    if not string.match(killedUnit:GetUnitName(), "dummy") then
        local targets = FindUnitsInRadius(0, killedUnit:GetAbsOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
        for k,v in pairs(targets) do
            if v:GetName() == "npc_dota_hero_shadow_shaman" and not v:HasModifier("modifier_prelati_regen_block") then
                if killedUnit:IsHero() then
                    v:GiveMana(v:GetMaxMana())
                else
                    v:GiveMana(v:GetMaxMana() * 0.03)
                end
            --[[elseif v:GetName() == "npc_dota_hero_riki" and v:HasModifier("modifier_surgical_procedure") then
                v:Heal(killedUnit:GetMaxHealth() * 0.3, v)
                v:GiveMana((killedUnit:GetMaxMana() or 0) * 0.3)]]
            end
        end
    end
    --SendChatToPanorama("OEC3")
    -- Change killer to be owning hero
    if not killerEntity:IsHero() then
        --print("Killed by neutral unit")
        if IsValidEntity(killerEntity:GetPlayerOwner()) then
            killerEntity = killerEntity:GetPlayerOwner():GetAssignedHero()
        end
    end

    --SendChatToPanorama("OEC4")

    if killedUnit.IsNurseryClone then
        local nursery = killedUnit.NurseryRhyme
        if killerEntity:GetTeamNumber() == nursery:GetTeamNumber() then return end

        print("Handling NR Tempest Double")
        -- Distribute XP to allies
        local alliedHeroes = FindUnitsInRadius(killerEntity:GetTeamNumber(), killedUnit:GetAbsOrigin(), nil, 4000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
        local realHeroCount = 0
        for i=1, #alliedHeroes do
            if alliedHeroes[i]:IsHero() and alliedHeroes[i]:GetName() ~= "npc_dota_hero_wisp" then
                realHeroCount = realHeroCount + 1
            end
        end

        for i=1, #alliedHeroes do
            if alliedHeroes[i]:IsHero() and alliedHeroes[i]:GetName() ~= "npc_dota_hero_wisp" then
                local exp_bounty = (XP_BOUNTY_PER_LEVEL_TABLE[killedUnit:GetLevel()] / realHeroCount) * 0.5
                if killedUnit:IsHero() and killedUnit:GetLevel() > alliedHeroes[i]:GetLevel() then
                    local level_difference = killedUnit:GetLevel() - alliedHeroes[i]:GetLevel()
                    exp_bounty = exp_bounty * (level_difference * 0.03 + 1)
                end

                alliedHeroes[i]:AddExperience(exp_bounty/2, false, false)
            end
        end

        -- Give kill bounty
        local bounty = (BOUNTY_PER_LEVEL_TABLE[killedUnit:GetLevel()]) * 0.5

        killerEntity:ModifyGold(bounty , false, 0)
        -- if killer has Golden Rule attribute, grant 50% more gold
        if killerEntity:FindAbilityByName("gilgamesh_golden_rule") and killerEntity:FindAbilityByName("gilgamesh_golden_rule"):GetLevel() == 2 then
            killerEntity:ModifyGold(BOUNTY_PER_LEVEL_TABLE[killedUnit:GetLevel()] / 2, false, 0)
        end
        --Granting XP to all heroes who assisted
        local assistTable = {}
        local allHeroes = HeroList:GetAllHeroes()
        for _,atker in pairs( allHeroes ) do
            for i = 0, killedUnit:GetNumAttackers() - 1 do
                local attackerID = killedUnit:GetAttacker( i )
                if atker:GetPlayerID() == attackerID then
                    local assister = PlayerResource:GetSelectedHeroEntity(attackerID)
                    if atker:GetTeam() == assister:GetTeam() and assister ~= killerEntity then
                        table.insert(assistTable, assister)
                        assister.ServStat:onAssist()
                        assister:ModifyGold(400 , false, 0)
                        local goldPopupFx = ParticleManager:CreateParticleForPlayer("particles/custom/system/gold_popup.vpcf", PATTACH_CUSTOMORIGIN, nil, assister:GetPlayerOwner())
                        ParticleManager:SetParticleControl( goldPopupFx, 0, killedUnit:GetAbsOrigin())
                        ParticleManager:SetParticleControl( goldPopupFx, 1, Vector(10,300,0))
                        ParticleManager:SetParticleControl( goldPopupFx, 2, Vector(3,#tostring(bounty)+1, 0))
                        ParticleManager:SetParticleControl( goldPopupFx, 3, Vector(255, 200, 33))
                    end
                end
            end
        end

        return
    end
    --SendChatToPanorama("OEC5")

    if killedUnit:IsRealHero() then
        --SendChatToPanorama("OEC6")
        if killedUnit:GetTeamNumber() == 2 then
            self.teama = self.teama + 1
            Timers:CreateTimer(3.5, function()
                self.teama = self.teama - 1
            end)
        else
            self.teamb = self.teamb + 1
            Timers:CreateTimer(3.5, function()
                self.teamb = self.teamb - 1
            end)
        end
        --SendChatToPanorama("OEC7")
        if self.teama > 4 or self.teamb > 4 then
            LoopOverPlayers(function(player, playerID, playerHero)
                    if playerHero.clown_announcer == true then
                        CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="astronomia"})
                    end
                end)
        end
        self.bIsCasuallyOccured = true -- someone died this round
        killedUnit:SetTimeUntilRespawn(killedUnit:GetLevel() + 3)
        -- if killed by illusion, change the killer to the owner of illusion instead
        if killerEntity:IsIllusion() then
            killerEntity = PlayerResource:GetPlayer(killerEntity:GetPlayerID()):GetAssignedHero()
        end
        --SendChatToPanorama("OEC8")

        -- if TK occured, do nothing and announce it
        if killerEntity:GetTeam() == killedUnit:GetTeam() then
            killerEntity.ServStat:onTeamKill()
            killedUnit.ServStat:onDeath()
            --GameRules:SendCustomMessage("<font color='#FF5050'>" .. killerEntity.name .. "</font> has slain friendly Servant <font color='#FF5050'>" .. killedUnit.name .. "</font>!", 0, 0)
            CustomGameEventManager:Send_ServerToAllClients( "fate_hero_killed", {killer=killerEntity:entindex(), victim=killedUnit:entindex(), assists=nil } )
        else
            killerEntity.ServStat:onKill()
            killedUnit.ServStat:onDeath()
            --SendChatToPanorama("OEC9")
            -- Add to death count
            if killedUnit.DeathCount == nil then
                killedUnit.DeathCount = 1
            elseif killedUnit:GetName() == "npc_dota_hero_doom_bringer" then
                if not killedUnit.bIsGHReady or IsTeamWiped(killedUnit) or killedUnit.GodHandStock == 0 then
                    killedUnit.DeathCount = killedUnit.DeathCount + 1
                end
            else
                killedUnit.DeathCount = killedUnit.DeathCount + 1
            end

            --SendChatToPanorama("OEC10")            

            -- check if unit can receive a shard
            if(_G.GameMap == "fate_ffa" ) then
                if killedUnit.DeathCount == 7 then
                    if killedUnit.ShardAmount == nil then
                        killedUnit.ShardAmount = 1
                        killedUnit.DeathCount = 0
                    else
                        killedUnit.ShardAmount = killedUnit.ShardAmount + 1
                        killedUnit.DeathCount = 0
                    end
                    local statTable = CreateTemporaryStatTable(killedUnit)
                    CustomGameEventManager:Send_ServerToPlayer( killedUnit:GetPlayerOwner(), "servant_stats_updated", statTable ) -- Send the current stat info to JS
                end
            end
             
            --SendChatToPanorama("OEC11")
            -- Distribute XP to allies
            local alliedHeroes = FindUnitsInRadius(killerEntity:GetTeamNumber(), killedUnit:GetAbsOrigin(), nil, 4000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
            local realHeroCount = 0
            for i=1, #alliedHeroes do
                if alliedHeroes[i]:IsHero() and alliedHeroes[i]:GetName() ~= "npc_dota_hero_wisp" then
                    realHeroCount = realHeroCount + 1
                end
            end
            --SendChatToPanorama("OEC12")

            for i=1, #alliedHeroes do
                if alliedHeroes[i]:IsHero() and alliedHeroes[i]:GetName() ~= "npc_dota_hero_wisp" then
                    local exp_bounty = XP_BOUNTY_PER_LEVEL_TABLE[killedUnit:GetLevel()] / realHeroCount

                    --print("Base Bounty: " .. exp_bounty)
                    if killedUnit:IsHero() and killedUnit:GetLevel() > alliedHeroes[i]:GetLevel() then
                        local level_difference = killedUnit:GetLevel() - alliedHeroes[i]:GetLevel()
                        exp_bounty = exp_bounty * (level_difference * 0.03 + 1)
                        --print("Bounty multiplier after: " .. exp_bounty)
                    end

                    alliedHeroes[i]:AddExperience(exp_bounty/2, false, false)
                end
            end
            --SendChatToPanorama("OEC13")

            -- Give kill bounty
            local bounty = BOUNTY_PER_LEVEL_TABLE[killedUnit:GetLevel()]

            if _G.FIRST_BLOOD_TRIGGERED == false then
                _G.FIRST_BLOOD_TRIGGERED = true

                bounty = bounty + 500
            end

            killerEntity:ModifyGold(bounty , false, 0)
            -- if killer has Golden Rule attribute, grant 50% more gold
            if killerEntity:FindAbilityByName("gilgamesh_golden_rule") and killerEntity:FindAbilityByName("gilgamesh_golden_rule"):GetLevel() == 2 then
                killerEntity:ModifyGold(BOUNTY_PER_LEVEL_TABLE[killedUnit:GetLevel()] / 2, false, 0)
            end
            --SendChatToPanorama("OEC14")
            --Granting XP to all heroes who assisted
            local assistTable = {}
            local allHeroes = HeroList:GetAllHeroes()
            for _,atker in pairs( allHeroes ) do
                for i = 0, killedUnit:GetNumAttackers() - 1 do
                    local attackerID = killedUnit:GetAttacker( i )
                    if atker:GetPlayerID() == attackerID then
                        local assister = PlayerResource:GetSelectedHeroEntity(attackerID)
                        if atker:GetTeam() == assister:GetTeam() and assister ~= killerEntity then
                            table.insert(assistTable, assister)
                            assister.ServStat:onAssist()
                            assister:ModifyGold(400 , false, 0)
                            local goldPopupFx = ParticleManager:CreateParticleForPlayer("particles/custom/system/gold_popup.vpcf", PATTACH_CUSTOMORIGIN, nil, assister:GetPlayerOwner())
                            --local goldPopupFx = ParticleManager:CreateParticleForTeam("particles/custom/system/gold_popup.vpcf", PATTACH_CUSTOMORIGIN, nil, killerEntity:GetTeamNumber())
                            ParticleManager:SetParticleControl( goldPopupFx, 0, killedUnit:GetAbsOrigin())
                            ParticleManager:SetParticleControl( goldPopupFx, 1, Vector(10,400,0))
                            ParticleManager:SetParticleControl( goldPopupFx, 2, Vector(3,#tostring(bounty)+1, 0))
                            ParticleManager:SetParticleControl( goldPopupFx, 3, Vector(255, 200, 33))
                        end
                    end
                end
            end
            --SendChatToPanorama("OEC15")
            --print("Player collected bounty : " .. bounty - killedUnit:GetGoldBounty())
            -- Create gold popup
            if killerEntity:GetPlayerOwner() ~= nil then
                local goldPopupFx = ParticleManager:CreateParticleForPlayer("particles/custom/system/gold_popup.vpcf", PATTACH_CUSTOMORIGIN, nil, killerEntity:GetPlayerOwner())
                --local goldPopupFx = ParticleManager:CreateParticleForTeam("particles/custom/system/gold_popup.vpcf", PATTACH_CUSTOMORIGIN, nil, killerEntity:GetTeamNumber())
                ParticleManager:SetParticleControl( goldPopupFx, 0, killedUnit:GetAbsOrigin())
                ParticleManager:SetParticleControl( goldPopupFx, 1, Vector(10,bounty,0))
                ParticleManager:SetParticleControl( goldPopupFx, 2, Vector(3,#tostring(bounty)+1, 0))
                ParticleManager:SetParticleControl( goldPopupFx, 3, Vector(255, 200, 33))
            end

            -- Display gold message
            local assistString = "plus <font color='#FFFF66'>" .. #assistTable * 400 .. "</font> gold split between contributors!"
            --GameRules:SendCustomMessage("<font color='#FF5050'>" .. killerEntity.name .. "</font> has slain <font color='#FF5050'>" .. killedUnit.name .. "</font> for <font color='#FFFF66'>" .. bounty .. "</font> gold, " .. assistString, 0, 0)
            -- Convert to entindex before sending kill event to panorama
            for i=1, #assistTable do
                assistTable[i] = assistTable[i]:entindex()
            end
            CustomGameEventManager:Send_ServerToAllClients( "fate_hero_killed", {killer=killerEntity:entindex(), victim=killedUnit:entindex(), assists=assistTable } )


            --[[-- Give assist bounty
            for k, _ in pairs(killedUnit.assistTable) do
                if k:GetTeam() == killerEntity:GetTeam() then
                    k:ModifyGold(300 , true, 0)
                    local goldPopupFx = ParticleManager:CreateParticleForPlayer("particles/custom/system/gold_popup.vpcf", PATTACH_CUSTOMORIGIN, nil, k:GetPlayerOwner())
                    --local goldPopupFx = ParticleManager:CreateParticleForTeam("particles/custom/system/gold_popup.vpcf", PATTACH_CUSTOMORIGIN, nil, killerEntity:GetTeamNumber())
                    ParticleManager:SetParticleControl( goldPopupFx, 0, killedUnit:GetAbsOrigin())
                    ParticleManager:SetParticleControl( goldPopupFx, 1, Vector(10,300,0))
                    ParticleManager:SetParticleControl( goldPopupFx, 2, Vector(3,#tostring(bounty)+1, 0))
                    ParticleManager:SetParticleControl( goldPopupFx, 3, Vector(255, 200, 33))
                end
            end]]


        end

        --SendChatToPanorama("OEC16")

        -- Need condition check for GH
        --if killedUnit:GetName() == "npc_dota_hero_doom_bringer" and killedUnit:GetPlayerOwner().IsGodHandAcquired then

        if _G.GameMap == "fate_trio_rumble_3v3v3v3" or _G.GameMap == "fate_ffa" then
            --print(PlayerResource:GetTeamKills(killerEntity:GetTeam()))
            --print(VICTORY_CONDITION)
            VICTORY_CONDITION = 30
            if PlayerResource:GetTeamKills(killerEntity:GetTeam()) >= VICTORY_CONDITION then
                GameRules:SetSafeToLeave( true )
                GameRules:SetGameWinner( killerEntity:GetTeam() )
            end
        elseif _G.GameMap == "fate_elim_6v6" or _G.GameMap == "fate_elim_7v7" or _G.GameMap == "fate_elim_7v7_test" or _G.GameMap =="anime_fate_7vs7_beta" or _G.GameMap =="7vs7_common" or _G.GameMap =="7vs7_draft" then
            if killedUnit:GetTeam() == DOTA_TEAM_GOODGUYS and killedUnit:IsRealHero() then
                self.nRadiantDead = self.nRadiantDead + 1
            else
                self.nDireDead = self.nDireDead + 1
            end
            --SendChatToPanorama("OEC17")

            local nRadiantAlive = 0
            local nDireAlive = 0
            self:LoopOverPlayers(function(player, playerID, playerHero)
                if playerHero:IsAlive() then
                    if playerHero:GetTeam() == DOTA_TEAM_GOODGUYS then
                        nRadiantAlive = nRadiantAlive + 1
                    else
                        nDireAlive = nDireAlive + 1
                    end
                end
            end)
            --print(_G.CurrentGameState)
            -- check for game state before deciding round
            if _G.CurrentGameState ~= "FATE_POST_ROUND" and not _G.LaPucelleActivated then
                if nRadiantAlive == 0 and nDireAlive ~= 0 then
                    --print("All Radiant heroes eliminated, removing existing timers and declaring winner...")

                    Timers:RemoveTimer('round_timer')
                    Timers:RemoveTimer('alertmsg')
                    Timers:RemoveTimer('alertmsg2')
                    Timers:RemoveTimer('timeoutmsg')
                    Timers:RemoveTimer('presence_alert')
                    --SendChatToPanorama("OEC18")
                    self:FinishRound(false, 1)
                elseif nDireAlive == 0 and nRadiantAlive ~= 0 then
                    --print("All Dire heroes eliminated, removing existing timers and declaring winner...")

                    Timers:RemoveTimer('round_timer')
                    Timers:RemoveTimer('alertmsg')
                    Timers:RemoveTimer('alertmsg2')
                    Timers:RemoveTimer('timeoutmsg')
                    Timers:RemoveTimer('presence_alert')
                    --SendChatToPanorama("OEC18")
                    self:FinishRound(false, 0)
                elseif nDireAlive == 0 and nRadiantAlive == 0 then
                    --SendChatToPanorama("OEC18")
                    self:FinishRound(false, 2)
                --[[else
                    if self.nRadiantScore + 1 < self.nDireScore                            
                        then self:FinishRound(false,3)
                    -- Default Dire Win
                    elseif self.nRadiantScore > self.nDireScore + 1
                        then  self:FinishRound(false,4)
                    -- Draw
                    else                    
                        self:FinishRound(false, 2)
                    end]]
                end
            end
        end        
    end
end

function OnVoteFinished(Index,keys)
    print("[FateGameMode]vote finished by player with result :" .. keys.killsVoted)
    local voteResult = keys.killsVoted
    voteResultTable[voteResult] = voteResultTable[voteResult] + 1
    --[[if voteResult == 1 then
        voteResultTable.v_OPTION_1 = voteResultTable.v_OPTION_1+1
    elseif voteResult == 2 then
        voteResultTable.v_OPTION_2 = voteResultTable.v_OPTION_2+1
    elseif voteResult == 3 then
        voteResultTable.v_OPTION_3 = voteResultTable.v_OPTION_3+1
    elseif voteResult == 4 then
        voteResultTable.v_OPTION_4 = voteResultTable.v_OPTION_4+1
    elseif voteResult == 5 then
        voteResultTable.v_OPTION_5 = voteResultTable.v_OPTION_5+1
    end]]
end

function OnDirectTransferChanged(Index, keys)
    local playerID = keys.player
    local transferEnabled = keys.directTransfer

    PlayerResource:GetPlayer(playerID):GetAssignedHero().bIsDirectTransferEnabled = transferEnabled
    print("Direct tranfer set to " .. transferEnabled .. " for " .. PlayerResource:GetPlayer(playerID):GetAssignedHero():GetName())
end


function OnServantCustomizeActivated(Index, keys)
    local caster = EntIndexToHScript(keys.unitEntIndex)
    local ability = EntIndexToHScript(keys.abilEntIndex)
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    local behav_string = tostring(ability:GetBehavior())
    if behav_string ~= "6293508" then
        return
    end
    if ability:GetManaCost(1) > caster:GetMana() then
        SendErrorMessage(hero:GetPlayerOwnerID(), "#Not_Enough_Master_Mana")
        return
    end
    if ability:IsCooldownReady() == false then
        return
    end
    caster:CastAbilityImmediately(ability, caster:GetPlayerOwnerID())
    local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable ) -- Send the current stat info to JS

    hero:EmitSound("Item.DropGemWorld")
    local tomeFx = ParticleManager:CreateParticle("particles/units/heroes/hero_silencer/silencer_global_silence_sparks.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
    ParticleManager:SetParticleControl(tomeFx, 1, hero:GetAbsOrigin())

    --EmitSoundOnLocationForAllies(hero:GetAbsOrigin(), "Item.PickUpGemShop", hero)

    --ability:StartCooldown(ability:GetCooldown(1))
    --caster:SetMana(caster:GetMana() - ability:GetManaCost(1))
end

function OnConfig1Checked(index, keys)
    local playerID = EntIndexToHScript(keys.player)
    local hero = PlayerResource:GetPlayer(keys.player):GetAssignedHero()
    if keys.bOption == 1 then hero.bIsAutoGoldRequestOn = true else hero.bIsAutoGoldRequestOn = false end
end

function OnConfig2Checked(index, keys)
    local playerID = EntIndexToHScript(keys.player)
    local hero = PlayerResource:GetPlayer(keys.player):GetAssignedHero()
    if keys.bOption == 1 then hero.bIsDmgPopupDisabled = true else hero.bIsDmgPopupDisabled = false end
end

function OnConfig4Checked(index, keys)
    local playerID = EntIndexToHScript(keys.player)
    local hero = PlayerResource:GetPlayer(keys.player):GetAssignedHero()
    if keys.bOption == 1 then hero.bIsAlertSoundDisabled = true else hero.bIsAlertSoundDisabled = false end
end

function OnConfig9Checked(index, keys)
    local playerID = EntIndexToHScript(keys.player)
    local ply = PlayerResource:GetPlayer(keys.player)
    local hero = PlayerResource:GetPlayer(keys.player):GetAssignedHero()
    if keys.bOption == 1 then ply.AutoTransferItemEnabled = true else ply.AutoTransferItemEnabled = false end
end

function OnHeroClicked(Index, keys)
    local playerID = EntIndexToHScript(keys.player)
    local hero = PlayerResource:GetPlayer(keys.player):GetAssignedHero()


    if hero.IsIntegrated or hero.IsMounted then
        -- Find the transport
        local units = FindUnitsInRadius(hero:GetTeam(), hero:GetAbsOrigin(), nil, 100, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
        for k,v in pairs(units) do
            local unitname = v:GetUnitName()
            if hero:IsAlive() and v:IsAlive() then
                if unitname == "caster_5th_ancient_dragon" or unitname == "gille_gigantic_horror" then
                    local playerData = {
                        transport = v:entindex()
                    }
                    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "player_selected_hero_in_transport", playerData )
                    return
                end
            end
        end
    end
end

-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function FateGameMode:InitGameMode()
    FateGameMode = self
    local hGameModeEntity = GameRules:GetGameModeEntity()
    hGameModeEntity:SetGiveFreeTPOnDeath(false)
    
    -- Find out which map we are using
    _G.GameMap = GetMapName()
    if _G.GameMap == "fate_elim_6v6" then
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 6)
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 6)
        GameRules:SetHeroRespawnEnabled(false)
        GameRules:SetGoldPerTick(0)
        GameRules:SetStartingGold(0)    

    elseif _G.GameMap == "fate_elim_7v7" or _G.GameMap == "fate_elim_7v7_test" or _G.GameMap == "anime_fate_7vs7_beta" or _G.GameMap =="7vs7_common" or _G.GameMap =="7vs7_draft" then
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 7)
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 7)
        GameRules:SetHeroRespawnEnabled(false)
        GameRules:SetGoldPerTick(0)
        GameRules:SetStartingGold(0)    

    elseif _G.GameMap == "fate_trio_rumble_3v3v3v3" then
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 3)
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 3)
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 3)
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_2, 3)
        GameRules:SetGoldPerTick(7.5)
        GameRules:SetStartingGold(0)  


    elseif _G.GameMap == "fate_ffa" then
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_2, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_3, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_4, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_5, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_6, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_7, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_8, 1 )
        GameRules:SetGoldPerTick(7.5)
        GameRules:SetStartingGold(0)    
    end
    -- Set game rules
    GameRules:SetUseUniversalShopMode(true)
    GameRules:SetSameHeroSelectionEnabled(true)
    GameRules:GetGameModeEntity():SetCustomGameForceHero("npc_dota_hero_wisp")
    --GameRules:SetHeroSelectionTime(0)
    GameRules:SetPreGameTime(10)
    GameRules:SetShowcaseTime(0)
    GameRules:SetStrategyTime(IsInToolsMode() and 3 or 0)
    GameRules:SetUseCustomHeroXPValues(true)
    GameRules:SetUseBaseGoldBountyOnHeroes(false)
    GameRules:SetCustomGameSetupTimeout(20)
    GameRules:SetFirstBloodActive(false)
    GameRules:SetCustomGameEndDelay(30)
    GameRules:SetCustomVictoryMessageDuration(30)
    GameRules:SetCustomGameSetupAutoLaunchDelay(IsInToolsMode() and 3 or 30)
    GameRules:SetCustomGameAllowBattleMusic( false )
    GameRules:SetCustomGameAllowHeroPickMusic( false )
    GameRules:SetCustomGameAllowMusicAtGameStart( false )
    if IsInToolsMode() then
        SendToServerConsole( "dota_easybuy 1" )
    end

    hGameModeEntity:SetControlFateMechanic( true )
    hGameModeEntity:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_ARMOR, 0.2)
    hGameModeEntity:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_ATTACK_SPEED , 2)
    hGameModeEntity:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP, 9)
    --GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP_REGEN_PERCENT, 0)
    --GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_STATUS_RESISTANCE_PERCENT, 0)
    --GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_MAGIC_RESISTANCE_PERCENT, 0)  
    --GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_MOVE_SPEED_PERCENT, 0)
    --GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MANA_REGEN_PERCENT, 0)
    --GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MAGIC_RESISTANCE_PERCENT, 0)    
    --GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_, 0)

    -- Random seed for RNG
    local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
    math.randomseed(tonumber(timeTxt))

    -- Event Hooks
    ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(FateGameMode, 'OnPlayerLevelUp'), self)
    --ListenToGameEvent('dota_ability_channel_finished', Dynamic_Wrap(FateGameMode, 'OnAbilityChannelFinished'), self)
    ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(FateGameMode, 'OnPlayerLearnedAbility'), self)
    ListenToGameEvent('entity_killed', Dynamic_Wrap(FateGameMode, 'OnEntityKilled'), self)
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(FateGameMode, 'OnConnectFull'), self)
    ListenToGameEvent('player_disconnect', Dynamic_Wrap(FateGameMode, 'OnDisconnect'), self)
    ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(FateGameMode, 'OnItemPurchased'), self)
    ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(FateGameMode, 'OnItemPickedUp'), self)
    --ListenToGameEvent('dota_inventory_player_got_item', Dynamic_Wrap(FateGameMode, 'OnItemAdded'), self)
    --ListenToGameEvent('last_hit', Dynamic_Wrap(FateGameMode, 'OnLastHit'), self)
    --ListenToGameEvent('dota_non_player_used_ability', Dynamic_Wrap(FateGameMode, 'OnNonPlayerUsedAbility'), self)
    ListenToGameEvent('player_changename', Dynamic_Wrap(FateGameMode, 'OnPlayerChangedName'), self)
    --ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(FateGameMode, 'OnRuneActivated'), self)
    --ListenToGameEvent('dota_player_take_tower_damage', Dynamic_Wrap(FateGameMode, 'OnPlayerTakeTowerDamage'), self)
    --ListenToGameEvent('tree_cut', Dynamic_Wrap(FateGameMode, 'OnTreeCut'), self)
    ListenToGameEvent('entity_hurt', Dynamic_Wrap(FateGameMode, 'OnEntityHurt'), self)
    ListenToGameEvent('player_connect', Dynamic_Wrap(FateGameMode, 'PlayerConnect'), self)
    ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(FateGameMode, 'OnAbilityUsed'), self)
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(FateGameMode, 'OnGameRulesStateChange'), self)
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(FateGameMode, 'OnNPCSpawned'), self)
    ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(FateGameMode, 'OnPlayerPickHero'), self)
    ListenToGameEvent('dota_team_kill_credit', Dynamic_Wrap(FateGameMode, 'OnTeamKillCredit'), self)
    ListenToGameEvent("player_reconnected", Dynamic_Wrap(FateGameMode, 'OnPlayerReconnect'), self)
    ListenToGameEvent('player_chat', Dynamic_Wrap(FateGameMode, 'OnPlayerChat'), self)
    --ListenToGameEvent('player_spawn', Dynamic_Wrap(FateGameMode, 'OnPlayerSpawn'), self)
    --ListenToGameEvent('dota_unit_event', Dynamic_Wrap(FateGameMode, 'OnDotaUnitEvent'), self)
    --ListenToGameEvent('nommed_tree', Dynamic_Wrap(FateGameMode, 'OnPlayerAteTree'), self)
    --ListenToGameEvent('player_completed_game', Dynamic_Wrap(FateGameMode, 'OnPlayerCompletedGame'), self)
    --ListenToGameEvent('dota_match_done', Dynamic_Wrap(FateGameMode, 'OnDotaMatchDone'), self)
    --ListenToGameEvent('dota_combatlog', Dynamic_Wrap(FateGameMode, 'OnCombatLogEvent'), self)
    --ListenToGameEvent('dota_player_killed', Dynamic_Wrap(FateGameMode, 'OnPlayerKilled'), self)
    --ListenToGameEvent('player_team', Dynamic_Wrap(FateGameMode, 'OnPlayerTeam'), self)

    -- For models swapping
    ListenToGameEvent( 'npc_spawned', Dynamic_Wrap( FateGameMode, 'OnHeroSpawned' ), self )
    -- Listen to vote result
    CustomGameEventManager:RegisterListener( "vote_finished", OnVoteFinished )
    CustomGameEventManager:RegisterListener( "direct_transfer_changed", OnDirectTransferChanged )
    CustomGameEventManager:RegisterListener( "servant_customize", OnServantCustomizeActivated )
    CustomGameEventManager:RegisterListener( "check_hero_in_transport", OnHeroClicked )
    CustomGameEventManager:RegisterListener( "config_option_1_checked", OnConfig1Checked )
    CustomGameEventManager:RegisterListener( "config_option_2_checked", OnConfig2Checked )
    CustomGameEventManager:RegisterListener( "config_option_4_checked", OnConfig4Checked )
    CustomGameEventManager:RegisterListener( "config_option_9_checked", OnConfig9Checked )
    -- CustomGameEventManager:RegisterListener( "player_chat_panorama", OnPlayerChat )
    CustomGameEventManager:RegisterListener( "player_alt_click", OnPlayerAltClick )
    CustomGameEventManager:RegisterListener("player_remove_buff", OnPlayerRemoveBuff )
    CustomGameEventManager:RegisterListener("player_cast_seal", OnPlayerCastSeal )
    CustomGameEventManager:RegisterListener("player_seal_1", OnPlayerCastSeal1 )
    CustomGameEventManager:RegisterListener("player_seal_2", OnPlayerCastSeal2 )
    CustomGameEventManager:RegisterListener("player_seal_3", OnPlayerCastSeal3 )
    CustomGameEventManager:RegisterListener("player_seal_4", OnPlayerCastSeal4 )
    CustomGameEventManager:RegisterListener("player_seal_5", OnPlayerCastSeal5 )
    CustomGameEventManager:RegisterListener("player_seal_6", OnPlayerCastSeal6 )
    -- LUA modifiers
    LinkLuaModifier("modifier_ms_cap", "modifiers/modifier_ms_cap", LUA_MODIFIER_MOTION_NONE)


    --for fixing some nasty bugs with medea, tpscrolls and other possible item limit thingies
    Convars:SetInt("dota_max_physical_items_purchase_limit", 75)

    Events:Emit("activate")

    PlayerTables:CreateTable("arena", {}, AllPlayersInterval)
    PlayerTables:CreateTable("player_hero_indexes", {}, AllPlayersInterval)
    PlayerTables:CreateTable("players_abandoned", {}, AllPlayersInterval)
    PlayerTables:CreateTable("gold", {}, AllPlayersInterval)
    PlayerTables:CreateTable("weather", {}, AllPlayersInterval)
    PlayerTables:CreateTable("disable_help_data", {[0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {}, [7] = {}, [8] = {}, [9] = {}, [10] = {}, [11] = {}, [12] = {}, [13] = {}, [14] = {}, [15] = {}, [16] = {}, [17] = {}, [18] = {}, [19] = {}, [20] = {}, [21] = {}, [22] = {}, [23] = {}}, AllPlayersInterval)


    -- Commands can be registered for debugging purposes or as functions that can be called by the custom Scaleform UI
    Convars:RegisterCommand( "command_example", Dynamic_Wrap(FateGameMode, 'ExampleConsoleCommand'), "A console command example", 0 )
    function FateGameMode:ExampleConsoleCommand()
    end

    --[[-- Convars:RegisterCommand( "player_say", Dynamic_Wrap(FateGameMode, 'PlayerSay'), "Reads player chat", 0)
    Convars:RegisterCommand('player_say', function(...)
        local arg = {...}
        table.remove(arg,1)
        local cmdPlayer = Convars:GetCommandClient()
        keys = {}
        keys.ply = cmdPlayer
        keys.text = table.concat(arg, " ")
        self:PlayerSay(keys)
    end, "Player said something", 0)]]

    -- Initialized tables for tracking state
    self.nRadiantScore = 0
    self.nDireScore = 0

    self.nCurrentRound = 0
    self.nRadiantDead = 0
    self.nDireDead = 0
    self.nLastKilled = nil
    self.fRoundStartTime = 0

    self.bIsCasualtyOccured = false

    -- userID map
    self.vUserNames = {}
    self.vPlayerList = {}
    self.vSteamIds = {}
    self.vBots = {}
    self.vBroadcasters = {}

    self.vPlayers = {}
    self.vRadiant = {}
    self.vDire = {}

    self.vPlayerShield = {}
    --IsFirstSeal = {}

    self.bSeenWaitForPlayers = false
    -- Active Hero Map
    self.vPlayerHeroData = {}
    self.bPlayersInit = false
end

function CountdownTimer()
    nCountdown = nCountdown + 1
    local t = nCountdown

    local minutes = math.floor(t / 60)
    local seconds = t - (minutes * 60)
    local m10 = math.floor(minutes / 10)
    local m01 = minutes - (m10 * 10)
    local s10 = math.floor(seconds / 10)
    local s01 = seconds - (s10 * 10)
    local broadcast_gametimer =
        {
            timer_minute_10 = m10,
            timer_minute_01 = m01,
            timer_second_10 = s10,
            timer_second_01 = s01,
        }
    CustomGameEventManager:Send_ServerToAllClients( "timer_think", broadcast_gametimer )
end

---------------------------------------------------------------------------
-- A timer that thinks every second
---------------------------------------------------------------------------
function FateGameMode:OnGameTimerThink()
    -- Stop thinking if game is paused
    if GameRules:IsGamePaused() == true then
        return 1
    end
    CountdownTimer()
    return 1
end

function FateGameMode:ModifyGoldFilter(filterTable)
    -- Disable gold gain from hero kills
    --local hero = PlayerResource:GetSelectedHeroEntity(filterTable.player_id_const)
    --local leaverCount = HasLeaversInTeam(hero)

    if filterTable["reason_const"] == DOTA_ModifyGold_HeroKill then
        filterTable["gold"] = 0
        return false
    end

    -- filterTable["gold"] = filterTable["gold"] + filterTable["gold"] * (0.15 * leaverCount)
    return true
end

function FateGameMode:ModifyExperienceFilter(filterTable)
    --[[local hero = PlayerResource:GetSelectedHeroEntity(filterTable.player_id_const)
    local leaverCount = HasLeaversInTeam(hero)

    filterTable["experience"] = filterTable["experience"] + filterTable["experience"] * (0.15 * leaverCount)]]
    return true
end

function FateGameMode:TakeDamageFilter(filterTable)
    local damage = filterTable.damage
    local damageType = filterTable.damagetype_const

    if not filterTable.entindex_attacker_const then
        return
    end

    if damage == 0 then return end

    local attacker = EntIndexToHScript(filterTable.entindex_attacker_const)
    local inflictor = nil
    if filterTable.entindex_inflictor_const then
        inflictor = EntIndexToHScript(filterTable.entindex_inflictor_const) -- the skill name
    end
    local victim = EntIndexToHScript(filterTable.entindex_victim_const)

    if attacker:HasModifier("modifier_love_spot_charmed") and victim:GetName() == "npc_dota_hero_huskar" then
        local loveSpotAbil = victim:FindAbilityByName("diarmuid_love_spot")
        local reduction = loveSpotAbil:GetLevelSpecialValueFor("damage_reduction", loveSpotAbil:GetLevel() - 1)
        filterTable.damage = filterTable.damage/100 * (100-reduction)
        damage = damage/100 * (100-reduction)
    end
    
    -- Functionality for the False Promise part of NR's new ult.
    --[[if victim:HasModifier("modifier_qgg_oracle") then
        local hModifier = victim:FindModifierByName("modifier_qgg_oracle")
        local tInfo = { hAttacker = attacker, fDamage = damage, eDamageType = damageType }
        tInfo.hAbility = inflictor
        table.insert(hModifier.tDamageInstances, tInfo)
        return false
    end]]

    -- if Nursery Rhyme's Doppelganger is attemping to deal lethal damage
    if inflictor and inflictor:GetName() == "nursery_rhyme_doppelganger" and damage > victim:GetHealth() then
        --print("no u cant kill")
        victim:SetHealth(100000)
        victim.bIsInvulDuetoDoppel = true
    end
    if not attacker.bIsDmgPopupDisabled then
        if damageType == 1 or damageType == 2 or damageType == 4 then
            PopupDamage(victim, math.floor(damage), Vector(255,255,255), damageType)
        end
    end
    return true
end

function FateGameMode:ExecuteProjectileFilter(hFilterTable)
    if not IsServer() then return end 
    if(hFilterTable.is_attack == 1 and hFilterTable.entindex_source_const == self.gilEntIndex ) then return false end
    if (hFilterTable.entindex_source_const == self.emiyaEntIndex and  EntIndexToHScript(self.emiyaEntIndex):HasModifier("modifier_unlimited_bladeworks") and hFilterTable.is_attack == 1 )  then return false end
    return true
end

function FateGameMode:ExecuteOrderFilter(hFilterTable)
    local hAbility     = EntIndexToHScript(hFilterTable.entindex_ability)
    local iSequenceNum = hFilterTable.sequence_number_const
    local IsQueue      = hFilterTable.queue >= 1
    local hUnits       = hFilterTable.units
    local hTarget      = EntIndexToHScript(hFilterTable.entindex_target)
    local vPosition    = Vector(hFilterTable.position_x, hFilterTable.position_y, hFilterTable.position_z)
    local iOrder       = hFilterTable.order_type
    local iPlayerID    = hFilterTable.issuer_player_id_const
 
    local hUnit = hUnits["0"]
          hUnit = type(hUnit) == "number" 
                  and EntIndexToHScript(hUnit) 
                  or nil

    if IsNotNull(hUnit) then
        if IsNotNull(AnimeVectorTargeting) then
            AnimeVectorTargeting:UpdateAnimeVectorTargetingAbility(hAbility, hUnit, hTarget, vPosition, iOrder)
        end

        --[[local CANT_PROCESS =    {
                                    [DOTA_UNIT_ORDER_CAST_POSITION]          = true,
                                    [DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION] = true,
                                    [DOTA_UNIT_ORDER_CAST_TARGET]            = true,
                                    [DOTA_UNIT_ORDER_CAST_TARGET_TREE]       = true,
                                    [DOTA_UNIT_ORDER_CAST_RUNE]              = true
                                }

        if CANT_PROCESS[iOrder] then
            if iOrder ~= DOTA_UNIT_ORDER_CAST_POSITION 
                and IsNotNull(hTarget) 
                and type(hTarget.GetOrigin) == "function" then
                vPosition = hTarget:GetOrigin()
            end

            if ( not IsInMarbleSphere({hUnit}) and IsInMarbleSphere({vPosition}) ) or ( not IsInMarbleSphere({vPosition}) and IsInMarbleSphere({hUnit}) ) then
                return false
            end
        end]]
    end

    return FateGameMode:ExecuteOrderFilterPepeg(hFilterTable)
end

function FateGameMode:ExecuteOrderFilterPepeg(filterTable)
    local ability = EntIndexToHScript(filterTable.entindex_ability) -- the handle of item
    local target = EntIndexToHScript(filterTable.entindex_target)
    local units = filterTable.units
    local targetIndex = filterTable.entindex_target-- the inventory target
    local playerID = filterTable.issuer_player_id_const
    local orderType = filterTable.order_type
    local xPos = tonumber(filterTable.position_x)
    local yPos = tonumber(filterTable.position_y)
    local zPos = tonumber(filterTable.position_z)
    local caster = nil
    if units["0"] then
        caster = EntIndexToHScript(units["0"])
    end
    -- Find items
    -- DOTA_UNIT_ORDER_PURASE_ITEM = 16
    -- DOTA_UNIT_ORDER_SELL_ITEM = 17
    -- DOTA_UNIT_ORDER_DISASSEMBLE_ITEM = 18
    -- DOTA_UNIT_ORDER_MOVE_ITEM = 19(drag and drop)

    -- attack command
    -- What do we do when handling the move between inventory and stash?
    --[[if orderType == 11 then
    end]]

    if orderType == DOTA_UNIT_ORDER_RADAR then
        return false
    end
    if orderType == 19 then
        local currentItemIndex, itemName = nil
        local charges = -1
        for i=0, 16 do
            if ability == caster:GetItemInSlot(i) then
                currentItemIndex = i
                itemName = ability:GetName()
                charges = ability:GetCurrentCharges()
                break
            end
        end
        caster:SwapItems(currentItemIndex, targetIndex)
        CheckItemCombination(caster)
        CheckItemCombinationInStash(caster)
        SaveStashState(caster)
        return false

    -- What do we do when item is bought?
    --elseif orderType == 16 then        
    -- What do we do when we sell items?
    elseif orderType == 17 then
        EmitSoundOnClient("General.Sell", caster:GetPlayerOwner())
        caster:ModifyGold(GetItemCost(ability:GetName()) *0.5, false , 0)
        ability:RemoveSelf()
        SaveStashState(caster)
        return false
    end

    if orderType == DOTA_UNIT_ORDER_CAST_POSITION then
        if ability:GetName() == "astolfo_hippogriff_raid" then
            local location = Vector(xPos, yPos, zPos)
            local origin = caster:GetAbsOrigin()
            
            if (location - origin):Length2D() <= ability:GetCastRange() then
                local facing = caster:GetForwardVector()
                local offset = origin + facing * 10

                filterTable.position_x = tostring(offset.x)
                filterTable.position_y = tostring(offset.y)
                filterTable.position_z = tostring(offset.z)
            end
            caster.HippogriffCastLocation = location
       end
    end
    return true
end

function FateGameMode:ItemAddedFilter(args)
    local item = EntIndexToHScript(args.item_entindex_const)
    if item:GetName() == "item_tpscroll" then return false end

    return true
end

function FateGameMode:InitializeRound()
    -- Flag game mode as pre round, and display tip
    _G.IsPreRound = true
    _G.LaPucelleActivated = false
    _G.FIRST_BLOOD_TRIGGERED = false
    --SendChatToPanorama("IR1")
    CreateUITimer("Pre-Round", PRE_ROUND_DURATION, "pregame_timer")
    --FireGameEvent('cgm_timer_display', { timerMsg = "Pre-Round", timerSeconds = 16, timerEnd = true, timerPosition = 0})
    --DisplayTip()
    GameRules:SendCustomMessage("Round "..self.nCurrentRound.." will begin in " .. PRE_ROUND_DURATION .. " seconds.", 0, 0)
    --Say(nil, string.format("Round %d will begin in " .. PRE_ROUND_DURATION .. " seconds.", self.nCurrentRound), false) -- Valve please

    local msg = {
        message = "Round " .. self.nCurrentRound .. " has begun!",
        duration = 4.0
    }
    local alertmsg = {
        message = "#Fate_Timer_30_Alert",
        duration = 4.0
    }
    local alertmsg2 = {
        message = "#Fate_Timer_10_Alert",
        duration = 4.0
    }
    local timeoutmsg = {
        message = "#Fate_Timer_Timeout",
        duration = 4.0
    }

    --SendChatToPanorama("IR2")

    -- Set up heroes for new round
    self:LoopOverPlayers(function(ply, plyID, playerHero)
        --SendChatToPanorama("IRL1"..plyID)
        local hero = playerHero

        if hero:GetName() == "npc_dota_hero_target_dummy" then return end
        --SendChatToPanorama("IRL2"..plyID)

        ResetAbilities(hero)
        ResetItems(hero)
        ResetMasterAbilities(hero)

        --SendChatToPanorama("IRL3"..plyID)
        
        hero:RemoveModifierByName("round_pause")
        RemoveTroublesomeModifiers(hero)
        giveUnitDataDrivenModifier(hero, hero, "round_pause", PRE_ROUND_DURATION) -- Pause all heroes
        --hero:SetGold(0, true)

        --SendChatToPanorama("IRL4"..plyID)

        if hero.ProsperityCount ~= nil then
            --hero.MasterUnit:SetMana(hero.MasterUnit:GetMana() + 1 * hero.ProsperityCount)
            hero.MasterUnit2:SetMana(hero.MasterUnit:GetMana())
            --print("granted more mana")
        end

        if hero.Level24Acquired then
            hero.MasterUnit:SetMana(hero.MasterUnit:GetMana() + 2)
            hero.MasterUnit2:SetMana(hero.MasterUnit2:GetMana() + 2)
        end

        --SendChatToPanorama("IRL5"..plyID)

        -- Grant gold
        if self.nCurrentRound > 1 then
            hero.CStock = 10
            if hero:GetGold() < 5000 then --
                --print("[FateGameMode] " .. hero:GetName() .. " gained 3000 gold at the start of round")
                --[[if hero.AvariceCount ~= nil then
                    hero:ModifyGold(3000 + hero.AvariceCount * 1500, false, 0)
                else]]
                    hero:ModifyGold(4000, false, 0)
                --end
            end
            if hero.AvariceCount ~= nil then
                hero:ModifyGold(3250*hero.AvariceCount, false, 0)
            end

            --local xpBonus = 100 + 

            hero:AddExperience(self.nCurrentRound * 100, false, false)
            if(hero.AvariceCount ~= nil) then
                --hero:AddExperience(self.nCurrentRound * 50 * hero.AvariceCount, false, false)
            end
        end
        --SendChatToPanorama("IRL6"..plyID)
    end)

    --SendChatToPanorama("IR3")


    Timers:CreateTimer('beginround', {
        endTime = PRE_ROUND_DURATION,
        callback = function()
            print("[FateGameMode]Round started.")
            --SendChatToPanorama("IRT1")
            _G.CurrentGameState = "FATE_ROUND_ONGOING"
            _G.IsPreRound = false
            _G.RoundStartTime = GameRules:GetGameTime()
            CreateUITimer(("Round " .. self.nCurrentRound), ROUND_DURATION, "round_timer" .. self.nCurrentRound)
            --SendChatToPanorama("IRT2")
            --FireGameEvent('cgm_timer_display', { timerMsg = ("Round " .. self.nCurrentRound), timerSeconds = 151, timerEnd = true, timerPosition = 0})
            --roundQuest = StartQuestTimer("roundTimerQuest", "Round " .. self.nCurrentRound, 150)

            self:LoopOverPlayers(function(player, playerID, playerHero)
                if playerHero:GetTeamNumber() == DOTA_TEAM_BADGUYS and self.nDireScore > self.nRadiantScore + 1 then
                    AddInertiaModifier(playerHero)
                elseif playerHero:GetTeamNumber() == DOTA_TEAM_GOODGUYS and self.nRadiantScore > self.nDireScore + 1 then
                    AddInertiaModifier(playerHero)
                end

                playerHero:RemoveModifierByName("round_pause")
                playerHero.ServStat:roundNumber(self.nCurrentRound)
            end)
            --SendChatToPanorama("IRT3")

            FireGameEvent("show_center_message",msg)
            --SendChatToPanorama("IRT4")

            if self.nCurrentRound == 1 then
                --[[if _G.ClownActive == true then
                    EmitAnnouncerSound("fiddle_battle_begins_"..math.random(1,4))
                else
                    EmitAnnouncerSound("Battle_Begins_" .. math.random(1,3))
                end]]
                LoopOverPlayers(function(player, playerID, playerHero)
                    if playerHero.clown_announcer == true then
                        CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="fiddle_battle_begins_"..math.random(1,4)})
                    else
                        CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Battle_Begins_" .. math.random(1,3)})
                    end
                end)
            elseif self.nRadiantScore == VICTORY_CONDITION - 1 and self.nDireScore == VICTORY_CONDITION - 1 then
                --[[if _G.ClownActive == true then
                    EmitAnnouncerSound("fiddle_last_round_1"..math.random(1,3))
                else
                    EmitAnnouncerSound("Last_Round_" .. math.random(1,2))
                end]]
                LoopOverPlayers(function(player, playerID, playerHero)
                    if playerHero.clown_announcer == true then
                        CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="fiddle_last_round_"..math.random(1,3)})
                    else
                        CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Last_Round_" .. math.random(1,2)})
                    end
                end)
            else
                --[[if _G.ClownActive == true then
                    EmitAnnouncerSound("fiddle_round_start_"..math.random(1,4))
                else
                    EmitAnnouncerSound("Round_Start_" .. math.random(1,2))
                end]]
                LoopOverPlayers(function(player, playerID, playerHero)
                    if playerHero.clown_announcer == true then
                        CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="fiddle_round_start_"..math.random(1,4)})
                    else
                        CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Round_Start_" .. math.random(1,2)})
                    end
                end)
            end
        end
    })

    Timers:CreateTimer('presence_alert', {
        endTime = PRESENCE_ALERT_DURATION + PRE_ROUND_DURATION,
        callback = function()
            --GameRules:SendCustomMessage("#Fate_Presence_Alert", 0, 0)
        end
    })

    Timers:CreateTimer('round_30sec_alert', {
        endTime = PRE_ROUND_DURATION + ROUND_DURATION - 30,
        callback = function()
            FireGameEvent("show_center_message",alertmsg)
        end
    })

    Timers:CreateTimer('round_10sec_alert', {
        endTime = PRE_ROUND_DURATION + ROUND_DURATION - 10,
        callback = function()
            FireGameEvent("show_center_message",alertmsg2)
        end
    })

    --SendChatToPanorama("IR4")

    Timers:CreateTimer('round_timer', {
        endTime = PRE_ROUND_DURATION + ROUND_DURATION,
        callback = function()
            print("[FateGameMode]Round timeout.")
            FireGameEvent("show_center_message",timeoutmsg)
            local nRadiantAlive = 0
            local nDireAlive = 0
            -- Check how many people are alive in each team
            self:LoopOverPlayers(function(player, playerID, playerHero)
                if playerHero:IsAlive() then
                    if playerHero:GetTeam() == DOTA_TEAM_GOODGUYS then
                        nRadiantAlive = nRadiantAlive + 1
                    else
                        nDireAlive = nDireAlive + 1
                    end                
                end
            end)

            if not _G.LaPucelleActivated then
            -- if nRadiantAlive > 6 then nRadiantAlive = 6 end
            -- if nDireAlive > 6 then nDireAlive = 6 end
            -- if remaining players are equal
                if nRadiantAlive == nDireAlive then
                    -- Default Radiant Win
                    if self.nRadiantScore + 0 < self.nDireScore
                        then self:FinishRound(true,3)
                    -- Default Dire Win
                    elseif self.nRadiantScore > self.nDireScore + 0
                        then self:FinishRound(true,4)
                    -- Draw
                    else
                        --if self.nRadiantScore == self.nDireScore
                        --then 
                        self:FinishRound(true, 2)
                    end
                -- if remaining players are not equal
                elseif nRadiantAlive > nDireAlive then
                    self:FinishRound(true, 0)
                elseif nRadiantAlive < nDireAlive then
                    self:FinishRound(true, 1)
                end
            end
        end
    })
end

--[[
0 : Radiant
1 : Dire
2 : Draw
3 : Radiant(by default)
4 : Dire(by default)]]
function FateGameMode:FinishRound(IsTimeOut, winner)
    print("[FATE] Winner decided")
    --UTIL_RemoveImmediate( roundQuest ) -- Stop round timer
    print(self.nRadiantScore)
    _G.CurrentGameState = "FATE_POST_ROUND"    
    
    CreateUITimer(("Round " .. self.nCurrentRound), 0, "round_timer" .. self.nCurrentRound)
    CreateUITimer("Pre-Round", 0, "pregame_timer")

    --SendChatToPanorama("FR1")
    -- clean up marbles and pause heroes for 5 seconds(as well as NR combo)
    self:LoopOverPlayers(function(player, playerID, playerHero)
        if playerHero:IsAlive() then
            giveUnitDataDrivenModifier(playerHero, playerHero, "round_pause", 7.0)
        end

        -- Remove marble abilities
        if playerHero:GetName() == "npc_dota_hero_ember_spirit" and playerHero:HasModifier("modifier_unlimited_bladeworks") then
            playerHero:RemoveModifierByName("modifier_unlimited_bladeworks")
        elseif playerHero:GetName() == "npc_dota_hero_chen" and playerHero:HasModifier("modifier_army_of_the_king_death_checker") then
            playerHero:RemoveModifierByName("modifier_army_of_the_king_death_checker")
        elseif playerHero:GetName() == "npc_dota_hero_doom_bringer" then
            if playerHero.RespawnPos then
                playerHero:SetRespawnPosition(playerHero.RespawnPos)
            end
        elseif playerHero:GetName() == "npc_dota_hero_lina" then
            playerHero:FindAbilityByName("nero_imperial_open"):ReInit(playerHero)
            playerHero:RemoveModifierByName("modifier_aestus_domus_aurea_nero")
        elseif playerHero:GetName() == "npc_dota_hero_templar_assassin" then
            playerHero:RemoveModifierByName("modifier_medusa_monstrous_strength")
            playerHero:FindAbilityByName("medusa_monstrous_strength"):EndCooldown()
        elseif playerHero:GetName() == "npc_dota_hero_riki" then
            playerHero:RemoveModifierByName("modifier_holy_mother_buff")
        elseif playerHero:GetName() == "npc_dota_hero_mirana" then
            playerHero:RemoveModifierByName("modifier_jeanne_crimson_saint")
        elseif playerHero:GetName() == "npc_dota_hero_sven" then
            playerHero:RemoveModifierByName("modifier_lancelot_minigun")
        end

        if playerHero:FindAbilityByName("khsn_flame_active") then
            if playerHero:FindAbilityByName("khsn_flame_active"):GetToggleState() then
                playerHero:FindAbilityByName("khsn_flame_active"):ToggleAbility()
            end
        end

        if playerHero:HasModifier("modifier_saint_debuff") then
            playerHero:RemoveModifierByName("modifier_saint_debuff")
        end
        if playerHero:HasModifier("modifier_story_for_someones_sake") then
            playerHero:RemoveModifierByName("modifier_story_for_someones_sake")
        end
        if playerHero:HasModifier("modifier_story_for_someones_sake_enemy") then
            playerHero:RemoveModifierByName("modifier_story_for_someones_sake_enemy")
        end
        if playerHero:HasModifier("modifier_gae_buidhe") or playerHero:HasModifier("modifier_gae_dearg") then
            playerHero:RemoveModifierByName("modifier_gae_buidhe")
            playerHero:RemoveModifierByName("modifier_gae_dearg")
        end

        if playerHero:HasModifier("modifier_mount_caster") then
            playerHero:RemoveModifierByName("modifier_mount_caster")
        end

        if playerHero:GetName() == "npc_dota_hero_shadow_shaman" then
            playerHero:RemoveModifierByName("modifier_integrate_gille")
            playerHero:RemoveModifierByName("modifier_integrate")
        end
    end)

    --SendChatToPanorama("FR2")

    -- Remove all units
    local units = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0,0,0), nil, 20000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
    local units2 = FindUnitsInRadius(DOTA_TEAM_BADGUYS, Vector(0,0,0), nil, 20000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
    for k,v in pairs(units) do
        if not v:IsNull() and IsValidEntity(v) and not v:IsRealHero() then
            for i=1, #DoNotKillAtTheEndOfRound do
                if not v:IsNull() and IsValidEntity(v) and v:GetUnitName() ~= DoNotKillAtTheEndOfRound[i] and v:GetAbsOrigin().y > -7000 then
                    v:Kill(v:GetAbilityByIndex(0), v)
                end
            end
        end
    end
    for k,v in pairs(units2) do
        if not v:IsNull() and IsValidEntity(v) and not v:IsRealHero() then
            for i=1, #DoNotKillAtTheEndOfRound do
                if not v:IsNull() and IsValidEntity(v) and v:GetUnitName() ~= DoNotKillAtTheEndOfRound[i] and v:GetAbsOrigin().y > -7000 then
                    v:Kill(v:GetAbilityByIndex(0), v)
                end
            end
        end
    end

    --SendChatToPanorama("FR3")

    -- decide the winner
    if winner == 0 then
        GameRules:SendCustomMessage("#Fate_Round_Winner_1", 0, 0)
        self.nRadiantScore = self.nRadiantScore + 1
        winnerEventData.winnerTeam = 0
        GameRules.Winner = 2
        statCollection:submitRound(false)
    elseif winner == 1 then
        GameRules:SendCustomMessage("#Fate_Round_Winner_2", 0, 0)
        self.nDireScore = self.nDireScore + 1
        winnerEventData.winnerTeam = 1
        GameRules.Winner = 3
        statCollection:submitRound(false)
    elseif winner == 2 then
        GameRules:SendCustomMessage("#Fate_Round_Draw", 0, 0)
        winnerEventData.winnerTeam = 2
        --[[if _G.ClownActive == true then
            EmitAnnouncerSound("fiddle_draw_"..math.random(1,4))
        else
            EmitAnnouncerSound("Game_Draw")
        end]]
        LoopOverPlayers(function(player, playerID, playerHero)
            if playerHero.clown_announcer == true then
                CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="fiddle_draw_"..math.random(1,4)})
            else
                CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="GameDraw"})
                end
            end)
    elseif winner == 3 then
        GameRules:SendCustomMessage("#Fate_Round_Winner_1_By_Default", 0, 0)
        self.nRadiantScore = self.nRadiantScore + 1
        winnerEventData.winnerTeam = 0
        GameRules.Winner = 2
        statCollection:submitRound(false)
    elseif winner == 4 then
        GameRules:SendCustomMessage("#Fate_Round_Winner_2_By_Default", 0, 0)
        self.nDireScore = self.nDireScore + 1
        winnerEventData.winnerTeam = 1
        GameRules.Winner = 3
        statCollection:submitRound(false)
    end

--[[
    
        if(winnerEventData.winnerTeam == 0 and (self.nRadiantScore == 5 or self.nRadiantScore == 10 or self.nRadiantScore == 15)) then 
        local grailmsg = {
                    message = "#Fate_Black_Grail_Alert",
                    duration = 5.0
                        }
                FireGameEvent("show_center_message", grailmsg)
            end
            if winnerEventData.winnerTeam == 1 and (self.nDireScore == 5 or self.nDireScore == 10 or self.nDireScore == 15) then
        local grailmsg = {
                    message = "#Fate_Red_Grail_Alert",
                    duration = 5.0
                        }
                FireGameEvent("show_center_message",grailmsg)
            end
            ]]

            if( _G.GameMap ~= "fate_ffa") then
        LoopOverPlayers(function(player, playerID, playerHero)
            if(winnerEventData.winnerTeam == 0 and (self.nRadiantScore == 5 or self.nRadiantScore == 10 or self.nRadiantScore == 15)) then 
                 if playerHero:GetTeamNumber() == DOTA_TEAM_BADGUYS then
                    if playerHero.ShardAmount == nil then
                        playerHero.ShardAmount = 1
                    else
                        playerHero.ShardAmount = playerHero.ShardAmount + 1
                    end
                    local statTable = CreateTemporaryStatTable(playerHero)
                    CustomGameEventManager:Send_ServerToPlayer( playerHero:GetPlayerOwner(), "servant_stats_updated", statTable ) -- Send the current stat info to JS
                    Notifications:Top(player, {text= "<font color='#58ACFA'></font> Your team had lost 5 rounds, you are rewarded with a shard of Holy Grail.", duration=8, style={color="rgb(255,140,0)", ["font-size"]="45px"}, continue=true})
                end
            elseif winnerEventData.winnerTeam == 1 and (self.nDireScore == 5 or self.nDireScore == 10 or self.nDireScore == 15) then
                if playerHero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then

                    if playerHero.ShardAmount == nil then
                        playerHero.ShardAmount = 1
                    else
                        playerHero.ShardAmount = playerHero.ShardAmount + 1
                    end
                    local statTable = CreateTemporaryStatTable(playerHero)
                    CustomGameEventManager:Send_ServerToPlayer( playerHero:GetPlayerOwner(), "servant_stats_updated", statTable ) -- Send the current stat info to JS
                    Notifications:Top(player, {text= "<font color='#58ACFA'></font> Your team had lost 5 rounds, you are rewarded with a shard of Holy Grail.", duration=8, style={color="rgb(255,140,0)", ["font-size"]="45px"}, continue=true})
                end

            end
        
             
        end)    
    end

    --SendChatToPanorama("FR4")

    if self.nRadiantScore == VICTORY_CONDITION or self.nDireScore == VICTORY_CONDITION then
        --[[if _G.ClownActive == true then
            EmitAnnouncerSound("fiddle_game_end_"..math.random(1,4))
        else
            EmitAnnouncerSound("Game_End_" .. math.random(1,3))
        end]]
        LoopOverPlayers(function(player, playerID, playerHero)
                    if playerHero.clown_announcer == true then
                        CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="fiddle_game_end_"..math.random(1,4)})
                    else
                        CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Game_End_" .. math.random(1,3)})
                    end
                end)    
    elseif self.nRadiantScore - self.nDireScore > 6 and winner == 0 then
        --[[if _G.ClownActive == true then
            EmitAnnouncerSound("fiddle_razgrom_"..math.random(1,7))
        else
            EmitAnnouncerSound("Landslide_" .. math.random(1,2))
        end]]
        LoopOverPlayers(function(player, playerID, playerHero)
                    if playerHero.clown_announcer == true then
                        CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="fiddle_razgrom_"..math.random(1,7)})
                    else
                        CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Landslide_" .. math.random(1,2)})
                    end
                end)
    elseif self.nDireScore - self.nRadiantScore > 6 and winner == 1 then
         --[[if _G.ClownActive == true then
            EmitAnnouncerSound("fiddle_razgrom_"..math.random(1,7))
        else
            EmitAnnouncerSound("Landslide_" .. math.random(1,2))
        end]]
        LoopOverPlayers(function(player, playerID, playerHero)
                    if playerHero.clown_announcer == true then
                        CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="fiddle_razgrom_"..math.random(1,7)})
                    else
                        CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Landslide_" .. math.random(1,2)})
                    end
                end)
    end

    --SendChatToPanorama("FR5")

    winnerEventData.radiantScore = self.nRadiantScore
    winnerEventData.direScore = self.nDireScore
    CustomNetTables:SetTableValue("score", "CurrentScore", { nRadiantScore = self.nRadiantScore, nDireScore = self.nDireScore })
    CustomGameEventManager:Send_ServerToAllClients( "winner_decided", winnerEventData ) -- Send the winner to Javascript
    GameRules:SendCustomMessage("#Fate_Round_Gold_Note", 0, 0)
    self:LoopOverPlayers(function(player, playerID, playerHero)
        local pHero = playerHero
        -- radiant = 2(equivalent to 0)
        -- dire = 3(equivalent to 1)

        if pHero:GetTeam() - 2 ~= winnerEventData.winnerTeam and winnerEventData.winnerTeam ~= 2 then
            pHero.MasterUnit:GiveMana(1)
            pHero.MasterUnit2:SetMana(pHero.MasterUnit:GetMana())
            --print("granted 1 mana to " .. pHero:GetName())
        end
    end)

    --SendChatToPanorama("FR6")
    -- Set score
    mode = GameRules:GetGameModeEntity()
    mode:SetTopBarTeamValue ( DOTA_TEAM_BADGUYS, self.nDireScore )
    mode:SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, self.nRadiantScore )
    self.nCurrentRound = self.nCurrentRound + 1
    
    self:LoopOverPlayers(function(player, playerID, playerHero)
        local hero = playerHero
        hero.ServStat:EndOfRound(self.nRadiantScore,self.nDireScore)
    end)

    --SendChatToPanorama("FR7")
    
    -- check for win condition
    if self.nRadiantScore == VICTORY_CONDITION then
        self:LoopOverPlayers(function(player, playerID, playerHero)
            local hero = playerHero
            if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
                hero.ServStat:EndOfGame("Won")
            else
                hero.ServStat:EndOfGame("Lost")
            end
            hero.ServStat:printconsole()
        end)
        GameRules:SendCustomMessage("Red Faction Victory!",0,0)
        my_http_post()
        GameRules:SetSafeToLeave( true )
        GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
        return
    elseif self.nDireScore == VICTORY_CONDITION then
        self:LoopOverPlayers(function(player, playerID, playerHero)
            local hero = playerHero
            if hero:GetTeam() == DOTA_TEAM_BADGUYS then
                hero.ServStat:EndOfGame("Won")
            else
                hero.ServStat:EndOfGame("Lost")
            end
            hero.ServStat:printconsole()
        end)
        GameRules:SendCustomMessage("Black Faction Victory!",0,0)
        my_http_post()
        GameRules:SetSafeToLeave( true )
        GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
        return
    end
    --SendChatToPanorama("FR8")

    Timers:CreateTimer('roundend', {
        endTime = 7,
        callback = function()
            -- Remove all units
            local units = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0,0,0), nil, 20000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
            local units2 = FindUnitsInRadius(DOTA_TEAM_BADGUYS, Vector(0,0,0), nil, 20000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
            --SendChatToPanorama("FRT1")
            for k,v in pairs(units) do
                if not v:IsNull() and IsValidEntity(v) and not v:IsRealHero() then
                    for i=1, #DoNotKillAtTheEndOfRound do
                        --print(v:GetUnitName())
                        if not v:IsNull() and IsValidEntity(v) and v:GetUnitName() ~= DoNotKillAtTheEndOfRound[i] and v:GetAbsOrigin().y > -7000 then
                            v:Kill(v:GetAbilityByIndex(0), v)
                        end
                    end
                end
            end
            --SendChatToPanorama("FRT2")
            for k,v in pairs(units2) do
                if not v:IsNull() and IsValidEntity(v) and not v:IsRealHero() then
                    for i=1, #DoNotKillAtTheEndOfRound do
                        --print(v:GetUnitName())
                        if not v:IsNull() and IsValidEntity(v) and v:GetUnitName() ~= DoNotKillAtTheEndOfRound[i] and v:GetAbsOrigin().y > -7000 then
                            v:Kill(v:GetAbilityByIndex(0), v)
                        end
                    end
                end
            end
            _G.IsPreRound = true

            local team2Index = 0
            local team3Index = 0
            --SendChatToPanorama("FRT3")

            self:LoopOverPlayers(function(player, playerID, playerHero)
                local respawnPos = playerHero.RespawnPos
                if self.nCurrentRound >= 2 then
                    local index
                    local team = playerHero:GetTeam()
                    if team == 2 then
                        index = team2Index
                        team2Index = team2Index + 1
                    else
                        index = team3Index
                        team3Index = team3Index + 1
                    end
                    respawnPos = GetRespawnPos(playerHero, self.nCurrentRound, index)
                end
                playerHero:SetRespawnPosition(respawnPos)
                playerHero:RespawnHero(false, false)
                playerHero:RemoveModifierByName("modifier_atalanta_curse")
                ProjectileManager:ProjectileDodge(playerHero)
            end, true)
            --SendChatToPanorama("FRT4")
            self:InitializeRound()
            _G.CurrentGameState = "FATE_PRE_ROUND"
        end
    })

end

function GetRespawnPos(playerHero, currentRound, index)
    local vColumn = Vector(0, -200 ,0)
    local vRow = Vector(200, 0, 0)

    -- [0] [1]
    -- [2] [3]
    -- [4] [x] x is default spawn
    local radiantOffset = vColumn * -1 + vRow * -.5
    local radiantSpawn = SPAWN_POSITION_RADIANT_DM + radiantOffset

    -- [0] [1]
    -- [2] [x]
    -- [4] [5] x is default spawn
    local direOffset = vColumn * 1 + vRow * -.5
    local direSpawn = SPAWN_POSITION_DIRE_DM + direOffset

    local row = index % 2
    local column = math.floor(index / 2)
    if index == 6 then -- for 7th player
        row = 2
        column = 1
    end
    local offset = vRow * row + vColumn * column

    local team = playerHero:GetTeam()
    local respawnSide = (team + currentRound) % 2
    local defaultRespawnPos = respawnSide == 1 and radiantSpawn or direSpawn
    return defaultRespawnPos + vRow * row + vColumn * column
end

function FateGameMode:LoopOverPlayers(callback, withDummy)
    for i=0, 13 do
        local playerID = i
        --print(i)
        local player = PlayerResource:GetPlayer(i)
        local playerHero = PlayerResource:GetSelectedHeroEntity(playerID)
        --if not playerHero then return end
        --if playerHero:GetName() == "npc_dota_hero_target_dummy" then return end
        if playerHero then
            if (playerHero:GetName() ~= "npc_dota_hero_target_dummy" or withDummy) then
                --print("Looping through hero " .. playerHero:GetName())
                if callback(player, playerID, playerHero) then
                    --break
                end
            end
        end
    end
end

-- This function is called as the first player loads and sets up the FateGameMode parameters
function FateGameMode:CaptureGameMode()
    print("First player loaded in, setting parameters")
    if mode == nil then
        -- Set FateGameMode parameters
        mode = GameRules:GetGameModeEntity()


        --mode:SetCameraDistanceOverride(1600)
        mode:SetCustomBuybackCostEnabled( CUSTOM_BUYBACK_COST_ENABLED )
        mode:SetCustomBuybackCooldownEnabled( CUSTOM_BUYBACK_COOLDOWN_ENABLED )
        mode:SetBuybackEnabled( BUYBACK_ENABLED )
        mode:SetTopBarTeamValuesVisible( TOP_BAR_VISIBLE )
        --screw 7.23
        mode:SetCustomXPRequiredToReachNextLevel( XP_TABLE )
        mode:SetUseCustomHeroLevels ( true )
        mode:SetFogOfWarDisabled(DISABLE_FOG_OF_WAR_ENTIRELY)
        mode:SetGoldSoundDisabled( true )
        mode:SetRemoveIllusionsOnDeath( true )
        mode:SetStashPurchasingDisabled ( false )
        mode:SetAnnouncerDisabled( true )
        mode:SetLoseGoldOnDeath( false )
   
        mode:SetExecuteOrderFilter( Dynamic_Wrap( FateGameMode, "ExecuteOrderFilter" ), FateGameMode )
        mode:SetTrackingProjectileFilter( Dynamic_Wrap( FateGameMode, "ExecuteProjectileFilter" ), FateGameMode )
        --mode:SetItemAddedToInventoryFilter(Dynamic_Wrap(FateGameMode, "ItemAddedFilter"), FateGameMode) (screw 7.23 x2)
        mode:SetModifyGoldFilter(Dynamic_Wrap(FateGameMode, "ModifyGoldFilter"), FateGameMode)
        mode:SetDamageFilter(Dynamic_Wrap(FateGameMode, "TakeDamageFilter"), FateGameMode)
        mode:SetModifyExperienceFilter(Dynamic_Wrap(FateGameMode, "ModifyExperienceFilter"), FateGameMode)
        mode:SetTopBarTeamValuesOverride ( USE_CUSTOM_TOP_BAR_VALUES )
        self:OnFirstPlayerLoaded()

        if _G.GameMap == "fate_elim_6v6" or _G.GameMap == "fate_elim_7v7" or _G.GameMap == "fate_elim_7v7_test" or _G.GameMap =="anime_fate_7vs7_beta" or _G.GameMap =="7vs7_common" or _G.GameMap =="7vs7_draft" then
            mode:SetTopBarTeamValuesOverride ( USE_CUSTOM_TOP_BAR_VALUES )
        end
    end
end


-- This function is called 1 to 2 times as the player connects initially but before they
-- have completely connected
function FateGameMode:PlayerConnect(keys)
  --  print('[BAREBONES] PlayerConnect')
    --PrintTable(keys)

    if keys.bot == 1 then
        -- This user is a Bot, so add it to the bots table
        self.vBots[keys.userid] = 1
    end
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
-- Assign players
function FateGameMode:OnConnectFull(keys)
  --  print ('[BAREBONES] OnConnectFull')
    Timers:CreateTimer(2, function()
        PrintTable(keys)
    end)
    FateGameMode:CaptureGameMode()

    --local entIndex = keys.index+1
    -- The Player entity of the joining user
    local userID = keys.userid
    local ply = PlayerResource:GetPlayer(userID)--EntIndexToHScript(entIndex)
    self.vUserIds = self.vUserIds or {}
    self.vUserIds[userID] = ply

    --[[local playerID = ply:GetPlayerID()
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
        playerID = keys.index
        print("teams not assigned yet, using index as player ID = " .. playerID)
    end
    self.vPlayerList = self.vPlayerList or {}
    self.vPlayerList[keys.userid] = playerID
    SendChatToPanorama("player " .. playerID .. " got assigned to " .. keys.userid .. "index in player list")
    --print(self.vPlayerList[keys.userid])]]
end

function FateGameMode:MakeDraw()
    print("draw")
    self:FinishRound(false,2)
end

function my_http_post()
    SendChatToPanorama("Work in Progress")
    local matchData = {}
    LoopOverPlayers(function(player, playerID, playerHero)
        local hero = playerHero
        local playerData = {GetSystemDate(), GetSystemTime(), GetMapName(), math.ceil(GameRules:GetGameTime()), hero.ServStat.playerName, hero.ServStat.steamId, hero.ServStat.heroName, hero.ServStat.lvl,
        hero.ServStat.round, hero.ServStat.radiantWin, hero.ServStat.direWin, hero.ServStat.winGame, hero.ServStat.kill, hero.ServStat.death, 
        hero.ServStat.assist, hero.ServStat.tkill, hero.ServStat.itemValue + hero.ServStat.goldWasted, hero.ServStat.itemValue, hero.ServStat.goldWasted,
        hero.ServStat.damageDealt, hero.ServStat.damageDealtBR, hero.ServStat.damageTaken, hero.ServStat.damageTakenBR, hero.ServStat.qseal, hero.ServStat.wseal,
        hero.ServStat.eseal, hero.ServStat.rseal, hero.ServStat.cScroll, hero.ServStat.bScroll, hero.ServStat.aScroll, hero.ServStat.sScroll, hero.ServStat.exScroll,
        hero.ServStat.ward, hero.ServStat.familiar, hero.ServStat.link, hero.ServStat.str, hero.ServStat.agi, hero.ServStat.int, hero.ServStat.atk, hero.ServStat.armor, 
        hero.ServStat.hpregen, hero.ServStat.mpregen, hero.ServStat.ms, hero.ServStat.shard1, hero.ServStat.shard2, hero.ServStat.shard3, hero.ServStat.shard4}
        table.insert(matchData, playerData)
    end)
    --[[for k,v in pairs(matchData) do
        for a,b in pairs(v) do
            SendChatToPanorama(b)
        end
    end]]
    --json encode
    --http post
end