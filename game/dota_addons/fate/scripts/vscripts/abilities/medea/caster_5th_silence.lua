-- caster_5th_silence — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_silence = class({})

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnSilenceStart

OnSilenceStart = function(keys)
	local caster = keys.caster
	local targetPoint = keys.ability:GetCursorPosition()
	local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
    for k,v in pairs(targets) do
		v:AddNewModifier(caster, nil, "modifier_silence", {duration=keys.Duration})
		v:AddNewModifier(caster, nil, "modifier_disarmed", {duration=keys.Duration})
	end
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_death_prophet/death_prophet_silence.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0 , targetPoint)
	ParticleManager:SetParticleControl(particle, 1 , Vector(300,0,0))
	ParticleManager:SetParticleControl(particle, 3 , Vector(300,0,0))

	caster:EmitSound("Medea_Skill_" .. math.random(4,6))

	Timers:CreateTimer(2.0, function()
		ParticleManager:DestroyParticle(particle, false)
		return nil
	end)
end


function caster_5th_silence:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function caster_5th_silence:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: caster_ability / OnSilenceStart
	OnSilenceStart({
		caster = caster,
		ability = self,
		target = caster,
		target_points = { point },
		Target = "POINT",
		Radius = self:GetSpecialValueFor("radius"),
		Duration = self:GetSpecialValueFor("duration")
	})
	EmitSoundOn("Hero_DeathProphet.Silence", caster)
end
