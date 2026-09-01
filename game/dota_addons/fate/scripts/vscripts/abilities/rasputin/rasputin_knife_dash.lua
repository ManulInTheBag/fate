require('abilities/rasputin/rasputin_gesture')
require('abilities/rasputin/rasputin_bk')

rasputin_knife_dash = class({})
LinkLuaModifier("modifier_rasputin_knife_dash_tracker", "abilities/rasputin/modifier_rasputin_knife_dash_tracker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rasputin_rush","abilities/rasputin/modifier_rasputin_rush",LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_rasputin_knife_grab","abilities/rasputin/modifier_rasputin_knife_grab",LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_rasputin_throw_lock","abilities/rasputin/rasputin_knife_dash", LUA_MODIFIER_MOTION_NONE)


local function IsDashing(unit)
	return unit:HasModifier("modifier_rasputin_dash_move")
		or unit:HasModifier("modifier_rasputin_rush")
		or unit:HasModifier("modifier_rasputin_dodge_leap")
end

local function ThrowOrigin(caster)

	local attach = caster:ScriptLookupAttachment("attach_attack2")

	if attach and attach > 0 then

		local origin = caster:GetAttachmentOrigin(attach)

		if origin and origin:Length() > 0 then
			return origin
		end

	end

	return caster:GetAbsOrigin()

end


