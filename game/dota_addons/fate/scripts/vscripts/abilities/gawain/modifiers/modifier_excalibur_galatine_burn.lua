modifier_excalibur_galatine_burn = class({})

function modifier_excalibur_galatine_burn:GetEffectName()
	return "particles/units/heroes/hero_doom_bringer/doom_infernal_blade_debuff.vpcf"
end
function modifier_excalibur_galatine_burn:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
function modifier_excalibur_galatine_burn:IsDebuff() return true end
function modifier_excalibur_galatine_burn:OnCreated()
	self:StartIntervalThink(0.25)
end
function modifier_excalibur_galatine_burn:OnIntervalThink()
	local caster = self:GetCaster()
	local target = self:GetParent()
	local damage = self:GetAbility():GetSpecialValueFor("dot_damage")

	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
end