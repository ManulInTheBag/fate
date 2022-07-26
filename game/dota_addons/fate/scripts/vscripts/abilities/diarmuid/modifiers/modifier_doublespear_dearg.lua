modifier_doublespear_dearg = class({})

function modifier_doublespear_dearg:OnCreated(args)
	if IsServer() then
		self.RemainingCooldown = args.RemainingCooldown
	end
end

function modifier_doublespear_dearg:OnRefresh(args)
	if IsServer() then
		self:OnCreated(args)
	end
end

function modifier_doublespear_dearg:OnDestroy()
	if IsServer() then
		local caster = self:GetParent()
		local ability = caster:FindAbilityByName("diarmuid_gae_dearg")
		ability:StartRemainingCooldown(self.RemainingCooldown)
	end
end

function modifier_doublespear_dearg:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_doublespear_dearg:IsHidden()
	return false
end

function modifier_doublespear_dearg:IsDebuff()
	return false
end

function modifier_doublespear_dearg:RemoveOnDeath()
    return true
end

function modifier_doublespear_dearg:GetTexture()
	return "custom/diarmuid_gae_buidhe"
end