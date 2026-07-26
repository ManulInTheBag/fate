-- saber_avalon — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/saber/saber_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

saber_avalon = class({})

LinkLuaModifier("modifier_avalon", "abilities/saber/saber_avalon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("avalon_pause", "abilities/saber/saber_avalon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_everdistant_utopia", "abilities/arturia/modifiers/modifier_everdistant_utopia", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/saber_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnAvalonStart, AvalonOnTakeDamage, SaberCheckCombo, AvalonDash

OnAvalonStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:RemoveModifierByName("modifier_avalon")

	caster:AddNewModifier(caster, ability, "modifier_avalon", {})
	--giveUnitDataDrivenModifier(caster, caster, "disarmed", 3)
	currentHealth = keys.caster:GetHealth()

	caster:EmitSound("Hero_Omniknight.GuardianAngel.Cast")
	EmitGlobalSound("Saber.Avalon")
	EmitGlobalSound("Saber.Avalon_Shout")

	if caster.IsUtopiaAcquired then
		caster:AddNewModifier(caster, ability, "modifier_everdistant_utopia", { Duration = 5,
																				Regen = 500 })
	end

	SaberCheckCombo(keys.caster, keys.ability)
end

AvalonOnTakeDamage = function(keys)
	local caster = keys.caster
	local attacker = keys.attacker
	local pid = caster:GetPlayerID() 
	local diff = 0
	local damageTaken = keys.DamageTaken
	local newCurrentHealth = caster:GetHealth()
	local emitwhichsound = RandomInt(1, 2)
	
	--if caster.IsAvalonPenetrated then return end

	if caster:IsAlive() and not caster:HasModifier("pause_sealdisabled") and not caster:HasModifier("modifier_max_excalibur") and caster.IsAvalonProc == true and caster:GetTeam() ~= attacker:GetTeam() and caster.IsAvalonOnCooldown ~= true and (caster:GetAbsOrigin() - attacker:GetAbsOrigin()):Length2D() < 3000 then 
		if emitwhichsound == 1 then attacker:EmitSound("Saber.Avalon_Counter1") else attacker:EmitSound("Saber.Avalon_Counter2") end
		AvalonDash(caster, attacker, keys.Damage, keys.ability)
		caster.IsAvalonOnCooldown = true
		Timers:CreateTimer({
			endTime = 3, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
			callback = function()
		    caster.IsAvalonOnCooldown = false
		    end
		})
	end 
	--[[if (damageTaken > keys.Threshold) then
		if avalonCooldown and not caster:HasModifier("pause_sealdisabled") then
			if emitwhichsound == 1 then attacker:EmitSound("Saber.Avalon_Counter1") else attacker:EmitSound("Saber.Avalon_Counter2") end
			
			AvalonDash(caster, attacker, keys.Damage, keys.ability)
			-- dash attack 3 seconds cooldown
			avalonCooldown = false
			Timers:CreateTimer({
				endTime = 3, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
				callback = function()
			    avalonCooldown = true
			    end
			})
		end
	end
	-- if damage would have been lethal without Avalon, set Saber's health to health when Avalon was cast
	if newCurrentHealth == 0 then
		caster:SetHealth(currentHealth)
	else
		caster:SetHealth(newCurrentHealth + damageTaken)
	end]]
end

SaberCheckCombo = function(caster, ability)
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if ability == caster:FindAbilityByName("saber_avalon") and caster:FindAbilityByName("saber_excalibur"):IsCooldownReady() and caster:FindAbilityByName("saber_max_excalibur"):IsCooldownReady() and caster:GetAbilityByIndex(2):GetAbilityName() ~= "saber_max_excalibur" then
			caster:SwapAbilities("saber_excalibur", "saber_max_excalibur", false, true) 
			Timers:CreateTimer({
				endTime = 3,
				callback = function()
				caster:SwapAbilities("saber_excalibur", "saber_max_excalibur", true, false)
			end
			})			
		end
	end
end

AvalonDash = function(caster, attacker, counterdamage, ability)
	local targetPoint = attacker:GetAbsOrigin()
	local casterDash = Physics:Unit(caster)
	local distance = targetPoint - caster:GetAbsOrigin()

	if not caster:IsAlive() then return end

	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.45)
    caster:PreventDI()
    caster:SetPhysicsFriction(0)
    caster:SetPhysicsVelocity(distance:Normalized() * distance:Length2D() * 2.5)
    caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
    caster:FollowNavMesh(true)
	caster:SetAutoUnstuck(false)
	
	Timers:CreateTimer({
		endTime = 0.4,
		callback = function()

	    --stop the dash
	    caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:OnPhysicsFrame(nil)
        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

		-- Original function
		local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, 250
	            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			DoDamage(caster, v, counterdamage , DAMAGE_TYPE_MAGICAL, 0, ability, false)
	        v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 2.0})
	    end
	    
		caster:AddNewModifier(caster, caster, "modifier_camera_follow", {duration = 1.0})
		caster:RemoveModifierByName("modifier_avalon")
		caster:RemoveModifierByName("modifier_everdistant_utopia")

		-- Particles
		--local impactFxIndex = ParticleManager:CreateParticle( "particles/custom/saber_avalon_impact.vpcf", PATTACH_ABSORIGIN, caster )
		local explosionFxIndex = ParticleManager:CreateParticle( "particles/custom/saber_avalon_explosion.vpcf", PATTACH_ABSORIGIN, caster )
		ParticleManager:SetParticleControl( explosionFxIndex, 3, caster:GetAbsOrigin() )
		EmitSoundOn( "Hero_EarthShaker.Fissure", caster )

		
		Timers:CreateTimer( 3.0, function()
			--ParticleManager:DestroyParticle( impactFxIndex, false )
			ParticleManager:DestroyParticle( explosionFxIndex, false )
		end)
		
	end
	})
end


function saber_avalon:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: saber_ability / OnAvalonStart
	OnAvalonStart({ caster = caster, ability = self, target = caster })
end

modifier_avalon = class({})


function modifier_avalon:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EVASION_CONSTANT,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_avalon:GetModifierEvasion_Constant()
	return 100
end

function modifier_avalon:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
	local fx = ParticleManager:CreateParticle("particles/custom/saber_avalon_floor.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	self:AddParticle(fx, false, false, -1, false, false)
end

function modifier_avalon:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_avalon:OnTakeDamage(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: saber_ability / AvalonOnTakeDamage
	AvalonOnTakeDamage({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker,
		damage = params.damage,
		DamageTaken = params.damage,
		Threshold = self:GetAbility():GetSpecialValueFor("damage_threshold"),
		DamageTaken = self:GetAbility():GetSpecialValueFor("attack_damage"),
		Damage = self:GetAbility():GetSpecialValueFor("damage")
	})
end

avalon_pause = class({})


function avalon_pause:CheckState()
	return {
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
end

function avalon_pause:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "0.1" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(0.1, true)
	end
end

function avalon_pause:OnRefresh(kv)
	self:OnCreated(kv)
end
