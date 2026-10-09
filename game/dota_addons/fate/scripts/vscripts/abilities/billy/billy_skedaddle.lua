--[[ Skedaddle (E) — отпрыгивает назад (от точки каста) на distance.
     С включённой D (bullet_cost пуль) перед прыжком стреляет к точке тремя пулями
     веером (центр и ±spread_angle), каждая гаснет на первом враге.
     Natural Perception: там, где такая пуля остановилась (враг или конец дальности),
     встаёт дымовая завеса — враги внутри почти слепнут (до 07.10.2026 это было у W).
     Рывок — отдельный motion-модификатор (как okada_flashblade), в KV стоит
     ROOT_DISABLES. Проходит сквозь стены и деревья (юзер 08.10.2026); если конец рывка
     пришёлся в стену — выходит вперёд по ту сторону (до 400), иначе встаёт в последнюю
     проходимую точку пути, как блинки (blink.lua).
     После нажатия на buff_duration — modifier_billy_skedaddle_buff: +distance к дальности
     Q и W (Billy_RangeBonus) и к обзору, +bonus_agi ловкости. ]]
require("abilities/billy/billy_shared")

billy_skedaddle = billy_skedaddle or class({})
LinkLuaModifier("modifier_billy_skedaddle_motion", "abilities/billy/billy_skedaddle", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_billy_smoke_thinker",    "abilities/billy/billy_skedaddle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_smoke_blind",      "abilities/billy/billy_skedaddle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_billy_skedaddle_buff",   "abilities/billy/billy_skedaddle", LUA_MODIFIER_MOTION_NONE)


function billy_skedaddle:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local dir = self:GetCursorPosition() - origin
    dir.z = 0
    if dir:Length2D() < 1 then dir = caster:GetForwardVector() end
    dir = dir:Normalized()

    if Billy_TrySpend(caster, self:GetSpecialValueFor("bullet_cost")) then
        Billy_FireFan(self, origin, dir, 3, self:GetSpecialValueFor("spread_angle"),
            self:GetSpecialValueFor("shot_range"), self:GetSpecialValueFor("width"),
            self:GetSpecialValueFor("speed"), nil, BILLY_FX.d)   -- стреляет только под D
        caster:EmitSound(BILLY_SND.multi)
    end

    local distance = self:GetSpecialValueFor("distance")
    local dashSpeed = self:GetSpecialValueFor("dash_speed")
    caster:AddNewModifier(caster, self, "modifier_billy_skedaddle_buff",
        { duration = self:GetSpecialValueFor("buff_duration") })
    -- рут прилетел на замахе: рывка нет (выстрелы D и бафф остаются)
    if caster:IsRooted() then
        caster:EmitSound("billy_vo_skedaddle")
        return
    end
    caster:AddNewModifier(caster, self, "modifier_billy_skedaddle_motion", {
        duration = distance / dashSpeed + 0.1,
        dx = -dir.x, dy = -dir.y, distance = distance, speed = dashSpeed,
    })
    -- caster:EmitSound("billy_skedaddle_jump")
    caster:EmitSound("billy_vo_skedaddle")
end

function billy_skedaddle:OnProjectileHit_ExtraData(target, location, data)
    if target and Billy_ArrowProof(target) then return false end   -- пролетает сквозь
    Billy_BulletEnd(data.bfx, target)
    local caster = self:GetCaster()
    if target and IsNotNull(target) and target:IsAlive() then
        Billy_FxImpact(target, "s", caster:GetAbsOrigin(), true)
        Billy_Damage(caster, target, self:GetSpecialValueFor("shot_damage"), DAMAGE_TYPE_PHYSICAL, self)
    end
    if Billy_HasAttr(caster, 5) then
        local pos = target and IsNotNull(target) and target:GetAbsOrigin() or GetGroundPosition(location, nil)
        CreateModifierThinker(caster, self, "modifier_billy_smoke_thinker",
            { duration = self:GetSpecialValueFor("np_smoke_duration") },
            pos, caster:GetTeamNumber(), false)
    end
    return true
end

---------------------------------------------------------------------------------------------------
modifier_billy_skedaddle_motion = modifier_billy_skedaddle_motion or class({})

function modifier_billy_skedaddle_motion:IsHidden()      return true end
function modifier_billy_skedaddle_motion:IsDebuff()      return false end
function modifier_billy_skedaddle_motion:IsPurgable()    return false end
function modifier_billy_skedaddle_motion:RemoveOnDeath() return true end

function modifier_billy_skedaddle_motion:CheckState()
    return {
        [MODIFIER_STATE_SILENCED]          = true,
        [MODIFIER_STATE_MUTED]             = true,
        [MODIFIER_STATE_DISARMED]          = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end

-- анимация прыжка на весь рывок: без override движение перебивает каст-анимацию
-- (с включённой D модель сама берёт вариант со стрельбой — activity modifier "bullets")
function modifier_billy_skedaddle_motion:DeclareFunctions()
    return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION }
end
function modifier_billy_skedaddle_motion:GetOverrideAnimation() return ACT_DOTA_CAST_ABILITY_3 end

function modifier_billy_skedaddle_motion:OnCreated(args)
    if not IsServer() then return end
    self.dir      = Vector(args.dx, args.dy, 0):Normalized()
    self.speed    = args.speed
    self.left     = args.distance
    self.safe     = self:GetParent():GetAbsOrigin()   -- последняя проходимая точка пути
    if not self:ApplyHorizontalMotionController() then
        self:Destroy()
    end
end

-- Сквозь стены: проходимость не проверяем, только край мира. Последнюю проходимую точку
-- запоминаем — туда встанем, если рывок кончился внутри стены.
local function InWorld(pos)
    return pos.x > GetWorldMinX() and pos.x < GetWorldMaxX()
       and pos.y > GetWorldMinY() and pos.y < GetWorldMaxY()
end

local EXIT_STEP, EXIT_SEARCH = 25, 400

local function Walkable(pos)
    return GridNav:IsTraversable(pos) and not GridNav:IsBlocked(pos)
end

function modifier_billy_skedaddle_motion:UpdateHorizontalMotion(unit, dt)
    if not IsServer() then return end
    local step = math.min(self.speed * dt, self.left)
    local nextPos = unit:GetAbsOrigin() + self.dir * step
    -- рут посреди рывка обрывает его (в руте E не кастуется — ROOT_DISABLES в KV)
    if step <= 0 or not InWorld(nextPos) or unit:IsRooted() then
        self:Destroy()
        return
    end
    nextPos = GetGroundPosition(nextPos, unit)
    unit:SetAbsOrigin(nextPos)
    if Walkable(nextPos) then self.safe = nextPos end
    self.left = self.left - step
    if self.left <= 0 then
        self:Destroy()
    end
end

function modifier_billy_skedaddle_motion:OnHorizontalMotionInterrupted()
    if IsServer() then self:Destroy() end
end

function modifier_billy_skedaddle_motion:OnDestroy()
    if not IsServer() then return end
    local parent = self:GetParent()
    if IsNotNull(parent) then
        parent:RemoveHorizontalMotionController(self)
        -- кончил внутри стены/деревьев — сначала дотягиваем вперёд (до EXIT_SEARCH), чтобы
        -- выйти по ту сторону; не вышло — назад к последней проходимой точке пути
        local pos = parent:GetAbsOrigin()
        if not Walkable(pos) then
            local exit
            for d = EXIT_STEP, EXIT_SEARCH, EXIT_STEP do
                local p = pos + self.dir * d
                if not InWorld(p) then break end
                if Walkable(p) then exit = p break end
            end
            pos = exit or self.safe or pos
        end
        FindClearSpaceForUnit(parent, pos, true)
    end
end

---------------------------------------------------------------------------------------------------
-- Дымовая завеса (Natural Perception): аура на думалке, враги внутри — с ослеплением.
-- Думалка сама удаляется вместе с модификатором (CreateModifierThinker).
modifier_billy_smoke_thinker = modifier_billy_smoke_thinker or class({})

function modifier_billy_smoke_thinker:IsHidden() return true end
function modifier_billy_smoke_thinker:IsAura()   return true end
function modifier_billy_smoke_thinker:GetModifierAura() return "modifier_billy_smoke_blind" end
function modifier_billy_smoke_thinker:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("np_smoke_radius")
end
function modifier_billy_smoke_thinker:GetAuraSearchTeam()  return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_billy_smoke_thinker:GetAuraSearchType()  return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_billy_smoke_thinker:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES end
function modifier_billy_smoke_thinker:GetAuraDuration()    return 0.1 end

function modifier_billy_smoke_thinker:OnCreated()
    if not IsServer() then return end
    local radius = self:GetAbility():GetSpecialValueFor("np_smoke_radius")
    local fx = ParticleManager:CreateParticle(BILLY_FX.smoke, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleShouldCheckFoW(fx, false)
    ParticleManager:SetParticleControl(fx, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(fx, 1, Vector(radius, radius, radius))
    self:AddParticle(fx, false, false, -1, false, false)
    -- EmitSoundOnLocationWithCaster(self:GetParent():GetAbsOrigin(), "billy_smoke", self:GetCaster())
end

modifier_billy_smoke_blind = modifier_billy_smoke_blind or class({})

function modifier_billy_smoke_blind:IsHidden()   return false end
function modifier_billy_smoke_blind:IsDebuff()   return true end
function modifier_billy_smoke_blind:IsPurgable() return false end

function modifier_billy_smoke_blind:DeclareFunctions()
    return { MODIFIER_PROPERTY_FIXED_DAY_VISION, MODIFIER_PROPERTY_FIXED_NIGHT_VISION }
end

function modifier_billy_smoke_blind:GetFixedDayVision()
    return self:GetAbility():GetSpecialValueFor("np_smoke_vision")
end
function modifier_billy_smoke_blind:GetFixedNightVision()
    return self:GetAbility():GetSpecialValueFor("np_smoke_vision")
end

---------------------------------------------------------------------------------------------------
-- После нажатия E: +distance к дальности Q/W (стаки — читает Billy_RangeBonus, и на клиенте)
-- и столько же к обзору, плюс ловкость по уровню E.
modifier_billy_skedaddle_buff = modifier_billy_skedaddle_buff or class({})

function modifier_billy_skedaddle_buff:IsHidden()   return false end
function modifier_billy_skedaddle_buff:IsDebuff()   return false end
function modifier_billy_skedaddle_buff:IsPurgable() return false end   -- не снимается (юзер 09.10.2026)
function modifier_billy_skedaddle_buff:GetTexture() return "custom/billy/billy_skedaddle" end

function modifier_billy_skedaddle_buff:OnCreated()
    self:OnRefresh()
end

function modifier_billy_skedaddle_buff:OnRefresh()
    local ability = self:GetAbility()
    if not ability then return end
    self.agi = ability:GetSpecialValueFor("bonus_agi")
    self.vision = ability:GetSpecialValueFor("distance")
    if IsServer() then self:SetStackCount(self.vision) end
end

function modifier_billy_skedaddle_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_BONUS_DAY_VISION,
        MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
    }
end

function modifier_billy_skedaddle_buff:GetModifierBonusStats_Agility() return self.agi or 0 end
function modifier_billy_skedaddle_buff:GetBonusDayVision()             return self.vision or 0 end
function modifier_billy_skedaddle_buff:GetBonusNightVision()           return self.vision or 0 end
