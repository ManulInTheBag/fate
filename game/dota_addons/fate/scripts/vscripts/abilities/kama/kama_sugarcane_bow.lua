require("abilities/kama/kama_shared")

kama_sugarcane_bow = kama_sugarcane_bow or class({})

--[[ F — Sugarcane Bow. Переключает вид стрел: Floral (одна цель и контроль) или
     Samsara (по площади и пробитие). Сам вид — модификатор-метка из kama_shared,
     его читают Q, E и D.
]]

LinkLuaModifier("modifier_kama_sugarcane_bow", "abilities/kama/kama_sugarcane_bow",
    LUA_MODIFIER_MOTION_NONE)

function kama_sugarcane_bow:GetIntrinsicModifierName()
    return "modifier_kama_sugarcane_bow"
end

function kama_sugarcane_bow:OnSpellStart()
    local caster = self:GetCaster()
    Kama_SetStance(caster, not Kama_IsSamsara(caster))
end

--=========================================================================--
-- Скрытая пассивка лука: выставляет вид стрел по умолчанию, проводит автоатаки
-- через общую точку попадания стрелы и играет анимацию автоатаки.
modifier_kama_sugarcane_bow = class({})

function modifier_kama_sugarcane_bow:IsHidden()      return true end
function modifier_kama_sugarcane_bow:IsPurgable()    return false end
function modifier_kama_sugarcane_bow:RemoveOnDeath() return false end
function modifier_kama_sugarcane_bow:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_kama_sugarcane_bow:OnCreated()
    if not IsServer() then return end
    self:EnsureStance()
end

function modifier_kama_sugarcane_bow:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_RESPAWN,
        MODIFIER_EVENT_ON_ORDER,
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_EVENT_ON_ATTACK_CANCELLED,
    }
end

--[[ Анимация автоатаки — тот же жест, что у выстрела Q (секвенция q_shot).
     В модели НЕТ секвенции на ACT_DOTA_ATTACK: движок играл бы её основной
     анимацией и после выстрела держал бы последний кадр до следующей атаки —
     Кама замирала с поднятым луком. Жест поверх обычной стойки гаснет сам, и
     между выстрелами она возвращается в стойку, как после Q.
     Скорость жеста — множитель скорости атаки: срыв тетивы (5-6 кадр) попадает
     на момент выстрела (AttackAnimationPoint 0.17 в KV героя). ]]
function modifier_kama_sugarcane_bow:OnAttackStart(keys)
    if not IsServer() or keys.attacker ~= self:GetParent() then return end
    local parent = self:GetParent()
    local fRate = parent:GetAttackSpeed(true)
    if not fRate or fRate <= 0 then fRate = 1 end

    Kama_StopAnimations(parent, true)
    -- затухания делим на скорость, чтобы на быстрой атаке жест не гас раньше срыва
    Kama_Gesture(parent, KAMA_SHOT_GESTURE, 0.1 / fRate, 0.4 / fRate, fRate)
    Kama_Backswing(parent, self:GetAbility(), KAMA_SHOT_LENGTH / fRate, KAMA_SHOT_GESTURE, true)
end

-- Атака сорвалась до выстрела: замах бросаем.
function modifier_kama_sugarcane_bow:OnAttackCancelled(keys)
    if not IsServer() or keys.attacker ~= self:GetParent() then return end
    Kama_StopAnimations(self:GetParent())
end

-- Запоминаем, когда игрок в последний раз приказал Каме действовать: это
-- читает Kama_OrderedSince.
function modifier_kama_sugarcane_bow:OnOrder(keys)
    if not IsServer() or keys.unit ~= self:GetParent() then return end
    if Kama_IsActionOrder(keys.order_type) then
        self:GetParent().fKamaLastOrder = GameRules:GetGameTime()
    end
end

-- Метку вида стрел могло снести общей зачисткой модификаторов: возвращаем ту
-- же, что и была (нет ни одной — Floral).
function modifier_kama_sugarcane_bow:EnsureStance()
    local parent = self:GetParent()
    Kama_SetStance(parent, Kama_IsSamsara(parent))
end

function modifier_kama_sugarcane_bow:OnRespawn(keys)
    if not IsServer() or keys.unit ~= self:GetParent() then return end
    self:EnsureStance()
end

function modifier_kama_sugarcane_bow:OnAttackLanded(keys)
    if not IsServer() then return end
    local parent = self:GetParent()
    if keys.attacker ~= parent then return end
    local target = keys.target
    if not Kama_Alive(target) or target:GetTeamNumber() == parent:GetTeamNumber() then return end
    Kama_ArrowHit(parent, target, {})
end
