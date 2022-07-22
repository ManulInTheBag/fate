LinkLuaModifier("modifier_nero_tres_buffed", "abilities/nero/nero_tres_buffed", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_nero_tres_enemy", "abilities/nero/nero_tres_buffed", LUA_MODIFIER_MOTION_HORIZONTAL)

nero_tres_buffed = class({})

function nero_tres_buffed:GetAOERadius()
    return self:GetSpecialValueFor("distance")
end

function nero_tres_buffed:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local FirstTarget = nil

	caster:AddNewModifier(caster, self, "modifier_nero_tres_buffed", {})
	caster:EmitSound("Nero_Skill_" .. math.random(1,4))

    if caster:GetAbilityByIndex(0):GetName() ~= "nero_tres_new" then
        caster:SwapAbilities("nero_tres_buffed", "nero_tres_new", false, true)
    end
    if caster:GetAbilityByIndex(1):GetName() ~= "nero_gladiusanus_new" then
        caster:SwapAbilities("nero_gladiusanus_buffed", "nero_gladiusanus_new", false, true)
    end
    if caster:GetAbilityByIndex(2):GetName() ~= "nero_rosa_new" then
        caster:SwapAbilities("nero_rosa_buffed", "nero_rosa_new", false, true)
    end
end

modifier_nero_tres_buffed = class({})
function modifier_nero_tres_buffed:IsHidden() return true end
function modifier_nero_tres_buffed:IsDebuff() return false end
function modifier_nero_tres_buffed:IsPurgable() return false end
function modifier_nero_tres_buffed:IsPurgeException() return false end
function modifier_nero_tres_buffed:RemoveOnDeath() return true end
function modifier_nero_tres_buffed:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_nero_tres_buffed:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_nero_tres_buffed:CheckState()
    local state =   { 
                        --[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        --[MODIFIER_STATE_SILENCED] = true,
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
function modifier_nero_tres_buffed:OnCreated(table)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.heat_abil = self.parent:FindAbilityByName("nero_heat")
    EmitSoundOn("nero_dash", self.parent)

    if IsServer() then
        self.speed          = self.ability:GetSpecialValueFor("speed")
        self.distance       = self.ability:GetAOERadius()--self.ability:GetSpecialValueFor("distance")
        self.damage         = self.ability:GetSpecialValueFor("damage")
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

        local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(slash_fx, 0, self.parent:GetAbsOrigin() + Vector(0, 0, 80))
        ParticleManager:SetParticleControl(slash_fx, 5, Vector(self.radius, 1, 1))
        ParticleManager:SetParticleControl(slash_fx, 10, Vector(0, 0, 0))

        Timers:CreateTimer(0.2, function()
            local slash_fx1 = ParticleManager:CreateParticle("particles/nero/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
            ParticleManager:SetParticleControl(slash_fx1, 0, self.parent:GetAbsOrigin() + Vector(0, 0, 80))
            ParticleManager:SetParticleControl(slash_fx1, 5, Vector(self.radius, 1, 1))
            ParticleManager:SetParticleControl(slash_fx1, 10, Vector(45, 0, 0))
            Timers:CreateTimer(0.2, function()
                ParticleManager:DestroyParticle(slash_fx1, false)
                ParticleManager:ReleaseParticleIndex(slash_fx1)
            end)
        end)

        Timers:CreateTimer(0.4, function()
            local slash_fx2 = ParticleManager:CreateParticle("particles/nero/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
            ParticleManager:SetParticleControl(slash_fx2, 0, self.parent:GetAbsOrigin() + Vector(0, 0, 80))
            ParticleManager:SetParticleControl(slash_fx2, 5, Vector(self.radius, 1, 1))
            ParticleManager:SetParticleControl(slash_fx2, 10, Vector(-45, 0, 0))
            Timers:CreateTimer(0.4, function()
                ParticleManager:DestroyParticle(slash_fx2, false)
                ParticleManager:ReleaseParticleIndex(slash_fx2)
            end)
        end)

        Timers:CreateTimer(0.2, function()
        	ParticleManager:DestroyParticle(slash_fx, false)
        	ParticleManager:ReleaseParticleIndex(slash_fx)
        end)

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
function modifier_nero_tres_buffed:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_nero_tres_buffed:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_nero_tres_buffed:UpdateHorizontalMotion(me, dt)
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

            self.parent:SetOrigin(next_pos)
            --self.parent:FaceTowards(self.point)

            self:PlayEffects()

            self.distance = self.distance - units_per_dt
        else
            self:Destroy()
        end
    end
end
function modifier_nero_tres_buffed:PlayEffects()
	local enemies = FindUnitsInRadius(self.parent:GetTeam(), self.parent:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)

    for _, enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() and IsValidEntity(enemy) and enemy ~= self.parent and not self.AttackedTargets[enemy:entindex()] then
            self.AttackedTargets[enemy:entindex()] = true

            if not self.FirstTarget then
            	self.heat_abil:IncreaseHeat(self.parent)
            	if not self.parent:HasModifier("modifier_nero_tres_window") then
            		self.parent:AddNewModifier(self.parent, self:GetAbility(), "modifier_nero_tres_window", {duration = self.ability:GetSpecialValueFor("window_duration")})
            	else
            		self.parent:RemoveModifierByName("modifier_nero_tres_window")
            	end

                self.FirstTarget = enemy
            end

            self.damage = self.ability:GetSpecialValueFor("damage") + (self.caster:HasModifier("modifier_sovereign_attribute") and self.caster:GetAverageTrueAttackDamage(self.caster)*self.ability:GetSpecialValueFor("damage_scale")/100 or 0)

            if not enemy:IsMagicImmune() then
				DoDamage(self.parent, enemy, self.damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
                enemy:AddNewModifier(self.parent, self.ability, "modifier_nero_tres_enemy", {duration = self.ability:GetSpecialValueFor("duration")})
			end

            if self.parent.AttributeNamePlaceholderAcquired then
            	self.parent:PerformAttack(enemy, true, true, false, true, true, false, false)
            end
        end
    end
end
function modifier_nero_tres_buffed:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_nero_tres_buffed:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end

modifier_nero_tres_enemy = class({})

function modifier_nero_tres_enemy:IsHidden() return false end
function modifier_nero_tres_enemy:IsDebuff() return false end
function modifier_nero_tres_enemy:IsPurgable() return false end
function modifier_nero_tres_enemy:IsPurgeException() return false end
function modifier_nero_tres_enemy:RemoveOnDeath() return true end

function modifier_nero_tres_enemy:OnCreated()
	if IsServer() then
		self.ability = self:GetAbility()
        self.caster = self:GetCaster()
        self.parent = self:GetParent()
        self.damage = self.ability:GetSpecialValueFor("damage_per_second")
		self:StartIntervalThink(0.25)
	end
end

function modifier_nero_tres_enemy:OnIntervalThink()
    if IsServer() then
        DoDamage(self.caster, self.parent, self.damage/4, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
    end
end

function modifier_nero_tres_enemy:GetEffectName()
    return "particles/units/heroes/hero_doom_bringer/doom_infernal_blade_debuff.vpcf"
end

function modifier_nero_tres_enemy:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end