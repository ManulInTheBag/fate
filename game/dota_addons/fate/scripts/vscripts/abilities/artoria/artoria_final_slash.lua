-----------------------------
--    Final Slash   --
-----------------------------

artoria_final_slash = class({})

LinkLuaModifier( "modifier_artoria_final_slash_stun", "abilities/artoria/modifiers/modifier_artoria_final_slash_stun", LUA_MODIFIER_MOTION_NONE )

function artoria_final_slash:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if target:IsMagicImmune() then
		return
	end
	
	EmitGlobalSound("artoria_strike_1")
	EmitGlobalSound("artoria_final_slash_voice")
	
	local damage = self:GetSpecialValueFor("damage")
	
	caster:AddNewModifier(caster, self, "modifier_artoria_final_slash_stun", { Duration = 1.05 })
	target:AddNewModifier(caster, self, "modifier_artoria_final_slash_stun", { Duration = self:GetSpecialValueFor("duration") })
	
	StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_CAST_ABILITY_4_END, rate=1.0})
	
	local chargeFxIndex = ParticleManager:CreateParticle( "particles/custom/artoria/artoria_excalibur_charge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	
	local targets = DOTA_UNIT_TARGET_HERO
	
	local allies = FindUnitsInRadius(
			self:GetCaster():GetTeamNumber(),	-- int, your team number
			caster:GetOrigin(),	-- point, center point
			nil,	-- handle, cacheUnit. (not known)
			FIND_UNITS_EVERYWHERE,	-- float, radius. or use FIND_UNITS_EVERYWHERE
			DOTA_UNIT_TARGET_TEAM_FRIENDLY,	-- int, team filter
			targets,	-- int, type filter
			0,	-- int, flag filter
			0,	-- int, order filter
			false	-- bool, can grow cache
		)
		
	for _,emiya in pairs(allies) do
		if emiya:GetUnitName() == "npc_dota_hero_ember_spirit" then
			emiya:RemoveModifierByName("modifier_artoria_ultimate_shirou_avalon")
			emiya:RemoveModifierByName("modifier_artoria_avalon_immunity")
			emiya:RemoveModifierByName("modifier_artoria_avalon_heal")
		end
	end
	
	self.flash = ParticleManager:CreateParticle("particles/custom/artoria/artoria_final_slash_flash.vpcf", PATTACH_CUSTOMORIGIN, self.Dummy)
	ParticleManager:SetParticleControlEnt(self.flash, 0, caster, PATTACH_POINT_FOLLOW, "attach_excalibur", caster:GetOrigin(), true)
	ParticleManager:SetParticleControl(self.flash, 1, caster:GetOrigin())	
	
	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetOrigin(), nil, 350 , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	
		Timers:CreateTimer(0.39, function() -- Adjust 2.5 to 3.2 to match the sound
			if caster:IsAlive() then
				-- Create Particle for projectile
				
				ParticleManager:DestroyParticle( chargeFxIndex, false )
				ParticleManager:ReleaseParticleIndex( chargeFxIndex )
				local casterFacing = caster:GetForwardVector()
				local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
				dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
				dummy:SetForwardVector(casterFacing)
				Timers:CreateTimer( function()
						if IsValidEntity(dummy) then
							local newLoc = dummy:GetAbsOrigin() + (1150 * 0.03 * casterFacing)
							dummy:SetAbsOrigin(GetGroundPosition(newLoc,dummy))
							-- DebugDrawCircle(newLoc, Vector(255,0,0), 0.5, keys.StartRadius, true, 0.15)
							return 0.03
						else
							return nil
						end
					end
				)
				
				local excalFxIndex = ParticleManager:CreateParticle( "particles/custom/saber/excalibur/shockwave.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, dummy )
				ParticleManager:SetParticleControl(excalFxIndex, 4, Vector(550,0,0))

				Timers:CreateTimer( 0.6, function()
						ParticleManager:DestroyParticle( excalFxIndex, false )
						ParticleManager:ReleaseParticleIndex( excalFxIndex )
						Timers:CreateTimer( 0.7, function()
								dummy:RemoveSelf()
								return nil
							end
						)
						return nil
					end
				)
				return 
			end
		end)
		
			--Removes Super Saiyan
	Timers:CreateTimer(1.30, function()
		if not caster:IsAlive() then
			ParticleManager:DestroyParticle( chargeFxIndex, false )
			ParticleManager:ReleaseParticleIndex( chargeFxIndex )
		end
	end)
	
	Timers:CreateTimer(0.4, function()
		if caster:IsAlive() then
			
			DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, self, false)
			
			EmitGlobalSound("artoria_final_slash_2")
			
			ScreenShake(target:GetOrigin(), 25, 3.0, 3, 10000, 0, true)
			
			caster:RemoveModifierByName("modifier_artoria_ultimate_avalon")
			caster:RemoveModifierByName("modifier_artoria_final_slash_window")
			caster:RemoveModifierByName("modifier_artoria_avalon_immunity")
			caster:RemoveModifierByName("modifier_artoria_avalon_heal")
			
			local culling_kill_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, target)
			ParticleManager:SetParticleControlEnt(culling_kill_particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(culling_kill_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(culling_kill_particle, 2, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(culling_kill_particle, 4, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(culling_kill_particle, 8, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(culling_kill_particle)

			Timers:CreateTimer( 3.0, function()
				ParticleManager:DestroyParticle( culling_kill_particle, false )
			end)
		end
		return
	end)
end