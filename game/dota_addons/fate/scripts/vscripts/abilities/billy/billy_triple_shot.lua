--[[ Shatter Shot (W) — крупная пуля летит на range со скоростью speed и прошивает
     насквозь всех на пути (каждого — один раз): урон damage.
     Пока она летит, повторное нажатие W — мгновенно, без замаха и маны — Билли стреляет
     в саму пулю: она разбивается на pellets дробинок конусом cone_angle на pellet_range,
     из своей точки по направлению полёта. Не нажал — пуля САМА разрывается на range
     (юзер 08.10.2026; раньше просто гасла).

     Рекаст и пинг (08.10.2026):
       * рекаст делает фильтр приказов (BillyTripleShotOrderFilter из ExecuteOrderFilter):
         любой каст W, пока пуля летит, — разрыв, какого бы типа ни был приказ. Клиент
         узнаёт, что W стала «мгновенной» (стаки RECAST), только через пинг, и в это окно
         присылает точечный каст — раньше это был новый выстрел. Каст без цели, когда пуля
         уже разорвалась (клиент ещё видел её летящей), отбрасывается — без случайного
         нового выстрела;
       * компенсации пинга (отката точки разрыва) НЕТ — юзер не захотел: дробь вылетает
         из серверной точки пули в момент прихода приказа.
     Дробинка гаснет на первом враге: урон pellet_damage + стак замедления (до
     slow_max_stacks, каждое попадание обновляет время).
     С включённой D пули (bullet_cost) списываются на КАСТЕ (юзер 09.10.2026; раньше —
     на разрыве), и пуля запоминает, была ли выстрелена с пулей: тогда она оранжевая, а её
     дробинки ещё бьют d_max_hp_pct% от макс. хп и вешают dimensional lock — даже если D
     выключили или пули кончились, пока она летела.

     ⚠️ Крупная пуля — НЕ снаряд движка, а думалка (CreateModifierThinker), которую
     двигаем сами: обрыв линейного снаряда посреди полёта (DestroyLinearProjectile) в
     рантайме чреват крашем. Думалка удаляется движком вместе со своим модификатором.
     Дробинки — обычные линейные снаряды: их никто не обрывает, гаснут сами (return true).

     Кулдаун: первый выстрел движок ставит на кулдаун — снимаем (EndCooldown), иначе
     рекаст недоступен. Ставим его руками, когда пуля разорвалась (рекастом или сама).
     «Пуля в полёте» — стаки modifier_billy_triple_shot_recast на Билли: их видит и
     клиент, по ним GetBehavior/GetCastPoint/GetManaCost переключают W на мгновенный
     рекаст (приём barghest_q). ]]
require("abilities/billy/billy_shared")

billy_triple_shot = billy_triple_shot or class({})
LinkLuaModifier("modifier_billy_triple_shot_bullet", "abilities/billy/billy_triple_shot", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_triple_shot_recast", "abilities/billy/billy_triple_shot", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_triple_shot_slow",   "abilities/billy/billy_triple_shot", LUA_MODIFIER_MOTION_NONE)

local RECAST = "modifier_billy_triple_shot_recast"
local FX_MAX_SIDE = 40   -- насколько частица пули может стартовать вбок от линии попадания (ширина 100)
local FX_MAX_FWD  = 80   -- и вперёд от центра тела

-- ⚠️ Считается и на клиенте: только GetModifierStackCount (FindModifierByName там нет).
function billy_triple_shot:IsRecast()
    local caster = self:GetCaster()
    if caster == nil or type(caster.GetModifierStackCount) ~= "function" then return false end
    return (caster:GetModifierStackCount(RECAST, caster) or 0) > 0
end

function billy_triple_shot:GetBehavior()
    if self:IsRecast() then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
             + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
    end
    return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_DIRECTIONAL
         + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
end

-- ⚠️ Раз метод переопределён, он решает всё: AbilityCastPoint в KV — только для тултипа,
-- держать равным cast_point (как у barghest_q).
function billy_triple_shot:GetCastPoint()
    if self:IsRecast() then return 0 end
    return self:GetSpecialValueFor("cast_point")
end

