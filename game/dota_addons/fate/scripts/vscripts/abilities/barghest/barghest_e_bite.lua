require("abilities/barghest/barghest_shared")

--[[ Bite of the Black Dog — рекаст Chain Hunt (E).

     Открывается ЧЕТВЁРТЫМ атрибутом (Fang Unbound) и доступна ровно то время,
     пока цель В СТАНЕ от рывка (modifier_barghest_e_stun, всегда stun_duration
     секунд — не путать с цепями, они висят дольше): на это окно кнопка E
     подменяется на эту
     (тот же приём SwapAbilities, что и у «отпустить»), а по концу окна
     возвращается обратно. Арм и разарм живут в barghest_shared
     (Barghest_BiteArm / Barghest_BiteDisarm) — их зовёт barghest_e.

     Механика: короткий рывок к прикованной цели, укус на bite_damage плюс
     процент от силы, лечение от нанесённого урона — и КРАЖА чужого эффекта на
     steal_duration секунд. Что именно украдено, решает КЛАСС Слуги-жертвы
     (GetServantClass в libraries/util.lua): по одному эффекту на класс, всё
     остальное падает в EXTRA.

     ⚠️ Кулдаун печатью Мастера не сбрасывается: способность стоит в CannotReset
     (libraries/util.lua) — оттуда же это читает тултип, отсюда «Unrefreshable».
     ⚠️ Уровень скрытой кнопке ставит не игрок: его тянут за уровнем E при
     каждом арме (приём hijikata_dash_recast), иначе GetSpecialValueFor отдавал
     бы значения первого уровня.
]]

barghest_e_bite = class({})

