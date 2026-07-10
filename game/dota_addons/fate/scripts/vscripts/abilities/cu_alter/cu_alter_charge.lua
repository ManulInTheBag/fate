-- Q : Charge
-- Cú Chulainn Alter lunges forward. The first enemy he collides with is stunned,
-- shoved a short distance forward and takes damage. The dash is a movement dash,
-- so it is disabled by root (see DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES in the KV).
--
-- Animations are driven by modifiers (MODIFIER_PROPERTY_OVERRIDE_ANIMATION) instead of
-- StartAnimation gestures, so the dash -> stab transition is crisp with no delay:
--   * dash: modifier_cu_alter_charge_motion overrides to ACT_DOTA_CAST_ABILITY_9
--   * stab: modifier_cu_alter_charge_hit overrides to ACT_DOTA_CAST_ABILITY_1 and
--           self-stuns for the full length of the stab animation.

cu_alter_charge = cu_alter_charge or class({})

-- ACT_DOTA_CAST_ABILITY_8/9 exist in the model but are not exposed as VScript globals
-- (only _1.._7 are). They are consecutive in the engine enum, so derive them from _7.
ACT_DOTA_CAST_ABILITY_8 = ACT_DOTA_CAST_ABILITY_8 or (ACT_DOTA_CAST_ABILITY_7 and ACT_DOTA_CAST_ABILITY_7 + 1)
ACT_DOTA_CAST_ABILITY_9 = ACT_DOTA_CAST_ABILITY_9 or (ACT_DOTA_CAST_ABILITY_7 and ACT_DOTA_CAST_ABILITY_7 + 2)

