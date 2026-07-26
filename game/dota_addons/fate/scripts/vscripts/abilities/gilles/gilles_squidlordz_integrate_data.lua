-- gilles_squidlordz_integrate_data — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/gilles/gilles_abyssal_contract.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

gilles_squidlordz_integrate_data = class({})

LinkLuaModifier("modifier_integrate", "abilities/gilles/gilles_squidlordz_integrate_data", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_integrate_passive", "abilities/gilles/gilles_squidlordz_integrate_data", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_integrate_gille", "abilities/gilles/gilles_squidlordz_integrate_data", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/gille_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnIntegrateStart, OnIntegrateDeath, IntegrateFollow

OnIntegrateStart = function(keys)
	local caster = keys.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local healthpercent = caster:GetHealthPercent() / 100
	local IntMaxhealth = caster:GetMaxHealth()+keys.Health
	local IntCurrenthealth = caster:GetHealth()+keys.Health * healthpercent
	local DeIntMaxhealth = caster:GetMaxHealth()-keys.Health
	local DeIntCurrenthealth = caster:GetHealth()-keys.Health * healthpercent

	Timers:CreateTimer(0.5, function()
		if caster:IsAlive() then
			if hero.IsIntegrated then
				if GridNav:IsBlocked(caster:GetAbsOrigin()) or not GridNav:IsTraversable(caster:GetAbsOrigin()) then
					keys.ability:EndCooldown()
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
	        		--print("looping through " .. playerHero:GetName())
	        		if playerHero.gachi == true then
	            		-- apply legion horn vsnd on their client
	            		CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="gilles_wife_d_0"..math.random(1,2)})
	            		--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
	        		end
    			end)
				hero.IsIntegrated = true
				hero:AddNewModifier(caster, keys.ability, "modifier_integrate_gille", {})
				caster:AddNewModifier(caster, keys.ability, "modifier_integrate", {})  
				caster:SetMaxHealth(IntMaxhealth)
				caster:SetHealth(IntCurrenthealth)
				caster:EmitSound("ZC.Tentacle1")
				--caster:EmitSound("ZC.Laugh")
				SendMountStatus(hero)
				return 
			end
			--[[
			else
				caster.AttemptingIntegrate = true
				ExecuteOrderFromTable({ UnitIndex = caster:GetEntityIndex(), 
										OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET, 
										TargetIndex = hero:GetEntityIndex(), 
										Position = hero:GetAbsOrigin(), 
										Queue = false
									}) 

				ExecuteOrderFromTable({ UnitIndex = hero:GetEntityIndex(), 
										OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET, 
										TargetIndex = caster:GetEntityIndex(), 
										Position = caster:GetAbsOrigin(), 
										Queue = false
									}) 
				Timers:CreateTimer("integrate_checker", {
					endTime = 0.0,
					callback = function()
					if (caster:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D() < 300 and caster.AttemptingIntegrate then 
						caster.IsIntegrated = true
						caster.AttemptingIntegrate = false
						keys.ability:ApplyDataDrivenModifier(caster, hero, "modifier_integrate_gille", {})
						keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_integrate", {})  
						caster:EmitSound("ZC.Tentacle1")
						caster:EmitSound("ZC.Laugh")
						return 
					end
					return 0.1
				end})
			end]]
		end
	end)
end

OnIntegrateDeath = function(keys)
	local caster = keys.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsIntegrated = false
	hero:RemoveModifierByName("modifier_integrate_gille")
	SendMountStatus(hero)
end

IntegrateFollow = function(keys)
	local caster = keys.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	if IsValidEntity(caster) then
		hero:SetAbsOrigin(caster:GetAbsOrigin() + Vector(0,0,500))
	end
end


function gilles_squidlordz_integrate_data:GetIntrinsicModifierName()
	return "modifier_integrate_passive"
end

function gilles_squidlordz_integrate_data:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: gille_ability / OnIntegrateStart
	OnIntegrateStart({
		caster = caster,
		ability = self,
		target = caster,
		Health = self:GetSpecialValueFor("health")
	})
end

modifier_integrate = class({})

function modifier_integrate:GetTexture() return "custom/gille_integrate" end
function modifier_integrate:GetEffectName() return "particles/units/heroes/hero_oracle/oracle_purifyingflames_heal.vpcf" end
function modifier_integrate:GetEffectAttachType() return PATTACH_POINT end

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

function modifier_integrate:OnDeath(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: gille_ability / OnIntegrateDeath
	OnIntegrateDeath({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker
	})
end

modifier_integrate_passive = class({})

function modifier_integrate_passive:IsHidden() return true end

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

function modifier_integrate_gille:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "90" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(90, true)
	end
	self:StartIntervalThink(0.03)
end

function modifier_integrate_gille:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_integrate_gille:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: gille_ability / IntegrateFollow
	IntegrateFollow({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end