LinkLuaModifier("modifier_barghest_bite_dash",      "abilities/barghest/barghest_e_bite", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_barghest_bite_saber",     "abilities/barghest/barghest_e_bite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_bite_archer",    "abilities/barghest/barghest_e_bite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_bite_lancer",    "abilities/barghest/barghest_e_bite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_bite_rider",     "abilities/barghest/barghest_e_bite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_bite_assassin",  "abilities/barghest/barghest_e_bite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_bite_invis",     "abilities/barghest/barghest_e_bite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_bite_caster",    "abilities/barghest/barghest_e_bite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_bite_berserker", "abilities/barghest/barghest_e_bite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_bite_extra",     "abilities/barghest/barghest_e_bite", LUA_MODIFIER_MOTION_NONE)

--[[ Класс жертвы -> что украдено. Всё, чего в таблице нет (Ruler, Avenger,
     Moon Cancer, Alter Ego, а заодно любые не-Слуги), считается EXTRA. ]]
local BARGHEST_BITE_BOON = {
    ["Saber"]     = "modifier_barghest_bite_saber",
    ["Archer"]    = "modifier_barghest_bite_archer",
    ["Lancer"]    = "modifier_barghest_bite_lancer",
    ["Rider"]     = "modifier_barghest_bite_rider",
    ["Assassin"]  = "modifier_barghest_bite_assassin",
    ["Caster"]    = "modifier_barghest_bite_caster",
    ["Berserker"] = "modifier_barghest_bite_berserker",
}

--[[ Все краденые модификаторы одним списком: перед новой кражей старую снимаем,
     двух сразу быть не должно. ]]
local BARGHEST_BITE_ALL = {
    "modifier_barghest_bite_saber",
    "modifier_barghest_bite_archer",
    "modifier_barghest_bite_lancer",
    "modifier_barghest_bite_rider",
    "modifier_barghest_bite_assassin",
    "modifier_barghest_bite_caster",
    "modifier_barghest_bite_berserker",
    "modifier_barghest_bite_extra",
}

--[[ Значение с поправкой на уровень. ⚠️ На нулевом уровне GetSpecialValueFor
     молча вернул бы 0 — читаем через явный индекс, не ниже первого. ]]
function barghest_e_bite:Value(sKey)
    local nLevel = self:GetLevel()
    if nLevel < 1 then nLevel = 1 end
    return self:GetLevelSpecialValueFor(sKey, nLevel - 1)
end

--[[ Цель ещё та же и всё ещё в стане от рывка? Окно укуса живёт ровно столько,
     сколько держит СТАН (modifier_barghest_e_stun, всегда stun_duration), —
     своего таймера у него нет. Цепи тут ни при чём: они висят дольше и только
     рутуют. ]]
function barghest_e_bite:GetBiteTarget()
    local hCaster = self:GetCaster()
    local hTarget = hCaster.hBarghestBiteTarget
    if not Barghest_Alive(hTarget) or not hTarget:IsAlive() then return nil end
    if not hTarget:HasModifier("modifier_barghest_e_stun") then return nil end
    return hTarget
end

function barghest_e_bite:OnSpellStart()
    if not IsServer() then return end
    local hCaster = self:GetCaster()
    local hTarget = self:GetBiteTarget()

    --[[ Цепи слетели ровно в момент нажатия (цель умерла, дебафф сняли) —
         ни маны, ни кулдауна за это не берём: игрок тут ни при чём. ]]
    if hTarget == nil then
        Barghest_BiteDisarm(hCaster)
        self:EndCooldown()
        hCaster:GiveMana(self:GetManaCost(self:GetLevel()))
        return
    end

    -- Кнопка своё отработала: возвращаем E сразу, а не по концу цепей.
    Barghest_BiteDisarm(hCaster)

    Barghest_Voice(hCaster, BARGHEST_VO.LAUGH, 2.0)
    hCaster:EmitSound(BARGHEST_SND.E_DASH)

    local nDistance = (hTarget:GetAbsOrigin() - hCaster:GetAbsOrigin()):Length2D()
    local fLife = nDistance / self:Value("dash_speed") + self:Value("dash_anim_tail")
    StartAnimation(hCaster, {duration = fLife, activity = ACT_DOTA_CAST_ABILITY_5, rate = 1.0})
    hCaster:AddNewModifier(hCaster, self, "modifier_barghest_bite_dash", {
        duration = fLife,
        -- ⚠️ В таблицу модификатора уходят только числа: цель передаём индексом.
        target   = hTarget:entindex(),
    })
end

--[[ Сам укус: урон, лечение от него и кража эффекта. ]]
function barghest_e_bite:DoBite(hTarget)
    if not IsServer() then return end
    local hCaster = self:GetCaster()
    if not Barghest_Alive(hCaster) or not hCaster:IsAlive() then return end
    if not Barghest_Alive(hTarget) or not hTarget:IsAlive() then return end
    if IsSpellBlocked(hTarget, hCaster) then return end

    EndAnimation(hCaster)
    StartAnimation(hCaster, {duration = 0.6, activity = ACT_DOTA_CAST_ABILITY_4, rate = 1.0})

    local nDamage = self:Value("bite_damage")
    --[[ Прибавка от силы — как у остальных мест четвёртого атрибута.
         ⚠️ GetStrength есть только у героев. ]]
    if type(hCaster.GetStrength) == "function" then
        nDamage = nDamage + hCaster:GetStrength() * self:Value("bite_str_pct") * 0.01
    end

    hTarget:EmitSound(BARGHEST_SND.R_HOUND)
    Barghest_FxAt(BARGHEST_FX.FIRE_HIT, hTarget:GetAbsOrigin(), hCaster)
    Barghest_FxCutThin(hCaster, Barghest_Radius(hCaster, self:Value("bite_radius")),
        hTarget:GetAbsOrigin())

    DoDamage(hCaster, hTarget, nDamage, self:GetAbilityDamageType(), 0, self, false)

    --[[ Лечение от нанесённого урона. Считаем от расчётного числа, а не от
         прошедшего: вампиризм пассивки (Blood of the Beast) и так добавит своё
         от фактического, а тут важна предсказуемость. ]]
    local nHeal = nDamage * self:Value("heal_pct") * 0.01
    if nHeal > 0 then
        hCaster:Heal(nHeal, self)
        Barghest_FxAt(BARGHEST_FX.LIFESTEAL, hCaster:GetAbsOrigin(), hCaster)
    end

    self:StealBoon(hTarget)
end

--[[ Кража по классу Слуги. Класс лежит в libraries/util.lua (ServantClasses):
     в самом аддоне его больше нигде нет, таблица собрана по админ-панели. ]]
function barghest_e_bite:StealBoon(hTarget)
    local hCaster = self:GetCaster()
    local sClass  = GetServantClass(hTarget)
    local sMod    = BARGHEST_BITE_BOON[sClass] or "modifier_barghest_bite_extra"

    -- Двух краж разом не бывает: старую снимаем.
    for _, sOld in pairs(BARGHEST_BITE_ALL) do
        if hCaster:HasModifier(sOld) then hCaster:RemoveModifierByName(sOld) end
    end
    hCaster:AddNewModifier(hCaster, self, sMod, {duration = self:Value("steal_duration")})
end

---------------------------------------------------------------------------------------------------
-- Рывок к прикованной цели. Цель стоит в цепях, но направление всё равно
-- пересчитываем каждый кадр: её могли сдвинуть чужим эффектом.
---------------------------------------------------------------------------------------------------
modifier_barghest_bite_dash = class({})

function modifier_barghest_bite_dash:IsHidden()      return true end
function modifier_barghest_bite_dash:IsDebuff()      return false end
function modifier_barghest_bite_dash:IsPurgable()    return false end
function modifier_barghest_bite_dash:RemoveOnDeath() return true end

function modifier_barghest_bite_dash:CheckState()
    return {
        [MODIFIER_STATE_ROOTED]   = true,
        [MODIFIER_STATE_DISARMED] = true,
    }
end

function modifier_barghest_bite_dash:OnCreated(tTable)
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
    if not IsServer() then return end

    self.hTarget    = EntIndexToHScript(tTable.target)
    self.nSpeed     = self.hAbility:Value("dash_speed")
    self.nStop      = Barghest_Radius(self.hParent, self.hAbility:Value("bite_radius"))
    self.nMax       = Barghest_Dash(self.hParent, self.hAbility:Value("dash_max_distance"))
    self.fTravelled = 0

    if not Barghest_Alive(self.hTarget) then
        self:Destroy()
        return
    end
    if not self:ApplyHorizontalMotionController() then
        self:Destroy()
        return
    end

    self.nFxIndex = ParticleManager:CreateParticle(Barghest_FxName(BARGHEST_FX.DASH, self.hParent),
        PATTACH_ABSORIGIN_FOLLOW, self.hParent)
    self:AddParticle(self.nFxIndex, false, false, -1, false, false)
end

function modifier_barghest_bite_dash:OnRefresh(tTable)
    self:OnCreated(tTable)
end

--[[ Чужой контроллер перехватил движение — рывок на этом кончается, укус
     отработает из OnDestroy, если цель уже рядом. ]]
function modifier_barghest_bite_dash:OnHorizontalMotionInterrupted()
    if not IsServer() then return end
    self.hParent:RemoveHorizontalMotionController(self)
    self:Destroy()
end

function modifier_barghest_bite_dash:UpdateHorizontalMotion(hUnit, fTime)
    if not IsServer() then return end
    if not Barghest_Alive(self.hTarget) then
        self:Destroy()
        return
    end

    local vTo = self.hTarget:GetAbsOrigin() - hUnit:GetAbsOrigin()
    vTo.z = 0
    -- Доехали: дальше решает OnDestroy.
    if vTo:Length2D() <= self.nStop then
        self:Destroy()
        return
    end

    local vDir  = vTo:Normalized()
    local fStep = self.nSpeed * fTime
    local vNext = hUnit:GetAbsOrigin() + vDir * fStep
    self.fTravelled = self.fTravelled + fStep
    if not GridNav:IsTraversable(vNext) or GridNav:IsBlocked(vNext)
       or self.fTravelled > self.nMax then
        self:Destroy()
        return
    end
    hUnit:SetForwardVector(vDir)
    hUnit:SetAbsOrigin(vNext)
end

function modifier_barghest_bite_dash:OnDestroy()
    if not IsServer() then return end
    if Barghest_Alive(self.hParent) then
        self.hParent:RemoveHorizontalMotionController(self)
        FindClearSpaceForUnit(self.hParent, self.hParent:GetAbsOrigin(), true)
    end
    if not Barghest_Alive(self.hAbility) then return end

    local hAbility = self.hAbility
    local hParent  = self.hParent
    local hTarget  = self.hTarget
    --[[ Дотянуться разрешаем чуть дальше радиуса остановки: рывок могли оборвать
         за кадр до касания, и терять из-за этого весь укус нечестно. ]]
    local nReach   = self.nStop * 1.5

    -- ⚠️ Через таймер: рывок обрывается и изнутри чужого пайплайна (смерть,
    -- перехват контроллера), а здесь мы наносим урон и вешаем модификаторы.
    Timers:CreateTimer(0, function()
        if not Barghest_Alive(hAbility) or not Barghest_Alive(hParent) then return end
        if not Barghest_Alive(hTarget) or not hTarget:IsAlive() then return end
        if (hTarget:GetAbsOrigin() - hParent:GetAbsOrigin()):Length2D() > nReach then return end
        hAbility:DoBite(hTarget)
    end)
end

---------------------------------------------------------------------------------------------------
-- SABER: магическое сопротивление и барьер, который держит только магию.
-- Барьер сделан по item_b_scroll (MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT),
-- но добивающий урон отложен на тик — см. modifier_barrier_new.
---------------------------------------------------------------------------------------------------
modifier_barghest_bite_saber = class({})

function modifier_barghest_bite_saber:IsHidden()      return false end
function modifier_barghest_bite_saber:IsDebuff()      return false end
function modifier_barghest_bite_saber:IsPurgable()    return true end
function modifier_barghest_bite_saber:RemoveOnDeath() return true end
function modifier_barghest_bite_saber:GetPriority()   return MODIFIER_PRIORITY_ULTRA end

function modifier_barghest_bite_saber:GetTexture()
    return "custom/barghest/barghest_e_bite"
end

function modifier_barghest_bite_saber:OnCreated()
    self.hAbility = self:GetAbility()
    self.bBroken  = false
    if not IsServer() then return end
    self:SetStackCount(self.hAbility:Value("saber_barrier"))
end

function modifier_barghest_bite_saber:OnRefresh()
    self:OnCreated()
end

function modifier_barghest_bite_saber:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT,
    }
