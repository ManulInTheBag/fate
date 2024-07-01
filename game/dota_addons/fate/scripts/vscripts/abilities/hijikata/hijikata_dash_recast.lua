hijikata_dash_recast = class({})
LinkLuaModifier("modifier_hijikata_rush", "abilities/hijikata/hijikata_dash_recast", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_hijikata_rotation_lock","abilities/hijikata/hijikata_dash_recast", LUA_MODIFIER_MOTION_NONE)

--[[
function hijikata_dash_recast:CastFilterResult()
	local caster = self:GetCaster()
	local target = caster.dash_target
    local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() 
	if distance > self:GetSpecialValueFor("distance") then
		return UF_FAIL_CUSTOM
	end

	return UF_SUCCESS
end

function hijikata_dash_recast:GetCustomCastError()
	return "not in the radius"
end
]]

function hijikata_dash_recast:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self
    
	if caster:FindAbilityByName("hijikata_dash"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("hijikata_dash"):SetLevel(self:GetLevel())
    end
 

end



function hijikata_dash_recast:OnSpellStart()
    local caster = self:GetCaster()
	local target = caster.dash_target
    local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() 
	if distance > self:GetSpecialValueFor("distance") then
		return
	end
    caster:AddNewModifier(caster, self, "modifier_hijikata_rotation_lock", {Duration = 0.3})
    StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_CAST_ABILITY_1_END, rate=1})

    Timers:CreateTimer(0.3, function() 
        local ring_fx = caster:FindAbilityByName("hijikata_dash").radius_ring_fx
        if ring_fx ~= nil then 
            ParticleManager:DestroyParticle(ring_fx, true)
            ParticleManager:ReleaseParticleIndex(ring_fx)
        end
        
        --caster:EmitSound("mordred_rush")

        self.damage = 250--self:GetSpecialValueFor("damage")
        self.speed = 2000--self:GetSpecialValueFor("speed")
        caster:AddNewModifier(caster, self, "modifier_hijikata_rush", {damage = self.damage,
                                                                        speed = self.speed })
        caster:RemoveModifierByName("modifier_hijikata_dash_recast_enable")
    end)                                                                
	
end




modifier_hijikata_rush = class({})

function modifier_hijikata_rush:OnCreated(hui)
    if not IsServer() then return end

	self.parent = self:GetParent()
    self.parent:Stop() 
	self.ability = self:GetAbility()
    self.damage_dealth = false
    self.parent:StartGesture(ACT_DOTA_AMBUSH)
    --self.parent:SetAnimation(ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_END) 
	self.target = self.parent.dash_target
	self.swordfx = ParticleManager:CreateParticle("particles/hijikata/hijikata_sword_dash.vpcf", PATTACH_ABSORIGIN_FOLLOW  , self.parent )
    ParticleManager:SetParticleControlEnt(self.swordfx, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_sword_base", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(self.swordfx, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_sword_end", Vector(0,0,0), true)
    if IsServer() then
		self.damage = hui.damage
		self.speed = hui.speed
       

        self.targetpos = self.target:GetAbsOrigin()

		self:StartIntervalThink(FrameTime())
		if self:ApplyHorizontalMotionController() == false then
            self:Destroy()
        end
	end
end
function modifier_hijikata_rush:OnRefresh(hui)
    self:OnCreated(hui)
end
function modifier_hijikata_rush:IsHidden() return false end
function modifier_hijikata_rush:IsDebuff() return false end
function modifier_hijikata_rush:RemoveOnDeath() return true end
function modifier_hijikata_rush:GetPriority() return MODIFIER_PRIORITY_HIGH end

function modifier_hijikata_rush:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_COMMAND_RESTRICTED] = true, }

    if self.target and not self.target:IsNull() and self.target:HasFlyMovementCapability() then
        state[MODIFIER_STATE_FLYING] = true
    else
        state[MODIFIER_STATE_FLYING] = false
    end
    
    return state
end

 

