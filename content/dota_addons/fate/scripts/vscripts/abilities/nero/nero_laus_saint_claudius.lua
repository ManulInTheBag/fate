nero_laus_saint_claudius = class({})

LinkLuaModifier("modifier_laus_saint_burn", "abilities/nero/modifiers/modifier_laus_saint_burn", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_laus_saint_claudius_cooldown", "abilities/nero/modifiers/modifier_laus_saint_claudius_cooldown", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_laus_saint_ready_checker", "abilities/nero/modifiers/modifier_laus_saint_ready_checker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lsk_stunned","abilities/nero/nero_laus_saint_claudius", LUA_MODIFIER_MOTION_NONE)

function nero_laus_saint_claudius:OnSpellStart()
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local ability = self

	caster:SwapAbilities("nero_laus_saint_claudius", "nero_aestus_domus_aurea", false, true)
    caster:AddNewModifier(caster, ability, "modifier_laus_saint_claudius_cooldown", {Duration = ability:GetCooldown(1)})

		if caster:IsAlive() and caster:HasModifier("modifier_aestus_domus_aurea_nero") then
	        caster:EmitSound("Nero_NP4")
	        --EmitGlobalSound("Devil_Trigger")
	        LoopOverPlayers(function(player, playerID, playerHero)
		        --print("looping through " .. playerHero:GetName())
		        if playerHero.music == true then
		            -- apply legion horn vsnd on their client
		            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Devil_Trigger"})
		            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		        end
    		end)

	        local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 99999, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	        local masterCombo = caster.MasterUnit2:FindAbilityByName(ability:GetAbilityName())
	        masterCombo:EndCooldown()
	        masterCombo:StartCooldown(ability:GetCooldown(1))

	        if caster:HasModifier("modifier_laus_saint_ready_checker") then
	        	caster:RemoveModifierByName("modifier_laus_saint_ready_checker")
	        end

	        for i = 1, #enemies do
				if enemies[i]:IsAlive() and enemies[i]:HasModifier("modifier_aestus_domus_aurea_enemy") then
					enemies[i]:AddNewModifier(caster, enemies[i], "modifier_lsk_stunned", {Duration = self:GetSpecialValueFor("stun_duration")})
				end
			end
    
	        giveUnitDataDrivenModifier(caster, caster, "jump_pause", self:GetSpecialValueFor("stun_duration"))
	        --local distance = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
	        --local diff = target:GetAbsOrigin() - caster:GetAbsOrigin()

	        StartAnimation(caster, {duration = 0.4, activity = ACT_DOTA_CAST_ABILITY_5, rate = 3})

	        Timers:CreateTimer(1.0, function()		
    		    if caster:IsAlive() then
    			    StartAnimation(caster, {duration = 0.4, activity = ACT_DOTA_ATTACK_EVENT, rate = 1.5})
    			    for i = 1, #enemies do
				        if enemies[i]:IsAlive() and enemies[i]:HasModifier("modifier_lsk_stunned") then
					        CreateSlashFx(caster, enemies[i]:GetAbsOrigin() + Vector(1200, 1200, 300),enemies[i]:GetAbsOrigin() + Vector(-1200, -1200, 300))
				        end
		     	    end
    		    end
    	    end)

	        Timers:CreateTimer(2.0, function()		
    	    	if caster:IsAlive() then
	    	    	StartAnimation(caster, {duration = 1, activity = ACT_DOTA_ATTACK_EVENT_BASH, rate = 1.5})
	    		    for i = 1, #enemies do
				        if enemies[i]:IsAlive() and enemies[i]:HasModifier("modifier_lsk_stunned") then
					        CreateSlashFx(caster, enemies[i]:GetAbsOrigin() + Vector(1200, -1200, 300),enemies[i]:GetAbsOrigin() + Vector(-1200, 1200, 300))
				        end
		     	    end		
	    	    end
	        end)

    	    Timers:CreateTimer(self:GetSpecialValueFor("stun_duration") - 0.05, function()
	    	    if caster:IsAlive() then
	    		    for i = 1, #enemies do
				        if enemies[i]:IsAlive() and enemies[i]:HasModifier("modifier_lsk_stunned") then
					        enemies[i]:EmitSound("Hero_Lion.FingerOfDeath")
			                StartAnimation(caster, {duration = 1, activity = ACT_DOTA_CAST_ABILITY_3_END, rate = 1.5})	
			                CreateSlashFx(caster, enemies[i]:GetAbsOrigin() + Vector(1200, 1200, 300),enemies[i]:GetAbsOrigin() + Vector(-1200, -1200, 300))
	    		            local slashFx = ParticleManager:CreateParticle("particles/kinghassan/nero_scorched_earth_child_embers_rosa.vpcf", PATTACH_ABSORIGIN, enemies[i] )
	    		            ParticleManager:SetParticleControl( slashFx, 0, enemies[i]:GetAbsOrigin() + Vector(0,0,300))

	    		            Timers:CreateTimer( 2.0, function()
		    		        ParticleManager:DestroyParticle( slashFx, false )
	    			        ParticleManager:ReleaseParticleIndex( slashFx )
		        	        end)

			                DoDamage(caster, enemies[i], damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			                enemies[i]:AddNewModifier(caster, self, "modifier_laus_saint_burn", { Duration = self:GetSpecialValueFor("duration"),
				    	    															    	  BurnDamage = self:GetSpecialValueFor("burn_damage") })
				        end
		     	    end

		    	    caster:RemoveModifierByName("modifier_aestus_domus_aurea_nero")
	    	    end
	    	end)
	    else
	    	self:GetAbility():SetCooldown(1)
	    	caster:RemoveModifierByName("modifier_laus_saint_claudius_cooldown")
	    end
end

modifier_lsk_stunned=class({})
function modifier_lsk_stunned:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true,
			 [MODIFIER_STATE_COMMAND_RESTRICTED] = true }
end