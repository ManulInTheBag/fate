LinkLuaModifier("modifier_hero_selection_skin", "modules/hero_selection/hero_replacer.lua", LUA_MODIFIER_MOTION_NONE)

function HeroSelection:SelectHero(playerId, heroName, beforeReplace, afterReplace, bSkipPrecache, skinNumber)
	Timers:CreateTimer(function()
		local connectionState = GetConnectionState(playerId)
		if connectionState == DOTA_CONNECTION_STATE_CONNECTED then
			local function SpawnHero()
				Timers:CreateTimer(function()
					connectionState = GetConnectionState(playerId)
					if connectionState == DOTA_CONNECTION_STATE_CONNECTED then
						local heroTableCustom = NPC_HEROES_CUSTOM[heroName] or NPC_HEROES[heroName]
						local oldhero = PlayerResource:GetSelectedHeroEntity(playerId)
						local hero
						local baseNewHero = heroTableCustom.base_hero or heroName

						if beforeReplace then beforeReplace(oldhero) end
						if oldhero then
							Timers:CreateTimer(FrameTime(), function()
								oldhero:ClearNetworkableEntityInfo()
								UTIL_Remove(oldhero)
							end)
							if oldhero:GetUnitName() == baseNewHero then -- Base unit equals, ReplaceHeroWith won't do anything
								local temp = PlayerResource:ReplaceHeroWith(playerId, FORCE_PICKED_HERO, 0, 0)
								Timers:CreateTimer(FrameTime(), function()
									temp:ClearNetworkableEntityInfo()
									UTIL_Remove(temp)
								end)
							end
							hero = PlayerResource:ReplaceHeroWith(playerId, baseNewHero, 0, 0)
						else
							print("[HeroSelection] For some reason player " .. playerId .. " has no hero. This player can't get a hero. Returning")
							return
						end
						HeroSelection:InitializeHeroClass(hero, heroTableCustom)
						for i = 0, hero:GetAbilityCount() - 1 do
							local ability = hero:GetAbilityByIndex(i)
							if ability and string.starts(ability:GetAbilityName(), "special_bonus_")
							and not IsFateNoneTalent(ability:GetAbilityName()) then
								UTIL_Remove(ability)
							end
						end
						-- Без единого таланта клиент падает по ALT, поэтому возвращаем пустышки
						GiveFateNoneTalents(hero)
						if heroTableCustom.base_hero then
							TransformUnitClass(hero, heroTableCustom)
							hero.UnitName = heroName
						end
						if Options:IsEquals("EnableAbilityShop") then
							for i = 0, hero:GetAbilityCount() - 1 do
								if hero:GetAbilityByIndex(i) then
									hero:RemoveAbility(hero:GetAbilityByIndex(i):GetName())
								end
							end
							hero:AddAbility("ability_empty")
							hero:AddAbility("ability_empty")
							hero:AddAbility("ability_empty")
							hero:AddAbility("ability_empty")
							hero:AddAbility("ability_empty")
							hero:AddAbility("ability_empty")
						end
						if skinNumber ~= 0 then 
							hero:AddNewModifier(hero, nil, "modifier_hero_selection_skin", {skinNumber = skinNumber})
						end
						if afterReplace then afterReplace(hero) end
					else
						return 0.1
					end
				end)
			end

			if bSkipPrecache then
				SpawnHero()
			else
				PrecacheUnitByNameAsync(GetKeyValue(heroName, "base_hero") or heroName, SpawnHero, playerId)
			end
		else
			return 0.1
		end
	end)
end

