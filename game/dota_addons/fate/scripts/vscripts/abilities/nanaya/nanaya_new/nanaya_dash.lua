LinkLuaModifier("modifier_nanaya_dash", "abilities/nanaya/nanaya_new/nanaya_dash", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nanaya_dash_invis", "abilities/nanaya/nanaya_new/nanaya_dash", LUA_MODIFIER_MOTION_NONE)

nanaya_dash = class({})

function nanaya_dash:OnSpellStart()
	local caster = self:GetCaster()

	ProjectileManager:ProjectileDodge(caster)
	local check = caster:GetAnglesAsVector():Normalized()
	local check2 = caster:GetForwardVector()

	local targetpoint = self:GetCursorPosition()

	if targetpoint == caster:GetAbsOrigin() then
		targetpoint = caster:GetAbsOrigin() + caster:GetForwardVector()
	end

	caster:AddNewModifier(caster, self, "modifier_nanaya_dash", {duration = 2})
	
	local jump = ParticleManager:CreateParticle("particles/blink.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(jump, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*-90)
	
	local jump2 = ParticleManager:CreateParticle("particles/shiki_blink_after.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(jump2, 0, GetGroundPosition(caster:GetAbsOrigin()+ caster:GetForwardVector():Normalized()*-250, nil))
	ParticleManager:SetParticleControl(jump2, 4, targetpoint)
	
	caster:EmitSound("nanaya.jumpforward")

	caster:AddNewModifier(caster, self, "modifier_nanaya_dash_invis", {duration = self:GetSpecialValueFor("invis_duration")})
end

modifier_nanaya_dash = class({})
function modifier_nanaya_dash:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_nanaya_dash:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end

function modifier_nanaya_dash:CheckState()
    local state =   { 
                        [MODIFIER_STATE_STUNNED] = true,
                        --[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    }
					   return state
end

function modifier_nanaya_dash:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
			MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE}
end
function modifier_nanaya_dash:GetOverrideAnimation()
	return ACT_SCRIPT_CUSTOM_27
end
function modifier_nanaya_dash:GetOverrideAnimationRate()
	return 2.0
end

function modifier_nanaya_dash:OnCreated()
	if not IsServer() then 
        return
    end

	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.point = self.ability:GetCursorPosition()

	if self.point == self:GetParent():GetAbsOrigin() then
		self.point = self:GetParent():GetAbsOrigin() + self:GetParent():GetForwardVector()
	end

	self.distances = self.ability:GetSpecialValueFor("range")

	if (self.point  - self.parent:GetAbsOrigin()):Length2D() > self.distances then
		self.point  = self.parent:GetAbsOrigin() + (((self.point - self.parent:GetAbsOrigin()):Normalized()) * self.distances)
	end

	self.distances = (self.point  - self.parent:GetAbsOrigin()):Length2D()

	self.direction = (self.point - self.parent:GetAbsOrigin()):Normalized()
	self:StartIntervalThink(FrameTime())
end

function modifier_nanaya_dash:OnIntervalThink()
	self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end

function modifier_nanaya_dash:UpdateHorizontalMotion(hero, times)
	if self.distances >= 0 then 
		local speed = 4000 * times
		local parent_pos = self.parent:GetAbsOrigin()
		
		self.next_pos = parent_pos + self.direction * speed
		self.distances = self.distances - speed
		self.parent:SetOrigin(self.next_pos)
	else
		self:Destroy()
	end
end
function modifier_nanaya_dash:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
	end
end
function modifier_nanaya_dash:OnDestroy()
	if IsServer() then
        self.parent:InterruptMotionControllers(true)
	end
end
function modifier_nanaya_dash:IsHidden()
	return true
end



modifier_nanaya_dash_invis = class({})

function modifier_nanaya_dash_invis:GetStatusEffectName()
	return "particles/status_fx/status_effect_phantom_assassin_fall20_active_blur.vpcf"
end

function modifier_nanaya_dash_invis:GetEffectName()
	return "particles/units/heroes/hero_phantom_assassin/phantom_assassin_active_blur.vpcf"
end

function modifier_nanaya_dash_invis:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_nanaya_dash_invis:DeclareFunctions()
     self.funcs = {MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
     				MODIFIER_PROPERTY_INVISIBILITY_LEVEL}
    return self.funcs
end

function modifier_nanaya_dash_invis:GetModifierInvisibilityLevel()
	return 1
end

function modifier_nanaya_dash_invis:CheckState()
	return {[MODIFIER_STATE_INVISIBLE] = true}
end

function modifier_nanaya_dash_invis:OnAbilityFullyCast(args)
    if args.unit == self:GetParent() then
    	if not (args.ability == self:GetAbility()) then
    		self:Destroy()
    	end
    end
end

function modifier_nanaya_dash_invis:IsDebuff()
    return false
end