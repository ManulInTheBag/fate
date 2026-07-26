LinkLuaModifier("modifier_workshop_recall", "abilities/caster/modifier_workshop_recall", LUA_MODIFIER_MOTION_NONE)
territoryAbilHandle = nil -- Ability handle for Create Workshop
ATTRIBUTE_HG_INT_MULTIPLIER = 0

--[[
	Author: Dun1007
	Date: 8.23.2015.
	
	Initializes Workshop
]]
--[[
	Author: Dun1007
	Date: 8.23.2015.
	
	Called when Caster(5th) is killed in order to clean up existing Workshop.
]]
--[[
	Author: Dun1007
	Date: 9.2.2015.
	
	Ping Caster's Workshop every 15 seconds to enemy
]]
--[[
	Author: Dun1007
	Date: 8.23.2015.
	
	Called when Workshop is killed in order to clean up summons
]]
--[[
	Author: Dun1007
	Date: 8.23.2015.
	
	Explode Workshop and deal damage to nearby enemies

	caster : Workshop
	hero : Caster(5th)
]]

--[[
	Author: Dun1007
	Date: 8.23.2015.
	
	Initialize drain mana and run a timer to check if it is resolved

	caster : Workshop
	target : Target
	hero : Caster(5th)
]]
--[[
	Author: Dun1007
	Date: 8.23.2015.
	
	End Mana Drain
]]
--[[
	Author: Dun1007
	Date: 8.23.2015.
	
	Initialize Skeleton Summon

	caster : Workshop
	ability : The respective item

	Warrior parameters : keys.Health/keys.Damag/keys.ArmorRatio/keys.HealthRatio/keys.MSRatio
	Archer parameters : keys.DamageRatio instead of ArmorRatio
]]


function OnSummonSkeleton(keys)
	local caster = keys.caster
	local ability = keys.ability
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local pid = caster:GetPlayerOwner():GetPlayerID()
	local unitname = nil

	if caster.IsMobilized then return end 

	caster:GetItemInSlot(0):StartCooldown(5)
	caster:GetItemInSlot(1):StartCooldown(5)

	if ability:GetName()  == "item_summon_skeleton_warrior"  then
		unitname =  "caster_5th_skeleton_warrior"
	elseif ability:GetName()  == "item_summon_skeleton_archer" then
		unitname = "caster_5th_skeleton_archer"
	end

	-- Summon spooky skeletal 
	local spooky = CreateUnitByName(unitname, caster:GetAbsOrigin(), true, nil, nil, caster:GetTeamNumber()) 
	spooky:SetControllableByPlayer(pid, true)
	spooky:SetOwner(caster:GetPlayerOwner():GetAssignedHero())
	LevelAllAbility(spooky)
	FindClearSpaceForUnit(spooky, spooky:GetAbsOrigin(), true)
	spooky:AddNewModifier(caster, nil, "modifier_kill", {duration = 25})

	-- Set skeletal stat according to parameters
	spooky:SetMaxHealth(keys.Health)
	spooky:SetBaseMaxHealth(keys.Health)
	spooky:SetHealth(keys.Health)
	spooky:SetBaseDamageMax(keys.Damage)
	spooky:SetBaseDamageMin(keys.Damage)
	-- Bonus properties(give it 0.1 sec delay just in case)
	Timers:CreateTimer(0.1, function()
		spooky:SetMaxHealth(keys.Health + hero:GetIntellect()*keys.HealthRatio)
		spooky:SetBaseMaxHealth(keys.Health + hero:GetIntellect()*keys.HealthRatio)
		spooky:SetHealth(keys.Health + hero:GetIntellect()*keys.HealthRatio)
		
		spooky:SetBaseMoveSpeed(spooky:GetBaseMoveSpeed() + hero:GetIntellect()*keys.MSRatio)
		if unitname == "caster_5th_skeleton_warrior" then
			spooky:SetPhysicalArmorBaseValue(spooky:GetPhysicalArmorValue(false) + hero:GetIntellect()*keys.ArmorRatio)
		else
			spooky:SetBaseDamageMax(spooky:GetBaseDamageMin() + hero:GetIntellect()*keys.DamageRatio)
			spooky:SetBaseDamageMin(spooky:GetBaseDamageMax() + hero:GetIntellect()*keys.DamageRatio)
		end 
	end)


	
