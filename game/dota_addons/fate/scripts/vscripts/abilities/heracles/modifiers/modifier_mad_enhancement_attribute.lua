modifier_mad_enhancement_attribute = class({})

function modifier_mad_enhancement_attribute:IsHidden()
	return true
end

function modifier_mad_enhancement_attribute:IsPermanent()
	return true
end

function modifier_mad_enhancement_attribute:RemoveOnDeath()
	return false
end

function modifier_mad_enhancement_attribute:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_mad_enhancement_attribute:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_mad_enhancement_attribute:OnTakeDamage(args)
	if not self:GetParent():HasModifier("modifier_heracles_berserk") and not self.timeout and (args.damage >= 500) and (self:GetParent():FindAbilityByName("heracles_berserk"):GetCooldownTimeRemaining() > 2) then
		ReduceCooldown(self:GetParent():FindAbilityByName("heracles_berserk"), 2)
		self.timeout = true
		Timers:CreateTimer(2, function()
			self.timeout = false

		end)
	end
end