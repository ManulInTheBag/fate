modifier_mtr_night_checker_tick = class({})
function modifier_mtr_night_checker_tick:IsHidden()
	return false
end

function modifier_mtr_night_checker_tick:IsDebuff()
	return false
end
function modifier_mtr_night_checker_tick:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_mtr_night_checker_tick:GetTexture()
	return "custom/jtr/maria_the_ripper_sequence"
end