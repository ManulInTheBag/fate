require("abilities/barghest/barghest_shared")

barghest_w = class({})

--[[ Iron Stance (W)
     Контра по образцу lancelot_parry: канал, во время которого урон съедает
     барьер. Барьер пробили — канал обрывается и она бьёт рукой об землю вокруг
     себя. Барьер выстоял, но урон был — удар на истечении стойки.
     Своё сверху концепта: каждый весомый удар по стойке её же и подкрепляет
     (`barrier_per_source`) — не чаще раза в кадр и только если удар был
     сильнее `barrier_min_damage`.

     ⚠️ Блок урона свой, а не modifier_barrier_new с HasCounter: ветка
     HasCounter в аддоне не используется НИКЕМ (cu_alter и demon_king передают
     false), проверить её было нечем, а прок при этом молчал. Здесь всё на
     виду — и момент срабатывания, и эффект.
     ⚠️ От lancelot_parry отличается тем, что ApplyDamage/EndChannel/Destroy
     НЕ зовутся прямо из GetModifierIncomingDamageConstant: движок в этот
     момент идёт по модификаторам юнита, и вложенный пайплайн урона роняет
     сервер. Всё уходит на Timers:CreateTimer(0).
]]

LinkLuaModifier("modifier_barghest_w_stance", "abilities/barghest/barghest_w", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_cc_immune", "abilities/barghest/barghest_w", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_w_guard", "abilities/barghest/barghest_w", LUA_MODIFIER_MOTION_NONE)
function barghest_w:GetAOERadius()
    return Barghest_Radius(self:GetCaster(), self:GetSpecialValueFor("slam_radius"))
end

function barghest_w:GetChannelTime()
    return self:GetSpecialValueFor("duration")
end

function barghest_w:OnAbilityPhaseStart()
    StartAnimation(self:GetCaster(), {duration = self:GetCastPoint(),
        activity = ACT_DOTA_CAST_ABILITY_2, rate = 1.0})
    return true
end

function barghest_w:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end

function barghest_w:OnSpellStart()
    if not IsServer() then return end
    local hCaster = self:GetCaster()
    EndAnimation(hCaster)
    hCaster:EmitSound(BARGHEST_SND.W_CAST)
    Barghest_Voice(hCaster, BARGHEST_VO.W, 3.0)	-- «Клянусь этим мечом…»

    self.bSlammed = false
    self.fCastTime = GameRules:GetGameTime()    -- от него считается окно быстрой отмены в R
    self.tPending = nil                         -- недорешённая отмена от прошлой стойки
    StartAnimation(hCaster, {duration = self:GetChannelTime(),
        activity = ACT_DOTA_CHANNEL_ABILITY_1, rate = 1.0})
    hCaster:AddNewModifier(hCaster, self, "modifier_barghest_w_stance",
        {duration = self:GetChannelTime()})
    hCaster:AddNewModifier(hCaster, self, "modifier_barghest_cc_immune",
        {duration = self:GetChannelTime() + 1})
end

--[[ Канал кончился: сам ли добежал, сбили ли контролем, оборвали ли приказом.
     Бьём, только если по ней прилетело — удар это ОТВЕТ на урон, а не
     бесплатная АоЕ по кнопке. ]]
function barghest_w:OnChannelFinish(bInterrupted)
    if not IsServer() then return end
    local hCaster = self:GetCaster()
    local hStance = hCaster:FindModifierByName("modifier_barghest_w_stance")
    local fAbsorbed = (hStance ~= nil) and (hStance.fAbsorbed or 0) or 0
    local nBarrier  = (hStance ~= nil and not hStance.bBroken) and hStance:GetStackCount() or 0

    hCaster:RemoveModifierByName("modifier_barghest_w_stance")
    EndAnimation(hCaster)

    -- Продолжение — за сам выход из стойки: WR по концепту способ разорвать
    -- дистанцию, и завязывать его на «успели ли ударить» значило бы
    -- «прижали — и не выйдешь».
    Barghest_ArmContinuation(hCaster, BARGHEST_CONT_W)

    local bEarly = bInterrupted and self.fCastTime ~= nil
        and GameRules:GetGameTime() - self.fCastTime <= self:GetSpecialValueFor("quick_cancel_window")
    if not bEarly then
        self:EndStance(hCaster, fAbsorbed)
        return
    end

    -- Быстрая отмена в R: удара нет, мана назад, остаток барьера ещё висит.
    local bIntoR = self:IsCancelledIntoR(hCaster)
    print(string.format("[barghest_w] early cancel %.2fs, into R = %s, barrier %d",
        GameRules:GetGameTime() - self.fCastTime, tostring(bIntoR), nBarrier))
    if bIntoR then
        self:QuickCancel(hCaster, nBarrier)
        return
    end

    --[[ Стойку оборвали рано, но не R: мувом, стопом, чем угодно. По слову
         юзера это тоже быстрая отмена, если R нажат следом — ждём его
         quick_cancel_wait секунд: R в OnAbilityPhaseStart сам зовёт
         ClaimQuickCancel. Не дождались — обычный конец стойки (удар, если по
         ней прилетело).
         Иммунитет к контролю на время ожидания НЕ держим, если удара не будет:
         иначе мув после W давал бы бесплатную секунду иммунитета. ]]
    if fAbsorbed <= 0 then
        hCaster:RemoveModifierByName("modifier_barghest_cc_immune")
    end
    local tPending = {nBarrier = nBarrier, fAbsorbed = fAbsorbed}
    self.tPending = tPending
    local hAbility = self
    Timers:CreateTimer(self:GetSpecialValueFor("quick_cancel_wait"), function()
        if not Barghest_Alive(hAbility) or hAbility.tPending ~= tPending then return end
        hAbility.tPending = nil
        print("[barghest_w] no R phase in time -> normal end")
        if Barghest_Alive(hCaster) then
            hAbility:EndStance(hCaster, tPending.fAbsorbed)
        end
    end)
