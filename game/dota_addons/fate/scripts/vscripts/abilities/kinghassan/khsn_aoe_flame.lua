LinkLuaModifier("modifier_khsn_aoe_flame", "abilities/kinghassan/khsn_aoe_flame", LUA_MODIFIER_MOTION_NONE)

khsn_aoe_flame = class({})
 
function khsn_aoe_flame:GetCastRange( vLocation, hTarget)
	return self:GetSpecialValueFor("radius")
end

function khsn_aoe_flame:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local aoe_lastspike = self:GetSpecialValueFor("aoe_lastspike")
	local damage_per_tick = (self:GetSpecialValueFor("damage_burn") + (caster.AzraelAcquired and 150 or 0))/15
	local damage_first = self:GetSpecialValueFor("damage_first")
	local hitcounter = 1
	local duration 	= self:GetSpecialValueFor("flame_duration")

	self.PI5 = FxCreator("particles/kinghassan/khsn_flame_aoe_swirl.vpcf",PATTACH_ABSORIGIN_FOLLOW,caster,0,nil)
	ParticleManager:SetParticleControlEnt(self.PI5, 5, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), false)
	ParticleManager:SetParticleControlEnt(self.PI5, 2, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), false)
	ParticleManager:SetParticleControlEnt(self.PI5, 7, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), false)

	local particle2 = ParticleManager:CreateParticle("particles/kinghassan/khsn_aoe_flame_magnetic_ring.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle2, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle2, 1, Vector(radius, radius, radius))

	Timers:CreateTimer(1.6, function()
		ParticleManager:DestroyParticle(particle2, false)
		ParticleManager:ReleaseParticleIndex(particle2)
	end)

	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 1.66)
	StartAnimation(caster, {duration = 2.4, activity = ACT_DOTA_CAST_ABILITY_4_END, rate = 0.5 })

	Timers:CreateTimer(0, function()
		if caster:IsAlive() then
			if hitcounter == 16 then
				self.TargetsHit = {}
				
				FxDestroyer(self.PI5, false)

        		caster:EmitSound("Hero_OgreMagi.Bloodlust.Cast")
				ScreenShake(caster:GetOrigin(), 7, 1.0, 2, 1500, 0, true)

				local direction = caster:GetForwardVector()

				local width_start = 100
				local width_end   = 325
				local speed       = 1050
				local distance = self:GetSpecialValueFor("radius_last")

				local point = caster:GetAbsOrigin() + caster:GetForwardVector()*distance

				local flame_projectile = {	Ability				= self,
												EffectName			= "particles/kinghassan/khsn_flame.vpcf",
												vSpawnOrigin		= caster:GetAbsOrigin(),
												fDistance			= distance,
												fStartRadius		= width_start,
												fEndRadius			= width_end,
												Source				= caster,
												bHasFrontalCone		= false,
												bReplaceExisting	= false,
												iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
												iUnitTargetFlags 	= DOTA_UNIT_TARGET_FLAG_NONE,
												iUnitTargetType		= DOTA_UNIT_TARGET_ALL,
												fExpireTime 		= GameRules:GetGameTime() + 10.0,
												bDeleteOnHit		= false,
												vVelocity			= Vector(direction.x,direction.y,0) * speed,
												bProvidesVision		= false }

				EmitSoundOn("Hero_SkeletonKing.Hellfire_BlastImpact", caster)
				EmitSoundOn("Hero_DragonKnight.BreathFire", caster)

				local qangle_rotation_rate = 40
				for i = 1, 9 do
				  	local qangle = QAngle(0, qangle_rotation_rate, 0)
				 	point = RotatePosition(caster:GetAbsOrigin(), qangle, point)

					local direction   = (point - caster:GetAbsOrigin()):Normalized()

					flame_projectile.vSpawnOrigin = caster:GetAbsOrigin() + direction * 125
					flame_projectile.vVelocity = Vector(direction.x,direction.y,0) * speed

					ProjectileManager:CreateLinearProjectile(flame_projectile)
				end
			else
				if hitcounter == 1 then
					EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_SkeletonKing.Hellfire_BlastImpact", caster)
				end
				local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
				for k,v in pairs(targets) do
					v:AddNewModifier(caster, self, "modifier_khsn_aoe_flame", {duration = duration})
					DoDamage(caster, v, damage_per_tick, DAMAGE_TYPE_MAGICAL, 0, self, false)
					giveUnitDataDrivenModifier(caster, v, "locked", 0.2)
					--v:AddNewModifier(caster, v, "modifier_stunned", { Duration = 0.4 })

					if hitcounter == 1 then
						DoDamage(caster, v, damage_first, DAMAGE_TYPE_MAGICAL, 0, self, false)

						local point = v:GetAbsOrigin()
						local projectile = CreateUnitByName("dummy_unit", point, false, caster, caster, caster:GetTeamNumber())
						projectile:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
						projectile:SetAbsOrigin(point)
						projectile:SetForwardVector(v:GetForwardVector())

						local burn_fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_shadowraze.vpcf", PATTACH_ABSORIGIN, projectile)
						ParticleManager:SetParticleControl(burn_fx, 0, point)

						EmitSoundOnLocationWithCaster(point, "Hero_SkeletonKing.Hellfire_BlastImpact", caster)

						local flame_fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_flame_kappa.vpcf", PATTACH_ABSORIGIN, projectile)
						ParticleManager:SetParticleControl(flame_fx, 0, point)
						ParticleManager:SetParticleControl(flame_fx, 1, Vector(0, 0, 1000))
					end
				end
				hitcounter = hitcounter + 1
				return 0.1
			end
		else
			FxDestroyer(self.PI4, false)
			FxDestroyer(self.PI5, false)
			return nil
		end
	end)
