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
-- Скрытая пассивка лука: выставляет вид стрел по умолчанию и проводит
-- автоатаки через общую точку попадания стрелы.
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
    }
end

-- Новый приказ обрывает анимацию «после выстрела» (см. Kama_FadeRecovery).
function modifier_kama_sugarcane_bow:OnOrder(keys)
    if not IsServer() or keys.unit ~= self:GetParent() then return end
    Kama_FadeRecovery(self:GetParent())
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
