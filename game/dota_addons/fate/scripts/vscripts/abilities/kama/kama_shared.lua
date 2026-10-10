--[[ Общее для всех способностей Kama: вид стрел (Floral / Samsara), шкала Charm
     и единая точка «стрела попала в цель».
     ⚠️ Каждый ScriptFile грузится в свою среду, поэтому общий код подключается
     через require (так же сделано у barghest_shared).
     ⚠️ Файл подключается и в КЛИЕНТСКОЙ VM, а там нет libraries/util — на
     уровне файла и в функциях, которые зовёт клиент, ничего серверного.
]]

LinkLuaModifier("modifier_kama_floral", "abilities/kama/kama_shared", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kama_samsara", "abilities/kama/kama_shared", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kama_charm", "abilities/kama/kama_shared", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kama_charmed", "abilities/kama/kama_shared", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kama_charm_immune", "abilities/kama/kama_shared", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kama_backswing", "abilities/kama/kama_shared", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kama_charging", "abilities/kama/kama_shared", LUA_MODIFIER_MOTION_NONE)

-- F: переключатель стрел. В его AbilityValues лежат и общие числа Charm.
KAMA_BOW = "kama_sugarcane_bow"

-- Почему исчез клон W. От причины зависит, оставит ли он цветок (атрибут 1):
-- оставляют EXPIRED, REPLACED и SWAPPED.
KAMA_CLONE_EXPIRED  = 1   -- вышло время
KAMA_CLONE_REPLACED = 2   -- вытеснен новым клоном
KAMA_CLONE_SWAPPED  = 3   -- Кама поменялась с ним местами
KAMA_CLONE_ABSORBED = 4   -- поглощён E
KAMA_CLONE_LOST     = 5   -- Кама ушла дальше clone_leash

--[[ Живой ли хэндл. Своя копия: IsNotNull из util есть не во всех VM. ]]
function Kama_Alive(hScript)
    local sType = type(hScript)
    if sType == "nil" then return false end
    if sType == "table" and type(hScript.IsNull) == "function" then
        return not hScript:IsNull()
    end
    return true
end

--[[ Печать Мастера обновила способности (ResetAbilities в master_ability.lua).
     Заряды W живут в стаках модификатора, одного EndCooldown им мало. ]]
function KamaOnSealRefresh(hHero)
    if not IsServer() or not Kama_Alive(hHero) then return end
    local hCharges = hHero:FindModifierByName("modifier_kama_embrace_charges")
    if hCharges then hCharges:Refill() end
end

--[[ Отладка анимаций. В Workshop Tools пишет в консоль, что и когда делает
     код ниже (строки «[KamaAnim …]»); в обычной игре молчит. ]]
local function Trace(sText)
    if IsServer() and IsInToolsMode() then
        print(string.format("[KamaAnim %.2f] %s", GameRules:GetGameTime(), sText))
    end
end
Kama_Trace = Trace

--[[ Жест с плавным входом и выходом и явной скоростью (по умолчанию 1.0).
     ⚠️ Именно этот вызов, а не StartGesture/StartGestureWithPlaybackRate: у тех
     жест кончается без затухания, и модель в конце дёргается — рывком
     возвращается из позы с поднятым луком в стойку.
     fFadeOut заодно задаёт, как быстро жест гасит FadeGesture. ]]
function Kama_Gesture(hUnit, nActivity, fFadeIn, fFadeOut, fRate)
    hUnit:RemoveGesture(nActivity)
    hUnit:StartGestureWithFadeAndPlaybackRate(nActivity, fFadeIn, fFadeOut or 0.4, fRate or 1.0)
end

