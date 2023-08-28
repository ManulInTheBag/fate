LinkLuaModifier("modifier_tennen_stacks", "abilities/okita/modifiers/modifier_tennen_stacks", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tennen_active", "abilities/okita/modifiers/modifier_tennen_active", LUA_MODIFIER_MOTION_NONE)

okita_tennen = class({})

function okita_tennen:OnAbilityPhaseStart()
    local target = self:GetCursorTarget()

    self.slashIndex = ParticleManager:CreateParticle( "particles/okita/okita_tennen_first_slash.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControl(self.slashIndex, 0, target:GetAbsOrigin())

    return true
end

function okita_tennen:OnAbilityPhaseInterrupted()
    ParticleManager:DestroyParticle(self.slashIndex, true)
    ParticleManager:ReleaseParticleIndex(self.slashIndex)
end

function okita_tennen:GetCastRange()
    return self:GetSpecialValueFor("range")
end

function okita_tennen:CastFilterResultTarget(hTarget)
    local caster = self:GetCaster()
    local target_flag = DOTA_UNIT_TARGET_FLAG_NONE
    local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

    if(filter == UF_SUCCESS) then
        if hTarget:GetName() == "npc_dota_ward_base" or (IsServer() and IsLocked(caster)) then 
            return UF_FAIL_CUSTOM 
        else
            return UF_SUCCESS
        end
    else
        return filter
    end
end

function okita_tennen:GetCustomCastErrorTarget(hTarget)
    local caster = self:GetCaster()
    local target_flag = DOTA_UNIT_TARGET_FLAG_NONE
    local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

    if(filter == UF_SUCCESS) then
        if hTarget:GetName() == "npc_dota_ward_base" or (IsServer() and IsLocked(caster)) then 
            return "Locked"
        else
            return UF_SUCCESS
        end
    else
        return filter
    end
end

function okita_tennen:OnSpellStart()
	local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    local damage = self:GetSpecialValueFor("damage")
    local stun_damage = self:GetSpecialValueFor("stun_damage")

    local targetor = target:GetAbsOrigin()
    local casteror = caster:GetAbsOrigin()
    local dir = (targetor - casteror):Normalized()
    dir.z = 0

    targetor = targetor + dir*150

    FindClearSpaceForUnit(caster, targetor, true)

    local effect_cast = ParticleManager:CreateParticle( "particles/okita/okita_blink_slash.vpcf", PATTACH_WORLDORIGIN, caster )
                        ParticleManager:SetParticleControl( effect_cast, 0, casteror )
                        ParticleManager:SetParticleControl( effect_cast, 1, casteror)
                        ParticleManager:SetParticleControl( effect_cast, 2, targetor )
                        ParticleManager:ReleaseParticleIndex( effect_cast )
                        Timers:CreateTimer(1.0, function()
                            ParticleManager:DestroyParticle(effect_cast, true)
                            ParticleManager:ReleaseParticleIndex( effect_cast )
                        end)

    local enemies = FATE_FindUnitsInLine(
                                        caster:GetTeamNumber(),
                                        casteror,
                                        targetor + dir*1,
                                        100,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_NONE,
                                        FIND_CLOSEST
                                    )

    for k,v in pairs(enemies) do
        v:EmitSound("Tsubame_Slash_" .. math.random(1,3))

        local slashIndex = ParticleManager:CreateParticle( "particles/okita/okita_tennen_first_slash.vpcf", PATTACH_ABSORIGIN_FOLLOW, v )
        ParticleManager:SetParticleControl(slashIndex, 0, v:GetAbsOrigin())

        if caster.IsTennenAcquired then
            caster:PerformAttack( v, true, true, true, true, false, true, true )
        end
        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

        if v:IsStunned() then
            Timers:CreateTimer(0.3, function()
                Timers:CreateTimer(0.1, function()
                    if caster.IsTennenAcquired then
                        caster:PerformAttack( v, true, true, true, true, false, true, true )
                    end
                    DoDamage(caster, v, stun_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

                    v:EmitSound("Tsubame_Slash_" .. math.random(1,3))
                end)

                local slashIndex = ParticleManager:CreateParticle( "particles/okita/okita_tennen_second_slash.vpcf", PATTACH_ABSORIGIN_FOLLOW, v )
                ParticleManager:SetParticleControl(slashIndex, 0, v:GetAbsOrigin())
            end)

            Timers:CreateTimer(0.5, function()
                Timers:CreateTimer(0.1, function()
                    if caster.IsTennenAcquired then
                        caster:PerformAttack( v, true, true, true, true, false, true, true )
                    end
                    DoDamage(caster, v, stun_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

                    v:EmitSound("Tsubame_Slash_" .. math.random(1,3))
                end)

                local slashIndex = ParticleManager:CreateParticle( "particles/okita/okita_tennen_third_slash.vpcf", PATTACH_ABSORIGIN_FOLLOW, v )
                ParticleManager:SetParticleControl(slashIndex, 0, v:GetAbsOrigin())
            end)

            if caster.IsReducedEarthAcquired then
                Timers:CreateTimer(0.7, function()
                    Timers:CreateTimer(0.1, function()
                        if caster.IsTennenAcquired then
                            caster:PerformAttack( v, true, true, true, true, false, true, true )
                        end
                        DoDamage(caster, v, stun_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

                        v:EmitSound("Tsubame_Slash_" .. math.random(1,3))
                    end)

                    local slashIndex = ParticleManager:CreateParticle( "particles/okita/okita_tennen_first_slash.vpcf", PATTACH_ABSORIGIN_FOLLOW, v )
                    ParticleManager:SetParticleControl(slashIndex, 0, v:GetAbsOrigin())
                end)

                Timers:CreateTimer(0.9, function()
                    Timers:CreateTimer(0.1, function()
                        if caster.IsTennenAcquired then
                            caster:PerformAttack( v, true, true, true, true, false, true, true )
                        end
                        DoDamage(caster, v, stun_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

                        v:EmitSound("Tsubame_Slash_" .. math.random(1,3))
                    end)

                    local slashIndex = ParticleManager:CreateParticle( "particles/okita/okita_tennen_third_slash.vpcf", PATTACH_ABSORIGIN_FOLLOW, v )
                    ParticleManager:SetParticleControl(slashIndex, 0, v:GetAbsOrigin())
                end)
            end
        end
    end
end