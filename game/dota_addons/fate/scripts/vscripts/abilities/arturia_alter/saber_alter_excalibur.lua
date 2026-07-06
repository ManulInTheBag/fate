saber_alter_excalibur = class({})

LinkLuaModifier("modifier_morgan_slow", "abilities/arturia_alter/saber_alter_excalibur", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_excalibur_vfx", "abilities/arturia_alter/saber_alter_excalibur", LUA_MODIFIER_MOTION_NONE)

function saber_alter_excalibur:OnSpellStart()
	local caster = self:GetCaster()
	local speed = self:GetSpecialValueFor("speed")
	local width = self:GetSpecialValueFor("width")
	local range = self:GetSpecialValueFor("length") - width -- We need this to take end radius of projectile into account

	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 3)
	if caster:HasModifier("modifier_hero_selection_skin") then
		caster:SetBodygroup(0, 1)
	end
	EmitGlobalSound("Saber.Caliburn")
	caster:AddNewModifier(caster, self, "modifier_dark_excalibur_vfx", {duration = self:GetSpecialValueFor("pause_duration")})
	StartAnimation(caster, {duration = 3, activity = ACT_DOTA_CAST_ABILITY_4, rate = 1.35})
	local dex =
	{
		Ability = self,
		EffectName = "",
		iMoveSpeed = speed,
		vSpawnOrigin = nil,
		fDistance = range,
		fStartRadius = width,
		fEndRadius = width,
		Source = caster,
		bHasFrontalCone = true,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		fExpireTime = GameRules:GetGameTime() + 5.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * speed
	}

	Timers:CreateTimer(0, function()
		if caster:IsAlive() then
			EmitGlobalSound("Excalibur_Morgan")
		end
	end)

	Timers:CreateTimer(2, function()
		if caster:IsAlive() then
			dex.vSpawnOrigin = caster:GetAbsOrigin()
			dex.vVelocity = caster:GetForwardVector() * speed/0.3

			local counter = 10
			Timers:CreateTimer(0, function()
				counter = counter - 1
				if not caster:IsAlive() then return end
				ProjectileManager:CreateLinearProjectile(dex)
				if(counter == 0) then
					if caster:HasModifier("modifier_hero_selection_skin") then
						Timers:CreateTimer(0.2, function()
							caster:SetBodygroup(0, 0)
						end)
					end
					return
				end
				return 0.08
			end)
			ScreenShake(caster:GetOrigin(), 5, 0.1, 2, 20000, 0, true)
			AddFOWViewer(2,Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 200) + caster:GetForwardVector()*100, 10, 1, false)
			AddFOWViewer(3,Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 200) + caster:GetForwardVector()*100, 10, 1, false)
			local excalFxIndex = ParticleManager:CreateParticle("particles/saber_alter/saber_alter_excalibur_beam.vpcf", PATTACH_ABSORIGIN, caster)
			local pepega_end = GetGroundPosition(caster:GetAbsOrigin() + caster:GetForwardVector()*(range + width-100), caster)
			local pepega_vec = (pepega_end - caster:GetAbsOrigin()):Normalized()
			ParticleManager:SetParticleControl(excalFxIndex, 0, Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 200) + caster:GetForwardVector()*100)
			ParticleManager:SetParticleControl(excalFxIndex, 1, caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.0 + Vector(0, 0, 266))
			Timers:CreateTimer(0.8, function()
				ParticleManager:DestroyParticle( excalFxIndex, false )
				ParticleManager:ReleaseParticleIndex( excalFxIndex )
			end)
			Timers:CreateTimer(0.1, function()
				AddFOWViewer(2,caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.2 + Vector(0, 0, 266), 10, 1, false)
				AddFOWViewer(3,caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.2 + Vector(0, 0, 266), 10, 1, false)
				local excalpepegFxIndex = ParticleManager:CreateParticle("particles/saber_alter/saber_alter_excalibur_beam_pepeg.vpcf", PATTACH_ABSORIGIN, caster)
				ParticleManager:SetParticleControl(excalpepegFxIndex, 0, caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.2 + Vector(0, 0, 266))
				ParticleManager:SetParticleControl(excalpepegFxIndex, 1, pepega_end + Vector(0,0,400))
				Timers:CreateTimer(0.8, function()
					ParticleManager:DestroyParticle( excalpepegFxIndex, false )
					ParticleManager:ReleaseParticleIndex( excalpepegFxIndex )
				end)
			end)
		else
			caster:SetBodygroup(0, 0)
		end
	end)
end

