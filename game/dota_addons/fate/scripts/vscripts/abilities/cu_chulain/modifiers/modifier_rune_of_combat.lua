modifier_rune_of_combat = class({})

LinkLuaModifier("modifier_rune_of_combat_hit", "abilities/cu_chulain/modifiers/modifier_rune_of_combat_hit", LUA_MODIFIER_MOTION_NONE)

-- запас к дальности атаки на бегу, чтобы удар не обрывался от пары юнитов дистанции
local ATTACK_RANGE_BUFFER = 75
local ATTACK_GESTURES = { ACT_DOTA_ATTACK, ACT_DOTA_ATTACK2 }
-- Какую долю замаха (с конца, вплотную к удару) держать морду на цели.
-- Движение в Доте идёт вдоль yaw, поэтому пока угол держится, отойти от цели нельзя —
-- отсюда рывок на каждый удар. 1.0 = весь замах (~24% времени, разворот заметнее, ход
-- дёргается сильнее), 0.3 = только момент удара, 0 = не разворачивать вовсе.
local FACE_LOCK_SHARE = 1.0
-- BAT героя из npc_fate_hero_cu_chulain.kv ("AttackRate"): нужен, чтобы посчитать интервал
-- между ударами. GetBaseAttackTime()/GetSecondsPerAttack() без аргумента падают, а с
-- GetAttackSpeed(true) (множитель, 1.0 на базе) интервал = BAT / множитель.
local BASE_ATTACK_TIME = 1.7

-- MODIFIER_EVENT_ON_ATTACK_LANDED тут объявлять нельзя: OnAttackLanded раздаёт
-- AttackLandedCentralized, и он пропускает модификаторы, у которых событие объявлено
function modifier_rune_of_combat:DeclareFunctions()
	return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
			 MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			 MODIFIER_EVENT_ON_ORDER }
end

