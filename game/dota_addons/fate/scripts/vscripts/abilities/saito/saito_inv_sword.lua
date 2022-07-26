LinkLuaModifier("modifier_saito_magres_down","abilities/saito/saito_inv_sword", LUA_MODIFIER_MOTION_NONE)
 saito_inv_sword = class({})

function saito_inv_sword:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
function saito_inv_sword:GetCastPoint()
    
	local Caster = self:GetCaster() 
    local stack_count = 0
    if(Caster:HasModifier("modifier_saito_fdb_repeated")) then
		stack_count = Caster:GetModifierStackCount("modifier_saito_fdb_repeated", Caster)  
	end
	if(Caster:HasModifier("modifier_saito_fdb_lastE")) then
		return 0.6
	end
    if stack_count <=2 then
		return 0.3
	elseif stack_count > 2 and stack_count < 5 then
		return 0.25
	else
		return 0.2
	end
end


function saito_inv_sword:GetPlaybackRateOverride()
	local Caster = self:GetCaster() 
	local stack_count = 0
	if(Caster:HasModifier("modifier_saito_fdb_lastE")) then		
		return 0.5
	end
	if(Caster:HasModifier("modifier_saito_fdb_repeated")) then
		stack_count = Caster:GetModifierStackCount("modifier_saito_fdb_repeated",Caster) 
	end
    if stack_count <=2 then
		return 1
	elseif stack_count > 2 and stack_count < 5 then
		return 1.2
	else
		return 1.4
	end
end


function saito_inv_sword:OnUpgrade()
    local Caster = self:GetCaster() 
    if(Caster:FindAbilityByName("saito_quickslash"):GetLevel()< self:GetLevel()) then
    Caster:FindAbilityByName("saito_quickslash"):SetLevel(self:GetLevel())
    end
    if(Caster:FindAbilityByName("saito_clap"):GetLevel()< self:GetLevel()) then
        Caster:FindAbilityByName("saito_clap"):SetLevel(self:GetLevel())
    end
end

