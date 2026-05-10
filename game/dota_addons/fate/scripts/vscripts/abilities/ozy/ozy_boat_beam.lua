ozy_boat_beam = class({})

function ozy_boat_beam:GetAnimeVectorTargetingRange()
    return 1200
end
function ozy_boat_beam:GetAnimeVectorTargetingStartRadius()
	return 200
end
function ozy_boat_beam:GetAnimeVectorTargetingEndRadius()
	return 200
end
function ozy_boat_beam:IsAnimeVectorTargetingIgnoreWidth()
	return false
end
function ozy_boat_beam:GetAnimeVectorTargetingColor()
    return Vector(255, 255, 0)
end
function ozy_boat_beam:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetPoint = self:GetCursorPosition()
	local ozymandias = hCaster.ozy
	local boatOrigin = hCaster:GetAbsOrigin()
	local ozyOrigin = ozymandias:GetAbsOrigin()
	local direction = self:GetAnimeVectorTargetingMainDirection()
	direction.z = 0
	direction = direction:Normalized()
	self.direction = direction

	local width = self:GetSpecialValueFor("width")
	local range = self:GetAnimeVectorTargetingRange()
	local speed = 1000
	local timeToEnd = range/speed
	if (vTargetPoint-hCaster:GetAbsOrigin()):Length2D() > 1300 then
		vTargetPoint = hCaster:GetAbsOrigin() + (vTargetPoint-hCaster:GetAbsOrigin()):Normalized() * 1300
		--direction = -(targetPoint - targetPointOld):Normalized()+ direction 
	end
	self.Laser = ParticleManager:CreateParticle("particles/ozy/boat/ozy_boat_laser_linear.vpcf", PATTACH_CUSTOMORIGIN, nil)
	self.laserStartPoint = boatOrigin + Vector(0,0, 2500)
	ParticleManager:SetParticleControlTransformForward(self.Laser, 1, self.laserStartPoint, direction)
	ParticleManager:SetParticleControl(self.Laser, 9, vTargetPoint)
	ParticleManager:SetParticleShouldCheckFoW(self.Laser, false)
 	EmitSoundOnLocationWithCaster(vTargetPoint, "ozy_laser", hCaster)
	if ozymandias.ozySa2Acquired then
		self.Burn = ParticleManager:CreateParticle("particles/karna/brahmastra_laser/ground_burn.vpcf", PATTACH_CUSTOMORIGIN,nil)
		ParticleManager:SetParticleControl(self.Burn, 0, vTargetPoint)
		ParticleManager:SetParticleControl(self.Burn, 1, vTargetPoint)
		ParticleManager:SetParticleShouldCheckFoW(self.Burn, false)
	end
	vTargetPoint = vTargetPoint + direction*-100
	local projectileTable = {
		caster = hCaster,
		source = hCaster,
	    EffectName = "",
	    ability = self,
	    sourceLoc = vTargetPoint,
	    direction = direction,
	    speed = speed,
	    distance = range+200,
	    startRadius = width,
	    endRadius = width,
	    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	    iUnitTargetFlags = 0,
	    iUnitTargetType = DOTA_UNIT_TARGET_ALL,
	    DeleteOnHit = false,
	}
	self.burnendpoint = vTargetPoint
	local projectile = FATE_ProjectileManager:CreateLinearProjectile(projectileTable)
	--hCaster:EmitSound("karna_brahmastra_laser")
	if hCaster.ozy.ozySa2Acquired then
		local counter = 0
		local burnDamagePerTick = (self:GetSpecialValueFor("burn_damage") + self:GetSpecialValueFor("burn_damage_per_level") * hCaster.ozy:GetLevel())/10
		Timers:CreateTimer(0.1, function() 
				counter = counter +1
				if(counter > 30) then
					ParticleManager:DestroyParticle(self.Burn, true)
					ParticleManager:ReleaseParticleIndex(self.Burn)
					return 
				end
				local targets = FindUnitsInLine(  hCaster.ozy:GetTeamNumber(),
												vTargetPoint,
												self.burnendpoint,
												nil,
												120,
												DOTA_UNIT_TARGET_TEAM_ENEMY,
												DOTA_UNIT_TARGET_ALL,
												0
												)
												
				for k,v in pairs(targets) do       
					DoDamage(hCaster.ozy, v,burnDamagePerTick , self:GetAbilityDamageType(), 0, self, false)
				end								
				return 0.1
			end)

	end
	


end



function ozy_boat_beam:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	if hTarget == nil then
   		return
  	end
  	if (hTarget:GetName() == "npc_dota_ward_base") then
  		return
  	end
	
	local hCaster = self:GetCaster()
	giveUnitDataDrivenModifier(hCaster, hTarget, "locked", self:GetSpecialValueFor("lock_duration"))
    DoDamage(hCaster, hTarget, self:GetCaster().ozy:GetLevel()* self:GetSpecialValueFor("damage_per_level") + self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)

end

function ozy_boat_beam:OnProjectileThink_ExtraData(vLocation)
	vLocation = GetGroundPosition(vLocation, self:GetCaster())
	local jopa2 = vLocation+ self.direction * 80
	ParticleManager:SetParticleControlTransformForward(self.Laser, 1, vLocation, self.direction)
	ParticleManager:SetParticleControl(self.Laser, 9, self.laserStartPoint)
	if IsNotNull(self.Burn) then
		self.burnendpoint = jopa2
		ParticleManager:SetParticleControl(self.Burn, 1, jopa2)
	end
end
