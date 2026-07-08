-- R : Spear of the Sky
-- Cú Chulainn Alter hurls his spear high into the sky. After a delay it crashes down at the
-- targeted point, damaging (+ % of his max health) and stunning all enemies in the impact radius.
-- Cast WITHOUT War Cry active: he also self-stuns, takes non-lethal self damage and gets spears.
-- Cast under War Cry (modifier_cu_alter_warcry_buff): none of that self-cost happens.

cu_alter_spear_of_the_sky = cu_alter_spear_of_the_sky or class({})

-- spears erupting from a unit (render-model particle, see cu_alter_battle_stance.lua)
local function SpearsBurstOn(unit, fwd, lifetime)
	local fx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_spears_burst.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
	ParticleManager:SetParticleControl(fx, 0, unit:GetAbsOrigin() + Vector(0, 0, 80))
	ParticleManager:SetParticleControlForward(fx, 0, fwd)
	Timers:CreateTimer(lifetime, function()
		ParticleManager:DestroyParticle(fx, true)	-- immediate: the model has its own long life, so tie duration here
		ParticleManager:ReleaseParticleIndex(fx)
	end)
end

-- Throw animation played from the cast phase (Karna-style) so it isn't started twice.
function cu_alter_spear_of_the_sky:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function cu_alter_spear_of_the_sky:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	EmitGlobalSound("cu_alter_vo_sky")	-- "This will be a massacre." (global — everyone hears it)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.3, activity = ACT_DOTA_CAST_ABILITY_6, rate = 1.0 })
	return true
end

function cu_alter_spear_of_the_sky:OnAbilityPhaseInterrupted()
	EndAnimation(self:GetCaster())
end

function cu_alter_spear_of_the_sky:OnSpellStart()
	local caster = self:GetCaster()
	local point  = self:GetCursorPosition()

	local delay  = self:GetSpecialValueFor("delay")
	local radius = self:GetSpecialValueFor("radius")

	-- horizontal direction from Cú Chulainn toward the target point
	local hdir = point - caster:GetAbsOrigin()
	hdir.z = 0
	if hdir:Length2D() < 1 then hdir = caster:GetForwardVector() end
	hdir = hdir:Normalized()

	-- hide the spear on the model while it is up in the sky (restored on impact)
	caster:SetBodygroup(0, 2)
	caster:EmitSound("Hero_Mars.Spear.Cast")	-- spear hurl (Dota Mars spear throw)

	-- the spear is hurled forward-and-up out of Cú Chulainn (self-flying model particle)
	local upFx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_spear_proj.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(upFx, 0, caster:GetAbsOrigin() + Vector(0, 0, 100))
	ParticleManager:SetParticleControl(upFx, 1, (hdir + Vector(0, 0, 2.2)):Normalized() * 3600)
	Timers:CreateTimer(0.6, function()
		ParticleManager:DestroyParticle(upFx, true)
		ParticleManager:ReleaseParticleIndex(upFx)
	end)

	-- Self cost, unless cast under War Cry.
	if not caster:HasModifier("modifier_cu_alter_warcry_buff") then
		caster:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("self_stun_duration") })
		SpearsBurstOn(caster, caster:GetForwardVector(), self:GetSpecialValueFor("self_stun_duration"))

		-- non-lethal self damage: capped so it can never drop him below 1 HP
		local selfDmg = caster:GetMaxHealth() * self:GetSpecialValueFor("self_damage_pct") / 100
		selfDmg = math.min(selfDmg, caster:GetHealth() - 1)
		if selfDmg > 0 then
			DoDamage(caster, caster, selfDmg, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_NON_LETHAL, self, false)
		end
	end

	-- Landing ring: allies see it the whole time (blue); enemies only in the last 1s (red).
	self.allyRing = ParticleManager:CreateParticleForTeam("particles/zlodemon/zlodemon_basic_circle.vpcf", PATTACH_WORLDORIGIN, nil, caster:GetTeamNumber())
	ParticleManager:SetParticleControl(self.allyRing, 0, point)
	ParticleManager:SetParticleControl(self.allyRing, 1, Vector(1.0, 0.25, 0.5))	-- pink
	ParticleManager:SetParticleControl(self.allyRing, 2, Vector(radius, delay, 0))

	Timers:CreateTimer(math.max(delay - 1, 0), function()
		self.enemyRing = ParticleManager:CreateParticleForTeam("particles/zlodemon/zlodemon_basic_circle.vpcf", PATTACH_WORLDORIGIN, nil, caster:GetOpposingTeamNumber())
		ParticleManager:SetParticleControl(self.enemyRing, 0, point)
		ParticleManager:SetParticleControl(self.enemyRing, 1, Vector(1, 0.1, 0.1))
		ParticleManager:SetParticleControl(self.enemyRing, 2, Vector(radius, 1, 0))
	end)

	-- reveal the landing spot while the spear is airborne
	AddFOWViewer(caster:GetTeamNumber(), point, self:GetSpecialValueFor("vision_radius"), delay + 0.5, false)

	-- the falling spear RAKES in at a sharp, shallow (acute) angle — a slanted diving strike, not a
	-- vertical drop — and very fast, timed so it hits the ground right as the spear lands.
	Timers:CreateTimer(math.max(delay - 0.15, 0), function()
		local spawn = point - hdir * 1700 + Vector(0, 0, 950)	-- low, raking approach (~29° from the ground)
		local downFx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_spear_proj.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(downFx, 0, spawn)
		ParticleManager:SetParticleControl(downFx, 1, (point - spawn):Normalized() * 13000)	-- fast
		Timers:CreateTimer(0.4, function()
			ParticleManager:DestroyParticle(downFx, true)
			ParticleManager:ReleaseParticleIndex(downFx)
		end)
	end)

	Timers:CreateTimer(delay, function()
		if self.allyRing then
			ParticleManager:DestroyParticle(self.allyRing, true)
			ParticleManager:ReleaseParticleIndex(self.allyRing)
			self.allyRing = nil
		end
		if self.enemyRing then
			ParticleManager:DestroyParticle(self.enemyRing, true)
			ParticleManager:ReleaseParticleIndex(self.enemyRing)
			self.enemyRing = nil
		end
		self:Impact(point)
	end)