function saito_inv_sword:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
    local damage = self:GetSpecialValueFor("damage")
    if(caster.FreestyleAcquired) then
        damage = damage + caster:GetAttackDamage()*self:GetSpecialValueFor("atk_scale")
    end
    if(IsServer )then
		if(caster:HasModifier("modifier_saito_fdb_lastE")) then
			damage = damage/2
			 
		end
	end
    local range = self:GetSpecialValueFor("range")
    local width = 120
    local FirstTarget = nil
    local AttackedTargets = {}
    local modifier_jopa = caster:FindModifierByName("modifier_saito_fdb")
    local slashes = ParticleManager:CreateParticle("particles/saito/saito_slash_enemy_3.vpcf", PATTACH_CUSTOMORIGIN, nil)
   
    caster:AddNewModifier(caster, caster, "modifier_saito_fdb_lastE",{duration = 15})
	caster:RemoveModifierByName("modifier_saito_fdb_lastQ")
	caster:RemoveModifierByName("modifier_saito_fdb_lastW")
    modifier_jopa:SpendStack()
    local angle = VectorToAngles(caster:GetForwardVector()).y
    local counter = 0
    local caster_pos =  caster:GetAbsOrigin() + caster:GetForwardVector()*self:GetSpecialValueFor("range")/2 
    local angle = VectorToAngles(caster:GetForwardVector()).y
    ParticleManager:SetParticleControl(slashes, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*self:GetSpecialValueFor("range")/2 )
    ParticleManager:SetParticleControl(slashes, 1,  Vector(0,angle-90,0))
    ParticleManager:SetParticleControl(slashes, 2,  Vector(900,0,0))
  

    caster:EmitSound("saito_inv_sword1")


    Timers:CreateTimer("Saito_slash", {
        endTime = 0.02,
        callback = function()
        if(counter > self:GetCastPoint()) then return end
        ParticleManager:DestroyParticle(slashes, false)
        ParticleManager:ReleaseParticleIndex(slashes)
        slashes = ParticleManager:CreateParticle("particles/saito/saito_slash_enemy_3.vpcf", PATTACH_CUSTOMORIGIN, nil)
        local diff = 700/self:GetCastPoint()/5*2
        local ring = 900-counter*diff*5
        if(ring <900-700) then 
            ring = 900-700
        end
        ParticleManager:SetParticleControl(slashes, 0, caster_pos)
        ParticleManager:SetParticleControl(slashes, 1,  Vector(0,angle-90,0))
        ParticleManager:SetParticleControl(slashes, 2,  Vector(ring,0,0))
        counter = counter +  self:GetCastPoint()/5
        caster:EmitSound("saito_inv_sword2")
		return 0.02
	end})

    --StartAnimation(caster, {duration = 1, activity = ACT_DOTA_RAZE_3, rate = 1+(0.4-self:GetCastPoint())*2})  
    local targets = FindUnitsInLine(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        caster:GetAbsOrigin()+range*caster:GetForwardVector(),
                                        nil,
                                        width,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
                                        )
    for _, enemy in pairs(targets) do
        if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
            if not FirstTarget then                                      
                FirstTarget = enemy
                damage = damage 
             end

            AttackedTargets[enemy:entindex()] = true

            if not enemy:IsMagicImmune() then
                DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
                if(caster.MasteryAcquired) then 
                    enemy:AddNewModifier(caster, self, "modifier_saito_magres_down", {Duration = 2})     
                end
            end
             --giveUnitDataDrivenModifier(caster, enemy, "locked", self:GetSpecialValueFor("airborn_duration"))
             enemy:AddNewModifier(caster, enemy, "modifier_stunned", {duration = 0.1})

             ApplyAirborneOnly(enemy, 500, self:GetSpecialValueFor("airborn_duration"))
             Timers:CreateTimer(self:GetSpecialValueFor("airborn_duration"), function()
                 enemy:SetAbsOrigin(GetGroundPosition(enemy:GetAbsOrigin(),enemy))
            end)                

            	
        end
    end
    Timers:CreateTimer(self:GetCastPoint()/2, function()
                                    local targets = FindUnitsInLine(  caster:GetTeamNumber(),
                                    caster:GetAbsOrigin(),
                                    caster:GetAbsOrigin()+range*caster:GetForwardVector(),
                                    nil,
                                    width,
                                    DOTA_UNIT_TARGET_TEAM_ENEMY,
                                    DOTA_UNIT_TARGET_ALL,
                                    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
        )
        ParticleManager:DestroyParticle(slashes, false)
        ParticleManager:ReleaseParticleIndex(slashes)
        local slashes_2 = ParticleManager:CreateParticle("particles/saito/saito_slash_enemy_2.vpcf", PATTACH_CUSTOMORIGIN, nil)
        local counter = 0
        local caster_pos =  caster:GetAbsOrigin() + caster:GetForwardVector()*self:GetSpecialValueFor("range")/2 
        local angle = VectorToAngles(caster:GetForwardVector()).y
        Timers:CreateTimer(0.02, function()
      
            if(counter > self:GetCastPoint()) then return end
            ParticleManager:DestroyParticle(slashes_2, false)
            ParticleManager:ReleaseParticleIndex(slashes_2)
            Timers:RemoveTimer("Saito_slash")
            slashes = ParticleManager:CreateParticle("particles/saito/saito_slash_enemy_2.vpcf", PATTACH_CUSTOMORIGIN, nil)
            local diff = 720/self:GetCastPoint()/5
            local ring = 900-counter*diff*5
            if(ring <900-720) then 
                ring = 900-720
            end
            ParticleManager:SetParticleControl(slashes, 0, caster_pos )
            ParticleManager:SetParticleControl(slashes, 1,  Vector(0,angle-90,0))
            ParticleManager:SetParticleControl(slashes, 2,  Vector(ring,0,0))
            counter = counter +  self:GetCastPoint()/5
          
            return 0.02
        end)




     
     for _, enemy in pairs(targets) do
        if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
            if not FirstTarget then                                      
                FirstTarget = enemy
                damage = damage 
             end

            AttackedTargets[enemy:entindex()] = true
            if not enemy:IsMagicImmune() then
                DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
            end
             --giveUnitDataDrivenModifier(caster, enemy, "locked", self:GetSpecialValueFor("airborn_duration"))
             enemy:AddNewModifier(caster, enemy, "modifier_stunned", {duration = 0.1})
 
        end
    end
    end)

end

modifier_saito_magres_down = class({})

function modifier_saito_magres_down:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }

	return funcs
end

function modifier_saito_magres_down:GetModifierMagicalResistanceBonus()
	return -self:GetAbility():GetSpecialValueFor("mr_down")
end

function modifier_saito_magres_down:IsHidden()
	return false 
end

function modifier_saito_magres_down:RemoveOnDeath()
	return true 
end