LinkLuaModifier("modifier_ryougi_knife_target", "abilities/ryougi/ryougi_knife_throw", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_knife_throw_slow", "abilities/ryougi/ryougi_knife_throw", LUA_MODIFIER_MOTION_NONE)


ryougi_knife_throw = class({})

function ryougi_knife_throw:OnUpgrade()
	local hCaster = self:GetCaster()
    
    if hCaster:FindAbilityByName("ryougi_knife_recast"):GetLevel() ~= self:GetLevel() then
    	hCaster:FindAbilityByName("ryougi_knife_recast"):SetLevel(self:GetLevel())
    end
end

function ryougi_knife_throw:OnSpellStart()
	local caster = self:GetCaster()
  	local tpoint = self:GetCursorPosition()
  	local dir = tpoint - caster:GetAbsOrigin()
  	dir.z = 0
  	if not(tpoint == caster:GetAbsOrigin()) then
  		caster:SetForwardVector(dir:Normalized())
  	end
	local target = caster:GetForwardVector()
	local range = self:GetSpecialValueFor("range")

	--EmitSoundOn("ryougi_knife_"..math.random(1,2), caster)
	EmitGlobalSound("ryougi_mieta")

	local tProjectile = {
	    EffectName = "particles/ryougi/ryougi_dagger_2.vpcf",
	    Ability = self,
	    vSpawnOrigin = caster:GetAbsOrigin(),
	    vVelocity = target * self:GetSpecialValueFor("speed"),
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
    self.hitenemy = false
end

function ryougi_knife_throw:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	if hTarget == nil or self.hitenemy  then --ты можешь подумать что я насрал и если инстом кинуть два ножа можно словить баг, но ты его и так ловил, удаляя ласт нож если хитнул любой из них так что похуй
  		return
  	end
  	if (hTarget:GetName() == "npc_dota_ward_base") then
  		return
  	end
  	local hCaster = self:GetCaster()
  	local eyes = hCaster:FindAbilityByName("ryougi_mystic_eyes")
  	
  	DoDamage(hCaster, hTarget, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
  	hTarget:AddNewModifier(hCaster, self, "modifier_ryougi_knife_target", {duration = self:GetSpecialValueFor("mark_duration")})
  	if hCaster.BlackMoonAcquired then
      hTarget:AddNewModifier(hCaster, self, "modifier_ryougi_knife_throw_slow", {duration = self:GetSpecialValueFor("attribute_slow_duration")})
    end
  	EmitSoundOn("ryougi_hit", hTarget)
  	eyes:CutLine(hTarget, "knife_throw")
  	--hTarget:EmitSound("Atalanta.RImpact")
   	--EmitGlobalSound("Atalanta.RImpact2")
    self.hitenemy = true
   	--Timers:CreateTimer(0.033,function()
   	ProjectileManager:DestroyLinearProjectile(self.iProjectile)
  	--end)
end

function ryougi_knife_throw:OnProjectileThink(location)
    local caster = self:GetCaster()
    local radius = 100
    local duration = 0.5

    AddFOWViewer(caster:GetTeamNumber(), location, radius, duration, false)
end

modifier_ryougi_knife_target = class({})

function modifier_ryougi_knife_target:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.parent = self:GetParent()

	if not self.caster.CurrentKnifeTarget then
		self.caster.CurrentKnifeTarget = self.parent
	end

	if self.caster:GetAbilityByIndex(5):GetName() == "ryougi_knife_throw" then	    		
		self.caster:SwapAbilities("ryougi_knife_recast", "ryougi_knife_throw", true, false)	
	end
end

function modifier_ryougi_knife_target:OnDestroy()
	if not IsServer() then return end
	self.caster.CurrentKnifeTarget = nil

	if self.caster:GetAbilityByIndex(5):GetName() == "ryougi_knife_recast" then	    		
		self.caster:SwapAbilities("ryougi_knife_recast", "ryougi_knife_throw", false, true)	
	end
end

modifier_ryougi_knife_throw_slow = class({})

function modifier_ryougi_knife_throw_slow:IsHidden() return false end
function modifier_ryougi_knife_throw_slow:IsDebuff() return true end
function modifier_ryougi_knife_throw_slow:RemoveOnDeath() return true end
function modifier_ryougi_knife_throw_slow:DeclareFunctions()
  return {  MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE  }
end
function modifier_ryougi_knife_throw_slow:GetModifierMoveSpeedBonus_Percentage()
  return -1*self:GetAbility():GetSpecialValueFor("attribute_slow_percent")
end