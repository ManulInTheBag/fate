-- avenger_tawrich_zarich — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/avenger/avenger_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

avenger_tawrich_zarich = class({})

LinkLuaModifier("modifier_tawrich_slow", "abilities/avenger/avenger_tawrich_zarich", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/avenger_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnTZStart, OnTZLevelUp

OnTZStart = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local TZCount = 0
	if IsSpellBlocked(keys.target, caster) then return end	



	--caster:AddNewModifier(caster, ability, "modifier_tawrich_crit", { Duration = 1})

	Timers:CreateTimer(0.033, function() 
		if TZCount == 6 then 
			--caster:RemoveModifierByName("modifier_tawrich_crit")
			return 
		end
		caster:EmitSound("Hero_BountyHunter.Jinada")
		local particle = ParticleManager:CreateParticle("particles/econ/courier/courier_mechjaw/mechjaw_death_sparks.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin()) 
		Timers:CreateTimer( 2.0, function()
			ParticleManager:DestroyParticle( particle, false )
			ParticleManager:ReleaseParticleIndex( particle )
		end)

		--caster:PerformAttack(target, true, true, true, true, false, false, false)
		local damage = keys.Damage --+ caster:GetAverageTrueAttackDamage(target) * 0.5
		DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
		-- if caster:HasModifier("modifier_murderous_instinct") then
		-- 	DoDamage(caster, target, caster:FindAbilityByName("avenger_murderous_instinct"):GetSpecialValueFor("on_attack_damage"), DAMAGE_TYPE_MAGICAL, 0, caster:FindAbilityByName("avenger_murderous_instinct"), false)
		-- end
		--[[if caster:HasModifier("modifier_murderous_instinct") and RandomInt(1, 100) < 35 then
			DoDamage(caster, target, damage * 2, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
		else
			DoDamage(caster, target, damage, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
		end]]

		
		caster:PerformAttack(target, true, false, true, true, false, true, true)
		TZCount = TZCount + 1
		

		return 0.10
	end)

	if not target:IsMagicImmune() then
        giveUnitDataDrivenModifier(caster, target, "disarmed", keys.Duration)
        giveUnitDataDrivenModifier(caster, target, "silenced", keys.Duration)
    end

    if not IsImmuneToSlow(keys.target) and not target:IsMagicImmune() then 
    	target:AddNewModifier(caster, keys.ability, "modifier_tawrich_slow", {}) 
    end
end

OnTZLevelUp = function(keys)
	local caster = keys.caster
	caster:FindAbilityByName("avenger_vengeance_mark"):SetLevel(keys.ability:GetLevel())
end


function avenger_tawrich_zarich:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: avenger_ability / OnTZStart
	OnTZStart({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("damage_per_attack"),
		Duration = self:GetSpecialValueFor("duration")
	})
end

function avenger_tawrich_zarich:OnUpgrade()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: avenger_ability / OnTZLevelUp
	OnTZLevelUp({ caster = caster, ability = self, target = target })
end

modifier_tawrich_slow = class({})

function modifier_tawrich_slow:IsDebuff() return true end

function modifier_tawrich_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_tawrich_slow:GetModifierMoveSpeedBonus_Percentage()
	return -50
end

function modifier_tawrich_slow:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%slow_duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("slow_duration"), true)
	end
end

function modifier_tawrich_slow:OnRefresh(kv)
	self:OnCreated(kv)
end
