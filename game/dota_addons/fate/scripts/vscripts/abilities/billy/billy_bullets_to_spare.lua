--[[ Bullets to Spare (D) — переключатель.
     Пока включена, Q/W/E/R тратят пули и получают усиление (см. Billy_TrySpend),
     а каждая дальняя атака тратит пулю и добивает ту же цель ещё двумя выстрелами
     в половину урона атаки. Запас пуль — стаки интринсика modifier_billy_bullets:
     всегда 6 (base_bullets), восстанавливается только перезарядкой (F) и на респавне.
     Хедшот (атрибут Here Is an Old Trick) атакой НЕ критует — только Q/W/E (юзер 08.10.2026).
     Варды урон способностей не получают (DoDamage их пропускает), поэтому доп. выстрел
     по варду — настоящая атака (PerformAttack): атака под D = три удара по варду. ]]
require("abilities/billy/billy_shared")

billy_bullets_to_spare = billy_bullets_to_spare or class({})
LinkLuaModifier("modifier_billy_bullets", "abilities/billy/billy_bullets_to_spare", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_gait",    "abilities/billy/billy_bullets_to_spare", LUA_MODIFIER_MOTION_NONE)

function billy_bullets_to_spare:GetIntrinsicModifierName()
    return "modifier_billy_bullets"
end

function billy_bullets_to_spare:OnToggle()
    if not IsServer() then return end
    -- вкл — взвод курка, выкл — спуск
    self:GetCaster():EmitSound(self:GetToggleState() and "billy_d_on" or "billy_d_off")
    -- явный сброс текущей анимации: без него стойка менялась, только когда герой вставал
    Billy_RefreshAnim(self:GetCaster(), self)
end

-- Доп. выстрелы атаки: урон посчитан в момент выстрела и едет в ExtraData.
function billy_bullets_to_spare:OnProjectileHit_ExtraData(target, location, data)
    Billy_BulletEnd(data.bfx, target)
    if not target or not IsNotNull(target) or not target:IsAlive() then return true end
    if Billy_ArrowProof(target) then return true end
    local caster = self:GetCaster()
    Billy_FxImpact(target, nil, caster:GetAbsOrigin(), true)   -- доп. выстрелы — всегда под D
    if target:GetName() == "npc_dota_ward_base" then
        -- мгновенная атака без снаряда: ward_base считает урон по ударам атак.
        -- wardShot глушит OnAttack (без второй пули и без траты пули)
        local m = caster:FindModifierByName("modifier_billy_bullets")
        if m then m.wardShot = true end
        caster:PerformAttack(target, false, false, true, true, false, false, true)
        if m then m.wardShot = false end
        return true
    end
    DoDamage(caster, target, data.damage or 0, DAMAGE_TYPE_PHYSICAL, 0, self, false)
    return true
end

---------------------------------------------------------------------------------------------------
modifier_billy_bullets = modifier_billy_bullets or class({})

function modifier_billy_bullets:IsHidden()      return false end
function modifier_billy_bullets:IsDebuff()      return false end
function modifier_billy_bullets:IsPurgable()    return false end
function modifier_billy_bullets:RemoveOnDeath() return false end
function modifier_billy_bullets:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
function modifier_billy_bullets:GetTexture() return "custom/billy/billy_bullets_to_spare" end

function modifier_billy_bullets:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_RESPAWN,
        MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
    }
end

--[[ Анимации модели (billy.vmdl) — activity modifiers, как у Искандера
     (modifier_iskandar_charisma: run_fast/run_slow по GetIdealSpeed). Теги складываются
     от разных модификаторов: этот даёт "bullets" (D включена и пули есть — стойка
     bullet_*, у Skedaddle прыжок со стрельбой), modifier_billy_gait — "walk"/"run". ]]
function modifier_billy_bullets:GetActivityTranslationModifiers()
    if Billy_IsDActive(self:GetParent()) and self:GetStackCount() > 0 then return "bullets" end
    return ""
end

function modifier_billy_bullets:OnCreated()
    if not IsServer() then return end
    self.parent  = self:GetParent()
    self.lastMax = Billy_GetMaxBullets(self.parent)
    self.dshots  = {}   -- record атак под D: на попадании — оранжевый всплеск
    self:SetStackCount(self.lastMax)
    self:StartIntervalThink(0.25)
    -- походка: обычный ход — walk, бег — только при скорости выше run_speed
    self.parent:AddNewModifier(self.parent, self:GetAbility(), "modifier_billy_gait", {})
end

-- Максимум сейчас постоянный (base_bullets); прибавку, если KV поменяют на ходу, докладываем в запас.
function modifier_billy_bullets:OnIntervalThink()
    local parent = self.parent
    -- стойка "bullets" зависит и от запаса: кончились/перезарядился при включённой D
    local armed = Billy_IsDActive(parent) and self:GetStackCount() > 0
    if self.lastArmed ~= nil and armed ~= self.lastArmed then Billy_RefreshAnim(parent) end
    self.lastArmed = armed
    local max = Billy_GetMaxBullets(parent)
    if max > self.lastMax then
        self:SetStackCount(self:GetStackCount() + (max - self.lastMax))
    end
    self.lastMax = max
    if self:GetStackCount() > max then self:SetStackCount(max) end

    -- маска атрибутов для клиента (см. billy_shared)
    local mask = Billy_AttrMask(parent)
    if mask > 0 and parent:IsAlive() then
        local m = parent:FindModifierByName("modifier_billy_attributes")
        if not m then
            m = parent:AddNewModifier(parent, nil, "modifier_billy_attributes", {})
        end
        if m and m:GetStackCount() ~= mask then m:SetStackCount(mask) end
    end
end

