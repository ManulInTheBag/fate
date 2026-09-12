require('abilities/rasputin/rasputin_gesture')
require('abilities/rasputin/rasputin_bk')

rasputin_dash = class({})

LinkLuaModifier("modifier_rasputin_turnrate", "abilities/rasputin/rasputin_dash", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_dash_dmg", "abilities/rasputin/rasputin_dash", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barrier_new", "modifiers/modifier_barrier_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_dash_move", "abilities/rasputin/rasputin_dash", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_rasputin_dash_surge", "abilities/rasputin/rasputin_dash", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_dash_charges", "abilities/rasputin/rasputin_dash", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_protection_from_arrows_active", "abilities/cu_chulain/modifiers/modifier_protection_from_arrows_active", LUA_MODIFIER_MOTION_NONE)

function rasputin_dash:GetIntrinsicModifierName()
	return "modifier_rasputin_dash_charges"
end


function rasputin_dash:CastFilterResultLocation(location)

	local caster = self:GetCaster()

    if RasputinIsRooted(caster) then
        self.customCastError = "Cannot use while rooted"
        return UF_FAIL_CUSTOM
    end



	if caster:HasModifier("modifier_rasputin_low_kick_dash") then
		self.customCastError = "Cannot use while airborne from low kick"
		return UF_FAIL_CUSTOM
	end


	if IsServer() then

		local charges = self:GetCharges()

		if charges and not charges:Has() then
			self.customCastError = "No charges"
			return UF_FAIL_CUSTOM
		end

	end

	return UF_SUCCESS

end

function rasputin_dash:GetCustomCastErrorLocation(location)
	return self.customCastError or "Cannot use right now"
end

function rasputin_dash:OnSpellStart()
	local caster = self:GetCaster()

	local charges = self:GetCharges()

	if charges then
		charges:Spend()
	end

	local direction = self:GetCursorPosition() - caster:GetAbsOrigin()
	direction.z = 0

	if direction:Length2D() == 0 then
		direction = caster:GetForwardVector()
		direction.z = 0
	end

	direction = direction:Normalized()


	if not RasputinIsFacingLocked(caster) then
		caster:Stop()
		caster:SetForwardVector(direction)
	end


	for _,name in ipairs({ "modifier_rasputin_dash_move", "modifier_rasputin_rush" }) do

		local mover = caster:FindModifierByName(name)

		if mover then
			mover.interrupted = true
			mover:Destroy()
		end

	end


	caster:InterruptMotionControllers(true)


	local distance = self:GetSpecialValueFor("distance")
	local speed = 2000

	if RasputinIsReborn(caster) then
		speed = speed * (1 + self:GetSpecialValueFor("reborn_dash_speed_pct") / 100)
	end


	caster:AddNewModifier(
		caster,
		self,
		"modifier_rasputin_dash_surge",
		{
			duration = self:GetSpecialValueFor("surge_duration")
		}
	)

	caster:AddNewModifier(caster, self, "modifier_rasputin_turnrate", {duration = distance / speed})


	-- Combat Movement: на время рывка Распутин уходит от снарядов,
	-- тем же модификатором, что и Protection from Arrows у Ку Хулина
	if caster.IsRasputinCombatMovementAcquired then

		caster:AddNewModifier(
			caster,
			self,
			"modifier_protection_from_arrows_active",
			{
				Duration = distance / speed,
				silent   = 1,
			}
		)

	end


	caster:AddNewModifier(caster, self, "modifier_rasputin_dash_move", {
		duration = distance / speed + 0.25,
		direction_x = direction.x,
		direction_y = direction.y,
		distance = distance,
		speed = speed,
	})
end


function rasputin_dash:GetCharges()

	return self:GetCaster():FindModifierByName("modifier_rasputin_dash_charges")

end


function rasputin_dash:RefundChargeRestore()

	local charges = self:GetCharges()

	if not charges then return end

	charges:Refund(self:GetLevelSpecialValueFor("charge_refund_per_stack", 0))

end


modifier_rasputin_dash_charges = class({})


function modifier_rasputin_dash_charges:IsHidden() return true end
function modifier_rasputin_dash_charges:IsPurgable() return false end
function modifier_rasputin_dash_charges:IsDebuff() return false end
function modifier_rasputin_dash_charges:RemoveOnDeath() return false end


function modifier_rasputin_dash_charges:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


local CHARGE_THINK = 0.1


function modifier_rasputin_dash_charges:GetMaxStackCount()
	return self:GetAbility():GetSpecialValueFor("max_charges")
end


function modifier_rasputin_dash_charges:OnCreated()

	if not IsServer() then return end


	self.progress = 0

	self:SetStackCount(self:GetMaxStackCount())

	self:StartIntervalThink(CHARGE_THINK)

end


function modifier_rasputin_dash_charges:OnRefresh()
	if not IsServer() then return end
	self:StartIntervalThink(CHARGE_THINK)
end


function modifier_rasputin_dash_charges:OnIntervalThink()

	if not IsServer() then return end

	local max = self:GetMaxStackCount()

	if self:GetStackCount() >= max then
		self.progress = 0
		return
	end

	self.progress = (self.progress or 0) + CHARGE_THINK

	local restore = self:GetAbility():GetSpecialValueFor("charge_restore_time")


	-- заряды подчиняются сокращению кулдаунов (предметы, печати, Reborn):
	-- иначе E - единственная способность, которую CDR не трогает вообще
	local parent = self:GetParent()

	if IsNotNull(parent) then
		restore = restore * parent:GetCooldownReduction()
	end

	if restore <= 0 then
		restore = CHARGE_THINK
	end

	while self.progress >= restore and self:GetStackCount() < max do
		self.progress = self.progress - restore
		self:SetStackCount(self:GetStackCount() + 1)
	end

	if self:GetStackCount() >= max then
		self.progress = 0
	end

end


function modifier_rasputin_dash_charges:Has()
	return self:GetStackCount() > 0
end


function modifier_rasputin_dash_charges:Spend()

	if not IsServer() then return end

	self:SetStackCount(math.max(self:GetStackCount() - 1, 0))

end


function modifier_rasputin_dash_charges:Refund(seconds)

	if not IsServer() then return end

	if not seconds or seconds <= 0 then return end

	if self:GetStackCount() >= self:GetMaxStackCount() then return end

	self.progress = (self.progress or 0) + seconds

end


modifier_rasputin_turnrate = class({})

function modifier_rasputin_turnrate:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
	}