end

--[[ R вошёл в замах: если стойка только что оборвана рано и ждёт решения —
     это и была отмена в R. ]]
function barghest_w:ClaimQuickCancel()
    local tPending = self.tPending
    if tPending == nil then return end
    self.tPending = nil
    print("[barghest_w] claimed by R phase")
    local hCaster = self:GetCaster()
    if Barghest_Alive(hCaster) then
        self:QuickCancel(hCaster, tPending.nBarrier)
    end
end

-- Не было урона — нет удара. Был — тем сильнее, чем больше по ней прилетело.
function barghest_w:EndStance(hCaster, fAbsorbed)
    if fAbsorbed > 0 then
        self:Slam(hCaster, fAbsorbed)
    else
        hCaster:RemoveModifierByName("modifier_barghest_cc_immune")
    end
end

--[[ Стойку оборвало именно R, и он уже в замахе (или только что из него).
     Обычно это не так: R — каст в точку, она сперва доворачивается к курсору,
     и канал рвётся раньше замаха. Такой случай ловит ожидание tPending и
     ClaimQuickCancel из замаха R. ]]
function barghest_w:IsCancelledIntoR(hCaster)
    local hR = hCaster:FindAbilityByName("barghest_r")
    if not Barghest_Alive(hR) then return false end
    if hR:IsInAbilityPhase() then return true end
    return hR.fLastPhase ~= nil and GameRules:GetGameTime() - hR.fLastPhase <= 0.1
end

--[[ W сразу отменили в R (за quick_cancel_window после каста): удара нет,
     часть маны возвращается, а недобитый барьер ещё quick_cancel_barrier
     секунд висит на ней отдельным модификатором — уже без стойки и без
     иммунитета к контролю. ]]
function barghest_w:QuickCancel(hCaster, nBarrier)
    hCaster:RemoveModifierByName("modifier_barghest_cc_immune")
    hCaster:GiveMana(self:GetSpecialValueFor("quick_cancel_mana"))
    if nBarrier > 0 and hCaster:IsAlive() then
        local hGuard = hCaster:AddNewModifier(hCaster, self, "modifier_barghest_w_guard",
            {duration = self:GetSpecialValueFor("quick_cancel_barrier")})
        if Barghest_Alive(hGuard) then
            hGuard:SetStackCount(nBarrier)
        end
    end
end

--[[ Удар об землю. fAbsorbed — сколько урона по ней прошло за стойку: он и
     решает силу удара. Прибавка ограничена slam_bonus_cap, иначе пятеро бьющих
     превращали бы стойку в бесконечную бомбу. ]]
