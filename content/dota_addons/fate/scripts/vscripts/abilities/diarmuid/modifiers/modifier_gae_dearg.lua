modifier_gae_dearg = class({})

if IsServer() then
	function modifier_gae_dearg:OnCreated(args)	
		self:SetStackCount(args.Stacks or 1)		

		local target = self:GetParent()
		local revoke_dur = self:GetStackCount() * 0.5
		--giveUnitDataDrivenModifier(self:GetCaster(), target, "revoked", revoke_dur)
		self:StartIntervalThink(0.033)
	end

	function modifier_gae_dearg:OnRefresh(args)	
		args.Stacks = self:GetStackCount() + 1
		self:OnCreated(args)		
	end

	function modifier_gae_dearg:OnDestroy()
		self:StartIntervalThink(-1)
	end

	function modifier_gae_dearg:OnIntervalThink()	
		local target = self:GetParent()
		local max_mana = target:GetMaxMana() - (325 * self:GetStackCount())

		if target:GetMana() > max_mana then
			target:SetMana(max_mana)
		end	
	end
end

function modifier_gae_dearg:IsHidden()
	return false
end

function modifier_gae_dearg:IsDebuff()
	return true
end

function modifier_gae_dearg:RemoveOnDeath()
	return true
end

function modifier_gae_dearg:IsPurgable()
	return false
end

function modifier_gae_dearg:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_gae_dearg:GetTexture()
	return "custom/diarmuid_attribute_crimson_rose"
end
