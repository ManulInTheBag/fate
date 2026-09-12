require("abilities/barghest/barghest_shared")

barghest_e = class({})

--[[ Chain Hunt (E) — управляемый рывок.

     Зарядка — НЕ канал, а рутующий модификатор (приём из emiya_caladbolg).
     Разница принципиальная: канал обрывается ЛЮБЫМ приказом, поэтому целиться
     во время него нечем. Рутованный герой приказ идти выполнить не может, но
     ПОВОРАЧИВАЕТСЯ на него своим turn rate — это и есть прицеливание.
     На время зарядки кнопка подменяется на barghest_e_release: нажал ещё раз —
     отпустил раньше времени. Не нажал — уходит само по истечении charge_time.

     Направление рывка = куда герой смотрит в момент отпускания. Дальше рывок
     доворачивается САМ, без всяких фильтров приказов: герой рутован, приказ
     идти он выполнить не может, но разворачивается на него — а контроллер
     движения просто следует за его forward-вектором, не быстрее turn_rate.
     ⚠️ Перехват приказов в ExecuteOrderFilter пробовали и выбросили: съеденный
     приказ не давал герою повернуться, и рулить рывком становилось нечем.

     ROOT_DISABLES в KV обязателен: рывок должен блокироваться рутом.
]]

LinkLuaModifier("modifier_barghest_e_charge",  "abilities/barghest/barghest_e", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_e_dash",    "abilities/barghest/barghest_e", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_barghest_e_chains",  "abilities/barghest/barghest_e", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_e_stun",    "abilities/barghest/barghest_e", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------
--[[ Что разрешено нажимать, пока идёт зарядка или сам разбег.

     Зарядка держится РУТОМ, а не каналом (иначе не прицелиться поворотом), и
     рут не мешает кастовать: игрок мог в зарядке нажать любую кнопку, а во
     время разбега — блинкануть, и рывок ломался вместе с анимацией.
     Ни SILENCED, ни COMMAND_RESTRICTED сюда не годятся: первым мы отрежем и
     саму кнопку «отпустить», вторым — поворот, на котором держится прицел.
     Поэтому приказы фильтруем: пропускаем движение (им она целится) и ровно
     две свои кнопки, всё остальное съедаем.
     ⚠️ Предметы приходят теми же CAST-приказами — блинк отсекается здесь же. ]]
local BARGHEST_E_CAST_ORDERS = {
    [DOTA_UNIT_ORDER_CAST_POSITION]          = true,
    [DOTA_UNIT_ORDER_CAST_TARGET]            = true,
    [DOTA_UNIT_ORDER_CAST_TARGET_TREE]       = true,
    [DOTA_UNIT_ORDER_CAST_NO_TARGET]         = true,
    [DOTA_UNIT_ORDER_CAST_TOGGLE]            = true,
    [DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO]       = true,
    [DOTA_UNIT_ORDER_CAST_RUNE]              = true,
    [DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION] = true,
}

-- Кнопки самой Chain Hunt: ими зарядку и отпускают.
local BARGHEST_E_ALLOWED = {
    ["barghest_e"]         = true,
    ["barghest_e_release"] = true,
}

--[[ Блокировка чужих кнопок состояниями движка.

     ⚠️ Одного фильтра приказов оказалось мало (в игре сквозь него всё равно
     жались способности и предметы), поэтому основной запрет теперь тут, а
     фильтр ниже остаётся второй линией.

     MUTED режет ТОЛЬКО предметы, способности им не закрыть. SILENCED закрыл бы
     и нашу же кнопку «отпустить», поэтому в ЗАРЯДКЕ способности гасим поимённо
     через SetActivated(false), запомнив, что было включено; в РАЗБЕГЕ отпускать
     уже нечего, там хватает обычного SILENCED. ]]
local function BarghestLockAbilities(hUnit, tSaved)
    if not IsServer() then return end
    for i = 0, hUnit:GetAbilityCount() - 1 do
        local hAb = hUnit:GetAbilityByIndex(i)
        if hAb ~= nil and not hAb:IsNull()
           and not BARGHEST_E_ALLOWED[hAb:GetAbilityName()]
           and hAb:IsActivated() then
            table.insert(tSaved, hAb)
            hAb:SetActivated(false)
        end
    end
end

--[[ ⚠️ Возвращаем ровно те способности, что гасили сами: слепой SetActivated(true)
     по всему списку включил бы и то, что выключено чужой механикой. ]]
local function BarghestUnlockAbilities(tSaved)
    if not IsServer() then return end
    for _, hAb in pairs(tSaved or {}) do
        if IsNotNull(hAb) then hAb:SetActivated(true) end
    end
end

-- Зовётся из FateGameMode:ExecuteOrderFilter. false = приказ съеден.
function BarghestChargeOrderFilter(hUnit, hAbility, iOrder)
    if not hUnit:HasModifier("modifier_barghest_e_charge")
       and not hUnit:HasModifier("modifier_barghest_e_dash") then
        return true
    end
    -- Не каст (движение, атака, стоп) — пропускаем: поворот в зарядке нужен.
    if not BARGHEST_E_CAST_ORDERS[iOrder] then return true end
    if not IsNotNull(hAbility) then return false end
    -- В самом разбеге не даём вообще ничего: даже «отпустить» там уже нечего.
    if hUnit:HasModifier("modifier_barghest_e_dash") then return false end
    return BARGHEST_E_ALLOWED[hAbility:GetAbilityName()] == true
end
--------------------------------------------------------------------------------

function barghest_e:GetAOERadius()
    return self:GetSpecialValueFor("max_distance")
end

function barghest_e:OnSpellStart()
    if not IsServer() then return end
    local hCaster = self:GetCaster()
    local fMax = self:GetSpecialValueFor("charge_time")

    self.fChargeStart = GameRules:GetGameTime()
    hCaster:EmitSound(BARGHEST_SND.E_CHARGE)
    Barghest_Voice(hCaster, BARGHEST_VO.E, 2.5)	-- «Пёс… ест пса…!»
    StartAnimation(hCaster, {duration = fMax, activity = ACT_DOTA_CHANNEL_ABILITY_2, rate = 1.0})
    hCaster:AddNewModifier(hCaster, self, "modifier_barghest_e_charge", {duration = fMax})

    -- Подменяем кнопку на «отпустить». С задержкой (release_swap_delay) —
    -- иначе то же нажатие, которым начали зарядку, тут же её и оборвёт.
    Timers:CreateTimer(self:GetSpecialValueFor("release_swap_delay"), function()
        if not IsNotNull(hCaster) then return end
        if hCaster:HasModifier("modifier_barghest_e_charge")
           and hCaster:FindAbilityByName("barghest_e_release") ~= nil then
            hCaster:SwapAbilities("barghest_e", "barghest_e_release", false, true)
        end
    end)
end

--[[ Доля заряда 0..1 на момент отпускания. ]]
function barghest_e:GetChargeFraction()
    local fMax = self:GetSpecialValueFor("charge_time")
    if fMax <= 0 or self.fChargeStart == nil then return 1 end
    return math.max(0, math.min(1, (GameRules:GetGameTime() - self.fChargeStart) / fMax))
end

--[[ Вернуть кнопку на место. Зовётся отовсюду, где зарядка кончилась. ]]
function barghest_e:RestoreButton()
    local hCaster = self:GetCaster()
    if not Barghest_Alive(hCaster) then return end
    if hCaster:FindAbilityByName("barghest_e_release") == nil then return end
    if hCaster:FindAbilityByName("barghest_e_release"):IsHidden() then return end
    hCaster:SwapAbilities("barghest_e", "barghest_e_release", true, false)
end

--[[ Отпустили: летим туда, куда СМОТРИМ. ]]
function barghest_e:LaunchDash()
    if not IsServer() then return end
    local hCaster = self:GetCaster()
    EndAnimation(hCaster)
    hCaster:StopSound(BARGHEST_SND.E_CHARGE)
    self:RestoreButton()

    if not Barghest_Alive(hCaster) or not hCaster:IsAlive() then return end
    if hCaster:IsStunned() or hCaster:IsRooted() then return end

    local fCharge = self:GetChargeFraction()
    local vDir = hCaster:GetForwardVector()
    vDir.z = 0
    vDir = vDir:Normalized()

    -- Дальность рывка тянется за размером: гигант делает шаг длиннее.
    local nMin = Barghest_Dash(hCaster, self:GetSpecialValueFor("min_distance"))
    local nMax = Barghest_Dash(hCaster, self:GetSpecialValueFor("max_distance"))
    local nDistance = nMin + (nMax - nMin) * fCharge

    -- Расчётное время полёта плюс dash_anim_tail: это ПОТОЛОК, обычно рывок
    -- кончается раньше сам (доехал, упёрся, влетел во врага). Запас нужен,
    -- потому что доворот удлиняет путь по сравнению с прямой линией.
    local fLife = nDistance / self:GetSpecialValueFor("speed")
                  + self:GetSpecialValueFor("dash_anim_tail")

    hCaster:EmitSound(BARGHEST_SND.E_DASH)
    StartAnimation(hCaster, {duration = fLife,
        activity = ACT_DOTA_CAST_ABILITY_5, rate = 1.0})
    hCaster:AddNewModifier(hCaster, self, "modifier_barghest_e_dash", {
        duration = fLife,
        x = vDir.x, y = vDir.y,
        distance = nDistance,
        charge = fCharge * 100,     -- в таблицу модификатора уходят только числа
    })
end

---------------------------------------------------------------------------------------------------
-- Зарядка. Рут вместо канала: приказ идти герой не выполнит, но повернётся.
---------------------------------------------------------------------------------------------------
modifier_barghest_e_charge = class({})

function modifier_barghest_e_charge:IsHidden()      return false end
function modifier_barghest_e_charge:IsDebuff()      return false end
function modifier_barghest_e_charge:IsPurgable()    return false end
function modifier_barghest_e_charge:RemoveOnDeath() return true end

--[[ ⚠️ Только рут и разоружение. Ни SILENCED, ни MUTED: кнопкой «отпустить»
     надо мочь воспользоваться. Поворот приказом движения рут не мешает —
     на этом и держится прицеливание. ]]
function modifier_barghest_e_charge:CheckState()
    return {
        [MODIFIER_STATE_ROOTED]   = true,
        [MODIFIER_STATE_DISARMED] = true,
        -- предметы (блинк в первую очередь) закрываются именно этим
        [MODIFIER_STATE_MUTED]    = true,
    }
end

function modifier_barghest_e_charge:OnCreated()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
    if not IsServer() then return end

    --[[ Чужие кнопки гасим на всю зарядку, свои две оставляем.
         ⚠️ Только если ещё не гасили: OnRefresh зовёт этот же OnCreated, а на
         повторном заходе все они уже выключены — список вышел бы пустым, и
         возвращать в OnDestroy стало бы нечего (кнопки остались бы мёртвыми). ]]
    if self.tLocked == nil then
        self.tLocked = {}
        BarghestLockAbilities(self.hParent, self.tLocked)
    end

    self.nFxIndex = ParticleManager:CreateParticle(Barghest_FxName(BARGHEST_FX.CHARGE, self.hParent),
        PATTACH_ABSORIGIN_FOLLOW, self.hParent)
    self:AddParticle(self.nFxIndex, false, false, -1, false, false)

    -- Линия прицела — только владельцу, как у emiya_caladbolg.
    local hOwner = self.hParent:GetPlayerOwner()
    if hOwner ~= nil then
        self.nAimFx = ParticleManager:CreateParticleForPlayer(
            Barghest_FxName(BARGHEST_FX.AIM, self.hParent),
            PATTACH_CUSTOMORIGIN, nil, hOwner)
        ParticleManager:SetParticleControl(self.nAimFx, 4, Vector(255, 60, 60))
    end
    self:StartIntervalThink(FrameTime())
end

function modifier_barghest_e_charge:OnRefresh()
    self:OnCreated()
end

--[[ Тянем линию прицела за поворотом героя и растим её по мере зарядки — так
     видно и направление, и накопленную дальность. ]]
function modifier_barghest_e_charge:OnIntervalThink()
    if not IsServer() then return end
    if not Barghest_Alive(self.hParent) or not Barghest_Alive(self.hAbility) then return end
    if self.nAimFx == nil then return end

    -- Прицел рисуем по ТОЙ ЖЕ дальности, что и полетит рывок (см. LaunchDash).
    local nMin = Barghest_Dash(self.hParent, self.hAbility:GetSpecialValueFor("min_distance"))
    local nMax = Barghest_Dash(self.hParent, self.hAbility:GetSpecialValueFor("max_distance"))
    local nLen = nMin + (nMax - nMin) * self.hAbility:GetChargeFraction()
    local vPos = self.hParent:GetAbsOrigin()
    ParticleManager:SetParticleControl(self.nAimFx, 0, vPos)
    ParticleManager:SetParticleControl(self.nAimFx, 1,
        vPos + self.hParent:GetForwardVector() * nLen)
end

--[[ Зарядка кончилась — сама ли по времени, кнопкой ли, смертью ли. Рывок
     пускаем отсюда: это единственная точка, через которую проходят все случаи.
     ⚠️ Через таймер: OnDestroy может отработать внутри чужого пайплайна. ]]
function modifier_barghest_e_charge:OnDestroy()
    if not IsServer() then return end
    BarghestUnlockAbilities(self.tLocked)
    self.tLocked = nil


    -- ⚠️ Стрелку прицела чистим РУКАМИ: она сделана CreateParticleForPlayer и в
    -- self:AddParticle не попадает, поэтому сама не удалялась и висела на
    -- экране после рывка.
    if self.nAimFx ~= nil then
        ParticleManager:DestroyParticle(self.nAimFx, false)
        ParticleManager:ReleaseParticleIndex(self.nAimFx)
        self.nAimFx = nil
    end

    local hAbility = self.hAbility
    if not Barghest_Alive(hAbility) then return end
    Timers:CreateTimer(0, function()
        if not Barghest_Alive(hAbility) then return end
        hAbility:LaunchDash()
    end)
end

---------------------------------------------------------------------------------------------------
-- Рывок: летим вперёд до первого врага. Встретили — впечатались оба:
-- его сковывает на месте, наш рывок на этом кончается.
---------------------------------------------------------------------------------------------------
modifier_barghest_e_dash = class({})

function modifier_barghest_e_dash:IsHidden()      return true end
function modifier_barghest_e_dash:IsDebuff()      return false end
function modifier_barghest_e_dash:IsPurgable()    return false end
function modifier_barghest_e_dash:RemoveOnDeath() return true end

function modifier_barghest_e_dash:CheckState()
    return {
        [MODIFIER_STATE_ROOTED]   = true,
        [MODIFIER_STATE_DISARMED] = true,
        -- в разбеге отпускать уже нечего: закрываем и способности, и предметы
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_MUTED]    = true,
    }
