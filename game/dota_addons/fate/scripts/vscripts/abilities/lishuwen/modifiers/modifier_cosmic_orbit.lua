modifier_cosmic_orbit = class({})

function modifier_cosmic_orbit:OnCreated(keys)
	if IsServer() then 
		self.MovespeedPct = 100
		self.DamageType = keys.DamageType

		local caster = self:GetParent()
		self.AttackSpeedBonus = keys.AttackSpeedBonus

		if caster.bIsMartialArtsImproved then 
			self.BonusDamage = keys.BonusDamage * 1.25 
			self:SetStackCount(keys.Stacks + 2)
		else
			self.BonusDamage = keys.BonusDamage
			self:SetStackCount(keys.Stacks)
		end

		self:StartIntervalThink(keys.MovespeedDuration)
	end
end

function modifier_cosmic_orbit:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then
		CustomNetTables:SetTableValue("sync","cosmic_orbit_variables", { movespeed_bonus = self.MovespeedPct })
		return self.MovespeedPct
	elseif IsClient() then
		local cosmic_movespeed = CustomNetTables:GetTableValue("sync","cosmic_orbit_variables").movespeed_bonus
		return cosmic_movespeed
	end
end

function modifier_cosmic_orbit:GetModifierAttackSpeedBonus_Constant()
	if IsServer() then
		CustomNetTables:SetTableValue("sync","cosmic_orbit_variables", { attack_speed = self.AttackSpeedBonus })
		return self.AttackSpeedBonus
	elseif IsClient() then
		local cosmic_attack_speed = CustomNetTables:GetTableValue("sync","cosmic_orbit_variables").attack_speed
		return cosmic_attack_speed
	end
end

function modifier_cosmic_orbit:DeclareFunctions()	
	local funcs =  {--MODIFIER_EVENT_ON_ATTACK_LANDED,
					MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
					MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
	return funcs
end

function modifier_cosmic_orbit:OnIntervalThink()
	self.MovespeedPct = 5

	self:StartIntervalThink(-1)
end

function modifier_cosmic_orbit:OnAttackLanded(keys)
	local caster = self:GetCaster()
	local target = keys.target

	if keys.attacker ~= caster or target == caster then return end

	if IsServer() then
		if self:GetStackCount() > 1 then
			self:SetStackCount(self:GetStackCount() - 1)
		else
			self:Destroy()
		end

		--if caster:HasModifier("modifier_berserk") and self.DamageType ~= DAMAGE_TYPE_PHYSICAL then return end

		DoDamage(caster, target, self.BonusDamage, self.DamageType, 0, self:GetAbility(), false)

		if self.DamageType == DAMAGE_TYPE_MAGICAL then
			self.DamageType = DAMAGE_TYPE_PHYSICAL
		elseif self.DamageType == DAMAGE_TYPE_PHYSICAL then
			self.DamageType = DAMAGE_TYPE_PURE
		else
			self.DamageType = DAMAGE_TYPE_MAGICAL
		end
	end
end

function modifier_cosmic_orbit:IsHidden()
	return false
end

function modifier_cosmic_orbit:IsDebuff()
	return false
end

function modifier_cosmic_orbit:RemoveOnDeath()
	return true
end

function modifier_cosmic_orbit:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_cosmic_orbit:GetTexture()
	return "custom/lishuwen_cosmic_orbit"
end
