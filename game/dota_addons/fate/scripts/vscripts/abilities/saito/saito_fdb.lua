
LinkLuaModifier("modifier_saito_fdb", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_pause", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_repeated", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_lastQ", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_lastW", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_lastE", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_vision", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_fdb_vision_provider", "abilities/saito/saito_fdb", LUA_MODIFIER_MOTION_NONE)


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
 
    damage_stored = {} 
    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true and playerHero == self:GetCaster() then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="saito_pidaras"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
    
    caster:AddNewModifier(caster, self, "modifier_saito_fdb_vision",{duration = (self:GetSpecialValueFor("buff_duration")+ (caster.UndefeatableSwordsmanAcquired and 2 or 0) )})
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, self:GetSpecialValueFor("vision_range"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    for _,v in pairs(targets) do
    	if not v:HasModifier("modifier_murderer_mist_in") and   CanBeDetected(v) then
			v:AddNewModifier(caster, self, "modifier_saito_fdb_vision_provider", { duration = self:GetSpecialValueFor("vision_duration") })
		end
    end	
	self:CheckCombo()

end
function saito_hajime_fdb:CheckCombo()
	local caster = self:GetCaster()
	local ability = self
 
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then      
    	if caster:FindAbilityByName("saito_undefeatable_style"):IsCooldownReady()  then
             
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
    local caster = self:GetCaster()
    caster.currentused = 0
    self:SetStackCount(self:GetMaxStackCount())
end

function modifier_saito_fdb:DeclareFunctions()
	return { MODIFIER_EVENT_ON_RESPAWN,
			  }
			 
end


function modifier_saito_fdb:OnRespawn()
    local caster = self:GetParent()

    caster.currentused = 0
    self:SetStackCount(self:GetMaxStackCount())
end

 

function modifier_saito_fdb:GetMaxStackCount()
    return self:GetAbility():GetSpecialValueFor("recast_amount")
end

function modifier_saito_fdb:SpendStack()
    local stacks = self:GetStackCount()
    if(stacks < 1) then
        stacks = 1

    end
    local caster = self:GetParent()
    local abilitycd = caster:GetAbilityByIndex(1):GetCooldown(caster:GetAbilityByIndex(1):GetLevel()-1)
    if(caster:HasModifier("modifier_saito_combo")) then
        abilitycd = 3
    end
    if(stacks<=1) then 
        caster:GetAbilityByIndex(0):EndCooldown()    
        caster:GetAbilityByIndex(1):EndCooldown()
        caster:GetAbilityByIndex(2):EndCooldown()
        caster:GetAbilityByIndex(0):StartCooldown(abilitycd)    
        caster:GetAbilityByIndex(1):StartCooldown(abilitycd)
        caster:GetAbilityByIndex(2):StartCooldown(abilitycd)
 
         
 
        
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
    if(caster:HasModifier("modifier_saito_combo")) then
        abilitycd = 3
    end
    if(IsServer) then
        if(caster:GetModifierStackCount("modifier_saito_fdb",caster)>0) then
             caster:GetAbilityByIndex(0):EndCooldown()    
             caster:GetAbilityByIndex(1):EndCooldown()
             caster:GetAbilityByIndex(2):EndCooldown()
         end
    end
    Timers:RemoveTimer("repeated_saito")
    local time_interval = 1.2 - 0.05*self:GetStackCount()
    if(caster.FreestyleAcquired) then
        time_interval = time_interval +0.3
    end
    if (caster:GetModifierStackCount("modifier_saito_fdb",caster) == 0) then
        time_interval = 0.01 
    end
    Timers:CreateTimer("repeated_saito", {
		endTime = time_interval, 
        callback = function()
        if(caster:HasModifier("modifier_saito_fdb_repeated")) then
            caster:RemoveModifierByName("modifier_saito_fdb_repeated")
        end
      
        --caster:GetAbilityByIndex(4):StartCooldown(abilitycd)
        caster:GetAbilityByIndex(0):EndCooldown()    
        caster:GetAbilityByIndex(1):EndCooldown()
        caster:GetAbilityByIndex(2):EndCooldown()
        caster:GetAbilityByIndex(0):StartCooldown(abilitycd)    
        caster:GetAbilityByIndex(1):StartCooldown(abilitycd)
        caster:GetAbilityByIndex(2):StartCooldown(abilitycd)
 
         
        caster:RemoveModifierByName("modifier_saito_fdb_lastQ")
        caster:RemoveModifierByName("modifier_saito_fdb_lastE")
        caster:RemoveModifierByName("modifier_saito_fdb_lastW")
        if(not (caster:HasModifier("modifier_saito_mind_eye") or caster:HasModifier("modifier_saito_formlessness_casting") ) ) then
            --caster:GetAbilityByIndex(4):StartCooldown(abilitycd)
            caster:GetAbilityByIndex(0):EndCooldown()    
            caster:GetAbilityByIndex(1):EndCooldown()
            caster:GetAbilityByIndex(2):EndCooldown()
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
    if(caster:HasModifier("modifier_saito_combo")) then
        abilitycd = 3
    end
    if( caster:GetModifierStackCount("modifier_saito_fdb",caster)>0) then
        caster:GetAbilityByIndex(0):EndCooldown()    
        caster:GetAbilityByIndex(1):EndCooldown()
        caster:GetAbilityByIndex(2):EndCooldown()
    end
    Timers:RemoveTimer("repeated_saito")
    local time_interval = 1.2 - 0.05*self:GetStackCount()
    if(caster.FreestyleAcquired) then
        time_interval = time_interval +0.3
    end
    if (caster:GetModifierStackCount("modifier_saito_fdb",caster) == 0) then
        time_interval = 0.01 
    end
    Timers:CreateTimer("repeated_saito", {
		endTime = time_interval, 
        callback = function()
        if(caster:HasModifier("modifier_saito_fdb_repeated")) then
            caster:RemoveModifierByName("modifier_saito_fdb_repeated")
        end
       
        if(not (caster:HasModifier("modifier_saito_mind_eye") or caster:HasModifier("modifier_saito_formlessness_casting")  ) ) then
            --caster:GetAbilityByIndex(4):StartCooldown(abilitycd)
            caster:GetAbilityByIndex(0):EndCooldown()    
            caster:GetAbilityByIndex(1):EndCooldown()
            caster:GetAbilityByIndex(2):EndCooldown()
            caster:GetAbilityByIndex(0):StartCooldown(abilitycd)    
            caster:GetAbilityByIndex(1):StartCooldown(abilitycd)
            caster:GetAbilityByIndex(2):StartCooldown(abilitycd)
           
            caster:RemoveModifierByName("modifier_saito_fdb_lastQ")
            caster:RemoveModifierByName("modifier_saito_fdb_lastE")
            caster:RemoveModifierByName("modifier_saito_fdb_lastW") 
            caster:FindModifierByName("modifier_saito_fdb"):SetStackCount(caster:FindModifierByName("modifier_saito_fdb"):GetMaxStackCount())
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


 

function modifier_saito_fdb_vision:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local resist = self:GetAbility():GetSpecialValueFor("resist") 
    local counter = 4
    
    if(self.damage_stored == 0 or self.attacker == nil) then return end
    local  damagepertick =   self.damageStored/4
    damagepertick = damagepertick/(100-resist)*resist
    local attacker = self.attacker
    self.damageStored = 0
    self.attacker = nil
    Timers:CreateTimer(1.5, function()      
        if(not caster:IsAlive())then return end  
        counter = counter -1
 
         --if(caster:HasModifier("modifier_saito_fdb_vision")) then
         --   damagepertick = damagepertick/(100-resist)*100
         --end
      
         
        if (caster:GetHealth() - damagepertick  > 0) then
            caster:SetHealth(caster:GetHealth() -  damagepertick )
        else 
            caster:SetHealth(1)
            DoDamage(attacker, caster , damagepertick, DAMAGE_TYPE_PURE,  0, ability, true)
        end
        if(counter == 0) then
          
            return  
        end
        return 0.25
    
    end)
   

end

function modifier_saito_fdb_vision:OnTakeDamage(args)
    local caster =self:GetParent()
    local ability = self:GetAbility()
    --if(  args.attacker ~= caster) then return end
    local resist = self:GetAbility():GetSpecialValueFor("resist") 

    ----damage 
    if(  args.attacker ~= caster and args.inflictor ~= ability)then
        
            self.damageStored = self.damageStored + args.damage 
            self.attacker = args.attacker
 
    
    end

    ----------mana refund
    if(args.damage_category == 0 and args.inflictor ~= self:GetAbility() and args.unit:GetTeam() ~= caster:GetTeam() and args.unit:GetName() ~= "npc_dota_ward_base" ) then
        local ability = self:GetParent():FindAbilityByName("saito_hajime_fdb")
      
        
        caster:SetMana(caster:GetMana()+ability:GetSpecialValueFor("mana_refund"))
        if(caster.UndefeatableSwordsmanAcquired)then
            caster:SetHealth(caster:GetHealth()+ability:GetSpecialValueFor("health_refund"))
            
        end

    end


end

function modifier_saito_fdb_vision:OnRefresh()
    if type(self.particleid) == "number" then
        ParticleManager:DestroyParticle(self.particleid, false)
    	ParticleManager:ReleaseParticleIndex(self.particleid)
        self.particleid = self:GetAbility().fx
    end
    end
    
    --function modifier_saito_fdb_vision:OnIntervalThink()
    --    ability = self:GetAbility()
    --    damage = ability.damage_stored
       
     --   Timers:CreateTimer(1.5, function()        
    --        if(caster:HasModifier("modifier_saito_fdb_vision")) then
    --            local resist = self:GetAbility():GetSpecialValueFor("resist") 
    --            damage = damage /(100-resist)*100/5
     --        end
   --      DoDamage(ability.max_damage_unit, caster , damage, DAMAGE_TYPE_PURE,  0, ability, false)        
        
     --   end)
    --    ability.damage_stored = damage_stored- damage_stored*0.2
    --    ability.max_damage_unit = nil
  --  end
function modifier_saito_fdb_vision:OnCreated()
self.particleid = self:GetAbility().fx
self.damageStored = 0
self.attacker = nil
self:StartIntervalThink(0.5)

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


modifier_saito_fdb_vision_provider = class({})

function modifier_saito_fdb_vision_provider:DeclareFunctions()
    return { MODIFIER_PROPERTY_PROVIDES_FOW_POSITION }
end

function modifier_saito_fdb_vision_provider:GetModifierProvidesFOWVision()
    return 1
end

function modifier_saito_fdb_vision_provider:IsHidden()
    return false
end

function modifier_saito_fdb_vision_provider:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

modifier_saito_fdb_pause = class({})

function modifier_saito_fdb_pause:IsHidden()	return true end
function modifier_saito_fdb_pause:RemoveOnDeath()return true end 
function modifier_saito_fdb_pause:IsDebuff() 	return false end

function modifier_saito_fdb_pause:CheckState()
	return { [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_ROOTED] = true,
             [MODIFIER_STATE_MUTED] = true,
             [MODIFIER_STATE_SILENCED] = true,}
end	
