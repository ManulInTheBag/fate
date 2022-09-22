modifier_rho_aias_particle = class({})

if IsServer() then
	function modifier_rho_aias_particle:OnCreated(args)
		self.rhoShieldParticleIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_rhoaias_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		self:StartIntervalThink(0.1)
	end

	function modifier_rho_aias_particle:OnRefresh(args)
		self:OnDestroy()
		self:OnCreated(args)
	end

	function modifier_rho_aias_particle:OnDestroy()
		ParticleManager:DestroyParticle( self.rhoShieldParticleIndex, false )
		ParticleManager:ReleaseParticleIndex( self.rhoShieldParticleIndex)
	end

	function modifier_rho_aias_particle:OnIntervalThink()
		local target = self:GetParent()
		ParticleManager:SetParticleControl( self.rhoShieldParticleIndex, 0, target:GetAbsOrigin() )
				
		local origin = self:GetParent():GetAbsOrigin()
		local forwardVec = self:GetParent():GetForwardVector()
		local rightVec = self:GetParent():GetRightVector()

		ParticleManager:SetParticleControl( self.rhoShieldParticleIndex, 1, Vector( origin.x + 150 * forwardVec.x, origin.y + 150 * forwardVec.y, origin.z + 225 ) ) -- petal_core, center of petals
		ParticleManager:SetParticleControl( self.rhoShieldParticleIndex, 2, Vector( origin.x - 30 * forwardVec.x, origin.y - 30 * forwardVec.y, origin.z + 375 ) ) -- petal_a
		ParticleManager:SetParticleControl( self.rhoShieldParticleIndex, 3, Vector( origin.x + 150 * forwardVec.x, origin.y + 150 * forwardVec.y, origin.z ) ) -- petal_d
		ParticleManager:SetParticleControl( self.rhoShieldParticleIndex, 4, Vector( origin.x + 150 * rightVec.x, origin.y + 150 * rightVec.y, origin.z + 300 ) ) -- petal_b
		ParticleManager:SetParticleControl( self.rhoShieldParticleIndex, 5, Vector( origin.x - 150 * rightVec.x, origin.y - 150 * rightVec.y, origin.z + 300 ) ) -- petal_c
		ParticleManager:SetParticleControl( self.rhoShieldParticleIndex, 6, Vector( origin.x + 150 * rightVec.x + 60 * forwardVec.x, origin.y + 150 * rightVec.y + 60 * forwardVec.y, origin.z + 25 ) ) -- petal_e
		ParticleManager:SetParticleControl( self.rhoShieldParticleIndex, 7, Vector( origin.x - 150 * rightVec.x + 60 * forwardVec.x, origin.y - 150 * rightVec.y + 60 * forwardVec.y, origin.z + 25 ) ) -- petal_f
	end
end

function modifier_rho_aias_particle:IsHidden()
	return true 
end