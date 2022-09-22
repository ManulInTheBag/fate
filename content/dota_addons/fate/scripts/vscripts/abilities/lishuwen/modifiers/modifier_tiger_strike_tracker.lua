modifier_tiger_strike_tracker = class({})

function modifier_tiger_strike_tracker:OnDestroy()
	if IsServer() then
		local ability = self:GetAbility()
		ability:StartCooldown(ability:GetCooldown(ability:GetLevel()))
	end
end

function modifier_tiger_strike_tracker:IsPurgable()
	return false
end

function modifier_tiger_strike_tracker:IsHidden()
	return true
end

function modifier_tiger_strike_tracker:IsDebuff()
	return false
end

function modifier_tiger_strike_tracker:RemoveOnDeath()
	return true
end

function modifier_tiger_strike_tracker:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_tiger_strike_tracker:GetTexture()
	return "custom/lishuwen_fierce_tiger_strike"
end
