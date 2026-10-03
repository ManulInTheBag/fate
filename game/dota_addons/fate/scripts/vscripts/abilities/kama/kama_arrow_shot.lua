require("abilities/kama/kama_shared")

kama_arrow_shot = kama_arrow_shot or class({})

--[[ Q — Arrow Shot. Выстрел стрелой по направлению.
     Floral: стрела останавливается на первой цели и даёт ей Charm.
     Samsara: стрела пробивает насквозь.
     Попадание снимает кулдаун с Q, W и E — но каждая стрела только один раз,
     сколько бы целей она ни задела.

     Стрелу пускает FireArrow: им же стреляют клоны W, с долей fFactor.
]]

-- Временные эффекты до своих партиклей: стрела Мираны и выстрел Виндрейнджер.
local FX_FLORAL  = "particles/units/heroes/hero_mirana/mirana_spell_arrow.vpcf"
local FX_SAMSARA = "particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf"

-- Способности, с которых попадание Q снимает кулдаун. W сюда не входит: у неё
-- заряды, с ними ReduceCooldowns работает отдельно.
local CDR_ABILITIES = {"kama_arrow_shot", "kama_petal_volley"}

--[[ Анимация выстрела — секвенция q_shot модели (те же кадры, что у обычной
     атаки, но своя активность, чтобы движок не подгонял её под скорость атаки).
     Тетива срывается на 5-6 кадре (~0.17 с), то есть как раз к концу кастпоинта.
     Кама и клоны W играют её ОДНИМ И ТЕМ ЖЕ вызовом в один и тот же момент —
     только так замах у них совпадает до кадра. Поэтому AbilityCastAnimation в
     KV у Q нет: движок играл бы выстрел Камы со своими настройками, чуть иначе,
     чем у клонов.
     StartAnimation тут не годится: он идёт через модификатор на клиенте,
     стоящий юнит подхватывает его с опозданием, а при частых отменах каста он
     запускает анимацию уже после отмены. ]]
local SHOT_FADE_IN = 0.1
-- секвенция длится 1 с, кастпоинт из неё уже прошёл
local SHOT_AFTER_CAST = 0.8

function kama_arrow_shot:OnAbilityPhaseStart()
    local caster = self:GetCaster()
    local vPoint = self:GetCursorPosition()
    caster:FadeGesture(KAMA_RECOVERY_GESTURE)
    Kama_Gesture(caster, KAMA_SHOT_GESTURE, SHOT_FADE_IN)
    for _, hClone in ipairs(self:GetClones()) do
        hClone:SetForwardVector(self:CloneDirection(hClone, vPoint, caster:GetForwardVector()))
        Kama_Gesture(hClone, KAMA_SHOT_GESTURE, SHOT_FADE_IN)
    end
    return true
end

-- Каст отменили: замах бросают и Кама, и клоны.
function kama_arrow_shot:OnAbilityPhaseInterrupted()
    self:GetCaster():FadeGesture(KAMA_SHOT_GESTURE)
    for _, hClone in ipairs(self:GetClones()) do
        hClone:FadeGesture(KAMA_SHOT_GESTURE)
    end
end

-- Живые клоны W (пусто, если W ещё нет).
function kama_arrow_shot:GetClones()
    local hEmbrace = self:GetCaster():FindAbilityByName("kama_embrace_of_dreams")
    if not Kama_Alive(hEmbrace) or hEmbrace:GetLevel() < 1 then return {} end
    return hEmbrace:GetClones()
end

-- Куда стреляет клон: в точку, куда целилась Кама. Точка прямо под клоном —
-- тогда в запасном направлении vFallback.
function kama_arrow_shot:CloneDirection(hClone, vPoint, vFallback)
    local vDirection = vPoint - hClone:GetAbsOrigin()
    vDirection.z = 0
    if vDirection:Length2D() < 1 then return vFallback end
    return vDirection:Normalized()
end

-- Каждый живой клон W делает Q дороже. Число клонов лежит в стаках
-- модификатора на Каме — так его видит и клиент.
function kama_arrow_shot:GetManaCost(iLevel)
    local caster = self:GetCaster()
    local nClones = caster:GetModifierStackCount("modifier_kama_dream_clones", caster)
    return self.BaseClass.GetManaCost(self, iLevel)
        + nClones * self:GetSpecialValueFor("mana_per_clone")
end

function kama_arrow_shot:OnSpellStart()
    local caster = self:GetCaster()
    local vPoint = self:GetCursorPosition()
    local vDirection = vPoint - caster:GetAbsOrigin()
    vDirection.z = 0
    if vDirection:Length2D() < 1 then vDirection = caster:GetForwardVector() end
    vDirection = vDirection:Normalized()

    -- стрела вылетает из руки с луком; у модели без такого крепления — от груди
    local nAttach = caster:ScriptLookupAttachment("attach_attack1")
    local vOrigin = nAttach > 0 and caster:GetAttachmentOrigin(nAttach)
        or caster:GetAbsOrigin() + Vector(0, 0, 100)

    caster:EmitSound("Ability.Powershot.Alt")
    self:FireArrow(vOrigin, vDirection, 1)
    self:FireFromClones(vPoint, vDirection)

    -- возврат лука доигрывается стоя; пошла, атакует или получила приказ —
    -- жест гаснет
    Kama_StopWhenBusy(caster, SHOT_AFTER_CAST, function()
        caster:FadeGesture(KAMA_SHOT_GESTURE)
    end)
