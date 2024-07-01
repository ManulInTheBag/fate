hijikata_dash = class({})

LinkLuaModifier("modifier_hijikata_dash_recast_enable", "abilities/hijikata/hijikata_dash", LUA_MODIFIER_MOTION_NONE)

function hijikata_dash:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self
    
	if caster:FindAbilityByName("hijikata_dash_recast"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("hijikata_dash_recast"):SetLevel(self:GetLevel())
    end
 

end

function hijikata_dash:AbilityChange()
	local caster =self:GetCaster()
	if caster:GetAbilityByIndex(0):GetName() == "hijikata_dash" then
		caster:SwapAbilities("hijikata_dash", "hijikata_dash_recast", false, true)
	end
	caster:AddNewModifier(caster, self, "modifier_hijikata_dash_recast_enable", {duration = self:GetSpecialValueFor("recast_duration"), hTarget = hTarget})

	self.radius_ring_fx =     ParticleManager:CreateParticle("particles/hijikata/hijikata_dash_radius.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(self.radius_ring_fx,1,Vector( self:GetSpecialValueFor("distance"),0,0))
	--ParticleManager:ReleaseParticleIndex(self.radius_ring_fx)
	

end

function hijikata_dash:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local range = self:GetSpecialValueFor("distance")
	local target = caster:GetForwardVector()
	local origin = caster:GetAttachmentOrigin(4) 
	caster:EmitSound("nobu_shoot_1")
	local tProjectile = {
		EffectName = "particles/hijikata/hijikata_bullet.vpcf",
		Ability = self,
		vSpawnOrigin = origin,
		vVelocity = target * 3000 ,
		fDistance = range,
		fStartRadius = 100,
		fEndRadius = 100,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = 0,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		--bProvidesVision = true,
		bDeleteOnHit = true,
		--iVisionRadius = 500,
		--bFlyingVision = true,
		--iVisionTeamNumber = caster:GetTeamNumber(),
		ExtraData = {fDamage = self:GetSpecialValueFor("damage")}
	}  
	self.iProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)
end


function hijikata_dash:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	local hCaster = self:GetCaster()
 	 if(hTarget ~= nil) then
	 DoDamage(hCaster, hTarget, tData.fDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	 hCaster:AddNewModifier(hCaster, self, "modifier_vision_provider", { Duration = self:GetSpecialValueFor("recast_duration") })
	 self:AbilityChange()
	 hCaster.dash_target = hTarget
 
  end
	 Timers:CreateTimer(0.033,function()
		 ProjectileManager:DestroyLinearProjectile(self.iProjectile)
	end)
  return true
end


modifier_hijikata_dash_recast_enable = class({})

function modifier_hijikata_dash_recast_enable:IsHidden()
    return false 
end

function modifier_hijikata_dash_recast_enable:RemoveOnDeath()
    return true
end

function modifier_hijikata_dash_recast_enable:IsDebuff()
    return false 
end

function modifier_hijikata_dash_recast_enable:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_hijikata_dash_recast_enable:OnDestroy()
	local parent = self:GetParent()
	if not IsServer() then return end
	if parent:GetAbilityByIndex(0):GetName() == "hijikata_dash_recast" then
		parent:SwapAbilities("hijikata_dash", "hijikata_dash_recast", true, false)
	end
	if self.radius_ring_fx ~= nil then 
		ParticleManager:DestroyParticle(self.radius_ring_fx, true)
		ParticleManager:ReleaseParticleIndex(self.radius_ring_fx)
	end
end