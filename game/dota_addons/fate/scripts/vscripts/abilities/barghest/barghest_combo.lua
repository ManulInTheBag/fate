require("abilities/barghest/barghest_shared")

barghest_combo = class({})

--[[ Комбо — Black Dog Galatine (D)

     Barghest после короткой подготовки вырастает в `model_scale` раз и рубит дугой
     перед собой, а дальше `giant_duration` секунд держит это состояние:
       • у ВСЕХ её способностей радиус попадания умножается на `radius_mult`
         (гейт — Barghest_Radius в barghest_shared, читает `radius_mult`
         прямо с этой способности);
       • пока она большая, ей идут +`bonus_armor` брони и +`bonus_mr`% МР,
         а сила умножается на `str_mult`.

     ⚠️ Собственная дуга комбо (`cleave_radius`) через Barghest_Radius НЕ
     гоняется: к моменту удара модификатор гиганта уже висит, и зона удвоилась
     бы дважды. Здесь всегда сырое значение из KV.

     ⚠️ Прибавка силы снимается СНИМКОМ в момент роста и лежит в стаках
     модификатора. Считать её как процент от текущей GetStrength нельзя: в
     GetStrength входит и сама прибавка, движок пересчитывает статы по кругу и
     сила уезжает в бесконечность. Стаки при этом сетевые — цифра в UI на
     клиенте совпадает с серверной.
]]

LinkLuaModifier("modifier_barghest_combo_lock",  "abilities/barghest/barghest_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_combo_giant", "abilities/barghest/barghest_combo", LUA_MODIFIER_MOTION_NONE)

--[[ Значения читаем с ЯВНЫМ индексом уровня, а не через GetSpecialValueFor.
     Комбо живёт на MaxLevel 1, и если его уровень по какой-то причине остался
     нулевым (не прошёл LevelAllAbility, пересоздали способность, отобрал
     рулбрейкер), GetSpecialValueFor вернёт 0 — и всё комбо молча выродится:
     нулевая подготовка, нулевой радиус, множитель размера 1. Так же
     подстрахован комбо Распутина. ]]
function barghest_combo:Value(sKey)
    return self:GetLevelSpecialValueFor(sKey, 0)
end

function barghest_combo:GetAOERadius()
    return self:Value("cleave_radius")
end

--[[ ⚠️ Только сервер: CastFilterResult* дёргается и в КЛИЕНТСКОЙ VM, где нет
     ни util.lua, ни половины методов юнита (ровно на этом дважды падала R).
     На клиенте разрешаем — настоящий отказ всё равно за сервером. ]]
function barghest_combo:CastFilterResultLocation()
    if not IsServer() then return UF_SUCCESS end
    if type(GetComboAvailability) ~= "function" then return UF_SUCCESS end
    -- 0 = комбо открыто (30 по всем статам) и не на кулдауне
    if GetComboAvailability(self:GetCaster()) ~= 0 then
        return UF_FAIL_CUSTOM
    end
    return UF_SUCCESS
end

function barghest_combo:GetCustomCastErrorLocation()
    return "Requires 30 in all stats"
end

