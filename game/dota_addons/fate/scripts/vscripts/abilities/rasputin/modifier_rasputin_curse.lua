modifier_rasputin_curse = class({})


local CURSE_FX = {
    { path = "particles/rasputin/rasputin_curse_lvl1.vpcf", radius_cp = 1 },
    { path = "particles/rasputin/rasputin_curse_lvl2.vpcf", radius_cp = 3, life_cp = 4 },
    { path = "particles/rasputin/rasputin_curse_lvl3.vpcf" },
}


local CURSE_FX_RADIUS = 60


local CURSE_FX_LIFETIME = 999


local CURSE_THINK = 0.1


local CURSE_DECAY_GRACE = 0.25


local CURSE_ANTIHEAL_WEAK = "modifier_heal_reduction_tier_2"
local CURSE_ANTIHEAL_STRONG = "modifier_heal_reduction_tier_3"
local CURSE_ANTIHEAL_REFRESH = 1.0
local CURSE_ANTIHEAL_EVERY = 0.5


-- 3-й уровень: димлок стандартным "locked" (см. util.lua locks/IsLocked),
-- подливается каждый тик, как в клетке Озимандиаса
local CURSE_LOCK_REFRESH = 0.15


function modifier_rasputin_curse:IsHidden() return false end
function modifier_rasputin_curse:IsDebuff() return true end


function modifier_rasputin_curse:IsPurgable() return false end
function modifier_rasputin_curse:RemoveOnDeath() return false end

function modifier_rasputin_curse:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function modifier_rasputin_curse:Value(key)

    local ability = self:GetAbility()

    if not ability or ability:IsNull() then return 0 end

    return ability:GetLevelSpecialValueFor(key, 0)

end


function modifier_rasputin_curse:Level()

    local perLevel = self:Value("curse_stacks_per_level")

    if perLevel <= 0 then return 0 end

    local level = math.floor(self:GetStackCount() / perLevel)

    local cap = self:Value("curse_max_level")

    if level > cap then
        level = cap
    end

    return level

end


function modifier_rasputin_curse:Ceiling()

    local ceiling = self:Value("curse_max_stacks")


    local threshold =
    self:Value("curse_max_level") * self:Value("curse_stacks_per_level")

    if ceiling < threshold then
        ceiling = threshold
    end

    return ceiling

end


function modifier_rasputin_curse:OnCreated()

    if not IsServer() then return end

    self:SetStackCount(0)


    self.raw = 0


    self.shown = -1


    self.fx = {}


    self.manaCancel = 0


    self:MaintainAntiHeal(true)

    self:StartIntervalThink(CURSE_THINK)

end


function modifier_rasputin_curse:ShowLevels()

    if not IsServer() then return end

    local level = self:Level()

    if level == self.shown then return end

    self.shown = level


    self:MaintainAntiHeal(true)

    local parent = self:GetParent()


    for at,fx in pairs(self.fx) do

        if at > level then


            ParticleManager:DestroyParticle(fx, false)
            ParticleManager:ReleaseParticleIndex(fx)

            self.fx[at] = nil

        end

    end

    for at = 1, level do

        local spec = CURSE_FX[at]

        if not self.fx[at] and spec then

            local fx = ParticleManager:CreateParticle(
                spec.path,
                PATTACH_ABSORIGIN_FOLLOW,
                parent
            )

            if spec.radius_cp then

                ParticleManager:SetParticleControl(
                    fx,
                    spec.radius_cp,
                    Vector(CURSE_FX_RADIUS, 0, 0)
                )

            end

            if spec.life_cp then

                ParticleManager:SetParticleControl(
                    fx,
                    spec.life_cp,
                    Vector(CURSE_FX_LIFETIME, 0, 0)
                )

            end

            self.fx[at] = fx

        end

    end


    self:HoldLock()

end


-- Уровень 3: пока держится, цель под dimensional lock
function modifier_rasputin_curse:HoldLock()

    if not IsServer() then return end

    if self:Level() < self:Value("curse_max_level") then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()

    if not IsNotNull(parent) or not IsNotNull(caster) then return end

    giveUnitDataDrivenModifier(caster, parent, "locked", CURSE_LOCK_REFRESH)

end


function modifier_rasputin_curse:HideLevels()

    if not IsServer() then return end

    for _,fx in pairs(self.fx or {}) do

        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)

    end

    self.fx = {}
    self.shown = -1

end


