muramasa_dance_upgraded = class({})
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_dance_debuff","abilities/muramasa/muramasa_dance_upgraded", LUA_MODIFIER_MOTION_NONE)

function muramasa_dance_upgraded:OnUpgrade()
  local caster = self:GetCaster() 
 if(caster:FindAbilityByName("muramasa_dance"):GetLevel()< self:GetLevel()) then
    caster:FindAbilityByName("muramasa_dance"):SetLevel(self:GetLevel())
 end
  
end

function muramasa_dance_upgraded:OnSpellStart()
 local caster = self:GetCaster()
 
 caster:FindAbilityByName("muramasa_dance"):StartCooldown(caster:FindAbilityByName("muramasa_dance"):GetCooldown(caster:FindAbilityByName("muramasa_dance"):GetLevel()))
 caster:SwapAbilities("muramasa_dance_upgraded", "muramasa_dance_stop",false , true)
 if( caster:GetAbilityByIndex(1):GetName() ~="muramasa_throw") then
  caster:SwapAbilities("muramasa_throw", "muramasa_throw_upgraded", true, false)
end
if( caster:GetAbilityByIndex(2):GetName() ~="muramasa_rush") then
  caster:SwapAbilities("muramasa_rush", "muramasa_rush_upgraded", true, false)
end

Timers:CreateTimer(1.55, function()
  if(caster:GetAbilityByIndex(0):GetName() =="muramasa_dance_stop") then
     caster:SwapAbilities("muramasa_dance", "muramasa_dance_stop", true, false)
  end

end)
 --giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 1.5) 
 local attack_time = 0.3
 caster:AddNewModifier(caster, self, "modifier_merlin_self_pause",{duration = attack_time*5})
 caster.lastdance = false
 self.attacks_completed = 0
 local counter = 0
 caster:StopAnimation()
 local particle1 = ParticleManager:CreateParticle("particles/muramasa/muramasa_sword_dance_first_hit_true.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
 ParticleManager:SetParticleControl(     particle1 , 0,  caster:GetAbsOrigin()  )  
 ProjectileManager:ProjectileDodge(caster)
 HardCleanse(caster)
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
      ProjectileManager:ProjectileDodge(caster)
      HardCleanse(caster)
      caster:StopAnimation()
     
    StartAnimation(caster, {duration=attack_time, activity=ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_END, rate=2.0})
    Timers:CreateTimer( 0.1, function()
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
    self.attacks_completed = 2
 end})
 Timers:CreateTimer("muramasa_attack_2", {
    endTime = attack_time*2,
    callback = function()
      if not caster:IsAlive() then return end
      caster:StopAnimation()
      ProjectileManager:ProjectileDodge(caster)
      HardCleanse(caster)
    StartAnimation(caster, {duration=attack_time, activity=ACT_DOTA_RAZE_2, rate=2.0})
    Timers:CreateTimer( 0.15, function()
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
  self.attacks_completed = 4
end})
    
 Timers:CreateTimer("muramasa_attack_3", {
    endTime = attack_time*3,
    callback = function()
      if not caster:IsAlive() then return end
      caster:StopAnimation()
      ProjectileManager:ProjectileDodge(caster)
      HardCleanse(caster)
    StartAnimation(caster, {duration=attack_time, activity=ACT_DOTA_ALCHEMIST_CONCOCTION, rate=2.0})
    Timers:CreateTimer( 0.125, function()
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
  self.attacks_completed = 3
end})
    
 Timers:CreateTimer("muramasa_attack_4", {
    endTime = attack_time*4,
    callback = function()
      if not caster:IsAlive() then return end
      caster:StopAnimation()
      ProjectileManager:ProjectileDodge(caster)
      HardCleanse(caster)
    StartAnimation(caster, {duration=attack_time, activity=ACT_DOTA_RAZE_3, rate=2.0})
    Timers:CreateTimer( 0.22, function()
     local particle5 = ParticleManager:CreateParticle("particles/muramasa/muramasa_sword_dance_last_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
     ParticleManager:SetParticleControl(     particle5 , 3,  caster:GetAbsOrigin()+ 50 * caster:GetForwardVector()  )  
     self.sound = "muramasa_dance_attack_"..math.random(1,4)
     caster:EmitSound(self.sound)
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
          enemy:AddNewModifier(caster, self, "modifier_muramasa_dance_debuff", {Duration = self:GetSpecialValueFor("dmg_amp_duration")})
          caster:PerformAttack( enemy, true, true, true, true, false, false, false )
     end
     Timers:CreateTimer( 1.2, function()
       ParticleManager:DestroyParticle(  particle5, true)
       ParticleManager:ReleaseParticleIndex(  particle5)

      
     end)
    end)
    caster:SwapAbilities("muramasa_dance", "muramasa_dance_stop", true, false)
    self.attacks_completed = 5
 end})


end

 
function muramasa_dance_upgraded:DanceAttack()
    caster = self:GetCaster()
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
    enemy:AddNewModifier(caster, self, "modifier_muramasa_dance_debuff", {Duration = self:GetSpecialValueFor("dmg_amp_duration")})
    caster:PerformAttack( enemy, true, true, true, true, false, false, false )

 end

 end

end
   
function muramasa_dance_upgraded:DanceAttack_Pierce()
   caster = self:GetCaster()
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
   enemy:AddNewModifier(caster, self, "modifier_muramasa_dance_debuff", {Duration = self:GetSpecialValueFor("dmg_amp_duration")})
   caster:PerformAttack( enemy, true, true, true, true, false, false, false )
 

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