-- berserker_5th_reincarnation — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/heracles/heracles_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

berserker_5th_reincarnation = class({})

LinkLuaModifier("modifier_reincarnation", "abilities/heracles/berserker_5th_reincarnation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_reincarnation_stack", "abilities/heracles/berserker_5th_reincarnation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_reincarnation_progress", "abilities/heracles/berserker_5th_reincarnation", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/berserker_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnReincarnationBuffEnded

OnReincarnationBuffEnded = function(keys)
	ParticleManager:DestroyParticle(keys.caster.reincarnation_particle, false)
	keys.caster.reincarnation_particle = nil
end


function berserker_5th_reincarnation:GetIntrinsicModifierName()
	return "modifier_reincarnation"
end

function berserker_5th_reincarnation:OnSpellStart()
	local caster = self:GetCaster()
	-- (DD-событие было пустым)
end

modifier_reincarnation = class({})

function modifier_reincarnation:IsHidden() return true end

function modifier_reincarnation:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_reincarnation:OnTakeDamage(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: berserker_ability / OnReincarnationDamageTaken
	OnReincarnationDamageTaken({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker,
		damage = params.damage,
		DamageTaken = params.damage,
		DamageTaken = self:GetAbility():GetSpecialValueFor("attack_damage")
	})
end

modifier_reincarnation_stack = class({})

function modifier_reincarnation_stack:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_reincarnation_stack:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function modifier_reincarnation_stack:GetModifierConstantHealthRegen()
	return 18
end

function modifier_reincarnation_stack:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "10" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(10, true)
	end
end

function modifier_reincarnation_stack:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_reincarnation_stack:OnDestroy()
	if not IsServer() then return end
	-- DD RunScript: berserker_ability / OnReincarnationBuffEnded
	OnReincarnationBuffEnded({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

modifier_reincarnation_progress = class({})

function modifier_reincarnation_progress:IsHidden() return true end
function modifier_reincarnation_progress:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end
