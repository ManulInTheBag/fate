-- caster_5th_territory_creation — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_territory_creation = class({})

LinkLuaModifier("modifier_caster_death_checker", "abilities/medea/caster_5th_territory_creation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_territory_death_checker", "abilities/medea/caster_5th_territory_creation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_territory_mana_regen", "abilities/medea/caster_5th_territory_creation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_territory_root", "abilities/medea/caster_5th_immobilize", LUA_MODIFIER_MOTION_NONE)
-- ^ класс объявлен в caster_5th_immobilize: тот же самый модификатор объявляли оба datadriven-блока
LinkLuaModifier("modifier_territory_under_construction", "abilities/medea/caster_5th_territory_creation", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnTerritoryCreated, OnTerritoryOwnerDeath, OnTerritoryDeath, OnTerritoryPingThink

OnTerritoryCreated = function(keys)
	local caster = keys.caster
	local pid = caster:GetPlayerID()
	local ply = caster:GetPlayerOwner()
	local ability = keys.ability
	local hero = ply:GetAssignedHero()
	local targetPoint = keys.ability:GetCursorPosition()
	territoryAbilHandle = keys.ability
	

	-- Check if Workshop already exists 
	if caster.IsTerritoryPresent then
		ability:EndCooldown()
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Workshop_Exists")
		return 
	else
		caster.IsTerritoryPresent = true
	end

	caster:AddNewModifier(caster, ability, "modifier_caster_death_checker", {})

	-- Create Workshop at location
	local unitName = hero.IsTerritoryImproved and "caster_5th_territory_improved" or "caster_5th_territory"
	caster.Territory = CreateUnitByName(unitName, targetPoint, true, caster, caster, caster:GetTeamNumber()) 
	caster.Territory:SetControllableByPlayer(pid, true)
	LevelAllAbility(caster.Territory)
	caster.Territory:AddNewModifier(caster, keys.ability, "modifier_territory_death_checker", {}) 

	--[[
	-- Create spy unit for enemies
	local enemyTeamNumber = 0
    LoopOverPlayers(function(ply, plyID)
        if ply:GetAssignedHero():GetTeamNumber() ~= caster:GetTeamNumber() then
        	enemyTeamNumber = ply:GetAssignedHero():GetTeamNumber()
        	return
        end
    end)
	enemydummy = CreateUnitByName("sight_dummy_unit", caster.Territory:GetAbsOrigin(), false, keys.caster, keys.caster, enemyTeamNumber)
	enemydummy:SetDayTimeVisionRange(300)
	enemydummy:SetNightTimeVisionRange(300)
	local unseen = enemydummy:FindAbilityByName("dummy_unit_passive")
	unseen:SetLevel(1)
	Timers:CreateTimer(function() 
		if not caster.Territory:IsAlive() then 
			enemydummy:RemoveSelf()
			return 
		else
			if not enemydummy:IsNull() then 
				enemydummy:SetAbsOrigin(caster.Territory:GetAbsOrigin())
			end
			return 1.0
		end
	end)]]

	-- Do special handling for attribute
	Timers:CreateTimer(5, function() --because it takes 5 seconds for territory to be built
		if hero.IsTerritoryImproved and hero.IsTerritoryPresent and not caster.Territory:IsNull() then 
			truesightdummy = CreateUnitByName("sight_dummy_unit", caster.Territory:GetAbsOrigin(), false, nil, nil, keys.caster:GetTeamNumber())
			truesightdummy:AddNewModifier(caster, caster, "modifier_item_ward_true_sight", {true_sight_range = 600}) 
			local unseen = truesightdummy:FindAbilityByName("dummy_unit_passive")
			unseen:SetLevel(1)
			Timers:CreateTimer(function() 
				if not hero.IsTerritoryPresent then -- and not truesightdummy:IsNull() then 
					truesightdummy:RemoveSelf()
					return
				else
					truesightdummy:SetAbsOrigin(caster.Territory:GetAbsOrigin())
					return 1.0
				end
			end)

			-- Give out mana regen for nearby allies
			Timers:CreateTimer(function()
				if caster.Territory:IsNull() or not hero.IsTerritoryPresent then return end
			  local targets = FindUnitsInRadius(caster:GetTeam(), caster.Territory:GetOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
				for k,v in pairs(targets) do
			        --if v:GetUnitName() ~= "caster_5th_territory" then 
			         	v:AddNewModifier(caster, keys.ability, "modifier_territory_mana_regen", {duration = 1.0}) 
			        --end
			    end
				return 1.0
				end
			)
		end
	end)


	local warriorItem = CreateItem("item_summon_skeleton_warrior" , nil, nil)
	local archerItem = CreateItem("item_summon_skeleton_archer" , nil, nil)
	local dragItem = CreateItem("item_summon_ancient_dragon"  , nil, nil)
	local skillLevel = 1 + (caster:GetLevel() - 1)/3
	if skillLevel > 8 then skillLevel = 8 end
	warriorItem:SetLevel(skillLevel)
	archerItem:SetLevel(skillLevel)
	dragItem:SetLevel(skillLevel)

	-- Initialize territory
	caster.Territory:SetHealth(1 + caster.Territory:GetMaxHealth()/2)
	caster.Territory:SetMana(0)
	caster.Territory:SetBaseManaRegen(25) 
	caster.Territory:AddItem(warriorItem)
	caster.Territory:AddItem(archerItem)
	if hero.IsTerritoryImproved then
		caster.Territory:AddItem(dragItem)
		caster.Territory:AddItem(CreateItem("item_all_seeing_orb" , nil, nil))
	end
	giveUnitDataDrivenModifier(caster, caster.Territory, "pause_sealdisabled", 5.0)
	caster.Territory:AddNewModifier(caster, keys.ability, "modifier_territory_root", {}) 


	-- Constrcut territory over time
	local territoryConstTimer = 0
	Timers:CreateTimer(function()
		if territoryConstTimer == 10 then
			if hero.IsTerritoryImproved then
				caster.Territory:GiveMana(300)
			end
			return 
		end
		caster.Territory:SetHealth(caster.Territory:GetHealth() + caster.Territory:GetMaxHealth() / 20)
		territoryConstTimer = territoryConstTimer + 1
		return 0.5
		end
	)


end

OnTerritoryOwnerDeath = function(keys)
	local caster = keys.caster
	if not caster.Territory:IsNull() and caster.Territory:IsAlive() then
		caster.Territory:Execute(keys.ability, keys.caster.Territory)
	end
end

OnTerritoryDeath = function(keys)
	local caster = keys.caster
	caster:GetPlayerOwner():GetAssignedHero().IsTerritoryPresent = false

	-- Find all summons and forcekill them
	local summons = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 20000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false) 
	for k,v in pairs(summons) do
		print("Found unit " .. v:GetUnitName())
		if v:GetUnitName() == "caster_5th_skeleton_warrior" or v:GetUnitName() == "caster_5th_skeleton_archer" or v:GetUnitName() == "caster_5th_ancient_dragon" then
			v:Kill(nil, caster)
		end
	end
end

OnTerritoryPingThink = function(keys)
	local caster = keys.caster
	local enemyTeamNumber = 0
	--[[
    LoopOverPlayers(function(ply, plyID, playerHero)
        if playerHero:GetTeamNumber() ~= caster:GetTeamNumber() then
        	enemyTeamNumber = playerHero:GetTeamNumber()
        	return
        end
    end)
	MinimapEvent( enemyTeamNumber, caster, caster:GetAbsOrigin().x, caster:GetAbsOrigin().y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 2 )]]
end


function caster_5th_territory_creation:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: caster_ability / OnTerritoryCreated
	OnTerritoryCreated({
		caster = caster,
		ability = self,
		target = caster,
		target_points = { point },
		Target = "POINT"
	})
	EmitSoundOn("Hero_Rubick.Telekinesis.Cast", caster)
end

modifier_caster_death_checker = class({})


function modifier_caster_death_checker:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_caster_death_checker:OnDeath(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: caster_ability / OnTerritoryOwnerDeath
	OnTerritoryOwnerDeath({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker
	})
end

modifier_territory_death_checker = class({})

function modifier_territory_death_checker:IsHidden() return true end

function modifier_territory_death_checker:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_territory_death_checker:OnCreated(kv)
	if not IsServer() then return end
	self:StartIntervalThink(15.0)
end

function modifier_territory_death_checker:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_territory_death_checker:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: caster_ability / OnTerritoryPingThink
	OnTerritoryPingThink({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

function modifier_territory_death_checker:OnDeath(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: caster_ability / OnTerritoryDeath
	OnTerritoryDeath({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker
	})
end

modifier_territory_mana_regen = class({})


function modifier_territory_mana_regen:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
end

function modifier_territory_mana_regen:GetModifierConstantManaRegen()
	return 50
end

modifier_territory_under_construction = class({})

function modifier_territory_under_construction:IsHidden() return false end

function modifier_territory_under_construction:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end

function modifier_territory_under_construction:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "5.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(5.0, true)
	end
end

function modifier_territory_under_construction:OnRefresh(kv)
	self:OnCreated(kv)
end