end

--[[ Клоны W повторяют выстрел: каждый стреляет со своего места в ту же ТОЧКУ,
     куда целилась Кама, с долей clone_factor. ]]
function kama_arrow_shot:FireFromClones(vPoint, vFallback)
    local tClones = self:GetClones()
    if #tClones < 1 then return end
    local hEmbrace = self:GetCaster():FindAbilityByName("kama_embrace_of_dreams")
    local fFactor = hEmbrace:GetSpecialValueFor("clone_factor") / 100

    for _, hClone in ipairs(tClones) do
        local vDirection = self:CloneDirection(hClone, vPoint, vFallback)
        hClone:SetForwardVector(vDirection)
        self:FireArrow(hClone:GetAbsOrigin() + Vector(0, 0, 100), vDirection, fFactor)
    end
end

--[[ Пустить одну стрелу. fFactor — доля урона, Charm и снятия кулдауна
     (1 у самой Камы, меньше у клонов). Вид стрелы берётся на момент выстрела. ]]
function kama_arrow_shot:FireArrow(vOrigin, vDirection, fFactor)
    local caster = self:GetCaster()
    local bSamsara = Kama_IsSamsara(caster)
    local nWidth = self:GetSpecialValueFor("width")

    -- помним, какие стрелы ещё могут снять кулдаун: ExtraData между попаданиями
    -- одной стрелы не меняется, счёт приходится вести тут
    self.nArrowId = (self.nArrowId or 0) + 1
    self.tArrowCanReduce = self.tArrowCanReduce or {}
    self.tArrowCanReduce[self.nArrowId] = true

    ProjectileManager:CreateLinearProjectile({
        Ability          = self,
        Source           = caster,
        EffectName       = bSamsara and FX_SAMSARA or FX_FLORAL,
        vSpawnOrigin     = vOrigin,
        vVelocity        = vDirection * self:GetSpecialValueFor("speed"),
        fDistance        = self:GetSpecialValueFor("range"),
        fStartRadius     = nWidth,
        fEndRadius       = nWidth,
        iUnitTargetTeam  = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType  = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        ExtraData        = {
            arrow   = self.nArrowId,
            factor  = fFactor,
            samsara = bSamsara and 1 or 0,
        },
    })
end

function kama_arrow_shot:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
    self.tArrowCanReduce = self.tArrowCanReduce or {}

    -- стрела долетела до конца дистанции
    if not Kama_Alive(hTarget) then
        self.tArrowCanReduce[tData.arrow] = nil
        return true
    end

    local caster = self:GetCaster()
    if not Kama_Alive(caster) then return true end
    local bSamsara = tData.samsara == 1

    if not IsSpellBlocked(hTarget, caster) then
        if self.tArrowCanReduce[tData.arrow] then
            self.tArrowCanReduce[tData.arrow] = nil
            self:ReduceCooldowns(tData.factor)
        end

        DoDamage(caster, hTarget, self:GetSpecialValueFor("damage") * tData.factor,
            self:GetAbilityDamageType(), 0, self, false)

        -- мана возвращается, только если цель стоит в области R
        local tArrow = {mana = self:GetSpecialValueFor("bloom_mana") * tData.factor}
        if not bSamsara then
            tArrow.charm = self:GetSpecialValueFor("charm") * tData.factor
        end
        Kama_ArrowHit(caster, hTarget, tArrow)
    end

    -- Samsara летит дальше, Floral на первой цели кончается
    if bSamsara then return false end
    self.tArrowCanReduce[tData.arrow] = nil
    return true
end

--[[ Снять кулдаун с Q, W и E за попадание стрелы. Это вычитание из остатка, а
     не установка кулдауна: сколько останется, зависит от того, сколько стрел
     попало. Атрибут 4 удваивает снятие. ]]
function kama_arrow_shot:ReduceCooldowns(fFactor)
    local caster = self:GetCaster()
    local sKey = caster.KamaAttr4Acquired and "cd_reduction_attr" or "cd_reduction"
    local fSeconds = self:GetSpecialValueFor(sKey) * fFactor

    for _, sName in ipairs(CDR_ABILITIES) do
        local hAbility = caster:FindAbilityByName(sName)
        if Kama_Alive(hAbility) and not hAbility:IsCooldownReady() then
            local fLeft = hAbility:GetCooldownTimeRemaining() - fSeconds
            hAbility:EndCooldown()
            if fLeft > 0 then hAbility:StartCooldown(fLeft) end
        end
    end

    -- у W вместо кулдауна заряды: сокращается время до следующего заряда
    local hCharges = caster:FindModifierByName("modifier_kama_embrace_charges")
    if hCharges then hCharges:Reduce(fSeconds) end
end
