-- astolfo_hippogriff_raid — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/astolfo/astolfo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

astolfo_hippogriff_raid = class({})

LinkLuaModifier("modifier_hippogriff_raid_respawn_checker", "abilities/astolfo/astolfo_hippogriff_raid", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/astolfo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnRaidCast, OnRaidStart, OnRaidCountReset, CreateBeaconForEnemies

OnRaidCast = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	if caster:HasModifier("modifier_hippogriff_ride_ascended") or caster.RaidActive then 
		ability:EndCooldown()
		caster:GiveMana(ability:GetManaCost(1)) 
		caster:Stop()
		return 
	end 

	caster:EmitSound("Astolfo.Hippogriff_Raid_Cast")
end

OnRaidStart = function(keys)
	local caster = keys.caster
	local targetPoint = caster.HippogriffCastLocation
	local ability = keys.ability
	local firstDmg = keys.FirstDamage

	if caster.bIsRidingAcquired then
	 	firstDmg = firstDmg + 150
	end

	--if caster.bIsRidingAcquired then firstDmgPct = firstDmgPct + 10 end
	local radius = keys.Radius
	local stunDuration = keys.StunDuration
	local secondDmg = keys.SecondDamage
	if caster.bIsRidingAcquired then
	 	secondDmg = secondDmg + 350
	end
	if caster:HasModifier("modifier_hippogriff_ride_ascended") or not IsInSameRealm(caster:GetAbsOrigin(), targetPoint) then
		caster:GiveMana(ability:GetManaCost(1))
		ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Be_Cast_Now")
		return
	end

	--[[if caster.nCurrentRaidAmount then
		if caster.nCurrentRaidAmount >= 2 then
			caster:GiveMana(ability:GetManaCost(1))
			ability:EndCooldown() 
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Be_Cast_Now")
			return
		else
			caster.nCurrentRaidAmount = caster.nCurrentRaidAmount+1
		end
	else
		caster.nCurrentRaidAmount = 1
	end]]

	caster.RaidActive = true

	Timers:CreateTimer(2.0, function()		
		caster.RaidActive = false
		return
	end)

	caster:EmitSound("Astolfo.Hippogriff_Raid_Cast_Success")
	caster:EmitSound("Hero_Phoenix.IcarusDive.Cast")

	local ascendFx = ParticleManager:CreateParticle( "particles/custom/astolfo/hippogriff_raid/astolfo_hippogriff_raid_ascend.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl( ascendFx, 0, caster:GetAbsOrigin())
	-- create beacon for team
	local teamBeacon = ParticleManager:CreateParticleForTeam("particles/custom/astolfo/astolfo_ground_mark_flex.vpcf", PATTACH_CUSTOMORIGIN, nil, caster:GetTeam())
	ParticleManager:SetParticleControl( teamBeacon, 0, targetPoint)

	if caster.bIsRidingAcquired then radius = radius + 100 end

	AddFOWViewer(caster:GetTeamNumber(), targetPoint, radius, 6, false)
	Timers:CreateTimer(2.0, function()
		CreateBeaconForEnemies(caster, targetPoint)
		EmitGlobalSound("Astolfo.Hippogriff_Raid_Shout")
		Timers:CreateTimer(1.5, function()
			EmitGlobalSound("Astolfo.Leap")

			local birdOrigin = caster:GetAbsOrigin() + Vector(0,0,2000) + (caster:GetAbsOrigin() - targetPoint):Normalized()*1000
			local dist = (targetPoint  - birdOrigin):Length2D()
			local birdVector = (targetPoint  - birdOrigin):Normalized() * dist * 3
			local swordFxIndex = ParticleManager:CreateParticle( "particles/custom/astolfo/raid_hippogriff.vpcf", PATTACH_CUSTOMORIGIN, caster )
			ParticleManager:SetParticleControl( swordFxIndex, 0, birdOrigin )
			ParticleManager:SetParticleControl( swordFxIndex, 1, birdVector )
			-- local swordFxIndex = ParticleManager:CreateParticle( "particles/custom/astolfo/astolfo_hippogriff_raid_flyer.vpcf", PATTACH_CUSTOMORIGIN, nil )
			-- ParticleManager:SetParticleControl( swordFxIndex, 0, birdOrigin)
			-- ParticleManager:SetParticleControl( swordFxIndex, 1,  birdVector)
		end)
		Timers:CreateTimer(1.0, function()
			local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius
		            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			for k,v in pairs(targets) do
		        DoDamage(caster, v, firstDmg, DAMAGE_TYPE_MAGICAL, 0, ability, false)
		        giveUnitDataDrivenModifier(caster, v, "locked", stunDuration)
		        --giveUnitDataDrivenModifier(caster, v, "stunned", stunDuration)
		    end

			EmitGlobalSound("Astolfo.SolarForge")
			local firstImpactIndex = ParticleManager:CreateParticle( "particles/custom/astolfo/hippogriff_raid/astolfo_hippogriff_raid_first_impact.vpcf", PATTACH_CUSTOMORIGIN, nil )
		    ParticleManager:SetParticleControl(firstImpactIndex, 0, Vector(1,0,0))
		    ParticleManager:SetParticleControl(firstImpactIndex, 1, Vector(radius-50,0,0))
		    ParticleManager:SetParticleControl(firstImpactIndex, 2, Vector(1.5,0,0))
		    ParticleManager:SetParticleControl(firstImpactIndex, 3, targetPoint)
		    ParticleManager:SetParticleControl(firstImpactIndex, 4, Vector(0,0,0))

			Timers:CreateTimer(0.75, function()
				
				local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius
			            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
				for k,v in pairs(targets) do
			        DoDamage(caster, v, secondDmg, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			        if caster.bIsRidingAcquired then
			        	v:AddNewModifier(caster, v, "modifier_stunned", { Duration = 0.5 })
			        end
			    end
			    ScreenShake(targetPoint, 15, 1.0, 2, 2000, 0, true)

			    --[[if caster.nCurrentRaidAmount >= 1 then
					caster.nCurrentRaidAmount = caster.nCurrentRaidAmount-1
				end]]
				caster.RaidActive = false

				EmitSoundOnLocationWithCaster(targetPoint, "Misc.Crash", caster)
				local secondImpactIndex = ParticleManager:CreateParticle( "particles/custom/astolfo/hippogriff_raid/astolfo_hippogriff_raid_second_impact.vpcf", PATTACH_CUSTOMORIGIN, nil )
			    ParticleManager:SetParticleControl(secondImpactIndex, 0, targetPoint)
			    ParticleManager:SetParticleControl(secondImpactIndex, 1, Vector(radius,1,1))
			end)
		end)
	end)
	--[[ 
	2 seconds timer
		create beacon at location
	4 seconds timer
		for enemies in radius at target location
			do damage
			apply stun

	5.5 seconds timer
		for enemies in radius at target loc
			do damage
	--]]
end

OnRaidCountReset = function(keys)
	local caster = keys.caster
	caster.nCurrentRaidAmount = 0
	
end

CreateBeaconForEnemies = function(caster, targetPoint)
    LoopOverPlayers(function(player, playerID, playerHero)
    	--print("looping through " .. playerHero:GetName())
        if playerHero:GetTeamNumber() ~= caster:GetTeamNumber() and player and playerHero then
        	AddFOWViewer(playerHero:GetTeamNumber(), targetPoint, 150, 2.5, false)
        	local beaconIndex = ParticleManager:CreateParticleForPlayer("particles/custom/astolfo/astolfo_ground_mark_flex.vpcf", PATTACH_CUSTOMORIGIN, nil, player)
			ParticleManager:SetParticleControl( beaconIndex, 0, targetPoint)
        	-- set a timer to check whether affected enemies retain buff
        	local beaconCounter = 0
        	Timers:CreateTimer(function() 
        		if beaconCounter > 40 then return end
        		if playerHero:HasModifier("modifier_la_black_luna_deaf") then
        			ParticleManager:SetParticleControl( beaconIndex, 0, Vector(20000,20000,1000))
        		else
        			ParticleManager:SetParticleControl( beaconIndex, 0, targetPoint)
        		end
        		beaconCounter = beaconCounter + 1
        		return 0.1
        	end)
        end
    end)
end


function astolfo_hippogriff_raid:GetIntrinsicModifierName()
	return "modifier_hippogriff_raid_respawn_checker"
end

function astolfo_hippogriff_raid:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function astolfo_hippogriff_raid:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: astolfo_ability / OnRaidCast
	OnRaidCast({ caster = caster, ability = self, target = caster, target_points = { point } })
	return true
end

function astolfo_hippogriff_raid:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: astolfo_ability / OnRaidStart
	OnRaidStart({
		caster = caster,
		ability = self,
		target = caster,
		target_points = { point },
		Delay = self:GetSpecialValueFor("total_delay"),
		Radius = self:GetSpecialValueFor("radius"),
		Target = "POINT",
		FirstDamage = self:GetSpecialValueFor("first_impact_damage"),
		StunDuration = self:GetSpecialValueFor("first_impact_stun_duration"),
		SecondDamage = self:GetSpecialValueFor("second_impact_damage")
	})
end

modifier_hippogriff_raid_respawn_checker = class({})

function modifier_hippogriff_raid_respawn_checker:IsHidden() return true end

function modifier_hippogriff_raid_respawn_checker:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_RESPAWN,
	}
end

function modifier_hippogriff_raid_respawn_checker:OnRespawn(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: astolfo_ability / OnRaidCountReset
	OnRaidCountReset({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end
