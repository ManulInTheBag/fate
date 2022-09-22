modifier_doublespear_buidhe = class({})

function modifier_doublespear_buidhe:OnCreated(args)
	if IsServer() then
		self.RemainingCooldown = args.RemainingCooldown
	end
end

function modifier_doublespear_buidhe:OnRefresh(args)
	if IsServer() then
		self:OnCreated(args)
	end
end

function modifier_doublespear_buidhe:OnDestroy()
	if IsServer() then
		local caster = self:GetParent()
		local ability = caster:FindAbilityByName("diarmuid_gae_buidhe")
		ability:StartRemainingCooldown(self.RemainingCooldown)
	end
end

function modifier_doublespear_buidhe:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_doublespear_buidhe:IsHidden()
	return false
end

function modifier_doublespear_buidhe:IsDebuff()
	return false
end

function modifier_doublespear_buidhe:RemoveOnDeath()
    return true
end

function modifier_doublespear_buidhe:GetTexture()
	return "custom/diarmuid_gae_buidhe"
end