muramasa_tsumukari_combo = class({})
 
LinkLuaModifier("modifier_muramasa_combo_cd", "abilities/muramasa/muramasa_tsumukari_combo", LUA_MODIFIER_MOTION_NONE)
 
function muramasa_tsumukari_combo:OnSpellStart()
local caster = self:GetCaster()
self.casted = true
local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
masterCombo:EndCooldown()
masterCombo:StartCooldown(self:GetCooldown(1))
if(caster:HasModifier("modifier_muramasa_tsumukari_buff")) then
    caster:SwapAbilities("muramasa_tsumukari_combo", "muramasa_tsumukari_release", false, true)
else
    caster:SwapAbilities("muramasa_tsumukari_combo", "muramasa_tsumukari", false, true)
end
caster:FindAbilityByName("muramasa_tsumukari_release"):StartCooldown(20)


------------------------------------------------------------------------------------------------
--------------------------------------------CHANT-----------------------------------------------
------------------------------------------------------------------------------------------------
Timers:CreateTimer(0, function() 
    EmitGlobalSound("muramasa_combo_cast")

end)

local marble_fx = ParticleManager:CreateParticle("particles/muramasa/muramasa_combo_swords_base.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster)
ParticleManager:SetParticleControl(marble_fx, 0, caster:GetAbsOrigin()) 
Timers:CreateTimer(1, function() 
    ParticleManager:DestroyParticle(marble_fx, true)
    ParticleManager:ReleaseParticleIndex(marble_fx)

end)
Timers:CreateTimer(0, function() 
    local sword_location =  caster:GetAbsOrigin()+Vector(0,0,130)+caster:GetForwardVector()*50
    local energy_fx_1 = ParticleManager:CreateParticle("particles/muramasa/muramasa_combo_swords_energy.vpcf", PATTACH_CUSTOMORIGIN  , nil)
    ParticleManager:SetParticleControl(energy_fx_1, 0, sword_location)   
    ParticleManager:SetParticleControl(energy_fx_1, 1, caster:GetAbsOrigin()+Vector(30,-230,70))   
    local energy_fx_2 = ParticleManager:CreateParticle("particles/muramasa/muramasa_combo_swords_energy.vpcf", PATTACH_CUSTOMORIGIN  , nil)
    ParticleManager:SetParticleControl(energy_fx_2, 0, sword_location)   
    ParticleManager:SetParticleControl(energy_fx_2, 1, caster:GetAbsOrigin()+Vector(-100,20,70))   
    local energy_fx_3 = ParticleManager:CreateParticle("particles/muramasa/muramasa_combo_swords_energy.vpcf", PATTACH_CUSTOMORIGIN  , nil)
    ParticleManager:SetParticleControl(energy_fx_3, 0, sword_location)   
    ParticleManager:SetParticleControl(energy_fx_3, 1, caster:GetAbsOrigin()+Vector(-150,-60,70))   
    local energy_fx_4 = ParticleManager:CreateParticle("particles/muramasa/muramasa_combo_swords_energy.vpcf", PATTACH_CUSTOMORIGIN  , nil)
    ParticleManager:SetParticleControl(energy_fx_4, 0, sword_location)   
    ParticleManager:SetParticleControl(energy_fx_4, 1, caster:GetAbsOrigin()+Vector(-150,-75,70))   
    local energy_fx_5 = ParticleManager:CreateParticle("particles/muramasa/muramasa_combo_swords_energy.vpcf", PATTACH_CUSTOMORIGIN  , nil)
    ParticleManager:SetParticleControl(energy_fx_5, 0, sword_location)   
    ParticleManager:SetParticleControl(energy_fx_5, 1, caster:GetAbsOrigin()+Vector(160,-85,70))   
    local energy_fx_6 = ParticleManager:CreateParticle("particles/muramasa/muramasa_combo_swords_energy.vpcf", PATTACH_CUSTOMORIGIN  , nil)
    ParticleManager:SetParticleControl(energy_fx_6, 0, sword_location)   
    ParticleManager:SetParticleControl(energy_fx_6, 1, caster:GetAbsOrigin()+Vector(120,30,70))   
    local energy_fx_7 = ParticleManager:CreateParticle("particles/muramasa/muramasa_combo_swords_energy.vpcf", PATTACH_CUSTOMORIGIN  , nil)
    ParticleManager:SetParticleControl(energy_fx_7, 0, sword_location)   
    ParticleManager:SetParticleControl(energy_fx_7, 1, caster:GetAbsOrigin()+Vector(90,90,70))   
    local energy_fx_8 = ParticleManager:CreateParticle("particles/muramasa/muramasa_combo_swords_energy.vpcf", PATTACH_CUSTOMORIGIN  , nil)
    ParticleManager:SetParticleControl(energy_fx_8, 0, sword_location)   
    ParticleManager:SetParticleControl(energy_fx_8, 1, caster:GetAbsOrigin()+Vector(-100,70,70))   
    Timers:CreateTimer(1, function() 
        ParticleManager:DestroyParticle(energy_fx_1, true)
        ParticleManager:ReleaseParticleIndex(energy_fx_1)
        ParticleManager:DestroyParticle(energy_fx_2, true)
        ParticleManager:ReleaseParticleIndex(energy_fx_2)
        ParticleManager:DestroyParticle(energy_fx_3, true)
        ParticleManager:ReleaseParticleIndex(energy_fx_3)
        ParticleManager:DestroyParticle(energy_fx_4, true)
        ParticleManager:ReleaseParticleIndex(energy_fx_4)
        ParticleManager:DestroyParticle(energy_fx_5, true)
        ParticleManager:ReleaseParticleIndex(energy_fx_5)
        ParticleManager:DestroyParticle(energy_fx_6, true)
        ParticleManager:ReleaseParticleIndex(energy_fx_6)
        ParticleManager:DestroyParticle(energy_fx_7, true)
        ParticleManager:ReleaseParticleIndex(energy_fx_7)
        ParticleManager:DestroyParticle(energy_fx_8, true)
        ParticleManager:ReleaseParticleIndex(energy_fx_8)

    end)
end)


 
caster:AddNewModifier(caster, self, "modifier_merlin_self_pause", {Duration = 2}) 
caster:AddNewModifier(caster, self, "modifier_muramasa_combo_cd", {Duration = self:GetCooldown(-1)}) 
StartAnimation(caster, {duration=1, activity=ACT_DOTA_ECHO_SLAM, rate=1})
Timers:CreateTimer(1, function() 
    StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_6, rate=1})

