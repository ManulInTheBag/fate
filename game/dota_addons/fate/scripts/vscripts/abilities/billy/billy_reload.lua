--[[ Reload! (F) — мгновенно перезаряжает револьвер до максимума пуль.
     Атрибут Quick Solver: ещё рывок скорости до quick_ms (абсолютная скорость —
     замедления её не режут) и −quick_cdr секунд к текущим КД Q/W/E/R. ]]
require("abilities/billy/billy_shared")

billy_reload = billy_reload or class({})
LinkLuaModifier("modifier_billy_quick_solver", "abilities/billy/billy_reload", LUA_MODIFIER_MOTION_NONE)

local CDR_ABILITIES = { "billy_trickshot", "billy_triple_shot", "billy_skedaddle", "billy_highnoon" }

-- КД падает с уровнем героя линейно: cd_max на 1-м, cd_min на max_hero_level (юзер 08.10.2026).
-- Уровень героя есть и на клиенте — тултип показывает текущее значение.
function billy_reload:GetCooldown(level)
    local cdMax, cdMin = self:GetSpecialValueFor("cd_max"), self:GetSpecialValueFor("cd_min")
    local maxLevel = math.max(2, self:GetSpecialValueFor("max_hero_level"))
    local caster = self:GetCaster()
    local lvl = caster and caster:GetLevel() or 1
    local frac = math.min(1, math.max(0, (lvl - 1) / (maxLevel - 1)))
    return cdMax - (cdMax - cdMin) * frac
end

function billy_reload:OnSpellStart()
    local caster = self:GetCaster()
    Billy_Reload(caster)
    caster:EmitSound("billy_reload")    -- выброс гильз, патроны по каморам, прокрутка барабана
    caster:EmitSound("billy_vo_reload")
    -- local fx = ParticleManager:CreateParticle("particles/billy/billy_reload.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    -- ParticleManager:ReleaseParticleIndex(fx)

    if Billy_HasAttr(caster, 2) then
        caster:AddNewModifier(caster, self, "modifier_billy_quick_solver",
            { duration = self:GetSpecialValueFor("quick_duration") })
        local cdr = self:GetSpecialValueFor("quick_cdr")
        for _, name in ipairs(CDR_ABILITIES) do
            local ab = caster:FindAbilityByName(name)
            -- W с пулей в полёте ещё не на КД: срез запомнит пуля, вычтет на разрыве
            if ab and IsNotNull(ab.bullet) then
                ab.bullet.cdCut = (ab.bullet.cdCut or 0) + cdr
            elseif ab then
                local left = ab:GetCooldownTimeRemaining()
                if left > 0 then
                    ab:EndCooldown()
                    if left - cdr > 0 then ab:StartCooldown(left - cdr) end
                end
            end
        end
    end
end

---------------------------------------------------------------------------------------------------
modifier_billy_quick_solver = modifier_billy_quick_solver or class({})

function modifier_billy_quick_solver:IsHidden()   return false end
function modifier_billy_quick_solver:IsDebuff()   return false end
function modifier_billy_quick_solver:IsPurgable() return true end
function modifier_billy_quick_solver:GetTexture() return "custom/billy/billy_attribute_2" end

function modifier_billy_quick_solver:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE, MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT }
end

function modifier_billy_quick_solver:GetModifierIgnoreMovespeedLimit() return 1 end

function modifier_billy_quick_solver:GetModifierMoveSpeed_Absolute()
    return self:GetAbility():GetSpecialValueFor("quick_ms")
end