function modifier_hijikata_rush:OnDestroy()
    if not IsServer() then return end
    self.parent:AddNewModifier(self.parent, self.ability, "modifier_hijikata_rotation_lock", {duration = 0.15})
    self.parent:RemoveGesture(ACT_DOTA_AMBUSH)
    StartAnimation( self.parent, {duration=0.5, activity=ACT_DOTA_ALCHEMIST_CONCOCTION, rate=1.0})
    
    local pos = self.parent:GetOrigin()
    local direction = self.targetpos - pos
    direction.z = 0     
    local attackFx = ParticleManager:CreateParticle("particles/hijikata/hijikata_dash_slash.vpcf", PATTACH_ABSORIGIN_FOLLOW ,self.parent)  
    
    --ParticleManager:SetParticleControlTransformForward(attackFx, 0, self.parent:GetAbsOrigin(), direction)
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
        if self.parent:HasModifier("jump_pause_nosilence") then
        	self.parent:RemoveModifierByName("jump_pause_nosilence")
        end

        if self.swordfx then
            ParticleManager:DestroyParticle(self.swordfx, false)
            ParticleManager:ReleaseParticleIndex(self.swordfx)
        end
    end
end

function modifier_hijikata_rush:UpdateHorizontalMotion(me, dt)
    local UFilter = UnitFilter( self.target,
                                self.ability:GetAbilityTargetTeam(),
                                self.ability:GetAbilityTargetType(),
                                self.ability:GetAbilityTargetFlags(),
                                self.parent:GetTeamNumber() )

    if UFilter ~= UF_SUCCESS then
        self:Destroy()

        return nil
    end

    if (self.targetpos - self.target:GetAbsOrigin()):Length2D() > 300 then
        self:Destroy()

        return nil
    end

    self.targetpos = self.target:GetAbsOrigin() 
    self.distance = (self.target:GetOrigin() - self.parent:GetOrigin()):Length2D()

  
 
    if self.distance < 200 and self.damage_dealth == false then
        self:BOOM()
        return nil
    end
    if self.distance < 100 then
        self:Destroy()
        return nil
    end
    self:Rush(me, dt)
end
function modifier_hijikata_rush:BOOM()
    local position = self.target:GetAbsOrigin()
    local damage = self.damage
    self.damage_dealth = true
    if IsSpellBlocked(self.target) then return end
   
    


        local blow_fx =     ParticleManager:CreateParticle("particles/econ/items/void_spirit/void_spirit_immortal_2021/void_spirit_immortal_2021_astral_step_dmg_blood.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
                            ParticleManager:SetParticleControl(blow_fx, 0, position)
                            ParticleManager:ReleaseParticleIndex(blow_fx)
    	if not self.target:IsMagicImmune() then
            Timers:CreateTimer(0.1, function()
                DoDamage(self.parent, self.target, damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
            end)
            
        end
    
        EmitSoundOnLocationWithCaster(position, "Archer.HruntHit", self.parent)


end
function modifier_hijikata_rush:Rush(me, dt)
    --[[if self.parent:IsStunned() then
        return nil
    end]]

    local pos = self.parent:GetOrigin()
    local targetpos = self.target:GetOrigin()

    local direction = targetpos - pos
    direction.z = 0     
    local target = pos + direction:Normalized() * (self.speed * dt)

    self.parent:SetOrigin(target)
    self.parent:FaceTowards(self.targetpos)

end

function modifier_hijikata_rush:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end

function modifier_hijikata_rush:GetEffectName()
    return "particles/hijikata/hijikata_dash_effects.vpcf"
end

function modifier_hijikata_rush:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
 

modifier_hijikata_rotation_lock = class({})


function modifier_hijikata_rotation_lock:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_DISABLE_TURNING  }

	return funcs
end

function modifier_hijikata_rotation_lock:GetModifierDisableTurning() 
	return 1
end
 


function modifier_hijikata_rotation_lock:CheckState()
    local state =   { 
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		
                    }
    return state
end
 
function modifier_hijikata_rotation_lock:IsHidden() return true end
function modifier_hijikata_rotation_lock:RemoveOnDeath() return true end
