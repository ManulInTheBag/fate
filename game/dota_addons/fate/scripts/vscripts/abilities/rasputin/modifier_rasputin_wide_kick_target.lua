require('abilities/rasputin/rasputin_gesture')

modifier_rasputin_wide_kick_target = class({})


-- Метка финишера, видимая ТОЛЬКО самому Распутину: кольцо под целью и дорожка
-- стрелок от него до неё. Оба партикля создаются через CreateParticleForPlayer,
-- так что врагу и союзникам они не рисуются вообще.
--
-- Кольцо висит всё время, пока держится метка. Дорожка - только пока по цели
-- реально можно нажать F (RasputinCanFinishTarget).
local MARK_FX = "particles/rasputin/rasputin_finisher_mark_enemy.vpcf"
local PATH_FX = "particles/rasputin/rasputin_finisher_path.vpcf"

-- Дорожка - ОДИН партикль: стрелки раскладывает сам движок между CP0 и CP1
-- (C_INIT_CreateSequentialPath + C_OP_MaintainSequentialPath), поэтому при
-- движении любого из концов линия переезжает целиком и без рывков, а по сети
-- уходит три контрольные точки вместо полусотни отдельных систем.
local PATH_CAST_GAP   = 90      -- отступ от Распутина
local PATH_TARGET_GAP = 60      -- отступ от цели, чтобы стрелки не лезли в модель
local PATH_THINK      = 0.03    -- пересчёт каждый тик: линия едет плавно


function modifier_rasputin_wide_kick_target:IsHidden()
    return true
end


function modifier_rasputin_wide_kick_target:IsPurgable()
    return true
end


function modifier_rasputin_wide_kick_target:DeclareFunctions()

    return {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    }

end


function modifier_rasputin_wide_kick_target:GetModifierProvidesFOWVision()
    return 1
end


function modifier_rasputin_wide_kick_target:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


-- Игрок, которому единственному показывают метку. Нет владельца (бот, демо-режим)
-- - партиклей просто не будет: показывать их всем нельзя.
function modifier_rasputin_wide_kick_target:GetViewer()

    local caster = self:GetCaster()

    if not IsNotNull(caster) then return nil end

    return caster:GetPlayerOwner()

end


function modifier_rasputin_wide_kick_target:OnCreated()

    if not IsServer() then return end

    self:CreateMarkFx()

    self:StartIntervalThink(PATH_THINK)

    self:UpdatePath()

end


function modifier_rasputin_wide_kick_target:OnRefresh()

    if not IsServer() then return end

    -- метку перевесили на уже помеченного: партикли уже висят, их не трогаем
    self:CreateMarkFx()

    self:StartIntervalThink(PATH_THINK)

    self:UpdatePath()

end


function modifier_rasputin_wide_kick_target:OnIntervalThink()

    if not IsServer() then return end

    self:UpdatePath()

end


function modifier_rasputin_wide_kick_target:OnDestroy()

    if not IsServer() then return end

    self:KillMarkFx()

    self:KillPathFx()

end


--------------------------------------------------------------------------------
-- Кольцо под целью
--------------------------------------------------------------------------------

function modifier_rasputin_wide_kick_target:CreateMarkFx()

    if not IsServer() then return end

    if self.markFx then return end

    local parent = self:GetParent()

    if not IsNotNull(parent) then return end

    local player = self:GetViewer()

    if not player then return end


    self.markFx =
    ParticleManager:CreateParticleForPlayer(
        RasputinFx(self:GetCaster(), MARK_FX),
        PATTACH_ABSORIGIN_FOLLOW,
        parent,
        player
    )

    -- CP1 - тинт кольца в диапазоне 0..255; белый оставляет авторский красный
    ParticleManager:SetParticleControl(self.markFx, 1, Vector(255, 255, 255))

    -- метка должна быть видна и в тумане: цель, ушедшую в туман, Распутин всё
    -- равно достаёт финишером, так что и подсветка обязана оставаться на виду
    ParticleManager:SetParticleShouldCheckFoW(self.markFx, false)

end


function modifier_rasputin_wide_kick_target:KillMarkFx()

    if not IsServer() then return end

    if not self.markFx then return end

    -- метки нет - убираем сразу, без затухания
    ParticleManager:DestroyParticle(self.markFx, true)
    ParticleManager:ReleaseParticleIndex(self.markFx)

    self.markFx = nil

end


--------------------------------------------------------------------------------
-- Дорожка стрелок
--------------------------------------------------------------------------------

function modifier_rasputin_wide_kick_target:KillPathFx()

    if not IsServer() then return end

    if not self.pathFx then return end

    ParticleManager:DestroyParticle(self.pathFx, true)
    ParticleManager:ReleaseParticleIndex(self.pathFx)

    self.pathFx = nil

end


function modifier_rasputin_wide_kick_target:UpdatePath()

    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()

    local player = self:GetViewer()


    -- по цели сейчас не нажать финишер - дорожку убираем; кольцо остаётся
    if not player
    or not RasputinCanFinishTarget(caster, parent)
    then
        self:KillPathFx()
        return
    end


    local from = caster:GetAbsOrigin()
    local to   = parent:GetAbsOrigin()

    local dir = to - from
    dir.z = 0

    local dist = dir:Length2D()

    -- цель вплотную: рисовать нечего
    if dist <= PATH_CAST_GAP + PATH_TARGET_GAP then
        self:KillPathFx()
        return
    end

    dir = dir:Normalized()


    local head = GetGroundPosition(from + dir * PATH_CAST_GAP, nil)
    local tail = GetGroundPosition(to - dir * PATH_TARGET_GAP, nil)


    if not self.pathFx then

        self.pathFx =
        ParticleManager:CreateParticleForPlayer(
            RasputinFx(caster, PATH_FX),
            PATTACH_WORLDORIGIN,
            nil,
            player
        )

        -- дорожка тянется через неразведанные участки карты - туман её резать
        -- не должен, иначе линия обрывается на полпути к цели
        ParticleManager:SetParticleShouldCheckFoW(self.pathFx, false)

    end


    ParticleManager:SetParticleControl(self.pathFx, 0, head)

    -- CP1 - дальний конец линии, вдоль неё движок и раскладывает стрелки
    ParticleManager:SetParticleControl(self.pathFx, 1, tail)

    -- CP2 - точка, на которую стрелки смотрят (C_OP_Orient2DRelToCP)
    ParticleManager:SetParticleControl(self.pathFx, 2, tail)

end


--------------------------------------------------------------------------------
-- Живёт в этом же файле: rasputin_finisher линкует его отсюда же.
-- Держит цель видимой после финишера, к метке отношения не имеет.
--------------------------------------------------------------------------------
modifier_rasputin_seen = class({})

function modifier_rasputin_seen:IsHidden() return true end
function modifier_rasputin_seen:IsPurgable() return false end
function modifier_rasputin_seen:IsDebuff() return false end
function modifier_rasputin_seen:RemoveOnDeath() return true end


function modifier_rasputin_seen:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function modifier_rasputin_seen:DeclareFunctions()

    return {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    }

end


function modifier_rasputin_seen:GetModifierProvidesFOWVision()
    return 1
end
