modifier_pc_nss_cooldown_recovery = class({})

function modifier_pc_nss_cooldown_recovery:OnCreated(table)
	if IsServer() then
		self:StartIntervalThink(1)
	end
end

function modifier_pc_nss_cooldown_recovery:OnIntervalThink()
	local caster = self:GetCaster()

	if caster == nil then return end

	local ability = caster:FindAbilityByName("lishuwen_no_second_strike")
	local cooldown = ability:GetCooldownTimeRemaining()

	if ability:IsCooldownReady() then
		return
	else
		ability:EndCooldown()
		ability:StartCooldown(cooldown - 1)
	end
end

function modifier_pc_nss_cooldown_recovery:IsHidden()
	return true
end

function modifier_pc_nss_cooldown_recovery:IsDebuff()
	return false
end

function modifier_pc_nss_cooldown_recovery:RemoveOnDeath()
	return true
end

function modifier_pc_nss_cooldown_recovery:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end