function billy_triple_shot:GetManaCost(level)
    if self:IsRecast() then return 0 end
    return self.BaseClass.GetManaCost(self, level)
end

function billy_triple_shot:OnSpellStart()
    if self:IsRecast() then
        self:Shatter()
        return
    end

    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local dir = self:GetCursorPosition() - origin
    dir.z = 0
    if dir:Length2D() < 1 then dir = caster:GetForwardVector() end
    dir = dir:Normalized()

    local gun = Billy_GunOrigin(caster)
    local start = Vector(origin.x, origin.y, gun.z)
    -- после Skedaddle (E) дальность больше на дальность рывка
    local range = self:GetSpecialValueFor("range") + Billy_RangeBonus(caster)
    local life = range / self:GetSpecialValueFor("speed")

    Billy_FxMuzzle(caster, dir)
    caster:EmitSound(BILLY_SND.shot)
    caster:EmitSound("billy_vo_triple_shot")
    Billy_QuickTurn(caster, self)          -- выстрелил — быстро разворачивается

    -- Пули под D списываются здесь, на касте (юзер 09.10.2026), и пуля запоминает итог:
    -- оранжевая (как пули остальных скиллов под D) и с усиленной дробью на разрыве.
    local armed = Billy_TrySpend(caster, self:GetSpecialValueFor("bullet_cost"))

    -- счётчик попаданий этого каста (пуля + дробь) по каждой цели — см. TakeHit
    self.castCounter = (self.castCounter or 0) + 1
    local castId = self.castCounter
    self.castHits = self.castHits or {}
    self.castHits[castId] = {}
    Timers:CreateTimer(10, function()
        if IsNotNull(self) and self.castHits then self.castHits[castId] = nil end
    end)

    -- Пуля стартует из дула (красиво), а летит в конечную точку линии из центра тела (удобно:
    -- куда целился, туда и прилетит, где бы ни был револьвер). Смещение дула от линии — вбок
    -- не больше FX_MAX_SIDE, вперёд не больше FX_MAX_FWD. Механика и частица идут по этому
    -- одному пути (modifier_billy_triple_shot_bullet), разрыв — там, где видна пуля.
    local rel = gun - start
    rel.z = 0
    local along = rel:Dot(dir)
    local side = rel - dir * along
    if side:Length2D() > FX_MAX_SIDE then side = side:Normalized() * FX_MAX_SIDE end
    local fxStart = start + dir * math.min(math.max(along, 0), FX_MAX_FWD) + side

    -- duration — страховка: модификатор сам гасит себя, долетев до range
    local thinker = CreateModifierThinker(caster, self, "modifier_billy_triple_shot_bullet", {
        duration = life + 0.2,
        cast = castId,
        fxx = fxStart.x, fxy = fxStart.y, fxz = fxStart.z,
        d = armed and 1 or 0,
        dx = dir.x, dy = dir.y, range = range,
        sx = start.x, sy = start.y, sz = start.z,
    }, start, caster:GetTeamNumber(), false)
    self.bullet = thinker and thinker:FindModifierByName("modifier_billy_triple_shot_bullet")
    if not self.bullet then return end

    -- длительность ≈ время полёта: значок на Билли показывает, когда пуля разорвётся.
    -- С запасом в пару кадров: снимает его сам разрыв, и W не станет «первым выстрелом»
    -- раньше, чем пуля разорвалась.
    caster:AddNewModifier(caster, self, RECAST, { duration = life + 2 * FrameTime() })
    self:EndCooldown()
end

-- Рекаст: выстрел в летящую пулю.
function billy_triple_shot:Shatter()
    local bullet = self.bullet
    if not IsNotNull(bullet) then return end
    bullet:Burst(true)
end

-- Рекаст из фильтра приказов: те же проверки, что сделал бы движок для мгновенного
-- каста без маны. Возвращает true, если пуля разорвана.
function billy_triple_shot:TryRecast()
    local caster = self:GetCaster()
    if not IsNotNull(self.bullet) or not IsNotNull(caster) or not caster:IsAlive() then return false end
    if caster:IsStunned() or caster:IsSilenced() or caster:IsHexed() or caster:IsCommandRestricted() then
        return false
    end
    self:Shatter()
    return true
