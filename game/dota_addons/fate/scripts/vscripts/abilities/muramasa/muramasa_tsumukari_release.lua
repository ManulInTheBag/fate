muramasa_tsumukari_release = class({})
 
LinkLuaModifier("modifier_muramasa_tsumukari_hit_slow","abilities/muramasa/muramasa_tsumukari_release", LUA_MODIFIER_MOTION_NONE)
 
 
function muramasa_tsumukari_release:OnUpgrade()
    local Caster = self:GetCaster() 
    if(Caster:FindAbilityByName("muramasa_tsumukari"):GetLevel()< self:GetLevel()) then
    Caster:FindAbilityByName("muramasa_tsumukari"):SetLevel(self:GetLevel())
    end
    
end
 
function muramasa_tsumukari_release:OnSpellStart()
local caster = self:GetCaster()
caster:EmitSound("muramasa_tsumukari_cast")
caster:EmitSound("muramasa_tsumukari_release")

--Timers:RemoveTimer("muramasa_sword_particle")
--caster:SwapAbilities("muramasa_tsumukari", "muramasa_tsumukari_release", true, false)

--caster:RemoveModifierByName("modifier_muramasa_tsumukari_buff")
 
     StartAnimation(caster, {duration=0.40, activity=ACT_DOTA_RAZE_1, rate=1})

 
  
  Timers:CreateTimer(0.15, function()   
 local attackFx = ParticleManager:CreateParticle("particles/muramasa/muramasa_tsumukari_slash.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster)
    ParticleManager:SetParticleControl(attackFx, 0, caster:GetAbsOrigin())   
    -- ParticleManager:SetParticleControlEnt(attackFx, 0, caster, PATTACH_POINT_FOLLOW, "body", Vector(0,0,0), true)
end)
local pull_center = caster:GetAbsOrigin() + caster:GetForwardVector() * 100

self.knockback = { should_stun = false,
                                    knockback_duration = 0.5,
                                    duration = 0.5,
                                    knockback_distance = -220,
                                    knockback_height =  0,
                                    center_x = pull_center.x,
                                    center_y = pull_center.y,
                                    center_z = pull_center.z }

              
local radius = self:GetSpecialValueFor("hit_radius")
local start_vec =caster:GetForwardVector()
local speed = 3600
local damage_impact = self:GetSpecialValueFor("damage_impact")
if caster.SwordTrialAcquired then 
    damage_impact = damage_impact + self:GetSpecialValueFor("str_scale")*caster:GetStrength()
end
local point = Vector(0,0,0)
local tsumukariProjectile = 
    {
        Ability = self,
        EffectName = "particles/muramasa/muramasa_tsumukari_ground.vpcf",
        iMoveSpeed = speed,
        vSpawnOrigin = pull_center,
        fDistance = 1200,
        fStartRadius = radius,
        fEndRadius = radius,
        Source = caster,
        bGroundLock = true,
        bHasFrontalCone = false,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
        bDeleteOnHit = false,
        vVelocity = start_vec * speed
    }

Timers:CreateTimer(1, function()  
    EmitGlobalSound("muramasa_explosion") 
    for i = 1, 10 do
        point = pull_center + i *start_vec * 120
        local explosionFx = ParticleManager:CreateParticle("particles/muramasa/muramasa_tsumukari_fire.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(explosionFx, 0, point)
        Timers:CreateTimer(2, function() 
            ParticleManager:DestroyParticle(explosionFx, true)
            ParticleManager:ReleaseParticleIndex(explosionFx)
        end)
   end
   local targets = FindUnitsInLine(
								        caster:GetTeamNumber(),
								        pull_center,
								        point,
								        nil,
								        radius*1.5,
										DOTA_UNIT_TARGET_TEAM_ENEMY,
										DOTA_UNIT_TARGET_ALL,
										0
    								)
    for k,v in pairs(targets) do       
     DoDamage(caster, v, damage_impact , DAMAGE_TYPE_MAGICAL, 0, self, false)
    end        
end)


    caster:AddNewModifier(caster, self, "modifier_merlin_self_pause", {Duration = 0.40}) 
Timers:CreateTimer(0.2, function() 
        local projectile = ProjectileManager:CreateLinearProjectile(tsumukariProjectile)
        --ParticleManager:DestroyParticle(caster:FindAbilityByName("muramasa_tsumukari").swordfx, true)
        --ParticleManager:ReleaseParticleIndex(caster:FindAbilityByName("muramasa_tsumukari").swordfx)
end)

function muramasa_tsumukari_release:OnProjectileThink(location)
    local caster = self:GetCaster()
        --AddFOWViewer(caster:GetTeamNumber(), location, 30, 1.5, false)
        SpawnVisionDummy(caster, location, 30,  1.5, false)
end

function muramasa_tsumukari_release:OnProjectileHit_ExtraData(hTarget, vLocation, table)
    if hTarget == nil then return end

    local caster = self:GetCaster()
    local damage_first = self:GetSpecialValueFor("damage_first")
    if caster.SwordTrialAcquired then 
        damage_first = damage_first + self:GetSpecialValueFor("str_scale")*caster:GetStrength()
    end

    local knockback = self.knockback

 
        if( not hTarget:HasModifier("modifier_muramasa_tsumukari_hit_slow")) then 
             hTarget:EmitSound("Hero_Sniper.AssassinateDamage")
             DoDamage(caster, hTarget, damage_first, DAMAGE_TYPE_MAGICAL, 0, self, false)
             if((hTarget:GetAbsOrigin() - caster:GetAbsOrigin() ):Length2D() < 300) then
                knockback.knockback_distance = -10
             end
             hTarget:AddNewModifier(caster, self, "modifier_knockback", knockback)   
             hTarget:AddNewModifier(caster, self, "modifier_muramasa_tsumukari_hit_slow", {duration = 1})   
        end
   
end

end
 

 


 modifier_muramasa_tsumukari_hit_slow = class({})




function modifier_muramasa_tsumukari_hit_slow:IsHidden()    return false end
function modifier_muramasa_tsumukari_hit_slow:RemoveOnDeath()return true end 
function modifier_muramasa_tsumukari_hit_slow:IsDebuff()    return true end

function modifier_muramasa_tsumukari_hit_slow:DeclareFunctions()
    local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

    return funcs
end

function modifier_muramasa_tsumukari_hit_slow:GetModifierMoveSpeedBonus_Percentage()
    return -self:GetAbility():GetSpecialValueFor("slow_power")
end