end

-- ⚠️ Без серверного гарда: сопротивление обязано считаться и на клиенте.
function modifier_barghest_bite_saber:GetModifierMagicalResistanceBonus()
    if not Barghest_Alive(self.hAbility) then return 0 end
    return self.hAbility:Value("saber_mr")
end

--[[ Остаток барьера показываем стаками — так игрок видит, сколько ещё держит.
     ⚠️ Пробитый барьер НЕ снимает сам модификатор: сопротивление живёт до конца
     кражи. Ни Destroy, ни ApplyDamage прямо из колбэка — только тиком позже
     (грабли из modifier_barrier_new). ]]
function modifier_barghest_bite_saber:GetModifierIncomingSpellDamageConstant(keys)
    if not IsServer() then
        return self:GetStackCount()
    end
    if self.bBroken then return 0 end
    if keys.damage == nil or keys.damage <= 0 then return 0 end

    local fIncoming = keys.original_damage or keys.damage
    local nBlock    = self:GetStackCount()
    if nBlock > fIncoming then
        self:SetStackCount(nBlock - fIncoming)
        return -fIncoming
    end

    self.bBroken = true
    self:SetStackCount(0)

    local tDamage = nil
    if fIncoming - nBlock > 0 then
        tDamage = {
            attacker     = keys.attacker,
            victim       = keys.target,
            damage       = fIncoming - nBlock,
            damage_type  = keys.damage_type,
            damage_flags = keys.damage_flags,
            ability      = keys.inflictor,
        }
    end
    if tDamage then
        Timers:CreateTimer(0, function()
            if not Barghest_Alive(tDamage.victim) then return end
            if not tDamage.victim:IsAlive() then return end
            ApplyDamage(tDamage)
        end)
    end
    return -nBlock
