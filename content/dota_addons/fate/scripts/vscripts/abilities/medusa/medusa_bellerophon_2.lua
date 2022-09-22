LinkLuaModifier("modifier_medusa_bellerophon","abilities/medusa/medusa_bellerophon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_medusa_bellerophon_cd", "abilities/medusa/medusa_bellerophon_2", LUA_MODIFIER_MOTION_NONE)

medusa_bellerophon_2 = class({})

function medusa_bellerophon_2:OnAbilityPhaseStart()
    EmitSoundOn("medusa_np_start", self:GetCaster())
    return true
end

function medusa_bellerophon_2:OnAbilityPhaseInterrupted()
    StopSoundOn("medusa_np_start", self:GetCaster())
end

function medusa_bellerophon_2:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_medusa_monstrous_strength") then
    	return UF_FAIL_CUSTOM
    elseif caster:GetAbsOrigin().y < -1700 then
    	return UF_FAIL_CUSTOM
    else
    	return UF_SUCCESS
    end
end

function medusa_bellerophon_2:GetCustomCastErrorLocation(hLocation)
	local caster = self:GetCaster()
    if caster:HasModifier("modifier_medusa_monstrous_strength") then
    	return "#Monstrous_Strength_Active"
    elseif caster:GetAbsOrigin().y < -1700 then
    	return "#Is_In_Marble"
    end
end

