-- E : Battle Stance
-- Cú Chulainn Alter takes a stance and draws a ring around himself. After a short delay,
-- if an enemy is inside the ring, he performs an uninterruptible charge through the nearest
-- one, stunning and damaging every enemy along the way.
-- If no enemy is present when the stance ends, the cooldown and mana are refunded.

cu_alter_battle_stance = cu_alter_battle_stance or class({})

LinkLuaModifier("modifier_cu_alter_stance",       "abilities/cu_alter/cu_alter_battle_stance", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cu_alter_stance_dash",  "abilities/cu_alter/cu_alter_battle_stance", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_barrier_new",           "modifiers/modifier_barrier_new",            LUA_MODIFIER_MOTION_NONE)

-- Shared spear-pierce FX (see cu_alter_charge.lua). Guarded against double definition.
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

if not CuAlterPierceFromCaster then
	function CuAlterPierceFromCaster(caster, target)
		local fwd = caster:GetForwardVector()
		CuAlterPierceFx(
			caster:GetAbsOrigin() + Vector(0, 0, 100) + caster:GetRightVector() * -20,
			target:GetAbsOrigin() + Vector(0, 0, 100) + fwd * -50,
			fwd)
	end
end

function cu_alter_battle_stance:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

-- Play the stance animation from the cast phase (Karna-style) so it isn't started twice
-- (once by the engine cast animation, once after the cast point).
function cu_alter_battle_stance:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	caster:EmitSound("cu_alter_vo_stance")	-- "There won't be a next time."
	caster:EmitSound("cu_alter_sfx_ecast")	-- stance cast SFX
	StartAnimation(caster, { duration = self:GetCastPoint() + self:GetSpecialValueFor("delay"), activity = ACT_DOTA_CAST_ABILITY_3, rate = 1.0 })
	return true
end

function cu_alter_battle_stance:OnAbilityPhaseInterrupted()
	EndAnimation(self:GetCaster())
end

-- called by modifier_barrier_new:OnDestroy (attribute Battle Continuation barrier)
function cu_alter_battle_stance:OptionalDestroy(parent)
end

function cu_alter_battle_stance:OnSpellStart()
	local caster = self:GetCaster()
	local delay  = self:GetSpecialValueFor("delay")

	caster:AddNewModifier(caster, self, "modifier_cu_alter_stance", { duration = delay })

	-- attribute Battle Continuation: taking the stance grants Cú Chulainn a barrier (up front, so it
	-- can actually soak damage during the vulnerable stance/charge — not tacked onto the dash).
	if caster.CuAlterAttr4Acquired then
		caster:AddNewModifier(caster, self, "modifier_barrier_new", {
			duration              = self:GetSpecialValueFor("attr_barrier_duration"),
			shield_amount         = self:GetSpecialValueFor("attr_barrier"),
			decreaseDamageOnProck = 0,
			beforeBScroll         = false,
			ShouldEndChannel      = false,
			HasCounter            = false,
		})
	end

	-- ring showing the detection radius during the stance
	self.ringFx = ParticleManager:CreateParticle("particles/zlodemon/zlodemon_basic_circle.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(self.ringFx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(self.ringFx, 1, Vector(1, 0.1, 0.1))
	ParticleManager:SetParticleControl(self.ringFx, 2, Vector(self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("delay"), 0))

	Timers:CreateTimer(delay, function()
		if not IsNotNull(caster) or not caster:IsAlive() then return end
		if self.ringFx then
			ParticleManager:DestroyParticle(self.ringFx, true)
			ParticleManager:ReleaseParticleIndex(self.ringFx)
			self.ringFx = nil
		end
		self:TryCharge()
	end)
end

function cu_alter_battle_stance:TryCharge()
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_cu_alter_stance")

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetAbsOrigin(),
		nil,
		self:GetSpecialValueFor("radius"),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_CLOSEST,
		false)

	local target = enemies[1]
	if not target then
		-- nobody to charge: give it back to the player
		self:EndCooldown()
		caster:GiveMana(self:GetManaCost(self:GetLevel()))
		return
	end

	local toTarget = (target:GetAbsOrigin() - caster:GetAbsOrigin())
	toTarget.z = 0
	local dir = toTarget:Normalized()
	caster:SetForwardVector(dir)

	self.hitTargets = {}
	local speed = self:GetSpecialValueFor("dash_speed")

	-- charge just past the target so Cú Chulainn always ends up behind its back
	local range = toTarget:Length2D() + self:GetSpecialValueFor("behind_offset")
	range = math.min(range, self:GetSpecialValueFor("dash_max"))

	--caster:EmitSound("cu_alter_stance_dash")
	caster:AddNewModifier(caster, self, "modifier_cu_alter_stance_dash", { duration = range / speed })
