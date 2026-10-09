--[[ Trickshot (Q) — выстрел в точку с рикошетом.
     Пуля летит к выбранной точке (не дальше range) и ранит всех на пути, от точки
     отскакивает в ближайшего врага в ricochet_range, оттуда — дальше по цепочке.
     Рикошетов base_ricochets, с включённой D (bullet_cost пуль) ещё extra_ricochets.
     Рикошет бьёт тем же уроном, что и линия (падения урона нет — юзер 09.10.2026). Пуля прошивает всех на
     линии насквозь; рикошет из точки прилёта уходит в ближайшего — в том числе в
     прошитого по пути, — но в одну цель дважды рикошетом не бьёт.
     Атрибуты: Here Is an Old Trick (−head_cdr КД, числа хедшота живут здесь),
     Natural Perception (+физ. урон за ловкость на каждое попадание).
     Здесь же окно комбо: Q с автокастом при 30/30/30 → R на 3 с меняется на комбо. ]]
require("abilities/billy/billy_shared")

billy_trickshot = billy_trickshot or class({})
LinkLuaModifier("modifier_billy_combo_switch", "abilities/billy/billy_trickshot", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_ricochet_anchor", "abilities/billy/billy_trickshot", LUA_MODIFIER_MOTION_NONE)

function billy_trickshot:GetCooldown(level)
    local cd = self.BaseClass.GetCooldown(self, level)
    if Billy_HasAttr(self:GetCaster(), 3) then
        cd = cd - self:GetSpecialValueFor("head_cdr")
    end
    return cd
end

function billy_trickshot:CheckCombo()
    local caster = self:GetCaster()
    local num = 29.1
    if caster:GetStrength() >= num and caster:GetAgility() >= num and caster:GetIntellect() >= num then
        local combo = caster:FindAbilityByName("billy_combo")
        if combo and combo:IsCooldownReady() then
            return true
        end
    end
    return false
end


function billy_trickshot:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    Billy_QuickTurn(caster, self)          -- выстрелил — быстро разворачивается

    if self:GetAutoCastState() and self:CheckCombo() then
        caster:AddNewModifier(caster, self, "modifier_billy_combo_switch", { duration = 3 })
    end

    local dir = self:GetCursorPosition() - origin
    dir.z = 0
    -- после Skedaddle (E) дальность больше на дальность рывка
    local range = self:GetSpecialValueFor("range") + Billy_RangeBonus(caster)
    local dist = math.min(dir:Length2D(), range)
    if dist < 1 then
        dir = caster:GetForwardVector()
        dist = range
    end
    dir = dir:Normalized()

    local empowered = Billy_TrySpend(caster, self:GetSpecialValueFor("bullet_cost"))
    local ricochets = self:GetSpecialValueFor("base_ricochets")
    if empowered then
        ricochets = ricochets + self:GetSpecialValueFor("extra_ricochets")
    end

    self.casts = self.casts or {}
    self.castCounter = (self.castCounter or 0) + 1
    local id = self.castCounter
    -- d: выстрел под D — у всей цепочки пуля/трейл BILLY_FX.d и оранжевые всплески
    self.casts[id] = { lineHit = {}, ricoHit = {}, ricochetsLeft = ricochets, damage = self:GetSpecialValueFor("damage"),
        d = empowered }
    -- страховка: если цепочка оборвалась без колбэка (цель исчезла), запись не висит вечно
    Timers:CreateTimer(10, function()
        if IsNotNull(self) and self.casts then self.casts[id] = nil end
    end)

    local speed = self:GetSpecialValueFor("speed")
    local width = self:GetSpecialValueFor("width")
    -- пуля (частица) летит от дула В ЗЕМЛЮ в точке выстрела; снаряд — горизонтально по линии
    local landing = GetGroundPosition(origin + dir * dist, nil)
    Billy_LinearShot({
        Ability          = self,
        vSpawnOrigin     = Billy_GunOrigin(caster),
        vFxEnd           = landing,
        fDistance        = dist,
        fStartRadius     = width,
        fEndRadius       = width,
        Source           = caster,
        bHasFrontalCone  = false,
        iUnitTargetTeam  = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        iUnitTargetType  = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        vVelocity        = dir * speed,
        ExtraData        = { cast = id, stage = 0 },
    }, empowered and BILLY_FX.d or nil)
    Billy_FxMuzzle(caster, dir)
    caster:EmitSound(BILLY_SND.shot)
    -- голос не на каждый выстрел: КД 6 с, иначе фраза надоедает
    if RandomFloat(0, 1) < self:GetSpecialValueFor("vo_chance") / 100 then
        caster:EmitSound("billy_vo_trickshot")
    end
end

-- from — откуда прилетела пуля (Билли или точка рикошета): кровь брызжет прочь от неё.
function billy_trickshot:HitTarget(cast, target, stage, from)
    local caster = self:GetCaster()
    if stage == 0 then
        cast.lineHit[target:entindex()] = true
    else
        cast.ricoHit[target:entindex()] = true
    end
    Billy_FxImpact(target, "s", from or caster:GetAbsOrigin(), cast.d)
    local damage = cast.damage
    Billy_Damage(caster, target, damage, DAMAGE_TYPE_PHYSICAL, self)
    if Billy_HasAttr(caster, 5) and IsNotNull(target) and target:IsAlive() then
        DoDamage(caster, target, caster:GetAgility() * self:GetSpecialValueFor("np_agi_damage"),
            DAMAGE_TYPE_PHYSICAL, 0, self, false)
    end
end

-- Следующее звено цепочки: ближайший ещё не задетый враг вокруг from.
function billy_trickshot:Ricochet(id, cast, from, stage, fromUnit)
    if cast.ricochetsLeft <= 0 then
        self.casts[id] = nil
        return
    end
    local caster = self:GetCaster()
    local units = FindUnitsInRadius(caster:GetTeamNumber(), from, nil,
        self:GetSpecialValueFor("ricochet_range"), DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        FIND_CLOSEST, false)
    local nextTarget
    for _, u in ipairs(units) do
        -- в туман рикошет летит, в НЕВИДИМОСТЬ — нет (как Ambush Хассана; юзер 09.10.2026).
        -- Невидимку, которого команда Билли видит (просвет), берёт.
        if not cast.ricoHit[u:entindex()] and u:IsAlive() and not Billy_ArrowProof(u)
            and not (u:IsInvisible() and not caster:CanEntityBeSeenByMyTeam(u)) then
            nextTarget = u
            break
        end
    end
    if not nextTarget then
        self.casts[id] = nil
        return
    end
    cast.ricochetsLeft = cast.ricochetsLeft - 1
    -- ⚠️ при Source = герой vSourceLoc игнорируется и пуля летит ОТ ГЕРОЯ (ловилось в
    -- игре): источник — якорь-думалка в точке остановки пули, живёт пару секунд
    -- (звено из цели — из её груди: attach_hitloc; из точки — якорь, поднятый на высоту
    -- пули, иначе пуля вылетает из земли: у пустой думалки нет аттачей)
    local source = IsNotNull(fromUnit) and fromUnit or nil
    local startPos
    if source then
        startPos = Billy_HitPos(source)
    else
        source = CreateModifierThinker(caster, self, "modifier_billy_ricochet_anchor",
            { duration = 2 }, from, caster:GetTeamNumber(), false)
        startPos = GetGroundPosition(from, nil) + Vector(0, 0, 90)
        source:SetAbsOrigin(startPos)
    end
    -- снаряд невидимый, пулю рисуем сами прямой от точки отскока в грудь цели: пуля
    -- линейная (скорость из CP1), самонаводящимся EffectName она летела вбок
    local speed = self:GetSpecialValueFor("ricochet_speed")
    local delta = Billy_HitPos(nextTarget) - startPos
    local len = delta:Length()
    local bfx = len > 1 and Billy_BulletFx(cast.d and BILLY_FX.d.bullet or BILLY_FX.bullet_ricochet, startPos,
        delta * (speed / len), len / speed, cast.d and BILLY_FX.d.trail or nil) or nil
    ProjectileManager:CreateTrackingProjectile({
        Target          = nextTarget,
        Source          = source,
        -- у думалки (invisiblebox) нет attach_hitloc: снаряд из неё ругался «Missing
        -- Attachment» — из якоря стартуем без аттача (его origin поднят на высоту пули),
        -- из цели — из её груди
        iSourceAttachment = fromUnit and DOTA_PROJECTILE_ATTACHMENT_HITLOCATION or (DOTA_PROJECTILE_ATTACHMENT_NONE or 0),
        Ability         = self,
        EffectName      = "",
        iMoveSpeed      = speed,
        bDodgeable      = false,
        -- пуля даёт обзор, пока летит (юзер 06.10.2026)
        bProvidesVision   = true,
        iVisionRadius     = BILLY_BULLET_VISION,
        iVisionTeamNumber = caster:GetTeamNumber(),
        ExtraData       = { cast = id, stage = stage, bfx = bfx, fx = startPos.x, fy = startPos.y },
    })
    EmitSoundOnLocationWithCaster(from, BILLY_SND.ricochet, caster)
end

function billy_trickshot:OnProjectileHit_ExtraData(target, location, data)
    local id = data.cast
    local cast = self.casts and self.casts[id]
    if not cast then
        Billy_BulletEnd(data.bfx, target)
        return true
    end

    if data.stage == 0 then
        -- линия: ранит всех на пути, на конце (target == nil) уходит в рикошет
        if target then
            if Billy_ArrowProof(target) then return false end   -- пролетает сквозь
            if not cast.lineHit[target:entindex()] then
                self:HitTarget(cast, target, 0)
            end
            return false
        end
        Billy_BulletEnd(data.bfx, target)
        -- пуля ударила в землю: землистый дымок, а не вспышка (под D — оранжевый всплеск)
        local back = self:GetCaster():GetAbsOrigin() - location
        back.z = 0
        Billy_FxDust(location, cast.d, back:Length2D() > 1 and back:Normalized() or nil)
        self:Ricochet(id, cast, GetGroundPosition(location, nil), 1)
        return true
    end

    Billy_BulletEnd(data.bfx, target)
    -- цель включила Protection from Arrows, пока к ней летел рикошет: пуля не берёт, цепочка кончилась
    if not target or not IsNotNull(target) or Billy_ArrowProof(target) then
        self.casts[id] = nil
        return true
    end
    local from = target:GetAbsOrigin()
    self:HitTarget(cast, target, data.stage, data.fx and Vector(data.fx, data.fy, from.z))
    self:Ricochet(id, cast, from, data.stage + 1, target)
    return true
end

---------------------------------------------------------------------------------------------------
-- Окно комбо: пока висит, на месте Highnoon (R, индекс 5) стоит комбо Thunderer.
-- Повторяет modifier_cu_alter_combo_switch.
modifier_billy_combo_switch = modifier_billy_combo_switch or class({})

function modifier_billy_combo_switch:IsHidden()      return false end
function modifier_billy_combo_switch:IsPurgable()    return false end
function modifier_billy_combo_switch:RemoveOnDeath() return true end

if IsServer() then
    function modifier_billy_combo_switch:OnCreated()
        local caster = self:GetParent()
        local r = caster:GetAbilityByIndex(5)
        if r and r:GetName() == "billy_highnoon" then
            caster:SwapAbilities("billy_highnoon", "billy_combo", false, true)
        end
    end

    function modifier_billy_combo_switch:OnDestroy()
        local caster = self:GetParent()
        local r = caster:GetAbilityByIndex(5)
        if r and r:GetName() == "billy_combo" then
            caster:SwapAbilities("billy_highnoon", "billy_combo", true, false)
        end
    end
end

---------------------------------------------------------------------------------------------------
-- Якорь рикошета: пустая думалка, из которой вылетает следующее звено цепочки.
modifier_billy_ricochet_anchor = modifier_billy_ricochet_anchor or class({})
function modifier_billy_ricochet_anchor:IsHidden() return true end
