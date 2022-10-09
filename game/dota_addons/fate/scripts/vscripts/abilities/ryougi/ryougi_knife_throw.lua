ryougi_knife_throw = class({})

function ryougi_knife_throw:OnUpgrade()
    local hCaster = self:GetCaster()
    
    if hCaster:FindAbilityByName("ryougi_knife_fan"):GetLevel() ~= self:GetLevel() then
    	hCaster:FindAbilityByName("ryougi_knife_fan"):SetLevel(self:GetLevel())
    end
end


function ryougi_knife_throw:OnSpellStart()
	local caster = self:GetCaster()
	local target = caster:GetForwardVector()
	local range = self:GetSpecialValueFor("range")

	EmitSoundOn("ryougi_knife_"..math.random(1,2), caster)

	local tProjectile = {
    EffectName = "particles/ryougi/ryougi_dagger_2.vpcf",
    Ability = self,
    vSpawnOrigin = caster:GetAbsOrigin(),
    vVelocity = target * self:GetSpecialValueFor("speed"),
    fDistance = range,
    fStartRadius = 75,
    fEndRadius = 75,
    Source = caster,
    bHasFrontalCone = false,
    bReplaceExisting = false,
    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    --bProvidesVision = true,
    bDeleteOnHit = true,
    --iVisionRadius = 500,
    --bFlyingVision = true,
    --iVisionTeamNumber = caster:GetTeamNumber(),
    ExtraData = {fDamage = fDamage}
  	}
 	self.iProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)
end

function ryougi_knife_throw:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	if hTarget == nil then
  		return
  	end
  	local hCaster = self:GetCaster()
  	local eyes = hCaster:FindAbilityByName("ryougi_mystic_eyes")
  	
  	DoDamage(hCaster, hTarget, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_PHYSICAL, 0, self, false)
  	if hCaster.BlackMoonAcquired then
  		giveUnitDataDrivenModifier(hCaster, hTarget, "silenced", self:GetSpecialValueFor("attribute_silence_duration"))
  	end
  	EmitSoundOn("ryougi_hit", hTarget)
  	eyes:CutLine(hTarget, "knife_throw")
  	--hTarget:EmitSound("Atalanta.RImpact")
   	--EmitGlobalSound("Atalanta.RImpact2")
   	Timers:CreateTimer(0.033,function()
   		ProjectileManager:DestroyLinearProjectile(self.iProjectile)
  	end)
end

function ryougi_knife_throw:OnProjectileThink(location)
    local caster = self:GetCaster()
    local radius = 100
    local duration = 0.5

    AddFOWViewer(caster:GetTeamNumber(), location, radius, duration, false)
end