-- Жест выстрела (секвенция q_shot): им стреляют Q, D, автоатака и клоны W.
KAMA_SHOT_GESTURE = ACT_DOTA_CAST_ABILITY_6
-- длина секвенции q_shot: кадры 311-335
KAMA_SHOT_LENGTH  = 24 / 30
--[[ Заряженный выстрел (D и Samsara E) — тот же клип, что у q_shot, разрезанный
     в модели на три жеста:
       d_draw    — Кама вскидывает лук и растягивает его до упора (8 кадров);
       d_hold    — стоит с растянутым луком (2 кадра, играются очень медленно);
       d_release — отпускает и опускает лук (14 кадров).
     Ведёт их Kama_DrawBow. ]]
KAMA_DRAW_GESTURE    = ACT_DOTA_OVERRIDE_ABILITY_1
KAMA_HOLD_GESTURE    = ACT_DOTA_OVERRIDE_ABILITY_2
KAMA_RELEASE_GESTURE = ACT_DOTA_CAST_ABILITY_7
local DRAW_LENGTH    = 8 / 30
local HOLD_CLIP      = 2 / 30
local RELEASE_LENGTH = 14 / 30
-- Свечение на луке, пока он растянут. Временное, до своего партикля: зарядка
-- Powershot Виндрейнджер (CP0 — лук, CP1 — куда целится).
local FX_BOW_CHARGE = "particles/units/heroes/hero_windrunner/windrunner_spell_powershot_channel.vpcf"

local function StopBowFx(hCaster)
    if hCaster.nKamaBowFx then
        ParticleManager:DestroyParticle(hCaster.nKamaBowFx, false)
        ParticleManager:ReleaseParticleIndex(hCaster.nKamaBowFx)
        hCaster.nKamaBowFx = nil
    end
end

--[[ Бросить заряженный выстрел на полпути (каст отменён, начат другой).
     Уже запланированные шаги Kama_DrawBow после этого не сработают. ]]
function Kama_CancelDraw(hCaster)
    if not IsServer() or not Kama_Alive(hCaster) then return end
    hCaster.nKamaDraw = (hCaster.nKamaDraw or 0) + 1
    hCaster:FadeGesture(KAMA_DRAW_GESTURE)
    hCaster:FadeGesture(KAMA_HOLD_GESTURE)
    StopBowFx(hCaster)
end

--[[ Заряженный выстрел: Кама растягивает лук, замирает с ним и отпускает
     ровно через fShot секунд — в этот момент должна вылететь стрела.
     Растягивает она в родном темпе клипа, поэтому при любом fShot меняется
     только то, сколько она стоит с растянутым луком.
     vAim — куда целится (для свечения на луке). ]]
