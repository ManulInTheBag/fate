require("abilities/kama/kama_shared")

kama_petal_volley = kama_petal_volley or class({})

--[[ E — Petal Volley. Поглощает всех клонов W и стреляет: одна стрела своя и
     ещё по одной за каждого поглощённого.
     Floral: стрелы летят очередью по направлению, каждая останавливается на
     первой цели; по Charmed-целям бьют критом.
     Samsara: способность по цели — стрелы падают на неё с неба: в цель все,
     а в каждого врага рядом с ней ещё по одной.
     От вида стрел зависит и способ наведения (GetBehavior).
     Клоны поглощаются сразу при нажатии, а выстрел идёт после зарядки
     (charge_time). Кама стоит на месте и ничего не может и во время зарядки,
     и пока не выпустит всю очередь — иначе блинк посреди очереди переносил бы
     оставшиеся стрелы на новое место.
]]

-- Стрела Floral — временная, до своего партикля: стрела Мираны.
local FX_ARROW = "particles/units/heroes/hero_mirana/mirana_spell_arrow.vpcf"
--[[ Стрела Samsara падает на цель с неба. CP0 — куда падает (следует за
     целью), CP1 — точка, над которой она появляется (партикль сам поднимает
     её на 1100 и сдвигает на 500 вбок).
     ⚠️ FALL_TIME — время падения, оно зашито в партикле (m_flTravelTime в
     kama_e_aoea.vpcf; вспышка удара — m_flDelay 0.3 там же). Урон наносится
     через FALL_TIME после появления стрелы: меняешь одно — меняй и другое. ]]
local FX_SKY_ARROW = "particles/kama/kama_e_aoe.vpcf"
local FALL_TIME = 0.35
-- сдвиг точки появления, зашитый в партикле: его надо вычесть, чтобы
-- поставить стрелу со своей стороны
local FX_SKY_OFFSET = Vector(-500, 0, 0)
-- Samsara: Кама стреляет в небо. Своей анимации для этого у модели нет,
-- поэтому играется обычный выстрел, а сама Кама на это время запрокинута
-- назад на SKY_PITCH градусов.
local SKY_PITCH = -40
-- срыв тетивы в жесте выстрела — через столько секунд после его начала
local SHOT_RELEASE = 0.17

function kama_petal_volley:GetBehavior()
    if Kama_IsSamsara(self:GetCaster()) then
        return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_AOE
    end
    return DOTA_ABILITY_BEHAVIOR_POINT
end

function kama_petal_volley:GetAOERadius()
    return self:GetSpecialValueFor("samsara_radius")
end

--[[ Samsara бьёт по цели в пределах AbilityCastRange. Floral стреляет по
     направлению, идти «в радиус» ей незачем: серверу отдаём «бесконечную»
     дальность, клиенту — дальность полёта стрелы. ]]
function kama_petal_volley:GetCastRange(vLocation, hTarget)
    if Kama_IsSamsara(self:GetCaster()) then
        return self.BaseClass.GetCastRange(self, vLocation, hTarget)
    end
    if IsServer() then return 99999 end
    return self:GetSpecialValueFor("range")
end

function kama_petal_volley:CastFilterResultTarget(hTarget)
    local caster = self:GetCaster()
    local nResult = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE,
        caster:GetTeamNumber())
    if nResult ~= UF_SUCCESS then return nResult end
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hTarget:GetAbsOrigin()) then
        return UF_FAIL_CUSTOM
    end
    return UF_SUCCESS
end

function kama_petal_volley:GetCustomCastErrorTarget(hTarget)
    return "#Must be in same realm"
end

-- Сколько анимация ещё доигрывается после последней стрелы очереди.
local POSE_AFTER_VOLLEY = 0.4

-- Живые клоны W (пусто, если W ещё нет).
function kama_petal_volley:GetClones()
    local hEmbrace = self:GetCaster():FindAbilityByName("kama_embrace_of_dreams")
    if not Kama_Alive(hEmbrace) or hEmbrace:GetLevel() < 1 then return {} end
    return hEmbrace:GetClones()
end

-- Сколько длится очередь из nArrows выстрелов, от первого до последнего.
function kama_petal_volley:VolleyTime(nArrows)
    return (nArrows - 1) * self:GetSpecialValueFor("arrow_interval")
end

--[[ Анимация spell_4: замах, пауза и резкий выпуск на 14-15 кадре (0.5 с в
     родном темпе). От нажатия до выстрела проходит кастпоинт + charge_time =
     0.6 с, отсюда rate 0.85. Меняешь эти времена — пересчитай rate.
     Длится, пока идёт очередь: стрел будет столько, сколько сейчас клонов. ]]
