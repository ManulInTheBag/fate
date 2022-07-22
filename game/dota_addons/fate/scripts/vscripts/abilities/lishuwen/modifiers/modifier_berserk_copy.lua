modifier_berserk = class({})

function modifier_berserk:OnCreated(keys)
	self.State = { [MODIFIER_STATE_ROOTED] = false, 
					[MODIFIER_STATE_DISARMED] = false,
					[MODIFIER_STATE_SILENCED] = false,
					[MODIFIER_STATE_MUTED] = false,
					[MODIFIER_STATE_STUNNED] = false,
				} 

	if keys.CCImmuneDuration > 0 then
		self:StartIntervalThink(keys.CCImmuneDuration)
	end
end

function modifier_berserk:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_berserk:CheckState()
	return self.State
end

function modifier_berserk:OnIntervalThink()
	self.State = {}
	self:StartIntervalThink(-1)
end

function modifier_berserk:DeclareFunctions()
  local funcs = {}
  --{ MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
  return funcs
end

--[[function modifier_berserk:GetModifierPreAttack_BonusDamage()
	if IsServer() then
		local ability = self:GetAbility()
		local parent = self:GetParent()
		local dmg_ratio = ability:GetSpecialValueFor("dmg_ratio")
		local parent_strength = parent:GetStrength()
		--local berserk_damage_bonus = dmg_ratio * parent_strength
		CustomNetTables:SetTableValue("sync","berserk_damage_bonus", {damage = parent_strength})
	 	return berserk_damage_bonus
 	end
 	if IsClient() then
 		local berserk_damage_bonus = CustomNetTables:GetTableValue("sync","berserk_damage_bonus").damage
 		return berserk_damage_bonus
 	end
end]]

function modifier_berserk:GetEffectName()
	return "particles/units/heroes/hero_spectre/spectre_ambient.vpcf"
end

function modifier_berserk:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_berserk:IsHidden()
	return false
end

function modifier_berserk:IsDebuff()
	return false
end

function modifier_berserk:RemoveOnDeath()
	return true
end

function modifier_berserk:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_berserk:GetTexture()
	return "custom/lishuwen_berserk"
end
