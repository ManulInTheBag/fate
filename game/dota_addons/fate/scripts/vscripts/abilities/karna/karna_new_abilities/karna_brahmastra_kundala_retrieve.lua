karna_brahmastra_kundala_retrieve = class({})

--phase start 0.1
--[[
function karna_brahmastra_kundala_retrieve:CastFilterResult()
	local caster_pos = self:GetCaster():GetAbsOrigin()
	local spear_pos = self:GetCaster():FindAbilityByName("karna_brahmastra_kundala_new").spear_position
	local distance =  (caster_pos-spear_pos):Length2D()
	if distance > self:GetSpecialValueFor("range") then  
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
	end
end

function karna_brahmastra_kundala_retrieve:GetCustomCastError()
	return "Too far from spear"
end
]]
function karna_brahmastra_kundala_retrieve:GetAOERadius()
	return self:GetSpecialValueFor("range")
end

function karna_brahmastra_kundala_retrieve:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local ability = self
	local origin = caster:GetAbsOrigin()
	local aoe_radius = 150
	local spear_abi = caster:FindAbilityByName("karna_brahmastra_kundala_new")
	local aoe_damage = spear_abi:GetSpecialValueFor("damage")
	
	if caster.IndraAttribute then
		aoe_damage = aoe_damage + (caster.IndraAttribute and 1 * caster:GetIntellect() or 0)
	end
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.4)  
	if caster:GetAbilityByIndex(2):GetName() == "karna_brahmastra_kundala_retrieve"  then
		caster:SwapAbilities("karna_brahmastra_kundala_retrieve", "karna_brahmastra_kundala_new", false, true)
	end
	ParticleManager:DestroyParticle(spear_abi.endFX, true)
	ParticleManager:ReleaseParticleIndex(spear_abi.endFX)
	Timers:RemoveTimer("karna_spear_retrieve")
	Timers:CreateTimer(0.15, function()
		if not caster:IsAlive() then return end
		StartAnimation(caster, {duration=0.4, activity=ACT_DOTA_CAST_REFRACTION, rate=1})
		caster:RemoveModifierByName("modifier_karna_no_spear")
	end)

	local spear_pos = spear_abi.spear_position
	local distance = (caster:GetAbsOrigin()-spear_pos):Length2D()
	local vector = (caster:GetAbsOrigin()-spear_pos):Normalized()
	local speed = distance / 0.2
	local tProjectile = {
		EffectName = "particles/karna/spear_throw.vpcf",
		Ability = self,
		vSpawnOrigin = spear_pos,
		vVelocity = vector * speed,
		fDistance = distance-50,
		fStartRadius = aoe_radius,
		fEndRadius = aoe_radius,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = 0,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		--bProvidesVision = true,
		bDeleteOnHit = false,
		--iVisionRadius = 500,
		--bFlyingVision = true,
		--iVisionTeamNumber = caster:GetTeamNumber(),
		ExtraData = {fDamage = aoe_damage, fRadius = aoe_radius}
	}  
	self.iProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)

end

 
function karna_brahmastra_kundala_retrieve:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	local hCaster = self:GetCaster()
  if(hTarget ~= nil) then
	if hTarget:HasModifier("modifier_protection_from_arrows_active") then return end

	  local explosionFx = ParticleManager:CreateParticle("particles/karna/karna_kundala_hit.vpcf", PATTACH_CUSTOMORIGIN, nil)
	  ParticleManager:SetParticleControl(explosionFx, 0, hTarget:GetAbsOrigin())
	  ParticleManager:ReleaseParticleIndex(explosionFx)
	   

	  local enemies = FindUnitsInRadius(  hCaster:GetTeamNumber(),
					  hTarget:GetAbsOrigin(),
					  nil,
					  tData.fRadius,
					  DOTA_UNIT_TARGET_TEAM_ENEMY,
					  DOTA_UNIT_TARGET_ALL,
					  DOTA_UNIT_TARGET_FLAG_NONE,
					  FIND_ANY_ORDER,
					  false)
  
	   for _,enemy in pairs(enemies) do
		  DoDamage(hCaster, enemy, tData.fDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		 end
		 hTarget:EmitSound("karna_new_shockwae")

	  
  end
  --[[
	 Timers:CreateTimer(0.033,function()
		 ProjectileManager:DestroyLinearProjectile(self.iProjectile)
	end)
  ]]
  --return true
end

function karna_brahmastra_kundala_retrieve:OnProjectileThink(location)
  local caster = self:GetCaster()
  local radius = 100
  local duration = 0.5

  AddFOWViewer(2, location, 40, 0.4, false)
  AddFOWViewer(3, location, 40, 0.4, false)
end
