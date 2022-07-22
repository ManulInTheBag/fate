modifier_laus_saint_burn = class({})

function modifier_laus_saint_burn:OnCreated(args)
	if IsServer() then
		self.BurnDamage = args.BurnDamage
		self.ThinkInterval = 0.25

		self:StartIntervalThink(0.25)
	end
end

function modifier_laus_saint_burn:OnIntervalThink()
	local target = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()

	DoDamage(caster, target, self.BurnDamage * self.ThinkInterval, DAMAGE_TYPE_MAGICAL, 0, ability, false)
end

function modifier_laus_saint_burn:GetTexture()
	return "custom/nero_laus_saint"
end

function modifier_laus_saint_burn:IsHidden()
	return false 
end

function modifier_laus_saint_burn:RemoveOnDeath()
	return true
end

function modifier_laus_saint_burn:IsDebuff()
	return true 
end

function modifier_laus_saint_burn:GetAttributes()
	return MODIFIER_ATTRIBUTE_NONE
end

function modifier_laus_saint_burn:GetEffectName()
	return "particles/units/heroes/hero_doom_bringer/doom_infernal_blade_debuff.vpcf"
end

function modifier_laus_saint_burn:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end