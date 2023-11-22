-----------------------------
--   Blocker    --
-----------------------------

modifier_relentless_assault_blocker = class({})

function modifier_relentless_assault_blocker:IsHidden()
	return false 
end

function modifier_relentless_assault_blocker:RemoveOnDeath()
	return false
end

function modifier_relentless_assault_blocker:IsDebuff()
	return true 
end

function modifier_relentless_assault_blocker:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end