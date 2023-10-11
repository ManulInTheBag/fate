emiya_big_swords = emiya_big_swords or class({})

function emiya_big_swords:CastFilterResultTarget(hTarget)
    local caster = self:GetCaster()
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hTarget:GetAbsOrigin()) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function emiya_big_swords:GetCustomCastErrorTarget(jopa)
    return "You are fucking danger to society"
end


function emiya_big_swords:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	self.fw = caster:GetForwardVector()
	local range = self:GetSpecialValueFor("range")
	local speed = self:GetSpecialValueFor("speed")
	local rw = caster:GetRightVector()
	local tProjectile1 = self:GetProjectile(target,"particles/emiya/emiya_big_swords_1.vpcf", rw * 50,self.fw,range,speed,1)
	local tProjectile2 = self:GetProjectile(target,"particles/emiya/emiya_big_swords_2.vpcf", rw * 150,self.fw,range,speed,2)
	local tProjectile3 = self:GetProjectile(target,"particles/emiya/emiya_big_swords_3.vpcf", rw * -50,self.fw,range,speed,3)
	local tProjectile4 = self:GetProjectile(target,"particles/emiya/emiya_big_swords_4.vpcf", rw * -150,self.fw,range,speed,4)
	caster:EmitSound("emiya_big_swords_spawn")
	if( IsNotNull(target)) then 
		self.fw = -(caster:GetAbsOrigin() - target:GetAbsOrigin()):Normalized()
		 --tProjectile1 = self:GetProjectile(target,"particles/emiya/emiya_big_swords_1_tracking.vpcf", rw * 50,self.fw,range,speed,1)
		 tProjectile2 = self:GetProjectile(target,"particles/emiya/emiya_big_swords_2_tracking.vpcf", rw * 150,self.fw,range,speed,2)
		 --tProjectile3 = self:GetProjectile(target,"particles/emiya/emiya_big_swords_3_tracking.vpcf", rw * -50,self.fw,range,speed,3)
		 tProjectile4 = self:GetProjectile(target,"particles/emiya/emiya_big_swords_4_tracking.vpcf", rw * -150,self.fw,range,speed,4)
		local fx2  = ParticleManager:CreateParticle("particles/emiya/emiya_big_swords_spawn.vpcf", PATTACH_CUSTOMORIGIN , nil )
		ParticleManager:SetParticleControl(fx2, 0, caster:GetAbsOrigin() +rw * 150 )
		ParticleManager:SetParticleControl(fx2, 1, caster:GetAbsOrigin() +rw * 150 + self.fw*450  )
		local fx4  = ParticleManager:CreateParticle("particles/emiya/emiya_big_swords_spawn.vpcf", PATTACH_CUSTOMORIGIN , nil )
		ParticleManager:SetParticleControl(fx4, 0, caster:GetAbsOrigin() +rw * -150 )
		ParticleManager:SetParticleControl(fx4, 1, caster:GetAbsOrigin() +rw * -150 + self.fw*450  )
	else
		local fx1 = ParticleManager:CreateParticle("particles/emiya/emiya_big_swords_spawn.vpcf", PATTACH_CUSTOMORIGIN, nil )
		ParticleManager:SetParticleControl(fx1, 0, caster:GetAbsOrigin() +rw * 50 )
		ParticleManager:SetParticleControl(fx1, 1, caster:GetAbsOrigin() +rw * 50 + self.fw*450  )
		local fx2  = ParticleManager:CreateParticle("particles/emiya/emiya_big_swords_spawn.vpcf", PATTACH_CUSTOMORIGIN , nil )
		ParticleManager:SetParticleControl(fx2, 0, caster:GetAbsOrigin() +rw * 150 )
		ParticleManager:SetParticleControl(fx2, 1, caster:GetAbsOrigin() +rw * 150 + self.fw*450  )
		local fx3  = ParticleManager:CreateParticle("particles/emiya/emiya_big_swords_spawn.vpcf", PATTACH_CUSTOMORIGIN , nil )
		ParticleManager:SetParticleControl(fx3, 0, caster:GetAbsOrigin() +rw * -50 )
		ParticleManager:SetParticleControl(fx3, 1, caster:GetAbsOrigin() +rw * -50 + self.fw*450  )
		local fx4  = ParticleManager:CreateParticle("particles/emiya/emiya_big_swords_spawn.vpcf", PATTACH_CUSTOMORIGIN , nil )
		ParticleManager:SetParticleControl(fx4, 0, caster:GetAbsOrigin() +rw * -150 )
		ParticleManager:SetParticleControl(fx4, 1, caster:GetAbsOrigin() +rw * -150 + self.fw*450  )
	end

	Timers:CreateTimer(0.9, function() 
		if fx1 ~= nil then
			ParticleManager:DestroyParticle( fx1, true)
			ParticleManager:ReleaseParticleIndex( fx1)
		end
		if fx2 ~= nil then
			ParticleManager:DestroyParticle( fx2, true)
			ParticleManager:ReleaseParticleIndex( fx2)
		end
		if fx3 ~= nil then
			ParticleManager:DestroyParticle( fx3, true)
			ParticleManager:ReleaseParticleIndex( fx3)
		end
		if fx4 ~= nil then
			ParticleManager:DestroyParticle( fx4, true)
			ParticleManager:ReleaseParticleIndex( fx4)
		end
		if( IsNotNull(target)) then 
			--FATE_ProjectileManager:CreateTrackingProjectile(tProjectile1)
			FATE_ProjectileManager:CreateTrackingProjectile(tProjectile2)
			--FATE_ProjectileManager:CreateTrackingProjectile(tProjectile3)
			FATE_ProjectileManager:CreateTrackingProjectile(tProjectile4)
		else
			ProjectileManager:CreateLinearProjectile(tProjectile1)
			ProjectileManager:CreateLinearProjectile(tProjectile2)
			ProjectileManager:CreateLinearProjectile(tProjectile3)
			ProjectileManager:CreateLinearProjectile(tProjectile4)
		end
	end)

	
