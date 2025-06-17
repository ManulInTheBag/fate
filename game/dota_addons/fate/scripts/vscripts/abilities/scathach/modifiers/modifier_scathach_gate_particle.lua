modifier_scathach_gate_particle = class({})

function modifier_scathach_gate_particle:IsHidden()
	return true
end

function modifier_scathach_gate_particle:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_scathach_gate_particle:IsDebuff()
	return false
end

function modifier_scathach_gate_particle:IsPurgable()
	return false
end

function modifier_scathach_gate_particle:OnCreated( kv )
	local parent = self:GetParent()
	local attacker_vector = parent:GetAbsOrigin()
	self:PlayEffects( true, attacker_vector )

	if IsServer() then
		self.parent = self:GetParent()
	end
end

function modifier_scathach_gate_particle:PlayEffects( front )
	-- Get Resources
	local particle_cast = "particles/custom/scathach/gate_of_skye_field.vpcf"
	local particle_cast_2 = "particles/custom/scathach/gate_of_skye_reborn.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:ReleaseParticleIndex( effect_cast )
	local effect_cast_2 = ParticleManager:CreateParticle( particle_cast_2, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:ReleaseParticleIndex( effect_cast )
end