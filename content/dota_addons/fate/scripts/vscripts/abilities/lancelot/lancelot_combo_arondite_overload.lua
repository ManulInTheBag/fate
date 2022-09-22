lancelot_combo_arondite_overload = class({})
modifier_arondite_overload_timer = class({})
modifier_arondite_overload_crit = class({})
modifier_arondite_overload_cooldown = class({})

LinkLuaModifier("modifier_arondite_overload_cooldown", "abilities/lancelot/lancelot_combo_arondite_overload", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arondite_overload_timer", "abilities/lancelot/lancelot_combo_arondite_overload", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arondite_overload_crit", "abilities/lancelot/lancelot_combo_arondite_overload", LUA_MODIFIER_MOTION_NONE)

function lancelot_combo_arondite_overload:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function lancelot_combo_arondite_overload:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetPoint = self:GetCursorPosition()
	local hPhysics = Physics:Unit(hCaster)
	local vOrigin = hCaster:GetAbsOrigin()
	local fDistance = (vTargetPoint - vOrigin):Length2D()
	local vForward = (vTargetPoint - vOrigin):Normalized() * fDistance

	hCaster:AddNewModifier(hCaster, self, "modifier_arondite_overload_cooldown", { Duration = 150 })
	local masterCombo = hCaster.MasterUnit2:FindAbilityByName("lancelot_nuke")
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(150)
    hCaster:FindAbilityByName("lancelot_nuke"):StartCooldown(150)

	hCaster:SetPhysicsFriction(0)
	hCaster:SetPhysicsVelocity(hCaster:GetForwardVector() * fDistance)
	hCaster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
	giveUnitDataDrivenModifier(hCaster, hCaster, "jump_pause", 6.0)
	hCaster:EmitSound("lancelot_arthur_" .. math.random(1,3))
	hCaster:AddNewModifier(hCaster, self, "modifier_arondite_overload_crit", { Duration = 6 })

	StartAnimation(hCaster, {duration=1, activity=ACT_DOTA_RUN, rate=0.8})
	 LoopOverPlayers(function(player, playerID, playerHero)
    	--print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
        	-- apply legion horn vsnd on their client
        	CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Saiyan"})
        	--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
	--EmitGlobalSound("Saiyan")

	hCaster.OverloadTImer = Timers:CreateTimer(1.0, function()
		self:StartCombo()
	end)
	hCaster:OnPhysicsFrame(function(unit)
		if CheckDummyCollide(unit) then
			self:StartCombo()
		end
	end)
	hCaster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		self:StartCombo()
	end)
end