end

function modifier_barghest_bite_saber:GetEffectName()
    return "particles/barghest/barghest_barrier.vpcf"
end

function modifier_barghest_bite_saber:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------
-- ARCHER: дальше видит и видит невидимых.
-- True sight вешаем стоковым modifier_item_ward_true_sight прямо на неё — так же
-- сделан атрибут khsn_ambush, дамми под это не нужен.
---------------------------------------------------------------------------------------------------
modifier_barghest_bite_archer = class({})

function modifier_barghest_bite_archer:IsHidden()      return false end
function modifier_barghest_bite_archer:IsDebuff()      return false end
function modifier_barghest_bite_archer:IsPurgable()    return true end
function modifier_barghest_bite_archer:RemoveOnDeath() return true end

function modifier_barghest_bite_archer:GetTexture()
    return "custom/barghest/barghest_e_bite"
end

function modifier_barghest_bite_archer:OnCreated()
    self.hAbility = self:GetAbility()
    if not IsServer() then return end
    if not Barghest_Alive(self.hAbility) then return end
    self:GetParent():AddNewModifier(self:GetCaster(), self.hAbility,
        "modifier_item_ward_true_sight", {
            true_sight_range = self.hAbility:Value("archer_true_sight"),
            -- ⚠️ Длительность берём из KV, а не GetRemainingTime: на момент
            -- OnCreated таймер модификатора может ещё не быть выставлен.
            duration         = self.hAbility:Value("steal_duration"),
        })
