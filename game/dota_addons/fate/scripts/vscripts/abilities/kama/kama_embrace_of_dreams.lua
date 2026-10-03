require("abilities/kama/kama_shared")

kama_embrace_of_dreams = kama_embrace_of_dreams or class({})

--[[ W — Embrace of Dreams. Ставит клона в точку.
     Клон — НЕ иллюзия и не герой: неуязвимый некликабельный объект с моделью
     Камы (юнит kama_clone). Сам он ничего не делает, только повторяет Q —
     этим занимается kama_arrow_shot.
     Способность на зарядах. Заряды свои, а не движковые: попадания Q должны
     сокращать время восстановления, а у движковых зарядов такого доступа нет.
     Приказ атаки в землю рядом с клоном меняет Каму с ним местами.
]]

LinkLuaModifier("modifier_kama_embrace_charges", "abilities/kama/kama_embrace_of_dreams",
    LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kama_dream_clones", "abilities/kama/kama_embrace_of_dreams",
    LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kama_dream_clone", "abilities/kama/kama_embrace_of_dreams",
    LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kama_swap_blast_slow", "abilities/kama/kama_embrace_of_dreams",
    LUA_MODIFIER_MOTION_NONE)

-- Временный эффект взрыва: кольцо по радиусу (CP1 — цвет, CP2 — радиус и время).
local FX_BLAST = "particles/zlodemon/zlodemon_basic_circle.vpcf"

function kama_embrace_of_dreams:GetIntrinsicModifierName()
    return "modifier_kama_embrace_charges"
end

-- Значение по текущему уровню, а у ещё не выученной способности — по первому:
-- пассивка с зарядами создаётся раньше, чем способность получает уровень, а
-- GetSpecialValueFor на нулевом уровне отдаёт 0.
function kama_embrace_of_dreams:Value(sKey)
    return self:GetLevelSpecialValueFor(sKey, math.max(self:GetLevel() - 1, 0))
end

function kama_embrace_of_dreams:HasCharge()
    local caster = self:GetCaster()
    return caster:GetModifierStackCount("modifier_kama_embrace_charges", caster) > 0
end

--[[ Клик дальше дальности каста не заставляет Каму идти: клон просто встаёт
     на предельной дистанции (ClampPoint). Поэтому серверу дальность отдаём
     «бесконечную», а клиенту — настоящую из KV, чтобы круг дальности не врал. ]]
function kama_embrace_of_dreams:GetCastRange(vLocation, hTarget)
    if IsServer() then return 99999 end
    return self.BaseClass.GetCastRange(self, vLocation, hTarget)
end

-- Точка каста, поджатая к настоящей дальности (AbilityCastRange из KV).
function kama_embrace_of_dreams:ClampPoint(vPoint)
    local vOrigin = self:GetCaster():GetAbsOrigin()
    local vOffset = vPoint - vOrigin
    vOffset.z = 0
    local nRange = self.BaseClass.GetCastRange(self, vPoint, nil)
    if vOffset:Length2D() <= nRange then return vPoint end
    return vOrigin + vOffset:Normalized() * nRange
end

function kama_embrace_of_dreams:CastFilterResultLocation(vLocation)
    if not self:HasCharge() then return UF_FAIL_CUSTOM end
    if IsServer() and not IsInSameRealm(self:GetCaster():GetAbsOrigin(),
        self:ClampPoint(vLocation)) then
        return UF_FAIL_CUSTOM
    end
    return UF_SUCCESS
end

function kama_embrace_of_dreams:GetCustomCastErrorLocation(vLocation)
    if not self:HasCharge() then return "#dota_hud_error_no_charges" end
    return "#Must be in same realm"
end

function kama_embrace_of_dreams:OnSpellStart()
    local caster = self:GetCaster()
    local hCharges = caster:FindModifierByName("modifier_kama_embrace_charges")
    if hCharges then hCharges:Spend() end
    self:SpawnClone(self:ClampPoint(self:GetCursorPosition()))
end

--=========================================================================--
-- Клоны
--=========================================================================--

--[[ Живые клоны, от старого к новому. Возвращает сам список: кто собирается
     убирать клонов в цикле — пусть сначала снимет копию. ]]
function kama_embrace_of_dreams:GetClones()
    self.tClones = self.tClones or {}
    for i = #self.tClones, 1, -1 do
        if not Kama_Alive(self.tClones[i]) then table.remove(self.tClones, i) end
    end
    return self.tClones
end