function barghest_w:Slam(hCaster, fAbsorbed)
    if not IsServer() then return end
    if self.bSlammed then return end
    if not Barghest_Alive(hCaster) or not hCaster:IsAlive() then return end
    self.bSlammed = true

    local fDelay = self:GetSpecialValueFor("slam_delay")

    -- Замах: звук пробитого барьера и сама анимация идут сразу...
    hCaster:EmitSound(BARGHEST_SND.W_BREAK)
    EndAnimation(hCaster)
    -- Клип живёт замах + slam_anim_tail: к моменту удара он должен ещё идти,
    -- иначе модель сваливается в IDLE раньше, чем рука дойдёт до земли.
    StartAnimation(hCaster, {duration = fDelay + self:GetSpecialValueFor("slam_anim_tail"),
        activity = ACT_DOTA_CAST_ICE_WALL, rate = 1.0})

    --[[ ...а урон, кольцо и грохот — через slam_delay, когда рука уже дошла до
         земли. Без задержки клип не успевал даже начаться, и удар случался
         раньше, чем его было видно.
         Урон считаем ЗДЕСЬ, а не в колбэке: уровень способности к моменту
         приземления не изменится, а хэндлов в замыкании тем самым меньше. ]]
    local nRadius = Barghest_Radius(hCaster, self:GetSpecialValueFor("slam_radius"))
    local nBonus = math.min(self:GetSpecialValueFor("slam_bonus_cap"),
        (fAbsorbed or 0) * self:GetSpecialValueFor("slam_from_absorbed") * 0.01)
    local nDamage = self:GetSpecialValueFor("slam_damage") + nBonus
    local nArcAngle    = self:GetSpecialValueFor("slam_arc_angle")
    local nDamageType  = self:GetAbilityDamageType()
    local nTargetTeam  = self:GetAbilityTargetTeam()
    local nTargetType  = self:GetAbilityTargetType()
    local nTargetFlags = self:GetAbilityTargetFlags()
    local hAbility = self

    Timers:CreateTimer(fDelay, function()
        -- ⚠️ Гарды обязательны: за эти 0.2 с её могли убить, а способность —
        -- забрать рулбрейкером.
        if not Barghest_Alive(hCaster) or not hCaster:IsAlive() then return end
        if not Barghest_Alive(hAbility) then return end

        -- Бьёт туда, где стоит НА МОМЕНТ приземления, а не где начала замах.
        local vPos = hCaster:GetAbsOrigin()
        hCaster:EmitSound(BARGHEST_SND.SLAM)
        hCaster:EmitSound(BARGHEST_SND.Q_ARC)

        -- ⚠️ Дуга и вспышка — ТОЛЬКО привязанными к юниту (так же поставлено в
        -- cu_alter_roar): на PATTACH_WORLDORIGIN эти партиклы не рисуются.
        -- Урон при этом идёт по КРУГУ, дуга здесь чисто визуальная.
        Barghest_FxArc(BARGHEST_FX.SHIELD_SLASH, hCaster, nRadius, nArcAngle)
        Barghest_FxOn(BARGHEST_FX.BURST, hCaster, 1.5)

        local tUnits = FindUnitsInRadius(hCaster:GetTeamNumber(), vPos, nil, nRadius,
            nTargetTeam, nTargetType, nTargetFlags, FIND_ANY_ORDER, false)
        for _, hUnit in pairs(tUnits) do
            if IsNotNull(hUnit) and not IsSpellBlocked(hUnit, hCaster) then
                DoDamage(hCaster, hUnit, nDamage, nDamageType, 0, hAbility, false)
                hCaster:FindAbilityByName("barghest_r"):ApplyBurn(hUnit)
                --Barghest_FxAt(BARGHEST_FX.SHOCK, hUnit:GetAbsOrigin(), hCaster)
            end
        end
    end)
end

---------------------------------------------------------------------------------------------------
-- Стойка: барьер, счётчик источников урона, ответный удар при пробитии
---------------------------------------------------------------------------------------------------
modifier_barghest_w_stance = class({})

function modifier_barghest_w_stance:IsHidden()      return false end
function modifier_barghest_w_stance:IsDebuff()      return false end
function modifier_barghest_w_stance:IsPurgable()    return true end
function modifier_barghest_w_stance:RemoveOnDeath() return true end
function modifier_barghest_w_stance:GetPriority()   return MODIFIER_PRIORITY_ULTRA end

function modifier_barghest_w_stance:OnCreated()
    self.hAbility = self:GetAbility()
    self.hParent  = self:GetParent()
    self.fLastFeed = nil    -- когда барьер подливали в последний раз
    self.fGained  = 0       -- сколько барьера уже подлили за эту стойку
    self.bBroken  = false
    self.fAbsorbed = 0      -- сколько урона по ней прошло: решает силу удара

    if not IsServer() then return end
    self:SetStackCount(self.hAbility:GetSpecialValueFor("barrier_base"))

    self.nFxIndex = ParticleManager:CreateParticle(Barghest_SkinFx(BARGHEST_FX.STANCE, self.hParent),
        PATTACH_CUSTOMORIGIN_FOLLOW , self.hParent)
    ParticleManager:SetParticleControlTransformForward(self.nFxIndex, 0, self.hParent:GetAbsOrigin() + self.hParent:GetForwardVector() * 150 + Vector(0,0,150), self.hParent:GetForwardVector())
    self:AddParticle(self.nFxIndex, false, false, -1, false, false)
    self.nFxIndex2 = ParticleManager:CreateParticle(Barghest_SkinFx(BARGHEST_FX.BARRIER, self.hParent),
    PATTACH_CUSTOMORIGIN_FOLLOW , self.hParent)
    self:AddParticle(self.nFxIndex2, true, false, -1, false, false)
