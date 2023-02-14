AllPlayersInterval = {0,1,2,3,4,5,6,7,8,9,10,11,12,13}

CUSTOM_STARTING_GOLD = 625
CUSTOM_GOLD_FOR_RANDOM_TOTAL = 800
ADS_CLICKED_BONUS_GOLD = 35
CUSTOM_GOLD_REPICK_COST = 200

MAX_SPAWNBOXES_SELECTED = 3

--DO NOT SET SUMM TIME <5 BECAUSE OF HERO_SELECTION.JS (herotables are loaded only after a while, because volvo suck)

HERO_SELECTION_PICK_TIME = 60
HERO_SELECTION_STRATEGY_TIME = 0
HERO_SELECTION_BANNING_TIME = 0

HERO_SELECTION_PHASE_NOT_STARTED = 0
HERO_SELECTION_PHASE_BANNING = 1
HERO_SELECTION_PHASE_HERO_PICK = 2
HERO_SELECTION_PHASE_STRATEGY = 3
HERO_SELECTION_PHASE_END = 4

FORCE_PICKED_HERO = "npc_dota_hero_target_dummy"

if not HeroSelection then
	HeroSelection = class({})
	HeroSelection.RandomableHeroes = {}
	HeroSelection.EmptyStateData = {
		hero = "npc_dota_hero_abaddon",
		status = "hover"
	}
	HeroSelection.CurrentState = HERO_SELECTION_PHASE_NOT_STARTED
	HeroSelection.GameStartTimers = {}
end

ModuleRequire(..., "util")
ModuleRequire(..., "linked")
ModuleRequire(..., "hero_replacer")
ModuleRequire(..., "client_actions")
ModuleLinkLuaModifier(..., "modifier_hero_selection_transformation")

Events:Register("activate", function ()
	if IsInToolsMode() then
		HERO_SELECTION_PICK_TIME = 3
	end
	GameRules:SetHeroSelectionTime(-1)
	local preTime = HERO_SELECTION_PICK_TIME + HERO_SELECTION_STRATEGY_TIME + 3-- + Options:GetValue("PreGameTime")
	if Options:GetValue("BanningPhaseBannedPercentage") > 0 then
		preTime = preTime + HERO_SELECTION_BANNING_TIME
	end
	GameRules:SetPreGameTime(preTime)
	GameRules:GetGameModeEntity():SetCustomGameForceHero(FORCE_PICKED_HERO)
	CustomGameEventManager:RegisterListener("hero_selection_player_hover", Dynamic_Wrap(HeroSelection, "OnHeroHover"))
	CustomGameEventManager:RegisterListener("hero_selection_player_select", Dynamic_Wrap(HeroSelection, "OnHeroSelectHero"))
	CustomGameEventManager:RegisterListener("hero_selection_player_random", Dynamic_Wrap(HeroSelection, "OnHeroRandomHero"))
	CustomGameEventManager:RegisterListener("hero_selection_minimap_set_spawnbox", Dynamic_Wrap(HeroSelection, "OnMinimapSetSpawnbox"))
	CustomGameEventManager:RegisterListener("hero_selection_player_repick", Dynamic_Wrap(HeroSelection, "OnHeroRepick"))
	PlayerTables:CreateTable("hero_selection_banning_phase", {}, AllPlayersInterval)

	Convars:RegisterCommand("arena_hero_selection_skip_phase", function()
		if HeroSelection.CurrentState == HERO_SELECTION_PHASE_BANNING then
			HeroSelection:StartStateHeroPick()
		elseif HeroSelection.CurrentState == HERO_SELECTION_PHASE_HERO_PICK then
			HeroSelection:StartStateStrategy()
		elseif HeroSelection.CurrentState == HERO_SELECTION_PHASE_STRATEGY then
			HeroSelection:StartStateInGame({})
		elseif HeroSelection.CurrentState == HERO_SELECTION_PHASE_END then
			Tutorial:ForceGameStart()
		end
	end, "Skips current phase", FCVAR_CHEAT)

	HeroSelection:PrepareTables()
end)

