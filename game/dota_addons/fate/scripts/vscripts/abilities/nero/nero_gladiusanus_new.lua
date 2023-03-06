LinkLuaModifier("modifier_nero_gladiusanus_window", "abilities/nero/nero_gladiusanus_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nero_gladiusanus_new", "abilities/nero/nero_gladiusanus_new", LUA_MODIFIER_MOTION_NONE)

nero_gladiusanus_new = class({})

function nero_gladiusanus_new:GetAOERadius()
    return self:GetSpecialValueFor("range")
end

function nero_gladiusanus_new:OnUpgrade()
    local hCaster = self:GetCaster()
    
    hCaster:FindAbilityByName("nero_gladiusanus_buffed"):SetLevel(self:GetLevel())
end

function nero_gladiusanus_new:GetCastAnimation()
    if self:GetCaster():HasModifier("modifier_nero_performance") then
        return ACT_DOTA_ATTACK
    end
    return ACT_DOTA_CAST_ABILITY_2
end

function nero_gladiusanus_new:GetManaCost()
    if self:GetCaster():HasModifier("modifier_aestus_domus_aurea_nero") then
        return 0
    end
    return 200
end

function nero_gladiusanus_new:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
    local damage = self:GetSpecialValueFor("damage")
    local range = self:GetSpecialValueFor("range")
    local width = self:GetSpecialValueFor("width")
    local FirstTarget = nil
    local AttackedTargets = {}
    StartAnimation(caster, {duration = 0.2, activity = ACT_DOTA_CAST_ABILITY_3, rate = 5})
    local targets = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        300,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                        FIND_ANY_ORDER,
                                        false)
    caster:RemoveModifierByName("modifier_nero_spectaculi_initium")
    if not caster:HasModifier("modifier_nero_performance") then
        caster:EmitSound("nero_w")
        local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_arcana_counter_slash_down.vpcf", PATTACH_WORLDORIGIN, caster)
        ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*150)
        ParticleManager:SetParticleControl(slash_fx, 7, caster:GetAbsOrigin() + caster:GetForwardVector()*150)
        ParticleManager:SetParticleControl(slash_fx, 8, caster:GetAbsOrigin() + caster:GetForwardVector()*150 + Vector(0, 0, 500))
        Timers:CreateTimer(1, function()
            ParticleManager:DestroyParticle(slash_fx, false)
            ParticleManager:ReleaseParticleIndex(slash_fx)
        end)
        local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin() + Vector(0, 0, 80))
        ParticleManager:SetParticleControl(slash_fx, 5, Vector(400, 1, 1))
        ParticleManager:SetParticleControl(slash_fx, 10, Vector(45, 0, 0))

        Timers:CreateTimer(0.4, function()
            ParticleManager:DestroyParticle(slash_fx, false)
            ParticleManager:ReleaseParticleIndex(slash_fx)
        end)

        --print(caster:GetPhysicsVelocity())

        caster:FindAbilityByName("nero_heat"):StartPerformance(2000, 4000/1.5)

        for _, enemy in pairs(targets) do
            if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
                if not FirstTarget then
                    local heat_abil = caster:FindAbilityByName("nero_heat")
                    heat_abil:IncreaseHeat(caster)
                    if not caster:HasModifier("modifier_nero_gladiusanus_window") then
                        caster:AddNewModifier(caster, self, "modifier_nero_gladiusanus_window", {duration = self:GetSpecialValueFor("window_duration")})
                    else
                        caster:RemoveModifierByName("modifier_nero_gladiusanus_window")
                    end

                    FirstTarget = enemy
                    damage = damage + self:GetSpecialValueFor("damage_per_stack")*caster:FindModifierByName("modifier_nero_heat").rank + (caster:HasModifier("modifier_sovereign_attribute") and caster:GetAverageTrueAttackDamage(caster)*self:GetSpecialValueFor("damage_scale")/100 or 0)
                end

                AttackedTargets[enemy:entindex()] = true

                if not enemy:IsMagicImmune() then
                    DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
                end

                --enemy:AddNewModifier(caster, enemy, "modifier_rooted", {duration = self:GetSpecialValueFor("root_duration")})
                giveUnitDataDrivenModifier(caster, enemy, "locked", self:GetSpecialValueFor("root_duration"))
                enemy:AddNewModifier(caster, enemy, "modifier_nero_gladiusanus_new", {duration = self:GetSpecialValueFor("root_duration")})
                enemy:AddNewModifier(caster, enemy, "modifier_stunned", {duration = 0.1})

                if not IsKnockbackImmune(enemy) then
                    ApplyAirborneOnly(enemy, 2000, self:GetSpecialValueFor("root_duration"))
                end
                --print(enemy:GetPhysicsVelocity()[3])
                Timers:CreateTimer(self:GetSpecialValueFor("root_duration"), function()
                    enemy:SetAbsOrigin(GetGroundPosition(enemy:GetAbsOrigin(),enemy))
                end)

                if caster.AttributeNamePlaceholderAcquired then
                    caster:PerformAttack(enemy, true, true, false, true, true, false, false)
                end
            end
        end
    else
        local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_arcana_counter_slash_down.vpcf", PATTACH_WORLDORIGIN, caster)
        ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*150)
        ParticleManager:SetParticleControl(slash_fx, 7, caster:GetAbsOrigin() + caster:GetForwardVector()*150 + Vector(0, 0, 500))
        ParticleManager:SetParticleControl(slash_fx, 8, caster:GetAbsOrigin() + caster:GetForwardVector()*150)
        Timers:CreateTimer(1, function()
            ParticleManager:DestroyParticle(slash_fx, false)
            ParticleManager:ReleaseParticleIndex(slash_fx)
        end)
        local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin() + Vector(0, 0, 80))
        ParticleManager:SetParticleControl(slash_fx, 5, Vector(400, 1, 1))
        ParticleManager:SetParticleControl(slash_fx, 10, Vector(-45, 0, 0))

        Timers:CreateTimer(0.4, function()
            ParticleManager:DestroyParticle(slash_fx, false)
            ParticleManager:ReleaseParticleIndex(slash_fx)
        end)

        caster:SetAbsOrigin(GetGroundPosition(caster:GetAbsOrigin(),caster))
        caster:FindAbilityByName("nero_heat"):EndPerformance()
        --print(caster:GetPhysicsVelocity())

        for _, enemy in pairs(targets) do
            if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
                if not FirstTarget then
                    local heat_abil = caster:FindAbilityByName("nero_heat")
                    heat_abil:IncreaseHeat(caster)
                    if not caster:HasModifier("modifier_nero_gladiusanus_window") then
                        caster:AddNewModifier(caster, self, "modifier_nero_gladiusanus_window", {duration = self:GetSpecialValueFor("window_duration")})
                    else
                        caster:RemoveModifierByName("modifier_nero_gladiusanus_window")
                    end

                    FirstTarget = enemy
                    damage = damage + self:GetSpecialValueFor("damage_per_stack")*caster:FindModifierByName("modifier_nero_heat").rank + (caster:HasModifier("modifier_sovereign_attribute") and caster:GetAverageTrueAttackDamage(caster)*self:GetSpecialValueFor("damage_scale")/100 or 0)
                end

                AttackedTargets[enemy:entindex()] = true

                if not enemy:IsMagicImmune() then
                    DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
                    enemy:AddNewModifier(caster, enemy, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})
                end

                
                enemy:RemoveModifierByName("modifier_nero_gladiusanus_new")
                enemy:SetAbsOrigin(GetGroundPosition(enemy:GetAbsOrigin(),enemy))

                if caster.AttributeNamePlaceholderAcquired then
                    caster:PerformAttack(enemy, true, true, false, true, true, false, false)
                end
            end
        end
        local hit_point = caster:GetAbsOrigin() + caster:GetForwardVector()*50
        EmitSoundOnLocationWithCaster(hit_point, "Hero_Leshrac.Split_Earth", caster)  
        local hit_fx = ParticleManager:CreateParticle("particles/nero/atalanta_earthshock.vpcf", PATTACH_ABSORIGIN, caster )
        ParticleManager:SetParticleControl( hit_fx, 0, GetGroundPosition(hit_point, caster))
        ParticleManager:SetParticleControl( hit_fx, 1, Vector(self:GetSpecialValueFor("landing_radius"), 300, 150))
        local enemies = FindUnitsInRadius(caster:GetTeam(), hit_point, nil, self:GetSpecialValueFor("landing_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
        for _,enemy in pairs(enemies) do
            if enemy and not enemy:IsNull() and IsValidEntity(enemy) and not AttackedTargets[enemy:entindex()] then
                if not enemy:IsMagicImmune() then
                    DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
                    enemy:AddNewModifier(caster, enemy, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})
                end
            end
        end
    end
end

modifier_nero_gladiusanus_new = class({})
function modifier_nero_gladiusanus_new:CheckState()
    local state =   { 
                        --[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        --[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        --[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        --[MODIFIER_STATE_DISARMED] = true,
                        --[MODIFIER_STATE_SILENCED] = true,
                        --[MODIFIER_STATE_MUTED] = true,
                    }
    return state
end
function modifier_nero_gladiusanus_new:IsHidden() return true end
function modifier_nero_gladiusanus_new:IsDebuff() return false end
function modifier_nero_gladiusanus_new:RemoveOnDeath() return true end
function modifier_nero_gladiusanus_new:OnCreated()
    self.elapsed = 0
    self:StartIntervalThink(FrameTime())
end
function modifier_nero_gladiusanus_new:OnIntervalThink()
    self.elapsed = self.elapsed + FrameTime()
    --print(self.elapsed)
end
function modifier_nero_gladiusanus_new:OnRefresh()
    self:OnCreated()
end

modifier_nero_gladiusanus_window = class({})

function modifier_nero_gladiusanus_window:IsHidden() return false end
function modifier_nero_gladiusanus_window:IsDebuff() return false end
function modifier_nero_gladiusanus_window:IsPurgable() return false end
function modifier_nero_gladiusanus_window:IsPurgeException() return false end
function modifier_nero_gladiusanus_window:RemoveOnDeath() return true end

function modifier_nero_gladiusanus_window:OnCreated()
	if IsServer() then
		self.ability = self:GetAbility()
		self.ability:EndCooldown()
	end
end

function modifier_nero_gladiusanus_window:OnDestroy()
	if IsServer() then
		self.ability:StartCooldown(self.ability:GetCooldown(self.ability:GetLevel()))
	end
end