function barghest_combo:OnSpellStart()
    if not IsServer() then return end
    local hCaster = self:GetCaster()
    if hCaster:HasModifier("modifier_barghest_combo_lock") then return end

    -- Курсор задаёт только направление удара: способность OVERSHOOT, пешком
    -- за курсором она не идёт (так же сделаны Q и R).
    local vDir = self:GetCursorPosition() - hCaster:GetAbsOrigin()
    vDir.z = 0
    if vDir:Length2D() > 1 then
        hCaster:SetForwardVector(vDir:Normalized())
    end

    local fPrep  = self:Value("prep_time")
    local fHit   = self:Value("cleave_delay")
    local fTail  = self:Value("cleave_tail")

    -- Лок на всю подготовку и удар: комбо не прерывается ничем, кроме смерти.
    hCaster:AddNewModifier(hCaster, self, "modifier_barghest_combo_lock",
        {duration = fPrep + fHit + fTail})

    --[[ Гиганта вешаем ЗДЕСЬ, а не после подготовки: модель раздувается плавно
         за `grow_time`, то есть ровно пока идёт замах, и к удару она уже
         большая. Мгновенный «щелчок» размера читался как баг. ]]
    hCaster:AddNewModifier(hCaster, self, "modifier_barghest_combo_giant",
        {duration = fPrep + fHit + self:Value("giant_duration")})

    -- Реплика идёт через общий голосовой канал: раньше фраза, крик роста и
    -- крик удара звучали втроём внахлёст.
    Barghest_Voice(hCaster, BARGHEST_VO.NP_START, fPrep + fHit)
    hCaster:EmitSound(BARGHEST_SND.E_CHARGE)   -- свелл на подготовку
    StartAnimation(hCaster, {duration = fPrep,
        activity = ACT_DOTA_CHANNEL_ABILITY_1, rate = 1.0})

    -- Подготовка: свечение растёт на самой Barghest, снимаем его в момент роста.
    local nPrepFx = ParticleManager:CreateParticle(BARGHEST_FX.CHARGE,
        PATTACH_ABSORIGIN_FOLLOW, hCaster)

    local hAbility = self
    Timers:CreateTimer(fPrep, function()
        -- ⚠️ За эти доли секунды её могли убить, а способность — отобрать.
        ParticleManager:DestroyParticle(nPrepFx, false)
        ParticleManager:ReleaseParticleIndex(nPrepFx)
        if not Barghest_Alive(hCaster) or not hCaster:IsAlive() then return end
        if not Barghest_Alive(hAbility) then return end
        hAbility:Grow()
    end)

    Timers:CreateTimer(fPrep + fHit, function()
        if not Barghest_Alive(hCaster) or not hCaster:IsAlive() then return end
        if not Barghest_Alive(hAbility) then return end
        hAbility:Cleave()
    end)
end

--[[ Момент, когда рост закончился: звук, вспышка и замах уже гигантским мечом.
     Сам модификатор гиганта висит с каста (см. OnSpellStart) — здесь только
     то, что должно совпасть с концом раздувания. ]]
function barghest_combo:Grow()
    local hCaster = self:GetCaster()

    hCaster:EmitSound(BARGHEST_SND.W_CAST)
    -- ⚠️ Своего крика тут НЕТ: он бы перебил реплику на середине. Голос
    -- заговорит на самом ударе (см. Cleave).
    Barghest_FxOn(BARGHEST_FX.BURST, hCaster, 1.5)
    ScreenShake(hCaster:GetAbsOrigin(), 10, 5, 0.8, 1600, 0, true)

    --[[ Замах — клип удара из активации Iron Stance (ACT_DOTA_CAST_ICE_WALL):
         это единственное её движение «двумя руками сверху вниз», под рубящий
         удар гигантским мечом подходит, в отличие от дуги Q1R. ]]
    StartAnimation(hCaster, {duration = self:Value("cleave_delay")
        + self:Value("cleave_tail"),
        activity = ACT_DOTA_CAST_ICE_WALL, rate = 1.0})
end

--[[ Сам рубящий удар: широкая дуга перед собой. ]]
function barghest_combo:Cleave()
    local hCaster = self:GetCaster()
    local vPos    = hCaster:GetAbsOrigin()
    local vDir    = hCaster:GetForwardVector()
    -- ⚠️ Сырое значение из KV, не Barghest_Radius: гигант уже висит (см. шапку).
    local nRadius = self:Value("cleave_radius")
    local nAngle  = self:Value("cleave_angle")
    local fStun   = self:Value("cleave_stun")

    local nDamage = self:Value("cleave_damage")
    -- ⚠️ GetStrength есть только у героев (у копии способности на Мастере — нет).
    if type(hCaster.GetStrength) == "function" then
        nDamage = nDamage + hCaster:GetStrength()
                  * self:Value("cleave_str_pct") * 0.01
    end

    hCaster:EmitSound(BARGHEST_SND.R_FIRE)
    Barghest_Voice(hCaster, BARGHEST_VO.NP_SHOUT, 2.0)
    -- Дуга — та же, что у удара из активации Iron Stance (BARGHEST_FX.SHIELD_SLASH),
    -- в пару к её же клипу ACT_DOTA_CAST_ICE_WALL. Огненная дуга R (ARC_FIRE)
    -- тут была не к месту: у комбо и W одно движение, значит и след один.
    Barghest_FxArc(BARGHEST_FX.SHIELD_SLASH, hCaster, nRadius, nAngle)
    Barghest_FxAt(BARGHEST_FX.GROUND_SLAM, vPos, hCaster)
    ScreenShake(vPos, 14, 6, 0.9, 2000, 0, true)

    for _, hUnit in pairs(Barghest_FindInArc(hCaster, self, vPos, vDir, nRadius, nAngle)) do
        if IsNotNull(hUnit) and not IsSpellBlocked(hUnit, hCaster) then
            DoDamage(hCaster, hUnit, nDamage, self:GetAbilityDamageType(), 0, self, false)
            hUnit:AddNewModifier(hCaster, self, "modifier_stunned", {duration = fStun})
            hUnit:EmitSound(BARGHEST_SND.HIT)
            Barghest_FxAt(BARGHEST_FX.FIRE_HIT, hUnit:GetAbsOrigin(), hCaster)
            -- Горение вешаем через саму R: и числа, и гейт по третьему атрибуту
            -- живут там, дублировать их здесь нечем.
            local hR = hCaster:FindAbilityByName("barghest_r")
            if Barghest_Alive(hR) and type(hR.ApplyBurn) == "function" then
                hR:ApplyBurn(hUnit)
            end
        end
    end
