modifier_pc_bonus_damage = class({})

function modifier_pc_bonus_damage:OnCreated(keys)
	local caster = self:GetParent()
	if IsServer() then
		if caster.bIsMartialArtsImproved then 
			self.BonusDamage = keys.BonusDamage * 1.1 
			self:SetStackCount(keys.AttackCount + 1)
		else
			self.BonusDamage = keys.BonusDamage
			self:SetStackCount(keys.AttackCount)
		end
	end
end

function modifier_pc_bonus_damage:GetModifierMoveSpeed_Absolute()
	return 550
end

function modifier_pc_bonus_damage:DeclareFunctions()
	local funcs = {	--MODIFIER_EVENT_ON_ATTACK_LANDED,
					MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE }
	return funcs
end

function modifier_pc_bonus_damage:OnAttackLanded(keys)
	if IsServer() then
		if keys.attacker ~= self:GetParent() then return end
		local caster = self:GetParent()
		local target = keys.target

		if self:GetStackCount() > 1 then
			self:SetStackCount(self:GetStackCount() - 1)
		else
			self:Destroy()
		end
		--if caster:HasModifier("modifier_berserk") then return end
		DoDamage(caster, target, self.BonusDamage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
	end
end


function modifier_pc_bonus_damage:IsHidden()
	return false
end

function modifier_pc_bonus_damage:IsDebuff()
	return false
end

function modifier_pc_bonus_damage:RemoveOnDeath()
	return true
end

function modifier_pc_bonus_damage:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_pc_bonus_damage:GetEffectName()
	return "particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf"
end

function modifier_pc_bonus_damage:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end