end

function modifier_barghest_e_dash:OnCreated(tTable)
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
    if not IsServer() then return end

    self.vDir       = Vector(tTable.x, tTable.y, 0):Normalized()
    self.nDistance  = tTable.distance
    self.fCharge    = (tTable.charge or 100) / 100
    self.nSpeed     = self.hAbility:GetSpecialValueFor("speed")
    self.nGrab      = Barghest_Radius(self.hParent, self.hAbility:GetSpecialValueFor("grab_radius"))
    self.nDamage    = self.hAbility:GetSpecialValueFor("chain_damage")
    --[[ Четвёртый атрибут (Fang Unbound) добавляет к урону рывка процент
         от силы героя. ⚠️ GetStrength есть только у героев. ]]
    local hOwner = self.hParent      -- модификатор висит на самой Баргест
    if hOwner.BarghestAttr4Acquired and type(hOwner.GetStrength) == "function" then
        self.nDamage = self.nDamage + hOwner:GetStrength()
                       * self.hAbility:GetSpecialValueFor("e_str_pct") * 0.01
    end
    self.fTravelled = 0
    self.hHit       = nil       -- в кого впечатались; он же оборвал рывок
    self.nRetries   = 0
    self.fTurnRate  = math.rad(self.hAbility:GetSpecialValueFor("turn_rate"))

    self.hParent:SetForwardVector(self.vDir)
    if not self:ApplyHorizontalMotionController() then
        self:Destroy()
        return
    end
    -- Шлейф скорости — только у заряженного рывка (speed_fx_charge_pct): на
    -- коротком он не успевает прочитаться и только замусоривает экран.
    if self.fCharge * 100 > self.hAbility:GetSpecialValueFor("speed_fx_charge_pct") then
        self.nFxIndexSpeed = ParticleManager:CreateParticle(Barghest_FxName(BARGHEST_FX.DASH_SPEED, self.hParent),
        PATTACH_ABSORIGIN_FOLLOW, self.hParent)
        self:AddParticle(self.nFxIndexSpeed, false, false, -1, false, false)
    end
    self.nFxIndex = ParticleManager:CreateParticle(Barghest_FxName(BARGHEST_FX.DASH, self.hParent),
        PATTACH_ABSORIGIN_FOLLOW, self.hParent)
    

    self:AddParticle(self.nFxIndex, false, false, -1, false, false)
