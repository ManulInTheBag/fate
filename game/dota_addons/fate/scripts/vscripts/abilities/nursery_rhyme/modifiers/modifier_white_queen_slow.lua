modifier_white_queen_slow = class({})

function modifier_white_queen_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_white_queen_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow_pct")
end

function modifier_white_queen_slow:IsDebuff()
	return true 
end

function modifier_white_queen_slow:GetTexture()
	return "custom/nursery_rhyme_white_queens_enigma"
end