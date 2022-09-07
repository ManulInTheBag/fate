LinkLuaModifier("modifier_death_door_pepeg", "abilities/kinghassan/khsn_azrael", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_combo", "abilities/kinghassan/khsn_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_azrael_stun", "abilities/kinghassan/khsn_azrael", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_azrael_particle", "abilities/kinghassan/khsn_azrael", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_azrael_combo_cd", "abilities/kinghassan/khsn_combo", LUA_MODIFIER_MOTION_NONE)

khsn_combo = class({})

function khsn_combo:OnSpellStart()
    local caster = self:GetCaster()
    local ability = self
    --self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_khsn_combo", {duration = 8})

    local masterCombo = caster.MasterUnit2:FindAbilityByName(ability:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(ability:GetCooldown(1))
    caster:AddNewModifier(caster, self, "modifier_azrael_combo_cd", {duration = ability:GetCooldown(1)})
    caster:FindAbilityByName("khsn_azrael"):StartCooldown(caster:FindAbilityByName("khsn_azrael"):GetCooldown(caster:FindAbilityByName("khsn_azrael"):GetLevel()))

    if IsSpellBlocked(self:GetCursorTarget()) then return end
    
    self:StartCombo(self:GetCursorTarget())
end

function khsn_combo:StartCombo(hui)
    local caster = self:GetCaster()
    local target = hui
    local ability = self

    giveUnitDataDrivenModifier(caster, caster, "jump_pause", 9999)
    caster:AddNewModifier(caster, self, "modifier_azrael_particle", {duration = 6.26 + 2.210})
    --caster:AddNewModifier(caster, self, "modifier_azrael_move", {duration = 1.63+3.25})
    EmitGlobalSound("azrael_start")

   Timers:CreateTimer(1.63, function()
        if target and not target:IsNull() and target:IsAlive() then
            EmitGlobalSound("azrael_middle")
        else
            caster:RemoveModifierByName("jump_pause")
            caster:RemoveModifierByName("modifier_azrael_particle")
        end
    end)

    Timers:CreateTimer(1.63 + 3.25, function()
        if target and not target:IsNull() and target:IsAlive() then
            target:AddNewModifier(caster, self, "modifier_azrael_stun", {duration = 2.75})
            EmitGlobalSound("azrael_end")
        else
            caster:RemoveModifierByName("jump_pause")
            caster:RemoveModifierByName("modifier_azrael_particle")
        end
    end)

    local damage = self:GetSpecialValueFor("damage") + (caster.AzraelAcquired and 500 or 0)
    local modifier_damage = 0
    local modifier_death = target:FindModifierByName("modifier_death_door")
    if target:HasModifier("modifier_death_door_pepeg") then
        modifier_death = target:FindModifierByName("modifier_death_door_pepeg")
    end
    local flag = DOTA_DAMAGE_FLAG_NONE
    if caster.AzraelAcquired then
        flag = DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY
    end
    local multiplier = self:GetSpecialValueFor("dmg_percent")/100 + (caster.AzraelAcquired and 0.25 or 0)
    if modifier_death then
        modifier_damage = modifier_death.recieved_damage*multiplier
    end

    --StartAnimation(caster, {duration=6.26, activity=ACT_DOTA_CAST_ABILITY_4, rate=0.4})

    Timers:CreateTimer(6.26, function()
        if target and not target:IsNull() and target:IsAlive() then
            if not target:IsRealHero() then
                target:Kill(self, caster)
                caster:RemoveModifierByName("jump_pause")
                caster:RemoveModifierByName("modifier_azrael_particle")
                return
            end
            local position = caster:GetAbsOrigin()
            local targetpos = target:GetAbsOrigin() + target:GetForwardVector()*300
            FindClearSpaceForUnit(caster, targetpos, true)
            caster:FaceTowards(target:GetAbsOrigin())
            EmitGlobalSound("azrael_finish")
            StartAnimation(caster, {duration=2.21, activity=ACT_DOTA_CAST_ABILITY_4_END, rate=1.0})
            local light_index = ParticleManager:CreateParticle("particles/kinghassan/khsn_domus_ray.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
            ParticleManager:SetParticleControl( light_index, 0, target:GetAbsOrigin())
            ParticleManager:SetParticleControl( light_index, 7, target:GetAbsOrigin())
            Timers:CreateTimer(1.370, function()
                if target and not target:IsNull() and target:IsAlive() then
                    local modifier_death2 = target:FindModifierByName("modifier_death_door")
                    if modifier_death2 then
                        if (modifier_death2.recieved_damage*multiplier > modifier_damage) then
                            modifier_damage = modifier_death2.recieved_damage*multiplier
                        end
                    end
                    DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, flag, self, false)
                    DoDamage(caster, target, modifier_damage, caster.AzraelAcquired and DAMAGE_TYPE_PURE or DAMAGE_TYPE_MAGICAL, flag, self, false)
                    caster:RemoveModifierByName("jump_pause")
                    --caster:SetAbsOrigin(position)
                    EmitGlobalSound("azrael_bell")
                    local slashFx = ParticleManager:CreateParticle("particles/kinghassan/khsn_feathers.vpcf", PATTACH_ABSORIGIN, target )
                    ParticleManager:SetParticleControl( slashFx, 0, target:GetAbsOrigin() + Vector(0,0,300))

                    LoopOverPlayers(function(player, playerID, playerHero)
                        --print("looping through " .. playerHero:GetName())
                        if playerHero.voice == true then
                            -- apply legion horn vsnd on their client
                            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="box_"..math.random(1,4)})
                            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
                        end
                    end)

                    Timers:CreateTimer( 2.0, function()
                        ParticleManager:DestroyParticle( slashFx, false )
                        ParticleManager:ReleaseParticleIndex( slashFx )
                    end)
                    Timers:CreateTimer(2.0, function()
                        EmitGlobalSound("azrael_bell")
                    end)
                    Timers:CreateTimer(4.0, function()
                        EmitGlobalSound("azrael_bell")
                    end)
                    if target:GetHealth() < self:GetSpecialValueFor("health_threshold")/100*target:GetMaxHealth() and caster.AzraelAcquired then
                        --[[target:AddNewModifier(caster, self, "modifier_death_door_pepeg", {duration = self:GetSpecialValueFor("sequence_duration"),
                                                                                            damage = damage})]]
                        target:Execute(self, caster, { bExecution = true })
                    end
                    --[[if not target:IsAlive() and caster.AzraelAcquired then
                        self:EndCooldown()
                    end]]
                else
                    caster:RemoveModifierByName("jump_pause")
                    caster:RemoveModifierByName("modifier_azrael_particle")
                end
            end)
        else
            caster:RemoveModifierByName("jump_pause")
            caster:RemoveModifierByName("modifier_azrael_particle")
        end
    end)
end

modifier_khsn_combo = class({})

function modifier_khsn_combo:IsDebuff() return false end
function modifier_khsn_combo:RemoveOnDeath() return true end

modifier_azrael_combo_cd = class({})

function modifier_azrael_combo_cd:GetTexture()
    return "custom/kinghassan/khsn_combo"
end

function modifier_azrael_combo_cd:IsHidden()
    return false 
end

function modifier_azrael_combo_cd:RemoveOnDeath()
    return false
end

function modifier_azrael_combo_cd:IsDebuff()
    return true 
end

function modifier_azrael_combo_cd:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end