if IsServer() then

	function modifier_rune_of_combat:OnCreated(args)
		self.BaseDamage = 25
		self.BonusAtkPct = args.BonusAtkPct
		self.StunDuration = args.StunDuration
		self.AttackSpeed = self:GetAbility():GetSpecialValueFor("bonus_attackspeed")
		self.attackCounter = 0
		self.target = nil
		self.iGesture = nil
		self.bFocusing = true
		self.nextSwing = 0		-- когда можно начинать следующий замах
		self.swingHitAt = nil	-- момент, когда текущий замах должен ударить
		self.swingFaceFrom = 0	-- с какого момента замаха держим морду на цели
		self.swingTarget = nil
		self:SetStackCount(self.AttackSpeed)
		CustomNetTables:SetTableValue("sync","rune_of_ferocity", { attack_speed = self.AttackSpeed })
		CustomNetTables:SetTableValue("sync","rune_of_combat_damage", { atk_bonus = self.BaseDamage })

		-- кольцо реальной досягаемости удара на бегу (та же дистанция, что проверяет IsValidVictim),
		-- чтобы на глаз понимать, добьёт он цель на ходу или нет
		local parent = self:GetParent()
		self.ringFx = ParticleManager:CreateParticle("particles/zlodemon/zlodemon_basic_circle.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControl(self.ringFx, 0, parent:GetAbsOrigin())
		ParticleManager:SetParticleControl(self.ringFx, 1, Vector(1, 0.1, 0.1))
		ParticleManager:SetParticleControl(self.ringFx, 2,
			Vector(parent:Script_GetAttackRange() + ATTACK_RANGE_BUFFER, self:GetDuration(), 0))

		self:AcquireTarget()
		self:StartIntervalThink(FrameTime())
	end

	function modifier_rune_of_combat:OnRefresh(args)
		self:DestroyRing()
		self:OnCreated(args)
	end

	function modifier_rune_of_combat:DestroyRing()
		if self.ringFx then
			ParticleManager:DestroyParticle(self.ringFx, false)
			ParticleManager:ReleaseParticleIndex(self.ringFx)
			self.ringFx = nil
		end
	end

	function modifier_rune_of_combat:OnDestroy()
		self:DestroyRing()
		local parent = self:GetParent()
		if self.iGesture and parent and not parent:IsNull() then
			parent:FadeGesture(self.iGesture)
		end
	end

	-- Разовый приказ атаковать ближайшего врага в радиусе — чтобы после каста руны не надо
	-- было отдельно кликать по цели. Приоритет героям. Если герой уже кого-то атакует,
	-- не перебиваем: игрок выбрал цель сам.
	function modifier_rune_of_combat:AcquireTarget()
		local parent = self:GetParent()
		if self:IsValidVictim(parent:GetAggroTarget()) then return end

		local fRadius = parent:Script_GetAttackRange() + ATTACK_RANGE_BUFFER
		local hTarget = nil
		for _, iTypeFlag in ipairs({ DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC }) do
			local tUnits = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetAbsOrigin(), nil,
				fRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, iTypeFlag,
				DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
			for _, hUnit in pairs(tUnits) do
				if self:IsValidVictim(hUnit) then
					hTarget = hUnit
					break
				end
			end
			if hTarget then break end
		end
		if not hTarget then return end

		ExecuteOrderFromTable({
			UnitIndex   = parent:GetEntityIndex(),
			OrderType   = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = hTarget:GetEntityIndex(),
			Queue       = false,
		})
		self.target    = hTarget
		self.bFocusing = true
	end

	-- Разворот корпуса на цель. FaceTowards тут бесполезен — это «просьба довернуться»,
	-- которую контроллер движения перетирает своим курсом на том же тике; SetForwardVector
	-- пишет угол напрямую. Зовётся только внутри замаха: движение идёт вдоль yaw, и держать
	-- угол постоянно = запретить герою отходить от цели (проверено, он просто бежит на неё).
	function modifier_rune_of_combat:FaceTarget(hTarget)
		local parent = self:GetParent()
		local vDir   = hTarget:GetAbsOrigin() - parent:GetAbsOrigin()
		vDir.z = 0
		if vDir:Length2D() > 1 then
			parent:SetForwardVector(vDir:Normalized())
		end
	end

	-- можно ли вообще замахнуться прямо сейчас.
	-- AttackReady() тут намеренно НЕ проверяется: темп держит self.nextSwing, а движковый
	-- кулдаун стартует только в момент удара (на длину замаха позже) и резал бы скорость атаки.
	function modifier_rune_of_combat:CanSwing()
		local parent = self:GetParent()
		return parent:IsAlive()
		   and parent:IsMoving()			-- стоим на месте — пусть бьёт движок, иначе двойные атаки
		   and not parent:IsAttacking()
		   and not parent:IsStunned()
		   and not parent:IsDisarmed()
		   and not parent:IsHexed()
		   and not parent:IsCommandRestricted()
	end

	function modifier_rune_of_combat:IsValidVictim(hTarget)
		local parent = self:GetParent()
		if not hTarget or hTarget:IsNull() or not hTarget:IsAlive() then return false end
		if hTarget:GetTeamNumber() == parent:GetTeamNumber() then return false end
		if hTarget:IsInvulnerable() or hTarget:IsAttackImmune() then return false end
		if not parent:CanEntityBeSeenByMyTeam(hTarget) then return false end

		-- хиты обоих юнитов обязательны: движок меряет дальность атаки между габаритами,
		-- а не между центрами. Без этого по толстой цели мы «не достаём» там, где движок достаёт
		local fReach = parent:Script_GetAttackRange() + ATTACK_RANGE_BUFFER
					 + parent:GetHullRadius() + hTarget:GetHullRadius()
		local vDiff = hTarget:GetAbsOrigin() - parent:GetAbsOrigin()
		if vDiff:Length2D() > fReach then return false end
		return true
	end

	-- Текущая цель фокуса: то, во что реально целится герой (аггро-цель движка), иначе
	-- последняя ударенная. Одна и та же цель и для разворота, и для ударов на бегу.
	-- Залоченная цель имеет приоритет над аггро-целью движка. Наоборот было нельзя: при беге
	-- вокруг врага приказ движения сбрасывает аггро, а рядом стоящий крип его перехватывает —
	-- фокус прыгал сам собой. Ручная смена цели всё равно проходит: правый клик по врагу
	-- обновляет self.target через OnOrder, а удар — через OnAttackLanded.
	function modifier_rune_of_combat:ResolveTarget()
		if self:IsValidVictim(self.target) then return self.target end

		local hAggro = self:GetParent():GetAggroTarget()
		if self:IsValidVictim(hAggro) then
			self.target = hAggro
			return hAggro
		end
		return nil
	end

	-- Удар разнесён на две фазы, как у обычной атаки: сначала замах, урон — только когда
	-- анимация дошла до точки удара (GetAttackAnimationPoint).
	function modifier_rune_of_combat:OnIntervalThink()
		local parent = self:GetParent()
		local now    = GameRules:GetGameTime()

		local hFocus = self:ResolveTarget()

		-- ФАЗА ЗАМАХА: доворачиваемся на цель и ждём момента удара
		if self.swingHitAt then
			local hTarget = self.swingTarget
			if not self:IsValidVictim(hTarget)
				or not parent:IsAlive() or parent:IsStunned() or parent:IsDisarmed() then
				-- Замах сорвался — удара не было, значит и кулдаун атаки съедать нельзя.
				-- Без этого сброса один кадр «цель выпала из радиуса» (а при беге вокруг
				-- дистанция всё время на грани) стоил целого пропущенного удара.
				self.swingHitAt, self.swingTarget = nil, nil
				self.nextSwing = now
				return
			end
			-- каждый тик, иначе движок возвращает героя на курс. Во время чтения не лезем:
			-- там углом распоряжается сама способность.
			if now >= self.swingFaceFrom and not parent:IsChanneling() then
				self:FaceTarget(hTarget)
			end
			if now >= self.swingHitAt then
				self.swingHitAt, self.swingTarget = nil, nil
				self.bManualHit = true	-- чтобы OnAttackLanded не сдвинул наш собственный темп
				parent:PerformAttack(hTarget, true, true, false, true, true, false, false)
			end
			return
		end

		-- ЗАМАХА НЕТ: решаем, начинать ли новый
		if not self.bFocusing then return end
		if now < self.nextSwing then return end
		if not self:CanSwing() then return end
		if not hFocus then return end
		local hTarget = hFocus

		-- GetAttackSpeed(true) = множитель скорости атаки (1.0 на базе). Он же playback rate:
		-- без него жест рассчитан на базовый BAT, не доигрывает и перезапускается сам поверх себя.
		local fAttackSpeed = math.max(parent:GetAttackSpeed(true), 0.1)
		local rate         = math.max(0.5, math.min(fAttackSpeed, 4.0))

		if self.iGesture then parent:RemoveGesture(self.iGesture) end
		self.iGesture = ATTACK_GESTURES[RandomInt(1, #ATTACK_GESTURES)]
		parent:StartGestureWithPlaybackRate(self.iGesture, rate)

		-- сбрасываем на случай, если прошлый удар промазал: OnAttackLanded тогда не пришёл
		-- и флаг завис бы взведённым
		self.bManualHit  = false
		local fWindup    = parent:GetAttackAnimationPoint() / rate
		self.swingTarget = hTarget
		self.swingHitAt  = now + fWindup
		self.swingFaceFrom = now + fWindup * (1 - FACE_LOCK_SHARE)
		self.nextSwing   = now + BASE_ATTACK_TIME / fAttackSpeed
	end

	function modifier_rune_of_combat:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end
		local ability = self:GetAbility()
		if not ability then return end

		self.attackCounter = self.attackCounter + 1
		self.BaseDamage = math.min(self.BaseDamage + self.BonusAtkPct, ability:GetSpecialValueFor("bonus_atk_max"))
		CustomNetTables:SetTableValue("sync","rune_of_combat_damage", { atk_bonus = self.BaseDamage })
		self:SetStackCount(self.AttackSpeed)
		CustomNetTables:SetTableValue("sync","rune_of_ferocity", { attack_speed = self.AttackSpeed })

		if args.target and not args.target:IsNull() then
			args.target:AddNewModifier(args.attacker, ability, "modifier_rune_of_combat_hit", { Duration = 3 })
			-- залипаем на том, кого только что ударили: это и есть «фокус»
			self.target = args.target
			self.bFocusing = true
		end

		-- обычная атака движком (стоя на месте) сдвигает наш темп, чтобы при переходе
		-- в бег не выдать лишний бесплатный удар. Свои удары темп не трогают: он уже
		-- отсчитан от начала замаха.
		if self.bManualHit then
			self.bManualHit = false
		else
			self.nextSwing = GameRules:GetGameTime()
				+ BASE_ATTACK_TIME / math.max(self:GetParent():GetAttackSpeed(true), 0.1)
		end
	end

	function modifier_rune_of_combat:OnOrder(keys)
		if keys.unit ~= self:GetParent() then return end
		local iOrder = keys.order_type

		if iOrder == DOTA_UNIT_ORDER_STOP or iOrder == DOTA_UNIT_ORDER_HOLD_POSITION then
			self.target = nil
			self.bFocusing = false
		elseif iOrder == DOTA_UNIT_ORDER_ATTACK_TARGET then
			local hTarget = keys.target
			if type(hTarget) == "number" then hTarget = EntIndexToHScript(hTarget) end
			self.target = hTarget
			self.bFocusing = true
		elseif iOrder == DOTA_UNIT_ORDER_MOVE_TO_POSITION
			or iOrder == DOTA_UNIT_ORDER_MOVE_TO_TARGET
			or iOrder == DOTA_UNIT_ORDER_ATTACK_MOVE then
			self.bFocusing = true
		end
	end

end

function modifier_rune_of_combat:GetModifierAttackSpeedBonus_Constant()
	if IsServer() then
		return self.AttackSpeed or 0
	end
	local tbl = CustomNetTables:GetTableValue("sync","rune_of_ferocity")
	return tbl and tbl.attack_speed or 0
end

function modifier_rune_of_combat:GetModifierBaseDamageOutgoing_Percentage()
	if IsServer() then
		return self.BaseDamage or 0
	end
	local tbl = CustomNetTables:GetTableValue("sync","rune_of_combat_damage")
	return tbl and tbl.atk_bonus or 0
end

function modifier_rune_of_combat:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_rune_of_combat:GetStatusEffectName()
	return "particles/status_fx/status_effect_beserkers_call.vpcf"
end
