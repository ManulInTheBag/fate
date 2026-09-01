modifier_rasputin_knife_dash_tracker = class({})


function modifier_rasputin_knife_dash_tracker:IsHidden()
    return false
end

function modifier_rasputin_knife_dash_tracker:IsDebuff()
    return false
end

function modifier_rasputin_knife_dash_tracker:GetTexture()
    return "custom/rasputin/rasputin_knife_dash_1"
end

function modifier_rasputin_knife_dash_tracker:IsPurgable()
    return false
end

function modifier_rasputin_knife_dash_tracker:RemoveOnDeath()
    return true
end


function modifier_rasputin_knife_dash_tracker:OnCreated()

    if not IsServer() then return end

    self:SetStackCount(1)

    local ability = self:GetAbility()
    local caster = self:GetCaster()


    self.marked = caster.dash_target


    ability.radius_ring_fx =
    ParticleManager:CreateParticleForTeam(
        RasputinFx(caster, "particles/rasputin/rasputin_dash_radius.vpcf"),
        PATTACH_ABSORIGIN_FOLLOW,
        caster,
        caster:GetTeam()
    )


    ParticleManager:SetParticleControl(
        ability.radius_ring_fx,
        1,
        Vector(
            ability:GetSpecialValueFor("distance"),
            0,
            0
        )
    )


    self:StartIntervalThink(0.25)

end


-- помеченная цель умерла - секвенция гаснет сама: метка снимается, иконка
-- возвращается на Q1, способность уходит в обычный кулдаун
function modifier_rasputin_knife_dash_tracker:OnIntervalThink()

    if not IsServer() then return end

    if IsNotNull(self.marked) and self.marked:IsAlive() then return end

    self:Destroy()

end


function modifier_rasputin_knife_dash_tracker:OnDestroy()

    if not IsServer() then return end


    local ability = self:GetAbility()


    local caster = self:GetCaster()

    if RasputinReleaseKnifeMark and IsNotNull(self.marked) then
        RasputinReleaseKnifeMark(self.marked, ability)
    end


    if IsNotNull(caster) and caster.dash_target == self.marked then
        caster.dash_target = nil
    end

    self.marked = nil


    if not self.consumed and IsNotNull(ability) then
        ability:StartSequenceCooldown()
    end


    if ability.radius_ring_fx then

        ParticleManager:DestroyParticle(
            ability.radius_ring_fx,
            true
        )

        ParticleManager:ReleaseParticleIndex(
            ability.radius_ring_fx
        )

        ability.radius_ring_fx = nil

    end

end
