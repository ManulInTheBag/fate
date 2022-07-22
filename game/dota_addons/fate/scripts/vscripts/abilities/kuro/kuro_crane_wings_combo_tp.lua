kuro_crane_wings_combo_tp = class({})

LinkLuaModifier("modifier_triple_linked_cooldown", "abilities/kuro/modifiers/modifier_triple_linked_cooldown", LUA_MODIFIER_MOTION_NONE)

function kuro_crane_wings_combo_tp:CastFilterResultLocation(hLocation)
	local caster = self:GetCaster()
	if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
    	return UF_FAIL_CUSTOM
    --[[elseif self:IsLocked(caster) or caster:HasModifier("jump_pause_nosilence") or caster:HasModifier("modifier_story_for_someones_sake") then
        return UF_FAIL_CUSTOM]] --smth causes bugs here
    else
    	return UF_SUCCESS
    end
end

function kuro_crane_wings_combo_tp:GetCustomCastErrorLocation(hLocation)
	local caster = self:GetCaster()
	if not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
    	return "#Wrong_Target_Location"
    end
end

function kuro_crane_wings_combo_tp:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	
	local ability = self
	local radius = self:GetSpecialValueFor("radius")
	local crane_ability = caster:FindAbilityByName("kuro_crane_wings")
	local damage = crane_ability:GetDamage()

	local dist = 300
	local kappa = true

	giveUnitDataDrivenModifier(caster, caster, "jump_pause", self:GetSpecialValueFor("stun_duration"))
	local distance = (caster:GetAbsOrigin() - target):Length2D()
	local diff = target - caster:GetAbsOrigin()	

	StartAnimation(caster, {duration = 1, activity = ACT_DOTA_CAST_ABILITY_4, rate = 1})
	EmitGlobalSound("chloe_crane_4")

	caster:RemoveModifierByName("modifier_kuro_crane_tracker")
	caster:AddNewModifier(caster, self, "modifier_triple_linked_cooldown", {Duration = self:GetCooldown(1)})

	local masterabil = caster.MasterUnit2:FindAbilityByName("kuro_crane_wings_combo_tp")

	masterabil:EndCooldown()
	masterabil:StartCooldown(self:GetCooldown(1))

	local targets = FindUnitsInRadius(caster:GetTeam(), target, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	for k,v in pairs(targets) do
		kappa = false
	end
	if kappa then return end

	Timers:CreateTimer(0.4, function()		
		if caster:IsAlive() then
			target = targets[1]:GetAbsOrigin()
			caster:SetAbsOrigin(target - (target - caster:GetAbsOrigin()):Normalized()*dist)
			local archer = Physics:Unit(caster)
    		caster:PreventDI()
   			caster:SetPhysicsFriction(0)
    		caster:SetPhysicsVelocity(Vector(caster:GetForwardVector().x * dist, caster:GetForwardVector().y * dist, 850))
    		caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
    		caster:FollowNavMesh(false)	
    		caster:SetAutoUnstuck(false)
    		caster:SetPhysicsAcceleration(Vector(0,0,-2666))
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
			self:FireExtraSwords(target, radius)

			StartAnimation(caster, {duration = 1, activity = ACT_DOTA_ATTACK_EVENT, rate = 2})			
		end
	end)

	Timers:CreateTimer(1.0, function()		
		if caster:IsAlive() then
			if kappa then return end
			caster:PreventDI(false)
			caster:SetPhysicsVelocity(Vector(0,0,0))
			caster:SetAutoUnstuck(true)
        	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
			CreateSlashFx(caster, target + Vector(200, 200, 0), target + Vector(-200, -200, 0))
			CreateSlashFx(caster, target + Vector(250, 250, 25), target + Vector(-250, -250, 25))
			CreateSlashFx(caster, target + Vector(300, 300, 50), target + Vector(-300, -300, 50))
			CreateSlashFx(caster, target + Vector(200, -200, 0), target + Vector(-200, 200, 0))
			CreateSlashFx(caster, target + Vector(250, -250, 25), target + Vector(-250, 250, 25))	
			CreateSlashFx(caster, target + Vector(300, -300, 50), target + Vector(-300, 300, 50))	

			local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			for k,v in pairs(targets) do
	        	DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	    	end	    
			caster:EmitSound("Hero_Centaur.DoubleEdge")
		end
	end)
end

function kuro_crane_wings_combo_tp:FireExtraSwords(targetPoint, radius)
	local caster = self:GetCaster()
	--print("firing extra swords")

	local targetCandidates = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	local charge = 4
	local kbAbility = caster:FindAbilityByName("kuro_kanshou_byakuya")

	if #targetCandidates >= 1 then
		local target = targetCandidates[1]

		for i = 1, charge do
			targetPoint = targetPoint + RandomVector(300)
			local dummy = CreateUnitByName("dummy_unit", targetPoint, false, caster, caster, caster:GetTeamNumber())
			dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)

			Timers:CreateTimer(2, function()
				dummy:RemoveSelf()
			end)

			local projectileSpeed = (targetPoint - target:GetAbsOrigin()):Length2D() / 0.55
			local info = {
				Target = target, 
				Source = dummy,
				Ability = kbAbility,
				EffectName = "particles/units/heroes/hero_queenofpain/queen_shadow_strike.vpcf",
				vSpawnOrigin = dummy:GetAbsOrigin(),
				iMoveSpeed = projectileSpeed,
				bDodgeable = true,
				ExtraData = { grant_charges = false }
			}
			ProjectileManager:CreateTrackingProjectile(info) 
		end
	end
end

function kuro_crane_wings_combo_tp:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local kanshou_ability = caster:FindAbilityByName("kuro_kanshou_byakuya")
	local damage = kanshou_ability:GetDamage()
	local KBHitFx = ParticleManager:CreateParticle("particles/econ/courier/courier_mechjaw/mechjaw_death_sparks.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(KBHitFx, 0, hTarget:GetAbsOrigin()) 
	-- Destroy particle after delay
	Timers:CreateTimer(0.5, function()
		ParticleManager:DestroyParticle( KBHitFx, false )
		ParticleManager:ReleaseParticleIndex( KBHitFx )
	end)

	hTarget:EmitSound("Hero_Juggernaut.OmniSlash.Damage")
	DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
end