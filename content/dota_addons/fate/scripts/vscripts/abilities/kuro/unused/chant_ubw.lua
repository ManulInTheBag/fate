emiya_chant_ubw = class({})
LinkLuaModifier("modifier_ubw_chant_count", "abilities/emiya/modifier_ubw_chant_count", LUA_MODIFIER_MOTION_NONE)

function emiya_chant_ubw:GetBuffDuration()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    return duration
end

function emiya_chant_ubw:GetUBWCastCount()
    local caster = self:GetCaster()
    local modifier = caster:FindModifierByName("modifier_ubw_chant_count")
    local currentStack = modifier and modifier:GetStackCount() or 0

    return currentStack
end

--[[function emiya_chant_ubw:GrantUBWChantBuff()
    
end]]

function emiya_chant_ubw:OnSpellStart()
    local caster = self:GetCaster()
    local ability = self
    local effect = "particles/units/heroes/hero_centaur/centaur_warstomp.vpcf"
    local currentStack = 0
    local modifier = caster:FindModifierByName("modifier_ubw_chant_count") 

    if modifier then
        currentStack = modifier:GetStackCount()
        caster:AddNewModifier(caster, self, "modifier_ubw_chant_count", {duration = self:GetBuffDuration(),
                                                                         MsBonus = self:GetSpecialValueFor("movespeed_bonus")})
        caster:SetModifierStackCount("modifier_ubw_chant_count", self, currentStack + 1)

        currentStack = currentStack + 1        
    else
        caster:AddNewModifier(caster, self, "modifier_ubw_chant_count", {duration = self:GetBuffDuration(),
                                                                         MsBonus = self:GetSpecialValueFor("movespeed_bonus")})
        caster:SetModifierStackCount("modifier_ubw_chant_count", self, 1)
        currentStack = 1
    end

    local bpCd = caster:GetAbilityByIndex(1):GetCooldownTimeRemaining()    
    local oeCd = caster:GetAbilityByIndex(2):GetCooldownTimeRemaining()

    caster:GetAbilityByIndex(0):EndCooldown()    
    caster:GetAbilityByIndex(1):EndCooldown()
    caster:GetAbilityByIndex(2):EndCooldown()

    caster:GetAbilityByIndex(0):StartCooldown(1)

    if bpCd - self:GetSpecialValueFor("cooldown_set") > 1 then
        caster:GetAbilityByIndex(1):StartCooldown(bpCd - self:GetSpecialValueFor("cooldown_set"))
    else
        caster:GetAbilityByIndex(1):StartCooldown(1)
    end

    if oeCd - self:GetSpecialValueFor("cooldown_set") > 1 then
        caster:GetAbilityByIndex(2):StartCooldown(oeCd - self:GetSpecialValueFor("cooldown_set"))
    else
        caster:GetAbilityByIndex(2):StartCooldown(1)
    end
        
    if currentStack == 1 then         
        EmitGlobalSound("emiya_ubw1")
    elseif currentStack == 2 then 
        EmitGlobalSound("emiya_ubw2")
    elseif currentStack == 3 then 
        EmitGlobalSound("emiya_ubw3")
    elseif currentStack == 4 then 
        EmitGlobalSound("emiya_ubw4")
    elseif currentStack == 5 then 
        EmitGlobalSound("emiya_ubw5")
    elseif currentStack == 6 then 
        EmitGlobalSound("emiya_ubw6") 
        local ability_slot = caster:GetAbilityByIndex(5)

        if ability_slot:GetName() == "emiya_chant_ubw" then
            caster:SwapAbilities("emiya_chant_ubw", "archer_5th_ubw", false, true) 
            caster:FindAbilityByName("archer_5th_ubw"):StartCooldown(4)
        end
    end
end

--[[function emiya_chant_ubw:StartUBW()
    local caster = self:GetCaster()
    local casterLocation = caster:GetAbsOrigin()
    local castDelay = 2
    local radius = self:GetSpecialValueFor("radius")
    --[[if caster:GetAbsOrigin().y < -3500 then
        SendErrorMessage(caster:GetPlayerOwnerID(), "#Already_In_Marble")
        caster:SetMana(caster:GetMana() + 800)
        keys.ability:EndCooldown()
        return
    end 

    local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius - 550, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    for q,w in pairs(targets) do
        giveUnitDataDrivenModifier(caster, w, "pause_sealdisabled", castDelay)
    end

    EmitGlobalSound("emiya_ubw7")

    giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", castDelay)
    --keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, "modifier_ubw_freeze",{})



    Timers:CreateTimer({
        endTime = castDelay,
        callback = function()
        if keys.caster:IsAlive() then
            local newLocation = caster:GetAbsOrigin()
            caster.UBWLocator = CreateUnitByName("ping_sign2", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
            caster.UBWLocator:FindAbilityByName("ping_sign_passive"):SetLevel(1)
            caster.UBWLocator:AddNewModifier(caster, caster, "modifier_kill", {duration = 12.5})
            caster.UBWLocator:SetAbsOrigin(caster:GetAbsOrigin())
            OnUBWStart(keys)

            keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, "modifier_ubw_death_checker",{})
            if caster.IsMartinAcquired then
                keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_shroud_of_martin_str_bonus", {})
            end

            local entranceFlashParticle = ParticleManager:CreateParticle("particles/custom/archer/ubw/entrance_flash.vpcf", PATTACH_ABSORIGIN, caster)
            ParticleManager:SetParticleControl(entranceFlashParticle, 0, newLocation)
            ParticleManager:CreateParticle("particles/custom/archer/ubw/exit_flash.vpcf", PATTACH_ABSORIGIN, caster)
        end
    end
    })

    -- DebugDrawCircle(caster:GetAbsOrigin(), Vector(255,0,0), 0.5, keys.Radius, true, 2.5)

    for i=2, 3 do
        local dummy = CreateUnitByName("dummy_unit", casterLocation, false, caster, caster, i)
        dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
        dummy:SetAbsOrigin(ubwCenter)
        AddFOWViewer(i, ubwCenter, 1800, 3, false)

        local particle = ParticleManager:CreateParticleForTeam("particles/custom/archer/ubw/firering.vpcf", PATTACH_ABSORIGIN, dummy, i)
        ParticleManager:SetParticleControl(particle, 6, casterLocation)
        local particleRadius = 0
        Timers:CreateTimer(0, function()
            if particleRadius < keys.Radius then
                particleRadius = particleRadius + keys.Radius * 0.03 / 2
                ParticleManager:SetParticleControl(particle, 1, Vector(particleRadius,0,0))
                return 0.03
            end
        end)
    end
end]]

function emiya_chant_ubw:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self
    
    caster:FindAbilityByName("archer_5th_sword_barrage_retreat_shot"):SetLevel(self:GetLevel())    
    caster:FindAbilityByName("archer_5th_sword_barrage_confine"):SetLevel(self:GetLevel())
    caster:FindAbilityByName("emiya_gae_bolg"):SetLevel(self:GetLevel())
    caster:FindAbilityByName("archer_5th_nine_lives"):SetLevel(self:GetLevel())
    caster:FindAbilityByName("archer_5th_sword_barrage"):SetLevel(self:GetLevel())
    caster:FindAbilityByName("archer_5th_ubw"):SetLevel(self:GetLevel())
end


function emiya_chant_ubw:GetCastAnimation()
    return ACT_DOTA_CAST_ABILITY_4
end

function emiya_chant_ubw:GetAbilityTextureName()
    return "custom/archer_5th_ubw"
end