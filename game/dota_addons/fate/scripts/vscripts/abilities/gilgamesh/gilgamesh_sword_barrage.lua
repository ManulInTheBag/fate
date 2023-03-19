gilgamesh_sword_barrage = class({})

function gilgamesh_sword_barrage:CastFilterResultTarget(hTarget)
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber())
	
	return filter
end

function gilgamesh_sword_barrage:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function gilgamesh_sword_barrage:CreateGOB(position)
	local caster = self:GetCaster()
	local vCasterOrigin = caster:GetAbsOrigin()
	 
	self.gramDummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
	self.gramDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	self.gramDummy:SetAbsOrigin(position)
	local gramDummy = self.gramDummy
	Timers:CreateTimer(1.0, function()
		gramDummy:RemoveSelf()
	end)
	self.gramDummy:SetForwardVector((vCasterOrigin-self.target:GetAbsOrigin()):Normalized())
 
	local portalFxIndex = ParticleManager:CreateParticle( "particles/gilgamesh/gob.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.gramDummy )
	ParticleManager:SetParticleControl(portalFxIndex, 3, position ) 
	ParticleManager:SetParticleControl(portalFxIndex, 10, Vector(1,0,0)) 
	Timers:CreateTimer(0.6, function()
		ParticleManager:DestroyParticle(portalFxIndex, false)
		ParticleManager:ReleaseParticleIndex(portalFxIndex)
	end)
end

function gilgamesh_sword_barrage:OnSpellStart()
	local caster = self:GetCaster()
	self.target = self:GetCursorTarget()
	local vCasterOrigin = caster:GetAbsOrigin()
	local vForwardVector =  caster:GetForwardVector()

	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.zlodemon == true then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_gil_q"})
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)
	self.gramDummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
	self.gramDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	self.gramDummy:SetForwardVector((vCasterOrigin-self.target:GetAbsOrigin()):Normalized())
	local vLeftVector = self.gramDummy:GetLeftVector()
	self.gramDummy:RemoveSelf()
	local vOrigin


	vOrigin = vCasterOrigin + vForwardVector*-50 + vLeftVector * 120 + Vector(0,0,150)
	self:CreateGOB(vOrigin)
	local info1 = {
		Target = self.target,
		Source = self.gramDummy,
		vSourceLoc = vOrigin + vForwardVector * -60, 
		Ability = self,
		bHasFrontalCone = false,
        bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		EffectName = "particles/gilgamesh/gob_weapon_barrage.vpcf",
		iMoveSpeed = 2500,
		fExpireTime = GameRules:GetGameTime() + 0.5,
		bDeleteOnHit = true,
		 
	}	


	
	
 


	vOrigin = vCasterOrigin + vForwardVector*-50 + vLeftVector * -120 + Vector(0,0,150)
	self:CreateGOB(vOrigin)
  local info2 = {
	  Target = self.target,
	  Source = self.gramDummy,
	  vSourceLoc = vOrigin + vForwardVector * -60, 
	  Ability = self,
	  EffectName = "particles/gilgamesh/gob_weapon_barrage.vpcf",
	  iMoveSpeed = 2500,
	  bHasFrontalCone = false,
	  bReplaceExisting = false,
	  iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	  iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
	  iUnitTargetType = DOTA_UNIT_TARGET_ALL,
	  fExpireTime = GameRules:GetGameTime() + 0.5,
	  bDeleteOnHit = true,
 
  }	
	vOrigin = vCasterOrigin + vForwardVector*-50  + Vector(0,0,350)
	self:CreateGOB(vOrigin)
  local info3 = {
	  Target = self.target,
	  Source = self.gramDummy,
	  vSourceLoc = vOrigin + vForwardVector * -60, 
	  Ability = self,
	  bHasFrontalCone = false,
	  bReplaceExisting = false,
	  iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	  iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
	  iUnitTargetType = DOTA_UNIT_TARGET_ALL,
	  EffectName = "particles/gilgamesh/gob_weapon_barrage.vpcf",
	  iMoveSpeed = 2500,
	  fExpireTime = GameRules:GetGameTime() + 0.5,
	  bDeleteOnHit = true,
 
  }	

	vOrigin = vCasterOrigin + vForwardVector*-50 + vLeftVector * -120 + Vector(0,0,550)
	self:CreateGOB(vOrigin)
  local info4 = {
	  Target = self.target,
	  Source = self.gramDummy,
	  vSourceLoc = vOrigin + vForwardVector * -60, 
	  Ability = self,
	  bHasFrontalCone = false,
	  bReplaceExisting = false,
	  iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	  iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
	  iUnitTargetType = DOTA_UNIT_TARGET_ALL,
	  EffectName = "particles/gilgamesh/gob_weapon_barrage.vpcf",
	  iMoveSpeed = 2500,
	  fExpireTime = GameRules:GetGameTime() + 0.5,
	  bDeleteOnHit = true,
 
  }	

	vOrigin = vCasterOrigin + vForwardVector*-50 + vLeftVector * 120 + Vector(0,0,550)
	self:CreateGOB(vOrigin)
	local info5 = {
		Target = self.target,
		Source = self.gramDummy,
		vSourceLoc = vOrigin + vForwardVector * -60, 
		Ability = self,
		bHasFrontalCone = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        bReplaceExisting = false,
		EffectName = "particles/gilgamesh/gob_weapon_barrage.vpcf",
		iMoveSpeed = 2500,
		fExpireTime = GameRules:GetGameTime() + 0.5,
		bDeleteOnHit = true,
	 
	}	


	local counter = 1
	local info  = {info1, info2, info3,info4,info5}
 
	Timers:CreateTimer(0.1,function()
	if counter == 6 then return end

	ProjectileManager:CreateTrackingProjectile(info[counter]) 
	counter = counter + 1
	return 0.1
	end)
 
 
	 
 

	caster:EmitSound("Hero_SkywrathMage.ConcussiveShot.Cast")

	 
end

function gilgamesh_sword_barrage:OnProjectileHit_ExtraData(hTarget, vLocation, tExtraData)
	if hTarget == nil then return end

	if IsSpellBlocked(hTarget) then return end

	local hCaster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local damage1  = 0
	DoDamage(hCaster, hTarget, damage/2, DAMAGE_TYPE_MAGICAL, 0, self, false)
	if hCaster.IsSumerAcquired then
		damage1 = hCaster:GetAttackDamage() * 0.5
		DoDamage(hCaster, hTarget, damage1/2, DAMAGE_TYPE_PHYSICAL, 0, self, false)
	end
	local targets = FindUnitsInRadius(hCaster:GetTeam(), vLocation, nil, 100, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do       
	DoDamage(hCaster, v, damage/2, DAMAGE_TYPE_MAGICAL, 0, self, false)
	if hCaster.IsSumerAcquired then
		DoDamage(hCaster, v, damage1/2, DAMAGE_TYPE_PHYSICAL, 0, self, false)
	end
	if not hTarget:IsMagicImmune() then
		hTarget:AddNewModifier(hCaster, hTarget, "modifier_stunned", { Duration = self:GetSpecialValueFor("stun_duration") })
	end

	end
	local particle = ParticleManager:CreateParticle("particles/gilgamesh/gob_hit.vpcf", PATTACH_ABSORIGIN, hTarget)
	Timers:CreateTimer(0.3,function()
		ParticleManager:DestroyParticle(particle, true)
		ParticleManager:ReleaseParticleIndex(particle)
	
	end)
	
end