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
    caster:EmitSound("merlin_excalibur")
    local counter = self:GetSpecialValueFor("damage_ticks")
    local damage = self:GetSpecialValueFor("damage_min") +(caster.KingAssistantAcquired and caster:GetIntellect()*self:GetSpecialValueFor("dmg_per_int") or 0)
    local damage_inc = self:GetSpecialValueFor("damage_increase") 
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
    caster:AddNewModifier(caster, ability, "modifier_merlin_excalibur_attack", {duration = self:GetSpecialValueFor("buff_duration")})
    Timers:CreateTimer(0.1, function() 
     
        local start_location = caster:GetAttachmentOrigin(3) 
        self.excalibur_glow = ParticleManager:CreateParticle("particles/merlin/excalibur_glow.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
        self.excalibur_beam = ParticleManager:CreateParticle("particles/merlin/excalibur_path.vpcf", PATTACH_CUSTOMORIGIN, nil)
       
        ParticleManager:SetParticleControl(self.excalibur_glow, 0, start_location     ) 
        ParticleManager:SetParticleControl(self.excalibur_glow, 1, start_location ) 
        ParticleManager:SetParticleControl(self.excalibur_glow, 2, start_location+Vector(0,0,-80)) 
        ParticleManager:SetParticleControl(self.excalibur_beam, 0, caster:GetAbsOrigin()+caster:GetForwardVector() *130) 
        ParticleManager:SetParticleControl(self.excalibur_beam, 1, caster:GetAbsOrigin()+caster:GetForwardVector() *range) 
        ParticleManager:SetParticleControl(self.excalibur_beam, 5,caster:GetAbsOrigin() ) --rings position

 
 
        Timers:CreateTimer(0.0, function() 
               counter = counter - 1
       
            if(counter == 0 ) then 
                ParticleManager:DestroyParticle(self.excalibur_glow, true)
                ParticleManager:ReleaseParticleIndex(self.excalibur_glow)
                ParticleManager:DestroyParticle(self.excalibur_beam, true)
                ParticleManager:ReleaseParticleIndex(self.excalibur_beam)
                ParticleManager:DestroyParticle(self.excalibur_pull, true)
                ParticleManager:ReleaseParticleIndex(self.excalibur_pull)
            return end
            if(counter <= 7 ) then 
                self.excalibur_pull = ParticleManager:CreateParticle("particles/merlin/merlin_excalibur_pull.vpcf", PATTACH_CUSTOMORIGIN, nil)
                ParticleManager:SetParticleControl(self.excalibur_pull, 0, caster:GetAbsOrigin()+caster:GetForwardVector() *range*1.1)  
                ParticleManager:SetParticleControl(self.excalibur_pull, 1, -caster:GetForwardVector() *range)  
                 angle = VectorToAngles(caster:GetForwardVector()).y
                ParticleManager:SetParticleControl(self.excalibur_pull, 2,  Vector(0,angle+90,0))

            end
       
            ParticleManager:SetParticleControl(self.excalibur_beam, 0, caster:GetAbsOrigin()+caster:GetForwardVector() *130) 
            ParticleManager:SetParticleControl(self.excalibur_beam, 1, caster:GetAbsOrigin()+caster:GetForwardVector() *range) 
           

            

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
                    if not enemy:IsMagicImmune() then
                          DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
                          enemy:AddNewModifier(caster, ability, "modifier_stunned", {duration = 0.02})

                          enemy:AddNewModifier(caster, ability, "modifier_merlin_movement",{duration = 0.11 })
                    end
                    
                end    

            	
            end
            damage = damage + damage_inc
            return 0.1
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
 		DoDamage(caster, target, self:GetAbility():GetSpecialValueFor("on_hit_dmg") + (caster.KingAssistantAcquired and caster:GetIntellect()*self:GetAbility():GetSpecialValueFor("att_dmg_per_int") or 0), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
         
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
