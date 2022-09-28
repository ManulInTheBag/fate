muramasa_sword_creation = class({})
LinkLuaModifier("modifier_muramasa_sword_creation","abilities/muramasa/muramasa_sword_creation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_flame","abilities/muramasa/muramasa_sword_creation", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_muramasa_rush_mr","abilities/muramasa/muramasa_sword_creation", LUA_MODIFIER_MOTION_NONE)

function muramasa_sword_creation:GetIntrinsicModifierName()
    return "modifier_muramasa_sword_creation"
end

 
 
modifier_muramasa_sword_creation = class({})




function modifier_muramasa_sword_creation:IsHidden()	return false end
function modifier_muramasa_sword_creation:RemoveOnDeath()return false end 
function modifier_muramasa_sword_creation:IsDebuff() 	return false end

function modifier_muramasa_sword_creation:DeclareFunctions()
    return { MODIFIER_PROPERTY_ATTACKSPEED_BASE_OVERRIDE,
    MODIFIER_EVENT_ON_UNIT_MOVED  }
end



function modifier_muramasa_sword_creation:GetModifierAttackSpeed_Limit()
    if(self:GetCaster():HasModifier("modifier_muramasa_tsumukari_buff") or self:GetCaster():HasModifier("modifier_muramasa_sword_trial_buff")) then 
        return 2
    else    
        return 1
    end
end

function modifier_muramasa_sword_creation:GetModifierAttackSpeedBaseOverride()
    if(self:GetCaster():HasModifier("modifier_muramasa_tsumukari_buff") or self:GetCaster():HasModifier("modifier_muramasa_sword_trial_buff")) then 
        return 2
    else    
        return 1
    end
end

 

function modifier_muramasa_sword_creation:OnUnitMoved(args)
    if(args.unit ~= self:GetParent() ) then return end
        if(self:GetParent().swordsfx == nil) then return end
    Timers:CreateTimer(0.2, function() 
        if(self:GetParent().swordsfx ~= nil) then
            Timers:RemoveTimer("muramasa_swords_particle")
            ParticleManager:DestroyParticle(self:GetParent().swordsfx, true)
            ParticleManager:ReleaseParticleIndex(self:GetParent().swordsfx)
            self:GetParent().swordsfx = nil
        end
    end)
end
 

 function modifier_muramasa_sword_creation:OnAttackLanded(args)
    local caster = self:GetParent()
    if(args.attacker ~= caster ) then return end
local point = args.target:GetAbsOrigin()

local radius = self:GetAbility():GetSpecialValueFor("attack_aoe_radius")
local damage = self:GetAbility():GetSpecialValueFor("base_dmg") + self:GetAbility():GetSpecialValueFor("dmg_per_agi") *caster:GetAgilityGain()*caster:GetLevel() 
local particlestring = "particles/muramasa/muramasa_atk_explosion_base.vpcf"

if(caster:HasModifier("modifier_berserk_scroll")) then
damage = damage + self:GetAbility():GetSpecialValueFor("dmg_berserker")
end
if(caster:HasModifier("modifier_muramasa_tsumukari_buff") or self:GetCaster():HasModifier("modifier_muramasa_sword_trial_buff")) then
damage = damage * self:GetCaster():FindAbilityByName("muramasa_tsumukari"):GetSpecialValueFor("atk_dmg_amplify")
radius = radius + 80
particlestring = "particles/muramasa/muramasa_atk_explosion_powered.vpcf"
end
 
if(caster:GetAbilityByIndex(0):GetName() == "muramasa_dance_stop") then -- check for Q cast
 
    damage = damage * self:GetCaster():FindAbilityByName("muramasa_dance"):GetSpecialValueFor("dmg_mod")/100
 
end


local explosionFx = ParticleManager:CreateParticle(particlestring, PATTACH_CUSTOMORIGIN, nil)
ParticleManager:SetParticleControl(explosionFx, 0, point)
 local targets = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
    for k,v in pairs(targets) do            
         DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
         if(caster.FlameAcquired) then
            v:AddNewModifier(caster, self:GetAbility(), "modifier_muramasa_flame", { Duration = 0.5, Damage = damage })
         end
       
    end 

 end

 modifier_muramasa_flame = class({})




function modifier_muramasa_flame:IsHidden()	return false end
function modifier_muramasa_flame:RemoveOnDeath()return true end 
function modifier_muramasa_flame:IsDebuff() 	return true end
function modifier_muramasa_flame:OnCreated(args)
self.damage  = args.Damage
end

function modifier_muramasa_flame:OnDestroy()  
    if(IsServer()) then
        DoDamage(self:GetCaster(), self:GetParent(), self.damage*0.3, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
    end
end