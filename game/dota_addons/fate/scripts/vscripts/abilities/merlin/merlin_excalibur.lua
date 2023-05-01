LinkLuaModifier("modifier_merlin_movement","abilities/merlin/merlin_excalibur", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_excalibur_attack","abilities/merlin/merlin_excalibur", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_self_stun","abilities/merlin/merlin_excalibur", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_atk_sound","abilities/merlin/merlin_excalibur", LUA_MODIFIER_MOTION_NONE)
merlin_excalibur = class({})


function merlin_excalibur:GetIntrinsicModifierName()
	return "modifier_merlin_atk_sound"
end


function merlin_excalibur:OnSpellStart()
    local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local ability = self
    caster:StartGesture(ACT_DOTA_AMBUSH)
    caster:EmitSound("merlin_excalibur")
    local counter = self:GetSpecialValueFor("ticks") 
    local damage = self:GetSpecialValueFor("damage") +(caster.KingAssistantAcquired and caster:GetIntellect()*self:GetSpecialValueFor("dmg_per_int") or 0)
    local range = self:GetSpecialValueFor("range")
    local width = self:GetSpecialValueFor("width")
    caster:FindAbilityByName("merlin_charisma"):AttStack() 
    if(caster.RapidChantingAcquired) then
		local cd1 = caster:GetAbilityByIndex(0):GetCooldownTimeRemaining()
		local cd3 = caster:GetAbilityByIndex(1):GetCooldownTimeRemaining()
		caster:GetAbilityByIndex(0):EndCooldown()
		caster:GetAbilityByIndex(1):EndCooldown()
        if(cd1 > 0 ) then
		    caster:GetAbilityByIndex(0):StartCooldown(cd1 -1)
        end
		if(caster:GetAbilityByIndex(2):GetName() ~= "merlin_garden_of_avalon") then
			local cd2 = caster:GetAbilityByIndex(2):GetCooldownTimeRemaining()
			caster:GetAbilityByIndex(2):EndCooldown()
            if(cd2 > 0 ) then
			    caster:GetAbilityByIndex(2):StartCooldown(cd2 -1)
            end
		end
        if(cd3 > 0 ) then
	    	caster:GetAbilityByIndex(1):StartCooldown(cd3 -1)
        end
	end
    caster:AddNewModifier(caster, ability, "modifier_merlin_self_stun", {duration = 1})

    local pull_center = caster:GetAbsOrigin()+caster:GetForwardVector() *220
    local range = self:GetSpecialValueFor("range")
    local pepega_end = GetGroundPosition(caster:GetAbsOrigin() + caster:GetForwardVector()*(range), caster)
    local pepega_vec = (pepega_end - caster:GetAbsOrigin()):Normalized()
    local distance_min = self:GetSpecialValueFor("distance_min")
    AddFOWViewer(2,caster:GetAbsOrigin() + pepega_vec*1000 + Vector(0, 0, 266), 10, 1, false)
    AddFOWViewer(3,caster:GetAbsOrigin() + pepega_vec*1000 + Vector(0, 0, 266), 10, 1, false)
    local excalpepegFxIndex = ParticleManager:CreateParticle("particles/merlin/melin_excalibur_test_pepeg.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(excalpepegFxIndex, 0, pull_center)
    ParticleManager:SetParticleControl(excalpepegFxIndex, 1, caster:GetAbsOrigin() + pepega_vec*800 + Vector(0, 0, 266)) 
    Timers:CreateTimer(0.8, function()
        ParticleManager:DestroyParticle( excalpepegFxIndex, false )
        ParticleManager:ReleaseParticleIndex( excalpepegFxIndex )
    end)
    Timers:CreateTimer(0.1, function()
        local excalFxIndex = ParticleManager:CreateParticle("particles/merlin/melin_excalibur_test.vpcf", PATTACH_ABSORIGIN, caster)
        local pepega_end = GetGroundPosition(caster:GetAbsOrigin() + caster:GetForwardVector()*(1000), caster)
        local pepega_vec = (pepega_end - caster:GetAbsOrigin()):Normalized()
           ParticleManager:SetParticleControl(excalFxIndex, 0, pull_center)
           ParticleManager:SetParticleControl(excalFxIndex, 1, caster:GetAbsOrigin() + pepega_vec*800 + Vector(0, 0, 266)) 
           Timers:CreateTimer(0.9, function()
            ParticleManager:DestroyParticle( excalFxIndex, false )
            ParticleManager:ReleaseParticleIndex( excalFxIndex )
        end)
        self.knockback = { should_stun = false,
                                knockback_duration = 0.05,
                                duration = 0.05,
                                knockback_distance = -60,
                                knockback_height =  0,
                                center_x = pull_center.x,
                                center_y = pull_center.y,
                                center_z = pull_center.z }
  
        Timers:CreateTimer(0.0, function() 
            if(caster:IsAlive() == false) then counter = 0 return end
            if(counter <= 0) then caster:AddNewModifier(caster, ability, "modifier_merlin_excalibur_attack", {duration = self:GetSpecialValueFor("buff_duration")}) return end
                
            counter = counter - 1    
            local targets = FindUnitsInLine(caster:GetTeam(), pull_center, pepega_end, nil, width, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0)  
            for k,v in pairs(targets) do            
                if not v:IsMagicImmune() then
                    DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
                    if((v:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > 350 and not IsKnockbackImmune(v))  then
                        v:RemoveModifierByName("modifier_knockback")
                        v:AddNewModifier(caster, self, "modifier_knockback", self.knockback)   
                    end
                    v:AddNewModifier(caster, ability, "modifier_stunned", {duration = 0.06})
              end
            end 
            return 0.05
        end)
    end)
 

end
modifier_merlin_atk_sound = class({})



function modifier_merlin_atk_sound:OnCreated()
	self.sound = "Tsubame_Slash_"..math.random(1,3)
end

function modifier_merlin_atk_sound:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end
	self.sound = "Tsubame_Slash_"..math.random(1,3)

end

function modifier_merlin_atk_sound:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_merlin_atk_sound:DeclareFunctions()
	local func = {
					MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,

				}
	return func
end

function modifier_merlin_atk_sound:GetAttackSound()
	return self.sound
end

function modifier_merlin_atk_sound:IsHidden() return true end
function modifier_merlin_atk_sound:RemoveOnDeath() return true end

 
modifier_merlin_movement = class({})
 
 
function modifier_merlin_movement:OnCreated()    
    if IsServer() then	 
        local caster = self:GetCaster()
        local enemy = self:GetParent()
        if((enemy:GetAbsOrigin() -  caster:GetAbsOrigin()):Length2D() > 500) then
            local pushback = Physics:Unit(enemy)
            enemy:PreventDI()
            enemy:SetPhysicsFriction(0)
            enemy:SetPhysicsVelocity(-(enemy:GetAbsOrigin() -  caster:GetAbsOrigin()):Normalized() * 300)
            enemy:SetNavCollisionType(PHYSICS_NAV_NOTHING)
            enemy:FollowNavMesh(false)
            
             
        end
    end

end

 
function modifier_merlin_movement:OnRefresh()    
    if IsServer() then	 
        local caster = self:GetCaster()
        local enemy = self:GetParent()
        if((enemy:GetAbsOrigin() -  caster:GetAbsOrigin()):Length2D() < 500) then
            enemy:PreventDI(false)
            enemy:SetPhysicsVelocity(Vector(0,0,0))
            enemy:OnPhysicsFrame(nil)
            FindClearSpaceForUnit(enemy, enemy:GetAbsOrigin(), true)
            
             
        end
    end

end


function modifier_merlin_movement:OnDestroy()    
    if IsServer() then	 
 
        local enemy = self:GetParent()
        
                   enemy:PreventDI(false)
                   enemy:SetPhysicsVelocity(Vector(0,0,0))
                   enemy:OnPhysicsFrame(nil)
                   FindClearSpaceForUnit(enemy, enemy:GetAbsOrigin(), true)
           
    end

end
    
  

 
function modifier_merlin_movement:IsHidden() return true end
function modifier_merlin_movement:RemoveOnDeath() return true end


modifier_merlin_excalibur_attack = class({})

function modifier_merlin_excalibur_attack:OnCreated( )
    self.particle = ParticleManager:CreateParticle("particles/merlin/merlin_excalibur_self.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(    self.particle , 0,  self:GetParent():GetAbsOrigin() )  
end

function modifier_merlin_excalibur_attack:OnRefresh()  
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = ParticleManager:CreateParticle("particles/merlin/merlin_excalibur_self.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(    self.particle , 0,  self:GetParent():GetAbsOrigin() )  
end

function modifier_merlin_excalibur_attack:OnDestroy( )
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
end


function modifier_merlin_excalibur_attack:OnAttackLanded(keys)
	local caster = self:GetCaster()
	local target = keys.target

	if keys.attacker ~= caster or target == caster then return end

	if IsServer() then
 		DoDamage(caster, target, self:GetAbility():GetSpecialValueFor("on_hit_damage") + (caster.KingAssistantAcquired and caster:GetIntellect()*self:GetAbility():GetSpecialValueFor("att_dmg_per_int") or 0), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
         
	end
    local particle = ParticleManager:CreateParticle("particles/merlin/merlin_excalibur_attack.vpcf", PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin()+Vector(0,0,150))  
end

 
function modifier_merlin_excalibur_attack:IsHidden() return false end
function modifier_merlin_excalibur_attack:RemoveOnDeath() return true end


modifier_merlin_self_stun = class({})

function modifier_merlin_self_stun:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_DISABLE_TURNING }

	return funcs
end

function modifier_merlin_self_stun:GetModifierDisableTurning() 
	return 1
end
 
function modifier_merlin_self_stun:CheckState()
    local state =   { 
 
						[MODIFIER_STATE_ROOTED] = true,
						[MODIFIER_STATE_DISARMED] = true,
 						[MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                        

                    }
    return state
end



 
function modifier_merlin_self_stun:IsHidden() return true end
function modifier_merlin_self_stun:RemoveOnDeath() return true end