function kama_embrace_of_dreams:SpawnClone(vPoint)
    local caster = self:GetCaster()
    local tClones = self:GetClones()

    -- лишний клон вытесняет самого старого
    while #tClones >= self:GetSpecialValueFor("max_clones") do
        self:RemoveClone(tClones[1], KAMA_CLONE_REPLACED)
    end

    local hClone = CreateUnitByName("kama_clone", GetGroundPosition(vPoint, nil), false,
        nil, nil, caster:GetTeamNumber())
    if not Kama_Alive(hClone) then return end

    hClone:SetForwardVector(caster:GetForwardVector())
    hClone:SetRenderColor(255, 170, 215)
    -- клон живёт ровно столько, сколько этот модификатор: он же его и убирает,
    -- и он же делает его неуязвимым и некликабельным
    local hLife = hClone:AddNewModifier(caster, self, "modifier_kama_dream_clone",
        {duration = self:GetSpecialValueFor("clone_duration")})
    if not hLife then
        hClone:RemoveSelf()
        return
    end

    table.insert(tClones, hClone)
    self:SyncCloneCount()
end

function kama_embrace_of_dreams:RemoveClone(hClone, nReason)
    self:ForgetClone(hClone)
    if not Kama_Alive(hClone) then return end
    local hModifier = hClone:FindModifierByName("modifier_kama_dream_clone")
    if hModifier then
        hModifier.nReason = nReason
        hModifier:Destroy()
    end
end

function kama_embrace_of_dreams:ForgetClone(hClone)
    local tClones = self.tClones or {}
    for i = #tClones, 1, -1 do
        if tClones[i] == hClone then table.remove(tClones, i) end
    end
    self:SyncCloneCount()
end

-- Число клонов держим в стаках модификатора на Каме: его читает клиент, когда
-- считает стоимость Q.
function kama_embrace_of_dreams:SyncCloneCount()
    local caster = self:GetCaster()
    local nClones = #self:GetClones()
    if nClones < 1 then
        caster:RemoveModifierByName("modifier_kama_dream_clones")
        return
    end
    local hModifier = caster:FindModifierByName("modifier_kama_dream_clones")
        or caster:AddNewModifier(caster, self, "modifier_kama_dream_clones", {})
    if hModifier then hModifier:SetStackCount(nClones) end
end

--=========================================================================--
-- Обмен местами
--=========================================================================--

--[[ Приказ атаки в землю в точке vPoint. Если рядом с точкой стоит клон —
     Кама встаёт на его место, клон исчезает, а там, где она стояла, хлопает
     небольшой взрыв. ]]
function kama_embrace_of_dreams:TrySwap(vPoint)
    local caster = self:GetCaster()
    if not caster:IsAlive() or caster:IsStunned() or caster:IsRooted()
        or caster:IsCommandRestricted() or IsLocked(caster) then
        return
    end

    local fNow = GameRules:GetGameTime()
    if fNow < (self.fSwapReadyAt or 0) then return end

    local hNearest, fNearest = nil, self:GetSpecialValueFor("swap_radius")
    for _, hClone in ipairs(self:GetClones()) do
        local fDistance = (hClone:GetAbsOrigin() - vPoint):Length2D()
        if fDistance <= fNearest then
            hNearest, fNearest = hClone, fDistance
        end
    end
    if not hNearest then return end

    local vFrom = caster:GetAbsOrigin()
    local vTo = hNearest:GetAbsOrigin()
    if (vTo - vFrom):Length2D() > self:GetSpecialValueFor("swap_range") then return end
    if not IsInSameRealm(vFrom, vTo) then return end

    self.fSwapReadyAt = fNow + self:GetSpecialValueFor("swap_cooldown")
    self:RemoveClone(hNearest, KAMA_CLONE_SWAPPED)
    ProjectileManager:ProjectileDodge(caster)
    FindClearSpaceForUnit(caster, vTo, true)
    self:SwapBlast(vFrom)
end

