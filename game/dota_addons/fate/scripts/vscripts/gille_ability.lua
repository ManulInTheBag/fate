function OnTentacleHookStart(keys)
	local caster = keys.caster
	local targetPoint = keys.ability:GetCursorPosition()
	caster.unithit = false 
end

function OnTentacleHookHit(keys)
	local caster = keys.caster
	local target = keys.target
 
	if caster.IsHookHit or caster.unithit then return end
 
	if(target:GetUnitName() ~= "gille_gigantic_horror") then
		caster.unithit = true 
		caster.IsHookHit = true
	else
		return
	end
	target:EmitSound("Hero_Pudge.AttackHookImpact")
	local diff = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() 
	target:AddNewModifier(target, target, "modifier_stunned", {Duration = 0.75})
	if not  IsKnockbackImmune(target) then
		local pullTarget = Physics:Unit(target)
		local pullVector = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Normalized() * diff * 2

		target:PreventDI()
		target:SetPhysicsFriction(0)
		target:SetPhysicsVelocity(Vector(pullVector.x, pullVector.y, 2000))
		target:SetNavCollisionType(PHYSICS_NAV_NOTHING)
		target:FollowNavMesh(false)
		target:SetAutoUnstuck(false)

		Timers:CreateTimer({
			endTime = 0.25,
			callback = function()
			target:SetPhysicsVelocity(Vector(pullVector.x, pullVector.y, -2000))
		end
		})

		Timers:CreateTimer(0.5, function()
			target:PreventDI(false)
			target:SetPhysicsVelocity(Vector(0,0,0))
			target:OnPhysicsFrame(nil)
			target:SetAutoUnstuck(true)
			FindClearSpaceForUnit(target, target:GetAbsOrigin(), true)

		end)
	end
  	Timers:CreateTimer(1.0, function()
		caster.IsHookHit = false
		caster.unithit = false 
	end)
end

