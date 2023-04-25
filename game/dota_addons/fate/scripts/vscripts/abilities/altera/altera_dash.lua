LinkLuaModifier("modifier_altera_dash", "abilities/altera/altera_dash", LUA_MODIFIER_MOTION_HORIZONTAL)

altera_dash = class({})

function altera_dash:GetAOERadius()
	local distance = self:GetSpecialValueFor("distance")
	if self:GetCaster():HasModifier("modifier_altera_form_int") then
		distance = distance + self:GetSpecialValueFor("int_bonus_distance")
	end
    return distance
end

function altera_dash:GetCastPoint()
	if self:GetCaster():HasModifier("modifier_altera_form_agi") then
	   	return 0
	end
	return self:GetSpecialValueFor("channel_time")
end

function altera_dash:OnSpellStart()
	local caster = self:GetCaster()

	StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_CAST_ABILITY_2_END, rate=1.0})

	local ability = self
	local FirstTarget = nil

	caster:AddNewModifier(caster, self, "modifier_altera_dash", {})
	--caster:EmitSound("Nero_Skill_" .. math.random(1,4))
end

modifier_altera_dash = class({})
function modifier_altera_dash:IsHidden() return true end
function modifier_altera_dash:IsDebuff() return false end
function modifier_altera_dash:IsPurgable() return false end
function modifier_altera_dash:IsPurgeException() return false end
function modifier_altera_dash:RemoveOnDeath() return true end
function modifier_altera_dash:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_altera_dash:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_altera_dash:CheckState()
    local state =   { 
                        --[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        --[MODIFIER_STATE_STUNNED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        --[MODIFIER_STATE_MUTED] = true,
                    }
    return state
end
--[[function modifier_nero_tres_new:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_OVERRIDE_ANIMATION, 
                    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,}
    return func
end
function modifier_nero_tres_new:GetOverrideAnimation()
    return ACT_DOTA_ATTACK_EVENT
end
function modifier_nero_tres_new:GetOverrideAnimationRate()
    return 2.0
end]]
function modifier_altera_dash:OnCreated(table)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    EmitSoundOn("nero_dash", self.parent)

    self.form = "neutral"
    self.damage = self.ability:GetSpecialValueFor("damage")
    self.particlename = "particles/altera/altera_dash_blast.vpcf"

    if self.caster:HasModifier("modifier_altera_form_str") then
    	self.form = "str"
    	self.particlename = "particles/altera/altera_dash_blast_red.vpcf"
    	if self.parent.CrestAcquired then
    		self.damage = self.damage + self.ability:GetSpecialValueFor("atr_damage_mult")*self.parent:GetStrength()
    	end
    end
    if self.caster:HasModifier("modifier_altera_form_agi") then
       	self.form = "agi"
       	self.particlename = "particles/altera/altera_dash_blast_green.vpcf"
       	if self.parent.CrestAcquired then
    		self.damage = self.damage + self.ability:GetSpecialValueFor("atr_damage_mult")*self.parent:GetAgility()
    	end
    end
    if self.caster:HasModifier("modifier_altera_form_int") then
       	self.form = "int"
       	self.particlename = "particles/altera/altera_dash_blast_blue.vpcf"
       	if self.parent.CrestAcquired then
    		self.damage = self.damage + self.ability:GetSpecialValueFor("atr_damage_mult")*self.parent:GetIntellect()
    	end
    end

    if IsServer() then
        self.speed          = self.ability:GetSpecialValueFor("speed")
        self.distance       = self.ability:GetAOERadius()--self.ability:GetSpecialValueFor("distance")
        self.radius = self:GetAbility():GetSpecialValueFor("radius")
        --self.crit           = self.ability:GetSpecialValueFor("crit")
        --self.delay_duration = self.ability:GetSpecialValueFor("delay_duration")

        --self.second_targets_damage = self.ability:GetSpecialValueFor("second_targets_damage") * 0.01

        self.point          = self.ability:GetCursorPosition() + RandomVector(1)
        self.direction      = (self.point - self.parent:GetAbsOrigin()):Normalized()
        self.direction.z    = 0
        self.point          = self.parent:GetAbsOrigin() + self.direction * self.distance

        self.parent:SetForwardVector(self.direction)

        self.AttackedTargets    = {}
        self.FirstTarget        = nil

        self.vAttachLoc = self.caster:GetAbsOrigin() - self.caster:GetLeftVector()*30 + self.caster:GetForwardVector()*70 + Vector(0, 0, 60)

        local pepeFx = ParticleManager:CreateParticle( "particles/altera/altera_dash_blast.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent )
		ParticleManager:SetParticleControl( pepeFx, 0, Vector(0, 0, 0))
		ParticleManager:SetParticleControl( pepeFx, 5, self.vAttachLoc )


	    self.groundFx = ParticleManager:CreateParticle( self.particlename, PATTACH_ABSORIGIN_FOLLOW, self.parent )
		ParticleManager:SetParticleControl( self.groundFx, 0, Vector(0, 0, 0))
		ParticleManager:SetParticleControl( self.groundFx, 5, self.vAttachLoc )

		self:AddParticle(self.groundFx, false, false, -1, false, false)

        --[[local dash_fx = ParticleManager:CreateParticle("particles/okita/okita_vendetta_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(dash_fx, 0, self.parent:GetAbsOrigin())

        self:AddParticle(dash_fx, false, false, -1, true, false)

        self.dash_fx2 = ParticleManager:CreateParticle("particles/okita/okita_surge_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(self.dash_fx2, 0, self.parent:GetAbsOrigin())

        self:AddParticle(self.dash_fx2, false, false, -1, true, false)]]

        self:StartIntervalThink(FrameTime())
        
        --[[if self:ApplyHorizontalMotionController() == false then 
            self:Destroy()
        end]]
    end
end
function modifier_altera_dash:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
    self.vAttachLoc = self.caster:GetAbsOrigin() - self.caster:GetLeftVector()*30 + self.caster:GetForwardVector()*70 + Vector(0, 0, 60)
    ParticleManager:SetParticleControl( self.groundFx, 5, self.vAttachLoc )
end
function modifier_altera_dash:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_altera_dash:UpdateHorizontalMotion(me, dt)
    if IsServer() then
        if self.distance >= 0 then
        	self.direction = self.parent:GetForwardVector()
            local units_per_dt = self.speed * dt
            local parent_pos = self.parent:GetAbsOrigin()

            local next_pos = parent_pos + self.direction * units_per_dt
            local distance_will = self.distance - units_per_dt

            --[[if distance_will < 0 then
                next_pos = self.point
            end]]

            --[[print(self.parent:GetAbsOrigin())
            print(next_pos)]]

            self.parent:SetOrigin(GetGroundPosition(next_pos, self.parent))
            --self.parent:FaceTowards(self.point)

            self:PlayEffects()

            self.distance = self.distance - units_per_dt
        else
            self:Destroy()
        end
    end
end
function modifier_altera_dash:PlayEffects()
	local enemies = FindUnitsInRadius(self.parent:GetTeam(), self.parent:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)

    for _, enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() and IsValidEntity(enemy) and enemy ~= self.parent and not self.AttackedTargets[enemy:entindex()] then
            if not enemy:IsMagicImmune() then
                self.AttackedTargets[enemy:entindex()] = true
				DoDamage(self.parent, enemy, self.damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
				if self.form == "str" then
					ApplyAirborne(self.parent, enemy, self.ability:GetSpecialValueFor("str_airborne_duration"))
				end
                if self.parent.CrestAcquired and enemy:IsConsideredHero() then
                    self.distance = self.distance + self.ability:GetSpecialValueFor("distance")
                end
			end
        end
    end
end
function modifier_altera_dash:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_altera_dash:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end