muramasa_eye_of_karma = class({})
LinkLuaModifier("modifier_muramasa_eye_of_karma","abilities/muramasa/muramasa_eye_of_karma", LUA_MODIFIER_MOTION_NONE)
 
function muramasa_eye_of_karma:OnSpellStart()
    local caster = self:GetCaster()
    local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, self:GetSpecialValueFor("search_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
    local target = nil
 
    --searching for non-assasins, if there is no present, take first assasin, if there is none - do nothing. 
    -- CanBeDetected() is fate function, check  vscripts\libraries\util file
    for _,v in pairs(targets) do
    	if   CanBeDetected(v) then
            target = v
            target:AddNewModifier(caster, self, "modifier_muramasa_eye_of_karma", { duration = self:GetSpecialValueFor("duration")+ 1.55 })
            return
         end
    end	
    if(target == nil and targets[1] ~= nil) then
       target = targets[1] 
       target:AddNewModifier(caster, self, "modifier_muramasa_eye_of_karma", { duration = self:GetSpecialValueFor("duration") + 1.55 })
    end    
     
end
 

modifier_muramasa_eye_of_karma = class({})
----------------------------------------
---note: blink lock abilities list are present at vscripts\libraries\util file
----------------------------------------

function modifier_muramasa_eye_of_karma:IsHidden()	return false end
function modifier_muramasa_eye_of_karma:RemoveOnDeath()return true end 
function modifier_muramasa_eye_of_karma:IsDebuff() 	return true end

----stacks of MR reduction initialized  and particle added  
function modifier_muramasa_eye_of_karma:OnCreated()
if(not IsServer()) then return end
local caster = self:GetCaster()
self.atkstacks = 0
caster.eyeofkarmafx = ParticleManager:CreateParticle("particles/muramasa/eye_of_karma_base.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
 ParticleManager:SetParticleShouldCheckFoW(caster.eyeofkarmafx, false)
self.visionenabled = 0
self:GetParent():EmitSound("Hero_Bane.Nightmare.Loop")
------ to grant vision and lock after 1 second
local duration = self:GetAbility():GetSpecialValueFor("duration") 
Timers:CreateTimer(1.55, function()      
    self:GetParent():StopSound("Hero_Bane.Nightmare.Loop")
    giveUnitDataDrivenModifier(caster,  self:GetParent(), "locked", duration)
    self:GetParent():AddNewModifier(caster, self:GetAbility(), "modifier_vision_provider", { Duration = duration })
    self:GetParent():EmitSound("Hero_Bane.Nightmare")
end)
 
------
end

--------------------------------------
-------particle is saved into caster to dodge possible particle not found problems
--------------------------------------

function modifier_muramasa_eye_of_karma:OnDestroy()
    if(not IsServer()) then return end
    ParticleManager:DestroyParticle(self:GetCaster().eyeofkarmafx, true)
	ParticleManager:ReleaseParticleIndex(self:GetCaster().eyeofkarmafx)

end
----
----on refresh does not execute OnCreated and OnDestroyed, so i need to just remember values  
----
function modifier_muramasa_eye_of_karma:OnRefresh(args)
   self.atkstacks = args.atkstacks
   self.visionenabled = args.visionenabled
end
 

function modifier_muramasa_eye_of_karma:DeclareFunctions()
    return {  MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS   }
end


 
function modifier_muramasa_eye_of_karma:GetModifierMagicalResistanceBonus()
    if( IsServer()) then 
	    return  -1*self:GetAbility():GetSpecialValueFor("mr_reduction_per_attack")*self.atkstacks 
    end
end

 
 

 function modifier_muramasa_eye_of_karma:OnAttackLanded(args)
    ------checking if the attacker is muramasa and he is under ulti buff
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local attacker = args.attacker
    if(attacker ~= caster ) then return end
    if(not attacker:HasModifier("modifier_muramasa_tsumukari_buff") ) then return end
    --------------------------------------------------------
    --increasing mr reduction and providing debuff extension 
    -------------------------------------------------------
    self.atkstacks = self.atkstacks +1
    -------------------------------------------------------
 
    local debufduration  = self:GetDuration()  + 0.5 - (self:GetDuration() - self:GetRemainingTime())
   
    self:GetParent():AddNewModifier(caster,ability, "modifier_muramasa_eye_of_karma", { duration = debufduration,atkstacks = self.atkstacks, visionenabled = self.visionenabled})
    self:GetParent():AddNewModifier(caster, ability, "modifier_vision_provider", { duration = debufduration })
    giveUnitDataDrivenModifier(caster,  self:GetParent(), "locked", debufduration )

end

 

  