end)
 

 
------------------------------------------------------------------------------------------------
--------------------------------------------SLASH-----------------------------------------------
------------------------------------------------------------------------------------------------
local slash_range = 500 
local slash_damage = self:GetSpecialValueFor("damage_first")
Timers:CreateTimer(1.5, function()   
    if(caster:IsAlive() == false) then return end
    EmitGlobalSound("muramasa_slash") 
    StartAnimation(caster, {duration=1, activity=ACT_DOTA_ARCTIC_BURN_END, rate=1})
    Timers:CreateTimer(0.3, function()  
        local attackFx = ParticleManager:CreateParticle("particles/muramasa/muramasa_tsumukari_slash_combo.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster)
        ParticleManager:SetParticleControl(attackFx, 0, caster:GetAbsOrigin())   
        --ParticleManager:SetParticleControlEnt(attackFx, 0, caster, PATTACH_POINT_FOLLOW, "body1", Vector(0,0,0), true)
        local targets = FindUnitsInLine(  caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        caster:GetAbsOrigin()+slash_range*caster:GetForwardVector(),
        nil,
        200,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_ALL,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
        )

        for _, enemy in pairs(targets) do
            if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
                if not enemy:IsMagicImmune() then
                     DoDamage(caster, enemy, slash_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
                end
            enemy:AddNewModifier(caster, enemy, "modifier_stunned", {duration = 1})

            end
        end    
    end)

  


end)


------------------------------------------------------------------------------------------------
------------------------------------------CRACK-------------------------------------------------
------------------------------------------------------------------------------------------------
if(caster:IsAlive() == false) then return end
local pull_center = caster:GetAbsOrigin() + caster:GetForwardVector() * 1250
local start_point = caster:GetAbsOrigin()
local radius = self:GetSpecialValueFor("hit_radius")
local start_vec =caster:GetForwardVector()
local speed = 1200
local distance =  self:GetSpecialValueFor("range")
local damage_impact = self:GetSpecialValueFor("damage_impact")
local damage_explosion = self:GetSpecialValueFor("damage_explosion")
local damage_burn = self:GetSpecialValueFor("burn_dmg_per_tick")
local tsumukariProjectile = 
    {
        Ability = self,
        --EffectName = "particles/muramasa/muramasa_tsumukari_ground.vpcf",
        iMoveSpeed = speed,
        vSpawnOrigin = caster:GetAbsOrigin() + caster:GetForwardVector() * 100,
        fDistance = distance,
        fStartRadius = radius,
        fEndRadius = radius,
        Source = caster,
        bGroundLock = true,
        bHasFrontalCone = false,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 10.0,
        bDeleteOnHit = false,
        vVelocity = start_vec * speed
    }

    

------------------------------------------------------------------------------------------------
-------------------------------------explosion--------------------------------------------------
------------------------------------------------------------------------------------------------
Timers:CreateTimer(4, function()   
    if(self.casted == false ) then return end
    EmitGlobalSound("muramasa_explosion")
    Timers:CreateTimer(0, function()  
    EmitGlobalSound("muramasa_explosion_2")
    end)
for i = 1, 10 do
    if(self.casted == false ) then return end
    local point = start_point + i *start_vec * 250
    local explosionFx = ParticleManager:CreateParticle("particles/muramasa/muramasa_tsumukari_fire_combo.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleShouldCheckFoW(explosionFx, false)
    ParticleManager:SetParticleControl(explosionFx, 0, point)
    Timers:CreateTimer(2.8, function() 
        ParticleManager:DestroyParticle(explosionFx, true)
        ParticleManager:ReleaseParticleIndex(explosionFx)
    end)
        local targets = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
        for k,v in pairs(targets) do       
            DoDamage(caster, v, damage_explosion , DAMAGE_TYPE_MAGICAL, 0, self, false)
        end
        Timers:CreateTimer(0.4, function() 
            local targets = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
            for k,v in pairs(targets) do       
                DoDamage(caster, v, damage_burn , DAMAGE_TYPE_MAGICAL, 0, self, false)
            end
        end)
        Timers:CreateTimer(0.8, function() 
            local targets = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
            for k,v in pairs(targets) do       
                DoDamage(caster, v, damage_burn , DAMAGE_TYPE_MAGICAL, 0, self, false)
            end
        end)
        Timers:CreateTimer(1.2, function() 
            local targets = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
            for k,v in pairs(targets) do       
                DoDamage(caster, v, damage_burn , DAMAGE_TYPE_MAGICAL, 0, self, false)
            end
        end)
        Timers:CreateTimer(1.6, function() 
            local targets = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
            for k,v in pairs(targets) do       
                DoDamage(caster, v, damage_burn , DAMAGE_TYPE_MAGICAL, 0, self, false)
            end
        end)
        end
end)


Timers:CreateTimer(1.7, function() 
    if(caster:IsAlive() == false) then 
        StopGlobalSound("muramasa_combo_cast")
        self.casted = false
        return
     end
    Timers:CreateTimer(0.3, function() 
        EmitGlobalSound("muramasa_crack_sound")
    end)
    Timers:CreateTimer(2.4, function() 
        StopGlobalSound("muramasa_crack_sound") 
    end)
  
        
        local projectile = ProjectileManager:CreateLinearProjectile(tsumukariProjectile)
        --ParticleManager:DestroyParticle(caster:FindAbilityByName("muramasa_tsumukari").swordfx, true)
        --ParticleManager:ReleaseParticleIndex(caster:FindAbilityByName("muramasa_tsumukari").swordfx)
        local CrackFx = ParticleManager:CreateParticle("particles/muramasa/muramasa_tsumukari_ground_combo.vpcf", PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleShouldCheckFoW(CrackFx, false)
        ParticleManager:SetParticleControl(CrackFx, 0, caster:GetAbsOrigin() + caster:GetForwardVector() * 100)
        ParticleManager:SetParticleControl(CrackFx, 1, caster:GetAbsOrigin() + caster:GetForwardVector() * 2500 )
        
        Timers:CreateTimer(3.0, function() 
            ParticleManager:DestroyParticle(CrackFx, true)
            ParticleManager:ReleaseParticleIndex(CrackFx)
          
             
       end)
end)


function muramasa_tsumukari_combo:OnProjectileThink(location)
    local caster = self:GetCaster()
    AddFOWViewer(caster:GetTeamNumber(), location, 200, 5, false)
end

function muramasa_tsumukari_combo:OnProjectileHit_ExtraData(hTarget, vLocation, table)
    if hTarget == nil then return end
    local duration = 4 
    local caster = self:GetCaster()
    local damage_first = self:GetSpecialValueFor("damage_first")
    DoDamage(caster, hTarget, damage_first, DAMAGE_TYPE_MAGICAL, 0, self, false)
    giveUnitDataDrivenModifier(caster, hTarget, "rooted", duration)
    giveUnitDataDrivenModifier(caster, hTarget, "locked", duration)

   
end

end
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------    
 

modifier_muramasa_combo_cd = class({})

function modifier_muramasa_combo_cd:IsHidden()
    return false 
end

function modifier_muramasa_combo_cd:RemoveOnDeath()
    return false
end

function modifier_muramasa_combo_cd:IsDebuff()
    return true 
end

function modifier_muramasa_combo_cd:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end