end

function modifier_barghest_w_stance:OnRefresh()
    self:OnCreated()
end

function modifier_barghest_w_stance:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
    }
end
function modifier_barghest_w_stance:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] =true }
end

--[[ Подпитка барьера от прилетевшего урона.
     ⚠️ Живёт ЗДЕСЬ, а не в OnTakeDamage, и это и была поломка: пока барьер
     держит, итоговый урон равен нулю, а событие MODIFIER_EVENT_ON_TAKEDAMAGE
     на нулевом уроне движок вообще не рассылает. Прибавка приходила только в
     тот кадр, когда барьер уже ПРОБИТ — то есть практически никогда.
     GetModifierIncomingDamageConstant видит каждое попадание без исключений.

     Два гейта, чтобы прибавка не стала бесплатной:
     • barrier_min_damage — удар слабее порога барьер не кормит вообще. Это и
       есть защита от «двадцать тиков по 5»;
     • barrier_gain_cd — общий кулдаун в один кадр. АоЕ и мультихиты сбрасывают
       по несколько инстансов урона в одном тике, и без него один взрыв
       засчитывался бы как пять подпиток. ]]
function modifier_barghest_w_stance:FeedBarrier(fDamage)
    local hAbility = self.hAbility
    if not Barghest_Alive(hAbility) then return end
    if fDamage < hAbility:GetSpecialValueFor("barrier_min_damage") then return end

    local fNow = GameRules:GetGameTime()
    if self.fLastFeed ~= nil
       and (fNow - self.fLastFeed) < hAbility:GetSpecialValueFor("barrier_gain_cd") then
        return
    end
    self.fLastFeed = fNow

    --[[ ⚠️ Потолок — на СУММУ подпитки за стойку (`barrier_gain_cap`), а не на
         текущий барьер: без потолка толпа наваливала его быстрее, чем
         успевала пробить, и стойку нельзя было сломать в принципе. А потолок
         на текущее значение было легко обходить: урон съедал барьер, и
         подпитка тут же доливала до кромки снова и снова — итого за стойку
         она получала сколько угодно. Теперь лимит именно на полученное. ]]
    local fRoom = hAbility:GetSpecialValueFor("barrier_gain_cap") - self.fGained
    if fRoom <= 0 then return end
    local fGain = math.min(fRoom, hAbility:GetSpecialValueFor("barrier_per_source"))
    self.fGained = self.fGained + fGain
    self:SetStackCount(self:GetStackCount() + fGain)
end

