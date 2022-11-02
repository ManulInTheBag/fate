if HeroDemo == nil then
	_G.HeroDemo = class({}) -- put HeroDemo in the global scope
	--refer to: http://stackoverflow.com/questions/6586145/lua-require-with-global-local
end

--------------------------------------------------------------------------------
-- GameEvent:OnGameRulesStateChange
--------------------------------------------------------------------------------
function HeroDemo:OnGameRulesStateChange()
    if not GameRules:IsCheatMode() then
        return
    end
	local nNewState = GameRules:State_Get()
	--print( "OnGameRulesStateChange: " .. nNewState )

	if nNewState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		--PlayerResource:GetPlayer(0):SetSelectedHero("npc_dota_hero_abaddon")
		print( "OnGameRulesStateChange: Hero Selection" )
		--PlayerResource:GetPlayer(0):SetSelectedHero("npc_dota_hero_abaddon")

		Timers:CreateTimer(1, function()
--PlayerResource:GetPlayer(0):SetSelectedHero("")
	end)

		Timers:CreateTimer(2, function()
--PlayerResource:GetPlayer(0):SetSelectedHero("npc_dota_hero_primal_beast")
	end)

	elseif nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
		
		--print( "OnGameRulesStateChange: Pre Game Selection" )
        self:FindTowers()
        --for iPlayerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
            --CustomUI:DynamicHud_Create( iPlayerID, "Hero_Demo", "file://{resources}/layout/custom_game/anime/anime_demo.xml", nil )
        --end
	elseif nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--print( "OnGameRulesStateChange: Game In Progress" )
	end
end

--------------------------------------------------------------------------------
-- GameEvent: OnHeroFinishSpawn
--------------------------------------------------------------------------------
function HeroDemo:OnHeroFinishSpawn(hEvent)
    --DeepPrintTable(hEvent)
    local hHero = EntIndexToHScript(hEvent.heroindex)
    if IsNotNull(hHero) then
    	local iPlayerID = hHero:GetPlayerOwnerID()
    	if not PlayerResource:IsFakeClient(iPlayerID) then
	    	--print(iPlayerID, hHero:GetMainControllingPlayer())
	    	CustomUI:DynamicHud_Create( -1, "Anime_HerotestMenu", "file://{resources}/layout/custom_game/eyeherodemo/eyeherodemo.xml", {pepeg = 100} )

	    	self:OnSelectSpawnHeroButtonPressed(nil, {str = "18"})
	    end
    end
end

--------------------------------------------------------------------------------
-- GameEvent: OnNPCSpawned
--------------------------------------------------------------------------------
function HeroDemo:OnNPCSpawned( event )
    if not GameRules:IsCheatMode() then
        return
    end
	--print( "^^^HeroDemo:OnNPCSpawned" )

	spawnedUnit = EntIndexToHScript( event.entindex )

	if spawnedUnit == nil then
		return
	end

	--DeepPrintTable( event )

	if spawnedUnit:GetUnitName() == "npc_dota_neutral_caster" then
		--print( "Neutral Caster spawned" )
		spawnedUnit:SetContextThink( "self:Think_InitializeNeutralCaster", function() return self:Think_InitializeNeutralCaster( spawnedUnit ) end, 0 )
	end

	if spawnedUnit:GetPlayerOwnerID() == 0 and spawnedUnit:IsRealHero() and not spawnedUnit:IsClone() and not spawnedUnit:IsTempestDouble() then
		--print( "spawnedUnit is player's hero" )

		-- clean up ui element for previous player hero if we have a different ent index
		if self.m_nPlayerEntIndex ~= -1 and self.m_nPlayerEntIndex ~= event.entindex then
			local event_data =
			{
				entindex = self.m_nPlayerEntIndex
			}
			CustomGameEventManager:Send_ServerToAllClients( "remove_hero_entry", event_data )
		end

		self.m_nPlayerEntIndex = event.entindex

		local event_data =
		{
			hero_id = spawnedUnit:GetHeroID()
		}
		CustomGameEventManager:Send_ServerToAllClients( "set_player_hero_id", event_data )

		local hPlayerHero = spawnedUnit
		hPlayerHero:SetContextThink( "self:Think_InitializePlayerHero", function() return self:Think_InitializePlayerHero( hPlayerHero ) end, 0 )
	end

	if event.is_respawn == 0 and spawnedUnit:IsRealHero() and not spawnedUnit:IsClone() and not spawnedUnit:IsTempestDouble() then
		local event_data =
		{
			entindex = event.entindex
		}
		CustomGameEventManager:Send_ServerToAllClients( "add_new_hero_entry", event_data )
	end
end

--------------------------------------------------------------------------------
-- GameEvent: OnItemPurchased
--------------------------------------------------------------------------------
function HeroDemo:OnItemPurchased( event )
    if not GameRules:IsCheatMode() then
        return
    end
	--local hBuyer = PlayerResource:GetPlayer( event.PlayerID )
	--local hBuyerHero = hBuyer:GetAssignedHero()
	local hBuyerHero = PlayerResource:GetSelectedHeroEntity(event.PlayerID)
	if IsNotNull(hBuyerHero) then
		hBuyerHero:ModifyGold( event.itemcost, true, 0 )
	end
end

--------------------------------------------------------------------------------
-- GameEvent: OnNPCReplaced
--------------------------------------------------------------------------------
function HeroDemo:OnNPCReplaced( event )
    if not GameRules:IsCheatMode() then
        return
    end
	local sNewHeroName = PlayerResource:GetSelectedHeroName( event.new_entindex )
	--print( "sNewHeroName == " .. sNewHeroName ) -- we fail to get in here
	self:BroadcastMsg( "Changed hero to " .. sNewHeroName )
end
