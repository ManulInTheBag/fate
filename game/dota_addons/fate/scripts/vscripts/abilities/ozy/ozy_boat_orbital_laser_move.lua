ozy_boat_orbital_laser_move = class({})


function ozy_boat_orbital_laser_move:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetPoint = self:GetCursorPosition()
	local ozymandias = hCaster.ozy
	local boatOrigin = hCaster:GetAbsOrigin()
	local ozyOrigin = ozymandias:GetAbsOrigin()
	local direction = self:GetAnimeVectorTargetingMainDirection()
	self.direction = direction
	local width = self:GetSpecialValueFor("width")
	local range = self:GetAnimeVectorTargetingRange()
	local speed = 1000
	local timeToEnd = range/speed
	self.Laser = ParticleManager:CreateParticle("particles/ozy/boat/ozy_boat_laser_linear.vpcf", PATTACH_CUSTOMORIGIN, nil)
	self.laserStartPoint = boatOrigin + Vector(0,0, 2500)
	ParticleManager:SetParticleControlTransformForward(self.Laser, 1, self.laserStartPoint, direction)
	ParticleManager:SetParticleControl(self.Laser, 9, vTargetPoint)
	ParticleManager:SetParticleShouldCheckFoW(self.Laser, false)




end

