-- caster_5th_recall — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_recall = class({})

LinkLuaModifier("modifier_recall", "abilities/medea/caster_5th_recall", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_workshop_recall", "abilities/caster/modifier_workshop_recall", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnTerritoryRecall, OnRecallCanceled

OnTerritoryRecall = function(keys)
	local hCaster = keys.caster
	local hTarget = hCaster:GetOwnerEntity()
    local hAbility = keys.ability

    hTarget:AddNewModifier(hCaster, hAbility, "modifier_workshop_recall", { Duration = 3 })
end

OnRecallCanceled = function(keys)
	local caster = keys.caster
	caster.IsRecallCanceled = true
    local modifier = caster:GetOwnerEntity():FindModifierByName("modifier_recall")
    local pc = modifier.Particle
    ParticleManager:DestroyParticle(pc, false)
    ParticleManager:ReleaseParticleIndex(pc)
    modifier:Destroy()
end


function caster_5th_recall:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: caster_ability / OnTerritoryRecall
	OnTerritoryRecall({ caster = caster, ability = self, target = caster })
end

modifier_recall = class({})


function modifier_recall:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_recall:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "3.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(3.0, true)
	end
end

function modifier_recall:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_recall:OnTakeDamage(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: caster_ability / OnRecallCanceled
	OnRecallCanceled({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker,
		damage = params.damage,
		DamageTaken = params.damage
	})
end
