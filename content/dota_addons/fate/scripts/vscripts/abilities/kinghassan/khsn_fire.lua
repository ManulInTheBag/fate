LinkLuaModifier("modifier_khsn_flame", "abilities/kinghassan/khsn_fire", LUA_MODIFIER_MOTION_NONE)

khsn_flame = class({})

function khsn_flame:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local damage = self:GetSpecialValueFor("main_damage")

	local direction = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()

	local width_start = self:GetSpecialValueFor("flame_width_start")
	local width_end   = self:GetSpecialValueFor("flame_width_end")
	local speed       = self:GetSpecialValueFor("flame_speed")
	local distance = self:GetSpecialValueFor("distance")

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
		
	ProjectileManager:CreateLinearProjectile(flame_projectile)

	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	target:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})
	EmitSoundOn("Hero_SkeletonKing.Hellfire_BlastImpact", caster)
	EmitSoundOn("Hero_DragonKnight.BreathFire", caster)
end
function khsn_flame:OnProjectileHit(hTarget, vLocation)
	if not hTarget then
		return nil
	end
	local duration 	= self:GetSpecialValueFor("flame_duration")

	hTarget:AddNewModifier(self:GetCaster(), self, "modifier_khsn_flame", {duration = duration})
end

modifier_khsn_flame = class({})

function modifier_khsn_flame:IsHidden() return false end
function modifier_khsn_flame:IsDebuff() return true end
function modifier_khsn_flame:RemoveOnDeath() return true end
function modifier_khsn_flame:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_khsn_flame:OnCreated()
	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()

	if IsServer() then
		self.flame_damage_interval 	= 0.1
		self.flame_damage_second 	= self.ability:GetSpecialValueFor("damage_per_second") * self.flame_damage_interval

		local burn_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_skeletonking/skeletonking_hellfireblast_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		
		self:AddParticle(burn_fx, false, false, -1, false, false)

		self:StartIntervalThink(self.flame_damage_interval)
	end
end
function modifier_khsn_flame:OnIntervalThink()
	if IsServer() then
		local multiplier = (self.parent:HasModifier("modifier_khsn_flame_ch") and self.parent:FindModifierByName("modifier_khsn_flame_ch"):GetStackCount() or 1)
		DoDamage(self.caster, self.parent, self.flame_damage_second*multiplier, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
		--[[if self.caster.FlameAcquired then
			DoDamage(self.caster, self.parent, self.parent:GetMaxHealth()*0.07*self.flame_damage_interval, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
		end]]
	end
end