-- Взрыв на прежнем месте Камы. Срабатывает с задержкой blast_delay: всё это
-- время кольцо показывает, куда он придётся.
function kama_embrace_of_dreams:SwapBlast(vCenter)
    local caster = self:GetCaster()
    local fDelay = self:GetSpecialValueFor("blast_delay")

    local nFx = ParticleManager:CreateParticle(FX_BLAST, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(nFx, 0, vCenter)
    ParticleManager:SetParticleControl(nFx, 1, Vector(1, 0.4, 0.7))
    ParticleManager:SetParticleControl(nFx, 2,
        Vector(self:GetSpecialValueFor("blast_radius"), fDelay, 0))

    Timers:CreateTimer(fDelay, function()
        ParticleManager:DestroyParticle(nFx, false)
        ParticleManager:ReleaseParticleIndex(nFx)
        if not Kama_Alive(self) or not Kama_Alive(caster) then return end
        self:BlastHit(vCenter)
    end)
end

function kama_embrace_of_dreams:BlastHit(vCenter)
    local caster = self:GetCaster()
    local nRadius = self:GetSpecialValueFor("blast_radius")
    local nDamage = self:GetSpecialValueFor("blast_damage")
    local fPull = self:GetSpecialValueFor("blast_pull_duration")
    local fSlow = self:GetSpecialValueFor("blast_slow_duration")

    local tEnemies = FindUnitsInRadius(caster:GetTeamNumber(), vCenter, nil, nRadius,
        DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
    for _, hEnemy in pairs(tEnemies) do
        if Kama_Alive(hEnemy) and not IsSpellBlocked(hEnemy, caster) then
            DoDamage(caster, hEnemy, nDamage, self:GetAbilityDamageType(), 0, self, false)

            if Kama_Alive(hEnemy) and hEnemy:IsAlive() then
                self:PullToward(hEnemy, vCenter, fPull)
                if not IsImmuneToSlow(hEnemy) then
                    hEnemy:AddNewModifier(caster, self, "modifier_kama_swap_blast_slow",
                        {duration = fSlow})
                end
            end
        end
    end
end

-- modifier_knockback толкает ОТ центра, поэтому центр ставим за спиной цели —
-- тогда её тянет к точке (так же сделано у Cu Alter).
function kama_embrace_of_dreams:PullToward(hUnit, vPoint, fDuration)
    if IsKnockbackImmune(hUnit) then return end
    local vUnit = hUnit:GetAbsOrigin()
    local vDirection = vPoint - vUnit
    vDirection.z = 0
    local fDistance = vDirection:Length2D()
    if fDistance < 1 then return end
    vDirection = vDirection:Normalized()

    local vBehind = vUnit - vDirection * 100
    hUnit:RemoveModifierByName("modifier_knockback")
    hUnit:AddNewModifier(self:GetCaster(), self, "modifier_knockback", {
        should_stun        = false,
        knockback_duration = fDuration,
        duration           = fDuration,
        knockback_distance = fDistance,
        knockback_height   = 0,
        center_x           = vBehind.x,
        center_y           = vBehind.y,
        center_z           = vBehind.z,
    })
end

--=========================================================================--
-- Заряды. Стаки = сколько зарядов есть; длительность модификатора показывает,
-- сколько осталось до следующего. Заодно ловит приказ атаки для обмена.
--=========================================================================--
modifier_kama_embrace_charges = class({})

function modifier_kama_embrace_charges:IsHidden()        return false end
function modifier_kama_embrace_charges:IsPurgable()      return false end
function modifier_kama_embrace_charges:RemoveOnDeath()   return false end
function modifier_kama_embrace_charges:DestroyOnExpire() return false end
function modifier_kama_embrace_charges:GetAttributes()   return MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_kama_embrace_charges:OnCreated()
    if not IsServer() then return end
    self:SetStackCount(self:GetAbility():Value("max_charges"))
    self:StartIntervalThink(0.1)
end

function modifier_kama_embrace_charges:DeclareFunctions()
    return {MODIFIER_EVENT_ON_ORDER}
end

function modifier_kama_embrace_charges:OnOrder(keys)
    if not IsServer() or keys.unit ~= self:GetParent() then return end
    if keys.order_type ~= DOTA_UNIT_ORDER_ATTACK_MOVE or not keys.new_pos then return end
    self:GetAbility():TrySwap(keys.new_pos)
end

function modifier_kama_embrace_charges:OnIntervalThink()
    if self.fReadyAt and GameRules:GetGameTime() >= self.fReadyAt then
        self:GainCharge()
    end
end

function modifier_kama_embrace_charges:Spend()
    self:DecrementStackCount()
    if not self.fReadyAt then self:BeginRecharge() end
    self:SyncCooldown()
end

function modifier_kama_embrace_charges:BeginRecharge()
    local fRestore = self:GetAbility():Value("charge_restore_time")
    self.fReadyAt = GameRules:GetGameTime() + fRestore
    self:SetDuration(fRestore, true)
end

function modifier_kama_embrace_charges:GainCharge()
    self:IncrementStackCount()
    if self:GetStackCount() < self:GetAbility():Value("max_charges") then
        self:BeginRecharge()
    else
        self.fReadyAt = nil
        self:SetDuration(-1, true)
    end
    self:SyncCooldown()
end

-- Попадание Q сокращает время до следующего заряда.
function modifier_kama_embrace_charges:Reduce(fSeconds)
    if not self.fReadyAt then return end
    self.fReadyAt = self.fReadyAt - fSeconds
    local fLeft = self.fReadyAt - GameRules:GetGameTime()
    if fLeft <= 0 then
        self:GainCharge()
    else
        self:SetDuration(fLeft, true)
        self:SyncCooldown()
    end
end

-- Печать Мастера обновляет способности: заряды возвращаются все.
function modifier_kama_embrace_charges:Refill()
    self:SetStackCount(self:GetAbility():Value("max_charges"))
    self.fReadyAt = nil
    self:SetDuration(-1, true)
    self:SyncCooldown()
end

-- Без зарядов сама способность показывает кулдаун до ближайшего заряда.
function modifier_kama_embrace_charges:SyncCooldown()
    local hAbility = self:GetAbility()
    hAbility:EndCooldown()
    if self:GetStackCount() < 1 and self.fReadyAt then
        hAbility:StartCooldown(math.max(self.fReadyAt - GameRules:GetGameTime(), 0.1))
    end
end

--=========================================================================--
-- Счётчик живых клонов на Каме (стаки). Виден игроку: от него зависит цена Q.
modifier_kama_dream_clones = class({})

function modifier_kama_dream_clones:IsHidden()      return false end
function modifier_kama_dream_clones:IsPurgable()    return false end
function modifier_kama_dream_clones:RemoveOnDeath() return false end

--=========================================================================--
-- Висит на самом клоне: отмеряет его время и следит за дистанцией до Камы.
modifier_kama_dream_clone = class({})

function modifier_kama_dream_clone:IsHidden()   return true end
function modifier_kama_dream_clone:IsPurgable() return false end

-- Те же состояния, что даёт dummy_unit_passive, но БЕЗ FLYING: с ним клон
-- всплывал в воздух, стоило ему повернуться для выстрела.
function modifier_kama_dream_clone:CheckState()
    return {
        [MODIFIER_STATE_UNSELECTABLE]      = true,
        [MODIFIER_STATE_INVULNERABLE]      = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP]    = true,
        [MODIFIER_STATE_NO_HEALTH_BAR]     = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end

function modifier_kama_dream_clone:OnCreated()
    if not IsServer() then return end
    self:StartIntervalThink(0.25)
end

function modifier_kama_dream_clone:OnIntervalThink()
    local hAbility = self:GetAbility()
    local hKama = self:GetCaster()
    if not Kama_Alive(hAbility) or not Kama_Alive(hKama) then
        self.nReason = KAMA_CLONE_LOST
        self:Destroy()
        return
    end

    local hParent = self:GetParent()
    local fDistance = (hKama:GetAbsOrigin() - hParent:GetAbsOrigin()):Length2D()
    if fDistance > hAbility:GetSpecialValueFor("clone_leash") then
        hAbility:RemoveClone(hParent, KAMA_CLONE_LOST)
    end
end

-- self.nReason — почему клон исчез (KAMA_CLONE_*); nil значит «вышло время».
function modifier_kama_dream_clone:OnDestroy()
    if not IsServer() then return end
    local hParent = self:GetParent()
    local hAbility = self:GetAbility()
    if Kama_Alive(hAbility) then hAbility:ForgetClone(hParent) end
    if not Kama_Alive(hParent) then return end

    -- сам юнит убираем кадром позже: OnDestroy может идти и оттого, что юнит
    -- уже удаляют, а второй RemoveSelf по нему недопустим
    hParent:AddNoDraw()
    Timers:CreateTimer(0, function()
        if Kama_Alive(hParent) then hParent:RemoveSelf() end
    end)
end

--=========================================================================--
-- Короткое замедление от взрыва при обмене.
modifier_kama_swap_blast_slow = class({})

function modifier_kama_swap_blast_slow:IsHidden()      return false end
function modifier_kama_swap_blast_slow:IsDebuff()      return true end
function modifier_kama_swap_blast_slow:IsPurgable()    return true end
function modifier_kama_swap_blast_slow:RemoveOnDeath() return true end

function modifier_kama_swap_blast_slow:DeclareFunctions()
    return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_kama_swap_blast_slow:GetModifierMoveSpeedBonus_Percentage()
    return -self:GetAbility():GetSpecialValueFor("blast_slow")
end
