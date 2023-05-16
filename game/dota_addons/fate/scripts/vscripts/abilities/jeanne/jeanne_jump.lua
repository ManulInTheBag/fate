LinkLuaModifier("modifier_jeanne_jump", "abilities/jeanne/jeanne_jump", LUA_MODIFIER_MOTION_BOTH)

jeanne_jump = class({})

function jeanne_jump:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_jeanne_jump", {})
end

function jeanne_jump:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function jeanne_jump:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function jeanne_jump:GetCustomCastErrorLocation(hLocation)
	if self:GetCaster():GetAbsOrigin().y < -2000 then
		return "#Inside_Reality_Marble"
	end
    return "#Wrong_Target_Location"
end

modifier_jeanne_jump = class({})
function modifier_jeanne_jump:IsHidden() return true end
function modifier_jeanne_jump:DeclareFunctions()
	return {	MODIFIER_PROPERTY_DISABLE_TURNING }
end
function modifier_jeanne_jump:GetModifierDisableTurning()
	return 1
end
function modifier_jeanne_jump:IsDebuff() return false end
function modifier_jeanne_jump:RemoveOnDeath() return true end
function modifier_jeanne_jump:CheckState()
    local state = { --[[[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_ROOTED] = true,
                    [MODIFIER_STATE_SILENCED] = true,]]
                    [MODIFIER_STATE_MUTED] = true,
                    [MODIFIER_STATE_DISARMED] = true,
                    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    --[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                }
    return state
end
function modifier_jeanne_jump:OnCreated()
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    if IsServer() then
        self.point = self.ability:GetCursorPosition()
        self.radius = self.ability:GetSpecialValueFor("radius")

        self.speed = self.ability:GetSpecialValueFor("speed")
        self.fly_duration = self.ability:GetSpecialValueFor("fly_duration")

        self.jump_start_pos = self.parent:GetOrigin()
        self.jump_distance = (self.point - self.jump_start_pos):Length2D()
        self.jump_direction = (self.point - self.jump_start_pos):Normalized()

        -- load data
        self.jump_duration = self.fly_duration--self.jump_distance/self.speed
        self.jump_hVelocity = self.jump_distance/self.fly_duration--self.speed

        self.jump_peak = self.ability:GetSpecialValueFor("max_height")
        
        --[[self.effect_duration = self.ability:GetSpecialValueFor("effect_duration")
        self.stun_height = self.ability:GetSpecialValueFor("stun_height")
        self.stun_damage = self.ability:GetSpecialValueFor("stun_damage")]]

        -- sync
        self.elapsedTime = 0
        self.motionTick = {}
        self.motionTick[0] = 0
        self.motionTick[1] = 0
        self.motionTick[2] = 0

        -- vertical motion model
        -- self.gravity = -10*1000
        self.jump_gravity = -self.jump_peak/(self.jump_duration*self.jump_duration*0.125)
        self.jump_vVelocity = (-0.5)*self.jump_gravity*self.jump_duration

        --[[local dash_fx = ParticleManager:CreateParticle("particles/heroes/anime_hero_uzume/uzume_dash.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
                        ParticleManager:SetParticleControl(dash_fx, 0, self.parent:GetOrigin()) -- point 0: origin, point 2: sparkles, point 5: burned soil
                        ParticleManager:SetParticleControl(dash_fx, 2, self.parent:GetOrigin())
                        ParticleManager:SetParticleControl(dash_fx, 5, self.parent:GetOrigin())

        self:AddParticle(dash_fx, false, false, -1, true, false)]]

        if self:ApplyVerticalMotionController() == false then
            self:Destroy()
        end
        if self:ApplyHorizontalMotionController() == false then 
            self:Destroy()
        end
    end
end
function modifier_jeanne_jump:UpdateHorizontalMotion(me, dt)
    self:SyncTime(1, dt)

    local target = self.jump_direction * self.jump_hVelocity * self.elapsedTime

    self.parent:SetOrigin(self.jump_start_pos + target)
    --self.parent:FaceTowards(self.point)
end
function modifier_jeanne_jump:UpdateVerticalMotion(me, dt)
    self:SyncTime(2, dt)

    local target = self.jump_vVelocity * self.elapsedTime + 0.5 * self.jump_gravity * self.elapsedTime * self.elapsedTime

    self.parent:SetOrigin(Vector(self.parent:GetOrigin().x, self.parent:GetOrigin().y, self.jump_start_pos.z + target))
end
function modifier_jeanne_jump:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_jeanne_jump:OnVerticalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_jeanne_jump:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end
function modifier_jeanne_jump:SyncTime( iDir, dt )
    -- check if already synced
    if self.motionTick[1]==self.motionTick[2] then
        self.motionTick[0] = self.motionTick[0] + 1
        self.elapsedTime = self.elapsedTime + dt
    end

    -- sync time
    self.motionTick[iDir] = self.motionTick[0]
    
    -- end motion
    if self.elapsedTime > self.jump_duration and self.motionTick[1] == self.motionTick[2] then
        self:PlayEffects()
        self:Destroy()
    end
end
function modifier_jeanne_jump:PlayEffects()
    if not self.do_damage then
        self.do_damage = true

        EmitSoundOnLocationWithCaster(self.point, "Hero_Leshrac.Split_Earth", self.parent)

        local hit_fx = ParticleManager:CreateParticle("particles/atalanta/atalanta_earthshock.vpcf", PATTACH_ABSORIGIN, self.parent )
		ParticleManager:SetParticleControl( hit_fx, 0, GetGroundPosition(self.parent:GetAbsOrigin(), self.parent))
		ParticleManager:SetParticleControl( hit_fx, 1, Vector(self:GetAbility():GetSpecialValueFor("radius"), 300, 150))
 
        local enemies = FindUnitsInRadius(  self.parent:GetTeamNumber(),
                                            self.point, 
                                            nil, 
                                            self.radius, 
                                            self.ability:GetAbilityTargetTeam(), 
                                            self.ability:GetAbilityTargetType(), 
                                            self.ability:GetAbilityTargetFlags(), 
                                            FIND_ANY_ORDER, 
                                            false)

        for _,enemy in ipairs(enemies) do
            self.damage = self:GetAbility():GetSpecialValueFor("damage")
            DoDamage(self.parent, enemy, self.damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
        end
    end
end