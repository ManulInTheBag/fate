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
       5 (E)  — волна энергии в виде чёрного пса: летит, разбивается о первого
                встречного и микростанит всех вокруг него

     Окно растёт с уровнем R (`window`). Попадание любым продолжением возвращает
     часть кулдауна Q и даёт стак разгона.
]]

-- modifier_barghest_continuation объявлен в barghest_shared: вешают его Q/W/E.
LinkLuaModifier("modifier_barghest_frenzy",       "abilities/barghest/barghest_r", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_burn",         "abilities/barghest/barghest_r", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_r_horn",       "abilities/barghest/barghest_r", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)
function barghest_r:GetAOERadius()
    return Barghest_Radius(self:GetCaster(), self:GetSpecialValueFor("radius"))
end

--[[ Что заряжено — числом, КЛИЕНТОБЕЗОПАСНО.
     ⚠️ GetModifierStackCount есть в обеих VM, а FindModifierByName только на
     сервере. Иконку слота считает клиент, поэтому здесь только это. ]]
--[[ Урон ветки с учётом третьего атрибута.

     Galatine's Ember, кроме дота горения, добавляет ВСЕМ веткам R прибавку
     от силы героя. Читается в одном месте, чтобы ветки не разъезжались:
     стоит забыть её в одной из пяти — и та молча останется слабее.
     ⚠️ GetStrength есть только у героев, гард обязателен. ]]
function barghest_r:GetBranchDamage()
    local nDamage = self:GetSpecialValueFor("damage")
    local hCaster = self:GetCaster()
    if Barghest_Alive(hCaster) and hCaster.BarghestAttr3Acquired
       and type(hCaster.GetStrength) == "function" then
        nDamage = nDamage + hCaster:GetStrength()
                  * self:GetSpecialValueFor("str_pct") * 0.01
    end
    return nDamage
end

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

--[[ Клип ветки для движка. Дублируется StartAnimation'ом в OnAbilityPhaseStart
     — см. комментарий там, это осознанно. ]]
function barghest_r:GetCastAnimation()
    return BARGHEST_R_ACT[self:GetArmedBranch()] or ACT_DOTA_CAST_ABILITY_6
end

--[[ ⚠️ Каст-пойнт решает ЭТОТ метод, а не AbilityCastPoint из KV: у волны (ER)
     замах длиннее остальных веток. KV-значение остаётся справочным и уходит в
     тултип через %AbilityCastPoint% — держать его равным `cast_point`. ]]
function barghest_r:GetCastPoint()
    if self:GetArmedBranch() == BARGHEST_CONT_E then
        return self:GetSpecialValueFor("wave_cast_point")
    end
    return self:GetSpecialValueFor("cast_point")
end

--[[ Замах ставим РУКАМИ поверх GetCastAnimation — тем же приёмом, что и в Q:
     веток пять, и без явного EndAnimation+StartAnimation движок не всегда
     переключал клип при смене заряженной ветки. ]]
function barghest_r:OnAbilityPhaseStart()
	local caster = self:GetCaster()
    EndAnimation(caster)
	StartAnimation(caster, {duration = self:GetCastPoint(),
        activity = BARGHEST_R_ACT[self:GetArmedBranch()] or ACT_DOTA_CAST_ABILITY_6,
        rate = 1})
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
    Barghest_Grunt(hCaster, BARGHEST_VO.R, 2)	-- выкрик на продолжение

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

