vlad_impale = class({})

function vlad_impale:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end 

if IsClient() then
  return 
end

function vlad_impale:VFX1_SpikesIndicator(caster,radius,point)
  self.PI1 = ParticleManager:CreateParticle("particles/custom/vlad/vlad_ip_prespike.vpcf", PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControl(self.PI1,0,caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(self.PI1,3,caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(self.PI1,4,Vector(100, 0, 0))
end
function vlad_impale:VFX2_OnTargetImpale(k,target)
  self.PI2[k] = FxCreator("particles/custom/vlad/vlad_impale_bleed.vpcf", PATTACH_ABSORIGIN_FOLLOW, target, 0, nil)
  ParticleManager:SetParticleControlEnt(self.PI2[k], 1, target, PATTACH_ABSORIGIN_FOLLOW	, nil, target:GetAbsOrigin(), false)
  
  self.PI3[k] = FxCreator("particles/custom/vlad/vlad_kb_ontarget.vpcf", PATTACH_ABSORIGIN, target, 0, nil)
  ParticleManager:SetParticleControl(self.PI3[k],4, Vector(2.7, 0, 0))
end
--[[actually on a second thought this particle triggers me so much i would rather reuse R ontarget stuff
function vlad_impale:VFX3_Spikes(caster,radius,point)
  self.PI4 = ParticleManager:CreateParticle("particles/custom/vlad/vlad_ip_spikes.vpcf", PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControl(self.PI4,0,point + Vector(0,0,100))
  ParticleManager:SetParticleControl(self.PI4,4,Vector(radius, 0, 0))
end--]]

function vlad_impale:OnUpgrade()
	local caster = self:GetCaster()
  local ability = self
	if not caster.ResetImpaleSwapTimer then
		function caster:ResetImpaleSwapTimer(...)
			ability:ResetImpaleSwapTimer(...)
		end
	end
end

function vlad_impale:ResetImpaleSwapTimer()
  local caster = self:GetCaster()
  if caster.ImpaleSwapTimer then
    Timers:RemoveTimer(caster.ImpaleSwapTimer)
    caster.ImpaleSwapTimer = nil
    caster:SwapAbilities("vlad_transfusion", "vlad_impale", true, false)
  end
end

function vlad_impale:GetCastRange(vLocation,hTarget)
  return self:GetSpecialValueFor("range")
end

function vlad_impale:OnSpellStart()
  local caster = self:GetCaster()
  local stun_min = self:GetSpecialValueFor("stun_min")
  local stun_gain = self:GetSpecialValueFor("stun_gain")
  local stun_max = self:GetSpecialValueFor("stun_max")
  local damage = self:GetSpecialValueFor("damage")
  local delay = self:GetSpecialValueFor("delay")
  local point = caster:GetCursorPosition()
  if caster.BloodletterAcquired then
		if caster:GetHealth()/caster:GetMaxHealth() <= 0.5 then
  
		  local saDamage = caster.MasterUnit2:FindAbilityByName("vlad_attribute_bloodletter"):GetSpecialValueFor("damage")
		  local saBleed = caster.MasterUnit2:FindAbilityByName("vlad_attribute_bloodletter"):GetSpecialValueFor("bleed")
		  local explosionFx = ParticleManager:CreateParticle("particles/vlad/vlad_impale_fort.vpcf", PATTACH_WORLDORIGIN, nil)
		  ParticleManager:SetParticleControl(explosionFx, 3, caster:GetAbsOrigin())
		  ParticleManager:ReleaseParticleIndex(explosionFx)
		  caster:EmitSound("Hero_Lycan.Attack")
		  local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
		  for k,v in pairs(targets) do
			DoDamage(caster, v, saDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			caster:AddBleedStack(v, false, saBleed)
			giveUnitDataDrivenModifier(caster, v, "rooted", 0.5)

		  end
		end
	  end
  caster:RemoveModifierByName("modifier_transfusion_self")
  self:ResetImpaleSwapTimer()

  local modifier = caster:FindModifierByName("modifier_transfusion_bloodpower")
 	local bloodpower = modifier and modifier:GetStackCount() or 0
  caster:RemoveModifierByName("modifier_transfusion_bloodpower")

  local stun = math.max(stun_min, math.min(stun_min + bloodpower * stun_gain, stun_max))
  local radius = self:GetAOERadius()
  --print(stun, "   ", radius)
    
  self:VFX1_SpikesIndicator(caster,radius,point)
  local counter = 0
  Timers:CreateTimer(0,function()
    if counter >= 10 then return end
      if (counter % 2) == 0 then
				caster:EmitSound("Hero_Lycan.Attack")
			else
				caster:EmitSound("Hero_NyxAssassin.SpikedCarapace")
			end
      counter = counter+1
      return 0.1

  end)
  --[[
  Timers:CreateTimer(delay, function()
    self.PI2={}
    self.PI3={}
    --self:VFX3_Spikes(caster,radius,point)
    local targets =   FindUnitsInLine(
      caster:GetTeamNumber(),
      caster:GetAbsOrigin(),
      point,
      nil,
      radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_ALL,
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
    ) 
    --local targets = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
    for k,v in pairs(targets) do
      self:VFX2_OnTargetImpale(k,v)
      DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
      caster:AddBleedStack(v, false)
      giveUnitDataDrivenModifier(caster, v, "stunned", stun)
    end
    if #targets ~= 0 then
      targets[1]:EmitSound("Hero_PhantomAssassin.CoupDeGrace")
      targets[1]:EmitSound("Hero_Leshrac.Split_Earth")
    end
   
  end)
 ]]
  Timers:CreateTimer(3, function()
    FxDestroyer(self.PI1, false)
    --FxDestroyer(self.PI2,false)
    --FxDestroyer(self.PI3,false)
    --FxDestroyer(self.PI4,false)
  end)

  local projectile_name = "particles/vlad/vlad_impale.vpcf"
	local projectile_direction = (point-caster:GetOrigin()):Normalized()
	local info = {
		Source = caster,
		Ability = self,
		vSpawnOrigin = caster:GetAbsOrigin(),
		
	    bDeleteOnHit = false,
	    
	    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
	    iUnitTargetType = DOTA_UNIT_TARGET_ALL,
	    
	    EffectName = projectile_name,
	    fDistance = self:GetSpecialValueFor("range"),
	    fStartRadius = radius,
	    fEndRadius = radius,
		vVelocity = projectile_direction * self:GetSpecialValueFor("range"),
	}
	ProjectileManager:CreateLinearProjectile(info)
end

function vlad_impale:OnProjectileHit( target, location )
  if not target then return end
  local caster = self:GetCaster()
  local stun_min = self:GetSpecialValueFor("stun_min")
  local stun_gain = self:GetSpecialValueFor("stun_gain")
  local stun_max = self:GetSpecialValueFor("stun_max")
  local damage = self:GetSpecialValueFor("damage")

  local modifier = caster:FindModifierByName("modifier_transfusion_bloodpower")
 	local bloodpower = modifier and modifier:GetStackCount() or 0

  local stun = math.max(stun_min, math.min(stun_min + bloodpower * stun_gain, stun_max))
  DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
  caster:AddBleedStack(target, false, 10)
  giveUnitDataDrivenModifier(caster, target, "stunned", stun)
  target:EmitSound("Hero_PhantomAssassin.CoupDeGrace")
  target:EmitSound("Hero_Leshrac.Split_Earth")
end

function vlad_impale:GetCastAnimation()
  return ACT_DOTA_CAST_ABILITY_3
end

function vlad_impale:GetAbilityTextureName()
  return "custom/vlad_impale"
end