end

function cu_alter_spear_of_the_sky:Impact(point)
	local caster = self:GetCaster()

	-- spear returns to the model (guarded: if the combo has taken over the model, keep its armour
	-- bodygroup — otherwise this delayed restore would revert the combo form, see the R→combo fix)
	if IsNotNull(caster) and not caster:HasModifier("modifier_cu_alter_combo") then caster:SetBodygroup(0, 0) end

	EmitSoundOnLocationWithCaster(point, "cu_alter_sfx_explosion", caster)	-- crashing blast
	-- classic red/orange fiery crash
	local impactFx = ParticleManager:CreateParticle("particles/custom/lancer/lancer_gae_bolg_hit.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(impactFx, 0, point)
	ParticleManager:SetParticleControl(impactFx, 1, point)

	-- dark explosion sphere (darkened copy of caladbolg_explosion)
	local blastFx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_r_explosion.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(blastFx, 0, point)
	ParticleManager:SetParticleControl(blastFx, 1, point)
	ParticleManager:SetParticleControl(blastFx, 3, point)
	Timers:CreateTimer(3.0, function()
		ParticleManager:DestroyParticle(blastFx, false)
		ParticleManager:ReleaseParticleIndex(blastFx)
	end)
	Timers:CreateTimer(3.0, function()
		ParticleManager:DestroyParticle(impactFx, false)
		ParticleManager:ReleaseParticleIndex(impactFx)
	end)

	local damage = self:GetSpecialValueFor("damage") + self:GetCaster():GetStrength() * 2.5 * (caster.CuAlterAttr2Acquired and 1 or 0)
		+ caster:GetMaxHealth() * self:GetSpecialValueFor("bonus_max_hp_damage_pct") / 100

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		point,
		nil,
		self:GetSpecialValueFor("radius"),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false)

	for _, enemy in pairs(enemies) do
		if IsNotNull(enemy) then
			DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			enemy:AddNewModifier(caster, self, "modifier_muted", { duration = self:GetSpecialValueFor("stun_duration") })
		end
	end
end