function OnContaminateStart(keys)
	local caster = keys.caster
	local totalDamage = 250 + 250 * PlayerResource:GetSelectedHeroEntity(caster:GetPlayerOwnerID()):FindAbilityByName("gille_abyssal_contract"):GetLevel()
    local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
		DoDamage(caster, v, totalDamage/2, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
		keys.ability:ApplyDataDrivenModifier(caster, v, "modifier_contaminate", {}) 
	end

	local tentacleFx = ParticleManager:CreateParticle("particles/units/heroes/hero_pugna/pugna_netherblast.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(tentacleFx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(tentacleFx, 1, Vector(keys.Radius+200,0,0))
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( tentacleFx, false )
		ParticleManager:ReleaseParticleIndex( tentacleFx )
	end)
end

function OnContaminateThink(keys)
	local caster = keys.caster
	local target = keys.target
	local ult = PlayerResource:GetSelectedHeroEntity(caster:GetPlayerOwnerID()):FindAbilityByName("gille_abyssal_contract")
	local damage = (250 + 250 * ult:GetLevel()) / 40
	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
end

function OnIntegrateStart(keys)
	local caster = keys.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local healthpercent = caster:GetHealthPercent() / 100
	local IntMaxhealth = caster:GetMaxHealth()+keys.Health
	local IntCurrenthealth = caster:GetHealth()+keys.Health * healthpercent
	local DeIntMaxhealth = caster:GetMaxHealth()-keys.Health
	local DeIntCurrenthealth = caster:GetHealth()-keys.Health * healthpercent

	Timers:CreateTimer(0.5, function()
		if caster:IsAlive() then
			if hero.IsIntegrated then
				if GridNav:IsBlocked(caster:GetAbsOrigin()) or not GridNav:IsTraversable(caster:GetAbsOrigin()) then
					keys.ability:EndCooldown()
					SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Unmount")
					return			
				else
					hero:RemoveModifierByName("modifier_integrate_gille")
					caster:RemoveModifierByName("modifier_integrate")
					caster:SetMaxHealth(DeIntMaxhealth)
					caster:SetHealth(DeIntCurrenthealth)
					hero.IsIntegrated = false
					caster.AttemptingIntegrate = false
					SendMountStatus(hero)
				end
			elseif (caster:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D() < 400 and not hero:HasModifier("stunned") and not hero:HasModifier("modifier_stunned") then
				LoopOverPlayers(function(player, playerID, playerHero)
	        		--print("looping through " .. playerHero:GetName())
	        		if playerHero.gachi == true then
	            		-- apply legion horn vsnd on their client
	            		CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="gilles_wife_d_0"..math.random(1,2)})
	            		--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
	        		end
    			end)
				hero.IsIntegrated = true
				hero:AddNewModifier(caster, keys.ability, "modifier_integrate_gille", {})
				caster:AddNewModifier(caster, keys.ability, "modifier_integrate", {})  
				caster:SetMaxHealth(IntMaxhealth)
				caster:SetHealth(IntCurrenthealth)
				caster:EmitSound("ZC.Tentacle1")
				--caster:EmitSound("ZC.Laugh")
				SendMountStatus(hero)
				return 
			end
			--[[
			else
				caster.AttemptingIntegrate = true
				ExecuteOrderFromTable({ UnitIndex = caster:GetEntityIndex(), 
										OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET, 
										TargetIndex = hero:GetEntityIndex(), 
										Position = hero:GetAbsOrigin(), 
										Queue = false
									}) 

				ExecuteOrderFromTable({ UnitIndex = hero:GetEntityIndex(), 
										OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET, 
										TargetIndex = caster:GetEntityIndex(), 
										Position = caster:GetAbsOrigin(), 
										Queue = false
									}) 
				Timers:CreateTimer("integrate_checker", {
					endTime = 0.0,
					callback = function()
					if (caster:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D() < 300 and caster.AttemptingIntegrate then 
						caster.IsIntegrated = true
						caster.AttemptingIntegrate = false
						keys.ability:ApplyDataDrivenModifier(caster, hero, "modifier_integrate_gille", {})
						keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_integrate", {})  
						caster:EmitSound("ZC.Tentacle1")
						caster:EmitSound("ZC.Laugh")
						return 
					end
					return 0.1
				end})
			end]]
		end
	end)
end

function OnIntegrateDeath(keys)
	local caster = keys.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsIntegrated = false
	hero:RemoveModifierByName("modifier_integrate_gille")
	SendMountStatus(hero)
end

function IntegrateFollow(keys)
	local caster = keys.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	if IsValidEntity(caster) then
		hero:SetAbsOrigin(caster:GetAbsOrigin() + Vector(0,0,500))
	end
end

function OnHorrorTeleport(keys)
	local caster = keys.caster
	local hero = PlayerResource:GetSelectedHeroEntity(caster:GetPlayerOwnerID())
	local targetPoint = keys.ability:GetCursorPosition()
	local delay = keys.Delay
	if (targetPoint - hero:GetAbsOrigin()):Length2D() > 1000 then 
		keys.ability:EndCooldown()
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Tentacle_Out_Of_Radius")
		return
	elseif hero.IsIntegrated then
		keys.ability:EndCooldown()
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Use_While_Integrated")
		return
	elseif IsInSameRealm(caster:GetAbsOrigin(),hero:GetAbsOrigin()) == false then
		keys.ability:EndCooldown()
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Teleport_Across_Realms")
		return			
	else
		EmitSoundOnLocationWithCaster(targetPoint, "Hero_Enigma.Demonic_Conversion", caster)
		local darkZoneFx = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_seer/dark_seer_vacuum.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(darkZoneFx, 0, targetPoint)
		ParticleManager:SetParticleControl(darkZoneFx, 1, Vector(500,0,0))
		ParticleManager:SetParticleControl(darkZoneFx, 2, Vector(500,0,0))
		Timers:CreateTimer(delay, function()
			--ParticleManager:DestroyParticle( darkZoneFx, false )
			--ParticleManager:ReleaseParticleIndex( darkZoneFx )
			if caster:IsAlive() and hero:IsAlive() then
				caster:SetAbsOrigin(targetPoint)
			end
		end)
	end
end

function RemoveAllPoisons(keys) -- so people don't respawn with poison DoT debuff modifiers
	local caster = keys.caster
    LoopOverHeroes(function(hero)
    	hero:RemoveModifierByName("modifier_contaminate")
    	hero:RemoveModifierByName("modifier_gille_combo")
    end)
end
