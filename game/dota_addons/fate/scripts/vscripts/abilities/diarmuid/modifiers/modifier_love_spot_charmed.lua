modifier_love_spot_charmed = class({})

function modifier_love_spot_charmed:RemoveOnDeath()
	return true 
end

function modifier_love_spot_charmed:IsHidden()
	return true
end

function modifier_love_spot_charmed:IsDebuff()
	return true
end