end

function modifier_barghest_bite_archer:OnRefresh()
    self:OnCreated()
end

--[[ ⚠️ True sight снимаем руками: он висит отдельным модификатором и своей
     длительностью пережил бы кражу, если её сняли диспелом раньше срока. ]]
function modifier_barghest_bite_archer:OnDestroy()
    if not IsServer() then return end
    local hParent = self:GetParent()
    if not Barghest_Alive(hParent) then return end
    hParent:RemoveModifierByName("modifier_item_ward_true_sight")
end

function modifier_barghest_bite_archer:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_BONUS_DAY_VISION,
        MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
    }
end

function modifier_barghest_bite_archer:GetBonusDayVision()
    if not Barghest_Alive(self.hAbility) then return 0 end
    return self.hAbility:Value("archer_vision")
end

function modifier_barghest_bite_archer:GetBonusNightVision()
    return self:GetBonusDayVision()
end

---------------------------------------------------------------------------------------------------
-- LANCER: чутьё, съедающее одно направленное заклинание.
-- Проверку зовёт IsSpellBlocked (libraries/util.lua) — там и стоит имя этого
-- модификатора, как у okita_mind_eye и saito_style.
---------------------------------------------------------------------------------------------------
modifier_barghest_bite_lancer = class({})

function modifier_barghest_bite_lancer:IsHidden()      return false end
function modifier_barghest_bite_lancer:IsDebuff()      return false end
function modifier_barghest_bite_lancer:IsPurgable()    return true end
function modifier_barghest_bite_lancer:RemoveOnDeath() return true end

function modifier_barghest_bite_lancer:GetTexture()
    return "custom/barghest/barghest_e_bite"
end

function modifier_barghest_bite_lancer:OnCreated()
    self.hAbility = self:GetAbility()
    self.bReady   = true
    if not IsServer() then return end
    self:SetStackCount(1)       -- 1 = щит заряжен, 0 = откатывается
    self:PlayShellFx()
end

function modifier_barghest_bite_lancer:OnRefresh()
    self:OnCreated()
end