function modifier_rasputin_curse:Feed(amount)

    if not IsServer() then return end

    self.fedAt = GameRules:GetGameTime()

    if not amount or amount <= 0 then return end

    self.raw = math.min((self.raw or 0) + amount, self:Ceiling())

    self:SetStackCount(math.floor(self.raw))

    self:ShowLevels()

end


function modifier_rasputin_curse:MaintainAntiHeal(force)

    if not IsServer() then return end

    local parent = self:GetParent()

    if not IsNotNull(parent) then return end

    local caster = self:GetCaster()

    if not IsNotNull(caster) then return end

    local strong = self:Level() >= 1

    local want = strong and CURSE_ANTIHEAL_STRONG or CURSE_ANTIHEAL_WEAK
    local drop = strong and CURSE_ANTIHEAL_WEAK or CURSE_ANTIHEAL_STRONG

    local now = GameRules:GetGameTime()

    if not force
    and self.antiHeal == want
    and now - (self.antiHealAt or 0) < CURSE_ANTIHEAL_EVERY
    then
        return
    end

    if self.antiHeal and self.antiHeal ~= want then
        parent:RemoveModifierByNameAndCaster(drop, caster)
    end

    self.antiHeal = want
    self.antiHealAt = now

    parent:AddNewModifier(
        caster,
        self:GetAbility(),
        want,
        {
            duration = CURSE_ANTIHEAL_REFRESH,
        }
    )

end


function modifier_rasputin_curse:OnIntervalThink()

    if not IsServer() then return end


    if _G.CurrentGameState == "FATE_POST_ROUND" then
        self:Destroy()
        return
    end


    self:MaintainAntiHeal(false)


    self:HoldManaRegen()

    self:HoldLock()


    if self.fedAt
    and GameRules:GetGameTime() - self.fedAt < CURSE_DECAY_GRACE
    then
        return
    end

    local time = self:Value("curse_decay_time")

    local perLevel = self:Value("curse_stacks_per_level")


    local rate = time > 0 and (perLevel / time) or perLevel

    self.raw = (self.raw or 0) - rate * CURSE_THINK

    if self.raw <= 0 then
        self:Destroy()
        return
    end

    self:SetStackCount(math.floor(self.raw))

    self:ShowLevels()

end


function modifier_rasputin_curse:DeclareFunctions()

    return {
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_ABILITY_START,
    }

end


function modifier_rasputin_curse:HoldManaRegen()

    if not IsServer() then return end

    if self:Level() < 2 then
        self.manaCancel = 0
        return
    end

    local parent = self:GetParent()

    if not IsNotNull(parent) then return end


    local without = parent:GetManaRegen() + (self.manaCancel or 0)

    if without < 0 then
        without = 0
    end

    self.manaCancel = without

end


function modifier_rasputin_curse:GetModifierConstantManaRegen()

    if self:Level() < 2 then return 0 end

    return -(self.manaCancel or 0)

end


function modifier_rasputin_curse:GetModifierTotalPercentageManaRegen()


    if IsServer() then return 0 end

    if self:Level() < 2 then return 0 end

    return -100

end


-- каждый стак режет скорость
function modifier_rasputin_curse:GetModifierMoveSpeedBonus_Percentage()
    return -self:GetStackCount() * self:Value("curse_slow_per_stack")
end


-- уровень 2: меньше исходящего урона
function modifier_rasputin_curse:GetModifierDamageOutgoing_Percentage()

    if self:Level() < 2 then return 0 end

    return -self:Value("curse_damage_reduction_pct")

end


-- уровень 3: любой каст (кроме предметов) приземляет цель рутом на миг -
-- рывки, не уважающие димлок, обрываются, как в клетке Озимандиаса
function modifier_rasputin_curse:OnAbilityStart(keys)

    if not IsServer() then return end

    local parent = self:GetParent()

    if keys.unit ~= parent then return end

    if not IsNotNull(keys.ability) or keys.ability:IsItem() then return end

    if self:Level() < self:Value("curse_max_level") then return end

    local rootFor = self:Value("curse_root_duration")

    if rootFor <= 0 then return end

    parent:AddNewModifier(
        self:GetCaster(),
        self:GetAbility(),
        "modifier_rooted",
        {
            duration = rootFor
        }
    )

end


function modifier_rasputin_curse:OnDestroy()

    if not IsServer() then return end

    self:HideLevels()

    local parent = self:GetParent()

    if not IsNotNull(parent) then return end

    -- "locked" не снимаем: он общий, истечёт сам через 0.15 с

    local caster = self:GetCaster()

    if self.antiHeal and IsNotNull(caster) then
        parent:RemoveModifierByNameAndCaster(self.antiHeal, caster)
    end

end
