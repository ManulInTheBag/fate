-- avenger_unlimited_remains — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/avenger/avenger_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

avenger_unlimited_remains = class({})

LinkLuaModifier("modifier_avenger_death_checker", "abilities/avenger/avenger_unlimited_remains", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/avenger_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnRemainStart, OnRemainDeath

OnRemainStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:AddNewModifier(caster, ability, "modifier_avenger_death_checker", {})
	local attackmove = {
		UnitIndex = nil,
		OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
		Position = nil
	}
	caster:EmitSound("Hero_Nevermore.Shadowraze")
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin() + caster:GetForwardVector() * 200) 
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
	end)

	for i=1, keys.SpawnNumber do
		local remain = CreateUnitByName("avenger_remain", caster:GetAbsOrigin() + caster:GetForwardVector() * 200, true, nil, nil, caster:GetTeamNumber()) 
		--remain:SetControllableByPlayer(caster:GetPlayerID(), true)
		remain:SetOwner(caster:GetPlayerOwner():GetAssignedHero())
		LevelAllAbility(remain)
		FindClearSpaceForUnit(remain, remain:GetAbsOrigin(), true)
		remain:FindAbilityByName("avenger_remain_passive"):SetLevel(keys.ability:GetLevel())
		remain:AddNewModifier(caster, nil, "modifier_kill", {duration = 24})
		Timers:CreateTimer(3.0, function() 
			if not remain:IsAlive() then return end
			attackmove.UnitIndex = remain:entindex()
			attackmove.Position = remain:GetOrigin() + RandomVector(1000) 
			ExecuteOrderFromTable(attackmove)
			return 3.0
		end)
	end


end

OnRemainDeath = function(keys)
	local caster = keys.caster
	local summons = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 20000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	for k,v in pairs(summons) do
		--print("Found unit " .. v:GetUnitName())
		if v:GetUnitName() == "avenger_remain" then
			v:ForceKill(true) 
		end
	end
end


function avenger_unlimited_remains:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: avenger_ability / OnRemainStart
	OnRemainStart({
		caster = caster,
		ability = self,
		target = caster,
		SpawnNumber = self:GetSpecialValueFor("spawn_number"),
		Period = self:GetSpecialValueFor("multiply_period")
	})
	caster:AddNewModifier(caster, self, "modifier_avenger_death_checker", {})
end

modifier_avenger_death_checker = class({})

function modifier_avenger_death_checker:IsHidden() return true end

function modifier_avenger_death_checker:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_avenger_death_checker:OnDeath(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: avenger_ability / OnRemainDeath
	OnRemainDeath({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker
	})
end