function HeroSelection:ChangeHero(playerId, newHeroName, keepExp, duration, item, callback, bUpdateStatus)
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)

	if not hero.ForcedHeroChange then
		if hero:HasModifier("modifier_shredder_chakram_disarm") then
			Containers:DisplayError(playerId, "#arena_hud_error_cant_change_hero")
			return false
		end
		if hero:HasAbility("centaur_stampede") then
			local heroTeam = PlayerResource:GetTeam(playerId)
			for i = 0, 23 do
				local playerHero = PlayerResource:GetSelectedHeroEntity(i)
				if playerHero and PlayerResource:GetTeam(i) == heroTeam and playerHero:HasModifier("modifier_centaur_stampede") then
					Containers:DisplayError(playerId, "#arena_hud_error_cant_change_hero")
					return false
				end
			end
		end

		if hero:HasAbility("necrolyte_reapers_scythe") and AnyUnitHasModifier("modifier_necrolyte_reapers_scythe", hero) then
			Containers:DisplayError(playerId, "#arena_hud_error_cant_change_hero")
			return false
		end
	end
	local preDuration = 0
	if hero:HasAbility("disruptor_thunder_strike") then
		local disruptor_thunder_strike = hero:FindAbilityByName("disruptor_thunder_strike")
		preDuration =
			disruptor_thunder_strike:GetSpecialValueFor("strikes") *
			disruptor_thunder_strike:GetSpecialValueFor("strike_interval")
	end
	if hero:HasAbility("monkey_king_wukongs_command") then
		preDuration = 0.5
		local originalPosition = hero:GetAbsOrigin()
		Timers:CreateTimer(FrameTime(), function()
			hero:SetAbsOrigin(Vector())
			Timers:CreateTimer(FrameTime(), function()
				hero:SetAbsOrigin(Vector(10000, 10000, 10000))
				Timers:CreateTimer(FrameTime(), function()
					hero:SetAbsOrigin(originalPosition)
				end)
			end)
		end)
	end

	hero.ChangingHeroProcessRunning = true
	ProjectileManager:ProjectileDodge(hero)
	hero:DestroyAllModifiers()
	hero:InterruptMotionControllers(false)
	hero:AddNewModifier(hero, nil, "modifier_hero_selection_transformation", nil)
	local xp = hero:GetCurrentXP()
	local location

	local startTime = GameRules:GetDOTATime(true, true)
	local items = {}
	local duelData = {}
	Timers:CreateTimer(preDuration, function()
		RemoveAllOwnedUnits(playerId)
		HeroSelection:SelectHero(playerId, newHeroName, function(oldHero)
			location = hero:GetAbsOrigin()
			local fountatin = FindFountain(PlayerResource:GetTeam(playerId))
			if not location and fountatin then location = fountatin:GetAbsOrigin() end

			for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
				local citem  = hero:GetItemInSlot(i)
				if citem and citem ~= item then
					local newItem = CreateItem(citem:GetName(), nil, nil)
					if citem:GetPurchaser() ~= hero then
						newItem.NotPurchasedByOwner = true
						newItem:SetPurchaser(citem:GetPurchaser())
					end
					newItem:SetPurchaseTime(citem:GetPurchaseTime())
					newItem:SetCurrentCharges(citem:GetCurrentCharges())
					if citem:GetCooldownTimeRemaining() > 0 then
						newItem.SavedCooldown = citem:GetCooldownTimeRemaining()
					end
					table.insert(items, newItem)
				else
					table.insert(items, CreateItem("item_dummy", hero, hero))
				end
			end

			duelData.StatusBeforeArena = hero.StatusBeforeArena
			duelData.OnDuel = hero.OnDuel
			duelData.ArenaBeforeTpLocation = hero.ArenaBeforeTpLocation
			duelData.DuelChecked = hero.DuelChecked
			for team,tab in pairs(Duel.heroes_teams_for_duel or {}) do
				for i,unit in pairs(tab) do
					if unit == hero then
						duelData.path = {team, i}
					end
				end
			end
		end, function(newHero)
			newHero:AddNewModifier(newHero, nil, "modifier_hero_selection_transformation", nil)
			FindClearSpaceForUnit(newHero, location, true)
			if keepExp then
				newHero:AddExperience(xp, 0, true, true)
			end
			for _,v in ipairs(items) do
				v:SetOwner(newHero)
				if not v.NotPurchasedByOwner then
					v:SetPurchaser(newHero)
					v.NotPurchasedByOwner = nil
				end
				if v.SavedCooldown then
					v:StartCooldown(v.SavedCooldown)
					v.SavedCooldown = nil
				end
				newHero:AddItem(v)
			end
			ClearSlotsFromDummy(newHero)

			for k,v in pairs(duelData) do
				if k ~= "path" then
					newHero[k] = v
				else
					Duel.heroes_teams_for_duel[v[1]][v[1]] = newHero
				end
			end
			Timers:CreateTimer(startTime + (duration or 0) - GameRules:GetDOTATime(true, true), function()
				if IsValidEntity(newHero) then
					newHero:RemoveModifierByName("modifier_hero_selection_transformation")
				end
			end)
			if callback then callback(newHero) end
		end, nil, bUpdateStatus)
	end)

	return true
end


modifier_hero_selection_skin = modifier_hero_selection_skin or class({})

function modifier_hero_selection_skin:IsHidden()                                                                       return true end
function modifier_hero_selection_skin:IsDebuff()                                                                       return false end
function modifier_hero_selection_skin:IsPurgable()                                                                     return false end
function modifier_hero_selection_skin:IsPurgeException()                                                               return false end
function modifier_hero_selection_skin:RemoveOnDeath()                                                                  return false end
function modifier_hero_selection_skin:IsDimensionException()                                                           return true end
function modifier_hero_selection_skin:AllowIllusionDuplicate()                                                         return true end
function modifier_hero_selection_skin:GetPriority()                                                                    return MODIFIER_PRIORITY_LOW end
function modifier_hero_selection_skin:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_MODEL_CHANGE
                    }
    return tFunc
end
function modifier_hero_selection_skin:GetModifierModelChange(keys)
    return self.sModelName
end
function modifier_hero_selection_skin:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
    self.skinNumber = hTable.skinNumber
    if IsServer() then
    	local tableData = PlayerTables:GetTableValue("hero_selection_heroes_data", self.hCaster:GetUnitName())
    	local skinData = tableData.skins["skin_"..self.skinNumber]
    	
    	if skinData then
        	self.sModelName = tableData.skins["skin_"..self.skinNumber].model--"models/zlodemon/salter_skin/sbr_alter.vmdl"
        else
        	self.sModelName = tableData.skins["skin_0"].model
        end
    end
end
function modifier_hero_selection_skin:OnRefresh(hTable)
    self:OnCreated(hTable)
end