function Kama_DrawBow(hCaster, hAbility, fShot, vAim)
    if not IsServer() or not Kama_Alive(hCaster) then return end
    Kama_CancelDraw(hCaster)
    local nRun = hCaster.nKamaDraw
    local function Stale()
        return not Kama_Alive(hCaster) or hCaster.nKamaDraw ~= nRun
    end

    Kama_Gesture(hCaster, KAMA_DRAW_GESTURE, 0.1, 0.1)

    local nFx = ParticleManager:CreateParticle(FX_BOW_CHARGE, PATTACH_CUSTOMORIGIN_FOLLOW, hCaster)
    ParticleManager:SetParticleControlEnt(nFx, 0, hCaster, PATTACH_POINT_FOLLOW, "attach_attack1",
        hCaster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(nFx, 1, vAim or hCaster:GetAbsOrigin() + hCaster:GetForwardVector() * 500)
    hCaster.nKamaBowFx = nFx

    -- жест натяга вот-вот кончится: подменяем его «стоит с растянутым луком»
    local fHoldAt = math.min(DRAW_LENGTH - 0.03, fShot)
    Timers:CreateTimer(fHoldAt, function()
        if Stale() or not hCaster:IsAlive() then return end
        -- с запасом 0.2 с: жест не должен кончиться раньше выстрела
        Kama_Gesture(hCaster, KAMA_HOLD_GESTURE, 0, 0.1, HOLD_CLIP / (fShot - fHoldAt + 0.2))
        hCaster:FadeGesture(KAMA_DRAW_GESTURE)
    end)

    Timers:CreateTimer(fShot, function()
        if Stale() then return end
        StopBowFx(hCaster)
        if not hCaster:IsAlive() then return end
        Trace("bow released")
        Kama_Gesture(hCaster, KAMA_RELEASE_GESTURE, 0)
        hCaster:FadeGesture(KAMA_HOLD_GESTURE)
        hCaster:FadeGesture(KAMA_DRAW_GESTURE)
        Kama_Backswing(hCaster, hAbility, RELEASE_LENGTH, KAMA_RELEASE_GESTURE)
    end)
end

--[[ Мгновенно развернуть Каму лицом к точке. Зовётся в начале каста: движок
     начинает каст, не дожидаясь конца разворота, и после клика за спину Кама
     замахивалась ещё боком к цели. ]]
function Kama_FacePoint(hCaster, vPoint)
    if not IsServer() or not Kama_Alive(hCaster) or not vPoint then return end
    local vDirection = vPoint - hCaster:GetAbsOrigin()
    vDirection.z = 0
    if vDirection:Length2D() < 1 then return end
    hCaster:SetForwardVector(vDirection:Normalized())
end

-- Приказ, после которого Кама занята делом: идти, бить, кастовать по цели или
-- точке, подбирать. Мгновенные способности без цели (смена стрел на F) сюда
-- не входят: они ничего не прерывают.
function Kama_IsActionOrder(nOrder)
    return nOrder == DOTA_UNIT_ORDER_MOVE_TO_POSITION
        or nOrder == DOTA_UNIT_ORDER_MOVE_TO_TARGET
        or nOrder == DOTA_UNIT_ORDER_MOVE_TO_DIRECTION
        or nOrder == DOTA_UNIT_ORDER_ATTACK_MOVE
        or nOrder == DOTA_UNIT_ORDER_ATTACK_TARGET
        or nOrder == DOTA_UNIT_ORDER_CAST_POSITION
        or nOrder == DOTA_UNIT_ORDER_CAST_TARGET
        or nOrder == DOTA_UNIT_ORDER_PICKUP_ITEM
end

-- Отдал ли игрок Каме такой приказ не раньше момента fTime. Время приказа
-- пишет скрытая пассивка лука.
function Kama_OrderedSince(hCaster, fTime)
    return (hCaster.fKamaLastOrder or 0) >= fTime
end

--[[ Дать Каме доиграть выстрел fDuration секунд (см. modifier_kama_backswing).
     nGesture — жест, который доигрывается; nil — поза через StartAnimation.
     bIgnoreOrders — это выстрел автоатаки: приказы игрока его не обрывают,
     только движение (повторный правый клик по той же цели выстрел не
     отменяет). Без него это доигрывание способности, и пока оно идёт, Кама
     сама автоатаку не начинает (см. modifier_kama_backswing). ]]
function Kama_Backswing(hCaster, hAbility, fDuration, nGesture, bIgnoreOrders)
    if not IsServer() or not Kama_Alive(hCaster) then return end
    hCaster:AddNewModifier(hCaster, hAbility, "modifier_kama_backswing",
        {duration = fDuration, gesture = nGesture or -1, orders = bIgnoreOrders and 0 or 1})
end

--[[ Убрать всё, что Кама доигрывает с прошлого каста. Зовётся в начале каста
     способностей, чтобы две анимации не накладывались.
     bEngineToo — гасить и анимации каста, которые играет сам движок (W и R).
     R зовёт без него: иначе погасил бы свою же, только что начатую.
     bShotNext — следом сразу запускается жест выстрела. Тогда прежний не
     гасим: Kama_Gesture сам его снимет, а «погасить» и «запустить» одну и ту
     же активность в одном кадре у клонов не бывает — пусть и у Камы не будет. ]]
function Kama_StopAnimations(hCaster, bEngineToo, bShotNext)
    if not IsServer() or not Kama_Alive(hCaster) then return end
    hCaster:RemoveModifierByName("modifier_kama_backswing")
    if not bShotNext then hCaster:FadeGesture(KAMA_SHOT_GESTURE) end
    Kama_CancelDraw(hCaster)
    hCaster:FadeGesture(KAMA_RELEASE_GESTURE)
    if bEngineToo then
        hCaster:FadeGesture(ACT_DOTA_CAST_ABILITY_2)
        hCaster:FadeGesture(ACT_DOTA_CAST_ABILITY_5)
    end
end

--[[ Кама доигрывает выстрел. Пока модификатор висит, анимацию обрывает приказ
     игрока (идти, бить, кастовать по цели) или само движение — иначе Кама
     ехала бы по земле в позе стрельбы.
     После способности (не после автоатаки) Кама ещё и не начинает автоатаку
     сама: её начало перезапускает жест выстрела, и доигрывание Q рвалось бы
     посередине — у клонов, которые не атакуют, оно идёт до конца. Прямой
     приказ атаковать работает как обычно. ]]
modifier_kama_backswing = class({})

function modifier_kama_backswing:IsHidden()      return true end
function modifier_kama_backswing:IsPurgable()    return false end
function modifier_kama_backswing:RemoveOnDeath() return true end

function modifier_kama_backswing:OnCreated(keys)
    if not IsServer() then return end
    self:Setup(keys)
    self:StartIntervalThink(0.03)
end

function modifier_kama_backswing:OnRefresh(keys)
    if not IsServer() then return end
    self:Setup(keys)
end

function modifier_kama_backswing:Setup(keys)
    self.nGesture = nil
    if keys.gesture and keys.gesture >= 0 then self.nGesture = keys.gesture end
    self.bOrders = keys.orders ~= 0
    Trace("backswing start, " .. string.format("%.2f", self:GetDuration()) .. " s")
end

function modifier_kama_backswing:DeclareFunctions()
    return {MODIFIER_EVENT_ON_ORDER, MODIFIER_PROPERTY_DISABLE_AUTOATTACK}
end

function modifier_kama_backswing:GetDisableAutoAttack()
    return self.bOrders and 1 or 0
end

function modifier_kama_backswing:OnIntervalThink()
    if self:GetParent():IsMoving() then self:Cancel("moving") end
end

function modifier_kama_backswing:OnOrder(keys)
    if not IsServer() or not self.bOrders or keys.unit ~= self:GetParent() then return end
    if Kama_IsActionOrder(keys.order_type) then self:Cancel("order " .. tostring(keys.order_type)) end
end

function modifier_kama_backswing:Cancel(sWhy)
    local hParent = self:GetParent()
    Trace("backswing cancelled: " .. sWhy)
    if self.nGesture then
        hParent:FadeGesture(self.nGesture)
    else
        EndAnimation(hParent)
    end
    self:Destroy()
end

function modifier_kama_backswing:OnDestroy()
    if not IsServer() then return end
    Trace("backswing over")
end

--[[ Зарядка выстрела (D и E): Кама замирает на fTime секунд, потом вызывается
     fnRelease. Держит её modifier_kama_charging.
     fHold — сколько ещё держать Каму на месте после fnRelease (очередь стрел E).
     Погибла за время зарядки — выстрела не будет. ]]
function Kama_Charge(hCaster, hAbility, fTime, fnRelease, fHold)
    if not IsServer() then return end
    hCaster:AddNewModifier(hCaster, hAbility, "modifier_kama_charging",
        {duration = fTime + (fHold or 0)})
    Timers:CreateTimer(fTime, function()
        if not Kama_Alive(hCaster) or not Kama_Alive(hAbility) or not hCaster:IsAlive() then return end
        fnRelease()
    end)
end

--[[ Кама заряжает выстрел: стоит на месте, не поворачивается, не атакует, не
     кастует и не жмёт предметы. Это НЕ стан — сделано по образцу
     modifier_merlin_self_stun. ]]
modifier_kama_charging = class({})

function modifier_kama_charging:IsHidden()      return true end
function modifier_kama_charging:IsPurgable()    return false end
function modifier_kama_charging:RemoveOnDeath() return true end

function modifier_kama_charging:DeclareFunctions()
    return {MODIFIER_PROPERTY_DISABLE_TURNING}
end

function modifier_kama_charging:GetModifierDisableTurning()
    return 1
end

function modifier_kama_charging:CheckState()
    return {
        [MODIFIER_STATE_ROOTED]   = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_MUTED]    = true,
    }
