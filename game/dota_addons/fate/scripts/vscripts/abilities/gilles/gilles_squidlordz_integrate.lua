gilles_squidlordz_integrate = class({})





function OnIntegrateStart(keys)
	local caster = keys.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local healthpercent = caster:GetHealthPercent() / 100
	local IntMaxhealth = caster:GetMaxHealth()+keys.Health
	local IntCurrenthealth = caster:GetHealth()+keys.Health * healthpercent
	local DeIntMaxhealth = caster:GetMaxHealth()-keys.Health
	local DeIntCurrenthealth = caster:GetHealth()-keys.Health * healthpercent

	LoopOverPlayers(function(player, playerID, playerHero)
	        --print("looping through " .. playerHero:GetName())
	        if playerHero.gachi == true then
	            -- apply legion horn vsnd on their client
	            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="gilles_wife_d_0"..math.random(1,2)})
	            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
	        end
    	end)

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
				hero.IsIntegrated = true
				keys.ability:ApplyDataDrivenModifier(caster, hero, "modifier_integrate_gille", {})
				keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_integrate", {})  
				caster:SetMaxHealth(IntMaxhealth)
				caster:SetHealth(IntCurrenthealth)
				caster:EmitSound("ZC.Tentacle1")
				SendMountStatus(hero)
				return 
			end
		end
	end)
end