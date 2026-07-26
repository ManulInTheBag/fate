-- master_presence_resonator — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

master_presence_resonator = class({})

-- Логика перенесена из scripts/vscripts/master_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnPRStart

OnPRStart = function(keys)
    local caster = keys.caster
    local ability = keys.ability
    local hero = PlayerResource:GetSelectedHeroEntity(caster:GetPlayerOwnerID())
    local heroTable = {}
    local target = nil

    local enemiesAlive = 0
    
    if not hero:IsAlive() then
    	return
    end

    LoopOverPlayers(function(player, playerID, playerHero)
    	if playerHero:IsAlive() and playerHero:GetTeamNumber() ~= hero:GetTeamNumber() then
    		enemiesAlive = enemiesAlive + 1
    	end
    end)

    LoopOverPlayers(function(player, playerID, playerHero)
		if playerHero:GetTeamNumber() ~= hero:GetTeamNumber() then
			if (playerHero:IsAlive() and CanBeDetected(playerHero))
			or (playerHero:IsAlive() and enemiesAlive == 1) then
				table.insert(heroTable, playerHero)
			end
		end
	end)

    if #heroTable > 0 then
    	if #heroTable == 1 then 
    		target = heroTable[1]
	    	MinimapEvent( hero:GetTeamNumber(), hero, target:GetAbsOrigin().x, target:GetAbsOrigin().y, DOTA_MINIMAP_EVENT_ENEMY_TELEPORTING, 2)
    	else
    		local nearestHero = heroTable[1]
    		local nearestDistance = (heroTable[1]:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D()

    		for i = 2, #heroTable do
	    		local distance = (heroTable[i]:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D()	    		

	    		if distance < nearestDistance then
	    			nearestHero = heroTable[i]
	    			nearestDistance = distance
	    		end
	    	end

	    	target = nearestHero
	    	

	    	--SpawnAttachedVisionDummy(hero, target, 100, 4, true)
	    	--SpawnAttachedVisionDummy(target, hero, 100, 4, true)    	

	    	MinimapEvent( hero:GetTeamNumber(), hero, target:GetAbsOrigin().x, target:GetAbsOrigin().y, DOTA_MINIMAP_EVENT_ENEMY_TELEPORTING, 2)
    	end    	
    	local target_master_ability = target.MasterUnit:FindAbilityByName(ability:GetName())

    	target:AddNewModifier(hero, nil, "modifier_vision_provider", { Duration = 2 })
	    hero:AddNewModifier(target, nil, "modifier_vision_provider", { Duration = 2 })
    end

    GameRules:SendCustomMessage("<font color='#58ACFA'>" .. FindName(hero:GetName()) .."</font>" ..  "<font color='#ff9900'>'s Master just used Presence Resonator!", 0, 0)

    if hero:GetName() == "npc_dota_hero_mirana" and hero.bIsIDAcquired then
    	ability:EndCooldown()
    	ability:StartCooldown(ability:GetCooldown(1)/2)
    end

    EmitGlobalSound("Resonator.Activate")
end


function master_presence_resonator:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: master_ability / OnPRStart
	OnPRStart({ caster = caster, ability = self, target = caster })
end
