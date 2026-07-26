-- avenger_autoattack — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/avenger/avenger_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

avenger_autoattack = class({})

LinkLuaModifier("avenger_autoattack_passive", "abilities/avenger/avenger_autoattack", LUA_MODIFIER_MOTION_NONE)

function avenger_autoattack:GetIntrinsicModifierName()
	return "avenger_autoattack_passive"
end

avenger_autoattack_passive = class({})

function avenger_autoattack_passive:IsHidden() return true end

function avenger_autoattack_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function avenger_autoattack_passive:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	EmitSoundOn("Hero_PhantomAssassin.Attack", self:GetCaster())
end