end

--=========================================================================--
-- Вид стрел
--=========================================================================--

--[[ Стреляет ли Кама сейчас стрелами Samsara. Нет модификатора — значит Floral:
     это вид по умолчанию. Зовётся и на клиенте (GetBehavior способностей). ]]
function Kama_IsSamsara(hCaster)
    if not Kama_Alive(hCaster) or type(hCaster.HasModifier) ~= "function" then return false end
    return hCaster:HasModifier("modifier_kama_samsara")
end

function Kama_SetStance(hCaster, bSamsara)
    if not IsServer() or not Kama_Alive(hCaster) then return end
    local sOn  = bSamsara and "modifier_kama_samsara" or "modifier_kama_floral"
    local sOff = bSamsara and "modifier_kama_floral" or "modifier_kama_samsara"
    hCaster:RemoveModifierByName(sOff)
    if not hCaster:HasModifier(sOn) then
        hCaster:AddNewModifier(hCaster, hCaster:FindAbilityByName(KAMA_BOW), sOn, {})
    end
end

-- Оба модификатора ничего не делают сами: это видимая игроку метка, которую
-- читают Q, E и D.
modifier_kama_floral = class({})

function modifier_kama_floral:IsHidden()      return false end
function modifier_kama_floral:IsDebuff()      return false end
function modifier_kama_floral:IsPurgable()    return false end
function modifier_kama_floral:RemoveOnDeath() return false end
function modifier_kama_floral:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

