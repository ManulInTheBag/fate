modifier_nss_shock = class({})

function modifier_nss_shock:OnCreated(keys)
	self.ShockDamage = keys.ShockDamage
end

function modifier_nss_shock:OnDestroy()
	if IsServer() then
		local target = self:GetParent()
		
		target:EmitSound("Hero_Oracle.FalsePromise.Damaged")
		if self:GetCaster():HasModifier("modifier_berserk") then
			DoDamage(self:GetCaster(), target, self.ShockDamage + (self:GetCaster().bIsCirculatoryShockAcquired and 0.2*(target:GetMaxHealth()-target:GetHealth()) or 0), DAMAGE_TYPE_PHYSICAL, 0, self:GetAbility(), false)
		else
			DoDamage(self:GetCaster(), target, self.ShockDamage + (self:GetCaster().bIsCirculatoryShockAcquired and 0.2*(target:GetMaxHealth()-target:GetHealth()) or 0), DAMAGE_TYPE_PURE, 0, self:GetAbility(), false)
		end
	end
end

function modifier_nss_shock:IsHidden()
	return false
end

function modifier_nss_shock:IsDebuff()
	return true
end

function modifier_nss_shock:RemoveOnDeath()
	return true
end

function modifier_nss_shock:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_nss_shock:GetEffectName()
	return ""
end

function modifier_nss_shock:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_nss_shock:GetTexture()
	return "custom/lishuwen_no_second_strike"
end


modifier_nss_shock_no_revoke = class({})

function modifier_nss_shock_no_revoke:OnCreated(keys)
	self.ShockDamage = keys.ShockDamage
end



function modifier_nss_shock_no_revoke:OnDestroy()
	if IsServer() then
		local target = self:GetParent()
		
		target:EmitSound("Hero_Oracle.FalsePromise.Damaged")
		if self:GetCaster():HasModifier("modifier_berserk") then
			DoDamage(self:GetCaster(), target, self.ShockDamage + (self:GetCaster().bIsCirculatoryShockAcquired and 0.2*(target:GetMaxHealth()-target:GetHealth()) or 0), DAMAGE_TYPE_PHYSICAL, 0, self:GetAbility(), false)
		else
			DoDamage(self:GetCaster(), target, self.ShockDamage + (self:GetCaster().bIsCirculatoryShockAcquired and 0.2*(target:GetMaxHealth()-target:GetHealth()) or 0), DAMAGE_TYPE_PURE, 0, self:GetAbility(), false)
		end
	end
end

function modifier_nss_shock_no_revoke:IsHidden()
	return false
end

function modifier_nss_shock_no_revoke:IsDebuff()
	return true
end

function modifier_nss_shock_no_revoke:RemoveOnDeath()
	return true
end

function modifier_nss_shock_no_revoke:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_nss_shock_no_revoke:GetEffectName()
	return ""
end

function modifier_nss_shock_no_revoke:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_nss_shock_no_revoke:GetTexture()
	return "custom/lishuwen_no_second_strike"
end