end

function emiya_big_swords:GetProjectile(target, effectname, CorrectionVector, fw, range, speed, swordNum)
	local caster = self:GetCaster()
	local vSpawnOrigin = caster:GetAbsOrigin() + CorrectionVector
	if IsNotNull(target) then
		local tProjectile = {
			Target = target,
			Ability = self,
			EffectName = effectname,
			iMoveSpeed = speed,
			bDodgeable = true,
			Source = caster,  
			vSourceLoc = vSpawnOrigin,
			bDeleteOnHit = true,
			bReplaceExisting = false,
			flExpireTime = GameRules:GetGameTime() + 3,
			ExtraData = {fDamage = self:GetSpecialValueFor("damage"), swordNum = swordNum, fw = fw, initxend = vSpawnOrigin.x, inityend = vSpawnOrigin.y,initzend = vSpawnOrigin.z, targeted = 1}

		  
		}
		return tProjectile

	else
		
		local tProjectile = {
			EffectName = effectname,
			Ability = self,
			vSpawnOrigin = vSpawnOrigin,
			vVelocity = fw * speed,
			fDistance = range,
			fStartRadius = 30,
			fEndRadius = 30,
			Source = caster,
			bHasFrontalCone = false,
			bReplaceExisting = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = 0,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			--bProvidesVision = true,
			bDeleteOnHit = true,
			--iVisionRadius = 500,
			--bFlyingVision = true,
			--iVisionTeamNumber = caster:GetTeamNumber(),
			ExtraData = {fDamage = self:GetSpecialValueFor("damage"), swordNum = swordNum, fw = fw, initxend = vSpawnOrigin.x, inityend = vSpawnOrigin.y,initzend = vSpawnOrigin.z, targeted = 0}
		}  
		return tProjectile
	end
	
