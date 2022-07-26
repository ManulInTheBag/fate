modifier_tres_target_marker = class({})

function modifier_tres_target_marker:IsHidden()
	return true
end

function modifier_tres_target_marker:GetEffectName()
	return "particles/units/heroes/hero_ember_spirit/ember_spirit_sleight_of_fist_targetted_marker.vpcf"
end

function modifier_tres_target_marker:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_tres_target_marker:RemoveOnDeath()
	return true
end