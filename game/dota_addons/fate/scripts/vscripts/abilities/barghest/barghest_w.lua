require("abilities/barghest/barghest_shared")

barghest_w = class({})

--[[ Iron Stance (W)
     Контра по образцу lancelot_parry: канал, во время которого урон съедает
     барьер. Барьер пробили — канал обрывается и она бьёт рукой об землю вокруг
     себя. Барьер выстоял, но урон был — удар на истечении стойки.
     Своё сверху концепта: каждый НОВЫЙ источник урона за стойку добавляет
     барьера (`barrier_per_source`).

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
    hCaster:EmitSound(BARGHEST_SND.W_BREAK)
    hCaster:EmitSound(BARGHEST_SND.SLAM)

    local vPos = hCaster:GetAbsOrigin()
    local nRadius = self:GetSpecialValueFor("slam_radius")
    local nBonus = math.min(self:GetSpecialValueFor("slam_bonus_cap"),
        (fAbsorbed or 0) * self:GetSpecialValueFor("slam_from_absorbed") * 0.01)
    local nDamage = self:GetSpecialValueFor("slam_damage") + nBonus

    StartAnimation(hCaster, {duration = 0.5, activity = ACT_DOTA_CAST_ABILITY_4, rate = 1.0})
    -- ⚠️ Шоквейв — ТОЛЬКО привязанным к юниту (так он поставлен в cu_alter_roar);
    -- кольцо по радиусу — warstomp'ом, у него CP1 честно задаёт размер.
    Barghest_FxRing(BARGHEST_FX.RING, vPos, nRadius)
    Barghest_FxOn(BARGHEST_FX.BURST, hCaster, 1.5)

    local tUnits = FindUnitsInRadius(hCaster:GetTeamNumber(), vPos, nil, nRadius,
        self:GetAbilityTargetTeam(), self:GetAbilityTargetType(),
        self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
    for _, hUnit in pairs(tUnits) do
        if IsNotNull(hUnit) and not IsSpellBlocked(hUnit, hCaster) then
            DoDamage(hCaster, hUnit, nDamage, self:GetAbilityDamageType(), 0, self, false)
            Barghest_FxAt(BARGHEST_FX.SHOCK, hUnit:GetAbsOrigin())
        end
    end
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
    self.tSources = {}
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
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end

--[[ Остаток барьера показываем стаками — так игрок видит, сколько ещё держит.
     На клиенте возвращаем стаки, чтобы цифра совпадала с сервером. ]]
function modifier_barghest_w_stance:GetModifierIncomingDamageConstant(keys)
    if not IsServer() then
        return self:GetStackCount()
    end
    if keys.damage <= 0 then return 0 end
    if self.bBroken then return 0 end

    -- Копим ВЕСЬ прошедший урон: от него растёт ответный удар.
    self.fAbsorbed = (self.fAbsorbed or 0) + keys.original_damage

    local nBlock = self:GetStackCount()
    if nBlock > keys.original_damage then
        self:SetStackCount(nBlock - keys.original_damage)
        return -keys.original_damage
    end

    -- Барьер пробит. ⚠️ Ни урона, ни Destroy, ни EndChannel прямо отсюда —
    -- только на следующий тик.
    self.bBroken = true
    self:SetStackCount(0)

    local nLeftover = keys.original_damage - nBlock
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

--[[ ⚠️ Тут можно только менять свои поля и стаки: вешать модификаторы и
     наносить урон прямо из колбэка нельзя. ]]
function modifier_barghest_w_stance:OnTakeDamage(keys)
    if not IsServer() then return end
    if keys.unit ~= self.hParent then return end
    -- ⚠️ Сверяемся с original_damage, а не с damage: барьер уже съел урон, и
    -- damage тут будет 0 — а бить по ней били, источник считать надо.
    if (keys.original_damage or 0) <= 0 then return end

    local hAttacker = keys.attacker
    if not Barghest_Alive(hAttacker) then return end
    local nId = hAttacker:entindex()
    if self.tSources[nId] then return end
    self.tSources[nId] = true

    -- ⚠️ Барьер с потолком: без него толпа наваливала его быстрее, чем успевала
    -- пробить, и стойку нельзя было сломать в принципе.
    if not self.bBroken then
        local nCap = self.hAbility:GetSpecialValueFor("barrier_cap")
        self:SetStackCount(math.min(nCap, self:GetStackCount()
            + self.hAbility:GetSpecialValueFor("barrier_per_source")))
    end
end
