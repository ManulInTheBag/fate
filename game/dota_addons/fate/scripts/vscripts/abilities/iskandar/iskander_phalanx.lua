iskander_phalanx = class({})
LinkLuaModifier("modifier_iskander_units_bonus_dmg", "abilities/iskandar/iskander_ionioi", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phalanx_soldier_wall","abilities/iskandar/iskander_phalanx", LUA_MODIFIER_MOTION_NONE)


function iskander_phalanx:GetCastPoint()
	return self:GetCaster().IsRiding and 0 or 0.3
end



function iskander_phalanx:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	local damage = self:GetSpecialValueFor("damage")
	if caster.IsBeyondTimeAcquired == true then
		duration = duration + 3
	end
	--if caster.AOTKSoldierCount == nil then caster.AOTKSoldierCount = 0 end --initialize soldier count if its not made yet
	local aotkAbility = caster:FindAbilityByName("iskander_ionioi")
    local targetPoint = self:GetCursorPosition()
    local forwardVec = caster:GetForwardVector()
    caster.PhalanxSoldiers = {}

	local leftvec = Vector(-forwardVec.y, forwardVec.x, 0)
	local rightvec = Vector(forwardVec.y, -forwardVec.x, 0)
	local caster_vector = caster:GetForwardVector()
	-- Spawn soldiers from target point to left end
	for i=0,3 do
		Timers:CreateTimer(i*0.1, function()
			local soldier = CreateUnitByName("iskander_infantry", targetPoint + leftvec * 75 * i, true, nil, nil, caster:GetTeamNumber())
			soldier:SetOwner(caster)
			soldier:SetForwardVector(caster_vector)
			soldier:AddNewModifier(caster, nil, "modifier_kill", {duration = duration})
			if not caster.IsAOTKActive then
				soldier:AddNewModifier(caster, self, "modifier_phalanx_soldier_wall", {duration = duration})
			end
			soldier:AddNewModifier(caster, self, "modifier_iskander_units_bonus_dmg", {duration = duration, dmg = aotkAbility:GetSpecialValueFor("infantry_bonus_damage")})
			self:PhalanxPull(caster, soldier, targetPoint, damage, self) -- do pullback
			soldier:EmitSound("Hero_LegionCommander.Overwhelming.Location")
			if i==0 then
				local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, soldier)
				ParticleManager:SetParticleControl(particle, 3, targetPoint)
				Timers:CreateTimer( 2.0, function()
					ParticleManager:DestroyParticle( particle, false )
					ParticleManager:ReleaseParticleIndex( particle )
				end)
			end 
			table.insert(caster.PhalanxSoldiers, soldier)
		end)
	end

	-- Spawn soldiers on right side
	for i=1,4 do
		Timers:CreateTimer(i*0.1, function()
			local soldier = CreateUnitByName("iskander_infantry", targetPoint + rightvec * 75 * i, true, nil, nil, caster:GetTeamNumber())
			soldier:SetOwner(caster)
			soldier:SetForwardVector(caster_vector)
			soldier:AddNewModifier(caster, nil, "modifier_kill", {duration = duration})
			--caster.AOTKSoldierCount = caster.AOTKSoldierCount + 1
			if not caster.IsAOTKActive then
				soldier:AddNewModifier(caster, self, "modifier_phalanx_soldier_wall", {duration = duration})
			end
			soldier:AddNewModifier(caster, self, "modifier_iskander_units_bonus_dmg", {duration = duration, dmg = aotkAbility:GetSpecialValueFor("infantry_bonus_damage")})
			self:PhalanxPull(caster, soldier, targetPoint, damage, self) -- do pullback

			--local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, soldier)
			--ParticleManager:SetParticleControl(particle, 3, soldier:GetAbsOrigin())
			soldier:EmitSound("Hero_LegionCommander.Overwhelming.Location")
			table.insert(caster.PhalanxSoldiers, soldier)
		end)
	end

	local soundQueue = math.random(1, 4)

	caster:EmitSound("Iskander_Skill_" .. soundQueue)

    
end


function iskander_phalanx:PhalanxPull(caster, soldier, targetPoint, damage, ability)
	local pull_duration = self:GetSpecialValueFor("pull_duration")
	local targets = FindUnitsInRadius(caster:GetTeam(), soldier:GetAbsOrigin(), nil, 150
	        , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
		if v.PhalanxSoldiersHit ~= true and v:GetName() ~= "npc_dota_ward_base" then
			DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			v.PhalanxSoldiersHit = true
				Timers:CreateTimer(0.5, function()
					v.PhalanxSoldiersHit = false
				end)
			if not IsKnockbackImmune(v) then
				local pullTarget = Physics:Unit(v)
				local pullVector = (caster:GetAbsOrigin() - targetPoint):Normalized() * 500
				v:PreventDI()
				v:SetPhysicsFriction(0)
				v:SetPhysicsVelocity(Vector(pullVector.x, pullVector.y, 500))
				v:SetNavCollisionType(PHYSICS_NAV_NOTHING)
				v:FollowNavMesh(false)

				Timers:CreateTimer({
					endTime = pull_duration/2,
					callback = function()
					v:SetPhysicsVelocity(Vector(pullVector.x, pullVector.y, -500))
				end
				})

			  	Timers:CreateTimer(pull_duration, function()
					v:PreventDI(false)
					v:SetPhysicsVelocity(Vector(0,0,0))
					v:OnPhysicsFrame(nil)
				end)
				giveUnitDataDrivenModifier(caster, v, "drag_pause", pull_duration)
				local forwardVec = v:GetForwardVector()
				v:SetForwardVector(Vector(forwardVec.x*-1, forwardVec.y, forwardVec.z))
			end
		end
    end
end


modifier_phalanx_soldier_wall = class({})

function modifier_phalanx_soldier_wall:IsDebuff()
	return true
end

function modifier_phalanx_soldier_wall:CheckState()
	local state = {
	[MODIFIER_STATE_INVULNERABLE] = true,
	[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	[MODIFIER_STATE_UNSELECTABLE] = true,
	[MODIFIER_STATE_STUNNED] = true,
	}
 
	return state
end
