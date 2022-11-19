gilgamesh_enkidu = class({})
modifier_gilgamesh_combo_window = class({})

LinkLuaModifier("modifier_enkidu_hold", "abilities/gilgamesh/modifiers/modifier_enkidu_hold", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gilgamesh_combo_window", "abilities/gilgamesh/gilgamesh_enkidu", LUA_MODIFIER_MOTION_NONE)

function gilgamesh_enkidu:CastFilterResultTarget(hTarget)
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber())
	
	return filter
end

function gilgamesh_enkidu:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function gilgamesh_enkidu:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	self.stopOrder_self = {
		UnitIndex = caster:entindex(), 
		OrderType = DOTA_UNIT_ORDER_STOP
	}

	if IsSpellBlocked(target) then
		ExecuteOrderFromTable(self.stopOrder_self)  return
		 end
	caster:EmitSound("Gilgamesh_Enkidu_2")
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.zlodemon == true then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_gil_f"})
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)
	local stopOrder = {
 		UnitIndex = target:entindex(), 
 		OrderType = DOTA_UNIT_ORDER_STOP
 	}



 	ExecuteOrderFromTable(stopOrder) 

 	target:AddNewModifier(caster, self, "modifier_enkidu_hold", { Duration = self:GetSpecialValueFor("duration") })
	if(caster.IsChainsAcquired) then
		Timers:CreateTimer(1.0,function()
		if not target:HasModifier("modifier_enkidu_hold") then return end
		local vTargetOrigin = target:GetAbsOrigin()
		local vForwardVector = target:GetForwardVector()
		local vLeftVector = target:GetLeftVector()
		vOrigin = vTargetOrigin + vForwardVector*-150 + vLeftVector * 150 + Vector(0,0,150)
		self:CreateGOB(vOrigin,target)
		local info1 = {
			Target = target,
			Source = self.gramDummy,
			vSourceLoc = vOrigin + vForwardVector * -60, 
			Ability = self,
			bHasFrontalCone = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			bReplaceExisting = false,
			EffectName = "particles/gilgamesh/gob_weapon_barrage.vpcf",
			iMoveSpeed = 2500,
			fExpireTime = GameRules:GetGameTime() + 0.5,
			bDeleteOnHit = true,
		 
		}	
		vOrigin = vTargetOrigin + vForwardVector*-150 + vLeftVector * -150 + Vector(0,0,150)
		self:CreateGOB(vOrigin,target)
		local info2 = {
			Target = target,
			Source = self.gramDummy,
			vSourceLoc = vOrigin + vForwardVector * -60, 
			Ability = self,
			bHasFrontalCone = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			bReplaceExisting = false,
			EffectName = "particles/gilgamesh/gob_weapon_barrage.vpcf",
			iMoveSpeed = 2500,
			fExpireTime = GameRules:GetGameTime() + 0.5,
			bDeleteOnHit = true,
		 
		}	
		vOrigin = vTargetOrigin + vForwardVector*150 + vLeftVector * 150 + Vector(0,0,150)
		self:CreateGOB(vOrigin,target)
		local info3 = {
			Target = target,
			Source = self.gramDummy,
			vSourceLoc = vOrigin + vForwardVector * -60, 
			Ability = self,
			bHasFrontalCone = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			bReplaceExisting = false,
			EffectName = "particles/gilgamesh/gob_weapon_barrage.vpcf",
			iMoveSpeed = 2500,
			fExpireTime = GameRules:GetGameTime() + 0.5,
			bDeleteOnHit = true,
		 
		}	
		vOrigin = vTargetOrigin + vForwardVector*200 + Vector(0,0,150)
		self:CreateGOB(vOrigin,target)
		local info4 = {
			Target = target,
			Source = self.gramDummy,
			vSourceLoc = vOrigin + vForwardVector * -60, 
			Ability = self,
			bHasFrontalCone = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			bReplaceExisting = false,
			EffectName = "particles/gilgamesh/gob_weapon_barrage.vpcf",
			iMoveSpeed = 2500,
			fExpireTime = GameRules:GetGameTime() + 0.5,
			bDeleteOnHit = true,
		 
		}	
		vOrigin = vTargetOrigin + vForwardVector*-200 + Vector(0,0,150)
		self:CreateGOB(vOrigin,target)
		local info5 = {
			Target = target,
			Source = self.gramDummy,
			vSourceLoc = vOrigin + vForwardVector * -60, 
			Ability = self,
			bHasFrontalCone = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			bReplaceExisting = false,
			EffectName = "particles/gilgamesh/gob_weapon_barrage.vpcf",
			iMoveSpeed = 2500,
			fExpireTime = GameRules:GetGameTime() + 0.5,
			bDeleteOnHit = true,
		 
		}	
		vOrigin = vTargetOrigin + vLeftVector * 200 + Vector(0,0,150)
		self:CreateGOB(vOrigin,target)
		local info6 = {
			Target = target,
			Source = self.gramDummy,
			vSourceLoc = vOrigin + vForwardVector * -60, 
			Ability = self,
			bHasFrontalCone = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			bReplaceExisting = false,
			EffectName = "particles/gilgamesh/gob_weapon_barrage.vpcf",
			iMoveSpeed = 2500,
			fExpireTime = GameRules:GetGameTime() + 0.5,
			bDeleteOnHit = true,
		 
		}	
		vOrigin = vTargetOrigin  + vLeftVector * -200 + Vector(0,0,150)
		self:CreateGOB(vOrigin,target)
		local info7 = {
			Target = target,
			Source = self.gramDummy,
			vSourceLoc = vOrigin + vForwardVector * -60, 
			Ability = self,
			bHasFrontalCone = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			bReplaceExisting = false,
			EffectName = "particles/gilgamesh/gob_weapon_barrage.vpcf",
			iMoveSpeed = 2500,
			fExpireTime = GameRules:GetGameTime() + 0.5,
			bDeleteOnHit = true,
		 
		}	
		vOrigin = vTargetOrigin + vForwardVector*150 + vLeftVector * -150 + Vector(0,0,150)
		self:CreateGOB(vOrigin,target)
		local info8 = {
			Target = target,
			Source = self.gramDummy,
			vSourceLoc = vOrigin + vForwardVector * -60, 
			Ability = self,
			bHasFrontalCone = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			bReplaceExisting = false,
			EffectName = "particles/gilgamesh/gob_weapon_barrage.vpcf",
			iMoveSpeed = 2500,
			fExpireTime = GameRules:GetGameTime() + 0.5,
			bDeleteOnHit = true,
		 
		}	

		local counter = 1
		local info  = {info1, info2, info3,info4,info5,info6,info7,info8}
		Timers:CreateTimer(0.4,function()
			if counter == 9 then return end
		
			ProjectileManager:CreateTrackingProjectile(info[counter]) 
			counter = counter + 1
			return 0.07
			end)
		 
		end)
	end

	function gilgamesh_enkidu:OnProjectileHit_ExtraData(hTarget, vLocation, tExtraData)
		if hTarget == nil then return end
	
		if IsSpellBlocked(hTarget) then return end
	
		local hCaster = self:GetCaster()
		local damage = self:GetSpecialValueFor("damage")
		DoDamage(hCaster, hTarget, damage/2, DAMAGE_TYPE_MAGICAL, 0, self, false)
		local targets = FindUnitsInRadius(hCaster:GetTeam(), vLocation, nil, 100, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		for k,v in pairs(targets) do       
		DoDamage(hCaster, v, damage/2, DAMAGE_TYPE_MAGICAL, 0, self, false)
		
		end
		local particle = ParticleManager:CreateParticle("particles/gilgamesh/gob_hit_large.vpcf", PATTACH_ABSORIGIN, hTarget)
		Timers:CreateTimer(0.3,function()
			ParticleManager:DestroyParticle(particle, true)
			ParticleManager:ReleaseParticleIndex(particle)
		
		end)
		
	end

 	--self.elapsed = 0.51

 	--if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
 	--	if caster:FindAbilityByName("gilgamesh_combo_final_hour"):IsCooldownReady() then
 	--		caster:AddNewModifier(caster, self, "modifier_gilgamesh_combo_window", { Duration = 3 })
 	--	end 		
	--end
end

function gilgamesh_enkidu:CreateGOB(position, target)
	local caster = self:GetCaster()
	local vCasterOrigin = caster:GetAbsOrigin()
	 
	self.gramDummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
	self.gramDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	self.gramDummy:SetAbsOrigin(position)
	local gramDummy = self.gramDummy
	Timers:CreateTimer(1.0, function()
		gramDummy:RemoveSelf()
	end)
	self.gramDummy:SetForwardVector((position-target:GetAbsOrigin()):Normalized())
 
	local portalFxIndex = ParticleManager:CreateParticle( "particles/gilgamesh/gob.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.gramDummy )
	ParticleManager:SetParticleControl(portalFxIndex, 3, position ) 
	ParticleManager:SetParticleControl(portalFxIndex, 10, Vector(1,0,0)) 
	Timers:CreateTimer(0.6, function()
		ParticleManager:DestroyParticle(portalFxIndex, true)
		ParticleManager:ReleaseParticleIndex(portalFxIndex)
	end)
end



--[[
function gilgamesh_enkidu:OnChannelThink(fInterval)

	self.elapsed = self.elapsed + fInterval
	if self.elapsed > 0.5 then
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()
		if( not target:HasModifier("modifier_enkidu_hold")) then
			ExecuteOrderFromTable(self.stopOrder_self) 
		end
		

		self.elapsed = 0
	end
end

function gilgamesh_enkidu:OnChannelFinish(bInterrupted)
    local target = self:GetCursorTarget()
    target:RemoveModifierByName("modifier_enkidu_hold")
end
]]
if IsServer() then 
	function modifier_gilgamesh_combo_window:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("gilgamesh_combo_final_hour", "gilgamesh_gram", true, false)
	end

	function modifier_gilgamesh_combo_window:OnDestroy()
		local caster = self:GetParent()
		caster:SwapAbilities("gilgamesh_combo_final_hour", "gilgamesh_gram", false, true)
	end
end


function modifier_gilgamesh_combo_window:IsHidden()
	return true
end

function modifier_gilgamesh_combo_window:RemoveOnDeath()
	return true 
end