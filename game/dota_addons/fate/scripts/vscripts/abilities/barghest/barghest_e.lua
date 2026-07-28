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
     доворачивается: приказы движения во время него перехватываются в
     ExecuteOrderFilter и идут в SteerTo, а не в движок (иначе они рвали бы
     motion controller). Скорость доворота — turn_rate.

     ROOT_DISABLES в KV обязателен: рывок должен блокироваться рутом.
]]

LinkLuaModifier("modifier_barghest_e_charge",  "abilities/barghest/barghest_e", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_e_dash",    "abilities/barghest/barghest_e", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_barghest_e_carried", "abilities/barghest/barghest_e", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_e_chains",  "abilities/barghest/barghest_e", LUA_MODIFIER_MOTION_NONE)

function barghest_e:GetAOERadius()
    return self:GetSpecialValueFor("max_distance")
end

function barghest_e:OnSpellStart()
    if not IsServer() then return end
    local hCaster = self:GetCaster()
    local fMax = self:GetSpecialValueFor("charge_time")

    self.fChargeStart = GameRules:GetGameTime()
    hCaster:EmitSound(BARGHEST_SND.E_CHARGE)
    StartAnimation(hCaster, {duration = fMax, activity = ACT_DOTA_CHANNEL_ABILITY_2, rate = 1.0})
    hCaster:AddNewModifier(hCaster, self, "modifier_barghest_e_charge", {duration = fMax})

    -- Подменяем кнопку на «отпустить». С задержкой — иначе то же нажатие,
    -- которым начали зарядку, тут же её и оборвёт.
    Timers:CreateTimer(0.25, function()
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

    local nMin = self:GetSpecialValueFor("min_distance")
    local nMax = self:GetSpecialValueFor("max_distance")
    local nDistance = nMin + (nMax - nMin) * fCharge

    hCaster:EmitSound(BARGHEST_SND.E_DASH)
    StartAnimation(hCaster, {duration = nDistance / self:GetSpecialValueFor("speed") + 0.2,
        activity = ACT_DOTA_CAST_ABILITY_5, rate = 1.0})
    hCaster:AddNewModifier(hCaster, self, "modifier_barghest_e_dash", {
        duration = nDistance / self:GetSpecialValueFor("speed") + 0.2,
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
    }
end

function modifier_barghest_e_charge:OnCreated()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
    if not IsServer() then return end

    self.nFxIndex = ParticleManager:CreateParticle(BARGHEST_FX.CHARGE,
        PATTACH_ABSORIGIN_FOLLOW, self.hParent)
    self:AddParticle(self.nFxIndex, false, false, -1, false, false)

    -- Линия прицела — только владельцу, как у emiya_caladbolg.
    local hOwner = self.hParent:GetPlayerOwner()
    if hOwner ~= nil then
        self.nAimFx = ParticleManager:CreateParticleForPlayer(BARGHEST_FX.AIM,
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

    local nMin = self.hAbility:GetSpecialValueFor("min_distance")
    local nMax = self.hAbility:GetSpecialValueFor("max_distance")
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
-- Рывок: летим вперёд, первого пойманного тащим с собой до конца
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
    self.nGrab      = self.hAbility:GetSpecialValueFor("grab_radius")
    self.nDamage    = self.hAbility:GetSpecialValueFor("chain_damage")
    self.fTravelled = 0
    self.hCarried   = nil
    self.tBrushed   = {}
    self.nRetries   = 0
    self.fTurnRate  = math.rad(self.hAbility:GetSpecialValueFor("turn_rate"))

    self.hParent:SetForwardVector(self.vDir)
    if not self:ApplyHorizontalMotionController() then
        self:Destroy()
        return
    end

    self.nFxIndex = ParticleManager:CreateParticle(BARGHEST_FX.DASH,
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

    -- Пойманного волочём перед собой — он и есть смысл рывка.
    if Barghest_Alive(self.hCarried) and self.hCarried:IsAlive() then
        self.hCarried:SetAbsOrigin(GetGroundPosition(vNext + self.vDir * self.nGrab,
            self.hCarried))
    end

    local hCaster = self:GetCaster()
    local tUnits = FindUnitsInRadius(hCaster:GetTeamNumber(), vNext, nil, self.nGrab,
        self.hAbility:GetAbilityTargetTeam(), self.hAbility:GetAbilityTargetType(),
        self.hAbility:GetAbilityTargetFlags(), FIND_CLOSEST, false)
    for _, hEnemy in pairs(tUnits) do
        if IsNotNull(hEnemy) and not IsSpellBlocked(hEnemy, hCaster)
           and not self.tBrushed[hEnemy:entindex()] then
            self.tBrushed[hEnemy:entindex()] = true
            DoDamage(hCaster, hEnemy, self.nDamage, self.hAbility:GetAbilityDamageType(),
                0, self.hAbility, false)
            if self.hCarried == nil then
                self.hCarried = hEnemy
                hEnemy:EmitSound(BARGHEST_SND.E_GRAB)
                hEnemy:AddNewModifier(hCaster, self.hAbility, "modifier_barghest_e_carried",
                    {duration = self.nDistance / self.nSpeed + 0.2})
            end
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
    local hCarried = self.hCarried
    local fCharge  = self.fCharge
    local hAbility = self.hAbility
    if not Barghest_Alive(hCarried) then return end

    -- ⚠️ Через таймер: рывок может кончиться внутри чужого пайплайна (смерть,
    -- прерывание контроллера), а тут мы вешаем модификаторы.
    Timers:CreateTimer(0, function()
        if not Barghest_Alive(hCarried) or not Barghest_Alive(hCaster) then return end
        if not Barghest_Alive(hAbility) then return end
        hCarried:RemoveModifierByName("modifier_barghest_e_carried")
        if not hCarried:IsAlive() then return end

        FindClearSpaceForUnit(hCarried, hCarried:GetAbsOrigin(), true)
        -- Дольше держали заряд — дольше висят цепи.
        hCarried:AddNewModifier(hCaster, hAbility, "modifier_barghest_e_chains",
            {duration = hAbility:GetSpecialValueFor("chain_duration") * fCharge})
        Barghest_ArmContinuation(hCaster, BARGHEST_CONT_E)
    end)
end

---------------------------------------------------------------------------------------------------
-- Пока волочёт: жертва оглушена и не толкается
---------------------------------------------------------------------------------------------------
modifier_barghest_e_carried = class({})

function modifier_barghest_e_carried:IsHidden()      return false end
function modifier_barghest_e_carried:IsDebuff()      return true end
function modifier_barghest_e_carried:IsPurgable()    return false end
function modifier_barghest_e_carried:RemoveOnDeath() return true end

function modifier_barghest_e_carried:CheckState()
    return {
        [MODIFIER_STATE_STUNNED]           = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end

-- ⚠️ Никакого GetOverrideAnimation: анимации на ЧУЖОМ юните в аддоне не
-- проигрываем никогда. Стан и так показывает состояние.

---------------------------------------------------------------------------------------------------
-- Цепи: держат на месте и постепенно жгут
---------------------------------------------------------------------------------------------------
modifier_barghest_e_chains = class({})

function modifier_barghest_e_chains:IsHidden()      return false end
function modifier_barghest_e_chains:IsDebuff()      return true end
function modifier_barghest_e_chains:IsPurgable()    return true end
function modifier_barghest_e_chains:RemoveOnDeath() return true end

function modifier_barghest_e_chains:GetTexture()
    return "custom/barghest/barghest_chains"
end

function modifier_barghest_e_chains:CheckState()
    return {[MODIFIER_STATE_ROOTED] = true}
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
