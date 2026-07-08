-- Combo : Rend of the Titan
-- One continuous animation (ACT_DOTA_CAST_ABILITY_ROT, 240 frames). Cú Chulainn Alter dons his
-- armour (bodygroup "cuArmor" choice 1) instead of the spear, roars, leaps forward, hacks in an
-- arc in front of him for a while, then delivers a final piercing blow that curses everyone hit.
--
-- The whole sequence is held and driven by a single modifier that:
--   * locks the caster (STUNNED) for the full length (uninterruptible except by death),
--   * plays the ROT animation via MODIFIER_PROPERTY_OVERRIDE_ANIMATION (crisp, no gesture delay),
--   * runs all gameplay events off its OnIntervalThink, timed to the animation's frames.
--
-- Frame layout of the 240-frame animation (at combo_fps, scaled by anim_rate):
--     0- 50  roar   (pure wind-up, no gameplay effect)
--    50- 80  jump   (leap forward by jump_distance, touchdown at frame 80)
--   100-180  hacks  (hack_ticks AoE hits: damage + mini-stun)
--       220  final  (single big AoE hit: damage + curse)
--       240  end    (release the lock, restore the model)

cu_alter_combo = cu_alter_combo or class({})
LinkLuaModifier("modifier_kb_immune", "abilities/zlodemon_nasral/modifier_kb_immune", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cu_alter_combo",    "abilities/cu_alter/cu_alter_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cu_alter_combo_cd", "abilities/cu_alter/cu_alter_combo", LUA_MODIFIER_MOTION_NONE)

-- Frame breakpoints of the ROT animation (tied to the animation, not balance knobs).
local FRAME_ROAR_END = 50
local FRAME_JUMP_END = 80	-- lands at frame 80 (matches the animation's touchdown)
local FRAME_HACK_END = 180
local FRAME_FINAL    = 220
local FRAME_TOTAL    = 240
-- hack cadence: slow, heavy single blows first (100..130), then a fast frenzy up to 180
local HACK_FRAMES    = { 100, 115, 130, 139, 147, 154, 161, 167, 173, 180 }

function cu_alter_combo:GetAOERadius()
	return self:GetSpecialValueFor("final_radius")
end

function cu_alter_combo:OnSpellStart()
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_cu_alter_combo") then return end

	-- point-target: aim the leap at the clicked point, capped to jump_distance. Face that way now,
	-- before the combo modifier locks him (STUNNED) — the modifier captures this facing.
	local point   = self:GetCursorPosition()
	local toPoint = point - caster:GetAbsOrigin()
	toPoint.z = 0
	self.comboJumpDistance = math.min(toPoint:Length2D(), self:GetSpecialValueFor("jump_distance"))
	if toPoint:Length2D() > 1 then
		caster:SetForwardVector(toPoint:Normalized())
	end

	local fps   = self:GetSpecialValueFor("combo_fps")
	local rate  = self:GetSpecialValueFor("anim_rate")
	local total = (FRAME_TOTAL / fps) / rate

	caster:AddNewModifier(caster, self, "modifier_cu_alter_combo", { duration = total })
	caster:AddNewModifier(caster,self, "modifier_kb_immune", {duration = total})
	EmitGlobalSound("cu_alter_vo_combo_start")	-- "Unleashing the curse..." (global)

	-- cooldown: mirror it onto the master copy (as other combos do) + a visible icon while hidden
	local masterCombo = caster.MasterUnit2 and caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
	if masterCombo then
		masterCombo:EndCooldown()
		masterCombo:StartCooldown(self:GetCooldown(self:GetLevel()))
	end
	caster:AddNewModifier(caster, self, "modifier_cu_alter_combo_cd", { duration = self:GetCooldown(self:GetLevel()) })
end

---------------------------------------------------------------------------------------------------
-- Driver modifier: lock + animation + timed gameplay events.
modifier_cu_alter_combo = modifier_cu_alter_combo or class({})

function modifier_cu_alter_combo:IsHidden()      return true end
function modifier_cu_alter_combo:IsDebuff()      return false end
function modifier_cu_alter_combo:IsPurgable()    return false end
function modifier_cu_alter_combo:RemoveOnDeath() return true end

-- Locked in place and unable to act for the whole combo (still killable = the risk).
function modifier_cu_alter_combo:CheckState()
	return {
		[MODIFIER_STATE_STUNNED]  = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
end

function modifier_cu_alter_combo:DeclareFunctions()
	return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
	         MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

-- committed but tough: once he leaps he takes reduced damage for the rest of the combo (okada-style)
function modifier_cu_alter_combo:GetModifierIncomingDamage_Percentage()
	if self.jumpStarted then
		return -self:GetAbility():GetSpecialValueFor("damage_reduction")
	end
	return 0
end
function modifier_cu_alter_combo:GetOverrideAnimation() return ACT_DOTA_CAST_ABILITY_ROT end
-- read from the ability (not self.rate) so the client, which never runs the server-only OnCreated
-- body, still renders at the right speed.
function modifier_cu_alter_combo:GetOverrideAnimationRate() return self:GetAbility():GetSpecialValueFor("anim_rate") end

function modifier_cu_alter_combo:OnCreated()
	if not IsServer() then return end
	self.caster  = self:GetCaster()
	self.ability = self:GetAbility()
	self.start   = GameRules:GetGameTime()
	self.fwd     = self.caster:GetForwardVector() -- facing is locked (STUNNED), capture once

	local fps  = self.ability:GetSpecialValueFor("combo_fps")
	self.rate  = self.ability:GetSpecialValueFor("anim_rate")
	local function T(frame) return (frame / fps) / self.rate end

	self.tJumpStart = T(FRAME_ROAR_END)   -- 50
	self.tJumpEnd   = T(FRAME_JUMP_END)   -- 80 (touchdown)
	self.tHackStart = T(FRAME_JUMP_END)   -- 80
	self.tHackEnd   = T(FRAME_HACK_END)   -- 180
	self.tFinal     = T(FRAME_FINAL)      -- 220

	self.hackTimes = {}
	for _, fr in ipairs(HACK_FRAMES) do self.hackTimes[#self.hackTimes + 1] = T(fr) end

	self.hacksFired  = 0
	self.jumpStarted = false
	self.jumpDone    = false
	self.finalDone   = false

	-- wear the armour (spear stowed) for the duration; bodygroup "cuArmor": 0=noArmor(+spear), 1=armor
	self.caster:SetBodygroup(0, 1)

	-- bloodlust aura while he prepares (the roar wind-up); removed the instant he leaps
	self.prepFx = ParticleManager:CreateParticle("particles/custom_game/heroes/hisoka/hisoka_bloodlust_release/hisoka_bloodlust_release.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster)
	Timers:CreateTimer(self.tJumpStart, function()
		if self.prepFx then
			ParticleManager:DestroyParticle(self.prepFx, false)
			ParticleManager:ReleaseParticleIndex(self.prepFx)
			self.prepFx = nil
		end
	end)

	self:StartIntervalThink(0.03)
end

function modifier_cu_alter_combo:OnIntervalThink()
	if not IsServer() then return end
	local caster  = self.caster
	if not IsNotNull(caster) then return end
	local elapsed = GameRules:GetGameTime() - self.start

	-- JUMP (frames 50-100): drive the caster forward, matching the animation's leap.
	if not self.jumpDone and elapsed >= self.tJumpStart then
		if not self.jumpStarted then
			self.jumpStarted = true
			self.jumpFrom    = caster:GetAbsOrigin()
			-- leap to the raw target, straight through any terrain in the way (FindClearSpaceForUnit on
			-- landing resolves the endpoint) — he vaults over walls/cliffs instead of stopping short.
			local jumpDist   = self.ability.comboJumpDistance or self.ability:GetSpecialValueFor("jump_distance")
			self.jumpTo      = self.jumpFrom + self.fwd * jumpDist
			-- crimson leap trail (same trail as the Q dash)
			self.jumpTrailFx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_dash_trail.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			caster:EmitSound("cu_alter_sfx_roar_weak")	-- roar as he launches into the air
		end
		local span = self.tJumpEnd - self.tJumpStart
		local t    = span > 0 and math.min((elapsed - self.tJumpStart) / span, 1) or 1
		-- SNAPPY leap: horizontal travel is front-loaded (explosive launch) so he SHOOTS forward and is
		-- basically over the landing spot by mid-flight.
		local f = 1 - (1 - t) * (1 - t) * (1 - t)   -- ease-out cubic
		-- Height = "superman slam": rise fast to the apex by mid-flight (short hang), then dive down with
		-- accelerating (gravity-like) speed and crash into the ground. Apex at t=0.5 keeps the hang brief.
		local h
		if t < 0.5 then
			h = math.sin((t / 0.5) * (math.pi / 2))   -- quick rise to the apex
		else
			local d = (t - 0.5) / 0.5
			h = 1 - d * d                              -- accelerating drop → hard landing
		end
		local pos = self.jumpFrom + (self.jumpTo - self.jumpFrom) * f
		pos.z = pos.z + self.ability:GetSpecialValueFor("jump_height") * h
		caster:SetAbsOrigin(pos)
		if t >= 1 then
			self.jumpDone = true
			if self.jumpTrailFx then
				ParticleManager:DestroyParticle(self.jumpTrailFx, false)
				ParticleManager:ReleaseParticleIndex(self.jumpTrailFx)
				self.jumpTrailFx = nil
			end
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
			self:Land()
		end
	end

	-- HACKS: ramped cadence — slow heavy blows (100-130) then a fast frenzy (to 180), per HACK_FRAMES.
	while self.hacksFired < #self.hackTimes and elapsed >= self.hackTimes[self.hacksFired + 1] do
		self:DoHack()
		self.hacksFired = self.hacksFired + 1
	end

	-- FINAL (frame 220): the piercing, cursing blow.
	if not self.finalDone and elapsed >= self.tFinal then
		self.finalDone = true
		self:DoFinal()
	end
end

-- Frontal AoE center, a little ahead of the caster along his (locked) facing.
function modifier_cu_alter_combo:FrontCenter()
	return self.caster:GetAbsOrigin() + self.fwd * self.ability:GetSpecialValueFor("forward_offset")
end

-- Landing of the leap (frame 100): the impact shakes the ground and stuns everyone nearby at once.
function modifier_cu_alter_combo:Land()
	local caster  = self.caster
	local ability = self.ability
	local pos     = caster:GetAbsOrigin()

	ScreenShake(pos, 12, 5, 0.7, 1600, 0, true)
	caster:EmitSound("maou_slam")	-- heavy landing thud

	-- ground-slam shockwave (recoloured maou slam). CP0 = impact point.
	local fx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_ground_slam.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fx, 0, pos)
	Timers:CreateTimer(2.5, function()
		ParticleManager:DestroyParticle(fx, false)
		ParticleManager:ReleaseParticleIndex(fx)
	end)

	-- crimson impact burst on landing (recoloured aoko intimidation impact)
	local impact = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_land_impact.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(impact, 0, pos)
	Timers:CreateTimer(2.5, function()
		ParticleManager:DestroyParticle(impact, false)
		ParticleManager:ReleaseParticleIndex(impact)
	end)

	-- radius ring at the strike zone, sized to the actual hack radius (where the repeated blows connect).
	-- Destroyed the instant the final blow lands (see DoFinal), so it doesn't linger past the hits.
	self.ringFx = ParticleManager:CreateParticle("particles/zlodemon/zlodemon_basic_circle.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.ringFx, 0, self:FrontCenter())
	ParticleManager:SetParticleControl(self.ringFx, 1, Vector(1, 0.1, 0.1))
	ParticleManager:SetParticleControl(self.ringFx, 2, Vector(ability:GetSpecialValueFor("hack_radius"), 5.0, 0))

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(), pos, nil,
		ability:GetSpecialValueFor("land_radius"),
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, e in pairs(enemies) do
		if IsNotNull(e) then
			e:AddNewModifier(caster, ability, "modifier_stunned", { duration = ability:GetSpecialValueFor("land_stun") })
			e:AddNewModifier(caster,ability, "modifier_kb_immune", {duration = 0.5})
		end
	end
end

function modifier_cu_alter_combo:DoHack()
	local caster  = self.caster
	local ability = self.ability
	local fast    = (self.hacksFired or 0) >= 3   -- after the 3 slow blows (frame 139+) = the frenzy

	caster:EmitSound((self.hacksFired or 0) % 2 == 0 and "cu_alter_sfx_slash1" or "cu_alter_sfx_slash2")	-- alternating slashes
	-- grunt every OTHER hit so the short clips don't overlap ("Kah!"/"Hmph!"/"There!")
	if (self.hacksFired or 0) % 2 == 0 then
		caster:EmitSound("cu_alter_vo_hack")
	end

	-- slashes in front, angled differently each hit (recoloured okada_random_slash_red). During the
	-- frenzy several land at once, scattered around, so it reads as a wild flurry.
	for i = 1, (fast and 3 or 1) do
		local at = self:FrontCenter() + RandomVector(RandomFloat(0, 200))
		local slashFx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_combo_slash.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(slashFx, 0, at)
		ParticleManager:SetParticleControlForward(slashFx, 0, RandomVector(1))
		Timers:CreateTimer(1.2, function()
			ParticleManager:DestroyParticle(slashFx, false)
			ParticleManager:ReleaseParticleIndex(slashFx)
		end)
	end

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		self:FrontCenter(),
		nil,
		ability:GetSpecialValueFor("hack_radius"),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false)
	for _, enemy in pairs(enemies) do
		if IsNotNull(enemy) then
			DoDamage(caster, enemy, ability:GetSpecialValueFor("hack_damage"), DAMAGE_TYPE_MAGICAL, 0, ability, false)
			enemy:AddNewModifier(caster, ability, "modifier_stunned", { duration = ability:GetSpecialValueFor("hack_stun") })
			enemy:AddNewModifier(caster,ability, "modifier_kb_immune", {duration = 0.5})
			-- juicy blood spray on every hit (okada combo blood, not identical spot each time)
			local blood = ParticleManager:CreateParticle("particles/okada/okada_combo_blood_mist.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
			ParticleManager:SetParticleControlForward(blood, 0, self.fwd)
			Timers:CreateTimer(2.0, function()
				ParticleManager:DestroyParticle(blood, false)
				ParticleManager:ReleaseParticleIndex(blood)
			end)
		end
	end
end

function modifier_cu_alter_combo:DoFinal()
	local caster  = self.caster
	local ability = self.ability
	EmitGlobalSound("cu_alter_vo_combo_shout")	-- "...Curruid Coinchenn!!" (global — everyone hears it)
	caster:EmitSound("cu_alter_sfx_pierce")	-- the Q piercing-blow SFX on the finisher

	-- the strike-zone ring has done its job — remove it the moment the final blow lands
	if self.ringFx then
		ParticleManager:DestroyParticle(self.ringFx, false)
		ParticleManager:ReleaseParticleIndex(self.ringFx)
		self.ringFx = nil
	end
	caster:EmitSound("okada_combo_blood")	-- juicy blood burst

	-- ground shockwave sized to read as the final AoE spread (matches final_radius). CP0 = strike centre.
	local slamFx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_ground_slam.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(slamFx, 0, self:FrontCenter())
	Timers:CreateTimer(2.5, function()
		ParticleManager:DestroyParticle(slamFx, false)
		ParticleManager:ReleaseParticleIndex(slamFx)
	end)

	-- big blood eruption on the finishing blow (gilles kraken), played AT the strike centre — a fixed
	-- world point (not attached to the hero, so it erupts where the blow actually lands).
	local center   = self:FrontCenter()
	local krakenFx = ParticleManager:CreateParticle("particles/gilles/new_combo/gilles_combo_kraken_2.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(krakenFx, 0, center)
	ParticleManager:SetParticleControl(krakenFx, 1, center)
	ParticleManager:SetParticleControlForward(krakenFx, 0, self.fwd)
	Timers:CreateTimer(3.0, function()
		ParticleManager:DestroyParticle(krakenFx, false)
		ParticleManager:ReleaseParticleIndex(krakenFx)
	end)

	-- the curse is sourced from Spear Throw so it reuses that ability's tuning (heal-reduction
	-- duration + Sealed Fate values). This delivers the full attribute-cursed effect regardless of
	-- whether Cursed Gáe Bolg has been unlocked.
	local w = caster:FindAbilityByName("cu_alter_spear_throw")
	caster:FindAbilityByName("cu_alter_warcry"):EndCooldown()
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		self:FrontCenter(),
		nil,
		ability:GetSpecialValueFor("final_radius"),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false)
	for _, enemy in pairs(enemies) do
		if IsNotNull(enemy) then
			DoDamage(caster, enemy, ability:GetSpecialValueFor("final_damage"), DAMAGE_TYPE_MAGICAL, 0, ability, false)
			enemy:AddNewModifier(caster, ability, "modifier_stunned", { duration = ability:GetSpecialValueFor("final_stun") })
			if w then
				enemy:AddNewModifier(caster, w, "modifier_heal_reduction_tier_3_uncleansable", { duration = w:GetSpecialValueFor("healres_duration") })
				enemy:AddNewModifier(caster, w, "modifier_cu_alter_sealed_fate", { duration = w:GetSpecialValueFor("healres_duration") })
			end

			-- spears erupt from inside each impaled target (same burst used by Battle Stance / Spear Throw)
			local spears = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_spears_burst.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
			ParticleManager:SetParticleControl(spears, 0, enemy:GetAbsOrigin() + Vector(0, 0, 80))
			ParticleManager:SetParticleControlForward(spears, 0, self.fwd)
			Timers:CreateTimer(0.5, function()
				ParticleManager:DestroyParticle(spears, false)
				ParticleManager:ReleaseParticleIndex(spears)
			end)
		end
	end
end

function modifier_cu_alter_combo:OnDestroy()
	if not IsServer() then return end
	if self.prepFx then
		ParticleManager:DestroyParticle(self.prepFx, false)
		ParticleManager:ReleaseParticleIndex(self.prepFx)
		self.prepFx = nil
	end
	if self.jumpTrailFx then
		ParticleManager:DestroyParticle(self.jumpTrailFx, false)
		ParticleManager:ReleaseParticleIndex(self.jumpTrailFx)
		self.jumpTrailFx = nil
	end
	if self.ringFx then
		ParticleManager:DestroyParticle(self.ringFx, false)
		ParticleManager:ReleaseParticleIndex(self.ringFx)
		self.ringFx = nil
	end
	if IsNotNull(self.caster) then
		-- restore the default model (spear back, no armour) and un-stick him
		self.caster:SetBodygroup(0, 0)
		FindClearSpaceForUnit(self.caster, self.caster:GetAbsOrigin(), true)
	end
end

---------------------------------------------------------------------------------------------------
-- Visible combo cooldown: the combo is hidden most of the time (swapped in only during the arm
-- window), so this persistent icon shows its cooldown. Mirrors modifier_okada_combo_cd.
modifier_cu_alter_combo_cd = modifier_cu_alter_combo_cd or class({})

function modifier_cu_alter_combo_cd:IsHidden()      return false end
function modifier_cu_alter_combo_cd:IsDebuff()      return true end
function modifier_cu_alter_combo_cd:IsPurgable()    return false end
function modifier_cu_alter_combo_cd:RemoveOnDeath() return false end

function modifier_cu_alter_combo_cd:GetTexture()
	return "custom/cu_alter/combo"
end

function modifier_cu_alter_combo_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
