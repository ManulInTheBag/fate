muramasa_dance = class({})
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)

function muramasa_dance:OnUpgrade()
   local caster = self:GetCaster() 
  if(caster:FindAbilityByName("muramasa_dance_upgraded"):GetLevel()< self:GetLevel()) then
     caster:FindAbilityByName("muramasa_dance_upgraded"):SetLevel(self:GetLevel())
  end
   
end

function muramasa_dance:OnSpellStart()
 local caster = self:GetCaster()
 caster:FindAbilityByName("muramasa_dance_upgraded"):StartCooldown(caster:FindAbilityByName("muramasa_dance_upgraded"):GetCooldown(caster:FindAbilityByName("muramasa_dance_upgraded"):GetLevel()))
 caster.lastdance = true
 caster:SwapAbilities("muramasa_dance", "muramasa_dance_stop",false , true)
if( caster:GetAbilityByIndex(1):GetName() ~="muramasa_throw") then
   caster:SwapAbilities("muramasa_throw", "muramasa_throw_upgraded", true, false)
end
if( caster:GetAbilityByIndex(2):GetName() ~="muramasa_rush") then
   caster:SwapAbilities("muramasa_rush", "muramasa_rush_upgraded", true, false)
end
 --giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 1.5) 
 local attack_time = 0.3
 caster:AddNewModifier(caster, self, "modifier_merlin_self_pause",{duration = attack_time*5})
 
 self.attacks_completed = 0
 local counter = 0

 Timers:CreateTimer(1.55, function()
   if(caster:GetAbilityByIndex(0):GetName() =="muramasa_dance_stop") then
      caster:SwapAbilities("muramasa_dance", "muramasa_dance_stop", true, false)
   end

 end)
 Timers:CreateTimer(0, function()
   if(counter == 15  ) then return end
      if(caster:IsStunned() == true) then
         if( self.attacks_completed < 2) then
            Timers:RemoveTimer("muramasa_attack_1")
         end
         if( self.attacks_completed < 3) then
            Timers:RemoveTimer("muramasa_attack_2")
         end
            if( self.attacks_completed < 4) then
            Timers:RemoveTimer("muramasa_attack_3")
         end
         if( self.attacks_completed < 5) then
            Timers:RemoveTimer("muramasa_attack_4")
         end
         if(caster:GetAbilityByIndex(0):GetName() ~="muramasa_dance") then
             caster:SwapAbilities("muramasa_dance", "muramasa_dance_stop", true, false)
         end
         caster:RemoveModifierByName("modifier_merlin_self_pause")
         return
      end
     
   counter = counter + 1  
   return 0.1
end)
 caster:StopAnimation()
 local particle1 = ParticleManager:CreateParticle("particles/muramasa/muramasa_sword_dance_first_hit_true.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
 ParticleManager:SetParticleControl(     particle1 , 0,  caster:GetAbsOrigin()  )  
  
 Timers:CreateTimer( 0.5, function()
   if(particle1 ~= nil) then
      ParticleManager:DestroyParticle(  particle1, true)
      ParticleManager:ReleaseParticleIndex(  particle1)
   end
end)
 StartAnimation(caster, {duration=attack_time, activity=ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_START, rate=2.0})
 Timers:CreateTimer( 0.1, function()
    self:DanceAttack()
   
    self.attacks_completed = 1
   end)
 Timers:CreateTimer("muramasa_attack_1", {
      endTime = attack_time,
    callback = function()
      if not caster:IsAlive() then return end
      caster:StopAnimation()
      self.attacks_completed = 2
    StartAnimation(caster, {duration=attack_time, activity=ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_END, rate=2.0})
    Timers:CreateTimer( 0.1, function()
      if(caster:IsStunned() == true) then 
         caster:StopAnimation()
         return
       end
      local particle2 = ParticleManager:CreateParticle("particles/muramasa/muramasa_sword_dance_pierce.vpcf", PATTACH_CUSTOMORIGIN, nil)
      ParticleManager:SetParticleControl(     particle2 , 0,  caster:GetAbsOrigin() + Vector(0,0,120)  )  
      ParticleManager:SetParticleControl(     particle2 , 1,  caster:GetAbsOrigin() +caster:GetForwardVector()*250 + Vector(0,0,40)  )  
      Timers:CreateTimer( 0.5, function()
      if(particle2 ~= nil) then
         ParticleManager:DestroyParticle(  particle2, true)
         ParticleManager:ReleaseParticleIndex(  particle2)
      end

      end)
        self:DanceAttack_Pierce()
        
    end)
  
 end})
 Timers:CreateTimer("muramasa_attack_2", {
    endTime = attack_time*2,
    callback = function()
      if not caster:IsAlive() then return end
      caster:StopAnimation()
      self.attacks_completed = 3
    StartAnimation(caster, {duration=attack_time, activity=ACT_DOTA_RAZE_2, rate=2.0})
    Timers:CreateTimer( 0.15, function()
      if(caster:IsStunned() == true) then 
         caster:StopAnimation()
         return
       end
      self:DanceAttack_Pierce()
      local particle3 = ParticleManager:CreateParticle("particles/muramasa/muramasa_sword_dance_first_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
      ParticleManager:SetParticleControl(     particle3 , 0,  caster:GetAbsOrigin()  )  
  end)
  Timers:CreateTimer( 0.2, function()
    if(particle3 ~= nil) then
       ParticleManager:DestroyParticle(  particle3, true)
       ParticleManager:ReleaseParticleIndex(  particle3)
    end
   
  end)
  
end})
    
 Timers:CreateTimer("muramasa_attack_3", {
    endTime = attack_time*3,
    callback = function()
      if not caster:IsAlive() then return end
      caster:StopAnimation()
      self.attacks_completed = 4
    StartAnimation(caster, {duration=attack_time, activity=ACT_DOTA_ALCHEMIST_CONCOCTION, rate=2.0})
    Timers:CreateTimer( 0.125, function()
      if(caster:IsStunned() == true) then 
         caster:StopAnimation()
         return
       end
      local particle4 = ParticleManager:CreateParticle("particles/muramasa/muramasa_sword_dance_pierce.vpcf", PATTACH_CUSTOMORIGIN, nil)
      ParticleManager:SetParticleControl(     particle4 , 0,  caster:GetAbsOrigin()  + Vector(0,0,120))  
      ParticleManager:SetParticleControl(     particle4 , 1,  caster:GetAbsOrigin() +caster:GetForwardVector()*250 + Vector(0,0,60) )  
  
      Timers:CreateTimer( 0.5, function()
      if(particle4 ~= nil) then
         ParticleManager:DestroyParticle(  particle4, true)
         ParticleManager:ReleaseParticleIndex(  particle4)
      end
      end)
      self:DanceAttack()
       
  end)
 
end})
    
 Timers:CreateTimer("muramasa_attack_4", {
    endTime = attack_time*4,
    callback = function()
      if not caster:IsAlive() then return end
      caster:StopAnimation()
      self.attacks_completed = 5
    StartAnimation(caster, {duration=attack_time, activity=ACT_DOTA_RAZE_3, rate=2.0})
    Timers:CreateTimer( 0.22, function()
      if(caster:IsStunned() == true) then 
         caster:StopAnimation()
         return
       end
     local particle5 = ParticleManager:CreateParticle("particles/muramasa/muramasa_sword_dance_last_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
     ParticleManager:SetParticleControl(     particle5 , 3,  caster:GetAbsOrigin()+ 50 * caster:GetForwardVector()  )  
     self.sound = "muramasa_dance_attack_"..math.random(1,4)
     caster:EmitSound(self.sound)
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
          DoDamage(caster, enemy, damage_base, DAMAGE_TYPE_MAGICAL, 0, self, false)
     end
     Timers:CreateTimer( 1.2, function()
       ParticleManager:DestroyParticle(  particle5, true)
       ParticleManager:ReleaseParticleIndex(  particle5)

      
     end)
    end)
    caster:SwapAbilities("muramasa_dance", "muramasa_dance_stop", true, false)
    
 end})


end

 
function muramasa_dance:DanceAttack()
    caster = self:GetCaster()
    local damage_base = self:GetSpecialValueFor("base_dmg")
    self.sound = "muramasa_dance_attack_"..math.random(1,4)
    caster:EmitSound(self.sound)
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
 local caster_angle = caster:GetAnglesAsVector().y
 local origin_difference = caster:GetAbsOrigin() - enemy:GetAbsOrigin()

 local origin_difference_radian = math.atan2(origin_difference.y, origin_difference.x)

 origin_difference_radian = origin_difference_radian * 180
 local enemy_angle = origin_difference_radian / math.pi

 enemy_angle = enemy_angle + 180.0

 local result_angle = enemy_angle - caster_angle
 result_angle = math.abs(result_angle)

 if result_angle <= 120  then
    caster:PerformAttack( enemy, true, true, true, true, false, false, false )
    DoDamage(caster, enemy, damage_base, DAMAGE_TYPE_MAGICAL, 0, self, false)

 end

 end

end
   
function muramasa_dance:DanceAttack_Pierce()
   caster = self:GetCaster()
   local damage_base = self:GetSpecialValueFor("base_dmg")
   self.sound = "muramasa_dance_attack_"..math.random(1,4)
   caster:EmitSound(self.sound)
  local enemies = FindUnitsInLine(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        caster:GetAbsOrigin()+250*caster:GetForwardVector(),
                                        nil,
                                        150,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
                                        )

for _,enemy in pairs(enemies) do
 
   caster:PerformAttack( enemy, true, true, true, true, false, false, false )
   DoDamage(caster, enemy, damage_base, DAMAGE_TYPE_MAGICAL, 0, self, false)

end

end
  