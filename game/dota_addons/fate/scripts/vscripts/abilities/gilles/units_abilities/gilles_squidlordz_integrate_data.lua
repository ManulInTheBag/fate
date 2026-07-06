gilles_squidlordz_integrate_data = class({})

LinkLuaModifier("modifier_integrate", "abilities/gilles/units_abilities/gilles_squidlordz_integrate_data", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_integrate_gille", "abilities/gilles/units_abilities/gilles_squidlordz_integrate_data", LUA_MODIFIER_MOTION_NONE)

function gilles_squidlordz_integrate_data:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local bonusHealth = self:GetSpecialValueFor("health")
	local healthpercent = caster:GetHealthPercent() / 100
	local IntMaxhealth = caster:GetMaxHealth()+bonusHealth
	local IntCurrenthealth = caster:GetHealth()+bonusHealth * healthpercent
	local DeIntMaxhealth = caster:GetMaxHealth()-bonusHealth
	local DeIntCurrenthealth = caster:GetHealth()-bonusHealth * healthpercent
	local ability = self

	Timers:CreateTimer(0.5, function()
		if caster:IsAlive() then
			if hero.IsIntegrated then
				if GridNav:IsBlocked(caster:GetAbsOrigin()) or not GridNav:IsTraversable(caster:GetAbsOrigin()) then
					ability:EndCooldown()
					SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Unmount")
					return
				else
					hero:RemoveModifierByName("modifier_integrate_gille")
					caster:RemoveModifierByName("modifier_integrate")
					caster:SetMaxHealth(DeIntMaxhealth)
					caster:SetHealth(DeIntCurrenthealth)
					hero.IsIntegrated = false
					caster.AttemptingIntegrate = false
					SendMountStatus(hero)
				end
			elseif (caster:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D() < 400 and not hero:HasModifier("stunned") and not hero:HasModifier("modifier_stunned") then
				LoopOverPlayers(function(player, playerID, playerHero)
					if playerHero.gachi == true then
						CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="gilles_wife_d_0"..math.random(1,2)})
					end
				end)
				hero.IsIntegrated = true
				hero:AddNewModifier(caster, ability, "modifier_integrate_gille", {duration = 90})
				caster:AddNewModifier(caster, ability, "modifier_integrate", {})
				caster:SetMaxHealth(IntMaxhealth)
				caster:SetHealth(IntCurrenthealth)
				caster:EmitSound("ZC.Tentacle1")
				SendMountStatus(hero)
				return
			end
		end
	end)
end

-- бафф на сквидлорде, пока Жиль сидит верхом
modifier_integrate = class({})

function modifier_integrate:GetTexture()
	return "custom/gille_integrate"
end

function modifier_integrate:GetEffectName()
	return "particles/units/heroes/hero_oracle/oracle_purifyingflames_heal.vpcf"
end

function modifier_integrate:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_integrate:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_integrate:GetModifierMoveSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("movespeed")
end

function modifier_integrate:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("attackspeed")
end

function modifier_integrate:OnDeath(keys)
	if not IsServer() then return end
	local caster = self:GetParent()
	if keys.unit ~= caster then return end
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsIntegrated = false
	hero:RemoveModifierByName("modifier_integrate_gille")
	SendMountStatus(hero)
end

-- статус Жиля верхом: спрятан, неуязвим, следует за сквидлордом
modifier_integrate_gille = class({})

function modifier_integrate_gille:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_FLYING] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end

function modifier_integrate_gille:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.03)
end

function modifier_integrate_gille:OnIntervalThink()
	local squidlord = self:GetCaster()
	if IsValidEntity(squidlord) then
		self:GetParent():SetAbsOrigin(squidlord:GetAbsOrigin() + Vector(0,0,500))
	end
end
