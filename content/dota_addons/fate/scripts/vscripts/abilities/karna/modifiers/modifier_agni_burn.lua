modifier_agni_burn = class({})

if IsServer() then
	function modifier_agni_burn:OnCreated(args)
		self:SetStackCount(args.Stacks or 1)
		self.BurnDamage = args.BurnDamage

		Timers:CreateTimer(args.Duration, function()
			if self then
				self:SetStackCount(self:GetStackCount() - 1)
			end
		end)

		local particle = ParticleManager:CreateParticle("particles/custom/karna/agni/agni_explosion.vpcf", PATTACH_ABSORIGIN, self:GetParent())
		ParticleManager:SetParticleControl(particle, 0, self:GetParent():GetAbsOrigin()) 

		Timers:CreateTimer(2, function()
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)

			return
		end)

		self:StartIntervalThink(0.25)
	end

	function modifier_agni_burn:OnRefresh(args)
		self:SetStackCount(self:GetStackCount() + 1)
		Timers:CreateTimer(args.Duration, function()
			if self then
				self:SetStackCount(self:GetStackCount() - 1)
			end
		end)
		self.BurnDamage = args.BurnDamage
	end

	function modifier_agni_burn:OnIntervalThink()
		local target = self:GetParent()
		local caster = self:GetCaster()
		local ability = self:GetAbility()

		DoDamage(caster, target, self.BurnDamage * self:GetStackCount() * 0.25, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	end
end

function modifier_agni_burn:RemoveOnDeath()
	return true 
end

function modifier_agni_burn:IsDebuff()
	return true
end

function modifier_agni_burn:GetEffectName()
	return "particles/custom/karna/agni/agni_fire_flame.vpcf"
end

function modifier_agni_burn:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end