end

function modifier_rasputin_turnrate:IsHidden()
	return true
end

function modifier_rasputin_turnrate:RemoveOnDeath()
	return true
end

function modifier_rasputin_turnrate:IsDebuff()
	return false
end

function modifier_rasputin_turnrate:GetModifierTurnRate_Percentage()
	return 100
end


modifier_rasputin_dash_move = class({})

function modifier_rasputin_dash_move:IsHidden()
	return true
end

function modifier_rasputin_dash_move:IsPurgable()
	return false
end


function modifier_rasputin_dash_move:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DISABLE_TURNING,
	}
end

function modifier_rasputin_dash_move:GetModifierDisableTurning()
	return 1
end

function modifier_rasputin_dash_move:OnCreated(kv)

	if not IsServer() then return end

	self.parent = self:GetParent()

	self.direction = Vector(kv.direction_x, kv.direction_y, 0):Normalized()
	self.speed = kv.speed
	self.distance = kv.distance
	self.traveled = 0

	self:StartDashPose()


	self.parent:EmitSound(RASPUTIN_SHORT_DASH_SOUND)


	RasputinDashTrail(self.parent, function()
	    return not self.destroyed
	end)

	RasputinDashShield(self.parent, function()
	    return not self.destroyed
	end)

	RasputinAfterimageTrail(self.parent, function()
		return not self.destroyed
	end)

	if self:ApplyHorizontalMotionController() == false then
		self:Destroy()
	end

end


function modifier_rasputin_dash_move:StartDashPose()

	if self.parent:HasModifier("modifier_rasputin_wide_kick_anim_lock") then
		return
	end

	local wait = RasputinBusyGestureRemaining(self.parent)

	if wait <= 0 then
		self.poseStarted = true
		RasputinPlayGesture(self.parent, ACT_DOTA_CAST_ABILITY_3, 0)
		return
	end

	Timers:CreateTimer(wait, function()

		if not IsNotNull(self) then return end


		if self.destroyed then return end

		if not IsNotNull(self.parent) then return end

		if self.parent:HasModifier("modifier_rasputin_wide_kick_anim_lock") then
			return
		end

		self.poseStarted = true

		RasputinPlayGesture(self.parent, ACT_DOTA_CAST_ABILITY_3, 0)

	end)