function modifier_barghest_bite_lancer:PlayShellFx()
    if not IsServer() then return end
    if self.nFxIndex ~= nil then return end
    --[[ ⚠️ Через AddParticle НЕ регистрируем: этот партикль мы гасим и зажигаем
         сами (он показывает готовность щита), а движок снял бы уже снятый
         индекс на конце модификатора. Уборка — в StopShellFx из OnDestroy. ]]
    self.nFxIndex = ParticleManager:CreateParticle("particles/zlodemon/immunity_sphere_buff.vpcf",
        PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
end

--[[ ⚠️ Партикль щита снимаем руками, а не только через AddParticle: он гаснет
     на время отката и зажигается снова, а не живёт до конца модификатора. ]]
function modifier_barghest_bite_lancer:StopShellFx()
    if not IsServer() then return end
    if self.nFxIndex == nil then return end
    ParticleManager:DestroyParticle(self.nFxIndex, false)
    ParticleManager:ReleaseParticleIndex(self.nFxIndex)
    self.nFxIndex = nil
end

--[[ Зовётся из IsSpellBlocked. true = заклинание съедено. ]]
function modifier_barghest_bite_lancer:BlockSpellCheck()
    if not IsServer() then return false end
    if not self.bReady then return false end
    self.bReady = false
    self:SetStackCount(0)
    self:StopShellFx()

    local fRecharge = 3
    if Barghest_Alive(self.hAbility) then
        fRecharge = self.hAbility:Value("lancer_recharge")
    end
    -- ⚠️ Гард на self: кража может кончиться (или её снимут) раньше отката.
    Timers:CreateTimer(fRecharge, function()
        if not Barghest_Alive(self) then return end
        if not Barghest_Alive(self:GetParent()) then return end
        self.bReady = true
        self:SetStackCount(1)
        self:PlayShellFx()
    end)
    return true
end

function modifier_barghest_bite_lancer:OnDestroy()
    if not IsServer() then return end
    self:StopShellFx()
end

---------------------------------------------------------------------------------------------------
-- RIDER: проходит сквозь чужие тела, бежит быстрее и его нельзя замедлить.
---------------------------------------------------------------------------------------------------
modifier_barghest_bite_rider = class({})

function modifier_barghest_bite_rider:IsHidden()      return false end
function modifier_barghest_bite_rider:IsDebuff()      return false end
function modifier_barghest_bite_rider:IsPurgable()    return true end
function modifier_barghest_bite_rider:RemoveOnDeath() return true end

function modifier_barghest_bite_rider:GetTexture()
    return "custom/barghest/barghest_e_bite"
end

--[[ Иммунитет к замедлению держится ДВУМЯ путями, и оба нужны:
     • имя модификатора вписано в IsImmuneToSlow (libraries/util.lua) — так
       слоу вообще не вешается, но проверку зовут не все способности аддона;
     • всё, что всё-таки повесили мимо проверки, снимает RemoveSlowEffect по
       тику (список slowmodifier оттуда же).
     ⚠️ Снятие модификаторов — только из OnCreated и тика: в damage-колбэках
     это роняет сервер. ]]
function modifier_barghest_bite_rider:OnCreated()
    self.hAbility = self:GetAbility()
    if not IsServer() then return end
    RemoveSlowEffect(self:GetParent())
    self:StartIntervalThink(0.25)
end

function modifier_barghest_bite_rider:OnRefresh()
    self:OnCreated()
end

function modifier_barghest_bite_rider:OnIntervalThink()
    if not IsServer() then return end
    local hParent = self:GetParent()
    if not Barghest_Alive(hParent) then return end
    RemoveSlowEffect(hParent)
end

function modifier_barghest_bite_rider:CheckState()
    return {[MODIFIER_STATE_NO_UNIT_COLLISION] = true}
end

function modifier_barghest_bite_rider:DeclareFunctions()
    return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_barghest_bite_rider:GetModifierMoveSpeedBonus_Percentage()
    if not Barghest_Alive(self.hAbility) then return 0 end
    return self.hAbility:Value("rider_ms_pct")
end

---------------------------------------------------------------------------------------------------
-- ASSASSIN: невидимость, которая гаснет от своих способностей и от урона и
-- возвращается, если assassin_fade секунд ничего не происходило.
-- ⚠️ Само состояние держит ОТДЕЛЬНЫЙ модификатор: выдача и снятие модификатора
-- заставляют движок пересчитать состояния, а правка таблицы внутри CheckState —
-- нет (на этом же держится modifier_robin_may_king_invis, только там обратного
-- включения нет).
---------------------------------------------------------------------------------------------------
modifier_barghest_bite_assassin = class({})

function modifier_barghest_bite_assassin:IsHidden()      return false end
function modifier_barghest_bite_assassin:IsDebuff()      return false end
function modifier_barghest_bite_assassin:IsPurgable()    return true end
function modifier_barghest_bite_assassin:RemoveOnDeath() return true end

function modifier_barghest_bite_assassin:GetTexture()
    return "custom/barghest/barghest_e_bite"
end

function modifier_barghest_bite_assassin:OnCreated()
    self.hAbility = self:GetAbility()
    if not IsServer() then return end
    self.fRevealUntil = 0
    self:Fade()
    self:StartIntervalThink(0.1)
end

function modifier_barghest_bite_assassin:OnRefresh()
    self:OnCreated()
end

function modifier_barghest_bite_assassin:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end

function modifier_barghest_bite_assassin:Fade()
    if not IsServer() then return end
    local hParent = self:GetParent()
    if not Barghest_Alive(hParent) then return end
    if hParent:HasModifier("modifier_barghest_bite_invis") then return end
    hParent:AddNewModifier(self:GetCaster(), self.hAbility, "modifier_barghest_bite_invis", {})
end

function modifier_barghest_bite_assassin:Reveal()
    if not IsServer() then return end
    local fDelay = 1.0
    if Barghest_Alive(self.hAbility) then
        fDelay = self.hAbility:Value("assassin_fade")
    end
    self.fRevealUntil = GameRules:GetGameTime() + fDelay

    local hParent = self:GetParent()
    if Barghest_Alive(hParent) and hParent:HasModifier("modifier_barghest_bite_invis") then
        hParent:RemoveModifierByName("modifier_barghest_bite_invis")
    end
end

function modifier_barghest_bite_assassin:OnIntervalThink()
    if not IsServer() then return end
    if GameRules:GetGameTime() < (self.fRevealUntil or 0) then return end
    self:Fade()
end

function modifier_barghest_bite_assassin:OnAbilityExecuted(keys)
    if not IsServer() then return end
    if keys.unit ~= self:GetParent() then return end
    self:Reveal()
end

--[[ ⚠️ Раскрытие откладываем на тик: событие урона движок рассылает, пока идёт
     по модификаторам юнита, а мы модификатор снимаем. ]]
function modifier_barghest_bite_assassin:OnTakeDamage(keys)
    if not IsServer() then return end
    if keys.unit ~= self:GetParent() then return end
    if keys.damage <= 0 then return end
    Timers:CreateTimer(0, function()
        if not Barghest_Alive(self) then return end
        self:Reveal()
    end)
end

function modifier_barghest_bite_assassin:OnDestroy()
    if not IsServer() then return end
    local hParent = self:GetParent()
    if not Barghest_Alive(hParent) then return end
    hParent:RemoveModifierByName("modifier_barghest_bite_invis")
end

-- Само состояние невидимости. Живёт и гаснет по команде модификатора выше.
modifier_barghest_bite_invis = class({})

function modifier_barghest_bite_invis:IsHidden()      return true end
function modifier_barghest_bite_invis:IsDebuff()      return false end
function modifier_barghest_bite_invis:IsPurgable()    return false end
function modifier_barghest_bite_invis:RemoveOnDeath() return true end

function modifier_barghest_bite_invis:CheckState()
    return {[MODIFIER_STATE_INVISIBLE] = true}
end

function modifier_barghest_bite_invis:DeclareFunctions()
    return {MODIFIER_PROPERTY_INVISIBILITY_LEVEL}
end

function modifier_barghest_bite_invis:GetModifierInvisibilityLevel()
    return 1
end

---------------------------------------------------------------------------------------------------
-- CASTER: сильная регенерация маны и послабее — здоровья.
---------------------------------------------------------------------------------------------------
modifier_barghest_bite_caster = class({})

function modifier_barghest_bite_caster:IsHidden()      return false end
function modifier_barghest_bite_caster:IsDebuff()      return false end
function modifier_barghest_bite_caster:IsPurgable()    return true end
function modifier_barghest_bite_caster:RemoveOnDeath() return true end

function modifier_barghest_bite_caster:GetTexture()
    return "custom/barghest/barghest_e_bite"
end

function modifier_barghest_bite_caster:OnCreated()
    self.hAbility = self:GetAbility()
end

function modifier_barghest_bite_caster:OnRefresh()
    self:OnCreated()
end

function modifier_barghest_bite_caster:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    }
end

