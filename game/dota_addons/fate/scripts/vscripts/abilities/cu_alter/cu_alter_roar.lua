-- F : Roar
-- Cú Chulainn Alter takes a stance and roars over a large radius for the channel duration.
-- Every pulse briefly stuns all enemies in range, shoves them slightly and drains their
-- Strength. The Strength drain stacks with every pulse that hits a target.
--
-- Additional ability: leveled through attributes, not through the normal hero level-up.

cu_alter_roar = cu_alter_roar or class({})

LinkLuaModifier("modifier_cu_alter_roar_str_debuff", "abilities/cu_alter/cu_alter_roar", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cu_alter_fear",            "abilities/cu_alter/cu_alter_roar", LUA_MODIFIER_MOTION_NONE)

function cu_alter_roar:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

-- Roar animation played from the cast phase (Karna-style) so it isn't started twice.
function cu_alter_roar:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	caster:EmitSound("cu_alter_vo_roar")	-- "Fear me! Tremble and panic."
	caster:EmitSound("cu_alter_sfx_roar_strong")	-- strong roar SFX under the voice
	StartAnimation(caster, { duration = self:GetCastPoint() + self:GetChannelTime(), activity = ACT_DOTA_CAST_ABILITY_5, rate = 1.0 })
	return true
end

function cu_alter_roar:OnAbilityPhaseInterrupted()
	EndAnimation(self:GetCaster())
end

function cu_alter_roar:OnSpellStart()
	local caster = self:GetCaster()
	self.accumulated = self:GetSpecialValueFor("tick_interval") -- pulse immediately on the first think
	self.pulsed = {} -- enemies hit by pulses (for the attribute fear check)

	-- ring showing the roar radius for the whole channel
	self.roarFx = ParticleManager:CreateParticle("particles/zlodemon/zlodemon_basic_circle.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(self.roarFx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(self.roarFx, 1, Vector(1, 0.1, 0.1))
	ParticleManager:SetParticleControl(self.roarFx, 2, Vector(self:GetSpecialValueFor("radius"), self:GetChannelTime(), 0))
end

function cu_alter_roar:OnChannelThink(flInterval)
	self.accumulated = (self.accumulated or 0) + flInterval
	local tick = self:GetSpecialValueFor("tick_interval")
	if self.accumulated < tick then return end
	self.accumulated = self.accumulated - tick

	self:Pulse()
end

function cu_alter_roar:Pulse()
	local caster = self:GetCaster()

	-- expanding wind wave each pulse (wind-only copy of the roar; children stripped so nothing flies
	-- off to the map centre, radius widened). See particles/cu_alter/cu_alter_roar_wind.vpcf.
	local waveFx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_roar_wind.vpcf", PATTACH_ABSORIGIN, caster)
	-- extra gusts layered on top so the roar reads as a real shockwave of wind
	local shockFx = ParticleManager:CreateParticle("particles/units/heroes/hero_beastmaster/beastmaster_primal_roar_shockwave.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	local pukFx   = ParticleManager:CreateParticle("particles/zlodemon/heracles/heracles_puk.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	Timers:CreateTimer(1.5, function()
		ParticleManager:DestroyParticle(waveFx, false)
		ParticleManager:ReleaseParticleIndex(waveFx)
		ParticleManager:DestroyParticle(shockFx, false)
		ParticleManager:ReleaseParticleIndex(shockFx)
		ParticleManager:DestroyParticle(pukFx, false)
		ParticleManager:ReleaseParticleIndex(pukFx)
	end)

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetAbsOrigin(),
		nil,
		self:GetSpecialValueFor("radius"),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false)

	local maxStacks = self:GetSpecialValueFor("max_stacks")

	for _, enemy in pairs(enemies) do
		if IsNotNull(enemy) then
			self.pulsed = self.pulsed or {}
			self.pulsed[enemy:entindex()] = enemy

			DoDamage(caster, enemy, self:GetSpecialValueFor("pulse_damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
			enemy:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("tick_stun_duration") })

			-- stacking Strength drain (one stack per pulse, refreshed each time)
			local mod = enemy:AddNewModifier(caster, self, "modifier_cu_alter_roar_str_debuff", { duration = self:GetSpecialValueFor("str_debuff_duration") })
			if mod and mod:GetStackCount() < maxStacks then
				mod:IncrementStackCount()
			end

			-- weak shove away from the caster
			if not IsKnockbackImmune(enemy) then
				local dir = (enemy:GetAbsOrigin() - caster:GetAbsOrigin())
				dir.z = 0
				dir = dir:Normalized()
				local knockback = {
					should_stun        = false,
					knockback_duration = self:GetSpecialValueFor("push_duration"),
					duration           = self:GetSpecialValueFor("push_duration"),
					knockback_distance = self:GetSpecialValueFor("push_distance"),
					knockback_height   = 0,
					center_x           = (enemy:GetAbsOrigin() - dir * 100).x,
					center_y           = (enemy:GetAbsOrigin() - dir * 100).y,
					center_z           = (enemy:GetAbsOrigin() - dir * 100).z,
				}
				enemy:RemoveModifierByName("modifier_knockback")
				enemy:AddNewModifier(caster, self, "modifier_knockback", knockback)
			end
		end
	end

	--local pulseFx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_roar_pulse.vpcf", PATTACH_ABSORIGIN, caster)
	--ParticleManager:ReleaseParticleIndex(pulseFx)
end

function cu_alter_roar:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()
	--caster:StopSound("cu_alter_roar_loop")
	EndAnimation(caster)
	if self.roarFx then
		ParticleManager:DestroyParticle(self.roarFx, true)
		ParticleManager:ReleaseParticleIndex(self.roarFx)
		self.roarFx = nil
	end

	-- attribute Roar of the Hound: enemies who endured the WHOLE roar (max stacks) are feared
	if caster.CuAlterAttr3Acquired then
		local maxStacks = self:GetSpecialValueFor("max_stacks")
		for _, enemy in pairs(self.pulsed or {}) do
			if IsNotNull(enemy) and enemy:IsAlive() then
				local mod = enemy:FindModifierByNameAndCaster("modifier_cu_alter_roar_str_debuff", caster)
				if mod and mod:GetStackCount() >= maxStacks then
					enemy:AddNewModifier(caster, self, "modifier_cu_alter_fear", { duration = self:GetSpecialValueFor("fear_duration") })
				end
			end
		end
	end
	self.pulsed = {}
end

---------------------------------------------------------------------------------------------------
-- Stacking Strength drain debuff. Registered in util.lua cleansable.
modifier_cu_alter_roar_str_debuff = modifier_cu_alter_roar_str_debuff or class({})

function modifier_cu_alter_roar_str_debuff:IsHidden()      return false end
function modifier_cu_alter_roar_str_debuff:IsDebuff()      return true end
function modifier_cu_alter_roar_str_debuff:RemoveOnDeath() return true end

function modifier_cu_alter_roar_str_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS }
end

function modifier_cu_alter_roar_str_debuff:GetModifierBonusStats_Strength()
	return -self:GetAbility():GetSpecialValueFor("str_reduction") * self:GetStackCount()
end

function modifier_cu_alter_roar_str_debuff:GetEffectName()
	return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end

function modifier_cu_alter_roar_str_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------
-- Fear: the victim loses control and flees away from Cú Chulainn. Registered in util.lua cleansable.
modifier_cu_alter_fear = modifier_cu_alter_fear or class({})

function modifier_cu_alter_fear:IsHidden()      return false end
function modifier_cu_alter_fear:IsDebuff()      return true end
function modifier_cu_alter_fear:IsPurgable()    return true end
function modifier_cu_alter_fear:RemoveOnDeath() return true end

-- NB: NO MODIFIER_STATE_COMMAND_RESTRICTED here — it blocks our own scripted flee order too, which
-- is why the victim just stood still. Instead we forcibly re-issue the flee every tick and lock them
-- out of acting with data-driven silence/disarm (the working charm pattern, modifier_love_spot_charmed).
function modifier_cu_alter_fear:OnCreated()
	if not IsServer() then return end
	self.caster = self:GetCaster()
	self:Flee()                  -- start fleeing immediately
	self:StartIntervalThink(0.1)  -- re-aim very often so the player can't wrestle control back
end

function modifier_cu_alter_fear:OnIntervalThink()
	self:Flee()
end

-- Smooth flee: issue ONE move order toward a far point away from the caster and let the unit path
-- there naturally. We never call Stop() (that was the stutter) and only re-issue every 0.3s to keep
-- the direction fresh and deny the player control. Acting is blocked via data-driven silence/disarm.
function modifier_cu_alter_fear:Flee()
	if not IsServer() then return end
	local parent = self:GetParent()
	if not IsNotNull(self.caster) or not IsNotNull(parent) then return end

	local away = parent:GetAbsOrigin() - self.caster:GetAbsOrigin()
	away.z = 0
	if away:Length2D() < 1 then away = RandomVector(1) end
	away = away:Normalized()

	giveUnitDataDrivenModifier(self.caster, parent, "silenced", 0.4)
	giveUnitDataDrivenModifier(self.caster, parent, "disarmed", 0.4)

	ExecuteOrderFromTable({
		UnitIndex = parent:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position  = parent:GetAbsOrigin() + away * 600,
		Queue     = false,
	})
end

function modifier_cu_alter_fear:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_cu_alter_fear:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
