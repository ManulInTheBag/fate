muramasa_dance = class({})
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_dance_controller","abilities/muramasa/muramasa_dance", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_dance_debuff","abilities/muramasa/muramasa_dance_upgraded", LUA_MODIFIER_MOTION_NONE)
--[[
function muramasa_dance:OnUpgrade()
   local caster = self:GetCaster() 
  if(caster:FindAbilityByName("muramasa_dance_upgraded"):GetLevel()< self:GetLevel()) then
     caster:FindAbilityByName("muramasa_dance_upgraded"):SetLevel(self:GetLevel())
  end
   
end
]]

function muramasa_dance:GetAbilityTextureName() 
   local hCaster = self:GetCaster()
   return "custom/muramasa/muramasa_dance"  .. (hCaster:GetModifierStackCount("modifier_muramasa_wicked_sword_counter", hCaster))
end

function muramasa_dance:OnSpellStart()
 local caster = self:GetCaster()
 local point = self:GetCursorPosition()

 if(caster.targetqenemy ~= nil and caster.targetqenemy:IsAlive()) then
   FindClearSpaceForUnit(caster,caster.targetqenemy:GetAbsOrigin() + caster.targetqenemy:GetForwardVector() * -100,false)
   caster:RemoveModifierByName("modifier_muramasa_wicked_sword_counter")
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
   self:MoveForward(point)
 elseif self.attacks_completed == 1 then   
   self:Attack2(point)
   self:MoveForward(point)
elseif self.attacks_completed == 2 then   
   self:Attack3()
   self:MoveForward(point)
elseif self.attacks_completed == 3 then   
   self:Attack4()
   self:MoveForward(point)
else   
   self:Attack5()
end

end

function muramasa_dance:MoveForward(point)
   local caster = self:GetCaster()
   local point = point
   local knockback1 = { should_stun = false,
      knockback_duration = 0.15,
      duration = 0.15,
      knockback_distance = -100,
      knockback_height = 0,
      center_x =point.x,
      center_y = point.y,
      center_z = point.z }
   caster:RemoveModifierByName("modifier_knockback")
   caster:AddNewModifier(caster, self, "modifier_knockback", knockback1)
 end


 function muramasa_dance:Attack1()
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

 function muramasa_dance:Attack2()
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

 function muramasa_dance:Attack3()
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

 function muramasa_dance:Attack4()
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

 function muramasa_dance:Attack5()
   local caster = self:GetCaster()

   caster:RemoveModifierByName("modifier_muramasa_dance_controller")
   caster:StopAnimation()
    StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_RAZE_3, rate=2.0})
   Timers:CreateTimer( 0.22, function()
      caster:EmitSound("muramasa_q_end")
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
       DoDamage(caster, enemy, damage_base, DAMAGE_TYPE_MAGICAL, 0, self, false)
       enemy:AddNewModifier(caster, self, "modifier_stunned", {Duration = 0.1})
       if caster:HasModifier("modifier_muramasa_forge") then 
         enemy:AddNewModifier(caster,self, "modifier_muramasa_dance_debuff", {duration = self:GetSpecialValueFor("dmg_amp_duration")})
      end
  end

 end)
 self.attacks_completed = 0

 end
  

    


 
function muramasa_dance:DanceAttack()
    caster = self:GetCaster()
    local damage_base = self:GetSpecialValueFor("base_dmg")
    caster:EmitSound("muramasa_q")
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
     local point = caster:GetAbsOrigin() + caster:GetForwardVector() * 150
     local knockback1 = { should_stun = true,
		 knockback_duration = 0.15,
		 duration = 0.15,
		 knockback_distance = -100,
		 knockback_height = 0,
		 center_x = point.x,
		 center_y = point.y,
		 center_z = point.z }
       if not IsKnockbackImmune(enemy) then
         enemy:RemoveModifierByName("modifier_knockback")
         enemy:AddNewModifier(caster, self, "modifier_knockback", knockback1)
       end
     if caster:HasModifier("modifier_muramasa_forge") then 
      enemy:AddNewModifier(caster,self, "modifier_muramasa_dance_debuff", {duration = self:GetSpecialValueFor("dmg_amp_duration")})
     end
   --end
 end

end

 



modifier_muramasa_dance_controller = class({})

 
function modifier_muramasa_dance_controller:OnDestroy()
   if not IsServer() then return end
   local caster = self:GetCaster()
   self.ability =caster:FindAbilityByName("muramasa_dance")
   --self.ability2 = caster:FindAbilityByName("muramasa_dance_upgraded")
   self.ability:EndCooldown()
   self.ability:StartCooldown(self.ability:GetCooldown(self.ability:GetLevel()))
   --self.ability2:EndCooldown()
   --self.ability2:StartCooldown(self.ability2:GetCooldown(self.ability2:GetLevel()))
--[[
if( caster:GetAbilityByIndex(1):GetName() ~="muramasa_throw") then
   if caster:GetAbilityByIndex(0):GetName() ~="muramasa_dance_upgraded" then
      caster:SwapAbilities("muramasa_dance_upgraded", "muramasa_dance", true, false)
   end
else
   if caster:GetAbilityByIndex(0):GetName() =="muramasa_dance_upgraded" then
      caster:SwapAbilities("muramasa_dance_upgraded", "muramasa_dance", false, true)
   end
end
]]
end
 
function modifier_muramasa_dance_controller:IsHidden() return false end
function modifier_muramasa_dance_controller:RemoveOnDeath() return true end