LinkLuaModifier("modifier_cu_alter_charge_motion", "abilities/cu_alter/cu_alter_charge", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_cu_alter_charge_hit",    "abilities/cu_alter/cu_alter_charge", LUA_MODIFIER_MOTION_NONE)
-- combo "arm" swap (Charge is the trigger with autocast on): swaps Roar out for the Combo in slot F
LinkLuaModifier("modifier_cu_alter_combo_switch",  "abilities/cu_alter/cu_alter_charge", LUA_MODIFIER_MOTION_NONE)

-- Shared spear-pierce FX (cu_chulain/gae_bolg_pierce): the thrust is drawn from srcPos
-- (CP0/CP1) to dstPos (CP5), oriented along fwd. Mirrors cu_chulain_gae_bolg.lua's 3-point
-- setup. Guarded so it's defined regardless of file load order.
if not CuAlterPierceFx then
	function CuAlterPierceFx(srcPos, dstPos, fwd)
		local fx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_pierce.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControlTransformForward(fx, 0, srcPos, fwd)
		ParticleManager:SetParticleControlTransformForward(fx, 1, srcPos, fwd)
		ParticleManager:SetParticleControlTransformForward(fx, 5, dstPos, fwd)
		Timers:CreateTimer(2.0, function()
			ParticleManager:DestroyParticle(fx, false)
			ParticleManager:ReleaseParticleIndex(fx)
		end)
	end
end

-- Shared "gather" knockback (see cu_alter_spear_throw.lua): shove `unit` toward `gatherPoint`.
-- Guarded so it's defined regardless of file load order.
if not CuAlterGatherKnockback then
	function CuAlterGatherKnockback(caster, ability, unit, gatherPoint, duration)
		if IsKnockbackImmune(unit) then return end
		local upos = unit:GetAbsOrigin()
		local dir  = gatherPoint - upos
		dir.z = 0
		local dist = dir:Length2D()
		if dist < 1 then return end
		dir = dir:Normalized()
		local center = upos - dir * 100
		unit:RemoveModifierByName("modifier_knockback")
		unit:AddNewModifier(caster, ability, "modifier_knockback", {
			should_stun        = false,
			knockback_duration = duration,
			duration           = duration,
			knockback_distance = dist,
			knockback_height   = 0,
			center_x           = center.x,
			center_y           = center.y,
			center_z           = center.z,
		})
	end
end

-- Convenience: melee pierce from the caster's chest into the target's chest.
if not CuAlterPierceFromCaster then
	function CuAlterPierceFromCaster(caster, target)
		local fwd = caster:GetForwardVector()
		CuAlterPierceFx(
			caster:GetAbsOrigin() + Vector(0, 0, 100) + caster:GetRightVector() * -20,
			target:GetAbsOrigin() + Vector(0, 0, 100) + fwd * -50,
			fwd)
	end
end

function cu_alter_charge:GetAOERadius()
	return self:GetSpecialValueFor("distance")
end

-- Combo gate: 30 in all stats and the combo off cooldown (mirrors okada_flashblade:CheckCombo).
function cu_alter_charge:CheckCombo()
	local caster = self:GetCaster()
	local num = 29.1
	if caster:GetStrength() >= num and caster:GetAgility() >= num and caster:GetIntellect() >= num then
		local combo = caster:FindAbilityByName("cu_alter_combo")
		if combo and combo:IsCooldownReady() then
			return true
		end
	end
	return false
end

function cu_alter_charge:OnSpellStart()
	local caster = self:GetCaster()

	-- with autocast on, casting Charge arms the combo: swap the Combo into the Roar (F) slot for 3s
	if self:GetAutoCastState() and self:CheckCombo() then
		caster:AddNewModifier(caster, self, "modifier_cu_alter_combo_switch", { duration = 3 })
	end

	-- Cast without a range limit (huge AbilityCastRange): he never walks up first. He dashes toward
	-- the clicked point but only as far as his max distance (closer clicks dash the shorter way).
	local point = self:GetCursorPosition()
	local toPoint = (point - caster:GetAbsOrigin())
	toPoint.z = 0
	local dist  = math.min(toPoint:Length2D(), self:GetSpecialValueFor("distance"))
	local dir   = toPoint:Normalized()
	caster:SetForwardVector(dir)

	local speed = self:GetSpecialValueFor("speed")

	caster:EmitSound("Hero_Slark.Pounce")	-- lunge whoosh (Dota Slark pounce)
	caster:AddNewModifier(caster, self, "modifier_cu_alter_charge_motion", { duration = dist / speed })
end

-- Applies the on-collision effects to a single enemy.
function cu_alter_charge:HitTarget(enemy)
	local caster = self:GetCaster()

	--DoDamage(caster, enemy, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
	--enemy:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration") })

	-- self-stun + stab animation for its full length (modifier-driven, no gesture delay)
	caster:AddNewModifier(caster, self, "modifier_cu_alter_charge_hit", { duration = self:GetSpecialValueFor("hit_anim_time") })

	enemy:EmitSound("cu_alter_sfx_pierce")	-- piercing hit
	CuAlterPierceFromCaster(caster, enemy)

	-- Small rectangular box (the target + a bit behind and to the sides): everyone else caught takes the
	-- same damage + stun, and ALL of them are GATHERED onto the spear — shoved toward the impale point so
	-- they collect together on the pierced target. FindUnitsInLine gives the box.
	local fwd    = caster:GetForwardVector() 
	local gather = enemy:GetAbsOrigin() 
	local box = FindUnitsInLine(
		caster:GetTeamNumber(),
		gather - fwd * 40,
		gather + fwd * self:GetSpecialValueFor("aoe_length"),
		nil,
		self:GetSpecialValueFor("aoe_width"),
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE)
	for _, u in pairs(box) do
		if IsNotNull(u) then
			DoDamage(caster, u, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
			u:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration") })
			CuAlterGatherKnockback(caster, self, u, gather+fwd * 200, self:GetSpecialValueFor("push_duration"))
		end
	end
end

---------------------------------------------------------------------------------------------------
modifier_cu_alter_charge_motion = modifier_cu_alter_charge_motion or class({})

function modifier_cu_alter_charge_motion:IsHidden()        return true end
function modifier_cu_alter_charge_motion:IsDebuff()        return false end
function modifier_cu_alter_charge_motion:IsPurgable()      return false end
function modifier_cu_alter_charge_motion:RemoveOnDeath()   return true end

-- Self-stun during the dash: no turning, no casting, uninterruptible movement.
-- NO_UNIT_COLLISION: without it the per-frame SetAbsOrigin makes the engine physically shove
-- units on the path aside — a pseudo-knockback that ignores knockback immunity.
function modifier_cu_alter_charge_motion:CheckState()
	return {
		[MODIFIER_STATE_STUNNED]  = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_cu_alter_charge_motion:DeclareFunctions()
	return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE }
end
function modifier_cu_alter_charge_motion:GetOverrideAnimation()     return ACT_DOTA_CAST_ABILITY_9 end
function modifier_cu_alter_charge_motion:GetOverrideAnimationRate() return 1.0 end

function modifier_cu_alter_charge_motion:OnCreated()
	self.caster  = self:GetCaster()
	self.ability = self:GetAbility()

	self.speed    = self.ability:GetSpecialValueFor("speed")
	self.radius   = self.ability:GetSpecialValueFor("radius")
	self.hasHit   = false

	if IsServer() then
		if not self:ApplyHorizontalMotionController() then
			self:Destroy()
			return
		end
		-- crimson lunge trail (recoloured / enlarged okada dash trail)
		self.trailFx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_dash_trail.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster)
	end
end

function modifier_cu_alter_charge_motion:UpdateHorizontalMotion(unit, dt)
	if not IsServer() then return end

	local dir      = self.caster:GetForwardVector()
	local nextPos  = unit:GetAbsOrigin() + dir * self.speed * dt

	-- stop at impassable terrain
	if not GridNav:IsTraversable(nextPos) or GridNav:IsBlocked(nextPos) then
		self:Destroy()
		return
	end

	unit:SetAbsOrigin(nextPos)

	-- collision check against the first enemy on the path
	local enemies = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		unit:GetAbsOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_CLOSEST,
		false)

	for _, enemy in pairs(enemies) do
		if IsNotNull(enemy) and not self.hasHit then
			self.hasHit = true
			self.ability:HitTarget(enemy)
			self:Destroy()
			return
		end
	end
end

function modifier_cu_alter_charge_motion:OnHorizontalMotionInterrupted()
	if IsServer() then
		self:Destroy()
	end
end

function modifier_cu_alter_charge_motion:OnDestroy()
	if IsServer() then
		self.caster:RemoveHorizontalMotionController(self)
		FindClearSpaceForUnit(self.caster, self.caster:GetAbsOrigin(), true)
		if self.trailFx then
			ParticleManager:DestroyParticle(self.trailFx, false)	-- stop emitting; existing ribbon fades out
			ParticleManager:ReleaseParticleIndex(self.trailFx)
			self.trailFx = nil
		end
		-- Always play the stab animation at the end of the dash — on a hit HitTarget already applied it,
		-- so only add it here on a MISS (same modifier: forces ACT_1 + self-stun for its length).
		if not self.hasHit then
			self.caster:AddNewModifier(self.caster, self.ability, "modifier_cu_alter_charge_hit", { duration = self.ability:GetSpecialValueFor("hit_anim_time") })
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Stab: forces the hit animation for its full length and self-stuns the caster meanwhile.
modifier_cu_alter_charge_hit = modifier_cu_alter_charge_hit or class({})

function modifier_cu_alter_charge_hit:IsHidden()      return true end
function modifier_cu_alter_charge_hit:IsDebuff()      return false end
function modifier_cu_alter_charge_hit:IsPurgable()    return false end
function modifier_cu_alter_charge_hit:RemoveOnDeath() return true end

function modifier_cu_alter_charge_hit:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true }
end

