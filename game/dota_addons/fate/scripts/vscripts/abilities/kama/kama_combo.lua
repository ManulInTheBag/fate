kama_combo = class({})

--[[ Kama Combo
     Создано панелью. ScriptFile: abilities/kama/kama_combo
     Кулдаун синхронизируется с копией у MasterUnit2
]]

LinkLuaModifier("modifier_kama_combo_cd", "abilities/kama/kama_combo",
    LUA_MODIFIER_MOTION_NONE)

function kama_combo:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function kama_combo:OnSpellStart()
    if not IsServer() then return end
    local caster = self:GetCaster()
    local cd = self:GetCooldown(1)

    -- ⚠️ Кулдаун комбо дублируется на копию у MasterUnit2: игрок смотрит на
    -- Мастера 2, а не на саму способность.
    caster:AddNewModifier(caster, self, "modifier_kama_combo_cd", {duration = cd})
    if IsNotNull(caster.MasterUnit2) then
        local hMasterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
        if hMasterCombo then
            hMasterCombo:EndCooldown()
            hMasterCombo:StartCooldown(cd)
        end
    end

    --EmitGlobalSound("kama_combo_cast")
    --local fx = ParticleManager:CreateParticle("particles/kama/kama_combo.vpcf",
    --    PATTACH_ABSORIGIN, caster)
    --ParticleManager:SetParticleControl(fx, 0, caster:GetAbsOrigin())
    --ParticleManager:ReleaseParticleIndex(fx)

    local radius = self:GetAOERadius()
    local damage = self:GetSpecialValueFor("damage")
    local stun   = self:GetSpecialValueFor("stun_duration")

    Timers:CreateTimer(self:GetSpecialValueFor("delay"), function()
        if not IsNotNull(caster) then return end
        local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(),
            nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO,
            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
        for _, hEnemy in pairs(targets) do
            if IsNotNull(hEnemy) then
                hEnemy:AddNewModifier(caster, self, "modifier_stunned", {Duration = stun})
                -- комбо бьёт сквозь иммунитет: тип урона PURE + флаг
                DoDamage(caster, hEnemy, damage, DAMAGE_TYPE_PURE,
                    DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self, false)
                --hEnemy:EmitSound("kama_combo_hit")
            end
        end
    end)
end

--=========================================================================--
-- Индикатор кулдауна комбо (его читает панель Мастера).
modifier_kama_combo_cd = class({})

function modifier_kama_combo_cd:IsHidden()      return false end
function modifier_kama_combo_cd:IsDebuff()      return false end
function modifier_kama_combo_cd:IsPurgable()    return false end
function modifier_kama_combo_cd:RemoveOnDeath() return false end
