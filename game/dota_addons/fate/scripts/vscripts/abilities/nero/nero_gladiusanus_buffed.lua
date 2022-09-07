LinkLuaModifier("modifier_nero_gladiusanus_new", "abilities/nero/nero_gladiusanus_new", LUA_MODIFIER_MOTION_NONE)

nero_gladiusanus_buffed = class({})

function nero_gladiusanus_buffed:GetAOERadius()
    return self:GetSpecialValueFor("range")
end

function nero_gladiusanus_buffed:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
    local damage = self:GetSpecialValueFor("damage")
    local range = self:GetSpecialValueFor("range")
    local width = self:GetSpecialValueFor("width")
    local FirstTarget = nil
    local AttackedTargets = {}
    StartAnimation(caster, {duration = 1, activity = ACT_DOTA_CAST_ABILITY_1, rate = 1})  
    local targets = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        1000,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                        FIND_ANY_ORDER,
                                        false)

    --[[local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_arcana_counter_slash_down.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*150)
    ParticleManager:SetParticleControl(slash_fx, 7, caster:GetAbsOrigin() + caster:GetForwardVector()*150)
    ParticleManager:SetParticleControl(slash_fx, 8, caster:GetAbsOrigin() + caster:GetForwardVector()*150 + Vector(0, 0, 500))
    Timers:CreateTimer(1, function()
        ParticleManager:DestroyParticle(slash_fx, false)
        ParticleManager:ReleaseParticleIndex(slash_fx)
    end)]]
    local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin() + Vector(0, 0, 80))
    ParticleManager:SetParticleControl(slash_fx, 5, Vector(1000, 1, 1))
    ParticleManager:SetParticleControl(slash_fx, 10, Vector(0, 0, 0))

    Timers:CreateTimer(0.4, function()
        ParticleManager:DestroyParticle(slash_fx, false)
        ParticleManager:ReleaseParticleIndex(slash_fx)
    end)

    --print(caster:GetPhysicsVelocity())

    for _, enemy in pairs(targets) do
        if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
            if not FirstTarget then
                local heat_abil = caster:FindAbilityByName("nero_heat")
                enemy:EmitSound("Hero_Lion.FingerOfDeath")
                heat_abil:IncreaseHeat(caster)
                --[[if not caster:HasModifier("modifier_nero_gladiusanus_window") then
                    caster:AddNewModifier(caster, self, "modifier_nero_gladiusanus_window", {duration = self:GetSpecialValueFor("window_duration")})
                else
                    caster:RemoveModifierByName("modifier_nero_gladiusanus_window")
                end]]
                FirstTarget = enemy
                damage = damage + (caster:HasModifier("modifier_sovereign_attribute") and caster:GetAverageTrueAttackDamage(caster)*self:GetSpecialValueFor("damage_scale")/100 or 0)
            end

            AttackedTargets[enemy:entindex()] = true

            if not enemy:IsMagicImmune() then
                DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
            end
                
                --enemy:AddNewModifier(caster, enemy, "modifier_rooted", {duration = self:GetSpecialValueFor("root_duration")})
            enemy:AddNewModifier(caster, enemy, "modifier_nero_gladiusanus_new", {duration = self:GetSpecialValueFor("root_duration")})
            enemy:AddNewModifier(caster, enemy, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})

            ApplyAirborneOnly(enemy, 2000, self:GetSpecialValueFor("root_duration"))
            --print(enemy:GetPhysicsVelocity()[3])
            Timers:CreateTimer(self:GetSpecialValueFor("root_duration"), function()
                enemy:SetAbsOrigin(GetGroundPosition(enemy:GetAbsOrigin(),enemy))
            end)

            if caster.AttributeNamePlaceholderAcquired then
                caster:PerformAttack(enemy, true, true, false, true, true, false, false)
            end
        end
    end
    if caster:GetAbilityByIndex(0):GetName() ~= "nero_tres_new" then
        caster:SwapAbilities("nero_tres_buffed", "nero_tres_new", false, true)
    end
    if caster:GetAbilityByIndex(1):GetName() ~= "nero_gladiusanus_new" then
        caster:SwapAbilities("nero_gladiusanus_buffed", "nero_gladiusanus_new", false, true)
    end
    if caster:GetAbilityByIndex(2):GetName() ~= "nero_rosa_new" then
        caster:SwapAbilities("nero_rosa_buffed", "nero_rosa_new", false, true)
    end
    if caster:GetAbilityByIndex(5):GetName() ~= "nero_spectaculi_initium" then
        caster:SwapAbilities("nero_spectaculi_buffed", "nero_spectaculi_initium", false, true)
    end
end