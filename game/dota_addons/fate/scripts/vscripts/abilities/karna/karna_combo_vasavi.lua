karna_combo_vasavi = class({})

LinkLuaModifier("modifier_vasavi_hit", "abilities/karna/modifiers/modifier_vasavi_hit", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_combo_vasavi_cooldown", "abilities/karna/modifiers/modifier_combo_vasavi_cooldown", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

function karna_combo_vasavi:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function karna_combo_vasavi:GetCastPoint()
	return self:GetSpecialValueFor("cast_point")
end

function karna_combo_vasavi:OnSpellStart()
	local caster = self:GetCaster()
	self.target = self:GetCursorPosition()
	local range =(self.target- caster:GetAbsOrigin()):Length2D()
	if(range > 3000) then 
		self.target = self.target:Normalized()*3000
	end
	local fire_delay = self:GetSpecialValueFor("fire_delay") 
	local sound_delay = self:GetSpecialValueFor("prefire_delay") 

	local ascendCount = 0
	local descendCount = 0

	local sound_number =  math.random(1,5)
	EmitGlobalSound("karna_vasavi_start_" ..sound_number)

	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(self:GetCooldown(1))

	local vasavi = caster:FindAbilityByName("karna_vasavi_shakti")
	vasavi:StartCooldown(vasavi:GetCooldown(vasavi:GetLevel()))

	caster:AddNewModifier(caster, self, "modifier_combo_vasavi_cooldown", { Duration = self:GetCooldown(1) })

	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 3.4)
	StartAnimation(caster, {duration=sound_delay, activity=ACT_DOTA_CAST_ABILITY_1, rate=0.5})
	Timers:CreateTimer(fire_delay + 1.0, function()

	end)
	--[[ this particle is bugged anyways, so i removed it //Zlodemon
	local weapon_spark_location = caster:GetOrigin() + Vector(caster:GetForwardVector().x, caster:GetForwardVector().y, 0) * 175 + Vector(0, 0, 125)

	self.WeaponSpark = ParticleManager:CreateParticle("particles/custom/karna/combo/combo_vasavi_attach.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(self.WeaponSpark, 0, weapon_spark_location) 
	--ParticleManager:SetParticleControlEnt(self.WeaponSpark, 0, caster, PATTACH_POINT_FOLLOW, "attach_weapon", caster:GetOrigin(), true)
	]]
    Timers:CreateTimer(fire_delay + 1.0, function()
    	ParticleManager:DestroyParticle( self.flameFx1, false )
        ParticleManager:ReleaseParticleIndex( self.flameFx1 )
        --ParticleManager:DestroyParticle( self.flameFx2, false )
        --ParticleManager:ReleaseParticleIndex( self.flameFx2 )
    end)

	Timers:CreateTimer('vas_asc', {
		endTime = 0,
		callback = function()
	   	if ascendCount == 15 and caster:IsAlive() then
	   		self.flameFx1 = ParticleManager:CreateParticle("particles/custom/gawain/gawain_excalibur_galatine_orb.vpcf", PATTACH_ABSORIGIN, caster )
    		ParticleManager:SetParticleControl( self.flameFx1, 0, caster:GetAbsOrigin() - caster:GetForwardVector()*300 + Vector(0,0,300))

    		--self.flameFx2 = ParticleManager:CreateParticle("particles/clinkz_death_pact_buff_ring_rope_bright.vpcf", PATTACH_WORLDORIGIN, caster)
    		--ParticleManager:SetParticleControl( self.flameFx1, 2, caster:GetAbsOrigin() - caster:GetForwardVector()*50 + Vector(0,0,120))
    		--ParticleManager:SetParticleControl( self.flameFx1, 2, caster:GetAbsOrigin())
		   	return
		elseif ascendCount == 15 then
			return
		end

		caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z+30))
		ascendCount = ascendCount + 1;
		return 0.033
	end
	})

	Timers:CreateTimer("vas_desc", {
	    endTime = fire_delay + 1.0,
	    callback = function()
	    	if descendCount == 15 then return end	    	

			caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z-30))
			descendCount = descendCount + 1;
	      	return 0.033
	    end
	})

	Timers:CreateTimer(sound_delay, function()
		if caster:IsAlive() then
			StartAnimation(caster, {duration=1, activity=ACT_DOTA_ATTACK, rate=0.7})
 
		end
		return
	end)

	Timers:CreateTimer(sound_delay*(1- (3000 -range   )/5500), function()
		if caster:IsAlive() then
			EmitGlobalSound("karna_vasavi_end")
			StopGlobalSound("karna_vasavi_start_" ..sound_number)
		end
		return
	end)


	Timers:CreateTimer(fire_delay, function()
		--ParticleManager:DestroyParticle(self.WeaponSpark, true)
		--ParticleManager:ReleaseParticleIndex(self.WeaponSpark)

		if caster:IsAlive() then
			local aoe = self:GetSpecialValueFor("beam_aoe")
			local range =(self.target- caster:GetAbsOrigin()):Length2D()

			--forwardVec = GetGroundPosition(forwardVec, nil)

		    local projectileTable = {
				Ability = self,
				EffectName = "particles/custom/karna/combo/vasavi_beam.vpcf",
				iMoveSpeed = 10,
				vSpawnOrigin = caster:GetAbsOrigin(),
				fDistance = range,
				Source = self:GetCaster(),
				fStartRadius = aoe,
		        fEndRadius = aoe,
				bHasFrontialCone = true,
				bReplaceExisting = false,
				iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
				iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
				iUnitTargetType = DOTA_UNIT_TARGET_ALL,
				fExpireTime = GameRules:GetGameTime() + 3,
				bDeleteOnHit = false,
				vVelocity = caster:GetForwardVector() * 3000,
			}
			self.time = 1.0
			self.timexp = 0
		    local projectile = ProjectileManager:CreateLinearProjectile(projectileTable)

		    self.Dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
			self.Dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)			

		    self.LaserBeam = ParticleManager:CreateParticle("particles/custom/karna/combo/vasavi_shakti_beam_combo.vpcf", PATTACH_CUSTOMORIGIN, self.Dummy)
			ParticleManager:SetParticleControlEnt(self.LaserBeam, 0, caster, PATTACH_POINT_FOLLOW, "attach_weapon", caster:GetOrigin(), true)
			ParticleManager:SetParticleControl(self.LaserBeam, 1, caster:GetOrigin())			
		end
		return
	end)