--[[ Поджечь цель — атрибут 3 (Galatine's Ember).
     Каждое попавшее продолжение добавляет стак и обновляет длительность, то есть
     держать горение можно только продолжая ротацию qrqrqr. Без купленного
     атрибута не делает ничего.
     ⚠️ Зовётся из КАЖДОЙ ветки, где R наносит урон: ветка, забывшая позвать,
     молча не поджигает. ]]
function barghest_r:ApplyBurn(hUnit)
    if not IsServer() then return end
    local hCaster = self:GetCaster()
    if not hCaster.BarghestAttr3Acquired then return end
    if not IsNotNull(hUnit) or not hUnit:IsAlive() then return end
    if IsSpellBlocked(hUnit, hCaster) then return end

    local hBurn = hUnit:AddNewModifier(hCaster, self, "modifier_barghest_burn",
        {duration = self:GetSpecialValueFor("burn_duration")})
    if Barghest_Alive(hBurn) then
        hBurn:SetStackCount(math.min(self:GetSpecialValueFor("burn_max_stacks"),
            hBurn:GetStackCount() + 1))
    end
end

--[[ Урон по кругу БЕЗ эффектов на целях. ⚠️ Раньше тут на каждого задетого
     садился свой взрыв, и на пачке врагов Q3R превращалась в стену огня —
     удар об землю один, и вспышка у него должна быть одна, в точке удара
     (её ставит сам вызывающий). ]]
function barghest_r:DamageArea(vPos, nRadius, nDamage)
    local hCaster = self:GetCaster()
    local bHit = false
    local tUnits = FindUnitsInRadius(hCaster:GetTeamNumber(), vPos, nil, nRadius,
        self:GetAbilityTargetTeam(), self:GetAbilityTargetType(),
        self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
    for _, hUnit in pairs(tUnits) do
        if IsNotNull(hUnit) and not IsSpellBlocked(hUnit, hCaster) then
            DoDamage(hCaster, hUnit, nDamage, self:GetAbilityDamageType(), 0, self, false)
            self:ApplyBurn(hUnit)
            bHit = true
        end
    end
    return bHit
end

-- 1 (Q1) — вторая арка, меч в огне: та же дуга, но КРАСНАЯ, шире и с огнём
function barghest_r:DoBlazingArc(vDir)
    local hCaster = self:GetCaster()
    local nRadius = Barghest_Radius(hCaster, self:GetSpecialValueFor("radius"))
    local nAngle  = self:GetSpecialValueFor("arc_angle")
    local nDamage = self:GetBranchDamage()
    hCaster:EmitSound(BARGHEST_SND.R_FIRE)

    Barghest_FxArc(BARGHEST_FX.ARC_FIRE, hCaster, nRadius, nAngle)

    local bHit = false
    for _, hUnit in pairs(Barghest_FindInArc(hCaster, self, hCaster:GetAbsOrigin(), vDir,
                                             nRadius, nAngle)) do
        if not IsSpellBlocked(hUnit, hCaster) then
            DoDamage(hCaster, hUnit, nDamage, self:GetAbilityDamageType(), 0, self, false)
            self:ApplyBurn(hUnit)
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
    -- Свои радиус и сектор, а не доля от общих: подгонять зону под картинку
    -- эффекта нельзя — по узкому сектору в упор попасть почти невозможно.
    local nRadius = Barghest_Radius(hCaster, self:GetSpecialValueFor("uppercut_radius"))
    local nDamage = self:GetBranchDamage()
    local fUp = self:GetSpecialValueFor("uppercut_duration")
    hCaster:EmitSound(BARGHEST_SND.R_UPPER)

    -- Снизу вверх: рез идёт от земли перед ней к небу — это и читается как
    -- подброс, в отличие от горизонтальной дуги Q1R.
    Barghest_FxCutUp   (hCaster, nRadius, hCaster:GetAbsOrigin())
    Barghest_FxOn(BARGHEST_FX.BURST, hCaster, 1.5)
    local bHit = false
    for _, hUnit in pairs(Barghest_FindInArc(hCaster, self, vPos, vDir,
                                             nRadius, self:GetSpecialValueFor("uppercut_arc_angle"))) do
        if not IsSpellBlocked(hUnit, hCaster) then
            DoDamage(hCaster, hUnit, nDamage, self:GetAbilityDamageType(), 0, self, false)
            self:ApplyBurn(hUnit)
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
    local nRadius = Barghest_Radius(hCaster, self:GetSpecialValueFor("slam_radius"))
    hCaster:EmitSound(BARGHEST_SND.R_SLAM)

    -- Ровно два эффекта на весь удар: вспышка на самой Barghest и огонь в
    -- точке удара. Ничего пер-таргетного тут быть не должно.
    Barghest_FxOn(BARGHEST_FX.BURST, hCaster, 1.5)
    Barghest_FxAt(BARGHEST_FX.FIRE_HIT, vPos, hCaster)
    return self:DamageArea(vPos, nRadius, self:GetBranchDamage())
end

-- 4 (W) — рывок вперёд с ударом рогами
function barghest_r:DoHornCharge(vDir)
    local hCaster = self:GetCaster()
    -- ⚠️ Анимации здесь НЕТ: ACT_DOTA_OVERRIDE_ABILITY_2 — это и есть клип
    -- ветки WR, движок уже играет его по GetCastAnimation. Повторный запуск
    -- сбрасывал таран в самом начале рывка.
    EndAnimation(hCaster)
    -- Потолок жизни модификатора: расчётное время полёта плюс запас. Обычно
    -- таран кончается раньше сам — доехал, упёрся в рельеф или зацепил врага.
    local charge_duration = self:GetSpecialValueFor("horn_distance")
                 / self:GetSpecialValueFor("horn_speed")
                 + self:GetSpecialValueFor("horn_dash_tail")
    hCaster:EmitSound(BARGHEST_SND.R_HORN)
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

--[[ 5 (E) — волна в виде чёрного пса. Урон и микростан наносит не эта функция,
     а OnProjectileHit_ExtraData: пёс ЛЕТИТ, и бить всех на линии в момент каста
     было бы нечестно — попадание обязано совпадать с картинкой.
     ⚠️ Возвращает true ВСЕГДА, то есть стак разгона и возврат кулдауна ER даёт
     даже мимо. Так и задумано: тащить факт попадания обратно из колбэка
     проджектайла ради одного стака не стоит усложнения. ]]
function barghest_r:DoHoundWave(vDir)
    local hCaster = self:GetCaster()
    local vOrigin = hCaster:GetAbsOrigin()
    local nDist   = self:GetSpecialValueFor("wave_distance")
    local nSpeed  = self:GetSpecialValueFor("wave_speed")
    local nWidth  = Barghest_Radius(hCaster, self:GetSpecialValueFor("wave_width"))
    hCaster:EmitSound(BARGHEST_SND.R_WAVE)

    Barghest_FxLine(hCaster, vDir, nDist, nWidth)

    --[[ Пёс — ОТДЕЛЬНЫЙ партикль, а не EffectName проджектайла: скорость он
         берёт с CP1, точку исчезновения с CP6, и движковый снаряд их не задаёт.
         Поэтому обоим даём одну и ту же wave_speed — разъедутся, и урон пойдёт
         мимо картинки. ]]
    local sParticle = "particles/barghest/barghest_black_dog_proj.vpcf"
     self.nParticle =  ParticleManager:CreateParticle(sParticle, PATTACH_WORLDORIGIN, nil)

    ParticleManager:SetParticleControl( self.nParticle, 0, vOrigin)
    ParticleManager:SetParticleControl( self.nParticle, 1, nSpeed * vDir)
    ParticleManager:SetParticleControl( self.nParticle, 6, (vDir * nDist) + vOrigin)
    ParticleManager:SetParticleControl( self.nParticle, 15, Vector(0,0,0))
        ParticleManager:SetParticleShouldCheckFoW( self.nParticle, false)
    ParticleManager:SetParticleAlwaysSimulate( self.nParticle)
    -- ⚠️ Убираем РУКАМИ и чуть раньше конца пути: сам он не умирает и без этого
    -- висит в точке прибытия.
    Timers:CreateTimer(nDist / nSpeed - 0.05, function()
        if type( self.nParticle) == "number" then
			ParticleManager:DestroyParticle( self.nParticle, false)
			ParticleManager:ReleaseParticleIndex( self.nParticle)
		end
    end)
    local tProjectile = {
		EffectName = "",            -- картинку рисует партикль пса выше
		Ability = self,
		vSpawnOrigin = hCaster:GetAbsOrigin(),
		vVelocity = vDir * nSpeed ,
		fDistance = nDist,
		fStartRadius = nWidth,
		fEndRadius = nWidth,
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
    return true
end

--[[ Попадание волны. Бьёт не по одной цели, а по всем в wave_hit_radius вокруг
     неё: пёс большой, и урон только по задетой модели читался бы как промах.
     ⚠️ Проджектайл убиваем СРАЗУ после первого попадания (bDeleteOnHit = false,
     значит сам он летел бы дальше и собирал цель за целью): волна должна
     разбиться о первого встречного, как и обещает описание. Через таймер, а не
     прямо здесь — уничтожать снаряд из его же колбэка нельзя. ]]
function barghest_r:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
  	local hCaster = self:GetCaster()
	if(hTarget ~= nil) then
		local enemies = FindUnitsInRadius(  hCaster:GetTeamNumber(),
						hTarget:GetAbsOrigin(),
                        nil,
                        Barghest_Radius(hCaster, self:GetSpecialValueFor("wave_hit_radius")),
                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                        DOTA_UNIT_TARGET_ALL,
                        DOTA_UNIT_TARGET_FLAG_NONE,
                        FIND_ANY_ORDER,
                        false)

        local fStun = self:GetSpecialValueFor("wave_ministun")
        for _,enemy in pairs(enemies) do
            if IsNotNull(enemy) and not IsSpellBlocked(enemy, hCaster) then
                DoDamage(hCaster, enemy, self:GetBranchDamage(),
                    self:GetAbilityDamageType(), 0, self, false)
                self:ApplyBurn(enemy)
                -- Микростан: сам по себе он ничего не решает, но сбивает касты и
                -- даёт Barghest время подойти — ради этого ветку и берут.
                enemy:AddNewModifier(hCaster, self, "modifier_stunned",
                    {duration = fStun})
                enemy:EmitSound(BARGHEST_SND.R_HOUND)
            end
        end
    end
   	Timers:CreateTimer(0.033,function()
   		ProjectileManager:DestroyLinearProjectile(self.iProjectile)
  	end)
	return true
end


---------------------------------------------------------------------------------------------------
-- Горение (атрибут 3). Стаки копятся с каждого попавшего продолжения, тик бьёт
-- burn_damage за стак в секунду.
---------------------------------------------------------------------------------------------------
modifier_barghest_burn = class({})

function modifier_barghest_burn:IsHidden()      return false end
function modifier_barghest_burn:IsDebuff()      return true end
function modifier_barghest_burn:IsPurgable()    return true end
function modifier_barghest_burn:RemoveOnDeath() return true end

function modifier_barghest_burn:GetTexture()
    return "custom/barghest/barghest_cont_3"
end

-- Пламя на цели. ⚠️ Партикль чужой (muramasa), поэтому он прекешится в KV R.
function modifier_barghest_burn:GetEffectName()
    return "particles/muramasa/muramasa_rush_burn.vpcf"
end

function modifier_barghest_burn:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_barghest_burn:OnCreated()
    self.hAbility = self:GetAbility()
    if not IsServer() then return end
    self:StartIntervalThink(self.hAbility:GetSpecialValueFor("burn_interval"))
end

-- ⚠️ OnRefresh НЕ трогает стаки: их считает ApplyBurn, иначе обновление
-- длительности сбрасывало бы накопленное.
function modifier_barghest_burn:OnRefresh()
    self:OnCreated()
end

function modifier_barghest_burn:OnIntervalThink()
    if not IsServer() then return end
    local hParent  = self:GetParent()
    local hCaster  = self:GetCaster()
    local hAbility = self.hAbility
    if not Barghest_Alive(hParent) or not Barghest_Alive(hCaster)
       or not Barghest_Alive(hAbility) then
        return
    end
    if not hParent:IsAlive() then return end

    -- burn_damage задан В СЕКУНДУ за стак, поэтому тик умножаем на интервал.
    local fInterval = hAbility:GetSpecialValueFor("burn_interval")
    DoDamage(hCaster, hParent,
        hAbility:GetSpecialValueFor("burn_damage") * self:GetStackCount() * fInterval,
        hAbility:GetAbilityDamageType(), 0, hAbility, false)
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
    self.nDistance = Barghest_Dash(self.hParent, self.hAbility:GetSpecialValueFor("horn_distance"))
    self.nStun     = self.hAbility:GetSpecialValueFor("horn_stun")
    self.nDamage   = self.hAbility:GetBranchDamage()
    self.nGrab     = Barghest_Radius(self.hParent, self.hAbility:GetSpecialValueFor("horn_grab_radius"))
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

        --[[ Таран кончился (доехал, упёрся, зацепил врага) — отыгрываем сам
             удар рогами. Пауза modifier_merlin_self_pause держит её на месте,
             пока клип идёт: иначе с первого же кадра можно убежать и удара не
             видно. Длится ровно до момента урона (horn_impact_delay). ]]
        local hAbility = self.hAbility
        local fImpact  = hAbility:GetSpecialValueFor("horn_impact_delay")

        EndAnimation(self.hParent)
        StartAnimation(self.hParent, {duration = hAbility:GetSpecialValueFor("horn_impact_anim"),
        activity = ACT_DOTA_ICE_VORTEX, rate = 1.0})
        self.hParent:AddNewModifier(self.hParent, self:GetAbility(), "modifier_merlin_self_pause", {Duration = fImpact})
        local hCaster = self.hParent
        Barghest_FxCut(hCaster, Barghest_Radius(hCaster, hAbility:GetSpecialValueFor("horn_cut_radius")), hCaster:GetAbsOrigin())
        local nGrab   = self.nGrab
        local nDamage = self.nDamage
        local nStun   = self.nStun
        Timers:CreateTimer(fImpact, function()
            -- ⚠️ Гарды обязательны: за эти доли секунды её могли убить, а
            -- способность — забрать рулбрейкером.
            if not Barghest_Alive(hCaster) or not hCaster:IsAlive() then return end
            if not Barghest_Alive(hAbility) then return end

            Barghest_FxOn(BARGHEST_FX.BURST, hCaster, 1.5)
            Barghest_FxAt(BARGHEST_FX.FIRE_HIT, hCaster:GetAbsOrigin(), hCaster)

            --[[ Удар рогами звучит ВСЕГДА, даже когда таран доехал в пустоту:
                 партиклы выше играют безусловно, и без звука конец разгона
                 выглядел оборванным. Поэтому звук на КАСТЕРЕ, а не на жертве —
                 иначе при промахе его некому отыграть, а при попадании он бы
                 задвоился (жертва стоит вплотную, разницы в позиции нет). ]]
            hCaster:EmitSound(BARGHEST_SND.R_IMPACT)

            -- Бьёт ОДНОГО, ближайшего: это таран рогами, а не АоЕ — отсюда
            -- FIND_CLOSEST и выход из цикла на первом же враге.
            local tUnits = FindUnitsInRadius(hCaster:GetTeamNumber(), hCaster:GetAbsOrigin(), nil, nGrab,
                hAbility:GetAbilityTargetTeam(), hAbility:GetAbilityTargetType(),
                hAbility:GetAbilityTargetFlags(), FIND_CLOSEST, false)
            for _, hEnemy in pairs(tUnits) do
                if IsNotNull(hEnemy) and not IsSpellBlocked(hEnemy, hCaster) then
                    DoDamage(hCaster, hEnemy, nDamage, hAbility:GetAbilityDamageType(),
                        0, hAbility, false)
                    hAbility:ApplyBurn(hEnemy)
                    hEnemy:AddNewModifier(hCaster, hAbility, "modifier_stunned",
                        {duration = nStun})
                    return
                end
            end
        end)
    end
end
