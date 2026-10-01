kama_q = class({})

--[[ Kama Q
     Создано панелью. ScriptFile: abilities/kama/kama_q
     
]]

function kama_q:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function kama_q:OnAbilityPhaseStart()
    StartAnimation(self:GetCaster(), {duration = self:GetCastPoint(),
        activity = ACT_DOTA_CAST_ABILITY_1, rate = 1.0})
    return true
end

function kama_q:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end

function kama_q:OnSpellStart()
    if not IsServer() then return end
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    EndAnimation(caster)
    --caster:EmitSound("kama_q_cast")

    local radius = self:GetSpecialValueFor("radius")
    local damage = self:GetSpecialValueFor("damage")

    --local fx = ParticleManager:CreateParticle("particles/kama/kama_q.vpcf",
    --    PATTACH_WORLDORIGIN, nil)
    --ParticleManager:SetParticleControl(fx, 0, point)
    --ParticleManager:SetParticleControl(fx, 1, Vector(radius, 0, 0))
    --ParticleManager:ReleaseParticleIndex(fx)

    local enemies = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, radius,
        self:GetAbilityTargetTeam(), self:GetAbilityTargetType(),
        self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
    for _, enemy in pairs(enemies) do
        if IsNotNull(enemy) and not IsSpellBlocked(enemy, caster) then
            DoDamage(caster, enemy, damage, self:GetAbilityDamageType(), 0, self, false)
        end
    end
end
