-- caster_5th_territory_explosion — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_territory_explosion = class({})

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnTerritoryExplosionCastStart, OnTerritoryExplosion

OnTerritoryExplosionCastStart = function(keys)
	local caster = keys.caster
	local target = keys.target

	local fx = ParticleManager:CreateParticle("particles/custom/caster/workshop_explosion.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(fx, 0, caster:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex( fx )
end

OnTerritoryExplosion = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 1.0)



	Timers:CreateTimer(1, function()
		if caster:IsAlive() then
			caster:EmitSound("Hero_ObsidianDestroyer.SanityEclipse.Cast")
			local damage = 300 + caster:GetMana() + hero:GetIntellect() * 8 
			if hero.IsTerritoryImproved then damage = damage + 300 end
			local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			for k,v in pairs(targets) do
				local distance = (caster:GetAbsOrigin() - v:GetAbsOrigin()):Length2D()
				local multiplier = 1
				if distance > 300 then
					-- 2/3 damage at max distance
					multiplier = 1 - (distance - 300) / 700 / 3
				end
				DoDamage(hero, v, damage * multiplier, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
			end
			-- particle
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_sanity_eclipse_area.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin()) -- height of the bolt
			ParticleManager:SetParticleControl(particle, 1, Vector(1000, 0, 0)) -- height of the bolt
			ParticleManager:SetParticleShouldCheckFoW(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
			caster:Execute(keys.ability, caster)
		end
		return
	end)
end


function caster_5th_territory_explosion:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	-- DD RunScript: caster_ability / OnTerritoryExplosionCastStart
	OnTerritoryExplosionCastStart({ caster = caster, ability = self, target = caster })
	return true
end

function caster_5th_territory_explosion:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: caster_ability / OnTerritoryExplosion
	OnTerritoryExplosion({ caster = caster, ability = self, target = caster })
end