function modifier_cu_alter_charge_hit:DeclareFunctions()
	return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE }
end
function modifier_cu_alter_charge_hit:GetOverrideAnimation()     return ACT_DOTA_CAST_ABILITY_1 end
function modifier_cu_alter_charge_hit:GetOverrideAnimationRate() return 1.0 end

---------------------------------------------------------------------------------------------------
-- Combo arm window: while active, the Combo occupies the Roar (F) slot so the player can fire it.
-- Roar (F) is Ability5 = ability index 4. Mirrors okada's modifier_okada_combo_switch. When the
-- window ends the abilities swap back (the combo itself has a long cooldown that keeps it hidden).
modifier_cu_alter_combo_switch = modifier_cu_alter_combo_switch or class({})

function modifier_cu_alter_combo_switch:IsHidden()      return false end
function modifier_cu_alter_combo_switch:IsPurgable()    return false end
function modifier_cu_alter_combo_switch:RemoveOnDeath() return true end

if IsServer() then
	function modifier_cu_alter_combo_switch:OnCreated()
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(4) and caster:GetAbilityByIndex(4):GetName() == "cu_alter_roar" then
			caster:SwapAbilities("cu_alter_roar", "cu_alter_combo", false, true)
		end
	end

	function modifier_cu_alter_combo_switch:OnDestroy()
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(4) and caster:GetAbilityByIndex(4):GetName() == "cu_alter_combo" then
			caster:SwapAbilities("cu_alter_roar", "cu_alter_combo", true, false)
		end
	end
end
