-- lishuwen_raging_dragon_strike — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/li_shuwen/li_shuwen_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lishuwen_raging_dragon_strike = class({})

LinkLuaModifier("modifier_raging_dragon_strike_cooldown", "abilities/li_shuwen/lishuwen_raging_dragon_strike", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_raging_dragon_strike_1_slow", "abilities/li_shuwen/lishuwen_raging_dragon_strike", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/lishuwen_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnDragonStrike1Start, OnDragonStrike1ProjectileHit, ApplyMarkOfFatality

OnDragonStrike1Start = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(keys.ability:GetCooldown(1))
	caster:AddNewModifier(caster, ability, "modifier_raging_dragon_strike_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})

	local tigerStrikeAbility = caster:FindAbilityByName("lishuwen_tiger_strike")
	local tigerStrikeCooldown = tigerStrikeAbility:GetCooldown(tigerStrikeAbility:GetLevel())
	tigerStrikeAbility:StartCooldown(tigerStrikeCooldown)

	if IsSpellBlocked(keys.target, caster) then return end

	--GrantCosmicOrbitResist(caster)
	--[[if caster.bIsFuriousChainAcquired then
		keys.Damage = keys.Damage + caster:GetAgility() * ATTR_AGI_RATIO
		GrantFuriousChainBuff(caster) 
		if target:HasModifier("modifier_mark_of_fatality") then
			caster:SetMana(caster:GetMana()+ATTR_MANA_REFUND)
		end
	end]]

	caster.targetTable = {} 
	-- fire linear projectile 
	local projectile = 
	{
		Ability = keys.ability,
        EffectName = "particles/econ/items/lina/lina_head_headflame/lina_spell_dragon_slave_headflame.vpcf",
        iMoveSpeed = 9999,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() - 150, -- give 50 unit buffer 
        fStartRadius = 250,
        fEndRadius = 250,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 0.1,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 9999
	}
	ProjectileManager:CreateLinearProjectile(projectile)

	-- Wait 1 frame to receive target info
	Timers:CreateTimer(0.034, function()
		local startpoint = caster:GetAbsOrigin()
		local endpoint = nil
		for k,v in pairs(caster.targetTable) do
			DoDamage(caster, v, keys.Damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
			caster:FindAbilityByName("lishuwen_no_second_strike"):AddShock(v, 5)
			ApplyMarkOfFatality(caster, v)
			endpoint = v:GetAbsOrigin()
			local trailFx = ParticleManager:CreateParticle( "particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_trail.vpcf", PATTACH_CUSTOMORIGIN, v )
			ParticleManager:SetParticleControl( trailFx, 1, startpoint )
			ParticleManager:SetParticleControl( trailFx, 0, endpoint )
			startpoint = v:GetAbsOrigin()
			v:EmitSound("Hero_EarthShaker.Attack")
		end
		local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
		caster:SetAbsOrigin(target:GetAbsOrigin() - diff*100)
		FindClearSpaceForUnit( caster, caster:GetAbsOrigin(), true )
	end)

	caster:SwapAbilities("lishuwen_raging_dragon_strike", "lishuwen_raging_dragon_strike_2", false, true) 
	caster.bIsCurrentDSCycleFinished = false
	caster.bIsCurrentDSCycleStarted = true


	-- start a timer to revert layout back after set time(4 sec)
    --[[Timers:CreateTimer('raging_dragon_timer', {
        endTime = 4,
        callback = function()
		local currentAbil = caster:GetAbilityByIndex(2)
		if currentAbil:GetAbilityName() ~= "lishuwen_raging_dragon_strike" or not caster.bIsCurrentDSCycleFinished then
			caster:SwapAbilities("lishuwen_tiger_strike",currentAbil:GetAbilityName() , true, false) 
		end
	end})]]

	caster:EmitSound("Hero_EarthShaker.Attack")
    local groundFx = ParticleManager:CreateParticle( "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_f_fallback_low.vpcf", PATTACH_ABSORIGIN, target )
    ParticleManager:SetParticleControl( groundFx, 1, target:GetAbsOrigin())
    local firstStrikeFx = ParticleManager:CreateParticle("particles/custom/lishuwen/lishuwen_first_hit.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl( firstStrikeFx, 0, target:GetAbsOrigin())
end

OnDragonStrike1ProjectileHit = function(keys)
	local caster = keys.caster
	local target = keys.target 
	table.insert(caster.targetTable,target)
end

ApplyMarkOfFatality = function(caster,target)
	local abil = caster:FindAbilityByName("lishuwen_martial_arts")

	SpawnAttachedVisionDummy(caster, target, abil:GetLevelSpecialValueFor("vision_radius", abil:GetLevel()-1 ), abil:GetLevelSpecialValueFor("duration", abil:GetLevel()-1 ), false)

	-- add new stack
	local currentStack = target:GetModifierStackCount("modifier_mark_of_fatality", abil)
	target:RemoveModifierByName("modifier_mark_of_fatality") 
	target:AddNewModifier(caster, abil, "modifier_mark_of_fatality", {}) 
	target:SetModifierStackCount("modifier_mark_of_fatality", abil, currentStack + 1)
end


function lishuwen_raging_dragon_strike:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: lishuwen_ability / OnDragonStrike1Start
	OnDragonStrike1Start({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("first_strike_damage")
	})
end

function lishuwen_raging_dragon_strike:OnProjectileHit(target, location)
	if target == nil then return false end
	local caster = self:GetCaster()
	-- DD RunScript: lishuwen_ability / OnDragonStrike1ProjectileHit
	OnDragonStrike1ProjectileHit({ caster = caster, ability = self, target = target })
	return false
end

modifier_raging_dragon_strike_cooldown = class({})

function modifier_raging_dragon_strike_cooldown:IsDebuff() return true end
function modifier_raging_dragon_strike_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

modifier_raging_dragon_strike_1_slow = class({})

function modifier_raging_dragon_strike_1_slow:IsDebuff() return true end

function modifier_raging_dragon_strike_1_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_raging_dragon_strike_1_slow:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("first_strike_slow")
end
function modifier_raging_dragon_strike_1_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("first_strike_slow")
end

function modifier_raging_dragon_strike_1_slow:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%first_strike_slow_duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("first_strike_slow_duration"), true)
	end
end

function modifier_raging_dragon_strike_1_slow:OnRefresh(kv)
	self:OnCreated(kv)
end