end

function modifier_barghest_e_dash:OnRefresh(tTable)
    self:OnCreated(tTable)
end

--[[ ⚠️ Рывок ПЕРЕХВАТЫВАЕТ управление обратно, а не умирает.
     Раньше здесь стоял Destroy, и любое движение героем обрывало рывок на
     полпути. Съедать приказ в ExecuteOrderFilter — тупик: тогда герой не
     поворачивается, а рулить нечем. Поэтому приказ пропускаем (уйти он всё
     равно не даст — стоит рут), а контроллер возвращаем себе.
     Счётчик попыток — страховка от бесконечной борьбы с чужим контроллером. ]]
function modifier_barghest_e_dash:OnHorizontalMotionInterrupted()
    if not IsServer() then return end
    self.hParent:RemoveHorizontalMotionController(self)

    self.nRetries = (self.nRetries or 0) + 1
    if self.nRetries > 20 or not self:ApplyHorizontalMotionController() then
        self:Destroy()
    end
end
function modifier_barghest_e_dash:GetStatusEffectName()
	return "particles/barghest/barghest_status_fx.vpcf"
end

function modifier_barghest_e_dash:UpdateHorizontalMotion(hUnit, fTime)
    if not IsServer() then return end

    --[[ Руль — ПОВОРОТ САМОГО ГЕРОЯ. Он рутован и уйти не может, но на приказ
         движения разворачивается своим turn rate; мы просто следуем за его
         направлением, не быстрее turn_rate. Никаких перехватов приказов —
         именно из-за них деш и ломался. ]]
    local vFace = hUnit:GetForwardVector()
    vFace.z = 0
    if vFace:Length2D() > 0.01 then
        self.vDir = Barghest_TurnToward(self.vDir, vFace:Normalized(),
            self.fTurnRate * fTime)
    end

    local fStep = self.nSpeed * fTime
    local vNext = hUnit:GetAbsOrigin() + self.vDir * fStep
    -- ⚠️ Считаем ПРОЙДЕННЫЙ путь, а не отдалённость от старта: с доворотом по
    -- дуге расстояние до точки старта почти не растёт, и рывок стал бы
    -- бесконечным.
    self.fTravelled = self.fTravelled + fStep
    if not GridNav:IsTraversable(vNext) or GridNav:IsBlocked(vNext)
       or self.fTravelled > self.nDistance then
        self:Destroy()
        return
    end
    hUnit:SetAbsOrigin(vNext)

    --[[ Столкновение. Врага НЕ везём: кого задели — того и сковали на месте, а
         рывок на этом кончается. Поэтому ищем только первого и сразу выходим.
         ⚠️ Урон — здесь (так же было и раньше), а стан вешаем из OnDestroy
         через таймер: модификатор на чужом юните прямо из колбэка контроллера
         движения ставить нельзя. ]]
    local hCaster = self:GetCaster()
    local tUnits = FindUnitsInRadius(hCaster:GetTeamNumber(), vNext, nil, self.nGrab,
        self.hAbility:GetAbilityTargetTeam(), self.hAbility:GetAbilityTargetType(),
        self.hAbility:GetAbilityTargetFlags(), FIND_CLOSEST, false)
    for _, hEnemy in pairs(tUnits) do
        if IsNotNull(hEnemy) and not IsSpellBlocked(hEnemy, hCaster) then
            self.hHit = hEnemy
            hEnemy:EmitSound(BARGHEST_SND.E_GRAB)
            DoDamage(hCaster, hEnemy, self.nDamage, self.hAbility:GetAbilityDamageType(),
                0, self.hAbility, false)
            self:Destroy()
            return
        end
    end
