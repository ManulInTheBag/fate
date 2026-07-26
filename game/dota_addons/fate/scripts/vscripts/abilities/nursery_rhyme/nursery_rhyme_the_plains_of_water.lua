-- nursery_rhyme_the_plains_of_water — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/nursery_rhyme/nursery_rhyme_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

nursery_rhyme_the_plains_of_water = class({})

LinkLuaModifier("modifier_plains_of_water_slow", "abilities/nursery_rhyme/nursery_rhyme_the_plains_of_water", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_plains_of_water_int_debuff", "abilities/nursery_rhyme/nursery_rhyme_the_plains_of_water", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_plains_of_water_int_buff", "abilities/nursery_rhyme/nursery_rhyme_the_plains_of_water", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/nursery_rhyme_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnPlainStart, OnPlainsUpgrade, ChainLightning

OnPlainStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local bounceCount = keys.MaxBounce

	if IsSpellBlocked(keys.target, caster) then return end -- Linken effect checker

	if caster.bIsNightmareAcquired then 
		bounceCount = bounceCount + ability:GetSpecialValueFor("bonus_bounce")
	end

	ChainLightning(keys, caster, target, bounceCount, nil, true)
end

OnPlainsUpgrade = function(keys)
	local caster = keys.caster
	local master_unit = caster.MasterUnit2

	if not master_unit then return end

	local plains = caster:FindAbilityByName("nursery_rhyme_the_plains_of_water")
	local attr = master_unit:FindAbilityByName("nursery_rhyme_attribute_nightmare")

	attr:SetLevel(plains:GetLevel())
end

ChainLightning = function(keys, source, target, count, CC, bIsFirstItrn)
	local caster = keys.caster
	local ability = keys.ability
	local reduction = keys.DmgRed
	local damage = keys.Damage
	if not CC then CC = {} end -- temporal storage for list of CCs to be applied by W	

	if count == 0 then return end
	if IsSpellBlocked(target, caster) then return end

	--if not bIsFirstItrn then
		--damage = keys.Damage * (100+reduction)/100
	--end

	if target:GetName() ~= "dummy_unit" then
		if caster.bIsNightmareAcquired then 
			-- steal int by 2, duration 15 sec
			if target:IsHero() then
				target:AddNewModifier(caster, ability, "modifier_plains_of_water_int_debuff", {})
				caster:AddNewModifier(caster, ability, "modifier_plains_of_water_int_buff", {})
			end
			damage = damage + 1.5 * caster:GetIntellect()
		end
		DoDamage(caster, target, damage, DAMAGE_TYPE_PHYSICAL, 0, ability, false)
		target:AddNewModifier(caster, ability, "modifier_plains_of_water_slow", { duration = 0.35 })
	end

	local lightningFx = ParticleManager:CreateParticle( "particles/custom/nursery_rhyme/plains_of_water.vpcf", PATTACH_CUSTOMORIGIN, nil );
	ParticleManager:SetParticleControlEnt( lightningFx, 0, source, PATTACH_POINT_FOLLOW, "attach_hitloc", source:GetAbsOrigin() + Vector( 0, 0, 96 ), true );
	ParticleManager:SetParticleControlEnt( lightningFx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetOrigin() + Vector(0,0,96), true );
	target:EmitSound("Hero_Winter_Wyvern.SplinterBlast.Target")

	Timers:CreateTimer(0.4, function()
		if IsValidEntity(target) and not target:IsNull() then
			local targets = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, 550, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_ANY_ORDER, false)
			
			for k,v in pairs(targets) do
				if v ~= target and not v:IsMagicImmune() then 
					ChainLightning(keys, target, v, count-1, CC, false)
					return
				end
			end
		
			-- local vPosition = RandomPointInCircle(target:GetAbsOrigin(), 350)
        	-- local hDummy = CreateUnitByName("dummy_unit", vPosition, false, caster, caster, caster:GetTeamNumber())
		    -- hDummy:SetOrigin(vPosition)
		    -- hDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		    -- hDummy:AddNewModifier(caster, ability, "modifier_kill", { Duration = 1.5 })
		    -- ChainLightning(keys, target, hDummy, count-1, CC, false)
		    -- Timers:CreateTimer(3, function()
		    --     if hDummy then hDummy:RemoveSelf() end
		    -- end)			
		end
		
		return
	end)
end


function nursery_rhyme_the_plains_of_water:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: nursery_rhyme_ability / OnPlainStart
	OnPlainStart({
		caster = caster,
		ability = self,
		target = target,
		MaxBounce = self:GetSpecialValueFor("max_bounce"),
		Damage = self:GetSpecialValueFor("damage"),
		DmgRed = self:GetSpecialValueFor("dmg_reduction")
	})
end

function nursery_rhyme_the_plains_of_water:OnUpgrade()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: nursery_rhyme_ability / OnPlainsUpgrade
	OnPlainsUpgrade({ caster = caster, ability = self, target = target })
end

modifier_plains_of_water_slow = class({})

function modifier_plains_of_water_slow:IsHidden() return false end
function modifier_plains_of_water_slow:IsDebuff() return true end
function modifier_plains_of_water_slow:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_plains_of_water_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_plains_of_water_slow:GetModifierMoveSpeedBonus_Percentage()
	return -75
end

function modifier_plains_of_water_slow:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "0.35" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(0.35, true)
	end
end

function modifier_plains_of_water_slow:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_plains_of_water_int_debuff = class({})

function modifier_plains_of_water_int_debuff:IsHidden() return true end
function modifier_plains_of_water_int_debuff:IsDebuff() return true end
function modifier_plains_of_water_int_debuff:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_plains_of_water_int_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function modifier_plains_of_water_int_debuff:GetModifierBonusStats_Intellect()
	return -3
end

function modifier_plains_of_water_int_debuff:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "15" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(15, true)
	end
end

function modifier_plains_of_water_int_debuff:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_plains_of_water_int_buff = class({})

function modifier_plains_of_water_int_buff:IsHidden() return true end
function modifier_plains_of_water_int_buff:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_plains_of_water_int_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function modifier_plains_of_water_int_buff:GetModifierBonusStats_Intellect()
	return 3
end

function modifier_plains_of_water_int_buff:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "15" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(15, true)
	end
end

function modifier_plains_of_water_int_buff:OnRefresh(kv)
	self:OnCreated(kv)
end
