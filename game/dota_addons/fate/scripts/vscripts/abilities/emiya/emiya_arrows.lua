emiya_arrows = class({})

LinkLuaModifier("modifier_arrow_rain_cooldown", "abilities/emiya/modifiers/modifier_arrow_rain_cooldown", LUA_MODIFIER_MOTION_NONE)

function emiya_arrows:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self
    
	if caster:FindAbilityByName("emiya_kanshou_byakuya"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("emiya_kanshou_byakuya"):SetLevel(self:GetLevel())
    end
 

end



function emiya_arrows:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local range = self:GetSpecialValueFor("range")  + (caster.IsEagleEyeAcquired and 400 or 0 )
	local target = caster:GetForwardVector()
	caster:EmitSound("Ability.Powershot.Alt")
	caster:EmitSound("DrowRanger.Attack")
	local tProjectile = {
		EffectName = "particles/emiya/emiya_q_arrow.vpcf",
		Ability = self,
		vSpawnOrigin = caster:GetAbsOrigin(),
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
		ExtraData = {fDamage = self:GetSpecialValueFor("damage") + caster:GetIntellect()*self:GetSpecialValueFor("damage_per_int")}
	}  
	self.iProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)
end


function emiya_arrows:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	local hCaster = self:GetCaster()
 	 if(hTarget ~= nil) then
	 DoDamage(hCaster, hTarget, tData.fDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	 if(self:GetCooldownTimeRemaining() > 1) then
		self:EndCooldown()	
		self:StartCooldown(1)  

	 end
	 hCaster:GiveMana(50)
  end
	 Timers:CreateTimer(0.033,function()
		 ProjectileManager:DestroyLinearProjectile(self.iProjectile)
	end)
  return true
end