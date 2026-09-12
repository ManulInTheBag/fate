modifier_rasputin_territory = class({})

function modifier_rasputin_territory:IsHidden() return false end
function modifier_rasputin_territory:IsPurgable() return false end
function modifier_rasputin_territory:IsDebuff() return false end
function modifier_rasputin_territory:RemoveOnDeath() return false end


local TICK = 0.5


local CLEANSE_WAVE_TIME = 0.5


function modifier_rasputin_territory:OnCreated(kv)

    if not IsServer() then return end

    self:ReadKeys(kv)

    self.fx = ParticleManager:CreateParticle(
        RasputinFx(self:GetParent(), "particles/rasputin/rasputin_territory_creation.vpcf"),
        PATTACH_ABSORIGIN_FOLLOW,
        self:GetParent()
    )

    self:SizeParticle()

    self:StartIntervalThink(TICK)

    self:ScheduleCleanses()

end


function modifier_rasputin_territory:OnRefresh(kv)

    if not IsServer() then return end

    self:ReadKeys(kv)

    self:SizeParticle()

    self:ScheduleCleanses()

end


function modifier_rasputin_territory:ReadKeys(kv)

    self.radius = kv.radius


    self.regen = kv.regen

    self.waves = kv.waves
    self.waveInterval = kv.wave_interval

    self.duration = kv.duration

end


function modifier_rasputin_territory:SizeParticle()

    if not self.fx then return end

    ParticleManager:SetParticleControl(
        self.fx,
        1,
        Vector(self.radius, self.duration or 0, 0)
    )


    ParticleManager:SetParticleControl(self.fx, 2, Vector(self.radius, 0, 0))

end


function modifier_rasputin_territory:ScheduleCleanses()


    self.generation = (self.generation or 0) + 1

    local generation = self.generation

    self.wavesLeft = 0

    if not self.waves or self.waves < 1 then return end

    self.wavesLeft = self.waves


    local ability = self:GetAbility()

    local tail = 0

    if IsNotNull(ability) then
        tail = ability:GetLevelSpecialValueFor("territory_wave_tail", 0)
    end

    local last = (self:GetDuration() or 0) - tail

    for i = 1, self.waves do

        local at = self.waveInterval * i

        if last > 0 and at > last then
            at = last
        end

        Timers:CreateTimer(at, function()


            if not IsNotNull(self) then return end

            if self.generation ~= generation then return end

            self.wavesLeft = math.max((self.wavesLeft or 0) - 1, 0)

            self:Cleanse()

        end)

    end

end


-- Территория снимается досрочно (поверх легла новая): волны очистки, до
-- которых она не дожила, схлопываются в одну и срабатывают сейчас
function modifier_rasputin_territory:FinishEarly()

    if not IsServer() then return end

    -- отменяет уже поставленные таймеры волн
    self.generation = (self.generation or 0) + 1

    if (self.wavesLeft or 0) < 1 then return end

    self.wavesLeft = 0

    self:Cleanse()

end


function modifier_rasputin_territory:FindAllies()

    local parent = self:GetParent()

    if not IsNotNull(parent) then return {} end


    return FindUnitsInRadius(
        parent:GetTeamNumber(),
        parent:GetAbsOrigin(),
        nil,
        self.radius,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

end


function modifier_rasputin_territory:Cleanse()

    if not IsServer() then return end

    local allies = self:FindAllies()


    for _,ally in pairs(allies) do

        if ally:IsAlive() then
            ApplyStrongDispel(ally)
        end

    end

    self:CleanseWave()

end


function modifier_rasputin_territory:CleanseWave()

    local parent = self:GetParent()

    if not IsNotNull(parent) then return end

    local radius = self.radius or 0

    if radius <= 0 then return end

    local origin = parent:GetAbsOrigin()

    local fx = ParticleManager:CreateParticle(
        RasputinFx(self:GetParent(), "particles/rasputin/rasputin_cleanse_new.vpcf"),
        PATTACH_CUSTOMORIGIN,
        parent
    )

    ParticleManager:SetParticleControl(fx, 0, origin)

    ParticleManager:SetParticleControl(
        fx,
        1,
        Vector(radius / CLEANSE_WAVE_TIME, CLEANSE_WAVE_TIME, 0)
    )

    ParticleManager:ReleaseParticleIndex(fx)

end


function modifier_rasputin_territory:OnIntervalThink()

    if not IsServer() then return end

    local amount = self.regen * TICK

    if amount <= 0 then return end

    local ability = self:GetAbility()

    for _,ally in pairs(self:FindAllies()) do

        if ally:IsAlive() then
            ally:Heal(amount, IsNotNull(ability) and ability or ally)
            ally:GiveMana(amount)
        end

    end

end


function modifier_rasputin_territory:OnDestroy()

    if not IsServer() then return end

    if self.fx then
        ParticleManager:DestroyParticle(self.fx, false)
        ParticleManager:ReleaseParticleIndex(self.fx)
        self.fx = nil
    end

end
