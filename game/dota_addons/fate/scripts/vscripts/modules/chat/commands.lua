CUSTOMCHAT_COMMAND_LEVEL_PUBLIC = 0
CUSTOMCHAT_COMMAND_LEVEL_CHEAT = 1
CUSTOMCHAT_COMMAND_LEVEL_DEVELOPER = 2
CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER = 3

return {
	["gold"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			Gold:ModifyGold(hero, tonumber(args[1]))
		end
	},
	["spawnrune"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function()
			CustomRunes:SpawnRunes()
		end
	},
	["t"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			for i = 2, 50 do
				if XP_PER_LEVEL_TABLE[hero:GetLevel()] and XP_PER_LEVEL_TABLE[hero:GetLevel() + 1] then
					hero:AddExperience(XP_PER_LEVEL_TABLE[hero:GetLevel() + 1] - XP_PER_LEVEL_TABLE[hero:GetLevel()], 0, false, false)
				else
					break
				end
			end
			hero:AddItem(CreateItem("item_blink", hero, hero))
			hero:AddItem(CreateItem("item_rapier_arena", hero, hero))
			SendToServerConsole("dota_ability_debug 1")
		end
	},
	["stats"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			local i = tonumber(args[1])
			hero:ModifyAgility(i)
			hero:ModifyStrength(i)
			hero:ModifyIntellect(i)
		end
	},
	["duel"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args)
			Duel:SetDuelTimer(args[1] or 0)
		end
	},
	["killcreeps"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			for _,v in ipairs(FindUnitsInRadius(hero:GetTeamNumber(), Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)) do
				v:ForceKill(true)
			end
		end
	},
	["reset"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			for i = 0, hero:GetAbilityCount() - 1 do
				local ability = hero:GetAbilityByIndex(i)
				if ability then
					RecreateAbility(hero, ability):SetLevel(0)
				end
			end
		end
	},
	["createcreep"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			local sName = tostring(args[1]) or "medium"
			local SpawnerType = tonumber(args[2]) or 0
			local time = tonumber(args[3]) or 0
			local unitRootTable = SPAWNER_SETTINGS[sName].SpawnTypes[SpawnerType]
			PrintTable(SPAWNER_SETTINGS[sName])
			local unit = CreateUnitByName(unitRootTable[1][-1], hero:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)
			unit.SpawnerIndex = SpawnerType
			unit.SpawnerType = sName
			unit.SSpawner = -1
			unit.SLevel = time
			Spawner:UpgradeCreep(unit, unit.SpawnerType, unit.SLevel, unit.SpawnerIndex)
		end
	},
	["talents_clear"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			hero:ClearTalents()
		end
	},
	["equip"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			DynamicWearables:EquipWearable(hero, tonumber(args[1]))
		end
	},
	["reattach"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			DynamicWearables:UnequipAll(hero)
			DynamicWearables:AutoEquip(hero)
		end
	},
	["maxenergy"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			hero:ModifyMaxEnergy(args[1] - hero:GetMaxEnergy())
		end
	},
	["runetest"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT,
		f = function(args, hero)
			for i = ARENA_RUNE_FIRST, ARENA_RUNE_LAST do
				CustomRunes:CreateRune(hero:GetAbsOrigin() + RandomVector(RandomInt(90, 300)), i)
			end
		end
	},


	["debugallcalls"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_DEVELOPER,
		f = function()
			DebugAllCalls()
		end
	},
	["dcs"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_DEVELOPER,
		f = function()
			_G.DebugConnectionStates = not DebugConnectionStates
		end
	},
	["kick"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_DEVELOPER,
		f = function(args)
			PlayerResource:KickPlayer(tonumber(args[1]))
		end
	},
	["model"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args, hero)
			hero:SetModel(args[1])
			hero:SetOriginalModel(args[1])
		end
	},
	["pick"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args, hero, playerId)
			HeroSelection:ChangeHero(playerId, args[1], true, 0)
		end
	},
	["abandon"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args, hero)
			if PlayerResource:IsValidPlayerID(tonumber(args[1])) then
				PlayerResource:MakePlayerAbandoned(tonumber(args[1]))
			end
		end
	},
	["ban"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args, hero)
			local playerId = tonumber(args[1])
			if not PlayerResource:IsValidPlayerID(playerId) then return end

			PLAYER_DATA[playerId].isBanned = true
			PlayerResource:MakePlayerAbandoned(playerId)
			PlayerResource:KickPlayer(playerId)
		end
	},
	["a_createhero"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args, hero, playerId)
			local heroName = args[1]
			local optplayerId
			if tonumber(args[2]) then optplayerId = tonumber(args[2]) end
			local heroTableCustom = NPC_HEROES_CUSTOM[heroName]
			local baseNewHero = heroTableCustom.base_hero or heroName
			local heroEntity = optplayerId and
				PlayerResource:ReplaceHeroWith(optplayerId, baseNewHero, 0, 0) or
				CreateHeroForPlayer(baseNewHero, PlayerResource:GetPlayer(playerId))

			local team = 2
			if PlayerResource:GetTeam(optplayerId or playerId) == team and table.includes(args, "enemy") then
				team = 3
			end
			heroEntity:SetTeam(team)
			heroEntity:SetAbsOrigin(hero:GetAbsOrigin())

			heroEntity:SetControllableByPlayer(playerId, true)
			if optplayerId then
				heroEntity:SetControllableByPlayer(optplayerId, true)
			end
			for i = 1, 300 do
				heroEntity:HeroLevelUp(false)
			end
			if optplayerId then
				HeroSelection:ChangeHero(optplayerId, heroName, true, 0)
			else
				HeroSelection:InitializeHeroClass(heroEntity, heroTableCustom)
				if heroTableCustom.base_hero then
					TransformUnitClass(heroEntity, heroTableCustom)
					heroEntity.UnitName = heroName
				end
			end
		end
	},
	["consts"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args)
			for k, v in pairs(_G) do
				if string.find(k, args[1]) then
					print(k, v)
				end
			end
		end
	},
	["end"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_DEVELOPER,
		f = function(args, hero)
			local team = tonumber(args[1])
			if team then
				GameMode:OnKillGoalReached(team)
			end
		end
	},
	["weather"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args)
			local weather = tostring(args[1])
			if weather then
				Weather:Start(weather)
			end
		end
	},
	["console"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_PUBLIC,
		f = function(_, _, playerId)
			Console:SetVisible(PlayerResource:GetPlayer(playerId))
		end
	},
	-- Проверка ряда эффектов над хелсбаром (libraries/effect_bars.lua): вешает
	-- стаки Ли, Сайто, Мурамасы, яд Робина и проклятие Скатах на всех юнитов в
	-- 1200 вокруг героя.
	--   -effbars [li] [saito] [mura] [robin] [scathach]  стаки (по умолчанию
	--       25 4 3 12 6, 0 = не вешать)
	--   -effbars me [...]             то же, но и на себя
	--   -effbars boom                 взрыв Ли, как от удара NSS (и без стаков)
	--   -effbars off                  снять всё
	-- Кастер - свой герой, поэтому потолки без его способностей берутся запасные
	-- (50 / 10 / 5 / 30 / 10), а атрибутов Ли и Робина нет - ступени цвета Ли не
	-- включатся, потолок яда 30.
	["effbars"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args, hero)
			if not IsNotNull(hero) then return end

			-- модификаторы связываются в файлах способностей: без этих героев в
			-- матче они не связаны (повторная связка безвредна)
			require("libraries/effect_bars")
			LinkLuaModifier("modifier_nss_shock_stackable", "abilities/lishuwen/lishuwen_no_second_strike.lua", LUA_MODIFIER_MOTION_NONE)
			LinkLuaModifier("saito_formlessness_new_stacks", "abilities/saito/vergil_saito/saito_formlessness_new", LUA_MODIFIER_MOTION_NONE)
			LinkLuaModifier("modifier_muramasa_sword_drop_enemy_buff", "abilities/muramasa/muramasa_sword_creation", LUA_MODIFIER_MOTION_NONE)
			LinkLuaModifier("modifier_robin_poison_stack", "abilities/robin/modifiers/modifier_robin_poison_stack", LUA_MODIFIER_MOTION_NONE)
			LinkLuaModifier("modifier_stachach_gae_bolg_curse", "abilities/scathach/scathach_gae_bolg", LUA_MODIFIER_MOTION_NONE)

			local LI = "modifier_nss_shock_stackable"
			local SAITO = "saito_formlessness_new_stacks"
			local MURA = "modifier_muramasa_sword_drop_enemy_buff"
			local ROBIN = "modifier_robin_poison_stack"
			local SCATHACH = "modifier_stachach_gae_bolg_curse"

			local withSelf = args[1] == "me"
			if withSelf then table.remove(args, 1) end

			local targets = {}
			for _, unit in pairs(FindUnitsInRadius(hero:GetTeamNumber(), hero:GetAbsOrigin(), nil, 1200,
					DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
					DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
					FIND_CLOSEST, false)) do
				if unit ~= hero then
					table.insert(targets, unit)
				end
			end
			if withSelf then
				table.insert(targets, hero)
			end

			if args[1] == "off" then
				for _, unit in pairs(targets) do
					unit:RemoveModifierByName(LI)
					unit:RemoveModifierByName(SAITO)
					unit:RemoveModifierByName(MURA)
					unit:RemoveModifierByName(ROBIN)
					unit:RemoveModifierByName(SCATHACH)
				end
				return
			end

			-- как удар NSS: взрыв и на целях без стаков
			if args[1] == "boom" then
				for _, unit in pairs(targets) do
					unit:RemoveModifierByName(LI)
					EffectBars:Burst(unit, "shuwen")
				end
				return
			end

			local li = tonumber(args[1]) or 25
			local saito = tonumber(args[2]) or 4
			local mura = tonumber(args[3]) or 3
			local robin = tonumber(args[4]) or 12
			local scathach = tonumber(args[5]) or 6

			for _, unit in pairs(targets) do
				if li > 0 then
					unit:AddNewModifier(hero, nil, LI, { duration = 15, stacks = li })
				end
				if saito > 0 then
					local mod = unit:AddNewModifier(hero, nil, SAITO, { duration = 8 })
					if mod then mod:SetStackCount(saito) end
				end
				if mura > 0 then
					local mod = unit:AddNewModifier(hero, nil, MURA, { duration = 20 })
					if mod then mod:SetStackCount(mura) end
				end
				if robin > 0 then
					local mod = unit:AddNewModifier(hero, nil, ROBIN, { duration = 15 })
					if mod then mod:SetStackCount(robin) end
				end
				if scathach > 0 then
					local mod = unit:AddNewModifier(hero, nil, SCATHACH, { duration = 10 })
					if mod then mod:SetStackCount(math.min(scathach, 10)) end
				end
			end

			GameRules:SendCustomMessage(string.format("[effbars] %d юнитов: Ли %d, Сайто %d, Мурамаса %d, Робин %d, Скатах %d",
				#targets, li, saito, mura, robin, scathach), 0, 0)
		end
	},
	-- Диагностика слотов способностей: сколько их у Слуги, что реально лежит в каждом слоте
	-- и доехали ли пустые таланты special_bonus_fate_none_* (без них клиент падает по ALT).
	["slots"] = {
		level = CUSTOMCHAT_COMMAND_LEVEL_CHEAT_DEVELOPER,
		f = function(args, hero)
			if not hero or hero:IsNull() then return end
			local nTotal, nTalents, sLine = 0, 0, ""
			for i = 0, hero:GetAbilityCount() - 1 do
				local ability = hero:GetAbilityByIndex(i)
				if ability then
					nTotal = nTotal + 1
					if string.match(ability:GetName(), "special_bonus") then nTalents = nTalents + 1 end
					sLine = sLine .. i .. ":" .. ability:GetName() .. "  "
					print("[FateSlots] " .. i .. " = " .. ability:GetName())
					if nTotal % 6 == 0 then
						GameRules:SendCustomMessage(sLine, 0, 0)
						sLine = ""
					end
				end
			end
			if sLine ~= "" then GameRules:SendCustomMessage(sLine, 0, 0) end
			local sSummary = hero:GetUnitName() .. ": способностей " .. nTotal ..
				", из них талантов " .. nTalents .. ", GetAbilityCount() = " .. hero:GetAbilityCount()
			GameRules:SendCustomMessage("<font color='#FFCC00'>" .. sSummary .. "</font>", 0, 0)
			print("[FateSlots] " .. sSummary)
		end
	},
}
