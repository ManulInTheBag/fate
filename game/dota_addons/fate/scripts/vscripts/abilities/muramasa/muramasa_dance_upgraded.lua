muramasa_dance_upgraded = class({})
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_dance_debuff","abilities/muramasa/muramasa_dance_upgraded", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_dance_controller","abilities/muramasa/muramasa_dance", LUA_MODIFIER_MOTION_NONE)

function muramasa_dance_upgraded:OnUpgrade()
   local caster = self:GetCaster() 
  if(caster:FindAbilityByName("muramasa_dance"):GetLevel()< self:GetLevel()) then
     caster:FindAbilityByName("muramasa_dance"):SetLevel(self:GetLevel())
  end
   
end

function muramasa_dance_upgraded:GetCastRange()
   if(self:GetCaster().targetqenemy ~= nil and self:GetCaster().targetqenemy:IsAlive()) then
     return 2000
   else
      return 250
   end
 end


 

function muramasa_dance_upgraded:OnSpellStart()
 local caster = self:GetCaster()
 if(caster.targetqenemy ~= nil and caster.targetqenemy:IsAlive()) then
   FindClearSpaceForUnit(caster,caster.targetqenemy:GetAbsOrigin() + caster.targetqenemy:GetForwardVector() * -100,false)
   local vector =  (-caster:GetAbsOrigin()+caster.targetqenemy:GetAbsOrigin()):Normalized()
   vector.z = 0
   caster:SetForwardVector(vector) 
   caster.targetqenemy = nil
 end
 caster.lastdance = true
 if not caster:HasModifier("modifier_muramasa_dance_controller") then
   self.attacks_completed = 0
   caster:AddNewModifier(caster, self, "modifier_muramasa_dance_controller", {duration = 5})
   caster:SetModifierStackCount( "modifier_muramasa_dance_controller", caster, 1)
 else
   self.attacks_completed = caster:GetModifierStackCount("modifier_muramasa_dance_controller", caster)
 end

 if self.attacks_completed == 0 then
   if( caster:GetAbilityByIndex(1):GetName() ~="muramasa_throw") then
      caster:SwapAbilities("muramasa_throw", "muramasa_throw_upgraded", true, false)
   end
   if( caster:GetAbilityByIndex(2):GetName() ~="muramasa_rush") then
      caster:SwapAbilities("muramasa_rush", "muramasa_rush_upgraded", true, false)
   end
 end
 if self.attacks_completed == 0 then
   self:Attack1()
 elseif self.attacks_completed == 1 then   
   self:Attack2()
elseif self.attacks_completed == 2 then   
   self:Attack3()
elseif self.attacks_completed == 3 then   
   self:Attack4()
else   
   self:Attack5()
end