--[[ Съеденное барьером засчитываем в счётчик D (Hound's Fury): до HP оно не
     доходит, и сам D его не увидел бы. Пробившую барьер часть D ловит сам. ]]
function modifier_barghest_w_stance:CountForFury(keys, fBlocked)
    if keys.attacker == self.hParent then return end    -- как в D: урон по себе не в счёт
    local hFury = self.hParent:FindModifierByName("modifier_barghest_d")
    if hFury ~= nil and hFury.AddDamage ~= nil then
        hFury:AddDamage(fBlocked)
    end
end

--[[ Остаток барьера показываем стаками — так игрок видит, сколько ещё держит.
     На клиенте возвращаем стаки, чтобы цифра совпадала с сервером. ]]
function modifier_barghest_w_stance:GetModifierIncomingDamageConstant(keys)
    if not IsServer() then
        return self:GetStackCount()
    end
    if keys.damage <= 0 then return 0 end
    if self.bBroken then return 0 end

    local fIncoming = keys.original_damage or keys.damage
    -- Копим ВЕСЬ прошедший урон: от него растёт ответный удар.
    self.fAbsorbed = (self.fAbsorbed or 0) + fIncoming

    -- ⚠️ Подпитка ДО блока, а не после: иначе удар, который как раз и пробивает
    -- барьер, в него ничего не вложил бы — самый частый случай.
    self:FeedBarrier(fIncoming)

    local nBlock = self:GetStackCount()
    if nBlock > fIncoming then
        self:SetStackCount(nBlock - fIncoming)
        self:CountForFury(keys, fIncoming)
        return -fIncoming
    end
    self:CountForFury(keys, nBlock)

    -- Барьер пробит. ⚠️ Ни урона, ни Destroy, ни EndChannel прямо отсюда —
    -- только на следующий тик.
    self.bBroken = true
    self:SetStackCount(0)
    ParticleManager:DestroyParticle(self.nFxIndex, true)
    ParticleManager:ReleaseParticleIndex(self.nFxIndex)

    local nLeftover = fIncoming - nBlock
    local hAbility  = self.hAbility
    local hParent   = self.hParent
    local tDamage   = nil
    if nLeftover > 0 then
        tDamage = {
            attacker     = keys.attacker,
            victim       = keys.target,
            damage       = nLeftover,
            damage_type  = keys.damage_type,
            damage_flags = keys.damage_flags,
            ability      = keys.inflictor,
        }
    end

    Timers:CreateTimer(0, function()
        if Barghest_Alive(hAbility) then
            -- EndChannel сам приведёт в OnChannelFinish, где и стоит удар.
            hAbility:EndChannel(false)
        end
        if Barghest_Alive(hParent) then
            hParent:RemoveModifierByName("modifier_barghest_w_stance")
        end
        if tDamage and Barghest_Alive(tDamage.victim) and Barghest_Alive(tDamage.attacker)
           and tDamage.victim:IsAlive() then
            ApplyDamage(tDamage)
        end
    end)

    --[[ ⚠️ Блокируем удар ЦЕЛИКОМ, а остаток (nLeftover) наносится отдельно
         следующим тиком (ApplyDamage выше) — как в modifier_barrier_new и Rho
         Aias. Было `return -nBlock`: остаток проходил и в самом ударе, и ещё
         раз через ApplyDamage — двойной урон при каждом пробитии. ]]
    return -fIncoming
end

--[[ Иммунитет к дебаффам на время стойки И на ответный удар.
     ⚠️ Живёт на секунду дольше канала намеренно: без этого стойку было
     достаточно прервать станом, и удар, ради которого её и держали, не
     выходил. Если урона не было (удара не будет) — снимается сразу в
     OnChannelFinish, чтобы бесплатной неуязвимости к контролю не осталось. ]]
modifier_barghest_cc_immune = class({})

function modifier_barghest_cc_immune:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end

function modifier_barghest_cc_immune:IsHidden()
	return false
end

---------------------------------------------------------------------------------------------------
-- Остаток барьера после быстрой отмены W в R. Только поглощение: без стойки,
-- без подпитки, без иммунитета к контролю и без удара. Стаки = сколько осталось.
---------------------------------------------------------------------------------------------------
modifier_barghest_w_guard = class({})

function modifier_barghest_w_guard:IsHidden()      return false end
function modifier_barghest_w_guard:IsDebuff()      return false end
function modifier_barghest_w_guard:IsPurgable()    return true end
function modifier_barghest_w_guard:RemoveOnDeath() return true end

function modifier_barghest_w_guard:GetTexture()
    return "custom/barghest/barghest_w"
end

function modifier_barghest_w_guard:OnCreated()
    if not IsServer() then return end
    self.hParent = self:GetParent()
    if self.nFx == nil then
        self.nFx = ParticleManager:CreateParticle(Barghest_SkinFx(BARGHEST_FX.BARRIER, self.hParent),
            PATTACH_CUSTOMORIGIN_FOLLOW, self.hParent)
        self:AddParticle(self.nFx, true, false, -1, false, false)
    end
end

function modifier_barghest_w_guard:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
    }
end

--[[ Съедает урон, пока есть стаки; что сверх — проходит в том же ударе
     (возвращаем блок только на остаток барьера, отдельного ApplyDamage нет).
     ⚠️ Destroy — только следующим тиком: прямо отсюда он роняет сервер. ]]
function modifier_barghest_w_guard:GetModifierIncomingDamageConstant(keys)
    if not IsServer() then
        return self:GetStackCount()
    end
    if keys.damage <= 0 or self.bBroken then return 0 end

    local fIncoming = keys.original_damage or keys.damage
    local nBlock = math.min(self:GetStackCount(), fIncoming)
    if keys.attacker ~= self.hParent then
        local hFury = self.hParent:FindModifierByName("modifier_barghest_d")
        if hFury ~= nil and hFury.AddDamage ~= nil then
            hFury:AddDamage(nBlock)
        end
    end

    if nBlock < self:GetStackCount() then
        self:SetStackCount(self:GetStackCount() - nBlock)
    else
        self.bBroken = true
        self:SetStackCount(0)
        local hSelf = self
        Timers:CreateTimer(0, function()
            if Barghest_Alive(hSelf) then hSelf:Destroy() end
        end)
    end
    return -nBlock
end
