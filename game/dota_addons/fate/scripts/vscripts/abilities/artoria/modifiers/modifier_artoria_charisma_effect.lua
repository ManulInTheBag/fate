-----------------------------
--    Modifier: Charisma Effect    --
-----------------------------

modifier_artoria_charisma_effect = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_artoria_charisma_effect:IsHidden()
	return false
end

function modifier_artoria_charisma_effect:IsDebuff()
	return false
end

function modifier_artoria_charisma_effect:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_artoria_charisma_effect:OnCreated( kv )
	local caster = self:GetCaster()
	
	speed_modifier = self:GetAbility():GetSpecialValueFor( "speed_modifier" )
end

function modifier_artoria_charisma_effect:OnRefresh( kv )
	local caster = self:GetCaster()
	
	speed_modifier = self:GetAbility():GetSpecialValueFor( "speed_modifier" )
end

function modifier_artoria_charisma_effect:OnRemoved()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_artoria_charisma_effect:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return funcs
end

function modifier_artoria_charisma_effect:GetModifierMoveSpeedBonus_Percentage()
	return speed_modifier
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_artoria_charisma_effect:GetEffectName()
	return "particles/items2_fx/rod_of_atos_debuff_glow.vpcf"
end

function modifier_artoria_charisma_effect:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end