function saber_alter_excalibur:OnProjectileHit(hTarget, vLocation)
	if not hTarget then return end
	local caster = self:GetCaster()
	local damagetotal = self:GetSpecialValueFor("damage") + self:GetSpecialValueFor("damagelvl") * caster:GetLevel()
	if caster.IsDarklightAcquired then
		damagetotal = damagetotal + caster:GetMaxMana()*(2.5)/100
	end
	if hTarget:GetUnitName() == "gille_gigantic_horror" then
		DoDamage(caster, hTarget, damagetotal*1.3, DAMAGE_TYPE_MAGICAL, 0, self, false)
	else
		DoDamage(caster, hTarget, damagetotal, DAMAGE_TYPE_MAGICAL, 0, self, false)
	end
	local hitFx = ParticleManager:CreateParticle("particles/custom/saber_alter/excalibur/hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget)
	ParticleManager:ReleaseParticleIndex(hitFx)
	hTarget:AddNewModifier(caster, self, "modifier_morgan_slow", {Duration = 1})
	giveUnitDataDrivenModifier(caster, hTarget, "locked", 1)
end

modifier_morgan_slow = class({})

function modifier_morgan_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_morgan_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_power")
end

function modifier_morgan_slow:IsHidden()
	return false
end

-- Cast VFX timeline (was a chain of 4 datadriven modifiers):
--   t=0.00: 3x sword charge glow (die at 1.05) + dark ground ring (dies at 2.1)
--   t=0.75: beam + sword overcharge + blackhole (die at 2.05)
-- All particles die with the modifier (death/dispel included).
modifier_dark_excalibur_vfx = class({})

function modifier_dark_excalibur_vfx:IsHidden()
	return true
end

function modifier_dark_excalibur_vfx:IsPurgable()
	return false
end

function modifier_dark_excalibur_vfx:OnCreated()
	if not IsServer() then return end
	local caster = self:GetParent()
	self.fxlist = {}

	local phase1 = {}
	for i=1,3 do
		local fx = ParticleManager:CreateParticle("particles/custom/saber_alter/saber_alter_excalibur_cast.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControlEnt(fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_sword", caster:GetAbsOrigin(), true)
		table.insert(phase1, fx)
		table.insert(self.fxlist, fx)
	end
	Timers:CreateTimer(1.05, function()
		if not self.destroyed then self:KillFx(phase1) end
	end)

	local phase3 = {}
	local ringFx = ParticleManager:CreateParticle("particles/econ/items/doom/doom_f2p_death_effect/doom_bringer_f2p_death_ring_d_black.vpcf", PATTACH_ABSORIGIN, caster)
	table.insert(phase3, ringFx)
	table.insert(self.fxlist, ringFx)
	Timers:CreateTimer(2.1, function()
		if not self.destroyed then self:KillFx(phase3) end
	end)

	Timers:CreateTimer(0.75, function()
		if self:IsNull() or self.destroyed then return end
		local phase2 = {}

		local beamFx = ParticleManager:CreateParticle("particles/custom/saber_alter/saber_alter_excalibur_beam.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		table.insert(phase2, beamFx)
		table.insert(self.fxlist, beamFx)

		local overchargeFx = ParticleManager:CreateParticle("particles/custom/saber_alter/saber_alter_excalibur_overcharge.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControlEnt(overchargeFx, 0, caster, PATTACH_POINT_FOLLOW, "attach_sword", caster:GetAbsOrigin(), true)
		table.insert(phase2, overchargeFx)
		table.insert(self.fxlist, overchargeFx)

		local blackholeFx = ParticleManager:CreateParticle("particles/units/heroes/hero_enigma/enigma_blackhole_n.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControlEnt(blackholeFx, 0, caster, PATTACH_POINT_FOLLOW, "attach_origin", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(blackholeFx, 1, caster, PATTACH_POINT_FOLLOW, "attach_origin", caster:GetAbsOrigin(), true)
		table.insert(phase2, blackholeFx)
		table.insert(self.fxlist, blackholeFx)

		Timers:CreateTimer(1.3, function()
			if not self.destroyed then self:KillFx(phase2) end
		end)
	end)
end

function modifier_dark_excalibur_vfx:KillFx(list)
	for _, fx in ipairs(list) do
		ParticleManager:DestroyParticle(fx, false)
		ParticleManager:ReleaseParticleIndex(fx)
		if self.fxlist then
			for i = #self.fxlist, 1, -1 do
				if self.fxlist[i] == fx then
					table.remove(self.fxlist, i)
				end
			end
		end
	end
end

function modifier_dark_excalibur_vfx:OnDestroy()
	if not IsServer() then return end
	self.destroyed = true
	local rest = self.fxlist
	self.fxlist = nil
	if rest then
		self:KillFx(rest)
	end
end