end

--[[
	Author: Dun1007
	Date: 8.23.2015.
	
	Initialize Dragon Summon

	caster : Workshop
	ability : The respective item
]]
LinkLuaModifier("modifier_medea_dragon", "abilities/caster/modifier_medea_dragon", LUA_MODIFIER_MOTION_NONE)

function OnSummonDragon(keys)
	local caster = keys.caster
	local ability = keys.ability
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local pid = caster:GetPlayerOwner():GetPlayerID()

	if caster.IsMobilized then return end 

	print("KEK DRAGON")
	-- Kill the existing dragon
	-- local dragFind = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	-- for k,v in pairs(dragFind) do
	-- 	print(v:GetClassname())
	-- 	if v:GetUnitName() == "caster_5th_ancient_dragon" then
	-- 		print("KEK TRYING REMOVE")
	-- 		v:ForceKill(false)
	-- 	end
	-- end
	if IsNotNull(caster.__hMedeyaDragonCringe) then
		caster.__hMedeyaDragonCringe:Kill(nil, caster)
		caster.__hMedeyaDragonCringe = nil
	end
	caster.__hMedeyaDragonCringe = CreateUnitByName("caster_5th_ancient_dragon", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
	local drag = caster.__hMedeyaDragonCringe
	print(drag:GetClassname(), "WTF")
	--drag:SetPlayerID(pid) 
	drag:SetControllableByPlayer(pid, true)
	drag:SetOwner(caster:GetPlayerOwner():GetAssignedHero())
	LevelAllAbility(drag)
	FindClearSpaceForUnit(drag, drag:GetAbsOrigin(), true)
	drag:AddItem(CreateItem("item_caster_5th_mount" , nil, nil))
	Timers:CreateTimer(60, function()
		if IsNotNull(drag) then
			drag:Kill(nil, caster)
		end
	end)
	drag:AddNewModifier(caster, nil, "modifier_kill", {duration = 61})
	drag:AddNewModifier(caster, nil, "modifier_medea_dragon", {duration = 61})

	drag:SetMaxHealth(keys.Health)
	drag:SetHealth(keys.Health)
	drag:SetBaseDamageMax(keys.Damage)
	drag:SetBaseDamageMin(keys.Damage)
	drag:SetMana(drag:GetMaxMana() + hero:GetIntellect()*keys.ManaRatio)

	Timers:CreateTimer(0.1, function()
		-- Bonus properties(give it 0.1 sec delay just in case)
		local newHealth = drag:GetMaxHealth() + hero:GetIntellect()*keys.HealthRatio
		drag:SetMaxHealth(newHealth)
		drag:SetHealth(newHealth)
		drag:SetBaseMoveSpeed(drag:GetBaseMoveSpeed() + hero:GetIntellect()*keys.MSRatio)
	end)

	local skillLevel = 1 + (hero:GetLevel() - 1)/3
	if skillLevel > 8 then skillLevel = 8 end

	drag:FindAbilityByName("caster_5th_dragon_frostbite"):SetLevel(skillLevel)
	drag:FindAbilityByName("caster_5th_dragon_arcane_wrath"):SetLevel(skillLevel)
    local playerData = {
        transport = drag:entindex()
    }
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "player_summoned_transport", playerData )
end

