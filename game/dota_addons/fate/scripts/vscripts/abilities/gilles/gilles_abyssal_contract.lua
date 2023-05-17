gilles_abyssal_contract = class({})
modifier_squidlord_death_checker = class({})
modifier_squidlord_alive = class({})

LinkLuaModifier("modifier_squidlord_death_checker", "abilities/gilles/gilles_abyssal_contract", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_squidlord_alive", "abilities/gilles/gilles_abyssal_contract", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gilles_combo_window", "abilities/gilles/modifiers/modifier_gilles_combo_window", LUA_MODIFIER_MOTION_NONE)

function gilles_abyssal_contract:GetManaCost(iLevel)
	return self:GetCaster():GetMaxMana()
end

function gilles_abyssal_contract:IsHiddenAbilityCastable()
	return true
end

function gilles_abyssal_contract:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function gilles_abyssal_contract:CastFilterResultLocation(vLocation)
	if self:GetCaster():HasModifier("modifier_squidlord_alive") then
		return UF_FAIL_CUSTOM
	else	
		return UF_SUCCESS
	end
end

function gilles_abyssal_contract:GetCustomCastErrorLocation(vLocation)
	return "Cannot Summon"
end

function gilles_abyssal_contract:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetPoint = self:GetCursorPosition()
	local fDelay = self:GetSpecialValueFor("summon_delay")
	local fSquidLordzHealth = self:GetSpecialValueFor("max_health")
	local fSquidLordzdamage = self:GetSpecialValueFor("attack_damage")
	local fAOE = self:GetAOERadius()

	EmitGlobalSound("Gilles_Cool")
	hCaster:AddNewModifier(hCaster, self, "modifier_squidlord_alive", { Duration = 2.9})

	AddFOWViewer(hCaster:GetTeamNumber(), vTargetPoint, fAOE, fDelay + 0.5, true)
    hCaster:EmitSound("Hero_Warlock.Upheaval")

	local contractFx = ParticleManager:CreateParticle("particles/custom/gilles/abyssal_contract_smoke.vcpf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(contractFx, 0, vTargetPoint)
	ParticleManager:SetParticleControl(contractFx, 1, Vector(fAOE + 200,0,0))
	Timers:CreateTimer(2.0, function()
		ParticleManager:DestroyParticle(contractFx, false)
		ParticleManager:ReleaseParticleIndex(contractFx)
	end)

	local contractFx2 = ParticleManager:CreateParticle("particles/custom/gilles/abyssal_contract_sigil.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(contractFx2, 0, vTargetPoint)
	Timers:CreateTimer(5.0, function()
		ParticleManager:DestroyParticle( contractFx2, false )
		ParticleManager:ReleaseParticleIndex( contractFx2 )
	end)

	Timers:CreateTimer(1.0, function()
		contractFx4 = ParticleManager:CreateParticle("particles/custom/gilles/abyssal_contract_pulse.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(contractFx4, 0, vTargetPoint)
		ParticleManager:SetParticleControl(contractFx4, 1, Vector(fAOE + 200, 0, 0))
		Timers:CreateTimer(2.0, function()
			ParticleManager:DestroyParticle(contractFx4, false)
			ParticleManager:ReleaseParticleIndex(contractFx4)
		end)
	end)	

	Timers:CreateTimer(3.0, function()
		if hCaster:IsAlive() then			
			-- Summon Gigantic Horror
			local hSquidLordz = CreateUnitByName("gille_gigantic_horror", vTargetPoint, true, nil, nil, hCaster:GetTeamNumber())
			
			hCaster.Squidlord = hSquidLordz

			if hCaster:HasModifier("modifier_abyssal_connection_attribute") then				
				hSquidLordz:SwapAbilities("fate_empty6", "gilles_squidlordz_integrate_data", false, true) 
				hSquidLordz:SwapAbilities("fate_empty7", "gilles_squidlordz_contaminate", false, true) 
				hSquidLordz:FindAbilityByName("gilles_squidlordz_contaminate"):SetLevel(self:GetLevel()) 
			end
			
			hSquidLordz:SetControllableByPlayer(hCaster:GetPlayerID(), true)
			hSquidLordz:SetOwner(hCaster)
			FindClearSpaceForUnit(hSquidLordz, hSquidLordz:GetAbsOrigin(), true)
			
			-- Level abilities
			hSquidLordz:FindAbilityByName("gille_tentacle_wrap"):SetLevel(self:GetLevel())
			hSquidLordz:FindAbilityByName("gille_subterranean_skewer"):SetLevel(self:GetLevel()) 
			hSquidLordz:FindAbilityByName("gille_gigantic_horror_passive"):SetLevel(self:GetLevel())

			hSquidLordz:SetMaxHealth(fSquidLordzHealth)
			hSquidLordz:SetBaseMaxHealth(fSquidLordzHealth)
			hSquidLordz:SetHealth(fSquidLordzHealth)
			hSquidLordz:SetBaseDamageMax(fSquidLordzdamage) 
			hSquidLordz:SetBaseDamageMin(fSquidLordzdamage) 
			Timers:CreateTimer(90, function()
				if hSquidLordz then
					hSquidLordz:Kill(hSquidLordz:GetAbilityByIndex(0), hSquidLordz)
				end
			end)
			hSquidLordz:AddNewModifier(hCaster, self, "modifier_kill", { duration = 91.0 })
			hSquidLordz:AddNewModifier(hCaster, self, "modifier_squidlord_death_checker", { Duration = 90 })
			hCaster:AddNewModifier(hCaster, self, "modifier_squidlord_alive", { Duration = 90})

			EmitGlobalSound("ZC.Ravage")

			hSquidLordz:SetDeathXP(self:GetLevel() * 50 + 100)
		    local playerData = { transport = hSquidLordz:entindex() }
            CustomGameEventManager:Send_ServerToPlayer( hCaster:GetPlayerOwner(), "player_summoned_transport", playerData )
			
			-- Damage enemies
			local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), vTargetPoint, nil, fAOE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			for k,v in pairs(tEnemies) do
				DoDamage(hCaster, v, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
				if not v:IsMagicImmune() then
					ApplyAirborne(hCaster, v, 0.5)
					v:AddNewModifier(hCaster, self, "modifier_stunned", { duration = 3 })					
				end				
			end

			if hCaster:GetStrength() > 29.1 and hCaster:GetIntellect() > 29.1 and hCaster:GetAgility() > 29.1 then
				if hCaster:FindAbilityByName("gille_larret_de_mort"):IsCooldownReady() then
					hCaster:AddNewModifier(hCaster, self, "modifier_gilles_combo_window", { Duration = 4})
				end
			end

			EmitGlobalSound("ZC.Ravage")
			
			local ravageParticle = ParticleManager:CreateParticle("particles/custom/gilles/abyssal_contract_tentacles.vpcf", PATTACH_CUSTOMORIGIN, hSquidLordz)
			ParticleManager:SetParticleControl(ravageParticle, 0, vTargetPoint)
			ParticleManager:SetParticleControl(ravageParticle, 1, Vector(fAOE * 0.2, 0, 0))
			ParticleManager:SetParticleControl(ravageParticle, 2, Vector(fAOE * 0.4, 0, 0))
			ParticleManager:SetParticleControl(ravageParticle, 3, Vector(fAOE * 0.6, 0, 0))
			ParticleManager:SetParticleControl(ravageParticle, 4, Vector(fAOE * 0.8, 0, 0))
			ParticleManager:SetParticleControl(ravageParticle, 5, Vector(fAOE, 0, 0))

			Timers:CreateTimer( 2.0, function()
				ParticleManager:DestroyParticle( ravageParticle, false )
				ParticleManager:ReleaseParticleIndex( ravageParticle )
			end)
		end

		StopSoundEvent("Hero_Warlock.Upheaval", hCaster)
	end)
end

function gilles_abyssal_contract:OnOwnerDied()
	if self:GetCaster().Squidlord and self:GetCaster().Squidlord:IsAlive() then
		self:GetCaster().Squidlord:ForceKill(true)
	end
end

function gilles_abyssal_contract:OnUpgrade()
	local MasterUnit2 = self:GetCaster().MasterUnit2

	if MasterUnit2 then 
		MasterUnit2:FindAbilityByName("gilles_abyssal_connection_attribute"):SetLevel(self:GetLevel())
	end	
end


if IsServer() then 
	function modifier_squidlord_death_checker:OnDestroy()		
		self:GetCaster():RemoveModifierByName("modifier_squidlord_alive")

		local hAbility = self:GetCaster():FindAbilityByName("gilles_abyssal_contract")
		hAbility:EndCooldown()
		hAbility:StartCooldown(hAbility:GetCooldown(hAbility:GetLevel()))
	end
end

function modifier_squidlord_death_checker:IsHidden()
	return true
end

function modifier_squidlord_alive:IsHidden()
	return true
end

function modifier_squidlord_alive:IsPermanent()
	return false
end

function modifier_squidlord_alive:RemoveOnDeath()
	return true
end

function modifier_squidlord_alive:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end