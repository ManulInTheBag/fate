
LinkLuaModifier("modifier_ozy_combo_cd", "abilities/ozy/ozy_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ozy_combo_status_fx", "abilities/ozy/ozy_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ozy_no_healthbar", "abilities/ozy/ozy_spawn_piramid", LUA_MODIFIER_MOTION_NONE)
ozy_combo = class({})


function ozy_combo:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetPoint = self:GetCursorPosition()
	local masterCombo = hCaster.Ozy.MasterUnit2:FindAbilityByName(self:GetAbilityName())
	hCaster.Ozy.PerformingCombo = true
	local delay = self:GetSpecialValueFor("delay")

	EmitGlobalSound("ozymandias_combo")
	
	Timers:CreateTimer(delay +0.5, function()
		hCaster.Ozy.PerformingCombo = false
	end)
	if (vTargetPoint-hCaster:GetAbsOrigin()):Length2D() > 5000 then
		vTargetPoint = hCaster:GetAbsOrigin() + (vTargetPoint-hCaster:GetAbsOrigin()):Normalized() * 5000
	end
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))
	hCaster.Ozy:AddNewModifier(hCaster.Ozy, self, "modifier_ozy_combo_cd", {duration = self:GetCooldown(1)})
	hCaster:AddNewModifier(hCaster.Ozy, self, "modifier_ozy_no_healthbar", {duration = delay + 0.5})
	hCaster:AddNewModifier(hCaster.Ozy, self, "modifier_phased", {duration = delay + 0.5})
	hCaster:AddNewModifier(hCaster.Ozy, self, "modifier_ozy_combo_status_fx", {duration = delay + 0.5})
	local markFx = ParticleManager:CreateParticle("particles/ozy/ozy_combo_ground_marker.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl( markFx, 0, vTargetPoint)
	ParticleManager:SetParticleShouldCheckFoW(markFx, false)
	self.visiondummy = SpawnVisionDummy(hCaster, vTargetPoint, self:GetSpecialValueFor("radius"), delay + 0.5, false)
	hCaster:SetHullRadius(0)
	hCaster:SetBaseMoveSpeed(0)
	local particleFx = "particles/ozy/ozy_combo_trail.vpcf"
	local jopaFx1 = ParticleManager:CreateParticle(particleFx, PATTACH_CUSTOMORIGIN_FOLLOW, hCaster)
	ParticleManager:SetParticleControlEnt( jopaFx1, 3, hCaster,PATTACH_POINT_FOLLOW, "ATTACH_END", Vector(0,0,0), false  )
	ParticleManager:SetParticleShouldCheckFoW(jopaFx1, false)

	local jopaFx2 = ParticleManager:CreateParticle(particleFx, PATTACH_CUSTOMORIGIN_FOLLOW, hCaster)
	ParticleManager:SetParticleControlEnt( jopaFx2, 3, hCaster, PATTACH_POINT_FOLLOW, "ATTACH_END1", Vector(0,0,0), false   )
	ParticleManager:SetParticleShouldCheckFoW(jopaFx2, false)

	local jopaFx3 = ParticleManager:CreateParticle(particleFx, PATTACH_CUSTOMORIGIN_FOLLOW, hCaster)
	ParticleManager:SetParticleControlEnt( jopaFx3, 3, hCaster, PATTACH_POINT_FOLLOW, "ATTACH_END2", Vector(0,0,0), false   )
	ParticleManager:SetParticleShouldCheckFoW(jopaFx3, false)

	local jopaFx4 = ParticleManager:CreateParticle(particleFx, PATTACH_ABSORIGIN_FOLLOW, hCaster)
	ParticleManager:SetParticleControlEnt( jopaFx4, 3, hCaster, PATTACH_POINT_FOLLOW, "ATTACH_END3", Vector(0,0,0), false  )
	ParticleManager:SetParticleShouldCheckFoW(jopaFx4, false)
	---------------FLY UP-----------------------
	local ascendCount = 0
	local timeToAscent = 1.5
	local ascentHeightMax = 600
	local ascentCountMax = timeToAscent / 0.033
	local ascentStep = ascentHeightMax/ascentCountMax
	EmitSoundOn("piramid_fly_sound", hCaster)

	Timers:CreateTimer('piramid_ascend', {
			endTime = 0,
			callback = function()
			if ascendCount >= ascentCountMax then 	  
				return 
			end
			hCaster:SetAbsOrigin(Vector(hCaster:GetAbsOrigin().x,hCaster:GetAbsOrigin().y,hCaster:GetAbsOrigin().z+ascentStep))
			ascendCount = ascendCount + 1;
			return 0.033
		end
		})



	-----------------ROTATE IN AIR--------------
	local timeToRotate = 1
	Timers:CreateTimer(timeToAscent,function()
		StartAnimation(hCaster, {duration=5, activity=ACT_DOTA_RAZE_2, rate=2})
	end)

	rotateCounter = 1
	local forwardVec = hCaster:GetForwardVector()
	Timers:CreateTimer(timeToAscent +1,function()
		if rotateCounter == 150 then return end
		hCaster:SetForwardVector(RotatePosition(Vector(0,0,0), QAngle(0,30*rotateCounter,0), forwardVec))
		rotateCounter = rotateCounter + 1
		return 0.03
	end)
	


	-------------------FLY TO TARGET POINT------
	local descendCount = 0	
	local timeToDescent = 0.5
	local distance = (hCaster:GetAbsOrigin() -vTargetPoint):Length()
	local descentCountMax = timeToDescent / 0.033
	local DescentStep = distance/descentCountMax
	local DescentVector = (vTargetPoint - hCaster:GetAbsOrigin()):Normalized() * DescentStep
	local HeightDiff = (hCaster:GetAbsOrigin().z + ascentHeightMax - GetGroundPosition(vTargetPoint, hCaster).z)
	local HeightDiffTick = HeightDiff/descentCountMax 
	Timers:CreateTimer('piramid_descent', {
			endTime = timeToRotate +timeToRotate,
			callback = function()
			if descendCount >= descentCountMax then 	  
				return 
			end
			hCaster:SetAbsOrigin(Vector(hCaster:GetAbsOrigin().x,hCaster:GetAbsOrigin().y,hCaster:GetAbsOrigin().z) + DescentVector)
			descendCount = descendCount + 1;
			return 0.033
		end
		})



	-----------------------------DEAL EFFECTS---
	local dealdamageTimeMax = 0.5
	local damageTotal = self:GetSpecialValueFor("damage")
	local damageTotalBig = self:GetSpecialValueFor("damage_big")
	local dealDamageRadius = self:GetSpecialValueFor("outer_radius")
	local dealDamageRadiusInside = self:GetSpecialValueFor("radius")
	local counter = 0
	local CounterMax = dealdamageTimeMax/FrameTime()
	Timers:CreateTimer(timeToAscent +timeToRotate + timeToDescent, function()
		self.markFxEnd = ParticleManager:CreateParticle("particles/ozy/piramid/ozymandias_piramid_drop_ground.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl( self.markFxEnd, 0, vTargetPoint)
		ParticleManager:SetParticleShouldCheckFoW(self.markFxEnd, false)
		EmitSoundOn("ozy_piramid_destroy_sound", hCaster)
		EmitGlobalSound("ozy_piramid_destroy_sfx")
	end)
	Timers:CreateTimer(timeToAscent +timeToRotate + timeToDescent, function()
		if counter >= CounterMax then
			hCaster:AddNoDraw()
			hCaster.Ozy.Piramid = nil
			hCaster:Kill(nil, hCaster.Ozy)
			
			ParticleManager:DestroyParticle(markFx, true)
			ParticleManager:ReleaseParticleIndex(markFx)
			ParticleManager:DestroyParticle(jopaFx1, true)
			ParticleManager:ReleaseParticleIndex(jopaFx1)
			ParticleManager:DestroyParticle(jopaFx2, true)
			ParticleManager:ReleaseParticleIndex(jopaFx2)
			ParticleManager:DestroyParticle(jopaFx3, true)
			ParticleManager:ReleaseParticleIndex(jopaFx3)
			ParticleManager:DestroyParticle(jopaFx4, true)
			ParticleManager:ReleaseParticleIndex(jopaFx4)
			ParticleManager:DestroyParticle(self.markFxEnd, false)
			ParticleManager:ReleaseParticleIndex(self.markFxEnd)
			return 
		end
		hCaster:SetAbsOrigin(Vector(hCaster:GetAbsOrigin().x,hCaster:GetAbsOrigin().y,hCaster:GetAbsOrigin().z - 3000*FrameTime()))
		local targets = FindUnitsInRadius(hCaster:GetTeam(), vTargetPoint, nil, dealDamageRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			if (v:GetAbsOrigin() - hCaster:GetAbsOrigin()):Length2D() < dealDamageRadiusInside then
				DoDamage(hCaster, v, damageTotalBig/CounterMax, self:GetAbilityDamageType(), 0, self, false)
				v:AddNewModifier(hCaster, v, "modifier_stunned", {Duration = 1})
			else
				DoDamage(hCaster, v, damageTotal/CounterMax, self:GetAbilityDamageType(), 0, self, false)
			end
	    end
		counter = counter+1
		
		ScreenShake(vTargetPoint, 500, 1, FrameTime()*2, 2500, 0, true)
		return FrameTime()
	end)

 
end

modifier_ozy_combo_cd = class({})

function modifier_ozy_combo_cd:GetTexture()
    return "custom/ozy/ozy_combo"
end

function modifier_ozy_combo_cd:IsHidden()
    return false 
end

function modifier_ozy_combo_cd:RemoveOnDeath()
    return false
end

function modifier_ozy_combo_cd:IsDebuff()
    return true 
end

function modifier_ozy_combo_cd:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


modifier_ozy_combo_status_fx = class({})

function modifier_ozy_combo_status_fx:IsHidden()
	return true
end
function modifier_ozy_combo_status_fx:RemoveOnDeath()
	return true
end


function modifier_ozy_combo_status_fx:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_ozy_combo_status_fx:GetStatusEffectName()
    return "particles/ozy/ozy_piramid_statusfx.vpcf"
end

 