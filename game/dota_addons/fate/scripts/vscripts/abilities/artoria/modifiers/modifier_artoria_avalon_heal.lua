-----------------------------
--   Modifier:  Avalon Heal    --
-----------------------------

modifier_artoria_avalon_heal = class({})

function modifier_artoria_avalon_heal:DeclareFunctions()
	return { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT }
end

function modifier_artoria_avalon_heal:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("hp_regen")
end

function modifier_artoria_avalon_heal:IsHidden()
	return false
end

--[[function modifier_artoria_avalon_heal:GetEffectName()
	return "particles/custom/kinghassan/kinghassan_protection_of_faith/kinghassan_protection_of_faith.vpcf"
end

function modifier_artoria_avalon_heal:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end]]