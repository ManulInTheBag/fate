gawain_sun_of_galatine = class({})

LinkLuaModifier("modifier_sun_of_galatine_self", "abilities/gawain/modifiers/modifier_sun_of_galatine_self", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sun_of_galatine_slow", "abilities/gawain/modifiers/modifier_sun_of_galatine_slow", LUA_MODIFIER_MOTION_NONE)

function gawain_sun_of_galatine:GetAbilityDamageType()
    return DAMAGE_TYPE_MAGICAL
end

function gawain_sun_of_galatine:GetAOERadius()
    return self:GetSpecialValueFor("area_of_effect")
end

function gawain_sun_of_galatine:OnSpellStart()
    local caster = self:GetCaster()
    local ability = self
    local radius = self:GetAOERadius()
    local damage = self:GetSpecialValueFor("damage")

    ---Spawn sun
    local sunAbility = caster:FindAbilityByName("gawain_artificial_sun")
    sunAbility:GenerateArtificialSun(caster, caster:GetAbsOrigin(), false, self:GetName())

    local explosionFx = ParticleManager:CreateParticle("particles/custom/gawain/gawain_supernova_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(explosionFx, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(explosionFx, 1, Vector(3,0,0))

    local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
    for k,v in pairs(targets) do            
        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
        v:AddNewModifier(caster, self, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration")})     
    end 
    if(caster.IsBeltAcquired) then
        local RunesFx = ParticleManager:CreateParticle("particles/gawain/gawain_sun_of_galatine_atribute_indicator.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(RunesFx, 0, caster:GetAbsOrigin())
        local expPosition = caster:GetAbsOrigin()
        Timers:CreateTimer(0.8, function()
            ParticleManager:DestroyParticle(RunesFx, true)
            ParticleManager:ReleaseParticleIndex(RunesFx)
            local explosionFx2 = ParticleManager:CreateParticle("particles/gawain/gawain_sun_of_galatine_atribute_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil)
            ParticleManager:SetParticleControl(explosionFx2, 0, expPosition)
            ParticleManager:ReleaseParticleIndex(explosionFx2)
            caster:EmitSound("Gawain_Sun_Explode")
            local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 350, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
            for k,v in pairs(targets) do            
                DoDamage(caster, v, damage*0.5, DAMAGE_TYPE_MAGICAL, 0, ability, false)
                v:AddNewModifier(caster, self, "modifier_stunned", {Duration = 0.1})     
            end 
        end)

    end
 
    caster:EmitSound("Gawain_Sun_Explode")
end