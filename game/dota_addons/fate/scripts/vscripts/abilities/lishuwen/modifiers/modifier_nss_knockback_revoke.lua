modifier_nss_knockback_revoke = class({})

function modifier_nss_knockback_revoke:IsHidden()
	return true
end

function modifier_nss_knockback_revoke:IsDebuff()
	return true
end

function modifier_nss_knockback_revoke:RemoveOnDeath()
	return true
end

function modifier_nss_knockback_revoke:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_nss_knockback_revoke:GetTexture()
	return "custom/lishuwen_no_second_strike"
end
