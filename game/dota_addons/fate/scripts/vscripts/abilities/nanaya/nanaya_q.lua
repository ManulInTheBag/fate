LinkLuaModifier("modifier_q_nanaya", "abilities/nanaya/nanaya_q", LUA_MODIFIER_MOTION_HORIZONTAL)


jump_nanaya = class({})

function jump_nanaya:OnSpellStart()
    local caster = self:GetCaster() 
    ProjectileManager:ProjectileDodge(caster)
	caster:EmitSound("nanaya.jumpforward")
	local jump = ParticleManager:CreateParticle("particles/blink.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(jump, 0, caster:GetAbsOrigin() + caster:GetForwardVector())
	ParticleManager:SetParticleControl(jump, 4, self:GetCursorPosition())
	local blink_target = self:GetCursorPosition()
	
	local dist = self:GetSpecialValueFor("distance")
	if (blink_target - caster:GetAbsOrigin()):Length2D() > dist then 
		blink_target = caster:GetAbsOrigin() + (((blink_target - caster:GetAbsOrigin()):Normalized()) * dist)
	end
	FindClearSpaceForUnit(caster, blink_target , true) 
end

nanaya_q_strike = class ({})

function nanaya_q_strike:OnSpellStart()
	local caster = self:GetCaster()
	ProjectileManager:ProjectileDodge(caster)
	local check = caster:GetAnglesAsVector():Normalized()
	local check2 = caster:GetForwardVector()
	local targetpoint = self:GetCursorTarget()
	caster:AddNewModifier(caster, self, "modifier_q_nanaya", {duration = 2})
	local jump = ParticleManager:CreateParticle("particles/blink.vpcf", PATTACH_CUSTOMORIGIN, caster)
	
	
	ParticleManager:SetParticleControl(jump, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*-90)
	
	local jump2 = ParticleManager:CreateParticle("particles/shiki_blink_after.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(jump2, 0, GetGroundPosition(caster:GetAbsOrigin()+ caster:GetForwardVector():Normalized()*-250, nil))
	ParticleManager:SetParticleControl(jump2, 4, caster:GetAbsOrigin())
	caster:EmitSound("nanaya.jumpforward")
	
	print (check)
	print (check2)
end

function nanaya_q_strike:OnUpgrade()
	local hCaster = self:GetCaster()
    
    if hCaster:FindAbilityByName("nanaya_q2jump"):GetLevel() ~= self:GetLevel() then
      hCaster:FindAbilityByName("nanaya_q2jump"):SetLevel(self:GetLevel())
end
end

modifier_q_nanaya = class ({})

function modifier_q_nanaya:OnCreated(args)
	self.parent = self:GetParent()
	self.ability = self:GetAbility()	
	self.speed = 2800
	self.caster = self:GetCaster()
	
	if IsServer() then
		self.target = self.ability:GetCursorTarget()
		self.targetpos = self.target:GetAbsOrigin()
		self.parent:StartGestureWithPlaybackRate(ACT_SCRIPT_CUSTOM_15, 1)
		print ("1")
		if self:ApplyHorizontalMotionController() == false then
            self:Destroy()
		end
		--self:StartIntervalThink(FrameTime())
	end
end


function modifier_q_nanaya:OnIntervalThink()
	--self:UpdateHorizontalMotion(FrameTime())
end

function modifier_q_nanaya:IsHidden() return false end
function modifier_q_nanaya:IsDebuff() return true end
function modifier_q_nanaya:RemoveOnDeath() return true end
function modifier_q_nanaya:GetPriority() return MODIFIER_PRIORITY_HIGH end


function modifier_q_nanaya:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		--[MODIFIER_STATE_DISARMED] = true,
		--[MODIFIER_STATE_SILENCED] = true,
	[MODIFIER_STATE_COMMAND_RESTRICTED] = true, }
	
	
    if self.target and not self.target:IsNull() and self.target:HasFlyMovementCapability() then
        state[MODIFIER_STATE_FLYING] = true
		else
        state[MODIFIER_STATE_FLYING] = false
	end
    
    return state
end

--[[function modifier_q_nanaya:DeclareFunctions() 
	local funcs = {
	MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
	}
	
	return funcs
end]]

function modifier_q_nanaya:UpdateHorizontalMotion(me, dt)
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
	
	--if (self.target:GetOrigin() - self.parent:GetOrigin() + self.parent:GetForwardVector()*180):Length2D() < 150 then
	if (self.target:GetOrigin() - self.parent:GetOrigin()):Length2D() < 150 then
		self:hit()
		self:Destroy()
		
		return nil
	end
	print ("1")
	self:dash(me, dt)
end

--[[function modifier_q_nanaya:GetOverrideAnimation()
	return ACT_SCRIPT_CUSTOM_14
	end
	
	function modifier_q_nanaya:GetOverrideAnimationRate()
	return 1
end]]


function modifier_q_nanaya:hit()
	--DoDamage(self.parent, self.target, 250, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
	self.dmg = self.ability:GetSpecialValueFor("dmg") + math.floor(self:GetCaster():GetAgility()*2)
							DoDamage(self.parent, self.target, self.dmg/2, DAMAGE_TYPE_PHYSICAL, 0, self, false)
							DoDamage(self.parent, self.target, self.dmg/2, DAMAGE_TYPE_PHYSICAL, 0, self, false)
						 --self.target:AddNewModifier(caster, self, "modifier_stunned", { Duration = 1 })
	self.target:EmitSound("nanaya.slash")
	local effect_cast = ParticleManager:CreateParticle( "particles/justcheck.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.target)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self.target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		self.target:GetOrigin(), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlForward( effect_cast, 1, (self.target:GetOrigin()+self.parent:GetOrigin()):Normalized() )
	ParticleManager:ReleaseParticleIndex( effect_cast )
	local effect_cast2 = ParticleManager:CreateParticle( "particles/nanaya_hit_test22.vpcf", PATTACH_CUSTOMORIGIN, self.parent)

			ParticleManager:SetParticleControl(effect_cast2, 1, self.target:GetAbsOrigin())
			--ParticleManager:SetParticleControl(effect_cast2, 0, self.target:GetAbsOrigin() - self.parent:GetForwardVector()*50 + Vector(0, 0, 200))
			ParticleManager:SetParticleControlEnt(effect_cast2, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_knife", self.parent:GetAbsOrigin(), true)

	local effect_cast1 = ParticleManager:CreateParticle( "particles/nanaya_combo_1hit2_.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self.parent)
	
	--[[ParticleManager:SetParticleControlEnt(
		effect_cast1,
		3,
		self.target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		self.target:GetOrigin(), -- unknown
		true -- unknown, true
		)
		
		--ParticleManager:SetParticleControl(effect_cast1, 4, self.target:GetAbsOrigin()-Vector(0, 0, 30))
	ParticleManager:SetParticleControl(effect_cast1, 4, self.target:GetAbsOrigin()+self.parent:GetForwardVector()*90)]]
	--ParticleManager:SetParticleControl(effect_cast1, 0, self.parent:GetAbsOrigin())
	ParticleManager:SetParticleControl(effect_cast1, 1, self.target:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex( effect_cast1 )
	self.parent:FaceTowards(self.parent:GetOrigin() + self.parent:GetForwardVector()*180)
	self.parent:SetOrigin(self.parent:GetOrigin() + self.parent:GetForwardVector()*180)
end

function modifier_q_nanaya:dash(me, dt)
	--[[if self.parent:IsStunned() then
		return nil
	end]]
	
	local pos = self.parent:GetOrigin()
	local targetpos = self.target:GetOrigin()
	
	local direction = targetpos - pos
	direction.z = 0     
	local target = pos + direction:Normalized() * (self.speed * dt)
	
	self.parent:SetOrigin(target)
	self.parent:FaceTowards(targetpos)
end

function modifier_q_nanaya:OnHorizontalMotionInterrupted()
	if IsServer() then
		self:Destroy()
	end
end

function modifier_q_nanaya:OnDestroy()
	
	if IsServer() then
		self.parent:RemoveGesture(ACT_SCRIPT_CUSTOM_15)
		self.parent:InterruptMotionControllers(true)
		self.parent:StartGestureWithPlaybackRate(ACT_SCRIPT_CUSTOM_14, 0.8)
	end
end		