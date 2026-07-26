-- avenger_remain_passive — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/avenger/avenger_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

avenger_remain_passive = class({})

LinkLuaModifier("avenger_remain_self_destruct", "abilities/avenger/avenger_remain_passive", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/avenger_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnRemainExplode

OnRemainExplode = function(keys)
	local caster = keys.caster
	local target = keys.target
	if (target:GetName() == "npc_dota_ward_base") or caster.IsDamageDone then
		return
	end
	caster.IsDamageDone = true
	caster:EmitSound("Hero_Broodmother.SpawnSpiderlingsImpact")
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, 250
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
         DoDamage(caster, v, keys.Damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
    end
    caster:ForceKill(true)
end


function avenger_remain_passive:GetIntrinsicModifierName()
	return "avenger_remain_self_destruct"
end

avenger_remain_self_destruct = class({})

function avenger_remain_self_destruct:IsHidden() return true end

function avenger_remain_self_destruct:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_START,
	}
end

function avenger_remain_self_destruct:OnCreated(kv)
	if not IsServer() then return end
	-- (DD-событие было пустым)
end

function avenger_remain_self_destruct:OnRefresh(kv)
	self:OnCreated(kv)
end

function avenger_remain_self_destruct:OnAttackStart(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf", PATTACH_CUSTOMORIGIN, params.target)
	ParticleManager:SetParticleControlEnt(fx, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "follow_origin", self:GetCaster():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, self:GetCaster(), PATTACH_POINT_FOLLOW, "follow_origin", self:GetCaster():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 2, self:GetCaster(), PATTACH_POINT_FOLLOW, "follow_origin", self:GetCaster():GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
	-- DD RunScript: avenger_ability / OnRemainExplode
	OnRemainExplode({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		attacker = params.attacker,
		target = params.target,
		Damage = self:GetAbility():GetSpecialValueFor("damage"),
		Period = self:GetAbility():GetSpecialValueFor("multiply_period")
	})
end
