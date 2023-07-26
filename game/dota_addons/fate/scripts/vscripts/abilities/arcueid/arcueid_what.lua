arcueid_what = class({})

function arcueid_what:OnSpellStart()
	local caster = self:GetCaster()
	local tpoint = self:GetCursorPosition()
  	local dir = tpoint - caster:GetAbsOrigin()
  	dir.z = 0
  	if not(tpoint == caster:GetAbsOrigin()) then
  		caster:SetForwardVector(dir:Normalized())
  	end
  	if self.active then
  		self:EndCooldown()
  		caster:GiveMana(200)
  		return
  	end
  	self.active = true
  	self.dir = dir:Normalized()
	local target = caster:GetForwardVector()
	local range = self:GetSpecialValueFor("range")

	local tProjectile = {
	    EffectName = nil,
	    Ability = self,
	    vSpawnOrigin = caster:GetAbsOrigin(),
	    vVelocity = target * 2250,
	    fDistance = range,
	    fStartRadius = 175,
	    fEndRadius = 175,
	    Source = caster,
	    bHasFrontalCone = false,
	    bReplaceExisting = false,
	    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
	    iUnitTargetType = DOTA_UNIT_TARGET_ALL,
	    --bProvidesVision = true,
	    bDeleteOnHit = false,
	    --iVisionRadius = 500,
	    --bFlyingVision = true,
	    --iVisionTeamNumber = caster:GetTeamNumber(),
	    ExtraData = {fDamage = fDamage}
  	}
 	self.iProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)

 	self.hook_particle = ParticleManager:CreateParticle("particles/arcueid/arcueid_hook.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(self.hook_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hand", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.hook_particle, 1, caster:GetAbsOrigin() + self.dir*150 + Vector(0, 0, 200))

	self.hitenemy = false
end

function arcueid_what:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	ParticleManager:DestroyParticle(self.hook_particle, false)
  	ParticleManager:ReleaseParticleIndex(self.hook_particle)
  	self.active = false
	if hTarget == nil or self.hitenemy then --ты можешь подумать что я насрал и если инстом кинуть два ножа можно словить баг, но ты его и так ловил, удаляя ласт нож если хитнул любой из них так что похуй
  		return
  	end
  	if (hTarget:GetName() == "npc_dota_ward_base") then
  		return
  	end
  	local hCaster = self:GetCaster()
  	
  	EmitSoundOn("arcueid_hit", hTarget)
	EmitSoundOn("Hero_PhantomAssassin.CoupDeGrace", hTarget)
	DoDamage(hCaster, hTarget, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)

	local smokeFx3 = ParticleManager:CreateParticle("particles/custom_game/heroes/kenshiro/kenshiro_pressure_points_explosion/kenshiro_pressure_points_explosion_blood.vpcf", PATTACH_CUSTOMORIGIN, hTarget)
	ParticleManager:SetParticleControl(smokeFx3, 0, hTarget:GetAbsOrigin())
	ParticleManager:DestroyParticle(smokeFx3, false)
	ParticleManager:ReleaseParticleIndex(smokeFx3)
	local effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_crit_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		hTarget,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		hTarget:GetOrigin(), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlTransformForward(effect_cast, 1, Vector(0,0,0), (hCaster:GetOrigin()-hTarget:GetOrigin()):Normalized())
	--ParticleManager:SetParticleControlForward( effect_cast, 1, (caster:GetOrigin()-self.source_enemy:GetOrigin()):Normalized() )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	local or_tar = hTarget:GetAbsOrigin()
	local or_en = hCaster:GetAbsOrigin()

	local distance = (or_tar - or_en):Length2D()

	local knockback = { should_stun = 1,
	        knockback_duration = 0.3,
		    duration = 0.3,
	        knockback_distance = -distance + 100,
	        knockback_height = 100 or 0,
	        center_x = or_en.x,
	        center_y = or_en.y,
	        center_z = or_en.z }

	hTarget:AddNewModifier(hCaster, self, "modifier_knockback", knockback)

    self.hitenemy = true
   	--Timers:CreateTimer(0.033,function()
   	ProjectileManager:DestroyLinearProjectile(self.iProjectile)
  	--end)
end

function arcueid_what:OnProjectileThink(location)
    local caster = self:GetCaster()
    local radius = 100
    local duration = 0.5

    AddFOWViewer(caster:GetTeamNumber(), location, radius, duration, false)
    AddFOWViewer(caster:GetOpposingTeamNumber(), location, 40, 0.6, false)

    ParticleManager:SetParticleControl(self.hook_particle, 1, location + self.dir*150 + Vector(0, 0, 200))
end