function rasputin_knife_dash:CastFilterResultLocation(location)
    local caster = self:GetCaster()

    if RasputinIsRooted(caster) then
        self.customCastError = "Cannot use while rooted"
        return UF_FAIL_CUSTOM
    end

    if caster:HasModifier("modifier_rasputin_low_kick_dash") then
        self.customCastError = "Cannot use while airborne from low kick"
        return UF_FAIL_CUSTOM
    end


    if IsServer() and self:CheckSequence() == 0 and self:IsKnifeInFlight() then
        self.customCastError = "Knife is still in the air"
        return UF_FAIL_CUSTOM
    end


    if IsServer() and self:CheckSequence() == 1 then


        local target = caster.dash_target

        if not IsNotNull(target) or not target:IsAlive() then
            self.customCastError = "No target"
            return UF_FAIL_CUSTOM
        end

        local distance =
        (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()

        if distance > self:GetSpecialValueFor("distance") then
            self.customCastError = "Target out of range"
            return UF_FAIL_CUSTOM
        end

    end

    return UF_SUCCESS
end

function rasputin_knife_dash:GetCustomCastErrorLocation(location)
    return self.customCastError or "Cannot use right now"
end

function rasputin_knife_dash:GetAbilityTextureName()

    local caster = self:GetCaster()

    if caster:HasModifier("modifier_rasputin_knife_dash_tracker") then

        local stack =
        caster:GetModifierStackCount("modifier_rasputin_knife_dash_tracker", caster)

        if stack == 1 then
            return "custom/rasputin/rasputin_knife_dash_2"
        end

    end

    return "custom/rasputin/rasputin_knife_dash_1"

end

function rasputin_knife_dash:CheckSequence()
    local caster = self:GetCaster()
    local modifier =caster:FindModifierByName("modifier_rasputin_knife_dash_tracker")
    if modifier then
        return modifier:GetStackCount()
    end
    return 0
end

function rasputin_knife_dash:SequenceSkill()

    local caster = self:GetCaster()


    local tracker =
    caster:FindModifierByName(
        "modifier_rasputin_knife_dash_tracker"
    )


    if not tracker then

        caster:AddNewModifier(
            caster,
            self,
            "modifier_rasputin_knife_dash_tracker",
            {
                Duration =
                self:GetSpecialValueFor("recast_duration")
            }
        )

        self.recastGapUntil =
        GameRules:GetGameTime() + self:GetSpecialValueFor("recast_duration")

        self:EndCooldown()

    else

        tracker:Destroy()

    end

end

function rasputin_knife_dash:OnSpellStart()
    local seq = self:CheckSequence()
	if seq == 0 then
		self:KnifeThrow()
	elseif seq == 1 then
		self:KnifeDash()
	end
end

function rasputin_knife_dash:KnifeThrow()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	local origin = caster:GetAbsOrigin()
	local direction =
	(position-origin):Normalized()
	if direction:Length2D()==0 then
		direction = caster:GetForwardVector()
	end
	direction.z = 0


	if not IsDashing(caster) then
		caster:Stop()
		caster:SetForwardVector(direction)
	end


	if not caster:HasModifier("modifier_rasputin_wide_kick_anim_lock") then
		RasputinPlayGesture(caster, ACT_DOTA_CAST_ABILITY_1)
	end

	caster:EmitSound(
	"rasputin_knife_dash_throw"
	)


	RasputinRetreat(
		caster,
		direction,
		self:GetSpecialValueFor("backstep_distance"),
		self:GetSpecialValueFor("backstep_duration")
	)


	local windup = self:GetSpecialValueFor("throw_delay")

	caster:AddNewModifier(
		caster,
		self,
		"modifier_rasputin_throw_lock",
		{
			duration = windup
		}
	)

	-- пока нож в воздухе, второй бросок запрещён (см. IsKnifeInFlight)
	self.knifeInFlight = true

	self.knifeFlightUntil =
	GameRules:GetGameTime()
	+ windup
	+ self:GetSpecialValueFor("distance") / 3000
	+ 0.5

	self.sequenceStart = GameRules:GetGameTime()

	self.bankedCooldownRefund = nil
	self.recastGapUntil = nil

	local function Launch()


		if not IsNotNull(self) then return end

		if not IsNotNull(caster) or not caster:IsAlive() then
			self.knifeInFlight = nil
			return
		end

		local projectile =
		{
			EffectName =
			"particles/rasputin/knife_throw.vpcf",

			Ability = self,


			vSpawnOrigin = ThrowOrigin(caster),


			vVelocity =
			direction * 3000 * (
				RasputinIsReborn(caster)
				and (1 + self:GetSpecialValueFor("reborn_projectile_speed_pct") / 100)
				or 1
			),

			fDistance =
			self:GetSpecialValueFor("distance"),

			fStartRadius = 115,

			fEndRadius = 115,

			Source = caster,

			bDeleteOnHit = true,


			iUnitTargetTeam =
			DOTA_UNIT_TARGET_TEAM_ENEMY,

			iUnitTargetType =
			DOTA_UNIT_TARGET_HERO +
			DOTA_UNIT_TARGET_BASIC
		}

		self.projectile =
		ProjectileManager:CreateLinearProjectile(projectile)

	end

	if windup and windup > 0 then
		Timers:CreateTimer(windup, Launch)
	else
		Launch()
	end

end


local SHIELD_MODIFIERS = {
	"modifier_barrier_new",
	"modifier_leonidas_enomotia_shield",
}


-- нож считается летящим от начала броска и до попадания или конца дистанции;
-- расчётное время полёта - страховка на случай, если OnProjectileHit не придёт
function rasputin_knife_dash:IsKnifeInFlight()

	if not self.knifeInFlight then return false end

	if GameRules:GetGameTime() >= (self.knifeFlightUntil or 0) then
		self.knifeInFlight = nil
		return false
	end

	return true

end


function rasputin_knife_dash:DamageShields(hTarget)

	local hCaster = self:GetCaster()

	if not hCaster.IsRasputinKeysAcquired then return end

	if not IsNotNull(hTarget) then return end

	local pct = self:GetSpecialValueFor("keys_shield_damage_pct")


	local counter =
	hCaster:FindModifierByName("modifier_rasputin_finisher_counter")

	if counter
	and counter:GetStackCount() >= self:GetSpecialValueFor("grab_stack_threshold")
	then
		pct = pct * (1 + self:GetSpecialValueFor("keys_shield_bonus_pct") / 100)
	end

	local total = 0

	-- кап на суммарный урон по барьерам за одно срабатывание
	local cap = self:GetSpecialValueFor("keys_shield_damage_cap")

	if not cap or cap <= 0 then
		cap = math.huge
	end

	for _,name in ipairs(SHIELD_MODIFIERS) do


		for _,shield in pairs(hTarget:FindAllModifiersByName(name)) do

			local left = shield:GetStackCount()

			if left > 0 and total < cap then

				local taken = left * pct / 100

				if total + taken > cap then
					taken = cap - total
				end

				shield:SetStackCount(math.max(left - taken, 0))

				total = total + taken

			end

		end

	end


end


function RasputinReleaseKnifeMark(unit, ability)

	if not IsNotNull(unit) then return end

	local fx = unit.rasputin_knife_mark_fx

	if not fx then return end

	ParticleManager:DestroyParticle(fx, true)
	ParticleManager:ReleaseParticleIndex(fx)

	unit.rasputin_knife_mark_fx = nil

	if not IsNotNull(ability) then return end

	local linger = ability:GetSpecialValueFor("vision_linger")

	if linger and linger > 0 then

		unit:AddNewModifier(
			ability:GetCaster(),
			ability,
			"modifier_vision_provider",
			{
				Duration = linger
			}
		)

	end

end


function rasputin_knife_dash:OnProjectileHit(hTarget, vLocation)
	local hCaster = self:GetCaster()

	-- прилетел в цель или выдохся по дистанции - в любом случае бросок закончен
	self.knifeInFlight = nil
 	 if(hTarget ~= nil) then
	if hTarget:HasModifier("modifier_protection_from_arrows_active") then return end
	hCaster:EmitSound("rasputin_knife_dash_hit")


	if hCaster.IsRasputinKeysAcquired then
		ApplyPurge(hTarget)
	end


    fDamage =
    RasputinScaleDamage(
        hCaster,
        self,
        self:GetSpecialValueFor("damage1")
    )

	DoDamage(hCaster, hTarget, fDamage, self:GetAbilityDamageType(), 0, self, false)


	-- Распутин умер, пока нож летел: урон засчитан, но метку и Q2 уже не выдаём
	if not hCaster:IsAlive() then return true end


	-- нож добил цель: стак за попадание оставляем, но метку, вижн и Q2 на труп не вешаем
	if not hTarget:IsAlive() then
		RasputinGrantStack(hCaster, self, hTarget)
		return true
	end
	hTarget:AddNewModifier(hCaster, self, "modifier_vision_provider", { Duration = self:GetSpecialValueFor("recast_duration") })


	if hCaster.dash_target and hCaster.dash_target ~= hTarget then
		RasputinReleaseKnifeMark(hCaster.dash_target)
	end

	hCaster.dash_target = hTarget


	RasputinReleaseKnifeMark(hTarget)

	hTarget.rasputin_knife_mark_fx =
	ParticleManager:CreateParticle(
		RasputinFx(hCaster, "particles/rasputin/rasputin_knife_mark.vpcf"),
		PATTACH_OVERHEAD_FOLLOW,
		hTarget
	)

	-- если Q2 уже взведён предыдущим ножом, второй нож переносит метку на новую цель,
	-- а не гасит секвенцию: иначе трекер умирал со старой целью в self.marked и
	-- партикль метки оставался на новой цели навсегда
	local tracker =
	hCaster:FindModifierByName("modifier_rasputin_knife_dash_tracker")

	if tracker then

		tracker.marked = hTarget

		tracker:SetDuration(self:GetSpecialValueFor("recast_duration"), true)

		self.recastGapUntil =
		GameRules:GetGameTime() + self:GetSpecialValueFor("recast_duration")

		self:EndCooldown()

	else

		self:SequenceSkill()

	end

	RasputinGrantStack(hCaster, self, hTarget)
  end
  return true
end

function rasputin_knife_dash:OnProjectileThink(location)
    local caster = self:GetCaster()


	AddFOWViewer(2, location, 40, 0.4, false)
    AddFOWViewer(3, location, 40, 0.4, false)
end


function rasputin_knife_dash:ConsumeTracker()

	local caster = self:GetCaster()

	local tracker =
	caster:FindModifierByName("modifier_rasputin_knife_dash_tracker")

	if not tracker then return end

	tracker.consumed = true

	tracker:Destroy()

end


function rasputin_knife_dash:StartSequenceCooldown()

	local start = self.sequenceStart or GameRules:GetGameTime()


	local refreshed = RasputinWasRefreshed(self, start)


	local cooldown =
	self:GetCooldown(self:GetLevel())
	* self:GetCaster():GetCooldownReduction()
	- (GameRules:GetGameTime() - start)
	- (self.bankedCooldownRefund or 0)

	self.bankedCooldownRefund = nil
	self.recastGapUntil = nil

	self:EndCooldown()

	if refreshed then
		self.rasputinRefreshedAt = nil
		return
	end

	if cooldown > 0 then
		self:StartCooldown(cooldown)
	end

end

function rasputin_knife_dash:KnifeDash()

	local caster = self:GetCaster()

	local target = caster.dash_target

	if not target or target:IsNull() or not target:IsAlive() then
		self:ConsumeTracker()
		self:StartSequenceCooldown()
		return
	end

	local distance =
	(target:GetAbsOrigin()
	-caster:GetAbsOrigin()):Length2D()


	if distance >
	self:GetSpecialValueFor("distance") then
		self:StartSequenceCooldown()
		return
	end

	local dir =
	(target:GetAbsOrigin()
	-caster:GetAbsOrigin()):Normalized()


	RasputinCancelWideKick(caster)

	caster:SetForwardVector(dir)


	caster:EmitSound(
	"rasputin_knife_dash_recast_start"
	)
	local old = caster:FindModifierByName("modifier_rasputin_rush")

	if old then
		old:Destroy()
	end


	local eDash = caster:FindModifierByName("modifier_rasputin_dash_move")

	if eDash then
		eDash.interrupted = true
		eDash:Destroy()
	end

	local rushSpeed = self:GetSpecialValueFor("speed")

	if RasputinIsReborn(caster) then
		rushSpeed = rushSpeed * (1 + self:GetSpecialValueFor("reborn_dash_speed_pct") / 100)
	end

	caster:AddNewModifier(
	caster,
	self,
	"modifier_rasputin_rush",
	{


	damage =
	RasputinScaleDamage(
		caster,
		self,
		self:GetSpecialValueFor("damage2")
	),

	speed = rushSpeed
	}
	)

	self:ConsumeTracker()

	self:StartSequenceCooldown()

end


modifier_rasputin_throw_lock = class({})


function modifier_rasputin_throw_lock:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_DISABLE_TURNING,
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
	}

	return funcs
end

function modifier_rasputin_throw_lock:GetModifierDisableTurning()
	return 1
end


function modifier_rasputin_throw_lock:GetModifierMoveSpeed_Absolute()
	return 1
end

function modifier_rasputin_throw_lock:IsHidden() return true end
function modifier_rasputin_throw_lock:IsPurgable() return false end
function modifier_rasputin_throw_lock:RemoveOnDeath() return true end

