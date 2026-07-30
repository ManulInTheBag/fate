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
LinkLuaModifier("modifier_barghest_q_slam_anim", "abilities/barghest/barghest_q", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_q_spin_anim", "abilities/barghest/barghest_q", LUA_MODIFIER_MOTION_NONE)

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

--[[ Удар второй стадии — ОТДЕЛЬНЫЙ клип, играет на старте выпада.
     В модели (content/.../barghest.vmdl) это `vertical_slash2`, кадры 181-207 на
     50 fps ≈ 0.54 c, ровно продолжение замаха `vertical_slash1` (ACT_2, кадры
     175-180) — то есть сам взмах сверху вниз. ]]
BARGHEST_Q_ACT_LUNGE_HIT = ACT_DOTA_CAST_ABILITY_4

--[[ Скорость проигрывания клипа для оверрайда анимации. Читается и на КЛИЕНТЕ,
     поэтому только GetSpecialValueFor: серверных методов юнита тут нельзя.
     Способность могли отобрать (revoke) — тогда просто штатная скорость. ]]
function Barghest_QAnimRate(hAbility, sKey)
    if hAbility == nil or type(hAbility.GetSpecialValueFor) ~= "function" then
        return 1.0
    end
    local nRate = hAbility:GetSpecialValueFor(sKey)
    if nRate == nil or nRate <= 0 then return 1.0 end
    return nRate
end

--[[ ⚠️ Замах отыгрывает ДВИЖОК по этому колбэку, руками его дублировать не
     надо. Именно в этом и была двойная анимация: здесь возвращался клип, и он
     же вторым разом запускался StartAnimation'ом из OnAbilityPhaseStart.
     Так же сделано у altera_whip и atalanta_calydonian_hunt — один
     GetCastAnimation и ничего больше. ]]
function barghest_q:GetCastAnimation()
    return BARGHEST_Q_ACT[self:GetStage()] or ACT_DOTA_CAST_ABILITY_1
end

--[[ ⚠️ У третьего удара СВОЙ каст-пойнт, и он длиннее общего.
     Вертушка — это каст-анимация, а у Q стоит IGNORE_BACKSWING: всё, что не
     успело проиграться за каст-пойнт, движок обрубает сразу после OnSpellStart.
     С общими 0.15 c от прокрута было видно два кадра — отсюда «слишком быстро
     проигрывается». Стадии 1 и 2 остаются на KV-значении: у первой удар и есть
     короткий взмах, у второй продолжение отыгрывает выпад.
     Приём тот же, что в cu_chulain_relentless_spear — каст-пойнт по шагу связки.
     ⚠️ Раз метод переопределён, он решает ВСЁ: `cast_point` для первых двух
     стадий берётся из AbilityValues, а AbilityCastPoint в KV остаётся только
     справочным — держать их равными. ]]
function barghest_q:GetCastPoint()
    if self:GetStage() == 3 then
        return self:GetSpecialValueFor("spin_cast_point")
    end
    return self:GetSpecialValueFor("cast_point")
end

--[[ Прокрут дополнительно ЗАМЕДЛЕН: одного длинного каст-пойнта мало — клип
     всё равно доигрывает быстрее, чем читается глазом. ]]
function barghest_q:GetPlaybackRateOverride()
    if self:GetStage() == 3 then
        return self:GetSpecialValueFor("spin_anim_rate")
    end
    -- Остальным стадиям override не нужен: ничего не возвращаем (как в nanaya_d).
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

    --[[ ⚠️ StartAnimation тут БОЛЬШЕ НЕТ, и возвращать его нельзя.
         Жест (modifier_animation из animations.lua) конкурирует с каст-анимацией
         движка: у Q стоит IGNORE_BACKSWING, движок обрывает каст-клип ровно на
         кастпоинте и сам же переводит модель в IDLE — жест, поставленный в тот же
         кадр, до экрана не доезжал. Именно поэтому «удар не проигрывался», хотя
         клип ACT_DOTA_CAST_ABILITY_4 в модели есть.
         Правило аддона (см. cu_alter_charge): деш→удар гнать МОДИФИКАТОРАМИ через
         MODIFIER_PROPERTY_OVERRIDE_ANIMATION — оверрайд жёстче каста и меняется
         без задержки в 0.066 c, которую даёт churn StartAnimation/EndAnimation.
         Клип выпада отдаёт modifier_barghest_q_lunge, доигровку удара об землю —
         modifier_barghest_q_slam_anim. Оба на ТОМ ЖЕ ACT_4, так что смена
         модификатора на приземлении клип не перезапускает. ]]
    hCaster:EmitSound(BARGHEST_SND.Q_LUNGE)
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

    --[[ Пост-анимация: держим героя на месте, пока вертушка доигрывает. У Q
         стоит IGNORE_BACKSWING, так что своего замирания после каста у неё нет
         — без этого можно было убежать с первого же кадра клипа. ]]
    hCaster:AddNewModifier(hCaster, self, "modifier_barghest_q_spin_anim",
        {duration = self:GetSpecialValueFor("spin_post_delay")})

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
-- Пост-анимация удара: короткое замирание, чтобы клип доиграл, плюс сам клип
-- через MODIFIER_PROPERTY_OVERRIDE_ANIMATION.
-- ⚠️ Активность у оверрайда ЗАХАРДКОЖЕНА в классе, а не приходит параметром:
-- анимация считается на клиенте, а туда таблица AddNewModifier не доезжает (ровно
-- поэтому animations.lua пакует activity в стаки). Отсюда два почти одинаковых
-- класса вместо одного с параметром — так же сделан modifier_cu_alter_charge_hit.
-- Набор состояний — как у modifier_altera_teardrop_anim, кроме SILENCED и MUTED:
-- ⚠️ Их тут быть НЕ должно. Смысл третьего удара — сразу уйти в R (он заряжает
-- BARGHEST_CONT_Q3), и глушить себя же на выходе из связки нельзя.
-- COMMAND_RESTRICTED и так не даст отдать приказ эти доли секунды.
---------------------------------------------------------------------------------------------------

--[[ Доигровка удара об землю после выпада. ACT_4 — тот же клип, что гонит сам
     выпад, поэтому смена модификатора на приземлении не перезапускает взмах. ]]
modifier_barghest_q_slam_anim = class({})

function modifier_barghest_q_slam_anim:IsHidden()      return true end
function modifier_barghest_q_slam_anim:IsDebuff()      return false end
function modifier_barghest_q_slam_anim:IsPurgable()    return false end
function modifier_barghest_q_slam_anim:RemoveOnDeath() return true end

function modifier_barghest_q_slam_anim:CheckState()
    return {
        [MODIFIER_STATE_ROOTED]             = true,
        [MODIFIER_STATE_DISARMED]           = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    }
end

function modifier_barghest_q_slam_anim:DeclareFunctions()
    return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE}