function modifier_barghest_bite_caster:GetModifierConstantManaRegen()
    if not Barghest_Alive(self.hAbility) then return 0 end
    return self.hAbility:Value("caster_mana_regen")
end

function modifier_barghest_bite_caster:GetModifierConstantHealthRegen()
    if not Barghest_Alive(self.hAbility) then return 0 end
    return self.hAbility:Value("caster_hp_regen")
end

---------------------------------------------------------------------------------------------------
-- BERSERKER: бьёт сильнее и получает больше. Плюс немного силы.
---------------------------------------------------------------------------------------------------
modifier_barghest_bite_berserker = class({})

function modifier_barghest_bite_berserker:IsHidden()      return false end
function modifier_barghest_bite_berserker:IsDebuff()      return false end
function modifier_barghest_bite_berserker:IsPurgable()    return true end
function modifier_barghest_bite_berserker:RemoveOnDeath() return true end

function modifier_barghest_bite_berserker:GetTexture()
    return "custom/barghest/barghest_e_bite"
end

function modifier_barghest_bite_berserker:OnCreated()
    self.hAbility = self:GetAbility()
end

function modifier_barghest_bite_berserker:OnRefresh()
    self:OnCreated()
end

function modifier_barghest_bite_berserker:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    }
end

function modifier_barghest_bite_berserker:GetModifierDamageOutgoing_Percentage()
    if not Barghest_Alive(self.hAbility) then return 0 end
    return self.hAbility:Value("berserker_outgoing_pct")
