muramasa_sword_creation = class({})
LinkLuaModifier("modifier_muramasa_sword_creation","abilities/muramasa/muramasa_sword_creation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_flame","abilities/muramasa/muramasa_sword_creation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_no_sword","abilities/muramasa/muramasa_sword_creation", LUA_MODIFIER_MOTION_NONE)
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
    MODIFIER_EVENT_ON_UNIT_MOVED,
    MODIFIER_EVENT_ON_RESPAWN,
    MODIFIER_PROPERTY_ATTACK_RANGE_BASE_OVERRIDE  }
end

function modifier_muramasa_sword_creation:OnCreated()
    self:SetStackCount(10)
end

function modifier_muramasa_sword_creation:OnRespawn(args)
    local caster = self:GetCaster() 
    if(caster ~= args.unit) then return end
    self:SetStackCount(10)
end

function modifier_muramasa_sword_creation:GetModifierAttackRangeOverride()
	return 150 * (self:GetCaster():HasModifier("modifier_muramasa_no_sword") and 0.5 or 1)
end

function modifier_muramasa_sword_creation:GetModifierAttackSpeed_Limit()
    if(self:GetCaster():HasModifier("modifier_muramasa_forge") or self:GetCaster():HasModifier("modifier_muramasa_sword_trial_buff")) then 
        return 2
    else    
        return 1
    end
end

function modifier_muramasa_sword_creation:GetModifierAttackSpeedBaseOverride()
    if(self:GetCaster():HasModifier("modifier_muramasa_forge") or self:GetCaster():HasModifier("modifier_muramasa_sword_trial_buff")) then 
        return 2
    else    
        return 1
    end
end

 

 

 function modifier_muramasa_sword_creation:OnAttackLanded(args)
    local caster = self:GetParent()
    if(args.attacker ~= caster ) then return end
local point = args.target:GetAbsOrigin()

local radius = self:GetAbility():GetSpecialValueFor("attack_aoe_radius")
local damage = self:GetAbility():GetSpecialValueFor("base_dmg") + self:GetAbility():GetSpecialValueFor("damage_per_level") *caster:GetLevel() 
local particlestring = "particles/muramasa/muramasa_atk_explosion_base.vpcf"

if(caster:HasModifier("modifier_berserk_scroll")) then
damage = damage + self:GetAbility():GetSpecialValueFor("dmg_berserker")
end
if(caster:HasModifier("modifier_muramasa_forge") or self:GetCaster():HasModifier("modifier_muramasa_sword_trial_buff")) then
radius = radius + 80
particlestring = "particles/muramasa/muramasa_atk_explosion_powered.vpcf"
end
 
if(caster:HasModifier("modifier_muramasa_dance_controller")) then -- check for Q cast
    damage = damage * self:GetCaster():FindAbilityByName("muramasa_dance"):GetSpecialValueFor("dmg_mod")/100
end

if caster.AppreciationOfSwordsAcquired then
    local cd= self.parent:FindAbilityByName("muramasa_forge"):GetCooldownTimeRemaining()
    self.parent:FindAbilityByName("muramasa_forge"):EndCooldown()
    if cd > 1 then 
        self.parent:FindAbilityByName("muramasa_forge"):StartCooldown(cd - 1)
    end
end
local stackCount = self:GetStackCount()
if(stackCount > 0 ) then
    local explosionFx = ParticleManager:CreateParticle(particlestring, PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(explosionFx, 0, point)

 local targets = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
    for k,v in pairs(targets) do        
        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)   
    end
    if( (stackCount - 1 )<= 0) then   
        self:SetStackCount(0)
        caster:EmitSound("muramasa_sword_break")
        caster:AddNewModifier(caster, self:GetAbility(), "modifier_muramasa_no_sword", {duration = 10})
    else
        self:SetStackCount(stackCount - 1)
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



modifier_muramasa_no_sword = class({})

function modifier_muramasa_no_sword:IsHidden() return false end
function modifier_muramasa_no_sword:DeclareFunctions()
  return { MODIFIER_PROPERTY_MODEL_CHANGE}
end

function modifier_muramasa_no_sword:GetModifierModelChange()
  return "models/muramasa/muramasa_no_sword.vmdl"
end

function modifier_muramasa_no_sword:OnDestroy()
    if not IsServer() then return  end
    local caster = self:GetCaster()
    local modifier = caster:FindModifierByName("modifier_muramasa_sword_creation")
    modifier:SetStackCount(10)
end