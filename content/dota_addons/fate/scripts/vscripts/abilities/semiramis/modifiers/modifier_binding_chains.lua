modifier_binding_chains = class({})

if IsServer() then
	function modifier_binding_chains:OnCreated(args)
		local target = self:GetParent()

		self:InitializeParticles()
	end

	function modifier_binding_chains:OnRefresh(args)
		self:OnDestroy()
		self:OnCreated(args)
	end

	function modifier_binding_chains:OnDestroy()
		self:RemoveParticles()
	end

	function modifier_binding_chains:InitializeParticles()
		local caster = self:GetCaster()
		local target = self:GetParent()
		local portal_loc = caster:GetAbsOrigin() + Vector(0, 0, 250)

		self.portal_particle = ParticleManager:CreateParticle( "particles/custom/semiramis/binding_chains/magic_circle.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
		ParticleManager:SetParticleControl( self.portal_particle, 4, portal_loc )

		self.chain_1 = ParticleManager:CreateParticle( "particles/custom/semiramis/semiramis_chains_body.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
		ParticleManager:SetParticleControl(self.chain_1, 2, target:GetAbsOrigin() + RandomVector(25) + Vector(0, 0, 30))
		ParticleManager:SetParticleControl(self.chain_1, 1, portal_loc )

		self.chain_2 = ParticleManager:CreateParticle( "particles/custom/semiramis/semiramis_chains_body.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
		ParticleManager:SetParticleControl(self.chain_2, 2, target:GetAbsOrigin() + RandomVector(35) + Vector(0, 0, 30))
		ParticleManager:SetParticleControl(self.chain_2, 1, portal_loc )

		self.chain_3 = ParticleManager:CreateParticle( "particles/custom/semiramis/semiramis_chains_body.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
		ParticleManager:SetParticleControl(self.chain_3, 2, target:GetAbsOrigin() + RandomVector(45) + Vector(0, 0, 30))
		ParticleManager:SetParticleControl(self.chain_3, 1, portal_loc )
	end

	function modifier_binding_chains:RemoveParticles()
		ParticleManager:DestroyParticle( self.portal_particle, true )
		ParticleManager:ReleaseParticleIndex( self.portal_particle )
		ParticleManager:DestroyParticle( self.chain_1, true )
		ParticleManager:ReleaseParticleIndex( self.chain_1 )
		ParticleManager:DestroyParticle( self.chain_2, true )
		ParticleManager:ReleaseParticleIndex( self.chain_2 )
		ParticleManager:DestroyParticle( self.chain_3, true )
		ParticleManager:ReleaseParticleIndex( self.chain_3 )
	end
end

function modifier_binding_chains:CheckState()
	return { [MODIFIER_STATE_ROOTED] = true,
			 [MODIFIER_STATE_DISARMED] = true }
end

function modifier_binding_chains:IsDebuff()
	return true
end

function modifier_binding_chains:RemoveOnDeath()
	return true
end