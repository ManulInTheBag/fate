-- false_assassin_minds_eye — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/sasaki/sasaki_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

false_assassin_minds_eye = class({})

LinkLuaModifier("modifier_minds_eye", "abilities/sasaki/false_assassin_minds_eye", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_minds_eye_crit", "abilities/sasaki/false_assassin_minds_eye", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_minds_eye_crit_hit", "abilities/sasaki/false_assassin_minds_eye", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/fa_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnMindsEyeAttacked, OnFACrit

OnMindsEyeAttacked = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ratio = keys.Ratio
	local revokedRatio = keys.RatioRevoked
	
	if caster:GetAttackTarget() ~= nil then
		if caster:GetAttackTarget():GetName() == "npc_dota_ward_base" then
			print("Attacking Ward")
			return
		end
	end

	if not caster:HasModifier("modifier_exhausted") then
		caster:GiveMana(10)
	end

	if IsRevoked(target) then
		DoDamage(caster, target, caster:GetAgility() * revokedRatio , DAMAGE_TYPE_PURE, 0, keys.ability, false)
	else
		DoDamage(caster, target, caster:GetAgility() * ratio , DAMAGE_TYPE_PURE, 0, keys.ability, false)
	end
end

OnFACrit = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:AddNewModifier(caster, ability, "modifier_minds_eye_crit_hit", {})
end


function false_assassin_minds_eye:GetIntrinsicModifierName()
	return "modifier_minds_eye"
end

function false_assassin_minds_eye:OnSpellStart()
	local caster = self:GetCaster()
	-- (DD-событие было пустым)
end

modifier_minds_eye = class({})

function modifier_minds_eye:IsHidden() return true end

function modifier_minds_eye:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_minds_eye:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	-- DD RunScript: fa_ability / OnMindsEyeAttacked
	OnMindsEyeAttacked({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		attacker = params.attacker,
		target = params.target,
		Ratio = self:GetAbility():GetSpecialValueFor("agi_ratio"),
		RatioRevoked = self:GetAbility():GetSpecialValueFor("agi_ratio_revoked")
	})
end

modifier_minds_eye_crit = class({})

function modifier_minds_eye_crit:IsHidden() return false end

function modifier_minds_eye_crit:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_START,
	}
end

function modifier_minds_eye_crit:OnAttackStart(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	self:GetCaster():RemoveModifierByName("modifier_minds_eye_crit_hit")
	if RollPercentage(self:GetAbility():GetSpecialValueFor("critical_rate")) then
		-- DD RunScript: fa_ability / OnFACrit
		OnFACrit({
			caster = self:GetCaster(),
			ability = self:GetAbility(),
			unit = self:GetParent(),
			attacker = params.attacker,
			target = params.target
		})
	end
end

modifier_minds_eye_crit_hit = class({})

function modifier_minds_eye_crit_hit:IsHidden() return true end

function modifier_minds_eye_crit_hit:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_minds_eye_crit_hit:GetModifierPreAttack_CriticalStrike()
	return self:GetAbility():GetSpecialValueFor("critical_damage")
end

function modifier_minds_eye_crit_hit:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/jugg_crit_blur_impact.vpcf", PATTACH_POINT, params.target)
	ParticleManager:ReleaseParticleIndex(fx)
	self:GetCaster():RemoveModifierByName("modifier_minds_eye_crit_hit")
end