end

function modifier_barghest_e_dash:OnDestroy()
    if not IsServer() then return end
    if Barghest_Alive(self.hParent) then
        self.hParent:RemoveHorizontalMotionController(self)
        FindClearSpaceForUnit(self.hParent, self.hParent:GetAbsOrigin(), true)
    end
    if not Barghest_Alive(self.hAbility) then return end

    local hCaster  = self:GetCaster()
    local hHit     = self.hHit
    local fCharge  = self.fCharge
    local hAbility = self.hAbility
    --[[ Никого не задели — рывок просто выдохся. Без третьего атрибута на этом
         всё и кончается; с Galatine's Ember ветка ER всё равно открывается,
         только цепей вешать не на кого — поэтому заряжаем и выходим. ]]
    if not Barghest_Alive(hHit) then
        Barghest_ArmOnHit(hCaster, false, BARGHEST_CONT_E)
        return
    end
        EndAnimation(hCaster)
    -- ⚠️ Через таймер: рывок может кончиться внутри чужого пайплайна (смерть,
    -- прерывание контроллера, наш же Destroy из UpdateHorizontalMotion), а тут
    -- мы вешаем модификаторы.
    Timers:CreateTimer(0, function()
        if not Barghest_Alive(hHit) or not Barghest_Alive(hCaster) then return end
        if not Barghest_Alive(hAbility) then return end
        if not hHit:IsAlive() then return end

        --[[ Дольше держали заряд — дольше держат цепи. Пол в chain_min_pct:
             без него рывок «в упор» давал цепи в сотые доли секунды, то есть
             ничего. ]]
        local fMin = hAbility:GetSpecialValueFor("chain_min_pct") * 0.01
        local fDur = hAbility:GetSpecialValueFor("chain_duration")
                     * (fMin + (1 - fMin) * fCharge)
        hHit:AddNewModifier(hCaster, hAbility, "modifier_barghest_e_chains",
            {duration = fDur})

        --[[ СТАН — отдельная и всегда одинаковая величина: stun_duration, на
             всех уровнях и при любом заряде. Он НЕ часть цепей: цепи держат
             рутом и жгут ровно столько, сколько накопил заряд, а хард-контроль
             от их длительности не зависит.
             ⚠️ Раньше стан был встроен в цепи (их CheckState) и тянулся за
             зарядом — на пятом уровне выходило до 2 с. Числа врозь и держать. ]]
        hHit:AddNewModifier(hCaster, hAbility, "modifier_barghest_e_stun",
            {duration = hAbility:GetSpecialValueFor("stun_duration")})

        --[[ Четвёртый атрибут открывает рекаст-укус, и ровно на время СТАНА:
             арм подменяет кнопку E, разарм стоит в OnDestroy стана. ]]
        Barghest_BiteArm(hCaster, hHit, hAbility)
        Barghest_ArmOnHit(hCaster, true, BARGHEST_CONT_E)
    end)
