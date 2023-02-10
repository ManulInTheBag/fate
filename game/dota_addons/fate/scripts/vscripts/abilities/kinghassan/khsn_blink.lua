LinkLuaModifier("modifier_khsn_blink_slow", "abilities/kinghassan/khsn_blink", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_silence", "abilities/kinghassan/khsn_stab", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_blink_checker", "abilities/kinghassan/khsn_blink", LUA_MODIFIER_MOTION_NONE)

khsn_blink = class({})

function khsn_blink:CastFilterResultTarget(vLocation)
    local hCaster = self:GetCaster()

    if vLocation:GetTeamNumber() ~= hCaster:GetTeamNumber()
        and hCaster and not hCaster:IsNull() then
        if not (IsServer() and IsLocked(hCaster)) then
            return UF_SUCCESS
        end
    end
    return UF_FAIL_CUSTOM
end

function khsn_blink:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor("duration")

	local position = target:GetAbsOrigin() - target:GetForwardVector()*150

	if IsSpellBlocked(target) then return end
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.zlodemon == true    then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_kh_q" })
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)
	local slashFx = ParticleManager:CreateParticle("particles/kinghassan/khsn_trail_scepter.vpcf", PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( slashFx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl( slashFx, 1, position)

	local slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl(slashIndex, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(slashIndex, 1, Vector(500,0,150))
    ParticleManager:SetParticleControl(slashIndex, 2, Vector(0.2,0,0))

	FindClearSpaceForUnit(caster, position, true)
	caster:FaceTowards(target:GetAbsOrigin())
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		target:AddNewModifier(caster, self, "modifier_khsn_blink_slow", {duration = duration})
		if caster.BoundaryAcquired then
			target:AddNewModifier(caster, self, "modifier_stunned", {duration = 0.2})
		end
		--caster:AddNewModifier(caster, self, "modifier_khsn_blink_checker", {duration = duration})
		caster:PerformAttack( target, true, true, true, true, false, false, false )
	end

	local point = caster:GetAbsOrigin() + caster:GetForwardVector()*self:GetSpecialValueFor("range")
	local width = self:GetSpecialValueFor("radius")

	local enemy = target

	--[[local enemies = FindUnitsInLine(
								        caster:GetTeamNumber(),
								        caster:GetAbsOrigin(),
								        point,
								        nil,
								        width,
										self:GetAbilityTargetTeam(),
										self:GetAbilityTargetType(),
										self:GetAbilityTargetFlags()
    								)

	for _,enemy in ipairs(enemies) do]]
		local damage = self:GetSpecialValueFor("damage")
		if not IsFacingUnit(enemy, caster, 90) then
			damage = damage
			EmitSoundOnLocationWithCaster(enemy:GetAbsOrigin(), "Hero_SkeletonKing.Hellfire_BlastImpact", caster)
			LoopOverPlayers(function(player, playerID, playerHero)
				--print("looping through " .. playerHero:GetName())
				if playerHero.zlodemon == true   then
					-- apply legion horn vsnd on their client
					CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_kh_e_backstab" })
					--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
				end
			end)
			enemy:AddNewModifier(caster, self, "modifier_khsn_silence", {duration = self:GetSpecialValueFor("silence_duration")})

			local burn_fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_shadowraze.vpcf", PATTACH_ABSORIGIN, enemy)
			ParticleManager:SetParticleControl(burn_fx, 0, enemy:GetAbsOrigin())

			local flame_fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_flame_kappa.vpcf", PATTACH_ABSORIGIN, enemy)
			ParticleManager:SetParticleControl(flame_fx, 0, enemy:GetAbsOrigin())
			ParticleManager:SetParticleControl(flame_fx, 1, Vector(0, 0, 1000))

			--if caster.FlameAcquired then 
				--caster:GiveMana(200)
			--end

			--enemy:AddNewModifier(caster, self, "modifier_khsn_flame1", {duration = self:GetSpecialValueFor("duration")})
		else
			LoopOverPlayers(function(player, playerID, playerHero)
				--print("looping through " .. playerHero:GetName())
				if playerHero.zlodemon == true  then
					-- apply legion horn vsnd on their client
					CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_kh_e" })
					--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
				end
			end)
		end
		giveUnitDataDrivenModifier(caster, enemy, "locked", self:GetSpecialValueFor("lock_duration"))
		DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
    --end
end

modifier_khsn_silence = class({})

function modifier_khsn_silence:IsHidden() return false end
function modifier_khsn_silence:IsDebuff() return true end
function modifier_khsn_silence:IsPurgable() return false end
function modifier_khsn_silence:IsPurgeException() return false end
function modifier_khsn_silence:RemoveOnDeath() return true end

function modifier_khsn_silence:CheckState()
    local state =   { 
                        [MODIFIER_STATE_SILENCED] = true
                    }
    return state
end

modifier_khsn_blink_slow = class({})

function modifier_khsn_blink_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
				--MODIFIER_PROPERTY_DISABLE_TURNING
				}
end

function modifier_khsn_blink_slow:IsHidden() return false end
function modifier_khsn_blink_slow:RemoveOnDeath() return true end
function modifier_khsn_blink_slow:IsDebuff() return true end

function modifier_khsn_blink_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("ms_slow")
end

--[[function modifier_khsn_blink_slow:GetModifierDisableTurning()
	return 1
end]]

function modifier_khsn_blink_slow:GetModifierTurnRate_Percentage()
	return -1*self:GetAbility():GetSpecialValueFor("turn_rate")
end

modifier_khsn_blink_checker = class({})

function modifier_khsn_blink_checker:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE}
end

function modifier_khsn_blink_checker:IsHidden() return false end
function modifier_khsn_blink_checker:IsDebuff() return false end

function modifier_khsn_blink_checker:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("dmg_bonus")
end

function modifier_khsn_blink_checker:GetModifierAttackSpeedBonus_Constant()
	return (self:GetParent().BoundaryAcquired and self:GetAbility():GetSpecialValueFor("attr_as") or 0)
end