function lancelot_combo_arondite_overload:StartCombo()
	local hCaster = self:GetCaster()
	local iFirstSlashCount = 0
	local fAOE = self:GetSpecialValueFor("radius")

	hCaster:EmitSound("lancelot_ready")

	giveUnitDataDrivenModifier(hCaster, hCaster, "jump_pause", 5.0)
	hCaster:EmitSound("lancelot_arthur_" .. math.random(1,3))
	hCaster:AddNewModifier(hCaster, self, "modifier_arondite_overload_crit", { Duration = 5 })

	Timers:CreateTimer(function()
		if iFirstSlashCount <= 0 then 
			hCaster:EmitSound("Saber_Alter.Vortigern")
			StartAnimation(hCaster, {duration = 1.0, activity = ACT_DOTA_ATTACK2, rate = 1.0})
			local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), hCaster:GetAbsOrigin(), nil, fAOE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for i = 1, #tEnemies do
				tEnemies[i]:AddNewModifier(hCaster, self, "modifier_arondite_overload_timer", { Duration = 3.5})
			end
		end
		if iFirstSlashCount >= 9 then return end

		-- Start rotating
		local vDestination = hCaster:GetForwardVector() + hCaster:GetAbsOrigin()
		local vOrigin = hCaster:GetAbsOrigin()
		local vTheta = ( 120 - iFirstSlashCount * 30 ) * math.pi / 180
		local px = math.cos(vTheta) * (vDestination.x - vOrigin.x) - math.sin(vTheta) * (vDestination.y - vOrigin.y) + vOrigin.x
		local py = math.sin(vTheta) * (vDestination.x - vOrigin.x) + math.cos(vTheta) * (vDestination.y - vOrigin.y) + vOrigin.y

		local vNewForward = (Vector(px, py, vOrigin.z) - vOrigin):Normalized()
		local vBeamVelocity= vNewForward * 3000
		
		iFirstSlashCount = iFirstSlashCount + 1
		
		-- Create particles
		local fxIndex1 = ParticleManager:CreateParticle("particles/custom/lancelot/judgement_beams.vpcf", PATTACH_CUSTOMORIGIN, hCaster)
		ParticleManager:SetParticleControl(fxIndex1, 0, hCaster:GetAbsOrigin())
		ParticleManager:SetParticleControl(fxIndex1, 1, vBeamVelocity)
		ParticleManager:SetParticleControl(fxIndex1, 2, Vector( 0.2, 0.2, 0.2 ))
		
		Timers:CreateTimer( 0.2, function()
			ParticleManager:DestroyParticle( fxIndex1, false )
			ParticleManager:ReleaseParticleIndex( fxIndex1 )
			return nil
		end)
		
		return 0.06
	end)

	local iSecondSlashCount = 0

	Timers:CreateTimer(0.7, function()
		if iSecondSlashCount <= 0 then 
			hCaster:EmitSound("Saber_Alter.Vortigern")
			StartAnimation(hCaster, {duration = 1.0, activity = ACT_DOTA_ATTACK, rate = 1.0})
			local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), hCaster:GetAbsOrigin(), nil, fAOE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for i = 1, #tEnemies do
				tEnemies[i]:AddNewModifier(hCaster, self, "modifier_arondite_overload_timer", { Duration = 2.7})
			end
		end
		if iSecondSlashCount >= 9 then return end
		
		-- Start rotating
		local vDestination = hCaster:GetForwardVector() + hCaster:GetAbsOrigin()
		local vOrigin = hCaster:GetAbsOrigin()
		local vTheta = (120 - iSecondSlashCount * (-30)) * math.pi / 180
		local px2 = math.cos(vTheta) * (vDestination.x - vOrigin.x) - math.sin(vTheta) * (vDestination.y - vOrigin.y) + vOrigin.x
		local py2 = math.sin(vTheta) * (vDestination.x - vOrigin.x) + math.cos(vTheta) * (vDestination.y - vOrigin.y) + vOrigin.y

		local vNewForward2 = (Vector(px2, py2, vOrigin.z) - vOrigin):Normalized()
		local vBeamVelocity2= vNewForward2 * 3000
		
		iSecondSlashCount = iSecondSlashCount + 1
		
		-- Create particles
		local fxIndex2 = ParticleManager:CreateParticle("particles/custom/lancelot/judgement_beams.vpcf", PATTACH_CUSTOMORIGIN, hCaster)
		ParticleManager:SetParticleControl(fxIndex2, 0, hCaster:GetAbsOrigin())
		ParticleManager:SetParticleControl(fxIndex2, 1, vBeamVelocity2)
		ParticleManager:SetParticleControl(fxIndex2, 2, Vector( 0.2, 0.2, 0.2 ))
		
		Timers:CreateTimer( 0.2, function()
			ParticleManager:DestroyParticle(fxIndex2, false)
			ParticleManager:ReleaseParticleIndex(fxIndex2)
			return nil
		end)
		
		return 0.06
	end)

	local iThirdSlashCount = 0

	Timers:CreateTimer(1.5, function()
		if iThirdSlashCount <= 0 then 
			hCaster:EmitSound("Saber_Alter.Vortigern")
			StartAnimation(hCaster, {duration = 1.0, activity = ACT_DOTA_ATTACK2, rate = 1.0})
			local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), hCaster:GetAbsOrigin(), nil, fAOE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for i = 1, #tEnemies do
				tEnemies[i]:AddNewModifier(hCaster, self, "modifier_arondite_overload_timer", { Duration = 2.0})
			end
		end
		if iThirdSlashCount >= 9 then return end

		
		-- Start rotating
		local vDestination = hCaster:GetForwardVector() + hCaster:GetAbsOrigin()
		local vOrigin = hCaster:GetAbsOrigin()
		local vTheta = (120 - iThirdSlashCount * 30) * math.pi / 180
		local px3 = math.cos(vTheta) * (vDestination.x - vOrigin.x) - math.sin(vTheta) * (vDestination.y - vOrigin.y) + vOrigin.x
		local py3 = math.sin(vTheta) * (vDestination.x - vOrigin.x) + math.cos(vTheta) * (vDestination.y - vOrigin.y) + vOrigin.y

		local vNewForward3 = (Vector(px3, py3, vOrigin.z) - vOrigin):Normalized()
		local vBeamVelocity3= vNewForward3 * 3000
		
		iThirdSlashCount = iThirdSlashCount + 1
		
		-- Create particles
		local fxIndex3 = ParticleManager:CreateParticle("particles/custom/lancelot/judgement_beams.vpcf", PATTACH_CUSTOMORIGIN, hCaster)
		ParticleManager:SetParticleControl(fxIndex3, 0, hCaster:GetAbsOrigin())
		ParticleManager:SetParticleControl(fxIndex3, 1, vBeamVelocity3)
		ParticleManager:SetParticleControl(fxIndex3, 2, Vector( 0.2, 0.2, 0.2 ))
		
		Timers:CreateTimer( 0.2, function()
			ParticleManager:DestroyParticle(fxIndex3, false)
			ParticleManager:ReleaseParticleIndex(fxIndex3)
			return nil
		end)
		
		return 0.06
	end)

	local iFourthSlashCount = 0

	Timers:CreateTimer(2.1, function()
		if iFourthSlashCount <= 0 then 
			hCaster:EmitSound("Saber_Alter.Vortigern")
			StartAnimation(hCaster, {duration = 1.0, activity = ACT_DOTA_ATTACK, rate = 1.0})
			local tEnemies = FindUnitsInRadius(hCaster:GetTeam(), hCaster:GetAbsOrigin(), nil, fAOE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for i = 1, #tEnemies do
				tEnemies[i]:AddNewModifier(hCaster, self, "modifier_arondite_overload_timer", { Duration = 1.4})
			end
		end
		if iFourthSlashCount >= 9 then return end
		
		-- Start rotating
		local vDestination = hCaster:GetForwardVector() + hCaster:GetAbsOrigin()
		local vOrigin = hCaster:GetAbsOrigin()
		local vTheta = (120 - iFourthSlashCount * (-30)) * math.pi / 180
		local px2 = math.cos(vTheta) * (vDestination.x - vOrigin.x) - math.sin(vTheta) * (vDestination.y - vOrigin.y) + vOrigin.x
		local py2 = math.sin(vTheta) * (vDestination.x - vOrigin.x) + math.cos(vTheta) * (vDestination.y - vOrigin.y) + vOrigin.y

		local vNewForward2 = (Vector(px2, py2, vOrigin.z) - vOrigin):Normalized()
		local vBeamVelocity2= vNewForward2 * 3000
		
		iFourthSlashCount = iFourthSlashCount + 1
		
		-- Create particles
		local fxIndex2 = ParticleManager:CreateParticle("particles/custom/lancelot/judgement_beams.vpcf", PATTACH_CUSTOMORIGIN, hCaster)
		ParticleManager:SetParticleControl(fxIndex2, 0, hCaster:GetAbsOrigin())
		ParticleManager:SetParticleControl(fxIndex2, 1, vBeamVelocity2)
		ParticleManager:SetParticleControl(fxIndex2, 2, Vector( 0.2, 0.2, 0.2 ))
		
		Timers:CreateTimer( 0.2, function()
			ParticleManager:DestroyParticle(fxIndex2, false)
			ParticleManager:ReleaseParticleIndex(fxIndex2)
			return nil
		end)
		
		return 0.06
	end)

	Timers:CreateTimer(3.0, function()
		StartAnimation(hCaster, {duration = 1.5, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.7})

		hCaster:EmitSound("lancelot_arthur")

		-- Create particles
		local fxIndex3 = ParticleManager:CreateParticle("particles/custom/lancelot/judgement_final.vpcf", PATTACH_CUSTOMORIGIN, hCaster)
		ParticleManager:SetParticleControl(fxIndex3, 0, hCaster:GetAbsOrigin())
		ParticleManager:SetParticleControl(fxIndex3, 1, Vector(800, 800, 800))
		ParticleManager:SetParticleControl(fxIndex3, 2, hCaster:GetAbsOrigin())
		
		local fxIndex3 = ParticleManager:CreateParticle("particles/custom/lancelot/judgement_final_c.vpcf", PATTACH_CUSTOMORIGIN, hCaster)
		ParticleManager:SetParticleControl(fxIndex3, 0, hCaster:GetAbsOrigin())
		ParticleManager:SetParticleControl(fxIndex3, 1, Vector(800, 800, 800))

		Timers:CreateTimer( 0.2, function()
			ParticleManager:DestroyParticle(fxIndex3, false)
			ParticleManager:ReleaseParticleIndex(fxIndex3)
			return
		end)
	end)

	Timers:CreateTimer(4.0, function()
		hCaster:RemoveModifierByName("jump_pause")
		hCaster:RemoveModifierByName("modifier_arondite_overload_crit")
	end)
end

if IsServer() then
	function modifier_arondite_overload_timer:OnDestroy()
		local hTarget = self:GetParent()
		local hCaster = self:GetCaster()

		if hTarget:IsAlive() and hCaster:IsAlive() then
			hCaster:PerformAttack(hTarget, true, true, true, true, false, false, true)
		end
	end
end

function modifier_arondite_overload_timer:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true,
			 [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
			 [MODIFIER_STATE_FROZEN] = true,
			 [MODIFIER_STATE_PROVIDES_VISION] = true }
end

function modifier_arondite_overload_timer:RemoveOnDeath()
	return false 
end

function modifier_arondite_overload_crit:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE }
end

function modifier_arondite_overload_crit:GetModifierPreAttack_CriticalStrike()
	return self:GetAbility():GetSpecialValueFor("damage")
end

function modifier_arondite_overload_crit:IsHidden()
	return true 
end

function modifier_arondite_overload_crit:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_arondite_overload_cooldown:IsHidden()
	return false 
end

function modifier_arondite_overload_cooldown:RemoveOnDeath()
	return false
end

function modifier_arondite_overload_cooldown:IsDebuff()
	return true 
end

function modifier_arondite_overload_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end