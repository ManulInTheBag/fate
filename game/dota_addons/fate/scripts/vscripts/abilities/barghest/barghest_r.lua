require("abilities/barghest/barghest_shared")

barghest_r = class({})

--[[ Beast's Continuation (R)
     Не самостоятельная способность, а ПРОДОЛЖЕНИЕ предыдущей: Q/W/E «заряжают»
     её на короткое окно, и от того, чем зарядили, зависит эффект. Ротация
     концепта — qrqrqr.

       1 (Q1) — второй удар аркой, меч в огне
       2 (Q2) — удар снизу, ненадолго подбрасывает
       3 (Q3) — удар об землю с огненным взрывом
       4 (W)  — рывок вперёд, удар рогами, стан первого встречного
       5 (E)  — волна энергии в виде чёрного пса, микростан по линии

     Окно растёт с уровнем R (`window`). Попадание любым продолжением возвращает
     часть кулдауна Q и даёт стак разгона.
]]

-- modifier_barghest_continuation объявлен в barghest_shared: вешают его Q/W/E.
LinkLuaModifier("modifier_barghest_frenzy",       "abilities/barghest/barghest_r", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_r_horn",       "abilities/barghest/barghest_r", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)
function barghest_r:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

--[[ Что заряжено — числом, КЛИЕНТОБЕЗОПАСНО.
     ⚠️ GetModifierStackCount есть в обеих VM, а FindModifierByName только на
     сервере. Иконку слота считает клиент, поэтому здесь только это. ]]
function barghest_r:GetArmedBranch()
    local hCaster = self:GetCaster()
    if hCaster == nil or type(hCaster.GetModifierStackCount) ~= "function" then
        return 0
    end
    return hCaster:GetModifierStackCount("modifier_barghest_continuation", hCaster) or 0
end

--[[ Иконка В СЛОТЕ прямо говорит, что сейчас даст R: R1/R2/R3 после ударов
     связки, RW после стойки, RE после рывка. Без заряда — обычная R. ]]
function barghest_r:GetAbilityTextureName()
    local n = self:GetArmedBranch()
    if n >= 1 and n <= 5 then
        return "custom/barghest/barghest_cont_" .. n
    end
    return "custom/barghest/barghest_r"
end

--[[ ⚠️ Только сервер. CastFilterResult* дёргается и в КЛИЕНТСКОЙ VM, а там у
     юнита нет ни FindModifierByName, ни util.lua — на этом падало дважды.
     На клиенте просто разрешаем: настоящий отказ всё равно за сервером. ]]
function barghest_r:GetContinuationBranch()
    if not IsServer() then return nil end
    local hCaster = self:GetCaster()
    if hCaster == nil or type(hCaster.FindModifierByName) ~= "function" then return nil end
    local hMod = hCaster:FindModifierByName("modifier_barghest_continuation")
    if hMod == nil then return nil end
    return hMod:GetStackCount()
end

function barghest_r:CastFilterResultLocation()
    if not IsServer() then return UF_SUCCESS end
    if self:GetContinuationBranch() == nil then
        return UF_FAIL_CUSTOM
    end
    return UF_SUCCESS
end

function barghest_r:GetCustomCastErrorLocation()
    return "Requires a previous ability"
end

--[[ У каждой ветки продолжения СВОЯ activity: пять разных движений — пять
     разных клипов. Индексы совпадают с BARGHEST_CONT_*. ]]
BARGHEST_R_ACT = {
    ACT_DOTA_CAST_ABILITY_6,        -- Q1R: огненная дуга
    ACT_DOTA_CAST_ABILITY_7,        -- Q2R: удар снизу
    ACT_DOTA_OVERRIDE_ABILITY_1,    -- Q3R: удар об землю
    ACT_DOTA_OVERRIDE_ABILITY_2,    -- WR:  таран рогами
    ACT_DOTA_OVERRIDE_ABILITY_3,    -- ER:  волна
}

--[[ ⚠️ Клип ветки отыгрывает ДВИЖОК по этому колбэку. Руками его не дублируем:
     раньше рядом стоял OnAbilityPhaseStart, который запускал ТО ЖЕ САМОЕ
     StartAnimation'ом — отсюда и дёрганые анимации продолжений. ]]
function barghest_r:GetCastAnimation()
    return BARGHEST_R_ACT[self:GetArmedBranch()] or ACT_DOTA_CAST_ABILITY_6
end

function barghest_r:GetCastPoint()
    if self:GetArmedBranch() == 5 then
        return 0.3
    else
        return 0.2
    end
end
function barghest_r:OnAbilityPhaseStart()
	local caster = self:GetCaster()
    EndAnimation(caster)
    local jopa = BARGHEST_R_ACT[self:GetArmedBranch()]
    print(jopa)
	StartAnimation(caster, {duration=self:GetCastPoint(), activity=jopa, rate=1})
end

function barghest_r:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    EndAnimation(caster)
end

function barghest_r:OnSpellStart()
    if not IsServer() then return end
    local hCaster = self:GetCaster()
    local nBranch = self:GetContinuationBranch()
    --[[ ⚠️ EndAnimation отсюда убран: он выставляет _animationEnd, из-за чего
         StartAnimation (animations.lua:482) откладывает следующий клип на
         0.066 с. Для веток, которые тут же запускают свою анимацию, это был
         провал на два кадра. ]]

    -- Продолжение одноразовое: снимаем сразу, иначе одним окном его отыграют дважды.
    hCaster:RemoveModifierByName("modifier_barghest_continuation")
    if nBranch == nil then return end

    local vPoint = self:GetCursorPosition()
    local vDir = vPoint - hCaster:GetAbsOrigin()
    vDir.z = 0
    if vDir:Length2D() < 1 then
        vDir = hCaster:GetForwardVector()
    end
    vDir = vDir:Normalized()
    hCaster:FaceTowards(vPoint)

    local bHit = false
    if nBranch == BARGHEST_CONT_Q1 then
        bHit = self:DoBlazingArc(vDir)
    elseif nBranch == BARGHEST_CONT_Q2 then
        bHit = self:DoUppercut(vDir)
    elseif nBranch == BARGHEST_CONT_Q3 then
        bHit = self:DoBurstSlam()
    elseif nBranch == BARGHEST_CONT_W then
        self:DoHornCharge(vDir)     -- попадание засчитывает сам рывок
        return
    elseif nBranch == BARGHEST_CONT_E then
        bHit = self:DoHoundWave(vDir)
    end

    if bHit then
        self:RewardHit()
    end
end

--[[ Награда за попадание: часть кулдауна Q обратно + стак разгона. ]]
function barghest_r:RewardHit()
    if not IsServer() then return end
    local hCaster = self:GetCaster()

    local hQ = hCaster:FindAbilityByName("barghest_q")
    if Barghest_Alive(hQ) and hQ:GetCooldownTimeRemaining() > 0 then
        local fLeft = hQ:GetCooldownTimeRemaining() - self:GetSpecialValueFor("cd_refund")
        hQ:EndCooldown()
        if fLeft > 0 then
            hQ:StartCooldown(fLeft)
        end
    end

    local hFrenzy = hCaster:AddNewModifier(hCaster, self, "modifier_barghest_frenzy",
        {duration = self:GetSpecialValueFor("frenzy_duration")})
    if Barghest_Alive(hFrenzy) then
        local nMax = self:GetSpecialValueFor("frenzy_max")
        hFrenzy:SetStackCount(math.min(nMax, hFrenzy:GetStackCount() + 1))
    end
end

function barghest_r:DamageArea(vPos, nRadius, nDamage)
    local hCaster = self:GetCaster()
    local bHit = false
    local tUnits = FindUnitsInRadius(hCaster:GetTeamNumber(), vPos, nil, nRadius,
        self:GetAbilityTargetTeam(), self:GetAbilityTargetType(),
        self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
    for _, hUnit in pairs(tUnits) do
        if IsNotNull(hUnit) and not IsSpellBlocked(hUnit, hCaster) then
            DoDamage(hCaster, hUnit, nDamage, self:GetAbilityDamageType(), 0, self, false)
            Barghest_FxAt(BARGHEST_FX.FIRE_HIT, hUnit:GetAbsOrigin())
            bHit = true
        end
    end
    return bHit
end

-- 1 (Q1) — вторая арка, меч в огне: та же дуга, но КРАСНАЯ, шире и с огнём
function barghest_r:DoBlazingArc(vDir)
    local hCaster = self:GetCaster()
    local nRadius = self:GetSpecialValueFor("radius")
    local nAngle  = self:GetSpecialValueFor("arc_angle")
    local nDamage = self:GetSpecialValueFor("damage")
    hCaster:EmitSound(BARGHEST_SND.R_FIRE)

    Barghest_FxArc(BARGHEST_FX.ARC_FIRE, hCaster, nRadius, nAngle)

    local bHit = false
    for _, hUnit in pairs(Barghest_FindInArc(hCaster, self, hCaster:GetAbsOrigin(), vDir,
                                             nRadius, nAngle)) do
        if not IsSpellBlocked(hUnit, hCaster) then
            DoDamage(hCaster, hUnit, nDamage, self:GetAbilityDamageType(), 0, self, false)
             Barghest_FxOn(BARGHEST_FX.BURST, hCaster, 1.5)
            bHit = true
        end
    end
    return bHit
end

-- 2 (Q2) — удар снизу: вертикальный рез снизу вверх, узкий и близкий
function barghest_r:DoUppercut(vDir)
    local hCaster = self:GetCaster()
    local vPos    = hCaster:GetAbsOrigin()
    local nRadius = self:GetSpecialValueFor("radius") * 0.7
    local nDamage = self:GetSpecialValueFor("damage")
    local fUp = self:GetSpecialValueFor("uppercut_duration")
    hCaster:EmitSound(BARGHEST_SND.R_UPPER)

    -- Снизу вверх: рез идёт от земли перед ней к небу — это и читается как
    -- подброс, в отличие от горизонтальной дуги Q1R.
    Barghest_FxCutUp   (hCaster, nRadius, hCaster:GetAbsOrigin())
    Barghest_FxOn(BARGHEST_FX.BURST, hCaster, 1.5)
    local bHit = false
    for _, hUnit in pairs(Barghest_FindInArc(hCaster, self, vPos, vDir,
                                             nRadius, self:GetSpecialValueFor("arc_angle"))) do
        if not IsSpellBlocked(hUnit, hCaster) then
            DoDamage(hCaster, hUnit, nDamage, self:GetAbilityDamageType(), 0, self, false)
            hUnit:AddNewModifier(hCaster, self, "modifier_stunned", {duration = fUp})
            -- Подброс: движковый knockback с высотой и почти нулевым сдвигом —
            -- цель уходит ВВЕРХ, а не улетает от неё. Стан держит её и после
            -- приземления. ⚠️ Иммунитет к отбрасыванию проверяем всегда.
            if not IsKnockbackImmune(hUnit) then
                local vFrom = hUnit:GetAbsOrigin()
                hUnit:RemoveModifierByName("modifier_knockback")
                hUnit:AddNewModifier(hCaster, self, "modifier_knockback", {
                    should_stun        = false,
                    knockback_duration = fUp,
                    duration           = fUp,
                    knockback_distance = self:GetSpecialValueFor("uppercut_push"),
                    knockback_height   = self:GetSpecialValueFor("uppercut_height"),
                    center_x = vFrom.x - vDir.x,
                    center_y = vFrom.y - vDir.y,
                    center_z = vFrom.z,
                })
            end
            --Barghest_FxAt(BARGHEST_FX.SHOCK, hUnit:GetAbsOrigin())
            bHit = true
        end
    end
    return bHit
end

-- 3 (Q3) — удар об землю с огненным взрывом: кольцо на всю зону + огонь
function barghest_r:DoBurstSlam()
    local hCaster = self:GetCaster()
    local vPos    = hCaster:GetAbsOrigin()
    local nRadius = self:GetSpecialValueFor("slam_radius")
    hCaster:EmitSound(BARGHEST_SND.R_SLAM)

    --Barghest_FxRing(BARGHEST_FX.RING, vPos, nRadius)
    Barghest_FxOn(BARGHEST_FX.BURST, hCaster, 1.5)
    Barghest_FxAt(BARGHEST_FX.FIRE_HIT, vPos)
    return self:DamageArea(vPos, nRadius, self:GetSpecialValueFor("damage"))
end

-- 4 (W) — рывок вперёд с ударом рогами
function barghest_r:DoHornCharge(vDir)
    local hCaster = self:GetCaster()
    -- ⚠️ Анимации здесь НЕТ: ACT_DOTA_OVERRIDE_ABILITY_2 — это и есть клип
    -- ветки WR, движок уже играет его по GetCastAnimation. Повторный запуск
    -- сбрасывал таран в самом начале рывка.
    EndAnimation(hCaster)
    local charge_duration = self:GetSpecialValueFor("horn_distance")
                 / self:GetSpecialValueFor("horn_speed") + 0.1
    hCaster:EmitSound(BARGHEST_SND.E_DASH)
    hCaster:AddNewModifier(hCaster, self, "modifier_barghest_r_horn", {
        duration = charge_duration,
        x = vDir.x, y = vDir.y,
    })
end

function barghest_r:getAngle2D(v1, v2)
    -- Находим угол каждого вектора относительно оси X и вычитаем их
    local angleRad = math.atan2(v2.y, v2.x) - math.atan2(v1.y, v1.x)
    
    -- Переводим радианы в градусы
    local angleDeg = math.deg(angleRad)
    
    -- Корректируем значение, чтобы оно всегда было в диапазоне [0, 360)
    if angleDeg < 0 then
        angleDeg = angleDeg + 360
    end
    
    return angleDeg
end

-- 5 (E) — волна в виде чёрного пса, микростан по линии
function barghest_r:DoHoundWave(vDir)
    local hCaster = self:GetCaster()
    local vOrigin = hCaster:GetAbsOrigin()
    local nDist = self:GetSpecialValueFor("wave_distance")
    local nDamage = self:GetSpecialValueFor("damage")
    hCaster:EmitSound(BARGHEST_SND.R_WAVE)

    Barghest_FxLine(hCaster, vDir, nDist, self:GetSpecialValueFor("wave_width"))

    local sParticle = "particles/barghest/barghest_black_dog_proj.vpcf" 
     self.nParticle =  ParticleManager:CreateParticle(sParticle, PATTACH_WORLDORIGIN, nil)

    ParticleManager:SetParticleControl( self.nParticle, 0, vOrigin)
    --ParticleManager:SetParticleControl( self.nParticle, 1, GetGroundPosition(vPoint, nil))
    ParticleManager:SetParticleControl( self.nParticle, 1, 3000 * vDir)
    ParticleManager:SetParticleControl( self.nParticle, 6, (vDir * nDist) + vOrigin)
    ParticleManager:SetParticleControl( self.nParticle, 15, Vector(0,0,0))
        ParticleManager:SetParticleShouldCheckFoW( self.nParticle, false)
    ParticleManager:SetParticleAlwaysSimulate( self.nParticle)
    Timers:CreateTimer(nDist/3000 - 0.05, function()
        if type( self.nParticle) == "number" then
			ParticleManager:DestroyParticle( self.nParticle, false)
			ParticleManager:ReleaseParticleIndex( self.nParticle)
		end
    end)
    local tProjectile = {
		EffectName = "",
		Ability = self,
		vSpawnOrigin = hCaster:GetAbsOrigin(),
		vVelocity = vDir * 3000 ,
		fDistance = nDist,
		fStartRadius = 200,
		fEndRadius = 200,
		Source = hCaster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = 0,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		--bProvidesVision = true,
		bDeleteOnHit = false,
		--iVisionRadius = 500,
		--bFlyingVision = true,
		--iVisionTeamNumber = caster:GetTeamNumber(),
	}  
	self.iProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)
    local bHit = true
    -- local tUnits = FATE_FindUnitsInLine(hCaster:GetTeamNumber(), vOrigin,
    --     vOrigin + vDir * nDist, self:GetSpecialValueFor("wave_width"),
    --     self:GetAbilityTargetTeam(), self:GetAbilityTargetType(),
    --     self:GetAbilityTargetFlags(), FIND_ANY_ORDER)
    -- for _, hUnit in pairs(tUnits) do
    --     if IsNotNull(hUnit) and not IsSpellBlocked(hUnit, hCaster) then
    --         DoDamage(hCaster, hUnit, nDamage, self:GetAbilityDamageType(), 0, self, false)
    --         hUnit:AddNewModifier(hCaster, self, "modifier_stunned",
    --             {duration = self:GetSpecialValueFor("wave_ministun")})
    --         Barghest_FxAt(BARGHEST_FX.FIRE_HIT, hUnit:GetAbsOrigin())
    --         bHit = true
    --     end
    -- end
    return bHit
end

function barghest_r:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
  	local hCaster = self:GetCaster()
	if(hTarget ~= nil) then
		local enemies = FindUnitsInRadius(  hCaster:GetTeamNumber(),
						hTarget:GetAbsOrigin(),
                        nil,
                        200,
                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                        DOTA_UNIT_TARGET_ALL,
                        DOTA_UNIT_TARGET_FLAG_NONE,
                        FIND_ANY_ORDER,
                        false)
    
        for _,enemy in pairs(enemies) do
            DoDamage(hCaster, enemy, self:GetSpecialValueFor("damage"), self:GetAbilityDamageType(), 0, self, false)

        hTarget:EmitSound("arash_attack_hit")

        
        end
    end
   	Timers:CreateTimer(0.033,function()
   		ProjectileManager:DestroyLinearProjectile(self.iProjectile)
  	end)
	return true
end


---------------------------------------------------------------------------------------------------
-- Разгон: каждое попавшее продолжение ускоряет атаку и усиливает вампиризм F
---------------------------------------------------------------------------------------------------
modifier_barghest_frenzy = class({})

function modifier_barghest_frenzy:IsHidden()      return false end
function modifier_barghest_frenzy:IsDebuff()      return false end
function modifier_barghest_frenzy:IsPurgable()    return true end
function modifier_barghest_frenzy:RemoveOnDeath() return true end

function modifier_barghest_frenzy:GetTexture()
    return "custom/barghest/barghest_frenzy"
end

function modifier_barghest_frenzy:OnStackCountChanged(iStackCount)
    ParticleManager:SetParticleControl(self.particle_unbreak, 1, Vector((iStackCount + 1)*2,0,0))

end

function modifier_barghest_frenzy:OnCreated()
	self.particle_unbreak = ParticleManager:CreateParticle("particles/hijikata/barghest_passive.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
							ParticleManager:SetParticleControl(self.particle_unbreak, 0, self:GetParent():GetAbsOrigin())
							ParticleManager:SetParticleControl(self.particle_unbreak, 1, Vector(self:GetStackCount(),0,0))

	self:AddParticle(self.particle_unbreak, false, true, -1, true, false)
end

-- Без IsServer-гарда: бонус обязан считаться и на клиенте.
function modifier_barghest_frenzy:DeclareFunctions()
    return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end

function modifier_barghest_frenzy:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("frenzy_as") * self:GetStackCount()
end

---------------------------------------------------------------------------------------------------
-- Рывок рогами (WR). Отдельный motion controller — деши в аддоне только так.
---------------------------------------------------------------------------------------------------
modifier_barghest_r_horn = class({})

function modifier_barghest_r_horn:IsHidden()      return true end
function modifier_barghest_r_horn:IsDebuff()      return false end
function modifier_barghest_r_horn:IsPurgable()    return false end
function modifier_barghest_r_horn:RemoveOnDeath() return true end

function modifier_barghest_r_horn:CheckState()
    return {
        [MODIFIER_STATE_ROOTED]   = true,
        [MODIFIER_STATE_DISARMED] = true,
    }
end

function modifier_barghest_r_horn:OnCreated(tTable)
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
    if not IsServer() then return end

    self.vDir      = Vector(tTable.x, tTable.y, 0):Normalized()
    self.nSpeed    = self.hAbility:GetSpecialValueFor("horn_speed")
    self.nDistance = self.hAbility:GetSpecialValueFor("horn_distance")
    self.nStun     = self.hAbility:GetSpecialValueFor("horn_stun")
    self.nDamage   = self.hAbility:GetSpecialValueFor("damage")
    self.nGrab     = 200
    self.vStart    = self.hParent:GetAbsOrigin()
    self.bDone     = false

    self.hParent:SetForwardVector(self.vDir)
    if not self:ApplyHorizontalMotionController() then
        self:Destroy()
        return
    end

    self.nFxIndex = ParticleManager:CreateParticle(BARGHEST_FX.DASH,
        PATTACH_ABSORIGIN_FOLLOW, self.hParent)
    self:AddParticle(self.nFxIndex, false, false, -1, false, false)
end

function modifier_barghest_r_horn:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_barghest_r_horn:DeclareFunctions()
    return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE}
end

function modifier_barghest_r_horn:GetOverrideAnimation()
    return ACT_DOTA_CAST_SUN_STRIKE
end

function modifier_barghest_r_horn:GetOverrideAnimationRate()
    return 1
end
function modifier_barghest_r_horn:OnHorizontalMotionInterrupted()
    if not IsServer() then return end
    -- ⚠️ Без этого чужой контроллер оставит героя висеть.
    self.hParent:RemoveHorizontalMotionController(self)
    self:Destroy()
end

function modifier_barghest_r_horn:UpdateHorizontalMotion(hUnit, fTime)
    if not IsServer() then return end
    if self.bDone then return end

    local vNext = hUnit:GetAbsOrigin() + self.vDir * self.nSpeed * fTime
    if not GridNav:IsTraversable(vNext) or GridNav:IsBlocked(vNext)
       or (vNext - self.vStart):Length2D() > self.nDistance then
        self:Destroy()
        return
    end
    hUnit:SetAbsOrigin(vNext)
    local tUnits = FindUnitsInRadius(self.hParent:GetTeamNumber(), self.hParent:GetAbsOrigin(), nil, self.nGrab,
            self.hAbility:GetAbilityTargetTeam(), self.hAbility:GetAbilityTargetType(),
            self.hAbility:GetAbilityTargetFlags(), FIND_CLOSEST, false)
    if #tUnits > 0 then
        self.bDone = true
        self:Destroy()
        self.hAbility:RewardHit()
    end

    
end

function modifier_barghest_r_horn:OnDestroy()
    if not IsServer() then return end
    if Barghest_Alive(self.hParent) then
        self.hParent:RemoveHorizontalMotionController(self)
        FindClearSpaceForUnit(self.hParent, self.hParent:GetAbsOrigin(), true)
        EndAnimation(self.hParent)
        StartAnimation(self.hParent, {duration = 0.4,
        activity = ACT_DOTA_ICE_VORTEX, rate = 1.0})
        self.hParent:AddNewModifier(self.hParent, self:GetAbility(), "modifier_merlin_self_pause", {Duration = 0.20}) 
        local hCaster = self.hParent
        Barghest_FxCut(hCaster, 300, hCaster:GetAbsOrigin())
        Timers:CreateTimer(0.2, function()
        
            Barghest_FxOn(BARGHEST_FX.BURST, hCaster, 1.5)
            Barghest_FxAt(BARGHEST_FX.FIRE_HIT, hCaster:GetAbsOrigin())
            
        local tUnits = FindUnitsInRadius(hCaster:GetTeamNumber(), hCaster:GetAbsOrigin(), nil, self.nGrab,
            self.hAbility:GetAbilityTargetTeam(), self.hAbility:GetAbilityTargetType(),
            self.hAbility:GetAbilityTargetFlags(), FIND_CLOSEST, false)
        for _, hEnemy in pairs(tUnits) do
            
                DoDamage(hCaster, hEnemy, self.nDamage, self.hAbility:GetAbilityDamageType(),
                    0, self.hAbility, false)
                hEnemy:AddNewModifier(hCaster, self.hAbility, "modifier_stunned",
                    {duration = self.nStun})
                --Barghest_FxAt(BARGHEST_FX.SHOCK, hEnemy:GetAbsOrigin())
                hEnemy:EmitSound(BARGHEST_SND.R_IMPACT)
                return
           
        end
        
        end)
    end
end
