modifier_nss_shock = class({})

function modifier_nss_shock:OnCreated(keys)
	self.ShockDamage = keys.ShockDamage
	self.StackDamage = keys.StackDamage
end

function modifier_nss_shock:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetParent()
		local damage = self.ShockDamage + (caster.bIsCirculatoryShockAcquired and 0.2*(target:GetMaxHealth()-target:GetHealth()) or 0)
		local damageType = caster:HasModifier("modifier_berserk") and DAMAGE_TYPE_PHYSICAL or DAMAGE_TYPE_PURE

		target:EmitSound("Hero_Oracle.FalsePromise.Damaged")
		DoDamageThroughIntervention(caster, target, damage, self.StackDamage, damageType, 0, self:GetAbility(), false)
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
	self.StackDamage = keys.StackDamage
end



function modifier_nss_shock_no_revoke:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetParent()
		local damage = self.ShockDamage + (caster.bIsCirculatoryShockAcquired and 0.2*(target:GetMaxHealth()-target:GetHealth()) or 0)
		local damageType = caster:HasModifier("modifier_berserk") and DAMAGE_TYPE_PHYSICAL or DAMAGE_TYPE_PURE

		target:EmitSound("Hero_Oracle.FalsePromise.Damaged")
		DoDamageThroughIntervention(caster, target, damage, self.StackDamage, damageType, 0, self:GetAbility(), false)
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