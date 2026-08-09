-- W : Spear Throw
-- Cú Chulainn Alter charges his spear. While charging he can turn the model to aim.
-- Recasting (or reaching max charge) releases a piercing spear in the facing direction.
-- The longer it is charged, the further it flies and the more damage it deals.
-- On hit: damage + slow + heal reduction (see modifier_heal_reduction_tier_* in
-- modifiers/modifier_heal_reduction.lua).
--
-- Structure mirrors emiya_caladbolg (charge modifier + hidden release ability swap).

cu_alter_spear_throw = cu_alter_spear_throw or class({})

-- ACT_DOTA_CAST_ABILITY_8/9 are bound in the model but VScript only exposes _1.._7 as globals.
-- They are consecutive in the engine enum, so derive the numeric values from _7.
ACT_DOTA_CAST_ABILITY_8 = ACT_DOTA_CAST_ABILITY_8 or (ACT_DOTA_CAST_ABILITY_7 and ACT_DOTA_CAST_ABILITY_7 + 1)
ACT_DOTA_CAST_ABILITY_9 = ACT_DOTA_CAST_ABILITY_9 or (ACT_DOTA_CAST_ABILITY_7 and ACT_DOTA_CAST_ABILITY_7 + 2)

LinkLuaModifier("modifier_cu_alter_spear_charge",   "abilities/cu_alter/cu_alter_spear_throw", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cu_alter_spear_throwlock", "abilities/cu_alter/cu_alter_spear_throw", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cu_alter_spear_slow",   "abilities/cu_alter/cu_alter_spear_throw", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cu_alter_sealed_fate",  "abilities/cu_alter/cu_alter_spear_throw", LUA_MODIFIER_MOTION_NONE)
-- shared heal-reduction debuff (see modifiers/modifier_heal_reduction.lua); link the tiers this ability can apply
LinkLuaModifier("modifier_heal_reduction_tier_1", "modifiers/modifier_heal_reduction", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heal_reduction_tier_2", "modifiers/modifier_heal_reduction", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heal_reduction_tier_3_uncleansable", "modifiers/modifier_heal_reduction", LUA_MODIFIER_MOTION_NONE)
-- shared reveal modifier (follows the unit, provides FoW vision to the caster's team)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

-- Shared "gather" knockback: shove `unit` toward `gatherPoint` (used by Q and W to collect everyone
-- struck onto the spear). modifier_knockback pushes AWAY from center, so we place the center just
-- behind the unit relative to the gather point and set the distance to reach it. Guarded so it's
-- defined regardless of which file loads first.
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

function cu_alter_spear_throw:GetAOERadius()
	return self:GetSpecialValueFor("max_range")
end

local W_SLOT_INDEX = 1 -- Ability2 (0-based)
local Q_SLOT_INDEX = 0
-- keep the hidden release ability at the same level as the main ability
function cu_alter_spear_throw:OnUpgrade()
	local caster = self:GetCaster()
	local release = caster:FindAbilityByName("cu_alter_spear_throw_release")
	if release and release:GetLevel() ~= self:GetLevel() then
		release:SetLevel(self:GetLevel())
	end
end

function cu_alter_spear_throw:OnSpellStart()
	if self.isCharging then return end

	local caster = self:GetCaster()
	self.isCharging = true
	self.startTime  = GameRules:GetGameTime()
	self.maxtime    = self:GetSpecialValueFor("max_channel")

	--caster:EmitSound("cu_alter_spear_charge")
	StartAnimation(caster, { duration = self.maxtime + 0.3, activity = ACT_DOTA_CAST_ABILITY_2, rate = 1.0 })

	caster:AddNewModifier(caster, self, "modifier_cu_alter_spear_charge", { duration = self.maxtime })

	--self.chargeFx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_spear_charge.vpcf", PATTACH_POINT_FOLLOW, caster)

	-- reveal the release ability shortly after so the player can fire early
	Timers:CreateTimer(0.3, function()
		if caster:GetAbilityByIndex(W_SLOT_INDEX) and caster:GetAbilityByIndex(W_SLOT_INDEX):GetName() == "cu_alter_spear_throw" and caster:HasModifier("modifier_cu_alter_spear_charge") then
			caster:SwapAbilities("cu_alter_spear_throw", "cu_alter_spear_throw_release", false, true)
		end
		if caster:GetAbilityByIndex(Q_SLOT_INDEX) and caster:GetAbilityByIndex(Q_SLOT_INDEX):GetName() == "cu_alter_charge" and caster:HasModifier("modifier_cu_alter_spear_charge") then
			caster:SwapAbilities("cu_alter_charge", "cu_alter_spear_throw_release_no_knockback", false, true)
		end
	end)
end

-- Fires the spear. Called from the charge modifier's OnDestroy (early release / max charge / interrupt).
function cu_alter_spear_throw:Release(shouldKnockback)
	local caster = self:GetCaster()
	self.isCharging = false

	-- throw animation (separate from the charge/preparation animation)
	EndAnimation(caster)
	StartAnimation(caster, { duration = 0.5, activity = ACT_DOTA_CAST_ABILITY_8, rate = 1.0 })
	caster:EmitSound("Hero_Mars.Spear.Cast")	-- spear hurl (Dota Mars spear throw)

	-- rooted for the throwing motion so he can't slide around while the animation plays
	caster:AddNewModifier(caster, self, "modifier_cu_alter_spear_throwlock", { duration = 0.2 })

	if self.chargeFx then
		ParticleManager:DestroyParticle(self.chargeFx, true)
		ParticleManager:ReleaseParticleIndex(self.chargeFx)
		self.chargeFx = nil
	end

	-- restore the ability layout
	if caster:GetAbilityByIndex(W_SLOT_INDEX) and caster:GetAbilityByIndex(W_SLOT_INDEX):GetName() == "cu_alter_spear_throw_release" then
		caster:SwapAbilities("cu_alter_spear_throw", "cu_alter_spear_throw_release", true, false)
	end
	if caster:GetAbilityByIndex(Q_SLOT_INDEX) and caster:GetAbilityByIndex(Q_SLOT_INDEX):GetName() == "cu_alter_spear_throw_release_no_knockback" then
		caster:SwapAbilities("cu_alter_charge", "cu_alter_spear_throw_release_no_knockback", true, false)
	end

	-- Empowerment / aim captured NOW (at release), while he is still facing his charge direction.
	local elapsed = math.min(GameRules:GetGameTime() - (self.startTime or 0), self.maxtime)
	local frac    = self.maxtime > 0 and (elapsed / self.maxtime) or 1
	local minR    = self:GetSpecialValueFor("min_range")
	local maxR    = self:GetSpecialValueFor("max_range")
	local range   = minR + (maxR - minR) * frac
	-- damage scales from 50% (instant) to 100% (fully charged)
	self.releaseDamage = self:GetSpecialValueFor("damage") * (0.5 + 0.5 * frac) + self:GetCaster():GetStrength() * 1.5 * (caster.CuAlterAttr2Acquired and 1 or 0)

	local dir   = caster:GetForwardVector()
	local speed = self:GetSpecialValueFor("speed")
	self.throwDir = dir

	-- Post-cast delay: the spear actually leaves only after the throwing motion plays out.
	local delay = self:GetSpecialValueFor("release_delay") or 0
	Timers:CreateTimer(delay, function()
		if not IsNotNull(caster) then return end

		-- hide the spear on the model while it is in flight (guarded: never clobber the combo's armour
		-- bodygroup — see the R→combo fix). bodygroup "cuArmor": 0=noArmor(with spear), 1=armor, 2=noArmorNoSpear
		if not caster:HasModifier("modifier_cu_alter_combo") then
			caster:SetBodygroup(0, 2)
			Timers:CreateTimer(0.3, function()
				if IsNotNull(caster) and not caster:HasModifier("modifier_cu_alter_combo") then caster:SetBodygroup(0, 0) end
			end)
		end

		-- Invisible linear projectile does the hit detection / range only (EffectName = "").
		local projectile = {
			EffectName        = "",
			Ability           = self,
			vSpawnOrigin      = caster:GetAbsOrigin() + Vector(0, 0, 90),
			vVelocity         = dir * speed,
			fDistance         = range,
			fStartRadius      = self:GetSpecialValueFor("radius"),
			fEndRadius        = self:GetSpecialValueFor("radius"),
			Source            = caster,
			bHasFrontalCone   = false,
			bReplaceExisting  = false,
			iUnitTargetTeam   = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetType   = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			iUnitTargetFlags  = DOTA_UNIT_TARGET_FLAG_NONE,
			bDeleteOnHit      = true,
			ExtraData = {ShouldKnockback = shouldKnockback}
		}
		self.iProjectile = ProjectileManager:CreateLinearProjectile(projectile)

		-- The spear model is a separate self-flying particle (gae_bolg_proj-style: CP1 = velocity),
		-- destroyed on hit or after its flight time. This is why it must NOT be the projectile's
		-- EffectName — otherwise it double-moves and never gets cleaned up.
		self.spearFx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_spear_proj.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(self.spearFx, 0, caster:GetAbsOrigin() + Vector(0, 0, 90))
		ParticleManager:SetParticleControl(self.spearFx, 1, dir * speed)

		Timers:CreateTimer(range / speed + 0.05, function()
			if self.spearFx then
				ParticleManager:DestroyParticle(self.spearFx, true)
				ParticleManager:ReleaseParticleIndex(self.spearFx)
				self.spearFx = nil
			end
		end)
	end)
end

function cu_alter_spear_throw:OnProjectileHit_ExtraData(target, location, data)
	-- stop the flying spear visual and the (invisible) projectile
	if self.spearFx then
		ParticleManager:DestroyParticle(self.spearFx, true)
		ParticleManager:ReleaseParticleIndex(self.spearFx)
		self.spearFx = nil
	end
	if self.iProjectile then
		Timers:CreateTimer(0.03, function() ProjectileManager:DestroyLinearProjectile(self.iProjectile) end)
	end

	if target == nil then return true end
	local caster = self:GetCaster()

	if target:HasModifier("modifier_protection_from_arrows_active") then return true end

	--DoDamage(caster, target, self.releaseDamage or self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)

	--target:AddNewModifier(caster, self, "modifier_cu_alter_spear_slow", { duration = self:GetSpecialValueFor("slow_duration") })

	-- reveal the pierced target to your team for a few seconds (the spear "stakes" them)
	target:AddNewModifier(caster, self, "modifier_vision_provider", { duration = self:GetSpecialValueFor("vision_duration") })

	-- attribute Cursed Gáe Bolg: uncleansable tier-3 heal reduction; otherwise the base tier
	if caster.CuAlterAttr2Acquired then
		target:AddNewModifier(caster, self, "modifier_heal_reduction_tier_3_uncleansable", { duration = self:GetSpecialValueFor("healres_duration") })
		-- Sealed Fate: reversed causality — the wound is already fatal. It detonates the instant the
		-- healing reduction wears off (same duration), or early if the target is driven low, amplified
		-- by every point of healing they soaked up while marked. Out-healing the curse feeds the blow.
		target:AddNewModifier(caster, self, "modifier_cu_alter_sealed_fate", { duration = self:GetSpecialValueFor("healres_duration") })
	else
		local tier = self:GetSpecialValueFor("healres_tier")
		target:AddNewModifier(caster, self, "modifier_heal_reduction_tier_" .. tier, { duration = self:GetSpecialValueFor("healres_duration") })
	end

	target:EmitSound("cu_alter_sfx_explosion_w")	-- spear impact
	local fwd = self.throwDir or caster:GetForwardVector()

	target:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration") })

	-- Small rectangular box behind the pierced target: everyone else in it takes the spear's damage +
	-- slow (not the single-target curse), and ALL of them are GATHERED onto the spear — shoved toward
	-- the impale point so they collect together on the pierced target. FindUnitsInLine gives the box.
	local gather = target:GetAbsOrigin() 
	local box = FindUnitsInLine(
		caster:GetTeamNumber(),
		gather - fwd * 40,
		gather + fwd * self:GetSpecialValueFor("aoe_length"),
		nil,
		self:GetSpecialValueFor("aoe_width"),
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE)
	for _, u in pairs(box) do
		if IsNotNull(u) then
			DoDamage(caster, u, self.releaseDamage or self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
			u:AddNewModifier(caster, self, "modifier_cu_alter_spear_slow", { duration = self:GetSpecialValueFor("slow_duration") })
			if data.ShouldKnockback == 1 then
				CuAlterGatherKnockback(caster, self, u, gather +fwd * 400, self:GetSpecialValueFor("push_duration"))
			end
		end
	end

	-- pierce reads as the thrown spear driving into the target along its flight direction
	CuAlterPierceFx(
		target:GetAbsOrigin() + Vector(0, 0, 130) - fwd * 80,
		target:GetAbsOrigin() + Vector(0, 0, 130),
		fwd)

	-- bloody explosion on the hit. NB: the erupting-spears burst is intentionally NOT played here —
	-- it is now the signature visual of the Sealed Fate curse (attribute), see modifier_cu_alter_sealed_fate.
	local blast = ParticleManager:CreateParticle("particles/custom/vlad/vlad_im_splash_blood.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	Timers:CreateTimer(2.0, function()
		ParticleManager:DestroyParticle(blast, false)
		ParticleManager:ReleaseParticleIndex(blast)
	end)

	return true
end

---------------------------------------------------------------------------------------------------
-- Release ability (hidden) : cancels the charge, which fires the spear.
cu_alter_spear_throw_release = cu_alter_spear_throw_release or class({})

function cu_alter_spear_throw_release:OnSpellStart()
	local caster = self:GetCaster()
	if IsNotNull(caster:FindModifierByName("modifier_cu_alter_spear_charge")) then
		caster:FindModifierByName("modifier_cu_alter_spear_charge").ShouldKnockback = true
	end
	caster:RemoveModifierByName("modifier_cu_alter_spear_charge")
end

cu_alter_spear_throw_release_no_knockback = cu_alter_spear_throw_release_no_knockback or class({})

function cu_alter_spear_throw_release_no_knockback:OnSpellStart()
	local caster = self:GetCaster()
	if IsNotNull(caster:FindModifierByName("modifier_cu_alter_spear_charge")) then
		caster:FindModifierByName("modifier_cu_alter_spear_charge").ShouldKnockback = false
	end
	caster:RemoveModifierByName("modifier_cu_alter_spear_charge")
end


---------------------------------------------------------------------------------------------------
-- Charge modifier : roots the caster (he can still turn to aim); firing happens on destroy.
modifier_cu_alter_spear_charge = modifier_cu_alter_spear_charge or class({})

function modifier_cu_alter_spear_charge:IsHidden()      return false end
function modifier_cu_alter_spear_charge:IsDebuff()      return false end
function modifier_cu_alter_spear_charge:IsPurgable()    return false end
function modifier_cu_alter_spear_charge:RemoveOnDeath() return true end

-- Rooted (can still turn to aim) and silenced so no other ability can be used while charging.
-- The release ability has DOTA_ABILITY_BEHAVIOR_IGNORE_SILENCE, so recasting W still works.
function modifier_cu_alter_spear_charge:CheckState()
	return {
		[MODIFIER_STATE_ROOTED]   = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		-- flying-for-pathing so turning to aim is smooth and unhindered by ground pathing
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
	}
end

function modifier_cu_alter_spear_charge:OnCreated()
	self.caster  = self:GetCaster()
	self.ability = self:GetAbility()
	self.minR    = self.ability:GetSpecialValueFor("min_range")
	self.maxR    = self.ability:GetSpecialValueFor("max_range")
	self.ShouldKnockback = false
	if IsServer() then
		-- direction arrow (like Emiya's Caladbolg)
		self.arrowFx = ParticleManager:CreateParticleForPlayer("particles/muramasa/vector.vpcf", PATTACH_CUSTOMORIGIN, nil, self.caster:GetPlayerOwner())
		ParticleManager:SetParticleControl(self.arrowFx, 0, self.caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(self.arrowFx, 1, self.caster:GetAbsOrigin() + self.caster:GetForwardVector() * self.minR)
		ParticleManager:SetParticleControl(self.arrowFx, 4, Vector(255, 0, 0)) -- color
		self:StartIntervalThink(FrameTime())
	end
end

function modifier_cu_alter_spear_charge:OnIntervalThink()
	if not IsServer() then return end
	-- interrupt the charge if the caster gets stunned
	if self.caster:IsStunned() then
		self:Destroy()
		return
	end
	-- grow/point the arrow toward the current facing, scaled by how long it has charged
	local maxtime = self.ability.maxtime or self.ability:GetSpecialValueFor("max_channel")
	local frac    = math.min((GameRules:GetGameTime() - (self.ability.startTime or 0)) / maxtime, 1)
	local length  = self.minR + (self.maxR - self.minR) * frac
	ParticleManager:SetParticleControl(self.arrowFx, 0, self.caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(self.arrowFx, 1, self.caster:GetAbsOrigin() + self.caster:GetForwardVector() * length)
end

function modifier_cu_alter_spear_charge:OnDestroy()
	if IsServer() then
		if self.arrowFx then
			ParticleManager:DestroyParticle(self.arrowFx, true)
			ParticleManager:ReleaseParticleIndex(self.arrowFx)
			self.arrowFx = nil
		end
		self:GetAbility():Release(self.ShouldKnockback)
	end
end

---------------------------------------------------------------------------------------------------
-- Throw lock : roots Cú Chulainn for the throwing motion so he can't move while the animation plays.
-- Not a stun/silence — he simply can't reposition mid-hurl.
modifier_cu_alter_spear_throwlock = modifier_cu_alter_spear_throwlock or class({})

function modifier_cu_alter_spear_throwlock:IsHidden()      return true end
function modifier_cu_alter_spear_throwlock:IsDebuff()      return false end
function modifier_cu_alter_spear_throwlock:IsPurgable()    return false end
function modifier_cu_alter_spear_throwlock:RemoveOnDeath() return true end

function modifier_cu_alter_spear_throwlock:CheckState()
	return { [MODIFIER_STATE_ROOTED] = true }
end

---------------------------------------------------------------------------------------------------
-- Movement slow applied on spear hit. Registered in util.lua slowmodifier / cleansable.
modifier_cu_alter_spear_slow = modifier_cu_alter_spear_slow or class({})

function modifier_cu_alter_spear_slow:IsHidden()      return false end
function modifier_cu_alter_spear_slow:IsDebuff()      return true end
function modifier_cu_alter_spear_slow:RemoveOnDeath() return true end

function modifier_cu_alter_spear_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_cu_alter_spear_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_pct")
end

function modifier_cu_alter_spear_slow:GetEffectName()
	return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end

function modifier_cu_alter_spear_slow:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------
-- Sealed Fate (attribute Cursed Gáe Bolg): reversed cause and effect. The wound was always going to
-- reach the heart; the strike is only the delayed proof. When the mark ends (or the target is driven
-- below a health threshold) it detonates for a guaranteed burst, amplified by all the healing the
-- target received while marked. Uncleansable — the barbs cannot be pulled out. NOT registered in
-- util.lua cleansable (like the tier-3 uncleansable heal reduction it rides on).
modifier_cu_alter_sealed_fate = modifier_cu_alter_sealed_fate or class({})

function modifier_cu_alter_sealed_fate:IsHidden()      return false end
function modifier_cu_alter_sealed_fate:IsDebuff()      return true end
function modifier_cu_alter_sealed_fate:IsPurgable()    return false end
function modifier_cu_alter_sealed_fate:RemoveOnDeath() return true end

function modifier_cu_alter_sealed_fate:OnCreated()
	if not IsServer() then return end
	self.caster     = self:GetCaster()
	self.ability    = self:GetAbility()
	self.healed     = 0            -- healing the target soaks up while marked
	self.detonated  = false
	self.executePct = self.ability:GetSpecialValueFor("sf_execute_pct")
	-- the marked prey is revealed to your team for the whole duration of the curse
	self:GetParent():AddNewModifier(self.caster, self.ability, "modifier_vision_provider", { duration = self:GetDuration() })
	-- ongoing "open wound" trail while the curse sits on the target
	self.trailFx = ParticleManager:CreateParticle("particles/units/heroes/hero_bloodseeker/bloodseeker_rupture_trail.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	self:StartIntervalThink(0.25)
end

function modifier_cu_alter_sealed_fate:DeclareFunctions()
	return { MODIFIER_EVENT_ON_HEAL_RECEIVED }
end

function modifier_cu_alter_sealed_fate:OnHealReceived(args)
	if not IsServer() then return end
	local parent = self:GetParent()
	if args.unit ~= parent then return end
	-- count only healing that actually restores HP, never overheal. args.gain is the pre-clamp
	-- heal amount (this engine fires the event before HP is applied — see karna_armor), so clamp it
	-- to the room he had. A target at full HP getting healed contributes nothing to the detonation.
	local room      = parent:GetMaxHealth() - parent:GetHealth()
	local effective = math.max(0, math.min(args.gain or 0, room))
	self.healed = self.healed + effective
end

function modifier_cu_alter_sealed_fate:OnIntervalThink()
	if not IsServer() then return end
	local parent = self:GetParent()
	-- the wound reaches the heart early once he is driven low
	if IsNotNull(parent) and parent:IsAlive() and parent:GetHealthPercent() <= self.executePct then
		self:Detonate()
		self:Destroy() -- triggers OnDestroy -> Detonate again (guarded, no-op)
	end
end

function modifier_cu_alter_sealed_fate:OnDestroy()
	if not IsServer() then return end
	if self.trailFx then
		ParticleManager:DestroyParticle(self.trailFx, false)
		ParticleManager:ReleaseParticleIndex(self.trailFx)
		self.trailFx = nil
	end
	self:Detonate() -- fate always catches up when the mark ends
end

function modifier_cu_alter_sealed_fate:Detonate()
	if self.detonated then return end
	self.detonated = true

	local parent = self:GetParent()
	if not IsNotNull(parent) or not parent:IsAlive() then return end

	-- heal-derived damage is capped so a heavily-sustained target can't feed an unbounded strike
	local healDmg = math.min(
		self.healed * self.ability:GetSpecialValueFor("sf_heal_pct") / 100,
		self.ability:GetSpecialValueFor("sf_heal_dmg_cap"))
	local dmg = self.ability:GetSpecialValueFor("sf_base_damage") + healDmg
	DoDamage(self.caster, parent, dmg, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)

	parent:EmitSound("cu_alter_sfx_blood")	-- the wound tears open when Sealed Fate detonates
	local fx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_spears_burst.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(fx, 0, parent:GetAbsOrigin() + Vector(0, 0, 80))
	Timers:CreateTimer(0.75, function()
		ParticleManager:DestroyParticle(fx, false)
		ParticleManager:ReleaseParticleIndex(fx)
	end)
end