end

function cu_alter_battle_stance:HitAlong(enemy)
	local caster = self:GetCaster()
	if self.hitTargets[enemy:entindex()] then return end
	self.hitTargets[enemy:entindex()] = enemy

	-- first damage part, dealt while charging through
	DoDamage(caster, enemy, self:GetSpecialValueFor("damage_dash"), DAMAGE_TYPE_MAGICAL, 0, self, false)
	enemy:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration") })

	CuAlterPierceFromCaster(caster, enemy)
	--enemy:EmitSound("")	-- TODO: impale impact SFX
end

-- Spears erupt from within the impaled target: a render-model particle
-- (models/cu_alter/cualter_spears.vmdl) played on the target. No dummy units.
-- Removed after exactly the stun duration.
function cu_alter_battle_stance:SpawnSpears(enemy)
	local caster = self:GetCaster()
	local pos = enemy:GetAbsOrigin() + Vector(0, 0, 80)
	local fx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_spears_burst.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
	ParticleManager:SetParticleControl(fx, 0, pos)
	ParticleManager:SetParticleControlForward(fx, 0, caster:GetForwardVector())
	Timers:CreateTimer(self:GetSpecialValueFor("stun_duration"), function()
		ParticleManager:DestroyParticle(fx, true)	-- immediate: the model has its own long life, so tie duration here
		ParticleManager:ReleaseParticleIndex(fx)
	end)
end

-- second damage part, dealt after the post-dash stun ends, to everyone hit by the charge
function cu_alter_battle_stance:DealDelayedDamage()
	local caster = self:GetCaster()
	local dmg = self:GetSpecialValueFor("damage_delayed")
	-- With the Cursed Gáe Bolg attribute, the delayed hit also inflicts Sealed Fate (curse values read
	-- from Spear Throw). The erupting-spears visual comes from the curse itself (on detonation), not
	-- from here — so no spears are played on the hit.
	local w = caster:FindAbilityByName("cu_alter_spear_throw")
	for _, enemy in pairs(self.hitTargets or {}) do
		if IsNotNull(enemy) and enemy:IsAlive() then
			DoDamage(caster, enemy, dmg, DAMAGE_TYPE_MAGICAL, 0, self, false)
			enemy:EmitSound("cu_alter_sfx_blood")	-- tearing flesh on the second hit

			if w and caster.CuAlterAttr2Acquired then
				enemy:AddNewModifier(caster, w, "modifier_heal_reduction_tier_3_uncleansable", { duration = w:GetSpecialValueFor("healres_duration") })
				enemy:AddNewModifier(caster, w, "modifier_cu_alter_sealed_fate", { duration = w:GetSpecialValueFor("healres_duration") })
			end

			-- blood fountain + a bloody explosion for the "erupting from inside" second hit
			local fx = ParticleManager:CreateParticle("particles/centaur_double_edge_ti9_bloodspray_tgt.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
			ParticleManager:SetParticleControlForward(fx, 0, caster:GetForwardVector())
			local blast = ParticleManager:CreateParticle("particles/custom/vlad/vlad_im_splash_blood.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
			Timers:CreateTimer(2.0, function()
				ParticleManager:DestroyParticle(fx, false)
				ParticleManager:ReleaseParticleIndex(fx)
				ParticleManager:DestroyParticle(blast, false)
				ParticleManager:ReleaseParticleIndex(blast)
			end)
		end
	end
	self.hitTargets = {}
end

---------------------------------------------------------------------------------------------------
-- Stance modifier : committed while charging up — rooted, cannot attack, cast or use items.
modifier_cu_alter_stance = modifier_cu_alter_stance or class({})

function modifier_cu_alter_stance:IsHidden()      return false end
function modifier_cu_alter_stance:IsDebuff()      return false end
function modifier_cu_alter_stance:IsPurgable()    return false end
function modifier_cu_alter_stance:RemoveOnDeath() return true end

function modifier_cu_alter_stance:CheckState()
	return {
		[MODIFIER_STATE_ROOTED]   = true,
		[MODIFIER_STATE_DISARMED] = true,	-- no attacking
		[MODIFIER_STATE_SILENCED] = true,	-- no abilities
		[MODIFIER_STATE_MUTED]    = true,	-- no items
	}
end

---------------------------------------------------------------------------------------------------
-- Dash modifier : uninterruptible charge that passes through units.
modifier_cu_alter_stance_dash = modifier_cu_alter_stance_dash or class({})

function modifier_cu_alter_stance_dash:IsHidden()       return true end
function modifier_cu_alter_stance_dash:IsDebuff()       return false end
function modifier_cu_alter_stance_dash:IsPurgable()     return false end
function modifier_cu_alter_stance_dash:RemoveOnDeath()  return true end

function modifier_cu_alter_stance_dash:CheckState()
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_DISARMED]          = true,
		[MODIFIER_STATE_STUNNED]           = true, -- cannot act; makes the charge "uninterruptible" for the caster
	}
