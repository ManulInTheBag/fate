function OnNineCast(keys)
	local caster = keys.caster
	local casterName = caster:GetName()
	if casterName == "npc_dota_hero_doom_bringer" then
		StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_CAST_ABILITY_5, rate=0.2})
	elseif casterName == "npc_dota_hero_sven" then
		StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_RUN, rate=0.2})
	elseif casterName == "npc_dota_hero_ember_spirit" then
		StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_RUN, rate=0.2})
	end
end

function OnNineStart(keys)
	local caster = keys.caster
	local casterName = caster:GetName()
	local targetPoint = keys.target_points[1]
	local ability = keys.ability
	local berserker = Physics:Unit(caster)
	local origin = caster:GetAbsOrigin()
	local distance = (targetPoint - origin):Length2D()
	local forward = (targetPoint - origin):Normalized() * distance

	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(caster:GetForwardVector()*distance)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 4.0)
	caster:EmitSound("Hero_OgreMagi.Ignite.Cast")
	--ability:ApplyDataDrivenModifier(caster, caster, "modifier_dash_anim", {})
	if casterName == "npc_dota_hero_doom_bringer" then
		StartAnimation(caster, {duration=1, activity=ACT_DOTA_CAST_ABILITY_5, rate=0.5})
	elseif casterName == "npc_dota_hero_sven" then
		StartAnimation(caster, {duration=1, activity=ACT_DOTA_RUN, rate=0.5})
	elseif casterName == "npc_dota_hero_ember_spirit" then
		StartAnimation(caster, {duration=1, activity=ACT_DOTA_RUN, rate=0.8})
	end

	function DoNineLanded(caster)
		caster:OnPreBounce(nil)
		caster:OnPhysicsFrame(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		Timers:RemoveTimer(caster.NineTimer)
		caster.NineTimer = nil
		if caster:IsAlive() then
			OnNineLanded(caster, keys.ability)
			return 
		end
		return
	end

	caster.NineTimer = Timers:CreateTimer(1.0, function()
		DoNineLanded(caster)
	end)

	caster:OnPhysicsFrame(function(unit)
		if CheckDummyCollide(unit) then
			DoNineLanded(unit)
		end
	end)

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		DoNineLanded(unit)
	end)

	if caster:GetName() == "npc_dota_hero_ember_spirit" then
		caster:EmitSound("Archer.NineLives")
	end


	--[[Timers:CreateTimer(function()
		if travelCounter == 33 then OnNineLanded(caster, keys.ability) return end
		caster:SetAbsOrigin(caster:GetAbsOrigin() + forward) 
		travelCounter = travelCounter + 1
		
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		return 0.03
		end
	)]]
end

-- add pause
function OnNineLanded(caster, ability)
	local tickdmg = ability:GetLevelSpecialValueFor("damage", ability:GetLevel() - 1)
	local lasthitdmg = ability:GetLevelSpecialValueFor("damage_lasthit", ability:GetLevel() - 1)
	local returnDelay = 0.1
	local radius = ability:GetSpecialValueFor("radius")
	local lasthitradius = ability:GetSpecialValueFor("radius_lasthit")
	local stun = ability:GetSpecialValueFor("stun_duration")
	local nineCounter = 0
	local bonus_damage = 0

	if caster.IsProjectionImproved then
		bonus_damage = caster:GetAverageTrueAttackDamage(caster)
	end

	local casterInitOrigin = caster:GetAbsOrigin() 

	-- main timer
	Timers:CreateTimer(function()
		if caster:IsAlive() then -- only perform actions while caster stays alive
			local particle = ParticleManager:CreateParticle("particles/custom/berserker/nine_lives/hit.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControlForward(particle, 0, caster:GetForwardVector() * -1)
			ParticleManager:SetParticleControl(particle, 1, Vector(0,0,(nineCounter % 2) * 180))			

			StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_ATTACK, rate=3.0}) 			
			caster:EmitSound("Hero_EarthSpirit.StoneRemnant.Impact") 

			if nineCounter == 8 then -- if it is last strike

				caster:EmitSound("Hero_EarthSpirit.BoulderSmash.Target")
				caster:RemoveModifierByName("pause_sealdisabled") 
				ScreenShake(caster:GetOrigin(), 7, 1.0, 2, 1500, 0, true)
				-- do damage to targets
				local damage = lasthitdmg 				
				
				local lasthitTargets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, lasthitradius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 1, false)
				for k,v in pairs(lasthitTargets) do
					if v:GetName() ~= "npc_dota_ward_base" then
						DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
						if caster.IsProjectionImproved then 
							giveUnitDataDrivenModifier(caster, v, "stunned", 1.5)
						else							
							giveUnitDataDrivenModifier(caster, v, "stunned", 1.0)
						end						
						
						-- push enemies back
						local pushback = Physics:Unit(v)
						v:PreventDI()
						v:SetPhysicsFriction(0)
						v:SetPhysicsVelocity((v:GetAbsOrigin() - casterInitOrigin):Normalized() * 300)
						v:SetNavCollisionType(PHYSICS_NAV_NOTHING)
						v:FollowNavMesh(false)
						Timers:CreateTimer(0.5, function()  
							v:PreventDI(false)
							v:SetPhysicsVelocity(Vector(0,0,0))
							v:OnPhysicsFrame(nil)
							FindClearSpaceForUnit(v, v:GetAbsOrigin(), true)
						end)
					end
				end
				
				caster:EmitSound("Archer.NineFinish") 

				ParticleManager:SetParticleControl(particle, 2, Vector(1,1,lasthitradius))
				ParticleManager:SetParticleControl(particle, 3, Vector(lasthitradius / 350,1,1))
				ParticleManager:CreateParticle("particles/custom/berserker/nine_lives/last_hit.vpcf", PATTACH_ABSORIGIN, caster)

				-- DebugDrawCircle(caster:GetAbsOrigin(), Vector(255,0,0), 0.5, lasthitradius, true, 0.5)
			else
				-- if its not last hit, do regular hit stuffs
				local damage = tickdmg -- store original tick damage				 
				local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 1, false)

				for k,v in pairs(targets) do
					if caster.IsProjectionImproved then 
						DoDamage(caster, v, damage + bonus_damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
					else
						DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
					end
					giveUnitDataDrivenModifier(caster, v, "stunned", 0.5)
				end

				ParticleManager:SetParticleControl(particle, 2, Vector(1,1,radius))
				ParticleManager:SetParticleControl(particle, 3, Vector(radius / 350,1,1))
				-- DebugDrawCircle(caster:GetAbsOrigin(), Vector(255,0,0), 0.5, radius, true, 0.5)

				nineCounter = nineCounter + 1
				return returnDelay
			end

		end 
	end)
end