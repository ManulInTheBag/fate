-- astolfo_down_with_a_touch — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/astolfo/astolfo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

astolfo_down_with_a_touch = class({})

LinkLuaModifier("modifier_down_with_a_touch_slow", "abilities/astolfo/astolfo_down_with_a_touch", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_down_with_a_touch_slow_2", "abilities/astolfo/astolfo_down_with_a_touch", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_down_with_a_touch_slow_3", "abilities/astolfo/astolfo_down_with_a_touch", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/astolfo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnDownStart, OnDownHit, OnDownSlowTier1End, OnDownSlowTier2End

OnDownStart = function(keys)
	local caster = keys.caster
	local targetPoint = keys.ability:GetCursorPosition()
	local ability = keys.ability
	local damage = keys.Damage
	local range = keys.Range
	local attackCount = keys.AttackCount
	local counter = 1
	local nHits = 4
	local vector = (targetPoint - caster:GetAbsOrigin()):Normalized()
	vector.z = 0
	caster:FaceTowards(targetPoint)
	caster:SetForwardVector(vector)
	if caster:HasModifier("modifier_hippogriff_ride_ascended") then 
		ability:EndCooldown()
		caster:GiveMana(ability:GetManaCost(1)) 
		return 
	end 
	range = 500
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.5)
	--giveUnitDataDrivenModifier(caster, caster, "zero_attack_damage", 0.5)
	--giveUnitDataDrivenModifier(caster, caster, "modifier_astolfo_disable_mstrength", 0.5)
	-- Attachments:AttachProp(caster, "attach_sword", "models/astolfo/astolfo_sword.vmdl")
	Timers:CreateTimer(function()
		if counter > nHits then 
			-- local prop = Attachments:GetCurrentAttachment(caster, "attach_sword")
			-- if not prop:IsNull() then prop:RemoveSelf() end
			return
		 end
		local forwardVec = RotatePosition(Vector(0,0,0), QAngle(0,RandomFloat(12, -12),0), vector)
		local spearProjectile = 
		{
			Ability = ability,
	        EffectName = "particles/custom/astolfo/astolfo_down_with_a_touch_projectile.vpcf",
	        iMoveSpeed = range * 5,
	        vSpawnOrigin = caster:GetOrigin(),
	        fDistance = range - 100,
	        fStartRadius = 200,
	        fEndRadius = 200,
	        Source = caster,
	        bHasFrontalCone = true,
	        bReplaceExisting = true,
	        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
	        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
	        fExpireTime = GameRules:GetGameTime() + 2.0,
			bDeleteOnHit = false,
			vVelocity = forwardVec * range * 5
		}
		local projectile = ProjectileManager:CreateLinearProjectile(spearProjectile)
		--[[if caster:HasModifier("modifier_astolfo_monstrous_strength") and caster.bIsSanityAcquired then
			DoDamage(caster, caster, 4*caster:GetHealth()/100 , DAMAGE_TYPE_MAGICAL, 0, ability, false)
		end]]
		StartAnimation(caster, {duration=0.15, activity=ACT_DOTA_ATTACK, rate=4.0})
		caster:EmitSound("Hero_Sniper.AssassinateDamage")
		counter = counter + 1
		return 0.12
	end)

end

OnDownHit = function(keys)
	local caster = keys.caster
	local target = keys.target
	local damage = keys.Damage
	local ability = keys.ability
	local lockDuration = keys.LockDuration
	DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, ability, false)
	giveUnitDataDrivenModifier(caster, target, "locked", lockDuration)
	if not IsImmuneToSlow(target) then
		target:AddNewModifier(caster, ability, "modifier_down_with_a_touch_slow", {})
	end

	if caster.bIsMStrengthAcquired then
		--caster:PerformAttack(target, true, true, true, true, false)
		caster:PerformAttack( target, true, true, true, true, false, true, false )
	end

	if caster.bIsSanityAcquired then
		giveUnitDataDrivenModifier(caster, target, "disarmed", lockDuration)
	end
end

OnDownSlowTier1End = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	if not IsImmuneToSlow(target) then
		target:AddNewModifier(caster, ability, "modifier_down_with_a_touch_slow_2", {})
	end
end

OnDownSlowTier2End = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	if not IsImmuneToSlow(target) then
		target:AddNewModifier(caster, ability, "modifier_down_with_a_touch_slow_3", {})
	end
end


function astolfo_down_with_a_touch:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: astolfo_ability / OnDownStart
	-- TODO(dd2lua): функция читает keys.Damage — проверить
	OnDownStart({
		caster = caster,
		ability = self,
		target = caster,
		target_points = { point },
		Target = "POINT",
		Range = self:GetSpecialValueFor("range"),
		AttackCount = self:GetSpecialValueFor("attack_amount")
	})
end

function astolfo_down_with_a_touch:OnProjectileHit(target, location)
	if target == nil then return false end
	local caster = self:GetCaster()
	-- DD RunScript: astolfo_ability / OnDownHit
	OnDownHit({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("damage"),
		LockDuration = self:GetSpecialValueFor("lock_duration")
	})
	return false
end

modifier_down_with_a_touch_slow = class({})

function modifier_down_with_a_touch_slow:IsDebuff() return true end

function modifier_down_with_a_touch_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_down_with_a_touch_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_down_with_a_touch_slow:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1, true)
	end
end

function modifier_down_with_a_touch_slow:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_down_with_a_touch_slow:OnDestroy()
	if not IsServer() then return end
	-- DD RunScript: astolfo_ability / OnDownSlowTier1End
	OnDownSlowTier1End({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

modifier_down_with_a_touch_slow_2 = class({})

function modifier_down_with_a_touch_slow_2:IsDebuff() return true end

function modifier_down_with_a_touch_slow_2:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_down_with_a_touch_slow_2:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow_tier2")
end

function modifier_down_with_a_touch_slow_2:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1, true)
	end
end

function modifier_down_with_a_touch_slow_2:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_down_with_a_touch_slow_2:OnDestroy()
	if not IsServer() then return end
	-- DD RunScript: astolfo_ability / OnDownSlowTier2End
	OnDownSlowTier2End({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

modifier_down_with_a_touch_slow_3 = class({})

function modifier_down_with_a_touch_slow_3:IsDebuff() return true end

function modifier_down_with_a_touch_slow_3:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_down_with_a_touch_slow_3:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow_tier3")
end

function modifier_down_with_a_touch_slow_3:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1, true)
	end
end

function modifier_down_with_a_touch_slow_3:OnRefresh(kv)
	self:OnCreated(kv)
end