function modifier_billy_bullets:OnRespawn(args)
    if args.unit ~= self:GetParent() then return end
    Billy_Reload(args.unit)
end

function modifier_billy_bullets:OnAttack(args)
    if not IsServer() then return end
    local parent = self:GetParent()
    if args.attacker ~= parent then return end
    if self.wardShot then return end   -- доп. выстрел D по варду (PerformAttack), пуля уже летела
    if not parent:IsRangedAttacker() then return end
    local target = args.target
    local ability = self:GetAbility()
    -- пуля под D тратится только обычной атакой по врагу (не мгновенной no_attack_cooldown)
    local empowered = not args.no_attack_cooldown and IsNotNull(target)
        and target:GetTeamNumber() ~= parent:GetTeamNumber()
        and Billy_TrySpend(parent, ability:GetSpecialValueFor("attack_bullet_cost"))
    -- пуля Билли вместо снаряда атаки (он невидимый, ProjectileModel "" в KV героя) —
    -- на каждую атаку, в том числе мгновенные (no_attack_cooldown) и по союзникам;
    -- под D — своя пуля, а попадание (OnAttackLanded по record) даёт оранжевый всплеск
    Billy_AttackBulletFx(parent, target, parent:GetProjectileSpeed(), empowered)
    if not empowered then return end
    self.dshots = self.dshots or {}   -- после script_reload OnCreated не перезапускался
    self.dshots[args.record] = true

    local damage = parent:GetAverageTrueAttackDamage(target)
        * ability:GetSpecialValueFor("attack_shot_damage_pct") / 100
    -- Все доп. выстрелы вылетают В МОМЕНТ атаки, из дула (юзер 09.10.2026): раньше они шли
    -- таймерами через 0.1 с и после блинка вылетали уже из новой позиции Билли. Очередь — за
    -- счёт скорости: i-я пуля на attack_shot_speed_step% медленнее, прилетает чуть позже.
    -- Звуки выстрелов — по-прежнему с паузой, но в точке выстрела, а не на Билли.
    local shots = ability:GetSpecialValueFor("attack_extra_shots")
    local step = ability:GetSpecialValueFor("attack_shot_speed_step") / 100
    local base = parent:GetProjectileSpeed()
    local gun = Billy_GunOrigin(parent)
    for i = 1, shots do
        local speed = base * math.max(1 - step * i, 0.3)
        -- снаряд невидимый, летит пуля Билли (гаснет на попадании по жетону bfx)
        ProjectileManager:CreateTrackingProjectile({
            Target            = target,
            Source            = parent,
            Ability           = ability,
            EffectName        = "",
            iMoveSpeed        = speed,
            bDodgeable        = true,
            bProvidesVision   = false,
            iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
            ExtraData         = { damage = damage, bfx = Billy_AttackBulletFx(parent, target, speed, true) },
        })
        Timers:CreateTimer(0.1 * i, function()
            if IsNotNull(parent) then EmitSoundOnLocationWithCaster(gun, BILLY_SND.shot, parent) end
        end)
    end
end

function modifier_billy_bullets:OnAttackLanded(args)
    if not IsServer() then return end
    if args.attacker ~= self:GetParent() then return end
    if self.dshots and self.dshots[args.record] then
        self.dshots[args.record] = nil
        -- только всплеск: искр и звука попадания у основной атаки и без D не было
        if IsNotNull(args.target) then
            local back = args.attacker:GetAbsOrigin() - args.target:GetAbsOrigin()
            back.z = 0
            Billy_FxBurstD(Billy_HitPos(args.target),
                back:Length2D() > 1 and back:Normalized() or -args.target:GetForwardVector())
        end
    end
end

-- промах/уклонение: запись атаки умирает без попадания — не копим мусор в self.dshots
function modifier_billy_bullets:OnAttackRecordDestroy(args)
    if not IsServer() or args.attacker ~= self:GetParent() then return end
    if self.dshots then self.dshots[args.record] = nil end
end


---------------------------------------------------------------------------------------------------
-- Походка (как у Искандера): "run" при скорости выше run_speed, иначе "walk".
-- В модели обе анимации висят на ACT_DOTA_RUN и различаются только этим тегом.
modifier_billy_gait = modifier_billy_gait or class({})

function modifier_billy_gait:IsHidden()      return true end
function modifier_billy_gait:IsPurgable()    return false end
function modifier_billy_gait:RemoveOnDeath() return false end
function modifier_billy_gait:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_billy_gait:DeclareFunctions()
    return { MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS }
end

-- переход через порог бега — тоже ручной сброс анимации (сам движок не перечитает)
function modifier_billy_gait:OnCreated()
    if not IsServer() then return end
    self:StartIntervalThink(0.1)
end

-- ⚠️ GetIdealSpeed на сервере дёргает modifier_attributes_ms, а тот падает, пока
-- hero.AGIgained не проставлен (первые мгновения после спавна) — до этого не спрашиваем.
local function SpeedKnown(parent)
    return not IsServer() or parent.AGIgained ~= nil
end

function modifier_billy_gait:OnIntervalThink()
    if not SpeedKnown(self:GetParent()) then return end
    local ab = self:GetAbility()
    local running = self:GetParent():GetIdealSpeed() > (ab and ab:GetSpecialValueFor("run_speed") or 500)
    if self.lastRunning ~= nil and running ~= self.lastRunning then Billy_RefreshAnim(self:GetParent()) end
    self.lastRunning = running
end

function modifier_billy_gait:GetActivityTranslationModifiers()
    if not SpeedKnown(self:GetParent()) then return "walk" end
    local ab = self:GetAbility()
    local runSpeed = ab and ab:GetSpecialValueFor("run_speed") or 500
    return self:GetParent():GetIdealSpeed() > runSpeed and "run" or "walk"
end
