modifier_enkidu_hold = class({})

if IsServer() then 
	function modifier_enkidu_hold:OnCreated(args)
		self.Particle = ParticleManager:CreateParticle( "particles/custom/gilgamesh/gilgamesh_enkidu.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControlEnt( self.Particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_origin", self:GetParent():GetAbsOrigin(), true )
		ParticleManager:SetParticleControl( self.Particle, 1, self:GetParent():GetAbsOrigin() )
	end

	function modifier_enkidu_hold:OnDestroy()
		ParticleManager:DestroyParticle( self.Particle, true )
		ParticleManager:ReleaseParticleIndex( self.Particle )
	end
end

function modifier_enkidu_hold:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true,
			 [MODIFIER_STATE_COMMAND_RESTRICTED] = true }
end

function modifier_enkidu_hold:GetTexture()
	return "custom/gilgamesh_enkidu"
end