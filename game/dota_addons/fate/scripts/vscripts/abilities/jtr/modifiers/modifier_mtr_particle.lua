modifier_mtr_particle = class({})

function modifier_mtr_particle:OnCreated()
	self.ParticleDummy = CreateUnitByName("dummy_unit", self:GetParent():GetAbsOrigin(), false, nil, nil, self:GetParent():GetTeamNumber())
	self.ParticleDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	self.Particle = ParticleManager:CreateParticle("particles/jtr/mtr_shadow.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self.ParticleDummy)
    ParticleManager:SetParticleControl(self.Particle, 1, self.ParticleDummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.Particle, 2, self.ParticleDummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.Particle, 3, self.ParticleDummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.Particle, 4, self.ParticleDummy:GetAbsOrigin())
    self:StartIntervalThink(0.033)
end
function modifier_mtr_particle:OnIntervalThink()
	self.ParticleDummy:SetAbsOrigin(self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(self.Particle, 1, self.ParticleDummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.Particle, 2, self.ParticleDummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.Particle, 3, self.ParticleDummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.Particle, 4, self.ParticleDummy:GetAbsOrigin())
end
function modifier_mtr_particle:OnDestroy()
	ParticleManager:DestroyParticle(self.Particle, false)
	ParticleManager:ReleaseParticleIndex(self.Particle)
	self.ParticleDummy:RemoveSelf()
end
function modifier_mtr_particle:CheckState()
	return --{ [MODIFIER_STATE_INVISIBLE] = true }
end