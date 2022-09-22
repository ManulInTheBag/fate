modifier_monstrous_strengh_damage_bonus = class({})

function modifier_monstrous_strengh_damage_bonus:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function modifier_monstrous_strengh_damage_bonus:GetModifierPreAttack_BonusDamage()
	local bonus_damage

	if IsServer() then 
		bonus_damage = self:GetParent():GetStrength()
		CustomNetTables:SetTableValue("sync","astolfo_monstrous_str", { bonus_damage = bonus_damage})
	else
		bonus_damage = CustomNetTables:GetTableValue("sync","astolfo_monstrous_str").bonus_damage
	end

	return bonus_damage
end

function modifier_monstrous_strengh_damage_bonus:IsPermanent()
	return true 
end

function modifier_monstrous_strengh_damage_bonus:GetTexture()
	return "custom/astolfo_attribute_monstrous_strength"
end