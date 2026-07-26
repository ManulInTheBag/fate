-- berserker_5th_fissure_strike — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/heracles/heracles_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

berserker_5th_fissure_strike = class({})

LinkLuaModifier("modifier_fissure_strike_slow", "abilities/heracles/berserker_5th_fissure_strike", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/berserker_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnFissureStart, OnFissureHit, BerCheckCombo

OnFissureStart = function(keys)
	local caster = keys.caster
	local frontward = (keys.ability:GetCursorPosition() - caster:GetAbsOrigin()):Normalized()
	local fiss = 
	{
		Ability = keys.ability,
        EffectName = "particles/custom/berserker/fissure_strike/shockwave.vpcf",
        iMoveSpeed = keys.Speed,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = keys.Range + caster:GetStrength()*(caster.IsDivinityImproved and 1 or 0),
        fStartRadius = keys.Width,
        fEndRadius = keys.Width,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 0.5,
		bDeleteOnHit = false,
		vVelocity = frontward * keys.Speed
	}
	caster.FissureOrigin  = caster:GetAbsOrigin()
	caster.FissureTarget = keys.ability:GetCursorPosition()
	if caster:HasModifier("modifier_heracles_berserk") and (keys.ability:GetLevel()>69) then
		StartAnimation(caster, {duration=1.8, activity=ACT_DOTA_OVERRIDE_ABILITY_1, rate=1.7})
		giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 1.4)
		Timers:CreateTimer(0.8, function()
			local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        500,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_NONE,
                                        FIND_ANY_ORDER,
                                        false)

			caster:EmitSound("Heracles_Roar_" .. math.random(1,6))
			
		    for _,enemy in pairs(enemies) do
		        local caster_angle = caster:GetAnglesAsVector().y
		        local origin_difference = caster:GetAbsOrigin() - enemy:GetAbsOrigin()

		        local origin_difference_radian = math.atan2(origin_difference.y, origin_difference.x)

		        origin_difference_radian = origin_difference_radian * 180
		        local enemy_angle = origin_difference_radian / math.pi

		        enemy_angle = enemy_angle + 180.0

		        local result_angle = enemy_angle - caster_angle
		        result_angle = math.abs(result_angle)

		        if result_angle <= 160 then
				    caster:PerformAttack(enemy, true, true, true, true, false, false, false)
				    DoCleaveAttack(caster, enemy, keys.ability, 0, 200, 400, 500, "particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave_gods_strength.vpcf")
		        end
		    end
		end)
		Timers:CreateTimer(1.15, function()
			local enemies = FindUnitsInLine(
								        caster:GetTeamNumber(),
								        caster:GetAbsOrigin(),
								        caster:GetAbsOrigin() + caster:GetForwardVector()*400,
								        nil,
								        350,
										DOTA_UNIT_TARGET_TEAM_ENEMY,
										DOTA_UNIT_TARGET_ALL,
										DOTA_UNIT_TARGET_FLAG_NONE
    								)

			caster:EmitSound("Heracles_Roar_" .. math.random(1,6))

			for _,enemy in pairs(enemies) do
				DoDamage(caster, enemy, caster:GetAverageTrueAttackDamage(caster)*2, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
				enemy:AddNewModifier(caster, enemy, "modifier_stunned", {Duration = 0.5})
				enemy:EmitSound("Hero_Centaur.HoofStomp")
				ParticleManager:CreateParticle("particles/custom/berserker/courage/stun_explosion.vpcf", PATTACH_ABSORIGIN, enemy)
		    end
		end)
		Timers:CreateTimer(1.4, function()
			local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin() + caster:GetForwardVector()*200,
                                        nil,
                                        500,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_NONE,
                                        FIND_ANY_ORDER,
                                        false)

			caster:EmitSound("Heracles_Roar_" .. math.random(1,6))
			caster:EmitSound("Hero_EarthShaker.Fissure")

			local fiss2 = 
			{
				Ability = keys.ability,
		        EffectName = "particles/custom/berserker/fissure_strike/shockwave.vpcf",
		        iMoveSpeed = keys.Speed,
		        vSpawnOrigin = caster:GetAbsOrigin(),
		        fDistance = keys.Range + caster:GetStrength()*(caster.IsEternalRageAcquired and 1 or 0),
		        fStartRadius = keys.Width,
		        fEndRadius = keys.Width,
		        Source = caster,
		        bHasFrontalCone = true,
		        bReplaceExisting = false,
		        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		        fExpireTime = GameRules:GetGameTime() + 0.5,
				bDeleteOnHit = false,
				vVelocity = frontward * keys.Speed
			}
			caster.FissureOrigin  = caster:GetAbsOrigin()
			caster.FissureTarget = keys.ability:GetCursorPosition()

			projectile = ProjectileManager:CreateLinearProjectile(fiss2)

			local hit_fx = ParticleManager:CreateParticle("particles/atalanta/atalanta_earthshock.vpcf", PATTACH_ABSORIGIN, caster )
			ParticleManager:SetParticleControl( hit_fx, 0, GetGroundPosition(caster:GetAbsOrigin() + caster:GetForwardVector()*200, caster))
			ParticleManager:SetParticleControl( hit_fx, 1, Vector(500, 300, 150))
			for _,enemy in pairs(enemies) do
				DoDamage(caster, enemy, caster:GetAverageTrueAttackDamage(caster)*3, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
				ApplyAirborne(caster, enemy, 0.7)
		    end
		end)
		keys.ability:EndCooldown()
		keys.ability:StartCooldown(keys.ability:GetSpecialValueFor("reduced_cd"))
	else
		caster:EmitSound("Heracles_Roar_" .. math.random(1,6))
		LoopOverPlayers(function(player, playerID, playerHero)
			--print("looping through " .. playerHero:GetName())
			if playerHero.zlodemon == true then
				-- apply legion horn vsnd on their client
				CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_herc_q"})
				--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
			end
		end)
		projectile = ProjectileManager:CreateLinearProjectile(fiss)
	end
	BerCheckCombo(caster, keys.ability)

	--[[if caster:GetIntellect() >= 80 then
		if caster:FindAbilityByName("pepeg_combo_final_gachi"):IsCooldownReady() then
			caster:SwapAbilities("berserker_5th_fissure_strike", "pepeg_combo_final_gachi", false, true)
			Timers:CreateTimer(4, function()
				caster:SwapAbilities("berserker_5th_fissure_strike", "pepeg_combo_final_gachi", true, false)
			end)
		end
	end]]

	if caster:GetStrength() >= 39.1 and caster:GetAgility() >= 39.1 then
		if caster:FindAbilityByName("berserker_5th_madmans_roar"):IsCooldownReady() then
			caster.QUsed = true
			Timers:CreateTimer(4, function()
				caster.QUsed = false
			end)
		end
	end
end

OnFissureHit = function(keys)
	local caster = keys.caster
	local target = keys.target
	local courageAbility = caster:FindAbilityByName("berserker_5th_courage")
	local casterOrirgin = caster:GetAbsOrigin()
	--[[if caster:HasModifier("modifier_courage_damage_stack_indicator") then
		keys.Damage = keys.Damage + courageAbility:GetLevelSpecialValueFor("bonus_damage", courageAbility:GetLevel()-1)/2
		DeductCourageDamageStack(caster)
	end]]

	DoDamage(keys.caster, keys.target, keys.Damage + caster:GetStrength()*(caster.IsEternalRageAcquired and 0.25 or 0), DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	if not IsImmuneToSlow(target) then target:AddNewModifier(caster, keys.ability, "modifier_fissure_strike_slow", {}) end

	if caster:HasModifier("modifier_heracles_berserk") and ((target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() <= 300) then
		DoDamage(keys.caster, keys.target, 0.5*caster:GetAverageTrueAttackDamage(caster), DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
		target:AddNewModifier(caster, target, "modifier_stunned", { Duration = 0.5 })
	end

	giveUnitDataDrivenModifier(keys.caster, keys.target, "pause_sealenabled", 0.01)
	if not IsKnockbackImmune(target) then
	    local pushTarget = Physics:Unit(target)
	    target:PreventDI()
	    target:SetPhysicsFriction(0)
		local vectorC = (caster.FissureTarget - caster.FissureOrigin) + Vector(0,0,100) --knockback in direction as fissure
		-- get the direction where target will be pushed back to
		target:SetPhysicsVelocity(vectorC:Normalized() * -1500)
	    target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
		local initialUnitOrigin = keys.target:GetAbsOrigin()
		local initialCasterOrigin = keys.caster:GetAbsOrigin()
		
		target:OnPhysicsFrame(function(unit) -- pushback distance check
			local unitOrigin = unit:GetAbsOrigin()
			local diff = unitOrigin - initialUnitOrigin
			local n_diff = diff:Normalized()
			if (casterOrirgin - unitOrigin):Length2D() < 100 then
				unit:PreventDI(false)
				unit:SetPhysicsVelocity(Vector(0,0,0))
				unit:OnPhysicsFrame(nil)
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
			end
			unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) -- track the movement of target being pushed back
			if diff:Length() > (caster:FindAbilityByName("berserker_5th_fissure_strike"):GetSpecialValueFor("knockback") + caster:GetStrength()*(caster.IsEternalRageAcquired and 0.5 or 0)) then -- if pushback distance is over 400, stop it
				unit:PreventDI(false)
				unit:SetPhysicsVelocity(Vector(0,0,0))
				unit:OnPhysicsFrame(nil)
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
			end
		end)		
		
		target:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
			unit:SetBounceMultiplier(0)
			unit:PreventDI(false)
			unit:SetPhysicsVelocity(Vector(0,0,0))
			target:AddNewModifier(caster, target, "modifier_stunned", { Duration = caster:FindAbilityByName("berserker_5th_fissure_strike"):GetSpecialValueFor("collide_duration") })
			DoDamage(caster, target, keys.CollideDamage + caster:GetStrength()*(caster.IsEternalRageAcquired and 0.1 or 0), DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
			--giveUnitDataDrivenModifier(caster, target, "stunned",  caster:FindAbilityByName("berserker_5th_fissure_strike"):GetSpecialValueFor("collide_duration"))
		end)
	end
end

BerCheckCombo = function(caster, ability)
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if ability == caster:FindAbilityByName("berserker_5th_fissure_strike") then
			QUsed = true
			QTime = GameRules:GetGameTime()
			Timers:CreateTimer({
				endTime = 4,
				callback = function()
				QUsed = false
			end
			})
		elseif ability == caster:FindAbilityByName("berserker_5th_berserk") and caster:FindAbilityByName("berserker_5th_courage"):IsCooldownReady() and caster:FindAbilityByName("berserker_5th_madmans_roar"):IsCooldownReady()  then
			if QUsed == true then 
				caster:SwapAbilities("berserker_5th_madmans_roar", "berserker_5th_courage", true, false) 
				local newTime =  GameRules:GetGameTime()
				Timers:CreateTimer({
					endTime = 4 - (newTime - QTime),
					callback = function()
					caster:SwapAbilities("berserker_5th_madmans_roar", "berserker_5th_courage", false, true) 
					QUsed = false
				end
				})
			end
		end
	end
end


function berserker_5th_fissure_strike:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: berserker_ability / OnFissureStart
	OnFissureStart({
		caster = caster,
		ability = self,
		target = caster,
		target_points = { point },
		Target = "POINT",
		Width = self:GetSpecialValueFor("radius"),
		Range = self:GetSpecialValueFor("range"),
		Speed = self:GetSpecialValueFor("proj_speed")
	})
	EmitSoundOn("Hero_Magnataur.ShockWave.Cast", caster)
end

function berserker_5th_fissure_strike:OnProjectileHit(target, location)
	if target == nil then return false end
	local caster = self:GetCaster()
	-- DD RunScript: berserker_ability / OnFissureHit
	OnFissureHit({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("damage"),
		CollideDamage = self:GetSpecialValueFor("collide_damage")
	})
	return false
end

modifier_fissure_strike_slow = class({})

function modifier_fissure_strike_slow:IsDebuff() return true end

function modifier_fissure_strike_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_fissure_strike_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow_amount")
end

function modifier_fissure_strike_slow:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_fissure_strike_slow:OnRefresh(kv)
	self:OnCreated(kv)
end