function HeroSelection:PrepareTables()
	local data = {
		HeroSelectionState = HeroSelection.CurrentState,
		HeroTabs = {}
	}
	local heroesData = {}
	for name, baseData in pairs(NPC_HEROES_CUSTOM) do
		if baseData.Enabled ~= 0 then
			local heroTable = GetHeroTableByName(name)
			local baseHero = heroTable.base_hero
			local tabIndex = baseHero and 2 or 1
			local heroData = {
				model = baseData.override_hero,
				useCustomScene = heroTable.UseCustomScene == 1,
				attributes = HeroSelection:ExtractHeroStats(baseData),
				tabIndex = tabIndex
			}

			heroData.attributesandcombo = {
   				baseData.Attribute1 and baseData.Attribute1 or "fate_empty1",
				baseData.Attribute2 and baseData.Attribute2 or "fate_empty6",
				baseData.Attribute3 and baseData.Attribute3 or "fate_empty7",
				baseData.Attribute4 and baseData.Attribute4 or "fate_empty8",
				baseData.Attribute5 and baseData.Attribute5 or "fate_empty9",
				baseData.Combo and baseData.Combo or "fate_empty10"
			}

			if not Options:IsEquals("MainHeroList", "NoAbilities") then
				heroData.abilities = {}--HeroSelection:ParseAbilitiesFromTable(heroTable)
				for i = 1,6 do
					local abil = "Ability"..i
					heroData.abilities[i] = baseData[abil]
				end
				heroData.isChanged = heroTable.Changed == 1 and tabIndex == 1
				heroData.linkedColorGroup = heroTable.LinkedColorGroup
				heroData.DisabledInRanked = heroTable.DisabledInRanked == 1
				heroData.Unreleased = heroTable.Unreleased == 1

				if heroTable.LinkedHero then
					heroData.linked_heroes = string.split(heroTable.LinkedHero, " | ")
				end
			end
			heroesData[baseData.override_hero] = heroData
		end
	end
	for name,enabled in pairsByKeys(ENABLED_HEROES[Options:GetValue("MainHeroList")]) do
		if enabled == 1 then
			if not heroesData[name] or heroesData[name].Enabled == 0 then
				error(name .. " is enabled in hero list, but not a valid hero")
			end
			local tabIndex = heroesData[name].tabIndex
			if not data.HeroTabs[tabIndex] then data.HeroTabs[tabIndex] = {} end
			table.insert(data.HeroTabs[tabIndex], name)
		end
	end
	for _,tab in pairs(data.HeroTabs) do
		for _,name in ipairs(tab) do
			if heroesData[name] and
				not heroesData[name].linked_heroes and
				not HeroSelection:IsHeroUnreleased(name) then
				table.insert(HeroSelection.RandomableHeroes, name)
			end
		end
	end
	PlayerTables:CreateTable("hero_selection_heroes_data", heroesData, AllPlayersInterval)
	PlayerTables:CreateTable("hero_selection_available_heroes", data, AllPlayersInterval)
end

function HeroSelection:SetTimerDuration(duration)
	PlayerTables:SetTableValue("hero_selection_available_heroes", "TimerEndTime", GameRules:GetGameTime() + duration)
end

function HeroSelection:SetState(state)
	HeroSelection.CurrentState = state
	PlayerTables:SetTableValue("hero_selection_available_heroes", "HeroSelectionState", state)
end

function HeroSelection:GetState()
	return HeroSelection.CurrentState
end

function HeroSelection:CreateTimer(...)
	local t = Timers:CreateTimer(...)
	table.insert(HeroSelection.GameStartTimers, t)
	PrintTable(HeroSelection.GameStartTimers)
	return t
end

function HeroSelection:DismissTimers()
	for _,v in ipairs(HeroSelection.GameStartTimers) do
		Timers:RemoveTimer(v)
	end
	HeroSelection.GameStartTimers = {}
end

function HeroSelection:HeroSelectionStart()
	GameRules:GetGameModeEntity():SetAnnouncerDisabled(true)
	--if Options:GetValue("BanningPhaseBannedPercentage") > 0 then
		--EmitAnnouncerSound("announcer_ann_custom_mode_05")
		HeroSelection:SetState(HERO_SELECTION_PHASE_BANNING)
		HeroSelection:SetTimerDuration(HERO_SELECTION_BANNING_TIME)
		HeroSelection:CreateTimer(HERO_SELECTION_BANNING_TIME, function()
			HeroSelection:StartStateHeroPick()
		end)
	--else
	--	HeroSelection:StartStateHeroPick()
	--end
end

