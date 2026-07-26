-- rider_5th_bloodfort_andromeda — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medusa/medusa_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

rider_5th_bloodfort_andromeda = class({})

LinkLuaModifier("modifier_bloodfort_slow", "abilities/medusa/rider_5th_bloodfort_andromeda", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bloodfort_seal", "abilities/medusa/rider_5th_bloodfort_andromeda", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/rider_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnBloodfortCast, OnBloodfortStart

OnBloodfortCast = function( keys )
	--[[local sparkFxIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_invoker/invoker_emp_charge.vpcf", PATTACH_ABSORIGIN, keys.caster )
	ParticleManager:SetParticleControl( sparkFxIndex, 0, keys.caster:GetAbsOrigin() )
	ParticleManager:SetParticleControl( sparkFxIndex, 1, keys.caster:GetAbsOrigin() )
	Timers:CreateTimer( 2.5, function()
			ParticleManager:DestroyParticle( sparkFxIndex, false )
			ParticleManager:ReleaseParticleIndex( sparkFxIndex )
		end
	)]]
end

OnBloodfortStart = function(keys)

	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local initCasterPoint = caster:GetAbsOrigin() 
	local duration = keys.Duration
	local radius = keys.Radius
	local ability = keys.ability
	local bloodfortCount = 0
	caster:EmitSound("medusa_bloodfort_new") 

	--[[local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
	local dummy_ability = dummy:FindAbilityByName("dummy_unit_passive")
	dummy_ability:SetLevel(1)
	dummy:AddNewModifier(caster, nil, "modifier_phased", {duration=5.0})

	local enemy = PickRandomEnemy(caster)
	if enemy ~= nil then
		SpawnVisionDummy(enemy, caster:GetAbsOrigin(), 50, 5, false)
	end	

	Timers:CreateTimer( duration, function()  DummyEnd(dummy) return end )]]

	local forcemove = {
		UnitIndex = nil,
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION ,
		Position = initCasterPoint
	}

	Timers:RemoveTimer("medusa_bloodfort")
	if type(ability.sphereFxIndex) == "number" then
		ParticleManager:DestroyParticle( ability.sphereFxIndex, false )
		ParticleManager:ReleaseParticleIndex( ability.sphereFxIndex )
	end

	--local area_id = FATE_ProjectileManager:CreateSlowingArea_Circle({caster = caster, location = initCasterPoint, radius = radius, target_team = FATE_PROJECTILE_TARGET_TEAM_ENEMY, speed = 100, level = 2})

	Timers:CreateTimer("medusa_bloodfort", {
		callback = function()
		if bloodfortCount >= duration or not caster:IsAlive() or ((caster:GetAbsOrigin() - initCasterPoint):Length2D() > radius and not caster:HasModifier("modifier_medusa_bellerophon")) then
			--FATE_ProjectileManager:DestroyArea(area_id)
			if type(ability.sphereFxIndex) == "number" then
				ParticleManager:DestroyParticle( ability.sphereFxIndex, false )
				ParticleManager:ReleaseParticleIndex( ability.sphereFxIndex )
			end
			return
		end

		local first = false
		
		local targets = FindUnitsInRadius(caster:GetTeam(), initCasterPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" and not v:IsMagicImmune() then
				if not IsImmuneToSlow(v) then v:AddNewModifier(caster, ability, "modifier_bloodfort_slow", {}) end

				local target_damage = keys.Damage + (v:HasModifier("modifier_medusa_bleed") and v:FindModifierByName("modifier_medusa_bleed"):GetStackCount()*ability:GetSpecialValueFor("bleed_damage") or 0)
				local target_absorb = keys.AbsorbAmount + (v:HasModifier("modifier_medusa_bleed") and v:FindModifierByName("modifier_medusa_bleed"):GetStackCount()*ability:GetSpecialValueFor("bleed_absorb") or 0)

		        DoDamage(caster, v, target_damage * 0.5, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)

		        if v:IsHero() then
		        	if not first then
		        		first = true
		        	else
		        		target_absorb = target_absorb/3
		        	end
		        	v:SetMana(v:GetMana() - (target_damage * 0.1))
		        	caster:ApplyHeal(target_absorb * 0.5, caster)
		        	caster:GiveMana(target_absorb * 0.1)
		        end

				if caster.SealAcquired and (bloodfortCount % 2 == 0) then  
					--[[
					forcemove.UnitIndex = v:entindex()
					ExecuteOrderFromTable(forcemove) 
					Timers:CreateTimer(0.15, function()
						v:Stop()
					end)
					]]
						giveUnitDataDrivenModifier(caster, v, "rooted", 0.3)
						giveUnitDataDrivenModifier(caster, v, "locked", 0.3)
					--ability:ApplyDataDrivenModifier(caster,v, "modifier_bloodfort_seal", {})
				end
			end
	    end
		bloodfortCount = bloodfortCount + 0.5
		return 0.5
		end
		}
	)
	
	-- Create Particle
	--[[local sphereFxIndex1 = ParticleManager:CreateParticle( "particles/custom/rider/rider_spirit.vpcf", PATTACH_CUSTOMORIGIN, dummy )
	ParticleManager:SetParticleControl( sphereFxIndex1, 0, caster:GetAbsOrigin() )
	ParticleManager:SetParticleControl( sphereFxIndex1, 1, Vector( radius, radius, radius ) )
	ParticleManager:SetParticleControl( sphereFxIndex1, 6, Vector( radius, radius, radius ) )
	ParticleManager:SetParticleControl( sphereFxIndex1, 10, Vector( radius, radius, radius ) )]]
	ability.sphereFxIndex = ParticleManager:CreateParticle("particles/custom/rider/rider_bloodfort_andromeda_sphere.vpcf", PATTACH_CUSTOMORIGIN, dummy)
	ParticleManager:SetParticleControl(ability.sphereFxIndex, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(ability.sphereFxIndex, 1, Vector(radius, radius, radius))
	
	--[[Timers:CreateTimer( duration, function()
			ParticleManager:DestroyParticle( ability.sphereFxIndex, false )
			ParticleManager:ReleaseParticleIndex( ability.sphereFxIndex )
			return nil
		end
	)]]
end


function rider_5th_bloodfort_andromeda:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function rider_5th_bloodfort_andromeda:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	-- DD RunScript: rider_ability / OnBloodfortCast
	OnBloodfortCast({ caster = caster, ability = self, target = caster })
	return true
end

function rider_5th_bloodfort_andromeda:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: rider_ability / OnBloodfortStart
	OnBloodfortStart({
		caster = caster,
		ability = self,
		target = caster,
		Damage = self:GetSpecialValueFor("damage"),
		Duration = self:GetSpecialValueFor("duration"),
		AbsorbAmount = self:GetSpecialValueFor("absorb"),
		Radius = self:GetSpecialValueFor("radius")
	})
end

modifier_bloodfort_slow = class({})

function modifier_bloodfort_slow:IsDebuff() return true end

function modifier_bloodfort_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_bloodfort_slow:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("slow")
end
function modifier_bloodfort_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_bloodfort_slow:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.5" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.5, true)
	end
end

function modifier_bloodfort_slow:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_bloodfort_seal = class({})

function modifier_bloodfort_seal:IsDebuff() return true end

function modifier_bloodfort_seal:CheckState()
	return {
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
end

function modifier_bloodfort_seal:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "0.1" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(0.1, true)
	end
end

function modifier_bloodfort_seal:OnRefresh(kv)
	self:OnCreated(kv)
end