modifier_kama_samsara = class({})

function modifier_kama_samsara:IsHidden()      return false end
function modifier_kama_samsara:IsDebuff()      return false end
function modifier_kama_samsara:IsPurgable()    return false end
function modifier_kama_samsara:RemoveOnDeath() return false end
function modifier_kama_samsara:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

--=========================================================================--
-- Charm
--=========================================================================--

function Kama_IsCharmed(hTarget)
    if not Kama_Alive(hTarget) or type(hTarget.HasModifier) ~= "function" then return false end
    return hTarget:HasModifier("modifier_kama_charmed")
end

--[[ Добавить цели Charm. Шкала копится в стаках modifier_kama_charm; каждый
     новый стак продлевает её. На charm_max шкала сбрасывается, цель становится
     Charmed и на charm_immunity секунд перестаёт набирать Charm. ]]
function Kama_AddCharm(hCaster, hTarget, nAmount)
    if not IsServer() then return end
    if not Kama_Alive(hCaster) or not Kama_Alive(hTarget) or not hTarget:IsAlive() then return end
    if not nAmount or nAmount <= 0 then return end
    if hTarget:HasModifier("modifier_kama_charm_immune") then return end

    local hBow = hCaster:FindAbilityByName(KAMA_BOW)
    if not Kama_Alive(hBow) then return end

    local hCharm = hTarget:AddNewModifier(hCaster, hBow, "modifier_kama_charm",
        {duration = hBow:GetSpecialValueFor("charm_duration")})
    if not Kama_Alive(hCharm) then return end

    local nCharm = hCharm:GetStackCount() + nAmount
    if nCharm < hBow:GetSpecialValueFor("charm_max") then
        hCharm:SetStackCount(nCharm)
        return
    end

    hCharm:Destroy()
    hTarget:AddNewModifier(hCaster, hBow, "modifier_kama_charm_immune",
        {duration = hBow:GetSpecialValueFor("charm_immunity")})
    hTarget:AddNewModifier(hCaster, hBow, "modifier_kama_charmed",
        {duration = hBow:GetSpecialValueFor("charmed_duration")})