function kama_petal_volley:OnAbilityPhaseStart()
    local caster = self:GetCaster()
    local hTarget = self:GetCursorTarget()
    Kama_StopAnimations(caster, true)
    Kama_FacePoint(caster, hTarget and hTarget:GetAbsOrigin() or self:GetCursorPosition())
    -- у Samsara своя анимация, она начинается позже (SkyShot)
    if Kama_IsSamsara(caster) then return true end

    local fShot = self:GetCastPoint() + self:GetSpecialValueFor("charge_time")
    local fVolley = self:VolleyTime(1 + #self:GetClones())
    StartAnimation(caster, {duration = fShot + fVolley + POSE_AFTER_VOLLEY,
        activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.85})
    return true
end

function kama_petal_volley:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end

-- Samsara: запрокинуться и выстрелить в небо.
function kama_petal_volley:SkyShot()
    local caster = self:GetCaster()
    self:Tilt(SKY_PITCH, 0.12)
    Kama_Gesture(caster, KAMA_SHOT_GESTURE, 0.1)
end

-- Плавно наклонить Каму до fPitch градусов (0 — стоит прямо) за fTime секунд.
function kama_petal_volley:Tilt(fPitch, fTime)
    local caster = self:GetCaster()
    local fFrom = caster:GetAnglesAsVector().x
    local nSteps = math.max(math.floor(fTime / 0.03), 1)
    local nStep = 0
    Timers:CreateTimer(function()
        if not Kama_Alive(caster) then return end
        nStep = nStep + 1
        local vAngles = caster:GetAnglesAsVector()
        caster:SetAngles(fFrom + (fPitch - fFrom) * nStep / nSteps, vAngles.y, vAngles.z)
        if nStep < nSteps then return 0.03 end
    end)
end

function kama_petal_volley:OnSpellStart()
    local caster = self:GetCaster()
    local nArrows = 1 + self:AbsorbClones()
    -- прицел и вид стрел фиксируются в момент нажатия
    local bSamsara = Kama_IsSamsara(caster)
    local hTarget = self:GetCursorTarget()
    local vDirection = self:GetCursorPosition() - caster:GetAbsOrigin()
    vDirection.z = 0
    vDirection = vDirection:Length2D() < 1 and caster:GetForwardVector() or vDirection:Normalized()

    -- Кама снова свободна после зарядки и очереди. Если игрок уже приказал ей
    -- что-то делать — анимацию обрываем сразу, иначе даём доиграть стоя.
    local fChargeStart = GameRules:GetGameTime()
    local fCharge = self:GetSpecialValueFor("charge_time")
    local fLocked = fCharge + self:VolleyTime(nArrows)
    -- у Samsara доигрывается жест выстрела, у Floral — поза из StartAnimation
    local nGesture = bSamsara and KAMA_SHOT_GESTURE or nil
    Timers:CreateTimer(fLocked, function()
        if not Kama_Alive(caster) then return end
        if bSamsara then self:Tilt(0, 0.2) end
        if not Kama_OrderedSince(caster, fChargeStart) then
            Kama_Backswing(caster, self, POSE_AFTER_VOLLEY, nGesture)
        elseif nGesture then
            caster:FadeGesture(nGesture)
        else
            EndAnimation(caster)
        end
    end)

    if bSamsara then
        -- срыв тетивы должен прийтись на конец зарядки
        Timers:CreateTimer(math.max(fCharge - SHOT_RELEASE, 0), function()
            if not Kama_Alive(caster) or not Kama_Alive(self) or not caster:IsAlive() then return end
            self:SkyShot()
        end)
    end

    Kama_Charge(caster, self, self:GetSpecialValueFor("charge_time"), function()
        caster:EmitSound("Ability.Powershot.Alt")
        if bSamsara then
            self:FireLasers(hTarget, nArrows)
        else
            self:FireVolley(vDirection, nArrows)
        end
    end, self:VolleyTime(nArrows))
end

-- Забрать всех клонов W. Поглощение не считается уничтожением клона.
function kama_petal_volley:AbsorbClones()
    -- копия списка: RemoveClone правит сам список
    local tClones = {}
    for _, hClone in ipairs(self:GetClones()) do
        table.insert(tClones, hClone)
    end
    if #tClones < 1 then return 0 end

    local hEmbrace = self:GetCaster():FindAbilityByName("kama_embrace_of_dreams")
    for _, hClone in ipairs(tClones) do
        hEmbrace:RemoveClone(hClone, KAMA_CLONE_ABSORBED)
    end
    return #tClones
end

--=========================================================================--
-- Floral: очередь стрел по направлению
--=========================================================================--

function kama_petal_volley:FireVolley(vDirection, nArrows)
    local caster = self:GetCaster()
    local fInterval = self:GetSpecialValueFor("arrow_interval")

    for i = 0, nArrows - 1 do
        Timers:CreateTimer(i * fInterval, function()
            if not Kama_Alive(self) or not Kama_Alive(caster) or not caster:IsAlive() then return end
            self:FireArrow(vDirection)
        end)
    end
end

function kama_petal_volley:FireArrow(vDirection)
    local caster = self:GetCaster()
    local nWidth = self:GetSpecialValueFor("width")

    -- стрела вылетает из руки с луком; у модели без такого крепления — от груди
    local nAttach = caster:ScriptLookupAttachment("attach_attack1")
    local vOrigin = nAttach > 0 and caster:GetAttachmentOrigin(nAttach)
        or caster:GetAbsOrigin() + Vector(0, 0, 100)

    ProjectileManager:CreateLinearProjectile({
        Ability          = self,
        Source           = caster,
        EffectName       = FX_ARROW,
        vSpawnOrigin     = vOrigin,
        vVelocity        = vDirection * self:GetSpecialValueFor("speed"),
        fDistance        = self:GetSpecialValueFor("range"),
        fStartRadius     = nWidth,
        fEndRadius       = nWidth,
        iUnitTargetTeam  = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType  = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
    })
end

--=========================================================================--
-- Samsara: стрелы с неба — в цель и по одной во всех врагов рядом
--=========================================================================--

function kama_petal_volley:FireLasers(hTarget, nArrows)
    local caster = self:GetCaster()
    if not Kama_Alive(hTarget) then return end
    local fInterval = self:GetSpecialValueFor("arrow_interval")

    local tNearby = FindUnitsInRadius(caster:GetTeamNumber(), hTarget:GetAbsOrigin(), nil,
        self:GetSpecialValueFor("samsara_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER, false)
    for _, hEnemy in pairs(tNearby) do
        if hEnemy ~= hTarget then self:FireLaser(hEnemy, false) end
    end

    -- способность по цели: блок заклинаний гасит все лазеры в саму цель
    if IsSpellBlocked(hTarget, caster) then return end
    for i = 0, nArrows - 1 do
        Timers:CreateTimer(i * fInterval, function()
            if not Kama_Alive(self) or not Kama_Alive(caster) or not caster:IsAlive() then return end
            if not Kama_Alive(hTarget) or not hTarget:IsAlive() then return end
            self:FireLaser(hTarget, true)
        end)
    end
end

--[[ Одна стрела с неба в hTarget: одна видимая стрела = одно попадание,
     так что в главную цель их падает столько, сколько выстрелов (своя и по
     одной за каждого поглощённого клона). Это не снаряд: стрела — партикль,
     а попадание наступает через FALL_TIME, куда бы цель ни ушла. Увернуться
     от неё нельзя.
     bChecked: блок заклинаний у цели уже проверен при касте. ]]
function kama_petal_volley:FireLaser(hTarget, bChecked)
    local caster = self:GetCaster()
    self:SkyArrowFx(hTarget)

    Timers:CreateTimer(FALL_TIME, function()
        if not Kama_Alive(self) or not Kama_Alive(caster) then return end
        if not Kama_Alive(hTarget) or not hTarget:IsAlive() then return end
        self:ArrowHit(hTarget, true, bChecked)
    end)
end

--[[ Партикль одной падающей стрелы. Падает со стороны Камы: точка появления
     — над линией «цель → Кама», с небольшим разбросом, чтобы стрелы одного
     залпа не шли след в след и их можно было сосчитать. ]]
function kama_petal_volley:SkyArrowFx(hTarget)
    local caster = self:GetCaster()
    local vTarget = hTarget:GetAbsOrigin()
    local vToKama = caster:GetAbsOrigin() - vTarget
    vToKama.z = 0
    vToKama = vToKama:Length2D() < 1 and -caster:GetForwardVector() or vToKama:Normalized()
    vToKama = RotatePosition(Vector(0, 0, 0), QAngle(0, RandomFloat(-20, 20), 0), vToKama)

    local nFx = ParticleManager:CreateParticle(FX_SKY_ARROW, PATTACH_ABSORIGIN_FOLLOW, hTarget)
    ParticleManager:SetParticleControl(nFx, 1, vTarget - FX_SKY_OFFSET + vToKama * FX_SKY_OFFSET:Length2D())
    ParticleManager:ReleaseParticleIndex(nFx)
end

--=========================================================================--

-- Стрела Floral долетела до цели.
function kama_petal_volley:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
    if not Kama_Alive(hTarget) or not hTarget:IsAlive() then return true end
    if not Kama_Alive(self:GetCaster()) then return true end
    self:ArrowHit(hTarget, false, false)
    return true
end

--[[ Попадание стрелы E. bChecked — блок заклинаний у цели уже проверен при
     касте (стрелы Samsara в главную цель); у остальных проверяется здесь. ]]
function kama_petal_volley:ArrowHit(hTarget, bSamsara, bChecked)
    local caster = self:GetCaster()
    if not bChecked and IsSpellBlocked(hTarget, caster) then return end

    local nDamage = self:GetSpecialValueFor("damage")
    if not bSamsara and Kama_IsCharmed(hTarget) then
        nDamage = nDamage * self:GetSpecialValueFor("crit_mult")
    end
    DoDamage(caster, hTarget, nDamage, self:GetAbilityDamageType(), 0, self, false)
    Kama_ArrowHit(caster, hTarget, {})
end
