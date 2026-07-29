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

function barghest_w:GetAOERadius()
    return self:GetSpecialValueFor("slam_radius")
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

    self.bSlammed = false
    StartAnimation(hCaster, {duration = self:GetChannelTime(),
        activity = ACT_DOTA_CHANNEL_ABILITY_1, rate = 1.0})
    hCaster:AddNewModifier(hCaster, self, "modifier_barghest_w_stance",
        {duration = self:GetChannelTime()})
end

--[[ Канал кончился: сам ли добежал, сбили ли контролем, оборвали ли приказом.
     Бьём, только если по ней прилетело — удар это ОТВЕТ на урон, а не
     бесплатная АоЕ по кнопке. ]]
function barghest_w:OnChannelFinish(bInterrupted)
    if not IsServer() then return end
    local hCaster = self:GetCaster()
    local hStance = hCaster:FindModifierByName("modifier_barghest_w_stance")
    local fAbsorbed = (hStance ~= nil) and (hStance.fAbsorbed or 0) or 0

    hCaster:RemoveModifierByName("modifier_barghest_w_stance")
    EndAnimation(hCaster)

    -- Не было урона — нет удара. Был — тем сильнее, чем больше по ней прилетело.
    if fAbsorbed > 0 then
        self:Slam(hCaster, fAbsorbed)
    end
    -- Продолжение — за сам выход из стойки: WR по концепту способ разорвать
    -- дистанцию, и завязывать его на «успели ли ударить» значило бы
    -- «прижали — и не выйдешь».
    Barghest_ArmContinuation(hCaster, BARGHEST_CONT_W)
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
    StartAnimation(hCaster, {duration = fDelay + 0.5,
        activity = ACT_DOTA_CAST_ABILITY_4, rate = 1.0})

    --[[ ...а урон, кольцо и грохот — через slam_delay, когда рука уже дошла до
         земли. Без задержки клип не успевал даже начаться, и удар случался
         раньше, чем его было видно.
         Урон считаем ЗДЕСЬ, а не в колбэке: уровень способности к моменту
         приземления не изменится, а хэндлов в замыкании тем самым меньше. ]]
    local nRadius = self:GetSpecialValueFor("slam_radius")
    local nBonus = math.min(self:GetSpecialValueFor("slam_bonus_cap"),
        (fAbsorbed or 0) * self:GetSpecialValueFor("slam_from_absorbed") * 0.01)
    local nDamage = self:GetSpecialValueFor("slam_damage") + nBonus
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
        -- ⚠️ Шоквейв — ТОЛЬКО привязанным к юниту (так он поставлен в
        -- cu_alter_roar); кольцо по радиусу — warstomp'ом, у него CP1 честно
        -- задаёт размер.
        Barghest_FxRing(BARGHEST_FX.RING, vPos, nRadius)
        Barghest_FxOn(BARGHEST_FX.BURST, hCaster, 1.5)

        local tUnits = FindUnitsInRadius(hCaster:GetTeamNumber(), vPos, nil, nRadius,
            nTargetTeam, nTargetType, nTargetFlags, FIND_ANY_ORDER, false)
        for _, hUnit in pairs(tUnits) do
            if IsNotNull(hUnit) and not IsSpellBlocked(hUnit, hCaster) then
                DoDamage(hCaster, hUnit, nDamage, nDamageType, 0, hAbility, false)
                Barghest_FxAt(BARGHEST_FX.SHOCK, hUnit:GetAbsOrigin())
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
    self.bBroken  = false
    self.fAbsorbed = 0      -- сколько урона по ней прошло: решает силу удара

    if not IsServer() then return end
    self:SetStackCount(self.hAbility:GetSpecialValueFor("barrier_base"))

    self.nFxIndex = ParticleManager:CreateParticle(BARGHEST_FX.STANCE,
        PATTACH_ABSORIGIN_FOLLOW, self.hParent)
    self:AddParticle(self.nFxIndex, false, false, -1, false, false)
end

function modifier_barghest_w_stance:OnRefresh()
    self:OnCreated()
end

function modifier_barghest_w_stance:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
    }
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

    -- ⚠️ Барьер с потолком: без него толпа наваливала его быстрее, чем успевала
    -- пробить, и стойку нельзя было сломать в принципе.
    self:SetStackCount(math.min(hAbility:GetSpecialValueFor("barrier_cap"),
        self:GetStackCount() + hAbility:GetSpecialValueFor("barrier_per_source")))
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
        return -fIncoming
    end

    -- Барьер пробит. ⚠️ Ни урона, ни Destroy, ни EndChannel прямо отсюда —
    -- только на следующий тик.
    self.bBroken = true
    self:SetStackCount(0)

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

    return -nBlock
end
