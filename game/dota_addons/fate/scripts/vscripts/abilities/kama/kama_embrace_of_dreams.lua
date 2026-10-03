kama_embrace_of_dreams = class({})

--[[ Kama W
     Создано панелью. ScriptFile: abilities/kama/kama_embrace_of_dreams
     Блокируется рутом (ROOT_DISABLES), движение — motion controller
]]

LinkLuaModifier("modifier_kama_embrace_of_dreams_motion", "abilities/kama/kama_embrace_of_dreams",
    LUA_MODIFIER_MOTION_HORIZONTAL)

function kama_embrace_of_dreams:GetAOERadius()
    return self:GetSpecialValueFor("distance")
end

function kama_embrace_of_dreams:OnSpellStart()
    local caster = self:GetCaster()
    --caster:EmitSound("kama_embrace_of_dreams_cast")
    -- запас 0.1 c: на последнем шаге контроллер ещё доезжает
    local duration = (self:GetAOERadius() / self:GetSpecialValueFor("speed")) + 0.1
    caster:AddNewModifier(caster, self, "modifier_kama_embrace_of_dreams_motion", {duration = duration})
end

--=========================================================================--
-- Модификатор движения. ⚠️ Деш обязан блокироваться рутом — за это отвечает
-- DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES в KV, а состояния ниже не дают кастеру
-- бить и колдовать в полёте.
modifier_kama_embrace_of_dreams_motion = class({})

function modifier_kama_embrace_of_dreams_motion:IsHidden()         return true end
function modifier_kama_embrace_of_dreams_motion:IsDebuff()         return false end
function modifier_kama_embrace_of_dreams_motion:IsPurgable()       return false end
function modifier_kama_embrace_of_dreams_motion:IsPurgeException() return false end
function modifier_kama_embrace_of_dreams_motion:RemoveOnDeath()    return true end

function modifier_kama_embrace_of_dreams_motion:CheckState()
    return {
        [MODIFIER_STATE_ROOTED]   = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_MUTED]    = true,
    }
end

function modifier_kama_embrace_of_dreams_motion:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
    self.nSpeed    = self.hAbility:GetSpecialValueFor("speed")
    self.nDistance = self.hAbility:GetAOERadius()
    self.nRadius   = self.hAbility:GetSpecialValueFor("radius")
    self.nDamage   = self.hAbility:GetSpecialValueFor("damage")

    if not IsServer() then return end
    self.vStart = self.hParent:GetAbsOrigin()
    local vPoint = self.hAbility:GetCursorPosition()
    self.vDirection = (vPoint - self.vStart)
    self.vDirection.z = 0
    self.vDirection = self.vDirection:Normalized()
    self.hParent:FaceTowards(vPoint)
    self.tHit = {}

    --StartAnimation(self.hParent, {duration = 0.4, activity = ACT_DOTA_RUN, rate = 1.4})
    --self.nFx = ParticleManager:CreateParticle("particles/kama/kama_embrace_of_dreams.vpcf",
    --    PATTACH_ABSORIGIN_FOLLOW, self.hParent)
    --self:AddParticle(self.nFx, false, false, -1, false, false)

    if not self:ApplyHorizontalMotionController() then
        self:Destroy()
    end
end

function modifier_kama_embrace_of_dreams_motion:OnRefresh(tTable)
    self:OnCreated(tTable)
end

-- ⚠️ Обязательно: без этого чужой motion controller оставит нас висеть.
function modifier_kama_embrace_of_dreams_motion:OnHorizontalMotionInterrupted()
    if IsServer() then
        self.hParent:RemoveHorizontalMotionController(self)
        self:Destroy()
    end
end

function modifier_kama_embrace_of_dreams_motion:UpdateHorizontalMotion(hUnit, nTime)
    if not IsServer() then return end
    if self.hParent:IsStunned() then return nil end

    local vCur  = hUnit:GetAbsOrigin()
    local vNext = vCur + self.vDirection * self.nSpeed * nTime

    -- стена или предел дистанции — останавливаемся ровно здесь
    if not GridNav:IsTraversable(vNext) or GridNav:IsBlocked(vNext)
        or (vNext - self.vStart):Length2D() > self.nDistance then
        self:Destroy()
        return nil
    end

    hUnit:SetAbsOrigin(vNext)
    self:DoEffect(vNext)
end

-- Урон по пути: каждого задеваем ОДИН раз (tHit), иначе цель у самой траектории
-- получит урон на каждом кадре.
function modifier_kama_embrace_of_dreams_motion:DoEffect(vPosition)
    local enemies = FindUnitsInRadius(self.hCaster:GetTeamNumber(), vPosition, nil,
        self.nRadius, self.hAbility:GetAbilityTargetTeam(),
        self.hAbility:GetAbilityTargetType(), self.hAbility:GetAbilityTargetFlags(),
        FIND_ANY_ORDER, false)
    for _, hEnemy in pairs(enemies) do
        if IsNotNull(hEnemy) and not self.tHit[hEnemy:entindex()] then
            self.tHit[hEnemy:entindex()] = true
            if not IsSpellBlocked(hEnemy, self.hCaster) then
                DoDamage(self.hCaster, hEnemy, self.nDamage,
                    self.hAbility:GetAbilityDamageType(), 0, self.hAbility, false)
                --hEnemy:EmitSound("kama_embrace_of_dreams_hit")
            end
        end
    end
end

function modifier_kama_embrace_of_dreams_motion:OnDestroy()
    if not IsServer() then return end
    self.hParent:InterruptMotionControllers(true)
    -- ⚠️ Без этого герой остаётся стоять в текстуре
    FindClearSpaceForUnit(self.hParent, self.hParent:GetAbsOrigin(), true)
    --EndAnimation(self.hParent)
end