end
 
 
function emiya_big_swords:DistanceToUbwEdge2D(vLocation, vVector) --- its cringe function but i had fun doing it so idc
	local ubwCenter = Vector(5926, -4837, 0)
	if( IsServer()) then 
		if(IsFFA()) then
			ubwCenter = Vector(5578.463867, -4475.173828, 0)
		end
	end
	local distanceFromCenter = (ubwCenter - vLocation):Length2D()
	local ubwRadius = 1100 -- this shit is actually not round, very bad circle,  trying to make it OK  
	local distance = distanceFromCenter
	local eps = 25 -- maximum error
	---- need to find point where circle and vector of unnown lenght touch. Dont know better solution, so just doing for loop  
	for i = 1,ubwRadius*2/eps do
		distanceFromCenter = (ubwCenter - (vLocation+vVector* i*25)):Length2D()
	  	if(distanceFromCenter >= ubwRadius + eps) then
			distance = i*25
			return  distance
		end
	end

	return  distance
end

function emiya_big_swords:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
  	local hCaster = self:GetCaster()
	  local fw = self.fw
	if(hTarget ~= nil) then
		
		
		DoDamage(hCaster, hTarget, tData.fDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		giveUnitDataDrivenModifier(hCaster, hTarget, "rooted", 0.3)
		giveUnitDataDrivenModifier(hCaster, hTarget, "locked", 0.3 +( hCaster.IsProjectionAcquired and 1.7 or 0) )
		hTarget:EmitSound("emiya_big_swords_hit")
		
		------Push target
		if not IsKnockbackImmune(hTarget) then
			local range = self:GetSpecialValueFor("range")
			local speed = self:GetSpecialValueFor("speed")
			if tData.targeted == 0 then
				local SwordAttachFx = ParticleManager:CreateParticle("particles/emiya/emiya_big_swords_"..tData.swordNum.."_target.vpcf", PATTACH_POINT_FOLLOW, hTarget)
				ParticleManager:SetParticleControlEnt(SwordAttachFx, 0, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetOrigin() , true)
				ParticleManager:SetParticleControlForward(SwordAttachFx,1,fw)
				ParticleManager:ReleaseParticleIndex(SwordAttachFx)
			else
			-- здесь должен быть партикль столкновения с другим вектором, но его нет, потому что севе нужно дописать свою либу а мне лень
			end

			local distanceTraveled = (vLocation - Vector(tData.initxend,tData.inityend,tData.initzend)):Length2D()		---jopa -- прим 30.08.2023: я не понял че сам  сделал
			local endpoint = vLocation + range  * fw --да, пинает оно тоже хуй пойми куда
			local knockbackDistance = range - distanceTraveled
			local distanceToUbwEdge = self:DistanceToUbwEdge2D(vLocation,fw )
			if(knockbackDistance > distanceToUbwEdge) then
				knockbackDistance = distanceToUbwEdge
			end
			self.knockback = { should_stun = true,
										knockback_duration = knockbackDistance/speed,
										duration = knockbackDistance/speed,
										knockback_distance = -knockbackDistance,
										knockback_height =  0,	
										center_x = endpoint.x,
										center_y = endpoint.y,
										center_z = endpoint.z }
			if(knockbackDistance > 80) then
				hTarget:AddNewModifier(hCaster, self, "modifier_knockback", self.knockback)     
			else
				giveUnitDataDrivenModifier(hCaster, hTarget, "stunned", 0.5)
			end
		end
		-----

	end

	---------create endcap
	if(hTarget == nil and  tData.targeted == 0) then
		local endcapFx = ParticleManager:CreateParticle("particles/emiya/emiya_big_swords_dissapear.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(endcapFx,3,vLocation)
		ParticleManager:SetParticleControlForward(endcapFx,3,fw)

	end

	------
	return true
end


