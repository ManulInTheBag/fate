-- Nero: Invictus Spiritus (lua port of the old datadriven version).
-- The revive mechanic itself runs off the IsISAcquired flag inside nero's
-- ability scripts; this hidden ability only carries the autoattack sound
-- passive (the old NeroTakeDamage/OnISStart hooks were already empty).
nero_invictus_spiritus = class({})

LinkLuaModifier("nero_autoattack_passive", "abilities/nero/nero_invictus_spiritus", LUA_MODIFIER_MOTION_NONE)

function nero_invictus_spiritus:GetIntrinsicModifierName()
	return "nero_autoattack_passive"
end

function nero_invictus_spiritus:OnSpellStart()
end

-- attack sound on every landed hit
nero_autoattack_passive = class({})

function nero_autoattack_passive:IsHidden() return true end
function nero_autoattack_passive:IsPurgable() return false end

function nero_autoattack_passive:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function nero_autoattack_passive:OnAttackLanded(params)
	if not IsServer() then return end
	if params.attacker ~= self:GetParent() then return end
	if self:GetAbility():GetLevel() < 1 then return end
	self:GetParent():EmitSound("Hero_LegionCommander.Attack")
end