end

-- Вызывается из FateGameMode:ExecuteOrderFilter. false — приказ съеден.
function BillyTripleShotOrderFilter(unit, ability, order)
    if order ~= DOTA_UNIT_ORDER_CAST_POSITION and order ~= DOTA_UNIT_ORDER_CAST_NO_TARGET then return true end
    if not IsNotNull(ability) or type(ability.GetAbilityName) ~= "function"
        or ability:GetAbilityName() ~= "billy_triple_shot" then return true end
    if IsNotNull(ability.bullet) then
        ability:TryRecast()           -- пуля летит: любой каст W — разрыв
        return false
    end
    -- пули нет, а приказ «без цели» — клиент ещё считал W рекастом; не стреляем заново
    return order ~= DOTA_UNIT_ORDER_CAST_NO_TARGET
end

-- Не больше max_hits попаданий одного каста (крупная пуля + дробь) по одной цели (юзер
-- 09.10.2026: чтобы дроби можно было дать нормальный урон без ваншота всеми шестью).
-- false — цель своё уже получила: пуля/дробинка проходит сквозь неё.
function billy_triple_shot:TakeHit(castId, unit)
    local hits = self.castHits and self.castHits[castId]
    if not hits then return true end
    local id = unit:entindex()
    local n = hits[id] or 0
    if n >= self:GetSpecialValueFor("max_hits") then return false end
    hits[id] = n + 1
    return true
end