end

function modifier_barghest_bite_berserker:GetModifierIncomingDamage_Percentage()
    if not Barghest_Alive(self.hAbility) then return 0 end
    return self.hAbility:Value("berserker_incoming_pct")
end

function modifier_barghest_bite_berserker:GetModifierBonusStats_Strength()
    if not Barghest_Alive(self.hAbility) then return 0 end
    return self.hAbility:Value("berserker_str")
end

---------------------------------------------------------------------------------------------------
-- EXTRA (Ruler, Avenger, Moon Cancer, Alter Ego и всё, чего нет в таблице
-- классов): понемногу всего.
---------------------------------------------------------------------------------------------------
modifier_barghest_bite_extra = class({})

function modifier_barghest_bite_extra:IsHidden()      return false end
function modifier_barghest_bite_extra:IsDebuff()      return false end
function modifier_barghest_bite_extra:IsPurgable()    return true end
function modifier_barghest_bite_extra:RemoveOnDeath() return true end

function modifier_barghest_bite_extra:GetTexture()
    return "custom/barghest/barghest_e_bite"
end

function modifier_barghest_bite_extra:OnCreated()
    self.hAbility = self:GetAbility()
end

function modifier_barghest_bite_extra:OnRefresh()
    self:OnCreated()
end

function modifier_barghest_bite_extra:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_BONUS_DAY_VISION,
        MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
    }
end

function modifier_barghest_bite_extra:Value(sKey)
    if not Barghest_Alive(self.hAbility) then return 0 end
    return self.hAbility:Value(sKey)
end

function modifier_barghest_bite_extra:GetModifierBonusStats_Strength()      return self:Value("extra_stats") end
function modifier_barghest_bite_extra:GetModifierBonusStats_Agility()       return self:Value("extra_stats") end
function modifier_barghest_bite_extra:GetModifierBonusStats_Intellect()     return self:Value("extra_stats") end
function modifier_barghest_bite_extra:GetModifierPhysicalArmorBonus()       return self:Value("extra_armor") end
function modifier_barghest_bite_extra:GetModifierMagicalResistanceBonus()   return self:Value("extra_mr") end
function modifier_barghest_bite_extra:GetModifierMoveSpeedBonus_Percentage() return self:Value("extra_ms_pct") end
function modifier_barghest_bite_extra:GetModifierPreAttack_BonusDamage()    return self:Value("extra_attack_damage") end
function modifier_barghest_bite_extra:GetModifierConstantHealthRegen()      return self:Value("extra_hp_regen") end
function modifier_barghest_bite_extra:GetModifierConstantManaRegen()        return self:Value("extra_mana_regen") end
function modifier_barghest_bite_extra:GetBonusDayVision()                   return self:Value("extra_vision") end
function modifier_barghest_bite_extra:GetBonusNightVision()                 return self:Value("extra_vision") end
