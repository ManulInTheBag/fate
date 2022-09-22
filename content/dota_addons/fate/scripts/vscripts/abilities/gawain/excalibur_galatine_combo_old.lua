function OnGalatineStart(keys)
	-- Declaring a bunch of stuffs
	local caster = keys.caster
	local ability = keys.ability
	--local ply = caster:GetPlayerOwner()
	local casterLoc = caster:GetAbsOrigin()
	local targetPoint = keys.target_points[1]
	local dist = keys.Max_range    --(targetPoint - casterLoc):Length2D()
	local orbLoc = caster:GetAbsOrigin()
	local diff = caster:GetForwardVector()
	local timeElapsed = 0
	local flyingDist = 0
	local orbVelocity = 100
	local fireTrailDuration = 3
	local damage = keys.Damage
	local InFirstLoop = true
	caster.IsGalatineActive = true

	local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(keys.ability:GetCooldown(1))
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_galatine_combo_cd", {duration = ability:GetCooldown(ability:GetLevel())})

	-- Stops Gawain from doing anything else essentially and play the Galatine animation
	
	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 4.5)
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_excalibur_galatine_vfx", {})	
	keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_excalibur_galatine_anim",{})
	-- Need the dank voice. 
	EmitGlobalSound("gawain_galatine_combo_cast")
	EmitGlobalSound("Uragirimono_no_Requiem")
	--EmitGlobalSound("Hero_Enigma.Black_Hole")

	--Timers:CreateTimer(3.0, function()
	--	StopSoundEvent("Hero_Enigma.Black_Hole", target)
	--end)

	caster:FindAbilityByName("gawain_excalibur_galatine"):StartCooldown(caster:FindAbilityByName("gawain_excalibur_galatine"):GetCooldown(1))

	-- Make dem particles and the Galatine ball
	--local castFx1 = ParticleManager:CreateParticle("particles/custom/saber_excalibur_circle.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	--ParticleManager:SetParticleControl( castFx1, 0, caster:GetAbsOrigin())

	local particle = ParticleManager:CreateParticle("particles/custom/gawain/gawain_combo.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 1, Vector(1000, 1000, 1000))
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
	end)


	local castFx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( castFx2, 0, caster:GetAbsOrigin())

	local galatineDummy = CreateUnitByName("gawain_galatine_dummy", Vector(20000,20000,0), true, nil, nil, caster:GetTeamNumber())
	local flameFx1 = ParticleManager:CreateParticle("particles/custom/gawain/gawain_excalibur_galatine_orb_combo.vpcf", PATTACH_ABSORIGIN_FOLLOW, galatineDummy )
	ParticleManager:SetParticleControl( flameFx1, 0, galatineDummy:GetAbsOrigin())

	galatineDummy:SetDayTimeVisionRange(300)
	galatineDummy:SetNightTimeVisionRange(300)	
	galatineDummy:AddNewModifier(caster, nil, "modifier_kill", {duration = 5.0})

	if caster.IsSoVAcquired then
		--damage = damage + 1500
		fireTrailDuration = fireTrailDuration + 3
	end

	Timers:CreateTimer(4.0, function()
		if not caster:IsAlive() then
			StopGlobalSound("Uragirimono_no_Requiem")
		end
		end)

	-- Checks if Gawain is still alive as well as whether or not it overshot where the player intended it to flew.. or it flew for too long
	Timers:CreateTimer(4.5, function()
		if caster:IsAlive() and timeElapsed < 1.5 and caster.IsGalatineActive and flyingDist < dist then			
			-- Need to initialize the variables and put in Gawain's detonate Galatine ability
			if InFirstLoop then
				EmitGlobalSound("gawain_galatine_combo_activate")
				casterLoc = caster:GetAbsOrigin()
				orbLoc = caster:GetAbsOrigin()
				diff = caster:GetForwardVector()
				caster:SwapAbilities("gawain_excalibur_galatine_combo", "gawain_excalibur_galatine_detonate_combo", false, true)
				InFirstLoop = false
			end
			-- Move the ball, reduce the remaining flight distance, reduce the remaining timer and increase the AoE gradually
			orbLoc = orbLoc + diff * orbVelocity
			galatineDummy:SetAbsOrigin(orbLoc)
			flyingDist = (casterLoc - orbLoc):Length2D()
			timeElapsed = timeElapsed + 0.05

			-- Get all nearby enemies and give them Galatine burn debuff if they don't have it
			local burnTargets = FindUnitsInRadius(caster:GetTeam(), galatineDummy:GetAbsOrigin(), nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)			
			for i,j in pairs(burnTargets) do
				ability:ApplyDataDrivenModifier(caster, j, "modifier_excalibur_galatine_burn", {}) 				
			end

			--Hacky way to leave a fire trail 
			--print(flyingDist)
			if (math.ceil(flyingDist) % 300 < 5) then
				LeaveFireTrail(keys, GetGroundPosition(galatineDummy:GetAbsOrigin(), nil), fireTrailDuration)
			end
			
			return 0.05
		else 
			LeaveFireTrail(keys, galatineDummy:GetAbsOrigin(), fireTrailDuration)
		
			GiveGawainGalatine(caster)

			-- Explosion on enemies
			local targets = FindUnitsInRadius(caster:GetTeam(), galatineDummy:GetAbsOrigin(), nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			local distance = 0
			local distancePenalty = 0
			for k,v in pairs(targets) do
				keys.ability:ApplyDataDrivenModifier(caster, v, "modifier_excalibur_galatine_burn", {})
				distance = (galatineDummy:GetAbsOrigin() - v:GetAbsOrigin()):Length2D()

				if caster.IsSoVAcquired then
					if distance <= 350 then
						damage = keys.Damage + 1500
					else
						damage = keys.Damage
					end
				end

				DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)				
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
			--ParticleManager:DestroyParticle( castFx1, false )
			--ParticleManager:ReleaseParticleIndex( castFx1 )

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

function OnGalatineDetonate(keys)
	local caster = keys.caster
	caster.IsGalatineActive = false
	GiveGawainGalatine(caster)
	--[[if caster:GetAbilityByIndex(5):GetAbilityName() == "gawain_excalibur_galatine_detonate_combo" then
		caster:SwapAbilities("gawain_excalibur_galatine", "gawain_excalibur_galatine_detonate_combo", true, false)
	end]]
end

function GiveGawainGalatine(caster)
	local galatineSlot = caster:GetAbilityByIndex(5)

	caster.IsGalatineActive = false

	if galatineSlot:GetAbilityName() ~= "gawain_excalibur_galatine" then
		caster:SwapAbilities("gawain_excalibur_galatine", galatineSlot:GetAbilityName(), true, false)
	end
end


--Copied from Jeanne's kek
function LeaveFireTrail(keys, location, duration)
	local caster = keys.caster
	local ability = keys.ability
	local damage = keys.BurnDamage

	local fireFx = ParticleManager:CreateParticle("particles/custom/gawain/gawain_galetine_flametrail_combo_parent.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(fireFx, 0, location)
	ParticleManager:SetParticleControl(fireFx, 1, Vector(duration,0,0))

	local counter = 0
	local period = 0.5
	Timers:CreateTimer(function()
		counter = counter + period
		if counter > duration then return end
		local targets = FindUnitsInRadius(caster:GetTeam(), location, nil, 700, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
		for k,v in pairs(targets) do
			--v:RemoveModifierByName("modifier_excalibur_galatine_burn")
			ability:ApplyDataDrivenModifier(caster, v, "modifier_excalibur_galatine_burn", {})
			--DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
		end
		return period
	end)
end

