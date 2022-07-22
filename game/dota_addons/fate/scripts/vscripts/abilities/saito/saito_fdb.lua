
LinkLuaModifier("modifier_saito_fdb", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_repeated", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_lastQ", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_lastW", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_lastE", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_vision", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)


saito_hajime_fdb = class({})

function saito_hajime_fdb:GetIntrinsicModifierName()
    return "modifier_saito_fdb"
end

function saito_hajime_fdb:GetAOERadius()
	return self:GetSpecialValueFor("vision_range")
end

 


function saito_hajime_fdb:OnUpgrade()
    if(self:GetCaster():FindModifierByName("modifier_saito_fdb") ~= null) then
    self:GetCaster():FindModifierByName("modifier_saito_fdb"):SetStackCount(self:GetCaster():FindModifierByName("modifier_saito_fdb"):GetMaxStackCount())
    end
end

function saito_hajime_fdb:OnSpellStart()

    local caster = self:GetCaster()
    self.fx = ParticleManager:CreateParticle("particles/saito/saito_fdb.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
 


    
    caster:AddNewModifier(caster, self, "modifier_saito_fdb_vision",{duration = (self:GetSpecialValueFor("vision_duration")+ (caster.UndefeatableSwordsmanAcquired and 2 or 0) )})
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, self:GetSpecialValueFor("vision_range"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    for _,v in pairs(targets) do
    	if not v:HasModifier("modifier_murderer_mist_in") then
			v:AddNewModifier(caster, self, "modifier_vision_provider", { duration = self:GetSpecialValueFor("vision_duration") })
		end
    end	
	self:CheckCombo()

end
function saito_hajime_fdb:CheckCombo()
	local caster = self:GetCaster()
	local ability = self
 
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then      
    	if caster:FindAbilityByName("saito_undefeatable_style"):IsCooldownReady() 
    		and caster:FindAbilityByName("saito_formlessness"):IsCooldownReady() 
    		and not caster:HasModifier("modifier_saito_formlessness_tracker") then
             
    		caster:SwapAbilities("saito_undefeatable_style", "saito_hajime_fdb", true, false)

    		Timers:CreateTimer('saito_trigger_window',{
		        endTime = 2,
		        callback = function()
		        if caster:GetAbilityByIndex(4):GetName() ~= "saito_hajime_fdb" and  caster:GetAbilityByIndex(4):GetName() ~= "saito_undefeatable_style_active" then
		       		caster:SwapAbilities("saito_undefeatable_style", "saito_hajime_fdb", false, true)
		       	end
		    end
		    })
 
        end
    end
 
end

modifier_saito_fdb = class({})
 

function modifier_saito_fdb:OnCreated()
    self:SetStackCount(self:GetMaxStackCount())
end


function modifier_saito_fdb:OnRespawn()
    self:SetStackCount(self:GetMaxStackCount())
end


function modifier_saito_fdb:GetMaxStackCount()
    return self:GetAbility():GetSpecialValueFor("recast_amount")
end

function modifier_saito_fdb:SpendStack()
    local stacks = self:GetStackCount()
    local caster = self:GetParent()
    local abilitycd = caster:GetAbilityByIndex(1):GetCooldown(caster:GetAbilityByIndex(1):GetLevel()-1)
    if(stacks<=0) then 
        caster:GetAbilityByIndex(0):StartCooldown(abilitycd)    
        caster:GetAbilityByIndex(1):StartCooldown(abilitycd)
        caster:GetAbilityByIndex(2):StartCooldown(abilitycd)
        --caster:GetAbilityByIndex(4):StartCooldown(abilitycd)
        caster:RemoveModifierByName("modifier_saito_fdb_lastQ")
        caster:RemoveModifierByName("modifier_saito_fdb_lastE")
        caster:RemoveModifierByName("modifier_saito_fdb_lastW")
        return false end
    if(stacks==1) then 
            caster:GetAbilityByIndex(0):StartCooldown(abilitycd)    
            caster:GetAbilityByIndex(1):StartCooldown(abilitycd)
            caster:GetAbilityByIndex(2):StartCooldown(abilitycd)
           -- caster:GetAbilityByIndex(4):StartCooldown(abilitycd)
            caster:RemoveModifierByName("modifier_saito_fdb_lastQ")
            caster:RemoveModifierByName("modifier_saito_fdb_lastE")
            caster:RemoveModifierByName("modifier_saito_fdb_lastW")
    end  
    local caster = self:GetAbility():GetCaster()
    self:SetStackCount(stacks-1)
    if(caster:HasModifier("modifier_saito_fdb_repeated")) then
        local repeatedStacks = caster:GetModifierStackCount("modifier_saito_fdb_repeated", self)
        if(repeatedStacks <=self:GetMaxStackCount()) then           
            caster:SetModifierStackCount("modifier_saito_fdb_repeated",caster, repeatedStacks +1)
        end
    else
        caster:AddNewModifier(caster,self.ability,"modifier_saito_fdb_repeated",{})       
    end
    
    return true
end

function modifier_saito_fdb:IsHidden()	return false end
function modifier_saito_fdb:RemoveOnDeath()return false end 
function modifier_saito_fdb:IsDebuff() 	return false end


modifier_saito_fdb_repeated = class({})

function modifier_saito_fdb_repeated:OnCreated()
    if not IsServer() then 
        return
    end 
    self:SetStackCount(1)
    local caster = self:GetParent()
    local abilitycd = caster:GetAbilityByIndex(1):GetCooldown(caster:GetAbilityByIndex(1):GetLevel()-1)
    caster:GetAbilityByIndex(0):EndCooldown()    
    caster:GetAbilityByIndex(1):EndCooldown()
    caster:GetAbilityByIndex(2):EndCooldown()
    Timers:RemoveTimer("repeated_saito")
    local time_interval = 1 - 0.05*self:GetStackCount()
    if(caster.FreestyleAcquired) then
        time_interval = time_interval +0.2
    end
    Timers:CreateTimer("repeated_saito", {
		endTime = time_interval, 
        callback = function()
        self:GetParent():RemoveModifierByName("modifier_saito_fdb_repeated")
      
        --caster:GetAbilityByIndex(4):StartCooldown(abilitycd)
        caster:GetAbilityByIndex(0):StartCooldown(abilitycd)    
        caster:GetAbilityByIndex(1):StartCooldown(abilitycd)
        caster:GetAbilityByIndex(2):StartCooldown(abilitycd)
        caster:RemoveModifierByName("modifier_saito_fdb_lastQ")
        caster:RemoveModifierByName("modifier_saito_fdb_lastE")
        caster:RemoveModifierByName("modifier_saito_fdb_lastW")
        if(not (caster:HasModifier("modifier_saito_mind_eye") or caster:HasModifier("modifier_saito_formlessness_casting") ) ) then
            --caster:GetAbilityByIndex(4):StartCooldown(abilitycd)
            caster:GetAbilityByIndex(0):StartCooldown(abilitycd)    
            caster:GetAbilityByIndex(1):StartCooldown(abilitycd)
            caster:GetAbilityByIndex(2):StartCooldown(abilitycd)
            caster:RemoveModifierByName("modifier_saito_fdb_lastQ")
            caster:RemoveModifierByName("modifier_saito_fdb_lastE")
            caster:RemoveModifierByName("modifier_saito_fdb_lastW")
            self:GetParent():FindModifierByName("modifier_saito_fdb"):SetStackCount(self:GetParent():FindModifierByName("modifier_saito_fdb"):GetMaxStackCount())
        end
    end})
end

function modifier_saito_fdb_repeated:OnStackCountChanged()
    if not IsServer() then 
        return
    end 
    local caster = self:GetParent()
    local abilitycd = caster:GetAbilityByIndex(1):GetCooldown(caster:GetAbilityByIndex(1):GetLevel()-1)
    if( caster:FindModifierByName("modifier_saito_fdb"):GetStackCount()>0) then
        caster:GetAbilityByIndex(0):EndCooldown()    
        caster:GetAbilityByIndex(1):EndCooldown()
        caster:GetAbilityByIndex(2):EndCooldown()
    end
    Timers:RemoveTimer("repeated_saito")
    local time_interval = 1 - 0.05*self:GetStackCount()
    if(caster.FreestyleAcquired) then
        time_interval = time_interval +0.2
    end
    Timers:CreateTimer("repeated_saito", {
		endTime = time_interval, 
        callback = function()
        self:GetParent():RemoveModifierByName("modifier_saito_fdb_repeated")
       
        if(not (caster:HasModifier("modifier_saito_mind_eye") or caster:HasModifier("modifier_saito_formlessness_casting") ) ) then
            --caster:GetAbilityByIndex(4):StartCooldown(abilitycd)
            caster:GetAbilityByIndex(0):StartCooldown(abilitycd)    
            caster:GetAbilityByIndex(1):StartCooldown(abilitycd)
            caster:GetAbilityByIndex(2):StartCooldown(abilitycd)
            caster:RemoveModifierByName("modifier_saito_fdb_lastQ")
            caster:RemoveModifierByName("modifier_saito_fdb_lastE")
            caster:RemoveModifierByName("modifier_saito_fdb_lastW")
            self:GetParent():FindModifierByName("modifier_saito_fdb"):SetStackCount(self:GetParent():FindModifierByName("modifier_saito_fdb"):GetMaxStackCount())
        end
    end})
end

function modifier_saito_fdb_repeated:GetTexture()
	return "custom/saito/saito_fdb_repeated"
end


function modifier_saito_fdb_repeated:IsHidden()	return false end
function modifier_saito_fdb_repeated:RemoveOnDeath()return true end 
function modifier_saito_fdb_repeated:IsDebuff() 	return false end

modifier_saito_fdb_lastQ = class({})
function modifier_saito_fdb_lastQ:IsHidden()	return true end
function modifier_saito_fdb_lastQ:RemoveOnDeath()return true end 
function modifier_saito_fdb_lastQ:IsDebuff() 	return false end
modifier_saito_fdb_lastW = class({})
function modifier_saito_fdb_lastW:IsHidden()	return true end
function modifier_saito_fdb_lastW:RemoveOnDeath()return true end 
function modifier_saito_fdb_lastW:IsDebuff() 	return false end
modifier_saito_fdb_lastE = class({})
function modifier_saito_fdb_lastE:IsHidden()	return true end
function modifier_saito_fdb_lastE:RemoveOnDeath()return true end 
function modifier_saito_fdb_lastE:IsDebuff() 	return false end


modifier_saito_fdb_vision = class({})

function modifier_saito_fdb_vision:OnTakeDamage(args)
    local caster =self:GetParent()
    if(  args.attacker ~= caster) then return end
    if(args.damage_category == 0) then
        local ability = self:GetParent():FindAbilityByName("saito_hajime_fdb")
      
        
        caster:SetMana(caster:GetMana()+ability:GetSpecialValueFor("mana_refund"))
        if(caster.UndefeatableSwordsmanAcquired)then
            caster:SetHealth(caster:GetHealth()+ability:GetSpecialValueFor("health_refund"))
        end

    end


end

function modifier_saito_fdb_vision:OnRefresh()
    ParticleManager:DestroyParticle(self.particleid, false)
	ParticleManager:ReleaseParticleIndex(self.particleid)
    self.particleid = self:GetAbility().fx
    end
    

function modifier_saito_fdb_vision:OnCreated()
self.particleid = self:GetAbility().fx

end

function modifier_saito_fdb_vision:OnDestroy()
    if not IsServer() then 
        return
    end 
	ParticleManager:DestroyParticle(self.particleid, false)
	ParticleManager:ReleaseParticleIndex(self.particleid)

end

function modifier_saito_fdb_vision:GetTexture()
	return "custom/saito/saito_fdb"
end

function modifier_saito_fdb_vision:IsHidden()	return false end
function modifier_saito_fdb_vision:RemoveOnDeath()return true end 
function modifier_saito_fdb_vision:IsDebuff() 	return false end