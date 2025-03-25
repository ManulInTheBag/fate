
demon_king_extermination = class({})

LinkLuaModifier("modifier_demon_king_extermination_burn", "abilities/demon_king_nobunaga/demon_king_extermination", LUA_MODIFIER_MOTION_NONE)
function demon_king_extermination:OnSpellStart()
   local caster = self:GetCaster() 
   local target = self:GetCursorTarget()
   local damage = self:GetSpecialValueFor("damage_hit")
   DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
   giveUnitDataDrivenModifier(caster, target, "locked", self:GetSpecialValueFor("lock_duration"))
   giveUnitDataDrivenModifier(caster, target, "stunned", 0.3)
   target:AddNewModifier(caster, self, "modifier_demon_king_extermination_burn",{duration = self:GetSpecialValueFor("burn_duration") })
end

function demon_king_extermination:OnAbilityPhaseStart()
   local caster = self:GetCaster()
   StartAnimation(caster, {duration=1, activity=ACT_DOTA_CAST_ABILITY_2, rate=1})

   self.castfx = ParticleManager:CreateParticle("particles/demon_king_nobunaga/extermination_cast_base.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
   ParticleManager:SetParticleControl(self.castfx, 1, caster:GetAbsOrigin()+caster:GetForwardVector()*-4 + caster:GetRightVector()*-3)
   ParticleManager:SetParticleControl(self.castfx, 0, caster:GetAbsOrigin()+caster:GetForwardVector()*-4 + caster:GetRightVector()*-3)

   self.handfx = ParticleManager:CreateParticle("particles/demon_king_nobunaga/extermination_cast_hand_smoke.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
   ParticleManager:SetParticleControlEnt(self.handfx, 0, caster, PATTACH_POINT_FOLLOW, "left_hand", Vector(0,0,0), true)
   Timers:CreateTimer(0.9, function()
      ParticleManager:DestroyParticle(self.handfx, true)
      ParticleManager:ReleaseParticleIndex(self.handfx)

   
   end)
   local castfx = self.castfx
   local handfx = self.handfx
   local swordblackfx = self.swordblackfx
   local swordredfx = self.swordredfx
   Timers:CreateTimer(1.5, function()
      -----------------------------------------------
      ParticleManager:DestroyParticle(castfx, true)
      ParticleManager:ReleaseParticleIndex(castfx)
      ParticleManager:DestroyParticle(handfx, true)
      ParticleManager:ReleaseParticleIndex(handfx)
      ParticleManager:DestroyParticle(swordblackfx, true)
      ParticleManager:ReleaseParticleIndex(swordblackfx)
      ParticleManager:DestroyParticle(swordredfx, true)
      ParticleManager:ReleaseParticleIndex(swordredfx)
      -----------------------------------------------
   end)
   return true
end


function demon_king_extermination:OnAbilityPhaseInterrupted()
   local target = self:GetCursorTarget()
   local caster = self:GetCaster() 
   local delay = self:GetSpecialValueFor("dash_delay")
   local speed = self:GetSpecialValueFor("dash_speed")
   local distance = (caster:GetAbsOrigin()-target:GetAbsOrigin()):Length2D()
   local vector =  -1*(caster:GetAbsOrigin()-target:GetAbsOrigin()):Normalized() 
   print("WTF")
   -----------------------------------------------
   ParticleManager:DestroyParticle(self.castfx, true)
   ParticleManager:ReleaseParticleIndex(self.castfx)
   ParticleManager:DestroyParticle(self.handfx, true)
   ParticleManager:ReleaseParticleIndex(self.handfx)
   ParticleManager:DestroyParticle(self.swordblackfx, true)
   ParticleManager:ReleaseParticleIndex(self.swordblackfx)
   ParticleManager:DestroyParticle(self.swordredfx, true)
   ParticleManager:ReleaseParticleIndex(self.swordredfx)
   -----------------------------------------------
   if(target:IsAlive() and target ~= nil and distance<self:GetSpecialValueFor("dash_distance_max") and caster:IsAlive() and not caster:IsStunned() ) then
      StartAnimation(caster, {duration=delay, activity=ACT_DOTA_CAST_ABILITY_2_END, rate=1})
      self:StartCooldown(self:GetCooldown(self:GetLevel()))
      caster:Stop()
      Timers:CreateTimer( delay, function()
				caster:StopAnimation()
            vector.z = 0
            caster:SetForwardVector(vector)
            local dash_duration =  (distance + 150)/speed
				StartAnimation(caster, {duration=dash_duration, activity=ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_END, rate=1})
            local sin = Physics:Unit(caster)
            caster:SetPhysicsFriction(0)
            caster:SetPhysicsVelocity(vector * speed)
            caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
            caster:SetGroundBehavior (PHYSICS_GROUND_LOCK)
           
            local dashProjectile = 
            {
               Ability = self,
                 --EffectName = "particles/saito/saitoquickslash.vpcf",
                 iMoveSpeed = speed,
                 vSpawnOrigin = caster:GetOrigin(),
                 fDistance =  (distance + 150),
                 fStartRadius = 128,
                 fEndRadius = 128,
                 Source = caster,
                 bHasFrontalCone = false,
                 bReplaceExisting = true,
                 iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
                 iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
                 iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                 fExpireTime = GameRules:GetGameTime() + 5.0,
                 bDeleteOnHit = false,
                 vVelocity = vector*speed
            }
            local projectile = ProjectileManager:CreateLinearProjectile(dashProjectile)
            Timers:CreateTimer("maou_nobu_dash", {
               endTime = dash_duration,
               callback = function()
          
               caster:OnPreBounce(nil)
               caster:SetBounceMultiplier(0)
               caster:PreventDI(false)
               caster:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
               caster:SetPhysicsVelocity(Vector(0,0,0))
               FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
               local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false) 
               if(targets[1] ~= nil ) then
                  caster:MoveToTargetToAttack(targets[1])
               end
             
            end})
          
		end)
   end

end

function demon_king_extermination:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end
   print("damage_dash")
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage_dash") 
	DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
   hTarget:AddNewModifier(caster, self, "modifier_demon_king_extermination_burn",{duration = self:GetSpecialValueFor("burn_duration")})

end



modifier_demon_king_extermination_burn = class({})

function modifier_demon_king_extermination_burn:GetEffectName()
   return "particles/muramasa/muramasa_rush_burn.vpcf"
end
function modifier_demon_king_extermination_burn:GetEffectAttachType()
   return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_demon_king_extermination_burn:OnCreated()
   local interval = 0.25
   self.caster = self:GetCaster()
   self.target = self:GetParent()
   self.ability = self:GetAbility()
   self.damage = self.ability :GetSpecialValueFor("burn_dps")*interval
   self:StartIntervalThink(interval)
end

function modifier_demon_king_extermination_burn:OnIntervalThink()
   if(not IsServer() ) then return end
   DoDamage(self.caster, self.target, self.damage, DAMAGE_TYPE_MAGICAL, 0,  self.ability, false)
end
 
 

 

function modifier_demon_king_extermination_burn:IsHidden()	return false end
function modifier_demon_king_extermination_burn:RemoveOnDeath()return true end 
function modifier_demon_king_extermination_burn:IsDebuff() 	return false end

 