-----------------------------
--    Modifier: Artoria Instinct    --
-----------------------------

modifier_artoria_instinct = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_artoria_instinct:IsHidden()
	return false
end

function modifier_artoria_instinct:IsDebuff()
	return false
end

function modifier_artoria_instinct:IsPurgable()
	return false
end

function modifier_artoria_instinct:RemoveOnDeath()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_artoria_instinct:OnCreated( kv )
	local caster = self:GetCaster()
	
	evasion_rate = self:GetAbility():GetSpecialValueFor( "evasion_rate" )
end

function modifier_artoria_instinct:OnRefresh( kv )
	local caster = self:GetCaster()
	
	evasion_rate = self:GetAbility():GetSpecialValueFor( "evasion_rate" )
end

function modifier_artoria_instinct:OnRemoved()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_artoria_instinct:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_EVASION_CONSTANT,
	}

	return funcs
end

function modifier_artoria_instinct:GetModifierEvasion_Constant()
	return evasion_rate
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_artoria_instinct:GetEffectName()
	return ""
end

function modifier_artoria_instinct:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end