end

function modifier_cu_alter_stance_dash:OnCreated()
	self.caster  = self:GetCaster()
	self.ability = self:GetAbility()
	self.speed   = self.ability:GetSpecialValueFor("dash_speed")
	self.radius  = self.ability:GetSpecialValueFor("dash_radius")

	if IsServer() then
		if not self:ApplyHorizontalMotionController() then
			self:Destroy()
			return
		end
		self.caster:EmitSound("cu_alter_sfx_pierce2")	-- charge-through whoosh
		-- dedicated charge animation for the dash (ACT_DOTA_CAST_ABILITY_7), held through the recovery
		local post = self.ability:GetSpecialValueFor("post_stun")
		StartAnimation(self.caster, { duration = self:GetDuration() + (post or 0), activity = ACT_DOTA_CAST_ABILITY_7, rate = 1.0 })
		--self.trailFx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_stance_dash.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster)
		--self:AddParticle(self.trailFx, false, false, -1, false, false)
	end
end

function modifier_cu_alter_stance_dash:UpdateHorizontalMotion(unit, dt)
	if not IsServer() then return end

	local dir     = self.caster:GetForwardVector()
	local nextPos = unit:GetAbsOrigin() + dir * self.speed * dt

	-- Plough straight through terrain (no traversable/blocked check): the charge phases through walls /
	-- cliffs instead of getting stuck on them. FindClearSpaceForUnit in OnDestroy resolves the endpoint.
	unit:SetAbsOrigin(nextPos)

	local enemies = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		unit:GetAbsOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false)

	for _, enemy in pairs(enemies) do
		if IsNotNull(enemy) then
			self.ability:HitAlong(enemy)
		end
	end
end

function modifier_cu_alter_stance_dash:OnHorizontalMotionInterrupted()
	if IsServer() then
		self:Destroy()
	end
end

function modifier_cu_alter_stance_dash:OnDestroy()
	if IsServer() then
		self.caster:RemoveHorizontalMotionController(self)
		FindClearSpaceForUnit(self.caster, self.caster:GetAbsOrigin(), true)
		-- NB: no EndAnimation here so ACT_DOTA_CAST_ABILITY_7 plays through the recovery window

		-- self-stun / recovery after the charge, then the delayed second damage
		local post = self.ability:GetSpecialValueFor("post_stun")
		if post and post > 0 then
			self.caster:AddNewModifier(self.caster, self.ability, "modifier_stunned", { duration = post })
		end
		local ability = self.ability
		Timers:CreateTimer(post or 0, function()
			ability:DealDelayedDamage()
		end)
	end
end
