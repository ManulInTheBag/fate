kama_sugarcane_bow = class({})

--[[ Kama F
     Создано панелью. ScriptFile: abilities/kama/kama_sugarcane_bow
     
]]

LinkLuaModifier("modifier_kama_sugarcane_bow", "abilities/kama/kama_sugarcane_bow",
    LUA_MODIFIER_MOTION_NONE)

function kama_sugarcane_bow:GetIntrinsicModifierName()
    return "modifier_kama_sugarcane_bow"
end

modifier_kama_sugarcane_bow = class({})

function modifier_kama_sugarcane_bow:IsHidden()      return false end
function modifier_kama_sugarcane_bow:IsPurgable()    return false end
function modifier_kama_sugarcane_bow:RemoveOnDeath() return false end

-- ⚠️ Без IsServer-гарда: бонус обязан считаться и на клиенте, иначе игрок
-- увидит в интерфейсе не то, что реально работает.
function modifier_kama_sugarcane_bow:DeclareFunctions()
    return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE}
end

function modifier_kama_sugarcane_bow:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end
