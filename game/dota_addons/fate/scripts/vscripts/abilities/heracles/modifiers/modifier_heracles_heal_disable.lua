modifier_heracles_heal_disable = class({})


function modifier_heracles_heal_disable:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE}
end

function modifier_heracles_heal_disable:GetModifierHealAmplify_PercentageTarget()
	return -100
end

function modifier_heracles_heal_disable:GetModifierHPRegenAmplify_Percentage()
	return -100
end


function modifier_heracles_heal_disable:RemoveOnDeath()
	return true
end

function modifier_heracles_heal_disable:IsPermanent()
	return false 
end

function modifier_heracles_heal_disable:IsDebuff()
	return true
end

function modifier_heracles_heal_disable:GetEffectName()
	return "particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_trail_circle.vpcf"
end

function modifier_heracles_heal_disable:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end