function HeroSelection:StartStateHeroPick()
	--Banning
	local notBanned = {}
	--[[for hero in pairs(PlayerTables:GetAllTableValuesForReadOnly("hero_selection_banning_phase")) do
		if not table.includes(notBanned, hero) then
			table.insert(notBanned, hero)
		end
	end
	local iterCount = math.ceil(#notBanned * Options:GetValue("BanningPhaseBannedPercentage") * 0.01)
	for i = 1, iterCount do
		table.remove(notBanned, RandomInt(1, #notBanned))
	end]]
	PlayerTables:DeleteTableKeys("hero_selection_banning_phase", notBanned)
	local banned = PlayerTables:GetAllTableValuesForReadOnly("hero_selection_banning_phase")
	local bannedCount = table.count(banned)
	--[[Chat:SendSystemMessage({
		localizable = pluralize(bannedCount, "DOTA_Chat_AD_BanCount1", "DOTA_Chat_AD_BanCount"),
		variables = {
			["%s1"] = bannedCount
		}
	})
	for hero in pairs(banned) do
		Chat:SendSystemMessage({
			localizable = "DOTA_Chat_AD_Ban",
			variables = {
				["%s1"] = hero
			}
		})
	end]]

	HeroSelection:DismissTimers()
	--print(AllPlayersInterval)
	local pick_data = PlayerTables:GetAllTableValuesForReadOnly("hero_selection_available_heroes")
	local pepe_data = PlayerTables:GetAllTableValuesForReadOnly("hero_selection_heroes_data")
	PrintTable(pepe_data)
	--PlayerTables:CreateTable("hero_selection_heroes_data", pepe_data, AllPlayersInterval)
	--PlayerTables:CreateTable("hero_selection_available_heroes", pick_data, AllPlayersInterval)
	--PrintTable(pick_data)
	--EmitAnnouncerSound("announcer_ann_custom_draft_01")
	HeroSelection:SetState(HERO_SELECTION_PHASE_HERO_PICK)
	HeroSelection:SetTimerDuration(HERO_SELECTION_PICK_TIME)
	for _,sec in ipairs({30, 15, 10, "05"}) do
		HeroSelection:CreateTimer(HERO_SELECTION_PICK_TIME - tonumber(sec), function()
			--EmitAnnouncerSound("announcer_ann_custom_timer_sec_" .. sec)
		end)
	end
	HeroSelection:CreateTimer(HERO_SELECTION_PICK_TIME, function()
		HeroSelection:StartStateStrategy()
	end)
end

function HeroSelection:StartStateStrategy()
	HeroSelection:DismissTimers()
	--HeroSelection:PreformRandomForNotPickedUnits()
	local toPrecache = {}
	for team,_v in pairs(PlayerTables:GetAllTableValues("hero_selection")) do
		for plyId,v in pairs(_v) do
			local heroNameTransformed = GetKeyValue(v.hero, "base_hero") or v.hero
			toPrecache[heroNameTransformed] = false
			PrecacheUnitByNameAsync(heroNameTransformed, function()
				toPrecache[heroNameTransformed] = true
				--CustomGameEventManager:Send_ServerToAllClients("hero_selection_update_precache_progress", toPrecache)
			end, plyId)
		end
	end
	--CustomGameEventManager:Send_ServerToAllClients("hero_selection_update_precache_progress", toPrecache)
	--GameRules:GetGameModeEntity():SetAnnouncerDisabled(false)
	--CustomGameEventManager:Send_ServerToAllClients("hero_selection_show_precache", {})

	HeroSelection:SetTimerDuration(HERO_SELECTION_STRATEGY_TIME)
	HeroSelection:SetState(HERO_SELECTION_PHASE_STRATEGY)
	HeroSelection:CreateTimer(HERO_SELECTION_STRATEGY_TIME, function()
		HeroSelection:StartStateInGame(toPrecache)
	end)
end

function HeroSelection:StartStateInGame(toPrecache)
	HeroSelection:DismissTimers()

	for i = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		if PLAYER_DATA[i].adsClicked then
			Gold:ModifyGold(i, ADS_CLICKED_BONUS_GOLD)
		end
	end
	--If for some reason even after that time heroes weren't precached
	Timers:CreateTimer({
		useGameTime = false,
		callback = function()
			local canEnd = true
			for k,v in pairs(toPrecache) do
				if not v then
					--print("pepega")
					canEnd = false
					return 0.1
				end
			end
			PauseGame(not canEnd)
			if canEnd then
				--print("pepega2")
				--Actually enter in-game state
				HeroSelection:SetState(HERO_SELECTION_PHASE_END)
				PrintTable(PlayerTables:GetAllTableValues("hero_selection"))
				for team,_v in pairs(PlayerTables:GetAllTableValues("hero_selection")) do
					PrintTable(PlayerTables:GetAllTableValues("hero_selection"))
					--print("pepega3")
					for plyId,v in pairs(_v) do
						--print(v.hero)
						--print("pepega4")
						--print(tostring(v.status))
						if tostring(v.status) == "picked" and not PlayerResource:IsPlayerAbandoned(plyId) then
							HeroSelection:SelectHero(plyId, tostring(v.hero), nil, nil, true)
						end
						if not (tostring(v.status) == "picked") then
							Timers:CreateTimer(0.1, function()
								local pepe = PlayerTables:GetTableValue("hero_selection", team)[plyId]
								if tostring(pepe.status) == "picked" and not PlayerResource:IsPlayerAbandoned(plyId) then
									PrecacheUnitByNameAsync(tostring(pepe.hero), function()
										HeroSelection:SelectHero(plyId, tostring(pepe.hero), nil, nil, true)
									end, plyId)
								else
									--print("debug")
									--print(tostring(pepe.status) == "picked")
									return 0.1
								end
							end)
						end
					end
				end
				--GameMode:OnHeroSelectionEnd()
			else
				--print("pepega3")
				return 0.1
			end
		end
	})
end