end

---------------------------------------------------------------------------------------------------
-- Стан от рывка. Отдельный модификатор, а не часть цепей: он ВСЕГДА длится
-- stun_duration — на всех уровнях E и при любом заряде. На нём же висит окно
-- рекаста-укуса (barghest_e_bite), поэтому окно не может пережить стан.
---------------------------------------------------------------------------------------------------
modifier_barghest_e_stun = class({})

function modifier_barghest_e_stun:IsHidden()      return false end
function modifier_barghest_e_stun:IsDebuff()      return true end
function modifier_barghest_e_stun:IsPurgable()    return true end
function modifier_barghest_e_stun:RemoveOnDeath() return true end

function modifier_barghest_e_stun:CheckState()
    return {[MODIFIER_STATE_STUNNED] = true}
end

function modifier_barghest_e_stun:GetEffectName()
    return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_barghest_e_stun:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

--[[ Стан кончился — закрылось и окно укуса. Сюда приходят все случаи разом:
     истёк, сняли диспелом, жертва умерла. ]]
function modifier_barghest_e_stun:OnDestroy()
    if not IsServer() then return end
    Barghest_BiteDisarm(self:GetCaster(), self:GetParent())
end

---------------------------------------------------------------------------------------------------
-- Цепи: держат на месте рутом и постепенно жгут. Хард-контроля тут НЕТ —
-- он живёт отдельно, в modifier_barghest_e_stun.
-- ⚠️ Никакого GetOverrideAnimation: анимации на ЧУЖОМ юните в аддоне не
-- проигрываем никогда.
---------------------------------------------------------------------------------------------------
modifier_barghest_e_chains = class({})

