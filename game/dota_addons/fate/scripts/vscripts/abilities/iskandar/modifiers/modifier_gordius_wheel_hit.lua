modifier_gordius_wheel_hit = class({})

if IsServer() then
	function modifier_gordius_wheel_hit:OnCreated(args)
		self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_thunder_strike_bolt.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    	ParticleManager:SetParticleControl(self.particle, 0, self:GetParent():GetAbsOrigin())
	end

	function modifier_gordius_wheel_hit:OnDestroy()
		ParticleManager:DestroyParticle(self.particle, false)
		ParticleManager:ReleaseParticleIndex(self.particle)
	end
end

function modifier_gordius_wheel_hit:IsHidden()
	return true
end

function modifier_gordius_wheel_hit:IsDebuff()
	return true
end

function modifier_gordius_wheel_hit:RemoveOnDeath()
	return true
end

function modifier_gordius_wheel_hit:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