end


 function muramasa_dance_upgraded:Attack1()
   local caster = self:GetCaster()
   self:EndCooldown()
   local particle1 = ParticleManager:CreateParticle("particles/muramasa/muramasa_q_slash_new_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
   ParticleManager:SetParticleControl(     particle1 , 0,  caster:GetAbsOrigin()  )  
   StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_START, rate=2.0})
   Timers:CreateTimer( 0.5, function()
     if(particle1 ~= nil) then
        ParticleManager:DestroyParticle(  particle1, true)
        ParticleManager:ReleaseParticleIndex(  particle1)
     end
    end)
    Timers:CreateTimer( 0.1, function()
      self:DanceAttack()
     
      caster:SetModifierStackCount( "modifier_muramasa_dance_controller", caster, 1)
     end) 
 end

 function muramasa_dance_upgraded:Attack2()
   local caster = self:GetCaster()
   self:EndCooldown()
   caster:StopAnimation()
   StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_RAZE_2, rate=2.0})
   local particle2 = ParticleManager:CreateParticle("particles/muramasa/muramasa_q_slash_new.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
   ParticleManager:SetParticleControl(     particle2 , 0,  caster:GetAbsOrigin()  )  
   Timers:CreateTimer( 0.5, function()
      if(particle2 ~= nil) then
         ParticleManager:DestroyParticle(  particle2, true)
         ParticleManager:ReleaseParticleIndex(  particle2)
      end
   
   end)
   Timers:CreateTimer( 0.1, function()
      self:DanceAttack()
      caster:SetModifierStackCount( "modifier_muramasa_dance_controller", caster, 2)
   end)
 end

 function muramasa_dance_upgraded:Attack3()
   self:EndCooldown()
   local caster = self:GetCaster()
   caster:StopAnimation()
    StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_START, rate=2.0})
    local particle3 = ParticleManager:CreateParticle("particles/muramasa/muramasa_q_slash_new_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(     particle3 , 0,  caster:GetAbsOrigin()  ) 
    Timers:CreateTimer( 0.1, function()
      self:DanceAttack()
      caster:SetModifierStackCount( "modifier_muramasa_dance_controller", caster, 3)
  end)
  Timers:CreateTimer( 0.5, function()
    if(particle3 ~= nil) then
       ParticleManager:DestroyParticle(  particle3, true)
       ParticleManager:ReleaseParticleIndex(  particle3)
    end
   
  end)
 end

 function muramasa_dance_upgraded:Attack4()
   local caster = self:GetCaster()
   self:EndCooldown()
   caster:StopAnimation()
   StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_RAZE_2, rate=2.0})
   local particle4 = ParticleManager:CreateParticle("particles/muramasa/muramasa_q_slash_new.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
   ParticleManager:SetParticleControl(     particle4 , 0,  caster:GetAbsOrigin()  ) 
   Timers:CreateTimer( 0.5, function()
      if(particle4 ~= nil) then
         ParticleManager:DestroyParticle(  particle4, true)
         ParticleManager:ReleaseParticleIndex(  particle4)
      end
   end)
   Timers:CreateTimer( 0.1, function()
      self:DanceAttack()
      caster:SetModifierStackCount( "modifier_muramasa_dance_controller", caster, 4)
   end)

 end

 function muramasa_dance_upgraded:Attack5()
   local caster = self:GetCaster()
   caster:RemoveModifierByName("modifier_muramasa_dance_controller")
   caster:StopAnimation()
    StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_RAZE_3, rate=2.0})
   Timers:CreateTimer( 0.22, function()
   local particle5 = ParticleManager:CreateParticle("particles/muramasa/muramasa_sword_dance_last_hit_new.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
   Timers:CreateTimer( 1.2, function()
      ParticleManager:DestroyParticle(  particle5, true)
      ParticleManager:ReleaseParticleIndex(  particle5)
   end)
   ParticleManager:SetParticleControl(     particle5 , 3,  caster:GetAbsOrigin()+ 50 * caster:GetForwardVector()  )  
   local damage_base = self:GetSpecialValueFor("base_dmg")
   local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
              caster:GetAbsOrigin() + 50 * caster:GetForwardVector(),
              nil,
              300,
              DOTA_UNIT_TARGET_TEAM_ENEMY,
              DOTA_UNIT_TARGET_ALL,
              DOTA_UNIT_TARGET_FLAG_NONE,
              FIND_ANY_ORDER,
              false)
  for _,enemy in pairs(enemies) do
       caster:PerformAttack( enemy, true, true, true, true, false, false, false )
       enemy:AddNewModifier(caster,self, "modifier_muramasa_dance_debuff", {duration = self:GetSpecialValueFor("dmg_amp_duration")})
       DoDamage(caster, enemy, damage_base, DAMAGE_TYPE_MAGICAL, 0, self, false)
  end

 end)
 self.attacks_completed = 0

 end
  

    


 
function muramasa_dance_upgraded:DanceAttack()
    caster = self:GetCaster()
    local damage_base = self:GetSpecialValueFor("base_dmg")
    self.sound = "muramasa_dance_attack_"..math.random(1,4)
    --caster:EmitSound(self.sound)
    local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                    caster:GetAbsOrigin(),
                    nil,
                    250,
                    DOTA_UNIT_TARGET_TEAM_ENEMY,
                    DOTA_UNIT_TARGET_ALL,
                    DOTA_UNIT_TARGET_FLAG_NONE,
                    FIND_ANY_ORDER,
                    false)

 for _,enemy in pairs(enemies) do
 --  local origin_diff = enemy:GetAbsOrigin() - caster:GetAbsOrigin()
  -- local origin_diff_norm = origin_diff:Normalized()
   --if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
     caster:PerformAttack( enemy, true, true, true, true, false, false, false )
     DoDamage(caster, enemy, damage_base, DAMAGE_TYPE_MAGICAL, 0, self, false)
     enemy:AddNewModifier(caster,self, "modifier_muramasa_dance_debuff", {duration = self:GetSpecialValueFor("dmg_amp_duration")})
   --end
 end

end

 
 
modifier_muramasa_dance_debuff = class({})

function modifier_muramasa_dance_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_muramasa_dance_debuff:IsDebuff()
	return true
end


function modifier_muramasa_dance_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

  

function modifier_muramasa_dance_debuff:GetModifierIncomingDamage_Percentage()
	return self:GetAbility():GetSpecialValueFor("dmg_amp")
end