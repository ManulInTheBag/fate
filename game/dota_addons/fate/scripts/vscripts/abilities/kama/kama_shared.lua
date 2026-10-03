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

--[[ Жесты, которыми Кама доигрывает выстрел после того, как стрела ушла
     (возврат лука у Q и у D). Любой новый приказ их обрывает — как обычный
     бэксвинг, иначе Кама ехала бы по земле в позе стрельбы. Ловит приказы
     скрытая пассивка лука (kama_sugarcane_bow). ]]
local RECOVERY_GESTURES = {ACT_DOTA_ATTACK, ACT_DOTA_CAST_ABILITY_7}

function Kama_FadeRecovery(hCaster)
    if not IsServer() or not Kama_Alive(hCaster) then return end
    for _, nActivity in ipairs(RECOVERY_GESTURES) do
        hCaster:FadeGesture(nActivity)
    end
end

--[[ Зарядка выстрела (D и E): Кама замирает на fTime секунд, потом вызывается
     fnRelease. Замирает через pause_sealenabled — обычный для аддона «стан с
     доступом к печатям», под ним анимация из StartAnimation продолжает играть.
     Погибла за это время — выстрела не будет. ]]
function Kama_Charge(hCaster, hAbility, fTime, fnRelease)
    if not IsServer() then return end
    giveUnitDataDrivenModifier(hCaster, hCaster, "pause_sealenabled", fTime)
    Timers:CreateTimer(fTime, function()
        if not Kama_Alive(hCaster) or not Kama_Alive(hAbility) or not hCaster:IsAlive() then return end
        fnRelease()
    end)
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
