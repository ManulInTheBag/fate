-- Lua port of the old datadriven jeanne_identity_discernment.
-- Logic stays in jeanne_ability.lua (OnIDPing / OnIDRespawn).
require('jeanne_ability')

jeanne_identity_discernment = class({})

LinkLuaModifier("modifier_identity_discernment", "abilities/jeanne/jeanne_identity_discernment", LUA_MODIFIER_MOTION_NONE)

function jeanne_identity_discernment:GetIntrinsicModifierName()
	return "modifier_identity_discernment"
end

function jeanne_identity_discernment:OnSpellStart()
	OnIDPing({ caster = self:GetCaster(), ability = self })
end

-- passive: refunds the cooldown on respawn (once per life mechanic)
modifier_identity_discernment = class({})

function modifier_identity_discernment:IsHidden() return true end
function modifier_identity_discernment:IsPurgable() return false end
function modifier_identity_discernment:RemoveOnDeath() return false end

function modifier_identity_discernment:DeclareFunctions()
	return { MODIFIER_EVENT_ON_RESPAWN }
end

function modifier_identity_discernment:OnRespawn(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	if self:GetAbility():GetLevel() < 1 then return end
	OnIDRespawn({ caster = self:GetParent(), ability = self:GetAbility() })
end