-- recast — Билли стреляет в пулю (вспышка у дула, его выстрел); авторазрыв на конце
-- пути — без этого. castId — каст, к которому относится пуля (счётчик попаданий).
-- empowered — пуля выстрелена с пулей D (решено и списано на касте).
function billy_triple_shot:FirePellets(pos, dir, recast, castId, empowered)
    local caster = self:GetCaster()
    local count = math.max(1, self:GetSpecialValueFor("pellets"))
    local step = count > 1 and self:GetSpecialValueFor("cone_angle") / (count - 1) or 0
    local half = (count - 1) / 2
    local range = self:GetSpecialValueFor("pellet_range")
    local width = self:GetSpecialValueFor("pellet_width")
    local speed = self:GetSpecialValueFor("pellet_speed")

    -- Билли стреляет в пулю: вспышка у дула в её сторону и вспышка на самой пуле
    if recast then
        Billy_FxMuzzle(caster, pos - caster:GetAbsOrigin())
        caster:EmitSound(BILLY_SND.shot)
        Billy_QuickTurn(caster, self)      -- выстрел в пулю — тоже выстрел Билли
    end
    local flash = ParticleManager:CreateParticle(BILLY_FX.gunflash, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleShouldCheckFoW(flash, false)
    ParticleManager:SetParticleControl(flash, 0, pos)
    ParticleManager:SetParticleControl(flash, 3, pos)
    ParticleManager:SetParticleControlForward(flash, 3, dir)
    ParticleManager:ReleaseParticleIndex(flash)
    EmitSoundOnLocationWithCaster(pos, BILLY_SND.multi, caster)

    for i = 0, count - 1 do
        local d = Billy_RotateDir(dir, (i - half) * step)
        Billy_LinearShot({
            Ability           = self,
            vSpawnOrigin      = pos,
            fDistance         = range,
            fStartRadius      = width,
            fEndRadius        = width,
            Source            = caster,
            bHasFrontalCone   = false,
            iUnitTargetTeam   = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags  = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
            iUnitTargetType   = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            vVelocity         = d * speed,
            ExtraData         = { d = empowered and 1 or 0, fx = pos.x, fy = pos.y, cast = castId },
        }, empowered and BILLY_FX.d or nil)
    end
end

-- Попадание дробинки (крупная пуля снарядом движка не летает).
function billy_triple_shot:OnProjectileHit_ExtraData(target, location, data)
    if target and Billy_ArrowProof(target) then return false end   -- пролетает сквозь
    if target and IsNotNull(target) and not self:TakeHit(data.cast, target) then return false end
    Billy_BulletEnd(data.bfx, target)
    if not target or not IsNotNull(target) or not target:IsAlive() then return true end
    local caster = self:GetCaster()
    local d = data.d == 1

    Billy_FxImpact(target, "s", Vector(data.fx or 0, data.fy or 0, 0), d)
    local damage = self:GetSpecialValueFor("pellet_damage")
    if d then
        damage = damage + target:GetMaxHealth() * self:GetSpecialValueFor("d_max_hp_pct") / 100
    end
    Billy_Damage(caster, target, damage, DAMAGE_TYPE_PHYSICAL, self)

    if IsNotNull(target) and target:IsAlive() then
        if not IsImmuneToSlow(target) then
            local m = target:AddNewModifier(caster, self, "modifier_billy_triple_shot_slow",
                { duration = self:GetSpecialValueFor("slow_duration") })
            if m and m:GetStackCount() < self:GetSpecialValueFor("slow_max_stacks") then
                m:IncrementStackCount()
            end
        end
        if d then
            giveUnitDataDrivenModifier(caster, target, "locked", self:GetSpecialValueFor("d_lock_duration"))
        end
    end
    return true
end

---------------------------------------------------------------------------------------------------
-- Крупная пуля: модификатор думалки. Положение считаем от времени (не накапливаем шаги),
-- попадания — отрезком от прошлой точки до новой, каждого юнита один раз.
-- Частица — Billy_BulletFx (массивная пуля комбо): летит сама со скоростью из CP1,
-- думалка с ней совпадает по времени; на разрыве гасим её Billy_BulletEnd.
modifier_billy_triple_shot_bullet = modifier_billy_triple_shot_bullet or class({})

function modifier_billy_triple_shot_bullet:IsHidden()   return true end
function modifier_billy_triple_shot_bullet:IsPurgable() return false end

function modifier_billy_triple_shot_bullet:OnCreated(args)
    if not IsServer() then return end
    local ability = self:GetAbility()
    self.dir    = Vector(args.dx, args.dy, 0):Normalized()   -- направление каста (конус дроби)
    self.castId = args.cast
    self.armed  = args.d == 1                                -- выстрел с пулей D (списана на касте)
    self.speed  = ability:GetSpecialValueFor("speed")
    self.range  = args.range or ability:GetSpecialValueFor("range")
    self.width  = ability:GetSpecialValueFor("width")
    self.damage = ability:GetSpecialValueFor("damage")
    self.life   = self.range / self.speed
    -- ОДИН путь для механики и частицы: от дула (args.fx*, смещение ограничено) в конечную
    -- точку линии из центра тела, за то же время. Раньше механика шла из центра, а частица
    -- из дула — при раннем разрыве дробь вылетала не там, где видна пуля («телепорт»).
    local center = Vector(args.sx, args.sy, args.sz)
    self.from   = args.fxx and Vector(args.fxx, args.fxy, args.fxz) or center
    self.vel    = (center + self.dir * self.range - self.from) * (1 / self.life)
    self.t0     = GameRules:GetGameTime()
    self.pos    = self.from
    self.hit    = {}
    local fx = self.armed and BILLY_FX.combo_d or { bullet = BILLY_FX.combo_bullet, trail = BILLY_FX.combo_trail }
    self.bfx    = Billy_BulletFx(fx.bullet, self.from, self.vel, self.life, fx.trail)
    self:StartIntervalThink(FrameTime())
end

-- Довести пулю до текущего момента; true — долетела до range.
function modifier_billy_triple_shot_bullet:Advance()
    local t = math.min(GameRules:GetGameTime() - self.t0, self.life)
    local pos = self.from + self.vel * t
    local caster, ability = self:GetCaster(), self:GetAbility()
    if IsNotNull(caster) and IsNotNull(ability) then
        local units = FATE_FindUnitsInLine(caster:GetTeamNumber(), self.pos, pos, self.width,
            DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
        for _, unit in pairs(units) do
            local id = unit:entindex()
            if not self.hit[id] and IsNotNull(unit) and unit:IsAlive() and not Billy_ArrowProof(unit)
                and ability:TakeHit(self.castId, unit) then
                self.hit[id] = true
                Billy_FxImpact(unit, "s", self.from)
                Billy_Damage(caster, unit, self.damage, DAMAGE_TYPE_PHYSICAL, ability)
            end
        end
        AddFOWViewer(caster:GetTeamNumber(), pos, BILLY_BULLET_VISION, 0.2, false)
    end
    self.pos = pos
    local parent = self:GetParent()
    if IsNotNull(parent) then parent:SetAbsOrigin(pos) end
    return t >= self.life
end

function modifier_billy_triple_shot_bullet:OnIntervalThink()
    if self:Advance() then self:Burst(false) end   -- долетела до range — разрыв сам
end

-- Разрыв: добить путь до этого момента, дробь — из текущей точки пули, погасить пулю.
-- recast — Билли выстрелил в неё (вспышка у дула), иначе разрыв сам на конце пути.
function modifier_billy_triple_shot_bullet:Burst(recast)
    if self.burst then return end
    self:Advance()
    self.burst = true
    local ability = self:GetAbility()
    if IsNotNull(ability) then ability:FirePellets(self.pos, self.dir, recast, self.castId, self.armed) end
    self:Destroy()
end

function modifier_billy_triple_shot_bullet:OnDestroy()
    if not IsServer() then return end
    -- разрыв — гасим сразу (трейл тает); погасла без разрыва (страховочная duration) —
    -- частицу уже остановил CP5
    if self.burst then Billy_BulletStop(self.bfx) else Billy_BulletEnd(self.bfx) end
    local ability = self:GetAbility()
    if not IsNotNull(ability) or ability.bullet ~= self then return end
    ability.bullet = nil
    local caster = self:GetCaster()
    if IsNotNull(caster) then caster:RemoveModifierByName(RECAST) end
    -- КД — с учётом интеллекта (GetEffectiveCooldown). Пока пуля летела, W не на КД, и
    -- сбросы КД в это время копятся на пуле: печать Мастера (BillyOnSealRefresh) — КД нет
    -- совсем, Quick Solver (billy_reload) — минус cdCut секунд.
    if self.refreshed then return end
    local cd = ability:GetEffectiveCooldown(-1) - (self.cdCut or 0)
    if cd > 0 then ability:StartCooldown(cd) end
end

-- ResetAbilities (печать Мастера и прочие полные сбросы): пуля W в полёте — после
-- разрыва W выходит без КД.
function BillyOnSealRefresh(hero)
    local w = IsNotNull(hero) and hero:FindAbilityByName("billy_triple_shot")
    if w and IsNotNull(w.bullet) then w.bullet.refreshed = true end
end

---------------------------------------------------------------------------------------------------
-- «Пуля в полёте»: стак 1 = W сейчас рекаст (по нему клиент рисует W мгновенной). Живёт,
-- пока жива пуля, снимается на разрыве. Виден на Билли значком W с таймером до разрыва
-- (юзер 07.10.2026). Сервер рекаст решает не по нему, а по ability.bullet (фильтр приказов).
modifier_billy_triple_shot_recast = modifier_billy_triple_shot_recast or class({})

function modifier_billy_triple_shot_recast:IsHidden()   return false end
function modifier_billy_triple_shot_recast:IsDebuff()   return false end
function modifier_billy_triple_shot_recast:IsPurgable() return false end
function modifier_billy_triple_shot_recast:GetTexture() return "custom/billy/billy_triple_shot" end

function modifier_billy_triple_shot_recast:OnCreated()
    if IsServer() then self:SetStackCount(1) end
end

---------------------------------------------------------------------------------------------------
-- Замедление дробью: slow_per_stack% за стак, стаков до slow_max_stacks.
modifier_billy_triple_shot_slow = modifier_billy_triple_shot_slow or class({})

function modifier_billy_triple_shot_slow:IsHidden()   return false end
function modifier_billy_triple_shot_slow:IsDebuff()   return true end
function modifier_billy_triple_shot_slow:IsPurgable() return true end

function modifier_billy_triple_shot_slow:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_billy_triple_shot_slow:GetModifierMoveSpeedBonus_Percentage()
    local ability = self:GetAbility()
    if not ability then return 0 end
    return -ability:GetSpecialValueFor("slow_per_stack") * self:GetStackCount()
end
