muramasa_tsumukari = class({})
LinkLuaModifier("modifier_muramasa_tsumukari","abilities/muramasa/muramasa_tsumukari", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_tsumukari_buff","abilities/muramasa/muramasa_tsumukari", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_sword_trial_buff","abilities/muramasa/muramasa_tsumukari", LUA_MODIFIER_MOTION_NONE)


function muramasa_tsumukari:GetIntrinsicModifierName()
    return "modifier_muramasa_tsumukari"
end

function muramasa_tsumukari:CastFilterResult()
    local caster = self:GetCaster()
    if  caster:HasModifier("modifier_muramasa_tsumukari_buff") then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function muramasa_tsumukari:GetCustomCastError() 
    local caster = self:GetCaster()
    if(caster:HasModifier("modifier_muramasa_tsumukari_buff") ) then 
        return "Already under ability effect"
    end
end

function muramasa_tsumukari:OnUpgrade()
    local Caster = self:GetCaster() 
    if(Caster:FindAbilityByName("muramasa_tsumukari_release"):GetLevel()< self:GetLevel()) then
    Caster:FindAbilityByName("muramasa_tsumukari_release"):SetLevel(self:GetLevel())
    end
    
end
 
function muramasa_tsumukari:OnSpellStart()
local caster = self:GetCaster()
local selfstacks = caster:GetModifierStackCount("modifier_muramasa_tsumukari", caster)
 
    local sound = "muramasa_chant_"..(selfstacks+1) 
    if(selfstacks == 7) then
        EmitGlobalSound(sound) 
    else
        caster:EmitSound(sound)
    end
    if(caster.FlameAcquired) then
        local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
        for k,v in pairs(targets) do            
            DoDamage(caster, v, self:GetSpecialValueFor("base_dmg") + caster:GetAgilityGain()*caster:GetLevel() *self:GetSpecialValueFor("dmg_per_agi"), DAMAGE_TYPE_MAGICAL, 0, self, false)
        end 
    end
    if(selfstacks <7) then
        if(caster.swordsfx ~= nil ) then
            Timers:RemoveTimer("muramasa_swords_particle")
            ParticleManager:DestroyParticle(caster.swordsfx, true)
            ParticleManager:ReleaseParticleIndex(caster.swordsfx)
        end
        caster.swordsfx = ParticleManager:CreateParticle("particles/muramasa/muramasa_sword_creation.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
        ParticleManager:SetParticleControl(        caster.swordsfx , 1,  Vector(selfstacks+ 1, 0,0 )  )  

        Timers:CreateTimer("muramasa_swords_particle", {
                 endTime = 0.6,
                 callback = function()
                 ParticleManager:DestroyParticle(caster.swordsfx, true)
                 ParticleManager:ReleaseParticleIndex(caster.swordsfx)
                 caster.swordsfx = nil
        end})
    end
    if(caster.SwordTrialAcquired) then
        caster:AddNewModifier(caster, self, "modifier_muramasa_sword_trial_buff", {duration = self:GetSpecialValueFor("att_duration")})
    end
    if(caster:HasModifier("modifier_muramasa_tsumukari")) then
        caster:SetModifierStackCount("modifier_muramasa_tsumukari", 
                                    caster, selfstacks+1 )
    else
        caster:AddNewModifier(caster, self, "modifier_muramasa_tsumukari", {})
         caster:SetModifierStackCount("modifier_muramasa_tsumukari", 
                                            caster, 1 )
    end 
    if(selfstacks == 7) then -- 7 = max stack - 1 
        --caster:RemoveModifierByName("modifier_muramasa_tsumukari")
        caster:SetModifierStackCount("modifier_muramasa_tsumukari", 
        caster, 0 )
        caster:AddNewModifier(caster, self, "modifier_muramasa_tsumukari_buff", {duration = self:GetSpecialValueFor("buff_duration")})
        self.swordfx = ParticleManager:CreateParticle("particles/muramasa/sword_glow.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
        ParticleManager:SetParticleControlEnt(self.swordfx, 1, caster, PATTACH_POINT_FOLLOW, "sword_base", Vector(0,0,0), true)
        ParticleManager:SetParticleControlEnt(self.swordfx, 2, caster, PATTACH_POINT_FOLLOW, "sword_end", Vector(0,0,0), true)
        caster:SwapAbilities("muramasa_tsumukari", "muramasa_tsumukari_release", false, true)
         Timers:CreateTimer("muramasa_sword_particle", {
             endTime = self:GetSpecialValueFor("buff_duration"),
             callback = function()
             if(not caster:IsAlive()) then return end
             if(self.swordfx ~= nil ) then
                    ParticleManager:DestroyParticle(self.swordfx, true)
                     ParticleManager:ReleaseParticleIndex(self.swordfx)
                     self.swordfx = nil
             end
             if(caster:GetAbilityByIndex(5):GetName() == "muramasa_tsumukari_release") then
                caster:SwapAbilities("muramasa_tsumukari", "muramasa_tsumukari_release", true, false)
             end
             local abilitycd = self:GetSpecialValueFor("cd_after_release")
             self:StartCooldown(abilitycd)    
        end})
    end
 
end

 
 

modifier_muramasa_tsumukari = class({})
function modifier_muramasa_tsumukari:IsHidden()    return false end
function modifier_muramasa_tsumukari:RemoveOnDeath()return true end 
function modifier_muramasa_tsumukari:IsDebuff()    return false end

function modifier_muramasa_tsumukari:DeclareFunctions()
	return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, 
        MODIFIER_EVENT_ON_RESPAWN
 
 
	}
end



function modifier_muramasa_tsumukari:OnRespawn(args)
local caster = self:GetCaster()
    if(caster ~= args.unit) then return end
    self:SetStackCount(0)
end

function modifier_muramasa_tsumukari:GetModifierMagicalResistanceBonus()
    local caster = self:GetCaster()
	return  self:GetAbility():GetSpecialValueFor("attribute_mr")  * (caster.AppreciationOfSwordsAcquired and 1 or 0) 
    *(caster:HasModifier("modifier_muramasa_tsumukari_buff") and 12 or self:GetStackCount() )
end

 

function modifier_muramasa_tsumukari:GetModifierPhysicalArmorBonus()
    local caster = self:GetCaster()
    return  self:GetAbility():GetSpecialValueFor("attribute_armor")  * (caster.AppreciationOfSwordsAcquired and 1 or 0) 
    *(caster:HasModifier("modifier_muramasa_tsumukari_buff") and 12 or self:GetStackCount() )
end

function modifier_muramasa_tsumukari:GetModifierMoveSpeedBonus_Percentage()
    local caster = self:GetCaster()
    return  self:GetAbility():GetSpecialValueFor("attribute_ms")  * (caster.AppreciationOfSwordsAcquired and 1 or 0) 
    *(caster:HasModifier("modifier_muramasa_tsumukari_buff") and 12 or self:GetStackCount() )
end

modifier_muramasa_tsumukari_buff = class({})
function modifier_muramasa_tsumukari_buff:IsHidden()    return false end
function modifier_muramasa_tsumukari_buff:RemoveOnDeath()return true end 
function modifier_muramasa_tsumukari_buff:IsDebuff()    return false end



function modifier_muramasa_tsumukari_buff:OnDestroy()
    if(not IsServer() ) then return end
    local caster = self:GetCaster()
    if(Timers.timers["muramasa_sword_particle"] ~= nil) then
        Timers:RemoveTimer("muramasa_sword_particle")
    end
    if(self:GetAbility().swordfx ~= nil )then 
        ParticleManager:DestroyParticle(self:GetAbility().swordfx, true)
        ParticleManager:ReleaseParticleIndex(self:GetAbility().swordfx)
        self:GetAbility().swordfx = nil
    end
    if(caster:GetAbilityByIndex(5):GetName() == "muramasa_tsumukari_release") then
         caster:SwapAbilities("muramasa_tsumukari", "muramasa_tsumukari_release", true, false)
    end
    
    local abilitycd = self:GetAbility():GetSpecialValueFor("cd_after_release")
    self:GetAbility():StartCooldown(abilitycd)    
end
function modifier_muramasa_tsumukari_buff:GetTexture()
return "custom/muramasa/muramasa_tsumukari_end"

end

 

modifier_muramasa_sword_trial_buff = class({})
function modifier_muramasa_sword_trial_buff:IsHidden()    return false end
function modifier_muramasa_sword_trial_buff:RemoveOnDeath()return true end 
function modifier_muramasa_sword_trial_buff:IsDebuff()    return false end

function modifier_muramasa_sword_trial_buff:OnAttackLanded(args)
    local ability = self:GetAbility()
    if(ability:GetCooldownTimeRemaining() > 1) then
        ability:EndCooldown()
        ability:StartCooldown(1)
    end
    self:Destroy()
end

function modifier_muramasa_sword_trial_buff:GetTexture()
    return "custom/muramasa/muramasa_sword_trial_attribute"
    
    end
    
     