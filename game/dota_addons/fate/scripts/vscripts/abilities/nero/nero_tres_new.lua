LinkLuaModifier("modifier_nero_tres_new", "abilities/nero/nero_tres_new", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_nero_tres_window", "abilities/nero/nero_tres_new", LUA_MODIFIER_MOTION_NONE)

nero_tres_new = class({})

function nero_tres_new:GetBehavior()
    if self:GetCaster():HasModifier("modifier_nero_performance") then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET
    end
    return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES
end

function nero_tres_new:GetAOERadius()
    return self:GetSpecialValueFor("distance")
end

function nero_tres_new:OnUpgrade()
    local hCaster = self:GetCaster()
    
    hCaster:FindAbilityByName("nero_tres_buffed"):SetLevel(self:GetLevel())
end

function nero_tres_new:GetManaCost()
    if self:GetCaster():HasModifier("modifier_aestus_domus_aurea_nero") then
        return 0
    end
    return 200
end

function nero_tres_new:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local FirstTarget = nil
    caster:RemoveModifierByName("modifier_nero_spectaculi_initium")
	if not caster:HasModifier("modifier_nero_performance") then
		caster:AddNewModifier(caster, self, "modifier_nero_tres_new", {})
		caster:EmitSound("Nero_Skill_" .. math.random(1,4))
	else
		local counter = 0
		local sound_counter = 1
        --caster:SetAbsOrigin(GetGroundPosition(caster:GetAbsOrigin(),caster))
        caster:EmitSound("Nero_Skill_" .. math.random(1,4))
        Timers:RemoveTimer("nero_tres_buffed")
        Timers:CreateTimer("nero_tres_buffed", {
            endTime = FrameTime(),
            callback = function()
            counter = counter + 1
            local sound_counter = sound_counter + 1
            if sound_counter > 2 then
                sound_counter = 1
            end
            EmitSoundOn("nero_swoosh_"..sound_counter, caster)
            local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
            ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin() + Vector(0, 0, 80))
            ParticleManager:SetParticleControl(slash_fx, 5, Vector(400, 1, 1))
            ParticleManager:SetParticleControl(slash_fx, 10, Vector(counter*30, 0, 0))
            local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        400,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                        FIND_ANY_ORDER,
                                        false)

            for _,enemy in pairs(enemies) do
                if not FirstTarget then
                    local heat_abil = caster:FindAbilityByName("nero_heat")
                    heat_abil:IncreaseHeat(caster)
                    if not caster:HasModifier("modifier_nero_tres_window") then
                        caster:AddNewModifier(caster, self, "modifier_nero_tres_window", {duration = self:GetSpecialValueFor("window_duration")})
                    else
                        caster:RemoveModifierByName("modifier_nero_tres_window")
                    end

                    FirstTarget = enemy
                end
                local damage = self:GetSpecialValueFor("slash_damage") + self:GetSpecialValueFor("slash_damage_per_stack")*caster:FindModifierByName("modifier_nero_heat").rank + (caster:HasModifier("modifier_sovereign_attribute") and caster:GetAverageTrueAttackDamage(caster)*self:GetSpecialValueFor("slash_damage_scale")/100 or 0)
                if not enemy:IsMagicImmune() then
                    DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
                    enemy:AddNewModifier(caster, self, "modifier_stunned", {Duration = 0.02})
                    --EmitSoundOn("nero_fast_slash", enemy)
                end
            end
            if counter < self:GetSpecialValueFor("slash_count") then
                return 0.1
            else
                if caster.IsISAcquired then
                    HardCleanse(caster)
                end
            end
        end
        })
		Timers:CreateTimer(FrameTime(), function()
		end)
	end
end

modifier_nero_tres_new = class({})
function modifier_nero_tres_new:IsHidden() return true end
function modifier_nero_tres_new:IsDebuff() return false end
function modifier_nero_tres_new:IsPurgable() return false end
function modifier_nero_tres_new:IsPurgeException() return false end
function modifier_nero_tres_new:RemoveOnDeath() return true end
function modifier_nero_tres_new:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_nero_tres_new:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_nero_tres_new:CheckState()
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
function modifier_nero_tres_new:OnCreated(table)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.heat_abil = self.parent:FindAbilityByName("nero_heat")
    EmitSoundOn("nero_dash", self.parent)

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

        local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(slash_fx, 0, self.parent:GetAbsOrigin() + Vector(0, 0, 80))
        ParticleManager:SetParticleControl(slash_fx, 5, Vector(self.radius, 1, 1))
        ParticleManager:SetParticleControl(slash_fx, 10, Vector(RandomInt(-10, 10), 0, 0))

        Timers:CreateTimer(0.4, function()
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
function modifier_nero_tres_new:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_nero_tres_new:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_nero_tres_new:UpdateHorizontalMotion(me, dt)
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
function modifier_nero_tres_new:PlayEffects()
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

            self.damage = self.ability:GetSpecialValueFor("damage") + self.ability:GetSpecialValueFor("damage_per_stack")*self.caster:FindModifierByName("modifier_nero_heat").rank + (self.caster:HasModifier("modifier_sovereign_attribute") and self.caster:GetAverageTrueAttackDamage(self.caster)*self.ability:GetSpecialValueFor("damage_scale")/100 or 0)

            if not enemy:IsMagicImmune() then
				DoDamage(self.parent, enemy, self.damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
			end

            if self.parent.AttributeNamePlaceholderAcquired then
            	self.parent:PerformAttack(enemy, true, true, false, true, true, false, false)
            end
        end
    end
end
function modifier_nero_tres_new:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_nero_tres_new:OnDestroy()
    if IsServer() then
        if self.parent.IsISAcquired then
            HardCleanse(self.parent)
        end
        self.parent:InterruptMotionControllers(true)
    end
end

modifier_nero_tres_window = class({})

function modifier_nero_tres_window:IsHidden() return false end
function modifier_nero_tres_window:IsDebuff() return false end
function modifier_nero_tres_window:IsPurgable() return false end
function modifier_nero_tres_window:IsPurgeException() return false end
function modifier_nero_tres_window:RemoveOnDeath() return true end

function modifier_nero_tres_window:OnCreated()
	if IsServer() then
		self.ability = self:GetAbility()
		self.ability:EndCooldown()
	end
end

function modifier_nero_tres_window:OnDestroy()
	if IsServer() then
		self.ability:StartCooldown(self.ability:GetCooldown(self.ability:GetLevel()))
	end
end