function modifier_barghest_e_chains:IsHidden()      return false end
function modifier_barghest_e_chains:IsDebuff()      return true end
function modifier_barghest_e_chains:IsPurgable()    return true end
function modifier_barghest_e_chains:RemoveOnDeath() return true end

function modifier_barghest_e_chains:GetTexture()
    return "custom/barghest/barghest_chains"
end

--[[ Цепи приколачивают цель к земле рутом. Стан из них УБРАН: он отдельный
     модификатор фиксированной длины (modifier_barghest_e_stun), иначе
     хард-контроль тянулся бы за длительностью цепей. ]]
function modifier_barghest_e_chains:CheckState()
    return {
        [MODIFIER_STATE_ROOTED] = true,
    }
end

function modifier_barghest_e_chains:OnCreated()
    self.hAbility = self:GetAbility()
    if not IsServer() then return end
    self:StartIntervalThink(self.hAbility:GetSpecialValueFor("chain_interval"))

    self.nFxIndex = ParticleManager:CreateParticle(BARGHEST_FX.CHAINS,
        PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    self:AddParticle(self.nFxIndex, false, false, -1, false, false)
end

function modifier_barghest_e_chains:OnIntervalThink()
    if not IsServer() then return end
    local hParent = self:GetParent()
    local hCaster = self:GetCaster()
    if not Barghest_Alive(hParent) or not Barghest_Alive(hCaster)
       or not Barghest_Alive(self.hAbility) then
        return
    end
    DoDamage(hCaster, hParent, self.hAbility:GetSpecialValueFor("chain_damage"),
        self.hAbility:GetAbilityDamageType(), 0, self.hAbility, false)
end
