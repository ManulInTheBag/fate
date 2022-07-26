excalibur_galatine_combo = class({})

function excalibur_galatine_combo:GetBehavior()
	local caster = self:GetCaster()
	if not caster:HasModifier("modifier_galatine_tracker") then
		return DOTA_ABILITY_BEHAVIOR_POINT
	else
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
	end
end

function excalibur_galatine_combo:GetManaCost(iLevel)
	local caster = self:GetCaster()
	if not caster:HasModifier("modifier_galatine_tracker") then
		return 800
	else
		return 0
	end
end

function excalibur_galatine_combo:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_2
end

function excalibur_galatine_combo:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function excalibur_galatine_combo:GetAbilityTextureName()
	return "custom/gawain_galatine_combo"
end

function excalibur_galatine_combo:OnSpellStart()	
	
end

function excalibur_galatine_combo:StartGalatine()
	local caster = self:GetCaster()
	local ability = self
	local casterLoc = caster:GetAbsOrigin()
	local targetPoint = self:GetCursorPosition()
	local dist = self:GetSpecialValueFor("max_distance")
	local aoe = self:GetSpecialValueFor("radius")
	local orbLoc = caster:GetAbsOrigin()
	local diff = caster:GetForwardVector()
	local timeElapsed = 0
	local flyingDist = 0
	local orbVelocity = 100
	local fireTrailDuration = 3
	local damage = self:GetSpecialValueFor("damage")

	caster:AddNewModifier(caster, self, "modifier_galatine_tracker", { Duration = 5.5 })

	local masterCombo = caster.MasterUnit2:FindAbilityByName(ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(ability:GetCooldown(1))

	caster:AddNewModifier(caster, ability, "modifier_galatine_combo_cd", {duration = ability:GetCooldown(1)})

	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 4.1)

	StartAnimation(caster, {duration=4, activity=ACT_DOTA_CAST_ABILITY_2, rate=0.2})

	EmitGlobalSound("Gawain_Galatine_Combo")

	caster:FindAbilityByName("gawain_excalibur_galatine"):StartCooldown(caster:FindAbilityByName("gawain_excalibur_galatine"):GetCooldown(1))

	local particle = ParticleManager:CreateParticle("particles/custom/gawain/gawain_combo.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 1, Vector(1000, 1000, 1000))
	Timers:CreateTimer(3.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
	end)

	local castFx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( castFx2, 0, caster:GetAbsOrigin())

	local galatineDummy = CreateUnitByName("gawain_galatine_dummy", Vector(20000,20000,0), true, nil, nil, caster:GetTeamNumber())
	local flameFx1 = ParticleManager:CreateParticle("particles/custom/gawain/gawain_excalibur_galatine_orb.vpcf", PATTACH_ABSORIGIN_FOLLOW, galatineDummy )
	ParticleManager:SetParticleControl( flameFx1, 0, galatineDummy:GetAbsOrigin())

	if caster:HasModifier("modifier_sov_attribute") then
		damage = damage + 1500
		fireTrailDuration = fireTrailDuration + 3
	end

	Timers:CreateTimer(4.0, function()
		if caster:IsAlive() then
			EmitGlobalSound("Gawain_Galatine_Combo_Launch")
			
			casterLoc = caster:GetAbsOrigin()
			orbLoc = caster:GetAbsOrigin()
			diff = caster:GetForwardVector()
			caster:AddNewModifier(caster, self, "modifier_galatine_tracker", { Duration = 1.5 })

			



			-- Move the ball, reduce the remaining flight distance, reduce the remaining timer and increase the AoE gradually
			orbLoc = orbLoc + diff * orbVelocity
			galatineDummy:SetAbsOrigin(orbLoc)
			flyingDist = (casterLoc - orbLoc):Length2D()
			timeElapsed = timeElapsed + 0.05

			-- Get all nearby enemies and give them Galatine burn debuff if they don't have it
			local burnTargets = FindUnitsInRadius(caster:GetTeam(), galatineDummy:GetAbsOrigin(), nil, aoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)			
			for i,j in pairs(burnTargets) do
				j:AddNewModifier(caster, ability, "modifier_excalibur_galatine_burn", {duration = fireTrailDuration})
			end

			if (math.ceil(flyingDist) % 300 < 5) then
				self:LeaveFireTrail(GetGroundPosition(galatineDummy:GetAbsOrigin(), nil), fireTrailDuration)
			end
			
			return 0.05
		else 
			self:LeaveFireTrail(GetGroundPosition(galatineDummy:GetAbsOrigin(), nil), fireTrailDuration)
			
			self:ReorderAbilities()

			-- Explosion on enemies
			local targets = FindUnitsInRadius(caster:GetTeam(), galatineDummy:GetAbsOrigin(), nil, aoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 

			for k,v in pairs(targets) do
				v:AddNewModifier(caster, ability, "modifier_excalibur_galatine_burn", {duration = fireTrailDuration})

				DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)				
			end

			local explodeFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_hit.vpcf", PATTACH_ABSORIGIN, galatineDummy )
			ParticleManager:SetParticleControl( explodeFx1, 0, galatineDummy:GetAbsOrigin())			

			local explodeFx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_ABSORIGIN_FOLLOW, galatineDummy )
			ParticleManager:SetParticleControl( explodeFx2, 0, galatineDummy:GetAbsOrigin())

			local splashFx = ParticleManager:CreateParticle("particles/custom/screen_yellow_splash_gawain.vpcf", PATTACH_EYES_FOLLOW, caster)
			Timers:CreateTimer( 3.0, function()
				ParticleManager:DestroyParticle( splashFx, false )
				ParticleManager:ReleaseParticleIndex( splashFx )
			end)

			galatineDummy:EmitSound("Hero_Phoenix.SuperNova.Explode")

			galatineDummy:ForceKill(true) 
			ParticleManager:DestroyParticle( flameFx1, false )
			ParticleManager:ReleaseParticleIndex( flameFx1 )

			Timers:CreateTimer( 2.0, function()
				ParticleManager:DestroyParticle( explodeFx1, false )
				ParticleManager:ReleaseParticleIndex( explodeFx1 )
				ParticleManager:DestroyParticle( explodeFx2, false )
				ParticleManager:ReleaseParticleIndex( explodeFx2 )
			end)
			return
		end
	end)
end

function excalibur_galatine_combo:LaunchOrb()
end

function excalibur_galatine_combo:DetonateOrb()
	local caster = self:GetCaster()

	caster:RemoveModifierByName("modifier_galatine_tracker")
end

function excalibur_galatine_combo:LeaveFireTrail(location, fireTrailDuration)
	local caster = self:GetCaster()
	local ability = self
	local damage = self:GetSpecialValueFor("fire_trail_damage")

	local fireFx = ParticleManager:CreateParticle("particles/custom/gawain/gawain_galetine_flametrail_parent.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(fireFx, 0, location)
	ParticleManager:SetParticleControl(fireFx, 1, Vector(fireTrailDuration,0,0))

	local counter = 0
	local period = 0.5
	Timers:CreateTimer(function()
		counter = counter + period
		if counter > fireTrailDuration then return end
		local targets = FindUnitsInRadius(caster:GetTeam(), location, nil, 325, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
		
		for k,v in pairs(targets) do
			v:AddNewModifier(caster, ability, "modifier_excalibur_galatine_burn", { Duration = fireTrailDuration,
																					Damage = damage })
		end

		return period
	end)
end

function excalibur_galatine_combo:GetTexture()
	return "custom/gawain_galatine_combo"
end