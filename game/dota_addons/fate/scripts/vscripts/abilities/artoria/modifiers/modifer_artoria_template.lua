modifier_artoria_ = class({})

function modifier_artoria_:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED,
			 MODIFIER_PROPERTY_STATS_STRENGTH_BONUS }
end



if IsServer() then
	function modifier_artoria_:CheckState()
		return self.state
	end

	function modifier_artoria_:OnCreated(args)	
		caster=self:GetCaster
	end

	function modifier_artoria_:OnRefresh(args)
		self:RemoveParticles()
		self:OnCreated(args)
	end

	function modifier_artoria_:OnDestroy()
		self:RemoveParticles()
	end

	function modifier_artoria_:RemoveParticles()
		ParticleManager:DestroyParticle( self.SwordParticle, false )
		ParticleManager:ReleaseParticleIndex( self.SwordParticle )
	end

	function modifier_artoria_:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end		
		local caster = self:GetParent()
	end

	function modifier_artoria_:OnIntervalThink()
		self.state = {}
		self:StartIntervalThink(-1)
	end
end

function modifier_artoria_:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_artoria_:IsPurgable()
    return true
end

function modifier_artoria_:IsHidden()
    return true
end

function modifier_artoria_:IsDebuff()
    return false
end

function modifier_artoria_:RemoveOnDeath()
    return true
end

function modifier_artoria_:GetTexture()
    return "custom/artoria/"
end