end

---------------------------------------------------------------------------------------------------
-- Лок на время подготовки и удара. Прерывается только смертью.
---------------------------------------------------------------------------------------------------
modifier_barghest_combo_lock = class({})

function modifier_barghest_combo_lock:IsHidden()      return true end
function modifier_barghest_combo_lock:IsDebuff()      return false end
function modifier_barghest_combo_lock:IsPurgable()    return false end
function modifier_barghest_combo_lock:RemoveOnDeath() return true end

function modifier_barghest_combo_lock:CheckState()
    return {
        [MODIFIER_STATE_STUNNED]  = true,
        [MODIFIER_STATE_DISARMED] = true,
    }
end

function modifier_barghest_combo_lock:OnDestroy()
    if not IsServer() then return end
    local hParent = self:GetParent()
    if Barghest_Alive(hParent) then
        EndAnimation(hParent)
    end
end

---------------------------------------------------------------------------------------------------
-- Состояние гиганта: размер, броня, МР, сила и удвоенные радиусы способностей.
---------------------------------------------------------------------------------------------------
modifier_barghest_combo_giant = class({})

function modifier_barghest_combo_giant:IsHidden()      return false end
function modifier_barghest_combo_giant:IsDebuff()      return false end
function modifier_barghest_combo_giant:IsPurgable()    return false end
function modifier_barghest_combo_giant:RemoveOnDeath() return true end

function modifier_barghest_combo_giant:GetTexture()
    return "custom/barghest/barghest_combo"
end

function modifier_barghest_combo_giant:GetEffectName()
    return BARGHEST_FX.GIANT_GLOW
end

function modifier_barghest_combo_giant:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_barghest_combo_giant:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_barghest_combo_giant:GetModifierPhysicalArmorBonus()
    return self:GetAbility():Value("bonus_armor")
end

function modifier_barghest_combo_giant:GetModifierMagicalResistanceBonus()
    return self:GetAbility():Value("bonus_mr")
end

function modifier_barghest_combo_giant:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():Value("bonus_ms_pct")
end

--[[ Снимок прибавки лежит в стаках (сетевые — читаются и на клиенте, цифры в
     UI не врут). Почему не процент от текущей силы — см. шапку файла. ]]
function modifier_barghest_combo_giant:GetModifierBonusStats_Strength()
    return self:GetStackCount()
end

function modifier_barghest_combo_giant:OnCreated()
    if not IsServer() then return end
    local hParent  = self:GetParent()
    local hAbility = self:GetAbility()
    if not Barghest_Alive(hParent) or not Barghest_Alive(hAbility) then return end

    if type(hParent.GetStrength) == "function" then
        self:SetStackCount(math.floor(hParent:GetStrength() * (hAbility:Value("str_mult") - 1)))
    end

    --[[ Всё, что растёт вместе с моделью, запоминаем ОТ ТЕКУЩЕГО значения:
         у Слуги может быть свой ModelScale в hero.kv, свой хулл и свой обзор,
         и жёсткие числа при снятии уронили бы её в чужие. ]]
    self.fScale  = FateGetBaseModelScale(hParent)
    self.fHull   = (type(hParent.GetHullRadius) == "function") and hParent:GetHullRadius() or nil
    --[[ ⚠️ Геттера обзора в API может не оказаться — тогда берём базу из KV
         (`base_vision`, держать равным VisionDaytimeRange в hero.kv).
         Без этого прибавка обзора молча не работала бы. ]]
    self.fDay    = (type(hParent.GetDayTimeVisionRange) == "function")
                   and hParent:GetDayTimeVisionRange() or hAbility:Value("base_vision")
    self.fNight  = (type(hParent.GetNightTimeVisionRange) == "function")
                   and hParent:GetNightTimeVisionRange() or hAbility:Value("base_vision")

    self.fMult   = hAbility:Value("model_scale")
    self.fGrow   = hAbility:Value("grow_time")
    self.fShrink = hAbility:Value("shrink_time")
    self.fVision = hAbility:Value("bonus_vision")
    -- Полоска HP считается от модели: у гиганта её надо поднимать руками,
    -- иначе висит на уровне пояса. В KV лежит значение для ПОЛНОГО размера.
    self.fBarFull = hAbility:Value("healthbar_offset")
    self.fBarBase = (self.fMult > 0) and (self.fBarFull / self.fMult) or self.fBarFull
    self.fStart  = GameRules:GetGameTime()
    self.fEnd    = self.fStart + self:GetDuration()

    self:Apply(0)
    self:StartIntervalThink(FrameTime())
