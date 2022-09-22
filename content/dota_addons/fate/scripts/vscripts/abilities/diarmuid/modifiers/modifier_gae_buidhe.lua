modifier_gae_buidhe = class({})

function modifier_gae_buidhe:OnCreated(args)
	if IsServer() then
		print("buff created")
		self:SetStackCount(args.Stacks or 1)
		self:StartIntervalThink(0.033)
		print("started thinking")
	end
end

function modifier_gae_buidhe:OnRefresh(args)
	if IsServer() then
		--args.Stacks = self:GetStackCount() + args.Stacks
		self:OnCreated(args)		
	end
end

function modifier_gae_buidhe:OnIntervalThink()
	--print("thinking buidhe")
	local target = self:GetParent()
	local max_health = math.max(target:GetMaxHealth() - (10 * self:GetStackCount()), 1)

	if target:GetHealth() > max_health and not (target:GetHealth() == 0) then
		target:SetHealth(max_health)
	elseif target:GetMaxHealth() < max_health or (target:GetHealth() == 0) or (not target:IsAlive()) then
		target:Kill(self:GetAbility(), self:GetCaster())		
		self:Destroy()
	end
end

function modifier_gae_buidhe:IsHidden()
	return false
end

function modifier_gae_buidhe:IsDebuff()
	return true
end

function modifier_gae_buidhe:RemoveOnDeath()
	return true
end

function modifier_gae_buidhe:IsPurgable()
	return false
end

function modifier_gae_buidhe:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_gae_buidhe:GetTexture()
	return "custom/diarmuid_attribute_golden_rose"
end
