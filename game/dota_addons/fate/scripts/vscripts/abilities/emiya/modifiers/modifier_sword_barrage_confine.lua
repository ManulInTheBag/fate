modifier_sword_barrage_confine = class({})

function modifier_sword_barrage_confine:IsHidden()
	return true
end

function modifier_sword_barrage_confine:IsDebuff()
	return true 
end

function modifier_sword_barrage_confine:RemoveOnDeath()
	return true
end

