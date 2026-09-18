require("abilities/barghest/barghest_shared")
require("abilities/barghest/barghest_vision_cone")

barghest_d = class({})

--[[ Hound's Fury (D)

     Мгновенный самобаф на `duration` секунд: +`bonus_str` силы, +`bonus_ms_pct`%
     скорости, красная подсветка (status fx) и конус обзора
     (modifier_barghest_vision_cone — раньше висел на комбо, теперь живёт здесь).

     Главное — СЧЁТЧИК полученного урона. Пока баф висит, весь входящий урон
     складывается; как только накопилось `threshold_pct`% от её максимального
     здоровья (не за удар и не порог текущего HP — именно сумма), срабатывает
     «рывок»: кулдауны Q/W/E/R укорачиваются на `cd_reduce` секунд и с неё
     снимаются негативные эффекты (HardCleanse из util). Срабатывать может
     сколько угодно раз за длительность, но каждый следующий порог на
     `threshold_step`% ниже, не ниже `threshold_min`%: 80 → 60 → 40 → 30 → 30…
     Остаток счётчика сверх порога переносится на следующий порог.

     ⚠️ Из колбэка урона ничего не снимаем и не трогаем: движок в этот момент
     идёт по модификаторам юнита (см. barghest_f:OnTakeDamage). Всё, что
     срабатывает, — следующим тиком через Timers.

     ⚠️ Стаки модификатора — накопленный урон в % от макс. HP (сетевые, игрок
     видит на иконке, сколько уже «набежало» до следующего порога).
]]

LinkLuaModifier("modifier_barghest_d", "abilities/barghest/barghest_d", LUA_MODIFIER_MOTION_NONE)

function barghest_d:Value(sKey)
    return self:GetSpecialValueFor(sKey)
end

function barghest_d:OnSpellStart()
    if not IsServer() then return end
    local hCaster = self:GetCaster()
    local fDuration = self:Value("duration")

    hCaster:AddNewModifier(hCaster, self, "modifier_barghest_d", {duration = fDuration})
    hCaster:AddNewModifier(hCaster, self, "modifier_barghest_vision_cone", {duration = fDuration})

    Barghest_Voice(hCaster, BARGHEST_VO.D, 2.0)
    hCaster:EmitSound(BARGHEST_SND.R_FIRE)
    Barghest_FxOn(BARGHEST_FX.BURST, hCaster, 1.5)
end

--[[ Срезать кулдаун одной способности на fSeconds, не уходя в минус. Приём
     из barghest_r:RewardHit. ]]
local function ReduceCooldown(hAbility, fSeconds)
    if not Barghest_Alive(hAbility) then return end
    local fLeft = hAbility:GetCooldownTimeRemaining()
    if fLeft <= 0 then return end
    fLeft = fLeft - fSeconds
    hAbility:EndCooldown()
    if fLeft > 0 then
        hAbility:StartCooldown(fLeft)
    end
end

modifier_barghest_d = class({})

function modifier_barghest_d:IsHidden()      return false end
function modifier_barghest_d:IsDebuff()      return false end
function modifier_barghest_d:IsPurgable()    return false end
function modifier_barghest_d:RemoveOnDeath() return true end

function modifier_barghest_d:GetTexture()
    return "custom/barghest/barghest_d"
end

function modifier_barghest_d:GetStatusEffectName()
    return "particles/econ/items/lifestealer/ls_ti9_immortal/status_effect_ls_ti9_open_wounds.vpcf"
end

function modifier_barghest_d:StatusEffectPriority()
    return 10
end

-- ⚠️ Без IsServer-гарда: сила и скорость обязаны считаться и на клиенте.
function modifier_barghest_d:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end

function modifier_barghest_d:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_barghest_d:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_ms_pct")
end

function modifier_barghest_d:OnCreated()
    if not IsServer() then return end
    self:Reset()
end

-- Повторный каст поверх — свежая активация: порог снова стартовый, счётчик пуст.
function modifier_barghest_d:OnRefresh()
    if not IsServer() then return end
    self:Reset()
end

function modifier_barghest_d:Reset()
    self.fDamage     = 0                                            -- накоплено урона (абсолют)
    self.nThreshold  = self:GetAbility():GetSpecialValueFor("threshold_pct")   -- текущий порог, % макс. HP
    self:SetStackCount(0)
end

--[[ Стаки = накопленный урон в процентах от макс. HP. ]]
function modifier_barghest_d:UpdateStacks()
    local hParent = self:GetParent()
    local nMax = hParent:GetMaxHealth()
    if nMax <= 0 then return end
    self:SetStackCount(math.floor(self.fDamage * 100 / nMax))
end

function modifier_barghest_d:OnTakeDamage(keys)
    if not IsServer() then return end
    local hParent = self:GetParent()
    if keys.unit ~= hParent then return end
    if keys.damage <= 0 then return end
    if keys.attacker == hParent then return end     -- урон по себе не считаем
    if not hParent:IsAlive() then return end
    if self.fDamage == nil then self:Reset() end

    self.fDamage = self.fDamage + keys.damage

    local fNeed = hParent:GetMaxHealth() * self.nThreshold * 0.01
    if self.fDamage < fNeed then
        self:UpdateStacks()
        return
    end

    -- Порог взят: остаток переносим, следующий порог ниже.
    local hAbility = self:GetAbility()
    self.fDamage = self.fDamage - fNeed
    self.nThreshold = math.max(
        hAbility:GetSpecialValueFor("threshold_min"),
        self.nThreshold - hAbility:GetSpecialValueFor("threshold_step"))
    self:UpdateStacks()

    -- ⚠️ Снимать модификаторы и трогать кулдауны прямо из колбэка урона нельзя
    -- (см. шапку) — следующим тиком.
    Timers:CreateTimer(0, function()
        if not Barghest_Alive(hParent) or not hParent:IsAlive() then return end
        if not Barghest_Alive(hAbility) then return end
        local fCd = hAbility:GetSpecialValueFor("cd_reduce")
        for _, sName in ipairs({"barghest_q", "barghest_w", "barghest_e", "barghest_r"}) do
            ReduceCooldown(hParent:FindAbilityByName(sName), fCd)
        end
        HardCleanse(hParent)
        hParent:EmitSound(BARGHEST_SND.HIT)
        Barghest_FxOn(BARGHEST_FX.BURST, hParent, 1.5)
    end)
end
