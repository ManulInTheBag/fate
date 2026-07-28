require("abilities/barghest/barghest_shared")

barghest_f = class({})

--[[ Blood of the Beast (F)
     Пассивка: слегка повышенное магическое сопротивление и лечение от
     НАНЕСЁННОГО урона — и от атак, и от способностей. Каждый стак разгона
     (`modifier_barghest_frenzy` из R) добавляет к вампиризму
     `lifesteal_per_frenzy`: чем дольше держится ротация qrqrqr, тем больше
     она с неё лечится.
     Прокачивается не уровнями, а атрибутом (в KV MaxLevel 1).
]]

LinkLuaModifier("modifier_barghest_f", "abilities/barghest/barghest_f", LUA_MODIFIER_MOTION_NONE)

function barghest_f:GetIntrinsicModifierName()
    return "modifier_barghest_f"
end

modifier_barghest_f = class({})

function modifier_barghest_f:IsHidden()      return false end
function modifier_barghest_f:IsDebuff()      return false end
function modifier_barghest_f:IsPurgable()    return false end
function modifier_barghest_f:RemoveOnDeath() return false end

-- ⚠️ Без IsServer-гарда: сопротивление обязано считаться и на клиенте, иначе
-- игрок увидит в интерфейсе не то, что реально работает.
function modifier_barghest_f:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end

function modifier_barghest_f:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_mr")
end

--[[ Сколько процентов урона возвращается здоровьем сейчас. ]]
function modifier_barghest_f:GetLifestealPct()
    local hAbility = self:GetAbility()
    local nPct = hAbility:GetSpecialValueFor("lifesteal_pct")
    local hFrenzy = self:GetParent():FindModifierByName("modifier_barghest_frenzy")
    if hFrenzy then
        nPct = nPct + hAbility:GetSpecialValueFor("lifesteal_per_frenzy")
                      * hFrenzy:GetStackCount()
    end
    return nPct
end

function modifier_barghest_f:OnTakeDamage(keys)
    if not IsServer() then return end
    local hParent = self:GetParent()
    if keys.attacker ~= hParent then return end
    if keys.damage <= 0 then return end
    if keys.unit == hParent then return end     -- с урона по себе не лечимся
    if not hParent:IsAlive() then return end

    local nHeal = keys.damage * self:GetLifestealPct() * 0.01
    if nHeal <= 0 then return end

    -- ⚠️ Лечить прямо из колбэка урона нельзя: движок в этот момент идёт по
    -- модификаторам юнита, и вложенная правка здоровья роняет сервер.
    -- Следующим тиком.
    local hAbility = self:GetAbility()
    Timers:CreateTimer(0, function()
        if not Barghest_Alive(hParent) or not hParent:IsAlive() then return end
        hParent:Heal(nHeal, hAbility)
        Barghest_FxAt(BARGHEST_FX.LIFESTEAL, hParent:GetAbsOrigin())
    end)
end