end

function khsn_aoe_flame:OnProjectileHit(hTarget, vLocation)
	if not hTarget then
		return nil
	end
	if self.TargetsHit[hTarget:entindex()] then return end
	local caster = self:GetCaster()
	local duration 	= self:GetSpecialValueFor("flame_duration")
	local damage = self:GetSpecialValueFor("damage_last") + (caster.AzraelAcquired and 200 or 0)
	
	self.TargetsHit[hTarget:entindex()] = true

	hTarget:AddNewModifier(caster, self, "modifier_khsn_aoe_flame", {duration = duration})
	DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
end

------

modifier_khsn_aoe_flame = class({})

function modifier_khsn_aoe_flame:DeclareFunctions()
	return {	MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE	}
end
function modifier_khsn_aoe_flame:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_percentage")
end

function modifier_khsn_aoe_flame:GetModifierProvidesFOWVision()
	if (not self:GetCaster().AzraelAcquired) or self:GetParent():HasModifier("modifier_murderer_mist_in") then
		return 0
	end
    return 1
end

function modifier_khsn_aoe_flame:OnTakeDamage(args)
	if not self:GetCaster().AzraelAcquired then return end
	if not args.attacker == self:GetCaster() then return end
	if args.inflictor == self:GetAbility() then return end

	self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_khsn_aoe_flame", {duration = self:GetAbility():GetSpecialValueFor("flame_duration")})
end

function modifier_khsn_aoe_flame:IsHidden() return false end
function modifier_khsn_aoe_flame:IsDebuff() return true end
function modifier_khsn_aoe_flame:RemoveOnDeath() return true end
function modifier_khsn_aoe_flame:OnCreated()
	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()

	if IsServer() then
		self.flame_damage_interval 	= 0.1
		self.flame_damage_second 	= self.ability:GetSpecialValueFor("flame_damage_per_second") * self.flame_damage_interval

		local burn_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_skeletonking/skeletonking_hellfireblast_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		
		self:AddParticle(burn_fx, false, false, -1, false, false)

		self:StartIntervalThink(self.flame_damage_interval)
	end
end
function modifier_khsn_aoe_flame:OnIntervalThink()
	if IsServer() then
		DoDamage(self.caster, self.parent, self.flame_damage_second, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
	end
end