end

function modifier_barghest_q_slam_anim:GetOverrideAnimation()
    return BARGHEST_Q_ACT_LUNGE_HIT
end

function modifier_barghest_q_slam_anim:GetOverrideAnimationRate()
    return Barghest_QAnimRate(self:GetAbility(), "lunge_anim_rate")
end

--[[ Доигровка вертушки (стадия 3). ACT_3 — та же активность, которую движок уже
     начал играть как каст-анимацию, так что оверрайд её продолжает, а не рвёт. ]]
modifier_barghest_q_spin_anim = class({})

function modifier_barghest_q_spin_anim:IsHidden()      return true end
function modifier_barghest_q_spin_anim:IsDebuff()      return false end
function modifier_barghest_q_spin_anim:IsPurgable()    return false end
function modifier_barghest_q_spin_anim:RemoveOnDeath() return true end

function modifier_barghest_q_spin_anim:CheckState()
    return {
        [MODIFIER_STATE_ROOTED]             = true,
        [MODIFIER_STATE_DISARMED]           = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    }
end

function modifier_barghest_q_spin_anim:DeclareFunctions()
    return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE}
end

function modifier_barghest_q_spin_anim:GetOverrideAnimation()
    return ACT_DOTA_CAST_ABILITY_3
end

function modifier_barghest_q_spin_anim:GetOverrideAnimationRate()
    return Barghest_QAnimRate(self:GetAbility(), "spin_anim_rate")
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

--[[ Клип удара гонит САМ модификатор движения, а не StartAnimation: оверрайд не
     срезается движком на кастпоинте и переключается без задержки в 0.066 c.
     Продолжается он в modifier_barghest_q_slam_anim на той же активности. ]]
function modifier_barghest_q_lunge:DeclareFunctions()
    return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE}
end

function modifier_barghest_q_lunge:GetOverrideAnimation()
    return BARGHEST_Q_ACT_LUNGE_HIT
end

function modifier_barghest_q_lunge:GetOverrideAnimationRate()
    return Barghest_QAnimRate(self.hAbility or self:GetAbility(), "lunge_anim_rate")
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

    --[[ Держим её на месте, пока меч идёт в землю и клип доигрывает. Без этого
         игрок уходит с первого же кадра приземления, бег перекрывает удар — и
         клип снова «не видно», сколько бы мы его ни держали в StartAnimation.
         У Q стоит IGNORE_BACKSWING, своего замирания после каста у неё нет. ]]
    hParent:AddNewModifier(hParent, hAbility, "modifier_barghest_q_slam_anim", {
        duration = hAbility:GetSpecialValueFor("lunge_slam_delay")
                   + hAbility:GetSpecialValueFor("lunge_slam_hold"),
    })

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