--[[
	Author: Dun1007
	Date: 8.23.2015.
	
	Initialize Dragon Summon

	caster : Workshop
	ability : The respective item
]]
function CasterFarSight(keys)
	local caster = keys.caster
	local radius = keys.Radius
	local hero = caster:GetPlayerOwner():GetAssignedHero() 
	local dist = (hero:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()

	if caster.IsMobilized then return end 

	if dist > 500 then
		keys.ability:EndCooldown() 
		caster:GiveMana(100)
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Caster_Out_Of_Radius")
		return
	end

	if ClairUsed(caster:GetTeamNumber(), 8) then
		keys.ability:EndCooldown() 
		caster:GiveMana(100)
		SendErrorMessage(caster:GetPlayerOwnerID(), "#another_clair_used")
		return
	end
	local truesightdummy = SpawnVisionDummy(caster, keys.ability:GetCursorPosition(), radius, 9, true)
	truesightdummy:SetDayTimeVisionRange(radius)
	truesightdummy:SetNightTimeVisionRange(radius)
	truesightdummy:EmitSound("Hero_KeeperOfTheLight.BlindingLight") 

	local unseen = truesightdummy:FindAbilityByName("dummy_unit_passive")
	unseen:SetLevel(1)
 

	local circleFxIndexEnemyTeam = ParticleManager:CreateParticleForTeam( "particles/custom/archer/archer_clairvoyance_circle_enemyteam.vpcf",  PATTACH_WORLDORIGIN, nil, caster:GetOpposingTeamNumber() )
	ParticleManager:SetParticleShouldCheckFoW(circleFxIndexEnemyTeam, false)
	ParticleManager:SetParticleControl( circleFxIndexEnemyTeam, 0, truesightdummy:GetAbsOrigin() )
	ParticleManager:SetParticleControl( circleFxIndexEnemyTeam, 1, Vector( radius, radius, radius ) )
	ParticleManager:SetParticleControl( circleFxIndexEnemyTeam, 2, Vector( 8, 0, 0 ) )
	local circleFxIndexTeam = ParticleManager:CreateParticleForTeam( "particles/custom/archer/archer_clairvoyance_circle_yourteam.vpcf", PATTACH_WORLDORIGIN, nil,caster:GetTeamNumber() )
	ParticleManager:SetParticleControl( circleFxIndexTeam, 0, truesightdummy:GetAbsOrigin() )
	ParticleManager:SetParticleControl( circleFxIndexTeam, 1, Vector( radius, radius, radius ) )
	ParticleManager:SetParticleControl( circleFxIndexTeam, 2, Vector( 8, 0, 0 ) )
	
	local dustFxIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_clairvoyance_dust.vpcf",  PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleShouldCheckFoW(dustFxIndex, false)
	ParticleManager:SetParticleControl( dustFxIndex, 0, truesightdummy:GetAbsOrigin() )
	ParticleManager:SetParticleControl( dustFxIndex, 1, Vector( radius, radius, radius ) )
	
	ParticleManager:SetParticleControl( dustFxIndex, 1, Vector( radius, radius, radius ) )
			
	-- Destroy particle after delay
	Timers:CreateTimer( 8, function()
			ParticleManager:DestroyParticle( circleFxIndexEnemyTeam, false )
			ParticleManager:DestroyParticle( dustFxIndex, false )
			ParticleManager:ReleaseParticleIndex( circleFxIndexEnemyTeam )
			ParticleManager:ReleaseParticleIndex( dustFxIndex )
			ParticleManager:DestroyParticle( circleFxIndexTeam, false )
			ParticleManager:ReleaseParticleIndex( circleFxIndexTeam )
			return nil
		end
	)
end

--[[
	Author: Dun1007
	Date: 8.24.2015.
	
	Issues stop order when Skeleton attempts attack a ward
]]
--[[
	Author: Dun1007
	Date: 8.24.2015.
	
	Applies stun when Skeleton's bash is successful
]]
--[[
	Author: Dun1007
	Date: 8.24.2015.
	
	Launch the breath of ice frontward
]]
--[[
	Author: Dun1007
	Date: 8.25.2015.
	
	Apply damage and root to enemies hit by ice breath
]]
--[[
	Author: Dun1007
	Date: 8.25.2015.
	
	Attach effect when Arcane Wrath starts casting
]]
function OnArcaneWrathCast(keys)
	local caster = keys.caster 
	local pid = caster:GetPlayerOwnerID()
	local hero = PlayerResource:GetSelectedHeroEntity(pid)
	if not hero.IsMounted then
		caster:Stop()
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Be_Cast_Now")
		return
	end

	local pfx = ParticleManager:CreateParticle("particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_freezing_field_casterribbons_arcana1.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl( pfx, 0, Vector(caster:GetAbsOrigin().x, caster:GetAbsOrigin().y, caster:GetAbsOrigin().z+300))
	caster:EmitSound("Hero_Ancient_Apparition.ColdFeetCast")
	Timers:CreateTimer(1.0, function()
		ParticleManager:DestroyParticle(pfx, false)
	end)
end

--[[
	Author: Dun1007
	Date: 8.25.2015.
	
	BOOM
]]
function OnArcaneWrathStart(keys)
	local caster = keys.caster
	local targetPos = keys.ability:GetCursorPosition()
	--provide vision
	local truesightdummy = CreateUnitByName("sight_dummy_unit", keys.ability:GetCursorPosition(), false, nil, nil, keys.caster:GetTeamNumber())
	truesightdummy:SetDayTimeVisionRange(keys.Radius)
	truesightdummy:SetNightTimeVisionRange(keys.Radius)
	local unseen = truesightdummy:FindAbilityByName("dummy_unit_passive")
	unseen:SetLevel(1)

	Timers:CreateTimer(keys.StunDuration, function() DummyEnd(truesightdummy) return end)

    local targets = FindUnitsInRadius(caster:GetTeam(), targetPos, nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
    for k,v in pairs(targets) do
    	DoDamage(caster, v, keys.Damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
    	v:AddNewModifier(caster, v, "modifier_stunned", {Duration = keys.StunDuration})
    end


	EmitSoundOnLocationWithCaster(targetPos, "Hero_ObsidianDestroyer.SanityEclipse.Cast", caster)
	local ArcaneWrathFx = ParticleManager:CreateParticle("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_sanity_eclipse_area.vpcf", PATTACH_CUSTOMORIGIN, caster)
  	ParticleManager:SetParticleControl(ArcaneWrathFx, 0, targetPos) 
	ParticleManager:SetParticleControl(ArcaneWrathFx, 1, Vector(400, 0, 0)) 

	Timers:CreateTimer(2.0, function()
		ParticleManager:DestroyParticle(ArcaneWrathFx, false)
	end)
end

function OnMountStart(keys)
	local caster = keys.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	Timers:CreateTimer(0.2, function()
		if caster:IsAlive() and not hero:HasModifier("jump_pause") then
			if hero.IsMounted then
				-- If Caster is attempting to unmount on not traversable terrain,
				if GridNav:IsBlocked(caster:GetAbsOrigin()) or not GridNav:IsTraversable(caster:GetAbsOrigin()) then
					keys.ability:EndCooldown()
					SendErrorMessage(hero:GetPlayerOwnerID(), "#Cannot_Unmount")
					return								
				else
					caster:SwapAbilities("caster_5th_dragon_arcane_wrath", "fate_empty2", true, true) 
					hero:RemoveModifierByName("modifier_mount_caster")
					caster:RemoveModifierByName("modifier_mount")
					hero.IsMounted = false
					SendMountStatus(hero)
				end
			elseif (caster:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D() < 400 and not hero:HasModifier("stunned") and not hero:HasModifier("modifier_stunned") then
				hero.IsMounted = true
				caster:SwapAbilities("caster_5th_dragon_arcane_wrath", "fate_empty2", true, true) 
				keys.ability:ApplyDataDrivenModifier(caster, hero, "modifier_mount_caster", {})
				keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_mount", {}) 
				SendMountStatus(hero)

				return
			end 
		end
	end)
end


--[[
	Author: Dun1007
	Date: 8.25.2015.
	
	Positions Caster on Dragon's back every tick as long as Caster is mounted
]]
function MountFollow(keys)
	local caster = keys.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	if not caster:IsNull() and IsValidEntity(caster) then
		hero:SetAbsOrigin(caster:GetAbsOrigin() + Vector(0,0,600))
	end
end
--[[
	Author: Dun1007
	Date: 8.25.2015.
	
	Un-mounts Caster
]]
function OnMountDeath(keys)
	local caster = keys.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero:RemoveModifierByName("modifier_mount_caster")
	caster:SwapAbilities("caster_5th_dragon_arcane_wrath", "fate_empty2", false, true) 
	hero.IsMounted = false
	SendMountStatus(hero)
end

