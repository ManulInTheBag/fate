modifier_cc_immune = class({})

function modifier_cc_immune:IsHidden() return false end
function modifier_cc_immune:IsDebuff() return false end



function modifier_cc_immune:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end