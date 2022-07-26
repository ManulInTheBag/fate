LinkLuaModifier("modifier_medusa_monstrous_strength","abilities/medusa/medusa_monstrous_strength", LUA_MODIFIER_MOTION_NONE)

medusa_monstrous_strength = class({})

function medusa_monstrous_strength:OnSpellStart()
	local caster = self:GetCaster()

    caster:EmitSound("Hero_Sven.GodsStrength")
    --caster:EmitSound("medusa_monstrous")

	caster:AddNewModifier(caster, self, "modifier_medusa_monstrous_strength", {duration = self:GetSpecialValueFor("duration")})
end

modifier_medusa_monstrous_strength = class({})

function modifier_medusa_monstrous_strength:IsHidden() return false end
function modifier_medusa_monstrous_strength:IsDebuff() return false end

function modifier_medusa_monstrous_strength:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,}
end

function modifier_medusa_monstrous_strength:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("as_bonus")
end

function modifier_medusa_monstrous_strength:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end

	--args.attacker:EmitSound("Astolfo_Sanity_" .. RandomInt(1, 8))
	giveUnitDataDrivenModifier(args.attacker, args.target, "modifier_disarmed", self:GetAbility():GetSpecialValueFor("disarm_duration"))
	DoDamage(args.attacker, args.target, args.target:GetMaxHealth()*self:GetAbility():GetSpecialValueFor("health_percent")/100, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
end

function modifier_medusa_monstrous_strength:GetEffectName()
	return "particles/medusa/medusa_monstrous_ambient.vpcf"
end

function modifier_medusa_monstrous_strength:GetEffectAttachType()
	return PATTACH_CUSTOMORIGIN_FOLLOW
end