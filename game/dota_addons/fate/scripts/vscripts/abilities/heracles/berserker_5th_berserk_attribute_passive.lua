-- berserker_5th_berserk_attribute_passive — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/heracles/heracles_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

berserker_5th_berserk_attribute_passive = class({})

LinkLuaModifier("modifier_berserk_eternal_rage_passive", "abilities/heracles/berserker_5th_berserk_attribute_passive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eternal_rage_slow", "abilities/heracles/berserker_5th_berserk_attribute_passive", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/berserker_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnBerserkProc

OnBerserkProc = function(keys)
	local caster = keys.caster
	local target = keys.target
	if caster.IsRageBashOnCooldown == false then
		local radius = 300
		local targets = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		for k,v in pairs(targets) do
	        DoDamage(caster, v, caster:GetAverageTrueAttackDamage(caster)/4, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
	        v:AddNewModifier(caster, keys.ability, "modifier_berserker_clap_slow", {Duration = 1})
		end
		caster.IsRageBashOnCooldown = true
		target:EmitSound("Hero_Centaur.HoofStomp")
		Timers:CreateTimer(1.0, function()
			caster.IsRageBashOnCooldown = false
		end)

		ParticleManager:CreateParticle("particles/custom/berserker/courage/stun_explosion.vpcf", PATTACH_ABSORIGIN, target)
		-- DebugDrawCircle(target:GetAbsOrigin(), Vector(255,0,0), 0.5, radius, true, 0.5)
	end
end


function berserker_5th_berserk_attribute_passive:GetIntrinsicModifierName()
	return "modifier_berserk_eternal_rage_passive"
end

function berserker_5th_berserk_attribute_passive:OnSpellStart()
	local caster = self:GetCaster()
	-- (DD-событие было пустым)
end

modifier_berserk_eternal_rage_passive = class({})


function modifier_berserk_eternal_rage_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_berserk_eternal_rage_passive:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	if RollPercentage(100) then
		-- DD RunScript: berserker_ability / OnBerserkProc
		OnBerserkProc({
			caster = self:GetCaster(),
			ability = self:GetAbility(),
			unit = self:GetParent(),
			attacker = params.attacker,
			target = params.target
		})
	end
end

modifier_eternal_rage_slow = class({})

function modifier_eternal_rage_slow:IsDebuff() return true end

function modifier_eternal_rage_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_eternal_rage_slow:GetModifierMoveSpeedBonus_Percentage()
	return -50
end

-- modifier_berserker_clap_slow ← berserker_ability.lua (монолит удалён)
LinkLuaModifier("modifier_berserker_clap_slow", "abilities/heracles/berserker_5th_berserk_attribute_passive", LUA_MODIFIER_MOTION_NONE)
modifier_berserker_clap_slow = class({})

function modifier_berserker_clap_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_berserker_clap_slow:GetModifierMoveSpeedBonus_Percentage()
	return -50
end

function modifier_berserker_clap_slow:IsHidden()
	return false
end
