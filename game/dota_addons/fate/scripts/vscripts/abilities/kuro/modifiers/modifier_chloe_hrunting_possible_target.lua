modifier_chloe_hrunting_possible_target = class({})

function modifier_chloe_hrunting_possible_target:IsHidden() return true end

function modifier_chloe_hrunting_possible_target:IsDebuff() return true end

modifier_hrunting_artillery_launch = class({})

function modifier_hrunting_artillery_launch:IsHidden() return true end

function modifier_hrunting_artillery_launch:IsDebuff() return true end

modifier_combo_window = class({})

function modifier_combo_window:IsHidden() return true end

function modifier_combo_window:IsDebuff() return false end

--[[function modifier_combo_window:OnDestroy()
	if self:GetParent():GetAbilityByIndex(3):GetName() == "kuro_hrunting" then
		self:GetParent():SwapAbilities("kuro_clairvoyance", "kuro_hrunting", true, false)
	end
end]]

modifier_hrunting_cooldown = class({})

function modifier_hrunting_cooldown:GetTexture()
	return "custom/kuro/chloe_hrunting"
end

function modifier_hrunting_cooldown:IsHidden()
	return false 
end

function modifier_hrunting_cooldown:RemoveOnDeath()
	return false
end

function modifier_hrunting_cooldown:IsDebuff()
	return true 
end

function modifier_hrunting_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end