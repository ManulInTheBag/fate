emiya_change = emiya_change or class({})

function emiya_change:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self

	if caster:FindAbilityByName("emiya_double_slash"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("emiya_double_slash"):SetLevel(self:GetLevel())
    end
 
 
end


function emiya_change:OnSpellStart()
	local vPoint = self:GetCursorPosition()
	self.arrowsPoint = vPoint 
	self.hCaster = self:GetCaster()
	self.vCasterPos = self.hCaster:GetAbsOrigin()
	local vCastDirection =    vPoint - self.vCasterPos
	vCastDirection.z = 0
	self.hCaster:SetForwardVector(vCastDirection)
	local distance = vCastDirection:Length2D()
	if(distance > self:GetSpecialValueFor("distance")) then
		self.arrowsPoint = vCastDirection:Normalized() *  self:GetSpecialValueFor("distance") + self.vCasterPos
	end
	vPoint = vCastDirection:Normalized() * 20000 + self.vCasterPos
	StartAnimation(self.hCaster, {duration=0.6, activity=ACT_DOTA_CAST_ABILITY_2, rate=1.0})
	giveUnitDataDrivenModifier(self.hCaster, self.hCaster, "pause_sealenabled", 0.6)
	Timers:CreateTimer(0.257,function()
		self:ShootArrow(self.vCasterPos + self.hCaster:GetForwardVector() * - 50, vPoint, 3500)
		self.hCaster:EmitSound("Ability.Powershot.Alt")
	end)
	Timers:CreateTimer(0.6,function()
		self:DoSwap()
	end)
	

end

function emiya_change:DoSwap()
	local swapAbil = self.hCaster:FindAbilityByName("emiya_weapon_swap")
	swapAbil:SwapWeapons(1)
	--self.hCaster:CastAbilityImmediately(swapAbil, self.hCaster:GetPlayerOwner():GetPlayerID())--- idk why do it like that, just for test
	self.hCaster:SetBodygroup(0,0)
end

function emiya_change:ShootArrow(vSpawnLoc, vPoint, nSpeed)
	pull_center = self.hCaster:GetForwardVector() * -300 +self.vCasterPos
	local endPos = self.hCaster:GetForwardVector()*700 + self.vCasterPos
	    self.knockback = { should_stun = true,
                                    knockback_duration = 0.2,
                                    duration = 0.2,
                                    knockback_distance = -300,
                                    knockback_height =  0,
                                    center_x = pull_center.x,
                                    center_y = pull_center.y,
                                    center_z = pull_center.z }
    self.hCaster:AddNewModifier( self.hCaster, self, "modifier_knockback", self.knockback) 
	local point_particle = ParticleManager:CreateParticle("particles/emiya/emiya_change_aoe_marker.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(point_particle, 0,  self.arrowsPoint )
	ParticleManager:SetParticleControl(point_particle, 1,  Vector(200,0,0) )
    local sArrowParticle = "particles/emiya/emiya_change_arrow_base.vpcf" 
	local nArrowParticle =  ParticleManager:CreateParticle(sArrowParticle, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleShouldCheckFoW(nArrowParticle, false)
	ParticleManager:SetParticleAlwaysSimulate(nArrowParticle)
	ParticleManager:SetParticleControl(nArrowParticle, 0, vSpawnLoc)
	ParticleManager:SetParticleControl(nArrowParticle, 1, GetGroundPosition(vPoint, nil))
	ParticleManager:SetParticleControl(nArrowParticle, 2, Vector(nSpeed, 0, 0))
	Timers:CreateTimer(0.6,function()
		ParticleManager:DestroyParticle(nArrowParticle, true)
		ParticleManager:ReleaseParticleIndex(nArrowParticle)
	end)
	Timers:CreateTimer(0.8,function()
		local nArrowParticleEnd =  ParticleManager:CreateParticle("particles/emiya/emiya_change_arrow_base_dissapear.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleShouldCheckFoW(nArrowParticleEnd, false)
		ParticleManager:SetParticleControl(nArrowParticleEnd, 3, self.arrowsPoint + Vector(0,0,1500))
		ParticleManager:ReleaseParticleIndex(nArrowParticleEnd)

	end)
	Timers:CreateTimer(1,function()
		ParticleManager:DestroyParticle(point_particle, true)
		ParticleManager:ReleaseParticleIndex(point_particle)
		local enemies = FindUnitsInRadius(  self.hCaster:GetTeamNumber(),
						self.arrowsPoint,
                        nil,
                        250,
                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                        DOTA_UNIT_TARGET_ALL,
                        DOTA_UNIT_TARGET_FLAG_NONE,
                        FIND_ANY_ORDER,
                        false)
    
     	for _,enemy in pairs(enemies) do
			DoDamage(self.hCaster, enemy, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
			giveUnitDataDrivenModifier(self.hCaster,enemy , "stunned", self:GetSpecialValueFor("stun_duration"))
       	end

	end)

end
 

function emiya_change:ReleaseArrow(frames)
	local caster = self:GetCaster()
	EndAnimation(caster)
	caster:RemoveModifierByNameAndCaster("modifier_emiya_caladbolg", caster)
    local casterFX = ParticleManager:CreateParticle("particles/emiya/caladbolg_init.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControlEnt(casterFX, 1, caster, PATTACH_ABSORIGIN, nil, caster:GetOrigin(), false)
    ParticleManager:ReleaseParticleIndex(casterFX)
	local target = caster:GetForwardVector()
	local range = self:GetSpecialValueFor("range") * (0.5 + frames/(self.maxtime*60))
	caster:EmitSound("Emiya_Caladbolg_" .. math.random(1,2))
	local tProjectile = {
		EffectName = "particles/emiya/caladbolg.vpcf",
		Ability = self,
		vSpawnOrigin = caster:GetAbsOrigin(),
		vVelocity = target * self:GetSpecialValueFor("speed") ,
		fDistance = range,
		fStartRadius = 100,
		fEndRadius = 100,
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
		ExtraData = {fDamage = self:GetSpecialValueFor("damage") * frames/(self.maxtime*30), fRadius = self:GetSpecialValueFor("radius")}
	}  
	self.iProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)
	--self:StartCooldown(self:GetLevel())	  	
end

function emiya_change:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
  	local hCaster = self:GetCaster()
	if(hTarget ~= nil) then
		local explosionFx = ParticleManager:CreateParticle("particles/emiya/caladbolg_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(explosionFx, 1, hTarget:GetAbsOrigin())
		ParticleManager:SetParticleControl(explosionFx, 0, hTarget:GetAbsOrigin())
		ParticleManager:SetParticleControl(explosionFx, 3, hTarget:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(explosionFx)
 		

		local enemies = FindUnitsInRadius(  hCaster:GetTeamNumber(),
						hTarget:GetAbsOrigin(),
                        nil,
                        tData.fRadius,
                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                        DOTA_UNIT_TARGET_ALL,
                        DOTA_UNIT_TARGET_FLAG_NONE,
                        FIND_ANY_ORDER,
                        false)
    
     	for _,enemy in pairs(enemies) do
			DoDamage(hCaster, hTarget, tData.fDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
       	end
		   hTarget:EmitSound("Misc.Crash")

		
	end
   	Timers:CreateTimer(0.033,function()
   		ProjectileManager:DestroyLinearProjectile(self.iProjectile)
  	end)
	return true
end

function emiya_change:OnProjectileThink(location)
    local caster = self:GetCaster()
    local radius = 100
    local duration = 0.5

    AddFOWViewer(caster:GetTeamNumber(), location, radius, duration, false)
end
 