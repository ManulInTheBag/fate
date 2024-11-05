demon_king_materialization = class({})

LinkLuaModifier("modifier_demon_king_materialization", "abilities/demon_king_nobunaga/demon_king_materialization", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_demon_king_materialization_progress", "abilities/demon_king_nobunaga/demon_king_materialization", LUA_MODIFIER_MOTION_NONE)
function demon_king_materialization:GetIntrinsicModifierName()
    return "modifier_demon_king_materialization"
end

function demon_king_materialization:OnUpgrade()
    local hero = self:GetCaster()
    if not hero:HasModifier("modifier_demon_king_materialization_progress") then
        hero:AddNewModifier(hero, self, "modifier_demon_king_materialization_progress", {})
    end
end

modifier_demon_king_materialization = class({})
modifier_demon_king_materialization_progress = class({})
 
-------
--Stages are levels, on which DKN gains her powers back
--Starting with 0 and up to ?
--Maximum stage must be acquireble only in really long matches like 15-15 or at least 12-13  
--Stages are gained through suffering damage? 
-------



function modifier_demon_king_materialization:OnCreated()
    local caster = self:GetParent()
    self.damage_stored = 0
    caster.current_stage = 1
    self.stagesRequirements = {0, 10000, 50000, 100000}
    self:SetStackCount(0)
end

function modifier_demon_king_materialization:OnRespawn()
    self:UpdateProgress()
end


 

function modifier_demon_king_materialization:OnTakeDamage(args)
    local caster =self:GetParent()
    local ability = self:GetAbility()
    if(  args.attacker ~= caster or (args.attacker == caster and args.inflictor == caster:FindAbilityByName("demon_king_ignition")))then  
        local damage = args.damage
        local curhealth = caster:GetHealth()
        if(damage > curhealth) then  
            damage = curhealth
        end
        self.damage_stored = self.damage_stored + damage
        self:UpdateProgress()
   
        if(caster.current_stage < ability:GetSpecialValueFor("maximum_stage")) then
            self:CheckForStageUpgrade()        
        end

    end
end

function modifier_demon_king_materialization:UpdateProgress() 
    if IsServer() then
        local caster = self:GetParent()
        local progress = caster:FindModifierByName("modifier_demon_king_materialization_progress")
        progress:SetStackCount(self.damage_stored*100/self.stagesRequirements[caster.current_stage+1])
    end
end
 

function modifier_demon_king_materialization:CheckForStageUpgrade()
    local caster = self:GetParent()
    if(self.damage_stored > self.stagesRequirements[caster.current_stage+1])then
        print("StageLevelUp")
        print(self.damage_stored)
        caster.current_stage = caster.current_stage + 1
        self:SetStackCount(self:GetStackCount()+1)
    end

end

 
function modifier_demon_king_materialization:GetAttributes()
    return  MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE +  MODIFIER_ATTRIBUTE_PERMANENT
end
function modifier_demon_king_materialization:RemoveOnDeath() return false end 
function modifier_demon_king_materialization:IsDebuff() 	return false end

 




function modifier_demon_king_materialization_progress:IsHidden()	return true end
function modifier_demon_king_materialization_progress:GetAttributes()
    return  MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE +  MODIFIER_ATTRIBUTE_PERMANENT
end
function modifier_demon_king_materialization_progress:RemoveOnDeath() return false end 
function modifier_demon_king_materialization_progress:IsDebuff() 	return false end