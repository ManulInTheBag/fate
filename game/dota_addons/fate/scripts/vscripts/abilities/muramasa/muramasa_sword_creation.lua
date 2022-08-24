muramasa_sword_creation = class({})
LinkLuaModifier("modifier_muramasa_sword_creation","abilities/muramasa/muramasa_sword_creation", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_muramasa_rush_mr","abilities/muramasa/muramasa_sword_creation", LUA_MODIFIER_MOTION_NONE)

function muramasa_sword_creation:GetIntrinsicModifierName()
    return "modifier_muramasa_sword_creation"
end


function muramasa_sword_creation:CastFilterResult()
    local caster = self:GetCaster()
    if caster:GetModifierStackCount("modifier_muramasa_sword_creation", self) >= self:GetSpecialValueFor("max_stacks") then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function muramasa_sword_creation:GetCustomCastError()
	return "Already reached maximum stacks"
end

function muramasa_sword_creation:OnSpellStart()
    local caster = self:GetCaster()
    local currentstacks = caster:GetModifierStackCount("modifier_muramasa_sword_creation", self)
    caster:SetModifierStackCount("modifier_muramasa_sword_creation",caster, currentstacks+ 1)
    if(self.swordsfx ~= nil ) then
        Timers:RemoveTimer("muramasa_swords_particle")
        ParticleManager:DestroyParticle(self.swordsfx, true)
        ParticleManager:ReleaseParticleIndex(self.swordsfx)
    end
    self.swordsfx = ParticleManager:CreateParticle("particles/muramasa/muramasa_sword_creation.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
    ParticleManager:SetParticleControl(        self.swordsfx , 1,  Vector(currentstacks+ 1, 0,0 )  )  

    Timers:CreateTimer("muramasa_swords_particle", {
        endTime = 0.6,
        callback = function()
            ParticleManager:DestroyParticle(self.swordsfx, true)
            ParticleManager:ReleaseParticleIndex(self.swordsfx)
            self.swordsfx = nil
   end})
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
    if(self:GetAbility().swordsfx == nil) then return end
    Timers:CreateTimer(0.2, function() 
        if(self:GetAbility().swordsfx ~= nil) then
            Timers:RemoveTimer("muramasa_swords_particle")
            ParticleManager:DestroyParticle(self:GetAbility().swordsfx, true)
            ParticleManager:ReleaseParticleIndex(self:GetAbility().swordsfx)
            self:GetAbility().swordsfx = nil
        end
    end)
end
 

 function modifier_muramasa_sword_creation:OnAttackLanded(args)
    local caster = self:GetParent()
    if(args.attacker ~= caster ) then return end
local point = args.target:GetAbsOrigin()

local radius = self:GetAbility():GetSpecialValueFor("attack_aoe_radius")
local damage = self:GetAbility():GetSpecialValueFor("base_dmg") + self:GetAbility():GetSpecialValueFor("dmg_per_agi") *caster:GetBaseAgility() 
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
    
       
    end 

 end