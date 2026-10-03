require("abilities/kama/kama_shared")

kama_blooming_ground = kama_blooming_ground or class({})

--[[ R — Blooming Ground. Область в точке: враги в ней замедлены, а любая
     стрела Камы по цели в области бьёт сильнее — отнимает долю текущего
     здоровья и добавляет замедление, пока цель не выйдет.
     Область — thinker с аурой; сам эффект стрелы живёт в модификаторе ауры
     (OnKamaArrow), его зовёт Kama_ArrowHit из kama_shared.
]]

LinkLuaModifier("modifier_kama_blooming_ground_thinker", "abilities/kama/kama_blooming_ground",
    LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kama_blooming_ground", "abilities/kama/kama_blooming_ground",
    LUA_MODIFIER_MOTION_NONE)

-- Временный эффект области: кольцо по радиусу (CP1 — цвет, CP2 — радиус и время).
local FX_ZONE = "particles/zlodemon/zlodemon_basic_circle.vpcf"

function kama_blooming_ground:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function kama_blooming_ground:CastFilterResultLocation(vLocation)
    if IsServer() and not IsInSameRealm(self:GetCaster():GetAbsOrigin(), vLocation) then
        return UF_FAIL_CUSTOM
    end
    return UF_SUCCESS
end

function kama_blooming_ground:GetCustomCastErrorLocation(vLocation)
    return "#Must be in same realm"
end

function kama_blooming_ground:OnSpellStart()
    local caster = self:GetCaster()
    local hZone = CreateModifierThinker(caster, self, "modifier_kama_blooming_ground_thinker",
        {duration = self:GetSpecialValueFor("duration")}, self:GetCursorPosition(),
        caster:GetTeamNumber(), false)

    self.tZones = self.tZones or {}
    table.insert(self.tZones, hZone)
end

-- Досрочно закрыть свои области (так делает комбо).
function kama_blooming_ground:EndZones()
    for _, hZone in ipairs(self.tZones or {}) do
        if Kama_Alive(hZone) then
            hZone:RemoveModifierByName("modifier_kama_blooming_ground_thinker")
        end
    end
    self.tZones = {}
end

--=========================================================================--
-- Сама область: аура на врагов и кольцо на земле.
modifier_kama_blooming_ground_thinker = class({})

function modifier_kama_blooming_ground_thinker:OnCreated()
    if not IsServer() then return end
    self.nRadius = self:GetAbility():GetSpecialValueFor("radius")

    self.nFx = ParticleManager:CreateParticle(FX_ZONE, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(self.nFx, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(self.nFx, 1, Vector(1, 0.4, 0.7))
    ParticleManager:SetParticleControl(self.nFx, 2, Vector(self.nRadius, self:GetDuration(), 0))
end

function modifier_kama_blooming_ground_thinker:OnDestroy()
    if not IsServer() then return end
    if self.nFx then
        ParticleManager:DestroyParticle(self.nFx, false)
        ParticleManager:ReleaseParticleIndex(self.nFx)
        self.nFx = nil
    end

    -- thinker обычно убирает сам движок; это страховка, чтобы юнит не остался
    local hParent = self:GetParent()
    Timers:CreateTimer(0, function()
        if Kama_Alive(hParent) then hParent:RemoveSelf() end
    end)
end

function modifier_kama_blooming_ground_thinker:IsAura()            return true end
function modifier_kama_blooming_ground_thinker:GetModifierAura()   return "modifier_kama_blooming_ground" end
function modifier_kama_blooming_ground_thinker:GetAuraRadius()     return self.nRadius or 0 end
-- вышел из области — эффект снимается почти сразу, вместе с набранным замедлением
function modifier_kama_blooming_ground_thinker:GetAuraDuration()   return 0.1 end
function modifier_kama_blooming_ground_thinker:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_kama_blooming_ground_thinker:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_kama_blooming_ground_thinker:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

--=========================================================================--
-- На враге в области. Стаки = сколько стрел в него попало, пока он внутри:
-- каждая добавляет замедление.
modifier_kama_blooming_ground = class({})

function modifier_kama_blooming_ground:IsHidden()   return false end
function modifier_kama_blooming_ground:IsDebuff()   return true end
function modifier_kama_blooming_ground:IsPurgable() return false end

function modifier_kama_blooming_ground:OnCreated()
    if not IsServer() then return end
    -- иммунные к замедлению всё равно получают урон от стрел, но не тормозятся
    self.bSlowImmune = IsImmuneToSlow(self:GetParent())
end

function modifier_kama_blooming_ground:DeclareFunctions()
    return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_kama_blooming_ground:GetModifierMoveSpeedBonus_Percentage()
    if self.bSlowImmune then return 0 end
    local hAbility = self:GetAbility()
    local nExtra = math.min(self:GetStackCount() * hAbility:GetSpecialValueFor("arrow_slow"),
        hAbility:GetSpecialValueFor("arrow_slow_max"))
    return -(hAbility:GetSpecialValueFor("slow") + nExtra)
end

--[[ В цель попала стрела Камы (зовёт Kama_ArrowHit).
     tArrow.mana — сколько маны вернуть Каме за это попадание (стрелы Q). ]]
function modifier_kama_blooming_ground:OnKamaArrow(hCaster, tArrow)
    if not IsServer() then return end
    local hAbility = self:GetAbility()
    local hParent = self:GetParent()
    -- область чужой Камы на нашу стрелу не откликается
    if not Kama_Alive(hAbility) or hAbility:GetCaster() ~= hCaster then return end

    local nMaxStacks = math.ceil(hAbility:GetSpecialValueFor("arrow_slow_max")
        / hAbility:GetSpecialValueFor("arrow_slow"))
    if self:GetStackCount() < nMaxStacks then self:IncrementStackCount() end

    if tArrow.mana then hCaster:GiveMana(tArrow.mana) end

    if hParent:IsAlive() then
        local nDamage = hParent:GetHealth() * hAbility:GetSpecialValueFor("arrow_hp_damage") / 100
        DoDamage(hCaster, hParent, nDamage, DAMAGE_TYPE_PURE, 0, hAbility, false)
    end
end
