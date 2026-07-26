-- lishuwen_raging_dragon_strike_2 — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/li_shuwen/li_shuwen_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lishuwen_raging_dragon_strike_2 = class({})

-- Логика перенесена из scripts/vscripts/lishuwen_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnDragonStrike2Start, OnDragonStrike1ProjectileHit

OnDragonStrike2Start = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	--GrantCosmicOrbitResist(caster)
	caster:SwapAbilities("lishuwen_raging_dragon_strike_2", "lishuwen_raging_dragon_strike_3", false, true) 
	--[[if caster.bIsFuriousChainAcquired then
		keys.Damage = keys.Damage + caster:GetAgility() * ATTR_AGI_RATIO
		GrantFuriousChainBuff(caster) 
	end]]

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
	for k,v in pairs(targets) do
		DoDamage(caster, v, keys.Damage, DAMAGE_TYPE_PHYSICAL, 0, ability, false)
		caster:FindAbilityByName("lishuwen_no_second_strike"):AddShock(v, 5)
		v:AddNewModifier(caster, v, "modifier_stunned", {Duration = keys.StunDuration})
	end
	caster:EmitSound("Hero_Centaur.HoofStomp")
	local risingWindFx = ParticleManager:CreateParticle("particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    local firstStrikeFx = ParticleManager:CreateParticle("particles/custom/lishuwen/lishuwen_second_hit.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl( firstStrikeFx, 0, caster:GetAbsOrigin())
end

OnDragonStrike1ProjectileHit = function(keys)
	local caster = keys.caster
	local target = keys.target 
	table.insert(caster.targetTable,target)
end


function lishuwen_raging_dragon_strike_2:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: lishuwen_ability / OnDragonStrike2Start
	OnDragonStrike2Start({
		caster = caster,
		ability = self,
		target = caster,
		Damage = self:GetSpecialValueFor("second_strike_damage"),
		Radius = self:GetSpecialValueFor("second_strike_radius"),
		StunDuration = self:GetSpecialValueFor("second_strike_stun_duration")
	})
end

function lishuwen_raging_dragon_strike_2:OnProjectileHit(target, location)
	if target == nil then return false end
	local caster = self:GetCaster()
	-- DD RunScript: lishuwen_ability / OnDragonStrike1ProjectileHit
	OnDragonStrike1ProjectileHit({ caster = caster, ability = self, target = target })
	return false
end
