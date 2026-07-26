-- caster_5th_mana_drain — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_mana_drain = class({})

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnManaDrainCast, OnManaDrainStart, OnManaDrainEnd

OnManaDrainCast = function(keys)
	local caster = keys.caster
	local target = keys.target
	--PrintTable(keys)
	--print(direction)
	--local direction = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	--caster:SetForwardVector(direction)
end

OnManaDrainStart = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()
	local ability = keys.ability
	local particleName = "particles/units/heroes/hero_lion/lion_spell_mana_drain.vpcf"



	if target == caster then 
		keys.ability:EndCooldown()
		caster:Interrupt()
		caster:InterruptChannel()
		print("KEK")
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Target_Self")
		return
	end

	ability:SetChanneling(true)
	
	caster.ManaDrainParticle = ParticleManager:CreateParticle(particleName, PATTACH_POINT_FOLLOW, caster)
	caster.ManaDrainTarget = target

	keys.ManaPerSec = keys.ManaPerSec + hero:GetIntellect() * 0.8

	caster.IsManaDrainChanneling = true
	local dist = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
	-- If target is same team, grant mana
	if target:GetTeamNumber() == caster:GetTeamNumber() then
		Timers:CreateTimer(function()  
			dist = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
			if caster.IsManaDrainChanneling == false or caster:GetMana() == 0 or target:GetMana() == target:GetMaxMana() or dist > 2000 or not target:CanEntityBeSeenByMyTeam(caster) then 
				keys.ability:EndChannel(false)
				return 
			end
			caster:Script_ReduceMana(keys.ManaPerSec/4, ability) 
			target:GiveMana(keys.ManaPerSec/4) 
			return 0.25
		end)
		ParticleManager:SetParticleControlEnt(caster.ManaDrainParticle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(caster.ManaDrainParticle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	else
		Timers:CreateTimer(function()  
			dist = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
			if caster.IsManaDrainChanneling == false or target:GetMana() == 0 or caster:GetMana() == caster:GetMaxMana() or dist > 2000 or not target:CanEntityBeSeenByMyTeam(caster) then 
				keys.ability:EndChannel(false)
				return 
			end
			target:Script_ReduceMana(keys.ManaPerSec/4, ability) 
			caster:GiveMana(keys.ManaPerSec/4) 
			return 0.25
		end)
		ParticleManager:SetParticleControlEnt(caster.ManaDrainParticle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(caster.ManaDrainParticle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	end

end

OnManaDrainEnd = function(keys)
	local caster = keys.caster
	caster.IsManaDrainChanneling = false
	ParticleManager:DestroyParticle(caster.ManaDrainParticle,false) 
	caster.ManaDrainTarget:StopSound("Hero_Lion.ManaDrain")
end


function caster_5th_mana_drain:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: caster_ability / OnManaDrainCast
	OnManaDrainCast({ caster = caster, ability = self, target = target })
	return true
end

function caster_5th_mana_drain:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: caster_ability / OnManaDrainStart
	OnManaDrainStart({
		caster = caster,
		ability = self,
		target = target,
		ManaPerSec = self:GetSpecialValueFor("mana_per_second")
	})
	EmitSoundOn("Hero_Lion.ManaDrain", target)
end

function caster_5th_mana_drain:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()
	-- DD RunScript: caster_ability / OnManaDrainEnd
	OnManaDrainEnd({ caster = caster, ability = self })
	if bInterrupted then
		-- DD RunScript: caster_ability / OnManaDrainEnd
		OnManaDrainEnd({ caster = caster, ability = self })
	end
end