end

function karna_combo_vasavi:OnProjectileThink(vLocation)
	--vLocation = vLocation + Vector(0, 0, 32)
	self.timexp = self.timexp + FrameTime()
	vLocation = self:GetCaster():GetAbsOrigin() + (self.target - self:GetCaster():GetAbsOrigin()):Normalized()*3000*self.timexp/self.time
	self.Dummy:SetAbsOrigin(vLocation)
	
	ParticleManager:SetParticleControlEnt(self.LaserBeam, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_weapon", self:GetCaster():GetOrigin(), true)
	ParticleManager:SetParticleControl(self.LaserBeam, 1, vLocation)
end

function karna_combo_vasavi:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	local hCaster = self:GetCaster()
	
	if hTarget == nil then 
		local end_radius = self:GetSpecialValueFor("end_radius")
		local end_targets = FindUnitsInRadius(hCaster:GetTeam(), vLocation, nil, end_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

		local full_damage = self:GetSpecialValueFor("full_damage")
		local damage_difference = self:GetSpecialValueFor("full_damage") - self:GetSpecialValueFor("beam_damage")		

		for i = 1, #end_targets do
			if IsDivineServant(end_targets[i]) and hCaster.IndraAttribute then
				full_damage = full_damage * 1.3
				damage_difference = damage_difference * 1.3
			elseif hCaster.IndraAttribute then
				full_damage = full_damage * 1.2
				damage_difference = damage_difference * 1.2
			end

			if not end_targets[i]:HasModifier("modifier_vasavi_hit") then
				DoDamage(hCaster, end_targets[i], full_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			else
				DoDamage(hCaster, end_targets[i], damage_difference, DAMAGE_TYPE_MAGICAL, 0, self, false)
			end
		end
		
		local particle = ParticleManager:CreateParticle("particles/custom/karna/combo/vasavi_explode.vpcf", PATTACH_CUSTOMORIGIN, self.Dummy)
		ParticleManager:SetParticleControl(particle, 0, self.Dummy:GetAbsOrigin()) 
		ParticleManager:SetParticleControl(particle, 1, Vector(end_radius + 200, end_radius + 200, end_radius + 200)) 

		ParticleManager:DestroyParticle(self.LaserBeam, false)
		ParticleManager:ReleaseParticleIndex(self.LaserBeam)

		--ParticleManager:DestroyParticle(self.WeaponSpark, true)
		--ParticleManager:ReleaseParticleIndex(self.WeaponSpark)

		EmitGlobalSound("karna_vasavi_explosion")

		Timers:CreateTimer(2, function()
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
			self.Dummy:RemoveSelf()

			return
		end)

		return 
	else
		local damage = self:GetSpecialValueFor("beam_damage")

		if IsDivineServant(hTarget) and hCaster.IndraAttribute then
			damage = damage * 1.5
		elseif hCaster.IndraAttribute then
			damage = damage * 1.25
		end

		hTarget:AddNewModifier(hCaster, self, "modifier_vasavi_hit", { Duration = 2 })
		DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	end	
end