end

--[[ fT — насколько она «раздута» прямо сейчас, 0..1. Через эту одну функцию
     идут и рост, и сдувание, чтобы они гарантированно были симметричны. ]]
function modifier_barghest_combo_giant:Apply(fT)
    local hParent = self:GetParent()
    if not Barghest_Alive(hParent) then return end
    local fScale = 1 + (self.fMult - 1) * fT

    --[[ ⚠️ Не SetModelScale напрямую, а общий стек масштабов (util.lua): иначе
         эффект вроде чаепития Alice, поймавший её раздутой, вернул бы гигантский
         размер насовсем. Свой множитель снимаем в OnDestroy, чужие не трогаем. ]]
    FateSetModelScaleMult(hParent, "barghest_giant", fScale)
    --[[ Реальный хитбокс тянем за моделью: без этого гигант протискивается в
         щели как обычный юнит и стоит «внутри» чужих моделей. Приём взят у
         пирамиды Озимандиаса (ozy_piramid_barrier: SetHullRadius 550/400). ]]
    if self.fHull ~= nil then
        hParent:SetHullRadius(self.fHull * fScale)
    end
    if type(hParent.SetHealthBarOffsetOverride) == "function" then
        hParent:SetHealthBarOffsetOverride(math.floor(self.fBarBase
            + (self.fBarFull - self.fBarBase) * fT))
    end
    -- Обзор растёт линейно вместе с размером: смотрит она с высоты.
    if self.fDay ~= nil then
        hParent:SetDayTimeVisionRange(self.fDay + self.fVision * fT)
    end
    if self.fNight ~= nil then
        hParent:SetNightTimeVisionRange(self.fNight + self.fVision * fT)
    end
end

function modifier_barghest_combo_giant:OnIntervalThink()
    if not IsServer() then return end
    if not Barghest_Alive(self:GetParent()) then return end
    local fNow  = GameRules:GetGameTime()
    local fLeft = self.fEnd - fNow
    local fT    = 1

    if self.fGrow > 0 and fNow - self.fStart < self.fGrow then
        fT = (fNow - self.fStart) / self.fGrow
    elseif self.fShrink > 0 and fLeft < self.fShrink then
        -- Сдувается за столько же плавно, сколько раздувалась.
        fT = math.max(0, fLeft / self.fShrink)
    end
    self:Apply(fT)
end

function modifier_barghest_combo_giant:OnDestroy()
    if not IsServer() then return end
    local hParent = self:GetParent()
    if not Barghest_Alive(hParent) then return end
    -- ⚠️ Возвращаем ВСЁ и явными числами: смерть обрывает модификатор посреди
    -- сдувания, и без этого она воскресла бы полугигантом.
    FateSetModelScaleMult(hParent, "barghest_giant", nil)
    if self.fHull  ~= nil then hParent:SetHullRadius(self.fHull) end
    if self.fDay   ~= nil then hParent:SetDayTimeVisionRange(self.fDay) end
    if self.fNight ~= nil then hParent:SetNightTimeVisionRange(self.fNight) end
    if type(hParent.SetHealthBarOffsetOverride) == "function" then
        hParent:SetHealthBarOffsetOverride(-1)
    end
    -- Ужавшись, она может оказаться внутри чужого хитбокса — расталкиваем.
    FindClearSpaceForUnit(hParent, hParent:GetAbsOrigin(), true)
end
