-----------------------------
--    Modifier: Blocker    --
-----------------------------

modifier_relentless_assault_blocker_combo = class({})

function modifier_relentless_assault_blocker_combo:IsHidden()
	return true 
end

function modifier_relentless_assault_blocker_combo:RemoveOnDeath()
	return false
end

function modifier_relentless_assault_blocker_combo:IsDebuff()
	return true 
end

function modifier_relentless_assault_blocker_combo:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end