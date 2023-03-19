-----------------------------
--    Modifier: Charisma    --
-----------------------------

modifier_artoria_charisma = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_artoria_charisma:IsHidden()
	return true
end

function modifier_artoria_charisma:IsDebuff()
	return false
end

function modifier_artoria_charisma:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Aura
function modifier_artoria_charisma:IsAura()
	return true
end

function modifier_artoria_charisma:GetModifierAura()
	return "modifier_artoria_charisma_effect"
end

function modifier_artoria_charisma:GetAuraRadius()
	return self.radius
end

function modifier_artoria_charisma:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_artoria_charisma:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function modifier_artoria_charisma:GetAuraSearchFlags()
	return 0
end

function modifier_artoria_charisma:GetAuraDuration()
	return 0.5
end
--------------------------------------------------------------------------------
-- Initializations
function modifier_artoria_charisma:OnCreated( kv )
	-- references
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" ) -- special value
end

function modifier_artoria_charisma:OnRefresh( kv )
	-- references
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" ) -- special value
end

function modifier_artoria_charisma:OnDestroy( kv )

end