kama_r = class({})

--[[ Kama R
     Создано панелью. ScriptFile: abilities/kama/kama_r
     
]]

function kama_r:OnAbilityPhaseStart()
    StartAnimation(self:GetCaster(), {duration = self:GetCastPoint(),
        activity = ACT_DOTA_CAST_ABILITY_1, rate = 1.0})
    return true
end

function kama_r:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end

function kama_r:OnSpellStart()
    if not IsServer() then return end
    local caster = self:GetCaster()
    EndAnimation(caster)
    --caster:EmitSound("kama_r_cast")

    local radius = self:GetSpecialValueFor("radius")
    local damage = self:GetSpecialValueFor("damage")

    --local fx = ParticleManager:CreateParticle("particles/kama/kama_r.vpcf",
    --    PATTACH_ABSORIGIN, caster)
    --ParticleManager:SetParticleControl(fx, 0, caster:GetAbsOrigin())
    --ParticleManager:SetParticleControl(fx, 1, Vector(radius, 0, 0))
    --ParticleManager:ReleaseParticleIndex(fx)

    local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(),
        nil, radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(),
        self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
    for _, enemy in pairs(enemies) do
        if IsNotNull(enemy) and not IsSpellBlocked(enemy, caster) then
            DoDamage(caster, enemy, damage, self:GetAbilityDamageType(), 0, self, false)
        end
    end
end