end

function modifier_rasputin_dash_move:UpdateHorizontalMotion(unit, dt)

	local move = self.direction * self.speed * dt

	unit:SetAbsOrigin(unit:GetAbsOrigin() + move)

	self.traveled = self.traveled + move:Length2D()

	if self.traveled >= self.distance then
		self:Destroy()
	end

end

function modifier_rasputin_dash_move:OnHorizontalMotionInterrupted()

	if not IsServer() then return end


	if self:ApplyHorizontalMotionController() == false then
		self.interrupted = true
		self:Destroy()
	end

end

function modifier_rasputin_dash_move:OnDestroy()

	if not IsServer() then return end


	self.destroyed = true

	if not self.parent or self.parent:IsNull() then
		return
	end


	if self.poseStarted then
		RasputinStopGesture(self.parent, ACT_DOTA_CAST_ABILITY_3)
	end

	self.parent:RemoveHorizontalMotionController(self)


	if not self.interrupted then
		FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
	end

end

function modifier_rasputin_dash_move:CheckState()

	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}

end


modifier_rasputin_dash_surge = class({})

function modifier_rasputin_dash_surge:IsHidden() return false end
function modifier_rasputin_dash_surge:IsPurgable() return false end
function modifier_rasputin_dash_surge:IsDebuff() return false end
function modifier_rasputin_dash_surge:RemoveOnDeath() return true end


function modifier_rasputin_dash_surge:DeclareFunctions()

	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}

end


function modifier_rasputin_dash_surge:OnTakeDamage(args)

	if not IsServer() then return end

	local parent = self:GetParent()


	if args.attacker ~= parent then return end
	if args.unit == parent then return end
	if not args.inflictor then return end

	-- Финишер рывок не тратит: бонус ждёт любой другой скилл
	local inflictor = args.inflictor

	if type(inflictor.GetAbilityName) == "function"
	and inflictor:GetAbilityName() == "rasputin_finisher"
	then
		return
	end

	local damage = args.damage or 0

	if damage <= 0 then return end

	if self.spent then return end

	self.spent = true

	local ability = self:GetAbility()


	local mana =
	ability:GetSpecialValueFor("surge_mana_base")

	local victim = args.unit

	-- добавка = база + % от максимального здоровья цели (оба растут с уровнем E)
	local bonusDamage =
	ability:GetSpecialValueFor("surge_bonus_damage")
	+ victim:GetMaxHealth() * ability:GetSpecialValueFor("surge_bonus_max_hp_pct") / 100

	local heal = 0

	-- Combat Movement: лечит ровно столько же, сколько добавка урона,
	-- только процент берётся от максимального здоровья самого Распутина
	if parent.IsRasputinCombatMovementAcquired then

		heal =
		ability:GetSpecialValueFor("surge_bonus_damage")
		+ parent:GetMaxHealth() * ability:GetSpecialValueFor("surge_bonus_max_hp_pct") / 100

	end


	Timers:CreateTimer(FrameTime(), function()

		if not IsNotNull(parent) then return end

		if not parent:IsAlive() then return end

		if mana > 0 then
			parent:GiveMana(mana)
		end

		if heal > 0 then
			parent:Heal(heal, IsNotNull(ability) and ability or parent)
		end


		-- добавка к первому же скиллу после рывка: одна инстанция,
		-- урон нельзя наносить прямо из колбэка урона, поэтому он здесь
		if bonusDamage > 0
		and IsNotNull(ability)
		and IsNotNull(victim)
		and victim:IsAlive()
		then

			DoDamage(
				parent,
				victim,
				bonusDamage,
				DAMAGE_TYPE_PHYSICAL,
				0,
				ability,
				false
			)

		end


		parent:RemoveModifierByName("modifier_rasputin_dash_surge")

	end)

end
