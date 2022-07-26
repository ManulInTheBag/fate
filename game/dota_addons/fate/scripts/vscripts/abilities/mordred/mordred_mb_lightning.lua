mordred_mb_lightning = class({})

LinkLuaModifier("modifier_mb_lightning_slow", "abilities/mordred/mordred_mb_lightning", LUA_MODIFIER_MOTION_NONE)

function mordred_mb_lightning:GetAbilityDamageType()
    return DAMAGE_TYPE_MAGICAL
end

function mordred_mb_lightning:GetAOERadius()
    return self:GetSpecialValueFor("area_of_effect")
end

function mordred_mb_lightning:OnSpellStart()
    local caster = self:GetCaster()
    local ability = self
    local radius = self:GetAOERadius()
    local damage = self:GetSpecialValueFor("damage")

    local mana_perc = self:GetSpecialValueFor("mana_percent")
    local mana = caster:GetMana()*mana_perc/100

    if caster:GetMana() < mana then
        mana = caster:GetMana()
    end

    if not caster:HasModifier("pedigree_off") then
        mana = 1
    end

    caster:SpendMana(mana, self)

    damage = damage + mana*self:GetSpecialValueFor("mana_damage")/100

    EmitSoundOn("mordred_teme", caster)

    local purgeFx = ParticleManager:CreateParticle("particles/custom/mordred/gods_resolution/gods_resolution_active_circle.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl( purgeFx, 0, caster:GetAbsOrigin())

    local iPillarFx = ParticleManager:CreateParticle("particles/custom/mordred/purge_the_unjust/ruler_purge_the_unjust_a.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl( iPillarFx, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl( iPillarFx, 1, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl( iPillarFx, 2, caster:GetAbsOrigin())

    Timers:CreateTimer(1.0, function()
        ParticleManager:DestroyParticle(iPillarFx, false)
        ParticleManager:ReleaseParticleIndex(iPillarFx)
    end)

    --[[if caster.CurseOfRetributionAcquired then
        caster:FindAbilityByName("mordred_curse_passive"):ShieldCharge()
    end]]

    local visiondummy = SpawnVisionDummy(caster, caster:GetAbsOrigin(), radius, self:GetSpecialValueFor("vision_duration"), true)

    local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
    for k,v in pairs(targets) do            
        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
        v:AddNewModifier(caster, self, "modifier_stunned", {Duration = 0.7})
        EmitSoundOn("mordred_lightning", v)
        Timers:CreateTimer(0.01, function()
            local particle = ParticleManager:CreateParticle("particles/custom/mordred/zuus_lightning_bolt.vpcf", PATTACH_WORLDORIGIN, v)
            local target_point = v:GetAbsOrigin()
            ParticleManager:SetParticleControl(particle, 0, Vector(target_point.x, target_point.y, target_point.z))
            ParticleManager:SetParticleControl(particle, 1, Vector(target_point.x, target_point.y, 2000))
            ParticleManager:SetParticleControl(particle, 2, Vector(target_point.x, target_point.y, target_point.z))
        end)     
    end 
end