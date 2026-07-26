-- caster_5th_divine_words — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_divine_words = class({})

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnDWStart

OnDWStart = function(keys)
	local caster = keys.caster
	local targetPoint = keys.ability:GetCursorPosition()
	local rainCount = 0
	local damage = keys.Damage
	if caster.IsHGImproved then damage = damage + caster:GetIntellect() * ATTRIBUTE_HG_INT_MULTIPLIER end

	caster:EmitSound("Medea_Skill_" .. math.random(1,3))

	local bonus_beams = math.floor(caster:GetIntellect() / 40)
	print(bonus_beams)

    Timers:CreateTimer(0.3, function()
    	if rainCount == (3 + bonus_beams) then return end
    	caster:EmitSound("Hero_Luna.LucentBeam.Target")
    	local vecLocation = targetPoint + RandomVector(50)
		local dummy = CreateUnitByName("dummy_unit", vecLocation, false, nil, nil, caster:GetTeamNumber())
		dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		dummy:SetAbsOrigin(vecLocation)
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_luna/luna_lucent_beam.vpcf", PATTACH_ABSORIGIN, dummy)
		ParticleManager:SetParticleControl(particle, 0, vecLocation)
		ParticleManager:SetParticleControl(particle, 1, vecLocation)
		ParticleManager:SetParticleControl(particle, 5, vecLocation)
		ParticleManager:SetParticleControl(particle, 6, vecLocation)
		Timers:CreateTimer(2.0, function()
			dummy:RemoveSelf()
		end)

		local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 

        for k,v in pairs(targets) do
        	DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
        	if v:HasModifier("modifier_c_rule_breaker") then
        		v:AddNewModifier(caster, keys.ability, "modifier_stunned", { Duration = 1.0 })
        	else
        		v:AddNewModifier(caster, keys.ability, "modifier_stunned", { Duration = 0.01 })
        	end
		end
		rainCount = rainCount + 1
      	return 0.35
    end
    )
end


function caster_5th_divine_words:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function caster_5th_divine_words:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: caster_ability / OnDWStart
	OnDWStart({
		caster = caster,
		ability = self,
		target = caster,
		target_points = { point },
		Target = "POINT",
		Radius = self:GetSpecialValueFor("radius"),
		Damage = self:GetSpecialValueFor("damage")
	})
end
