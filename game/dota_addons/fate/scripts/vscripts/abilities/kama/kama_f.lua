kama_f = class({})

--[[ Kama F
     Создано панелью. ScriptFile: abilities/kama/kama_f
     
]]

LinkLuaModifier("modifier_kama_f", "abilities/kama/kama_f",
    LUA_MODIFIER_MOTION_NONE)

function kama_f:GetIntrinsicModifierName()
    return "modifier_kama_f"
end

modifier_kama_f = class({})

function modifier_kama_f:IsHidden()      return false end
function modifier_kama_f:IsPurgable()    return false end
function modifier_kama_f:RemoveOnDeath() return false end

-- ⚠️ Без IsServer-гарда: бонус обязан считаться и на клиенте, иначе игрок
-- увидит в интерфейсе не то, что реально работает.
function modifier_kama_f:DeclareFunctions()
    return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE}
end

function modifier_kama_f:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end