function medusa_bellerophon_2:OnSpellStart()
	local caster = self:GetCaster()
	local initialVec = caster:GetForwardVector()
	local initialPosition = caster:GetAbsOrigin()

	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))
    local abil = caster:FindAbilityByName("medusa_bellerophon")
    abil:StartCooldown(abil:GetCooldown(abil:GetLevel() - 1))

    caster:AddNewModifier(caster, self, "modifier_medusa_bellerophon_cd", {duration = self:GetCooldown(1)})

	self.AttackedTargets    = {}
	self.belle_proj = nil

	local ascendCount = 1
	local descendCount = 0
	local ascend_dist = 0
	local asc_pepe = 30

	local dmgdelay = 0

	EmitSoundOn("medusa_pegasus_flight", caster)

	Timers:CreateTimer(2.2, function()
		if not caster:IsAlive() then
			StopSoundOn("medusa_pegasus_flight", caster)
			return
		end
		EmitSoundOn("medusa_belle_alt_new", caster)
	end)

	local circle_center = caster:GetAbsOrigin() + caster:GetRightVector()*2000

	--[[Timers:CreateTimer(1.0, function()
		EmitGlobalSound("medusa_bellerophon_alt")
	end)]]

	--caster:SetForwardVector(-Vector(ascendVec.x, ascendVec.y, 0))

	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 3.66)

	local trail_fx = ParticleManager:CreateParticle( "particles/medusa/medusa_trail_test_3.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(trail_fx, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

	local chTarget = CreateUnitByName("medusa_pegasus", caster:GetAbsOrigin(), true, caster, nil, caster:GetTeamNumber())
	local unseen = chTarget:FindAbilityByName("dummy_unit_passive_no_fly")
	unseen:SetLevel(1)
	chTarget:SetAbsOrigin(caster:GetAbsOrigin())
	chTarget:SetForwardVector(caster:GetForwardVector())
	giveUnitDataDrivenModifier(caster, chTarget, "jump_pause", 3.66)

	local first_time_huh = false

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 999999, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
		if not first_time_huh then
			first_time_huh = true
			caster:AddNewModifier(enTarget, nil, "modifier_medusa_bellerophon", {duration = 3.66})
			chTarget:AddNewModifier(enTarget, nil, "modifier_medusa_bellerophon", {duration = 3.66})
		end
	end

	StartAnimation(caster, {duration=2.97, activity=ACT_DOTA_RAZE_2, rate=0.5})
	StartAnimation(chTarget, {duration=2.97, activity=ACT_DOTA_RAZE_3, rate=0.5})

	PlayerResource:SetCameraTarget(caster:GetPlayerOwnerID(), caster)

	Timers:CreateTimer(3.66, function()
		PlayerResource:SetCameraTarget(caster:GetPlayerOwnerID(), nil)
		if IsValidEntity(chTarget) and not chTarget:IsNull() then 
		    chTarget:ForceKill(false)
		    chTarget:AddEffects(EF_NODRAW)
		end
	end)

	Timers:CreateTimer(3.8, function()
		ParticleManager:DestroyParticle(trail_fx, false)
		ParticleManager:ReleaseParticleIndex(trail_fx)
	end)

	Timers:CreateTimer(FrameTime(), function()
		if ascendCount == 91 then
			--caster:SetAbsOrigin(initialPosition)
			--caster:SetForwardVector(initialVec)
			--chTarget:SetAbsOrigin(caster:GetAbsOrigin())
			--chTarget:SetForwardVector(caster:GetForwardVector())
			--print(init_origin)
			--print(caster:GetAbsOrigin())
		 	return
		end
		if ascendCount < 46 then
			asc_pepe = ascendCount
		else
			asc_pepe = -ascendCount + 45
		end
		if not caster:IsAlive() then
			StopSoundOn("medusa_pegasus_flight", caster)
			StopSoundOn("medusa_belle_alt_new", caster)
			return
		end
		ascend_dist = ascend_dist + asc_pepe
		local origin = caster:GetAbsOrigin()
		local next_pos = GetGroundPosition(RotatePosition(circle_center, QAngle(0,-ascendCount*360/(90*91/2),0), origin), caster)
		local see_vec = (Vector(next_pos.x, next_pos.y, asc_pepe) - Vector(origin.x, origin.y, 0)):Normalized()
		--print((Vector(next_pos.x, next_pos.y, asc_pepe) - Vector(origin.x, origin.y, 0)):Length2D())
		caster:SetForwardVector(see_vec)
		caster:SetAbsOrigin(next_pos + Vector(0, 0, ascend_dist))
		chTarget:SetAbsOrigin(caster:GetAbsOrigin())
		chTarget:SetForwardVector(caster:GetForwardVector())
		ascendCount = ascendCount + 1
		return 0.033
	end)


	Timers:CreateTimer(FrameTime()*90, function()
		if not caster:IsAlive() then
			StopSoundOn("medusa_pegasus_flight", caster)
			StopSoundOn("medusa_belle_alt_new", caster)
			return
		end
		caster:SetForwardVector(initialVec)

		StartAnimation(caster, {duration=0.9, activity=ACT_DOTA_RAZE_1, rate=1})
		StartAnimation(chTarget, {duration=0.9, activity=ACT_DOTA_RAZE_1, rate=1})

		local projectile_info = {
					Ability = self,
					EffectName = nil,
					vSpawnOrigin = caster:GetAbsOrigin(),
					fDistance = 5440,
					fStartRadius = 400,
					fEndRadius = 400,
					Source = self:GetCaster(),
					bHasFrontalCone = false,
					bReplaceExisting = false,
					iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
					iUnitTargetFlags = nil,
					iUnitTargetType = DOTA_UNIT_TARGET_HERO,
					fExpireTime = GameRules:GetGameTime() + 0.9,
					vVelocity = Vector(caster:GetForwardVector().x, caster:GetForwardVector().y, 0)*272*30,
					bProvidesVision = false,
					bDeleteOnHit = false
				}
		self.belle_proj = ProjectileManager:CreateLinearProjectile(projectile_info)

		local effectIndex_b = ParticleManager:CreateParticle("particles/th2/heroes/marisa/marisa_04_spark_wind_b.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(effectIndex_b, 0, caster:GetOrigin() + Vector(caster:GetForwardVector().x * 0,caster:GetForwardVector().y * 0,150))
				ParticleManager:SetParticleControl(effectIndex_b, 8, caster:GetForwardVector())

		Timers:CreateTimer(2.0, function()
					if effectIndex_b then
						ParticleManager:DestroyParticle(effectIndex_b, false)
					end
				end)

		Timers:CreateTimer(function()
			local origin = caster:GetAbsOrigin()
			--if (origin - targetPoint):Length2D() > 2000 then return end
			if descendCount == 20 then
				FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
				return
			end

			--caster:SetForwardVector(Vector(descendVec.x, descendVec.y, 0))
			local next_pos_desc = GetGroundPosition(caster:GetAbsOrigin() + caster:GetForwardVector()*272, caster)
			local destroy_proj = false
			if next_pos_desc.x > 8160 then
				next_pos_desc.x = 8160
				destroy_proj = true
			end
			if next_pos_desc.x < -8160 then
				next_pos_desc.x = -8160
				destroy_proj = true
			end
			if next_pos_desc.y > 7000 then
				next_pos_desc.y = 7000
				destroy_proj = true
			end
			if next_pos_desc.y < -1568 then
				next_pos_desc.y = -1568
				destroy_proj = true
			end
			caster:SetAbsOrigin(next_pos_desc)

			chTarget:SetAbsOrigin(caster:GetAbsOrigin())
			chTarget:SetForwardVector(caster:GetForwardVector())

			if destroy_proj == true then
				ProjectileManager:DestroyLinearProjectile(self.belle_proj)
				projectile_info = {
					Ability = self,
					EffectName = nil,
					vSpawnOrigin = caster:GetAbsOrigin(),
					fDistance = 5440,
					fStartRadius = 400,
					fEndRadius = 400,
					Source = self:GetCaster(),
					bHasFrontalCone = false,
					bReplaceExisting = false,
					iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
					iUnitTargetFlags = nil,
					iUnitTargetType = DOTA_UNIT_TARGET_HERO,
					fExpireTime = GameRules:GetGameTime() + 0.9,
					vVelocity = Vector(caster:GetForwardVector().x, caster:GetForwardVector().y, 0)*272*30,
					bProvidesVision = false,
					bDeleteOnHit = false
				}
				self.belle_proj = ProjectileManager:CreateLinearProjectile(projectile_info)
			end

			descendCount = descendCount + 1
			return 0.033
		end)
	end)
end

function medusa_bellerophon_2:OnProjectileHit_ExtraData(hTarget, vLocation, hTable)
    if IsNotNull(hTarget) then
        local hCaster       = self:GetCaster()
        local iCasterTeam   = hCaster:GetTeamNumber()
        local caster = self:GetCaster()
        local enemy = hTarget

        if not self.AttackedTargets[hTarget:entindex()] then
            self.AttackedTargets[hTarget:entindex()] = true
        	DoDamage(hCaster, hTarget, self:GetSpecialValueFor("damage") + (hCaster.RidingAcquired and (self:GetSpecialValueFor("riding_damage") + hCaster:GetAgility()*self:GetSpecialValueFor("agility_multiplier")) or 0), DAMAGE_TYPE_MAGICAL, 0, self, false)
        	enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})

	        local anglevalue = caster:GetRightVector()
	        local right_point = caster:GetAbsOrigin() + anglevalue*100
	        local left_point = caster:GetAbsOrigin() - anglevalue*100

	        local right_len = (right_point - enemy:GetAbsOrigin()):Length2D()
	        local left_len = (left_point - enemy:GetAbsOrigin()):Length2D()

	        if (left_len < right_len) then
	        	anglevalue = -anglevalue
	        end

		    local temptarget = CreateUnitByName("hrunt_illusion", enemy:GetAbsOrigin(), true, caster, nil, caster:GetTeamNumber())
			temptarget:SetModel("models/development/invisiblebox.vmdl")
		    temptarget:SetOriginalModel("models/development/invisiblebox.vmdl")
		    temptarget:SetModelScale(1)
		    local unseen = temptarget:FindAbilityByName("dummy_unit_passive")
		    unseen:SetLevel(1)

		    Timers:CreateTimer(5, function()
				if IsValidEntity(temptarget) and not temptarget:IsNull() then 
		            temptarget:ForceKill(false)
		            temptarget:AddEffects(EF_NODRAW)
		    	end
		    end)

			temptarget:SetForwardVector(anglevalue)

			local kborigin = -temptarget:GetForwardVector()*100 + temptarget:GetAbsOrigin()

			local knockback = { should_stun = false,
	                                knockback_duration = 0.25,
	                                duration = 0.25,
	                                knockback_distance = 300 or 0,
	                                knockback_height = 150,
	                                center_x = kborigin.x,
	                                center_y = kborigin.y,
	                                center_z = kborigin.z }

	    	enemy:AddNewModifier(caster, self, "modifier_knockback", knockback)
        end
    end
end

modifier_medusa_bellerophon_cd = class({})

function modifier_medusa_bellerophon_cd:GetTexture()
	return "custom/medusa/medusa_bellerophon_2"
end

function modifier_medusa_bellerophon_cd:IsHidden()
	return false 
end

function modifier_medusa_bellerophon_cd:RemoveOnDeath()
	return false
end

function modifier_medusa_bellerophon_cd:IsDebuff()
	return true 
end

function modifier_medusa_bellerophon_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end