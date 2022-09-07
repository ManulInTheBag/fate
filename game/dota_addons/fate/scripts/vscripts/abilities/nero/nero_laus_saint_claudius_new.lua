nero_laus_saint_claudius_new = class({})

LinkLuaModifier("modifier_laus_saint_burn", "abilities/nero/modifiers/modifier_laus_saint_burn", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_laus_saint_claudius_cooldown", "abilities/nero/modifiers/modifier_laus_saint_claudius_cooldown", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_laus_saint_ready_checker", "abilities/nero/modifiers/modifier_laus_saint_ready_checker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lsk_stunned","abilities/nero/nero_laus_saint_claudius_new", LUA_MODIFIER_MOTION_NONE)

function nero_laus_saint_claudius_new:OnSpellStart()
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local ability = self
	local modifier = caster:FindModifierByName("modifier_aestus_domus_aurea_nero")
	local center_point = Vector(modifier.TheatreCenterX, modifier.TheatreCenterY, modifier.TheatreCenterZ)
	local counter = 0
	caster:SwapAbilities("nero_laus_saint_claudius_new", "nero_heat", false, true)
    --caster:AddNewModifier(caster, ability, "modifier_laus_saint_claudius_cooldown", {Duration = ability:GetCooldown(1)})

    if caster.UpgradeLSK == true then
    	caster.UpgradeLSK = false
	    Timers:CreateTimer(0.01, function()
	    	if counter <= 7 then
		    	for i = 1,caster:FindAbilityByName("nero_aestus_domus_aurea"):GetSpecialValueFor("explosion_count") do
		    		Timers:CreateTimer(FrameTime() + (i-1)*(0.4/caster:FindAbilityByName("nero_aestus_domus_aurea"):GetSpecialValueFor("explosion_count")), function()
					    local targetPoint = RandomPointInCircle(center_point, caster:FindAbilityByName("nero_aestus_domus_aurea"):GetSpecialValueFor("radius") - 250)
					    --DebugDrawCircle(targetPoint, Vector(255,0,0), 0.5, 250, true, 30)

					    local flameFx = ParticleManager:CreateParticle("particles/nero/nero_fiery_finale_eruption.vpcf", PATTACH_WORLDORIGIN, caster )
						ParticleManager:SetParticleControl( flameFx, 0, targetPoint)
						local effect_cast = ParticleManager:CreateParticle( "particles/nero/hero_snapfire_ultimate_linger.vpcf", PATTACH_WORLDORIGIN, caster )
						ParticleManager:SetParticleControl( effect_cast, 0, targetPoint )
						ParticleManager:SetParticleControl( effect_cast, 1, targetPoint )
						ParticleManager:DestroyParticle( effect_cast, false )
						ParticleManager:ReleaseParticleIndex( effect_cast )
						Timers:CreateTimer(5, function()
							ParticleManager:DestroyParticle( flameFx, false )
							ParticleManager:ReleaseParticleIndex( flameFx )
						end)
					end)
				end
				local targets = FindUnitsInRadius(caster:GetTeam(), center_point, nil, caster:FindAbilityByName("nero_aestus_domus_aurea"):GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
				for k,v in pairs(targets) do
					DoDamage(caster, v, ability:GetSpecialValueFor("explosion_damage") , DAMAGE_TYPE_MAGICAL, 0, self, false)
					v:AddNewModifier(caster, self, "modifier_stunned", {Duration = 0.1})
				end
			end
			counter = counter+1
			return 0.4
		end)
	end

		if caster:IsAlive() and caster:HasModifier("modifier_aestus_domus_aurea_nero") then
	        EmitGlobalSound("nero_lsk")
	        --EmitGlobalSound("Devil_Trigger")
	        LoopOverPlayers(function(player, playerID, playerHero)
		        --print("looping through " .. playerHero:GetName())
		        if playerHero.music == true then
		            -- apply legion horn vsnd on their client
		            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Devil_Trigger"})
		            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		        end
    		end)

	        local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 99999, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

	        --[[local masterCombo = caster.MasterUnit2:FindAbilityByName(ability:GetAbilityName())
	        masterCombo:EndCooldown()
	        masterCombo:StartCooldown(ability:GetCooldown(1))]]

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

	        StartAnimation(caster, {duration = 2, activity = ACT_DOTA_CAST_ABILITY_1_END, rate = 1})

	        local light_index = ParticleManager:CreateParticle("particles/kinghassan/khsn_domus_ray.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl( light_index, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl( light_index, 7, caster:GetAbsOrigin())

	        Timers:CreateTimer(0.3, function()
		        local roseFX = ParticleManager:CreateParticle("particles/kinghassan/nero_scorched_earth_child_embers_rosa.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster )
		        ParticleManager:SetParticleControlEnt(roseFX, 0, caster, PATTACH_POINT_FOLLOW, "attach_combo", caster:GetAbsOrigin(), true)
		    end)
			--ParticleManager:SetParticleControl( roseFX, 0, caster:GetAbsOrigin() + Vector(0,0,300))

	        Timers:CreateTimer(1.0, function()		
    		    if caster:IsAlive() then
    			    --StartAnimation(caster, {duration = 1, activity = ACT_DOTA_ATTACK, rate = 1})
    			    for i = 1, #enemies do
				        if enemies[i]:IsAlive() and enemies[i]:HasModifier("modifier_lsk_stunned") then
					        CreateSlashFx(caster, enemies[i]:GetAbsOrigin() + Vector(1200, 1200, 300),enemies[i]:GetAbsOrigin() + Vector(-1200, -1200, 300))
				        end
		     	    end
    		    end
    	    end)

	        Timers:CreateTimer(2.0, function()
    	    	if caster:IsAlive() then
	    	    	StartAnimation(caster, {duration = 1, activity = ACT_DOTA_CAST_ABILITY_5, rate = 1.2})
	    		    for i = 1, #enemies do
				        if enemies[i]:IsAlive() and enemies[i]:HasModifier("modifier_lsk_stunned") then
					        CreateSlashFx(caster, enemies[i]:GetAbsOrigin() + Vector(1200, -1200, 300),enemies[i]:GetAbsOrigin() + Vector(-1200, 1200, 300))
				        end
		     	    end		
	    	    end
	        end)

    	    Timers:CreateTimer(self:GetSpecialValueFor("stun_duration") - 0.05, function()
	    	    if caster:IsAlive() then
	    	    	local teleported = false
	    	    	if caster.IsISAcquired then
						HardCleanse(caster)
					end
	    		    for i = 1, #enemies do
				        if enemies[i]:IsAlive() and enemies[i]:HasModifier("modifier_lsk_stunned") then
				        	if not teleported then
					        	caster:SetAbsOrigin(enemies[i]:GetAbsOrigin() + enemies[i]:GetForwardVector()*150)
					        	caster:FaceTowards(GetGroundPosition(enemies[i]:GetAbsOrigin(), enemies[i]))
					        	local heat_abil = caster:FindAbilityByName("nero_heat")
	            				heat_abil:IncreaseHeat(caster)
					        	teleported = true
					        end
					        if i > 1 then
					        	local trail_fx = ParticleManager:CreateParticle("particles/nero/nero_trail.vpcf", PATTACH_ABSORIGIN, caster)
								ParticleManager:SetParticleControl(trail_fx, 0, enemies[i-1]:GetAbsOrigin())
								ParticleManager:SetParticleControl(trail_fx, 1, enemies[i]:GetAbsOrigin())

								Timers:CreateTimer(0.5, function()
									ParticleManager:DestroyParticle(trail_fx, false)
									ParticleManager:ReleaseParticleIndex(trail_fx)
								end)
							end
					        enemies[i]:EmitSound("Hero_Lion.FingerOfDeath")
			                --StartAnimation(caster, {duration = 1, activity = ACT_DOTA_CAST_ABILITY_3_END, rate = 1.5})	
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
	return { [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_COMMAND_RESTRICTED] = false }
end