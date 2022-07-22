modifier_moonwalk_root_cooldown = class({})

function modifier_moonwalk_root_cooldown:IsDebuff()
	return true 
end

function modifier_moonwalk_root_cooldown:RemoveOnDeath()
	return true
end

function modifier_moonwalk_root_cooldown:IsHidden()
	return true
end