end

-- Шкала Charm на цели: число стаков = набранный Charm.
modifier_kama_charm = class({})

function modifier_kama_charm:IsHidden()      return false end
function modifier_kama_charm:IsDebuff()      return true end
function modifier_kama_charm:IsPurgable()    return true end
function modifier_kama_charm:RemoveOnDeath() return true end

-- Метка «Charm сейчас не набирается».
modifier_kama_charm_immune = class({})

function modifier_kama_charm_immune:IsHidden()      return false end
function modifier_kama_charm_immune:IsDebuff()      return false end
function modifier_kama_charm_immune:IsPurgable()    return false end
function modifier_kama_charm_immune:RemoveOnDeath() return true end

--[[ Charmed: цель замедлена и сама идёт к Каме.
     Управление отбирается так же, как у modifier_cu_alter_fear: приказ идти
     переиздаётся каждый тик, а действовать не дают датадривен silenced/disarmed.
     MODIFIER_STATE_COMMAND_RESTRICTED нельзя — он блокирует и наш приказ. ]]
modifier_kama_charmed = class({})

function modifier_kama_charmed:IsHidden()      return false end
function modifier_kama_charmed:IsDebuff()      return true end
function modifier_kama_charmed:IsPurgable()    return true end
function modifier_kama_charmed:RemoveOnDeath() return true end

function modifier_kama_charmed:DeclareFunctions()
    return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

-- Стак 1 = цель иммунна к замедлению (выставляется на сервере, читается везде).
function modifier_kama_charmed:GetModifierMoveSpeedBonus_Percentage()
    if self:GetStackCount() == 1 then return 0 end
    return -self:GetAbility():GetSpecialValueFor("charmed_slow")
end

function modifier_kama_charmed:OnCreated()
    if not IsServer() then return end
    self.hKama = self:GetCaster()
    if IsImmuneToSlow(self:GetParent()) then self:SetStackCount(1) end
    self:Lure()
    self:StartIntervalThink(0.1)
end

function modifier_kama_charmed:OnIntervalThink()
    self:Lure()
end

function modifier_kama_charmed:Lure()
    local hParent = self:GetParent()
    if not Kama_Alive(self.hKama) or not Kama_Alive(hParent) then return end
    -- Кама мертва — идти не к кому: цель просто остаётся замедленной до конца.
    if not self.hKama:IsAlive() then return end

    giveUnitDataDrivenModifier(self.hKama, hParent, "silenced", 0.4)
    giveUnitDataDrivenModifier(self.hKama, hParent, "disarmed", 0.4)

    ExecuteOrderFromTable({
        UnitIndex = hParent:entindex(),
        OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        Position  = self.hKama:GetAbsOrigin(),
        Queue     = false,
    })
end

--=========================================================================--
-- Попадание стрелы
--=========================================================================--

--[[ Единая точка «стрела Камы попала в цель». Через неё идёт ЛЮБАЯ стрела:
     автоатака, Q, выстрелы клонов, E, D, комбо — чтобы эффекты, которые
     срабатывают от стрел, жили в одном месте.
     tArrow.charm — сколько Charm даёт эта стрела (nil — нисколько).
     tArrow.mana  — сколько маны вернуть Каме, если цель стоит в области R. ]]
function Kama_ArrowHit(hCaster, hTarget, tArrow)
    if not IsServer() then return end
    if not Kama_Alive(hCaster) or not Kama_Alive(hTarget) then return end
    tArrow = tArrow or {}

    if tArrow.charm then
        Kama_AddCharm(hCaster, hTarget, tArrow.charm)
    end

    -- Blooming Ground: цель в области R — стрела отнимает долю здоровья и
    -- добавляет замедление (kama_blooming_ground.lua)
    local hBloom = hTarget:FindModifierByName("modifier_kama_blooming_ground")
    if hBloom then hBloom:OnKamaArrow(hCaster, tArrow) end
end
