LinkLuaModifier("modifier_nanaya_e_jump", "abilities/nanaya/nanaya_e_jump", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("nanaya_e_jump_invisibility", "abilities/nanaya/nanaya_e_jump", LUA_MODIFIER_MOTION_NONE)

nanaya_e_jump = class({})

function nanaya_e_jump:OnSpellStart()
	local caster = self:GetCaster()
	local check = caster:GetAnglesAsVector():Normalized()
	local check2 = caster:GetForwardVector()
	local targetpoint = self:GetCursorPosition()
	caster:AddNewModifier(caster, self, "modifier_nanaya_e_jump", {duration = 2})
	local jump = ParticleManager:CreateParticle("particles/blink.vpcf", PATTACH_CUSTOMORIGIN, caster)
	local sAbil = caster:GetAbilityByIndex(0):GetAbilityName()
	 if sAbil == "nanaya_q2jump" then
		caster:SwapAbilities("nanaya_q_strike", "nanaya_q2jump", true, false)
end
	ParticleManager:SetParticleControl(jump, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*-90)
	
	local jump2 = ParticleManager:CreateParticle("particles/shiki_blink_after.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(jump2, 0, GetGroundPosition(caster:GetAbsOrigin()+ caster:GetForwardVector():Normalized()*-250, nil))
	ParticleManager:SetParticleControl(jump2, 4, targetpoint)
	caster:EmitSound("nanaya.jumpforward")
	if caster.enanaya then 
		caster:AddNewModifier(caster, self, "nanaya_e_jump_invisibility", {duration = 0.4})
	end

	
	print (check)
	print (check2)
end

function nanaya_e_jump:GetCastPoint()
return 0.01
end

function nanaya_e_jump:GetPlaybackRateOverride()
return 1.8
end

function nanaya_e_jump:GetCastAnimation()
return ACT_SCRIPT_CUSTOM_27
end

modifier_nanaya_e_jump = class({})
function modifier_nanaya_e_jump:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_nanaya_e_jump:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end

function modifier_nanaya_e_jump:CheckState()
    local state =   { 
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        --[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,

                    }
					   return state
end


function modifier_nanaya_e_jump:OnCreated()
	if not IsServer() then 
        return
    end 
	self.parent = self:GetParent()
		self.ability = self:GetAbility()
		self.point = self.ability:GetCursorPosition()
		--self.distances = self.ability:GetSpecialValueFor("range")

		self.distances = 800

	if (self.point  - self.parent:GetAbsOrigin()):Length2D() > self.distances then
		self.point  = self.parent:GetAbsOrigin() + (((self.point - self.parent:GetAbsOrigin()):Normalized()) * self.distances)
end
	self.distances = (self.point  - self.parent:GetAbsOrigin()):Length2D()

		--self.point = self.parent:GetAbsOrigin() + (((self.point - self.parent:GetAbsOrigin()):Normalized()) * self.distances)
	--end

		self.direction = (self.point - self.parent:GetAbsOrigin()):Normalized()
		self:StartIntervalThink(FrameTime())
	end


function modifier_nanaya_e_jump:OnIntervalThink()
	self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end

function modifier_nanaya_e_jump:UpdateHorizontalMotion(hero, times)
	if self.distances >= 0 then 
		local speed = 4000 * times
		local parent_pos = self.parent:GetAbsOrigin()
		
		self.next_pos = parent_pos + self.direction * speed
		self.distances = self.distances - speed
		self.parent:SetOrigin(self.next_pos)
		--self.parent:FaceTowards(self.point)
	else
		self:Destroy()
	end

		--self:Destroy()
	end

function modifier_nanaya_e_jump:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
	end
end


function modifier_nanaya_e_jump:OnDestroy()
	
	if IsServer() then
        self.parent:InterruptMotionControllers(true)
	end
end

	nanaya_e_jump_invisibility = class({})

	if IsServer() then 
	function nanaya_e_jump_invisibility:OnCreated(args)
		self.State = {[MODIFIER_STATE_INVISIBLE] = true}
		 


	end
end

 

function nanaya_e_jump_invisibility:DeclareFunctions()
     self.funcs = {MODIFIER_EVENT_ON_ABILITY_FULLY_CAST}
    return self.funcs
end

function nanaya_e_jump_invisibility:CheckState()
	return self.State
end


function nanaya_e_jump_invisibility:OnDestroy()
	--local illusion =  self:GetCaster().illusion 
	--if IsValidEntity(illusion) and not illusion:IsNull() then 
	--	illusion:ForceKill(false)
	--end

end

--[[function nanaya_e_jump_invisibility:OnAbilityFullyCast(args)
        if args.unit == self:GetParent() then
         
                self:Destroy()
            end
        end]]

 --[[function nanaya_e_jump_invisibility:OnAbilityFullyCast(args)
        if args.unit == self:GetParent() then
                self:Destroy()
            end
    end]]


function nanaya_e_jump_invisibility:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function nanaya_e_jump_invisibility:IsPurgable()
    return true
end

function nanaya_e_jump_invisibility:IsDebuff()
    return false
end

function nanaya_e_jump_invisibility:RemoveOnDeath()
    return true
end

function nanaya_e_jump_invisibility:GetTexture()
    return "custom/true_assassin_ambush"
end
------------