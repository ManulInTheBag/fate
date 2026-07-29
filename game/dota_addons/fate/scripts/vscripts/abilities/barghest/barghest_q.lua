require("abilities/barghest/barghest_shared")

barghest_q = class({})

--[[ Knight's Cadence (Q)
     Связка из трёх ударов, стадия переключается на каждое нажатие:
       1 — удар аркой мечом перед собой
       2 — небольшой выпад вперёд с ударом мечом об землю
       3 — удар мечом вокруг себя
     Попавшая стадия заряжает СВОЁ продолжение R (Q1R/Q2R/Q3R) — промахом
     продолжение не получить, так задумано в концепте.

     ⚠️ Кулдаун в KV — это пауза МЕЖДУ ударами связки (короткая), полный
     кулдаун ставится руками после третьего. Иначе связка недостижима: с
     кулдауном 4 c и окном 3 c вторая стадия не наступала НИКОГДА, всегда бил
     первый удар — отсюда и «R после Q1/Q2/Q3 одинаковый».

     ⚠️ Стадия хранится в модификаторе, а не в поле способности: так игрок
     видит, какой удар следующий и сколько осталось окна, и состояние само
     сбрасывается по смерти.
]]

LinkLuaModifier("modifier_barghest_q_chain", "abilities/barghest/barghest_q", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_q_lunge", "abilities/barghest/barghest_q", LUA_MODIFIER_MOTION_HORIZONTAL)

function barghest_q:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

--[[ Иконка В СЛОТЕ показывает, какой удар связки пойдёт следующим.
     ⚠️ Считается и на клиенте, поэтому только стаки модификатора — ни util,
     ни серверных методов юнита тут нельзя. ]]
function barghest_q:GetAbilityTextureName()
    return "custom/barghest/barghest_chain_" .. self:GetStage()
end

--[[ Третий удар бьёт ВОКРУГ СЕБЯ — целиться в нём нечем, поэтому он
     NO_TARGET, а первые два остаются направленными. Смена поведения по шагу
     связки — приём из cu_chulain_relentless_spear. ]]
function barghest_q:GetBehavior()
    if self:GetStage() == 3 then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
    end
    return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_OVERSHOOT
         + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
end

--[[ Какой удар пойдёт сейчас: следующий по связке или снова первый.
     ⚠️ Через GetModifierStackCount, а НЕ через FindModifierByName: последнего в
     клиентской VM не существует, а иконку слота клиент считает сам. Ноль стаков
     = модификатора нет (при живой связке стак всегда ≥ 1), значит первый удар. ]]
function barghest_q:GetStage()
    local hCaster = self:GetCaster()
    if hCaster == nil or type(hCaster.GetModifierStackCount) ~= "function" then
        return 1
    end
    local nDone = hCaster:GetModifierStackCount("modifier_barghest_q_chain", hCaster) or 0
    return math.max(1, math.min(3, nDone + 1))
end

--[[ У каждого удара связки СВОЯ activity, иначе под три разных движения
     нельзя подобрать три разных клипа: 1 — дуга, 2 — выпад, 3 — вертушка.
     Это ЗАМАХ, он играет на кастпоинте. ]]
BARGHEST_Q_ACT = {
    ACT_DOTA_CAST_ABILITY_1,
    ACT_DOTA_CAST_ABILITY_2,
    ACT_DOTA_CAST_ABILITY_3,
}

--[[ Удар второй стадии — ОТДЕЛЬНЫЙ клип, играет на старте выпада. Тот же,
     которым бьёт об землю стойка: клип точно есть на модели. ]]
BARGHEST_Q_ACT_LUNGE_HIT = ACT_DOTA_CAST_ABILITY_4

--[[ ⚠️ Замах отыгрывает ДВИЖОК по этому колбэку, руками его дублировать не
     надо. Именно в этом и была двойная анимация: здесь возвращался клип, и он
     же вторым разом запускался StartAnimation'ом из OnAbilityPhaseStart.
     Так же сделано у altera_whip и atalanta_calydonian_hunt — один
     GetCastAnimation и ничего больше. ]]
function barghest_q:GetCastAnimation()
    return BARGHEST_Q_ACT[self:GetStage()] or ACT_DOTA_CAST_ABILITY_1
end

function barghest_q:OnSpellStart()
    if not IsServer() then return end
    local hCaster = self:GetCaster()
    --[[ ⚠️ EndAnimation тут тоже НЕ зовём. Он ставит _animationEnd = сейчас, а
         StartAnimation (animations.lua:482) при свежем _animationEnd
         откладывает следующий клип на 0.066 с. То есть каждый EndAnimation
         прямо перед StartAnimation — это гарантированный провал на два кадра,
         ровно то самое «анимация не успевает проиграться». ]]

    local iStage = self:GetStage()

    --[[ ⚠️ Курсор и доворот — ТОЛЬКО у первых двух стадий. Третья объявлена
         NO_TARGET (см. GetBehavior), курсора у неё нет: GetCursorPosition
         вернёт позицию самой Баргест, vDir выродится, а FaceTowards в
         собственную точку дёргает разворот на ровном месте. Бьёт она вокруг
         себя — поворачивать её не нужно и нечем. ]]
    if iStage == 3 then
        if self:DoSpin() then
            Barghest_ArmContinuation(hCaster, BARGHEST_CONT_Q3)
        end
        self:AdvanceChain(iStage)
        return
    end

    local vPoint = self:GetCursorPosition()
    local vDir = vPoint - hCaster:GetAbsOrigin()
    vDir.z = 0
    if vDir:Length2D() < 1 then
        vDir = hCaster:GetForwardVector()
    end
    vDir = vDir:Normalized()
    hCaster:FaceTowards(vPoint)

    if iStage == 1 then
        if self:DoArc(vDir) then
            Barghest_ArmContinuation(hCaster, BARGHEST_CONT_Q1)
        end
    else
        self:DoLunge(vDir, vPoint)  -- попадание считает сам выпад, в конце движения
    end

    self:AdvanceChain(iStage)
end

--[[ Продвинуть связку и выставить нужный кулдаун. ]]
function barghest_q:AdvanceChain(iStage)
    local hCaster = self:GetCaster()
    if iStage >= 3 then
        -- Связка отыграна: сбрасываем и уходим в полный кулдаун.
        hCaster:RemoveModifierByName("modifier_barghest_q_chain")
        self:EndCooldown()
        self:StartCooldown(self:GetSpecialValueFor("full_cooldown"))
        return
    end
    local hChain = hCaster:AddNewModifier(hCaster, self, "modifier_barghest_q_chain",
        {duration = self:GetSpecialValueFor("chain_window")})
    if Barghest_Alive(hChain) then
        hChain:SetStackCount(iStage)
    end
end

function barghest_q:DamageUnits(tUnits)
    local hCaster = self:GetCaster()
    local nDamage = self:GetSpecialValueFor("damage")
    local bHit = false
    for _, hUnit in pairs(tUnits) do
        if IsNotNull(hUnit) and not IsSpellBlocked(hUnit, hCaster) then
            DoDamage(hCaster, hUnit, nDamage, self:GetAbilityDamageType(), 0, self, false)
            hUnit:EmitSound(BARGHEST_SND.HIT)
            bHit = true
        end
    end
    return bHit
end

-- Стадия 1: широкая дуга перед собой
function barghest_q:DoArc(vDir)
    local hCaster = self:GetCaster()
    local nRadius = self:GetSpecialValueFor("radius")
    local nAngle = self:GetSpecialValueFor("arc_angle")
    hCaster:EmitSound(BARGHEST_SND.Q_ARC)

    Barghest_FxArc(BARGHEST_FX.ARC, hCaster, nRadius, nAngle)

    return self:DamageUnits(Barghest_FindInArc(hCaster, self, hCaster:GetAbsOrigin(),
        vDir, nRadius, nAngle))
end

--[[ Стадия 2: выпад вперёд + удар об землю в точке приземления.
     Точка приземления: КЛИК, если до него ближе lunge_distance, иначе
     lunge_distance по направлению клика. Дальность каста при этом не
     ограничена — курсор задаёт только направление и точку. ]]
function barghest_q:DoLunge(vDir, vPoint)
    local hCaster = self:GetCaster()
    local nMax = self:GetSpecialValueFor("lunge_distance")
    local nWant = (vPoint - hCaster:GetAbsOrigin()):Length2D()
    local nDist = math.max(80, math.min(nMax, nWant))

    --[[ Удар играем СРАЗУ, на старте выпада: он и есть само движение вперёд, а
         не то, что происходит после приземления. ⚠️ Клип обязан отличаться от
         замаха с кастпоинта — раньше тут стоял тот же ACT_DOTA_CAST_ABILITY_2,
         и он проигрывался дважды подряд. ]]
    hCaster:EmitSound(BARGHEST_SND.Q_LUNGE)
    StartAnimation(hCaster, {duration = nDist / self:GetSpecialValueFor("lunge_speed") + 0.1,
        activity = BARGHEST_Q_ACT_LUNGE_HIT, rate = 1.0})
    hCaster:AddNewModifier(hCaster, self, "modifier_barghest_q_lunge", {
        duration = 0.5,
        x = vDir.x, y = vDir.y,
        distance = nDist,
    })
end

-- Стадия 3: удар вокруг себя
function barghest_q:DoSpin()
    local hCaster = self:GetCaster()
    local nRadius = self:GetSpecialValueFor("spin_radius")
    hCaster:EmitSound(BARGHEST_SND.Q_SPIN)

    --[[ ⚠️ Анимации здесь НЕТ. Вертушка — это ACT_DOTA_CAST_ABILITY_3, и его
         уже играет движок по GetCastAnimation. Повторный запуск того же клипа
         и был «чем-то не так с анимацией» на третьем ударе: клип сбрасывался
         на 0.15 с и начинался заново. Первая стадия сделана так же (в DoArc
         анимации нет) и вопросов не вызывала. ]]
    -- Дуга на все 360° плюс кольцо по земле: третий удар обязан читаться как
    -- «вокруг себя», а не как ещё одна дуга вперёд.
    Barghest_FxArc(BARGHEST_FX.ARC, hCaster, nRadius, 360)
    Barghest_FxRing(BARGHEST_FX.RING, hCaster:GetAbsOrigin(), nRadius)

    local tUnits = FindUnitsInRadius(hCaster:GetTeamNumber(), hCaster:GetAbsOrigin(), nil,
        nRadius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(),
        self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
    return self:DamageUnits(tUnits)
end

---------------------------------------------------------------------------------------------------
-- Состояние связки: стаки = сколько ударов уже сделано
---------------------------------------------------------------------------------------------------
modifier_barghest_q_chain = class({})

function modifier_barghest_q_chain:IsHidden()      return false end
function modifier_barghest_q_chain:IsDebuff()      return false end
function modifier_barghest_q_chain:IsPurgable()    return false end
function modifier_barghest_q_chain:RemoveOnDeath() return true end

--[[ Иконка показывает, СКОЛЬКО ударов связки уже сделано, то есть какой пойдёт
     следующим. Тестовая: цифра на всю плитку. ]]
function modifier_barghest_q_chain:GetTexture()
    local n = self:GetStackCount()
    if n < 1 then n = 1 end
    if n > 3 then n = 3 end
    return "custom/barghest/barghest_chain_" .. n
end

---------------------------------------------------------------------------------------------------
-- Выпад второй стадии. Мини-деш, но всё равно через motion controller — правило
-- аддона: своим перемещением героя занимается отдельный модификатор движения.
---------------------------------------------------------------------------------------------------
modifier_barghest_q_lunge = class({})

function modifier_barghest_q_lunge:IsHidden()      return true end
function modifier_barghest_q_lunge:IsDebuff()      return false end
function modifier_barghest_q_lunge:IsPurgable()    return false end
function modifier_barghest_q_lunge:RemoveOnDeath() return true end

function modifier_barghest_q_lunge:CheckState()
    return {[MODIFIER_STATE_ROOTED] = true}
end

function modifier_barghest_q_lunge:OnCreated(tTable)
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
    if not IsServer() then return end

    self.vDir      = Vector(tTable.x, tTable.y, 0):Normalized()
    -- Дальность приходит из способности: она зависит от того, куда кликнули.
    self.nDistance = tTable.distance
                     or self.hAbility:GetSpecialValueFor("lunge_distance")
    self.vStart    = self.hParent:GetAbsOrigin()
    -- Скорость ПОСТОЯННАЯ, а не «дистанция за фиксированное время»: иначе
    -- короткий выпад полз бы, а длинный телепортировал.
    self.nSpeed      = self.hAbility:GetSpecialValueFor("lunge_speed")
    self.nStopRadius = self.hAbility:GetSpecialValueFor("lunge_stop_radius")

    self.hParent:SetForwardVector(self.vDir)
    if not self:ApplyHorizontalMotionController() then
        self:Destroy()
    end
end

function modifier_barghest_q_lunge:OnRefresh(tTable)
    self:OnCreated(tTable)
end

function modifier_barghest_q_lunge:OnHorizontalMotionInterrupted()
    if not IsServer() then return end
    self.hParent:RemoveHorizontalMotionController(self)
    self:Destroy()
end

function modifier_barghest_q_lunge:UpdateHorizontalMotion(hUnit, fTime)
    if not IsServer() then return end
    local vNext = hUnit:GetAbsOrigin() + self.vDir * self.nSpeed * fTime
    if not GridNav:IsTraversable(vNext) or GridNav:IsBlocked(vNext)
       or (vNext - self.vStart):Length2D() > self.nDistance then
        self:Destroy()
        return
    end
    hUnit:SetAbsOrigin(vNext)

    --[[ ⚠️ Выпад ТОРМОЗИТ о первого врага. Без этого связка рвалась сама об
         себя: первый удар бьёт в радиусе 275, а выпад уносит на 450 — тот, кого
         только что задели аркой, оказывался ЗА спиной и вне радиуса удара об
         землю. Теперь до цели долетаем и бьём по ней, а не мимо.
         Первые 120 единиц не тормозим: иначе при вплотную стоящем враге выпада
         не было бы вовсе, а он всё-таки рывок. Радиус остановки (200) меньше
         радиуса удара (275), так что застрять «слишком далеко» нельзя. ]]
    if (vNext - self.vStart):Length2D() < 120 then return end

    local tUnits = FindUnitsInRadius(hUnit:GetTeamNumber(), vNext, nil, self.nStopRadius,
        self.hAbility:GetAbilityTargetTeam(), self.hAbility:GetAbilityTargetType(),
        self.hAbility:GetAbilityTargetFlags(), FIND_CLOSEST, false)
    for _, hEnemy in pairs(tUnits) do
        if IsNotNull(hEnemy) and hEnemy:IsAlive() then
            self:Destroy()
            return
        end
    end
end

--[[ Удар об землю — в конце выпада, чем бы он ни кончился (дошёл, упёрся в
     стену, прервали). ⚠️ Гард обязателен: OnDestroy отрабатывает и при смерти
     героя. ]]
function modifier_barghest_q_lunge:OnDestroy()
    if not IsServer() then return end
    if not Barghest_Alive(self.hParent) or not Barghest_Alive(self.hAbility) then return end

    self.hParent:RemoveHorizontalMotionController(self)
    FindClearSpaceForUnit(self.hParent, self.hParent:GetAbsOrigin(), true)

    if not self.hParent:IsAlive() then return end

    -- ⚠️ Анимации здесь НЕТ: удар отыгрывается на СТАРТЕ выпада, в DoLunge.
    -- Сюда попадаем уже на приземлении, и второй клип тут читался бы как
    -- повтор того же движения.
    local hParent  = self.hParent
    local hAbility = self.hAbility
    local vDir     = self.vDir
    local nRadius  = hAbility:GetSpecialValueFor("radius")

    --[[ Урон приходит через lunge_slam_delay, а не в тот же кадр, что и
         остановка. Выпад в упор длится меньше 0.1 с, и без задержки меч втыкался
         в землю раньше, чем клип успевал до этого дойти. ]]
    Timers:CreateTimer(hAbility:GetSpecialValueFor("lunge_slam_delay"), function()
        -- ⚠️ За эти доли секунды её могли убить, а способность — отобрать.
        if not Barghest_Alive(hParent) or not hParent:IsAlive() then return end
        if not Barghest_Alive(hAbility) then return end

        -- Бьёт туда, где стоит НА МОМЕНТ удара, а не где затормозила.
        local vPos = hParent:GetAbsOrigin()
        -- Прямой рез сверху вниз + пыль: выпад должен читаться как «воткнула меч
        -- в землю», а не как ещё один взмах.
        hParent:EmitSound(BARGHEST_SND.SLAM)
        Barghest_FxCut(hParent, vPos + Vector(0, 0, 220), vPos + vDir * 120)
        Barghest_FxRing(BARGHEST_FX.RING, vPos, nRadius)

        local tUnits = FindUnitsInRadius(hParent:GetTeamNumber(), vPos, nil, nRadius,
            hAbility:GetAbilityTargetTeam(), hAbility:GetAbilityTargetType(),
            hAbility:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
        if hAbility:DamageUnits(tUnits) then
            Barghest_ArmContinuation(hParent, BARGHEST_CONT_Q2)
        end
    end)
end
