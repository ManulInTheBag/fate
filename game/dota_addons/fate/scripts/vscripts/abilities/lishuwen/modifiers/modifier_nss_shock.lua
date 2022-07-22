modifier_nss_shock = class({})

function modifier_nss_shock:OnCreated(keys)
	self.ShockDamage = keys.ShockDamage
end

function modifier_nss_shock:GetModifierPreAttack_BonusDamage()
	return 0
end

function modifier_nss_shock:DeclareFunctions()
	local funcs = {	MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
	return funcs
end

function modifier_nss_shock:OnDestroy()
	if IsServer() then
		local target = self:GetParent()

		target:EmitSound("Hero_Oracle.FalsePromise.Damaged")
		DoDamage(self:GetCaster(), target, self.ShockDamage, DAMAGE_TYPE_PURE, 0, self:GetAbility(), false)
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