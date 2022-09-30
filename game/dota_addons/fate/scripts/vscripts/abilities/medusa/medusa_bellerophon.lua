LinkLuaModifier("modifier_medusa_bellerophon","abilities/medusa/medusa_bellerophon", LUA_MODIFIER_MOTION_NONE)

medusa_bellerophon = class({})

function medusa_bellerophon:GetAnimeVectorTargetingRange()
    return 900
end
function medusa_bellerophon:GetAnimeVectorTargetingStartRadius()
    return 200
end
function medusa_bellerophon:GetAnimeVectorTargetingEndRadius()
    return 200
end
function medusa_bellerophon:IsAnimeVectorTargetingIgnoreWidth()
	return false
end
function medusa_bellerophon:GetAnimeVectorTargetingColor()
    return Vector(0, 255, 255)
end
function medusa_bellerophon:GetCastRange()
	local range = (self:GetSpecialValueFor("cast_range") + (self:GetCaster().RidingAcquired and self:GetSpecialValueFor("attribute_range") or 0))
	return range
end

function medusa_bellerophon:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_medusa_monstrous_strength") then
    	return UF_FAIL_CUSTOM
    elseif IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
    	return UF_FAIL_CUSTOM
    else
    	return UF_SUCCESS
    end
end

function medusa_bellerophon:GetCustomCastErrorLocation(hLocation)
	local caster = self:GetCaster()
    if caster:HasModifier("modifier_medusa_monstrous_strength") then
    	return "#Monstrous_Strength_Active"
    elseif not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
    	return "#Wrong_Target_Location"
    end
end

function medusa_bellerophon:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local targetPoint = point
	local direction = self:GetAnimeVectorTargetingMainDirection()
	local initialPosition = caster:GetAbsOrigin()

	self.AttackedTargets    = {}

	local ascendCount = 0
	local descendCount = 0

	local dmgdelay = 0

	local init_origin = point - (direction)*2500 + Vector(0, 0, 1)*2000
	local ascendVec = Vector(0, 0, 0)
	ascendVec = (init_origin - initialPosition):Normalized()
	local ascendDist = (initialPosition - init_origin):Length2D()
	local ascend_x = init_origin.x - initialPosition.x
	local ascend_y = init_origin.y - initialPosition.y
	local ascend_z = init_origin.z - initialPosition.z
	local dist = (init_origin - point):Length2D()

	local descendVec = Vector(0,0,0)
	descendVec = (targetPoint - init_origin):Normalized()

	local or_check = caster:GetAbsOrigin()

	Timers:CreateTimer(0.5, function()
		if not caster:IsAlive() then
			return
		end
		EmitSoundOn("medusa_belle_new", caster)--EmitGlobalSound("medusa_bellerophon")
	end)

	--[[Timers:CreateTimer(1.0, function()
		EmitGlobalSound("medusa_bellerophon_alt")
	end)]]

	--caster:SetForwardVector(-Vector(ascendVec.x, ascendVec.y, 0))

	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 1.4)
	giveUnitDataDrivenModifier(caster, caster, "stunned", 2.2)
	giveUnitDataDrivenModifier(caster, caster, "revoked", 2.2)
	caster:SetForwardVector(Vector(ascendVec.x, ascendVec.y, 0))

	local first_time_huh = false

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 999999, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
		if not first_time_huh then
			first_time_huh = true
			caster:AddNewModifier(enTarget, nil, "modifier_medusa_bellerophon", {duration = 1.3})
		end
	end

	local trail_fx = ParticleManager:CreateParticle( "particles/medusa/medusa_trail_test_3.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(trail_fx, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

	local chTarget = CreateUnitByName("medusa_pegasus", caster:GetAbsOrigin(), true, nil, nil, caster:GetTeamNumber())
	local unseen = chTarget:FindAbilityByName("dummy_unit_passive_no_fly")
	unseen:SetLevel(1)
	chTarget:SetAbsOrigin(caster:GetAbsOrigin())
	chTarget:SetForwardVector(caster:GetForwardVector())
	giveUnitDataDrivenModifier(caster, chTarget, "jump_pause", 1.4)
	giveUnitDataDrivenModifier(caster, caster, "stunned", 2.2)
	giveUnitDataDrivenModifier(caster, caster, "revoked", 2.2)

	StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_RAZE_3, rate=0.3})
	StartAnimation(chTarget, {duration=1.0, activity=ACT_DOTA_RAZE_2, rate=0.3})

	Timers:CreateTimer(4, function()
		if IsValidEntity(chTarget) and not chTarget:IsNull() then 
		    chTarget:ForceKill(false)
		    chTarget:AddEffects(EF_NODRAW)
		end
	end)

	Timers:CreateTimer(2.2, function()
		ParticleManager:DestroyParticle(trail_fx, false)
		ParticleManager:ReleaseParticleIndex(trail_fx)
	end)

	Timers:CreateTimer(FrameTime(), function()
		if ascendCount == 25 then
			--caster:SetAbsOrigin(init_origin)
			--print(init_origin)
			--print(caster:GetAbsOrigin())
		 	return
		end
		if not caster:IsAlive() then
			StopSoundOn("medusa_belle_new", caster)
			return
		end
		local origin = caster:GetAbsOrigin()
		caster:SetForwardVector(Vector(ascendVec.x, ascendVec.y, ascendVec.z))
		caster:SetAbsOrigin(Vector(origin.x + ascend_x/24, origin.y + ascend_y/24, origin.z + ascend_z/24))
		chTarget:SetAbsOrigin(caster:GetAbsOrigin())
		chTarget:SetForwardVector(caster:GetForwardVector())
		ascendCount = ascendCount + 1
		return 0.033
	end)

	Timers:CreateTimer(0.8, function()
		caster:EmitSound("Misc.Crash")
	end)

	Timers:CreateTimer(1.0 - FrameTime(), function()
		if not caster:IsAlive() then
			StopSoundOn("medusa_belle_new", caster)
			return
		end
		caster:SetForwardVector(Vector(descendVec.x, descendVec.y, 0))

		StartAnimation(caster, {duration=0.29, activity=ACT_DOTA_RAZE_3, rate=1})
		StartAnimation(chTarget, {duration=0.29, activity=ACT_DOTA_RAZE_2, rate=1})

		Timers:CreateTimer(FrameTime(), function()
			local origin = caster:GetAbsOrigin()
			--if (origin - targetPoint):Length2D() > 2000 then return end
			if descendCount == 9 then return end
			if not caster:IsAlive() then
				StopSoundOn("medusa_belle_new", caster)
				return
			end

			caster:SetForwardVector(Vector(descendVec.x, descendVec.y, 0))
			caster:SetAbsOrigin(Vector(origin.x + descendVec.x * dist/6,
										origin.y + descendVec.y * dist/6,
										origin.z - 277))

			chTarget:SetAbsOrigin(caster:GetAbsOrigin())
			chTarget:SetForwardVector(caster:GetForwardVector())
			descendCount = descendCount + 1
			return 0.033
		end)

		-- this is when Rider makes a landing 
		Timers:CreateTimer(0.3 + FrameTime(), function() 
			local origin = caster:GetAbsOrigin()
			if (origin - targetPoint):Length2D() < 3000 then
				-- set unit's final position first before checking if IsInSameRealm
				-- to allow Belle across river etc
				-- only if it is across realms do we try to adjust position
				--[[effectIndex_b = ParticleManager:CreateParticle("particles/th2/heroes/marisa/marisa_04_spark_wind_b.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(effectIndex_b, 0, caster:GetOrigin() + Vector(caster:GetForwardVector().x * 0,caster:GetForwardVector().y * 0,150))
				ParticleManager:SetParticleControl(effectIndex_b, 8, caster:GetForwardVector())]]
				--[[Timers:CreateTimer(2.0, function()
					if effectIndex_b then
						ParticleManager:DestroyParticle(effectIndex_b, false)
					end
				end)]]
				ScreenShake(caster:GetOrigin(), 7, 1.0, 2, 2000, 0, true)
				caster:SetAbsOrigin(targetPoint)
				FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
				chTarget:SetAbsOrigin(caster:GetAbsOrigin())
				caster:SetForwardVector(Vector(descendVec.x, descendVec.y, 0))
				chTarget:SetForwardVector(caster:GetForwardVector())
				StartAnimation(caster, {duration=0.9, activity=ACT_DOTA_RAZE_1, rate=1})
				StartAnimation(chTarget, {duration=0.9, activity=ACT_DOTA_RAZE_1, rate=1})
				Timers:CreateTimer(0.9, function()
					if IsValidEntity(chTarget) and not chTarget:IsNull() then 
					    chTarget:ForceKill(false)
					    chTarget:AddEffects(EF_NODRAW)
					end
				end)
				local currentPosition = caster:GetAbsOrigin()
				if not IsInSameRealm(currentPosition, initialPosition) then
					local diffVector = currentPosition - initialPosition
					local normalisedVector = diffVector:Normalized()
					local length = diffVector:Length2D()
					local newPosition = currentPosition
					while length >= 0
						and (not IsInSameRealm(currentPosition, initialPosition)
							or GridNav:IsBlocked(currentPosition)
							or not GridNav:IsTraversable(currentPosition)
						)
					do
						currentPosition = currentPosition - normalisedVector * 10
						length = length - 10
					end
					caster:SetAbsOrigin(currentPosition)
					FindClearSpaceForUnit(caster, currentPosition, true)
				end

				local projectile_info = {
					Ability = self,
					EffectName = nil,
					vSpawnOrigin = caster:GetAbsOrigin(),
					fDistance = 900,
					fStartRadius = 350,
					fEndRadius = 350,
					Source = self:GetCaster(),
					bHasFrontalCone = false,
					bReplaceExisting = false,
					iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
					iUnitTargetFlags = nil,
					iUnitTargetType = DOTA_UNIT_TARGET_HERO,
					fExpireTime = GameRules:GetGameTime() + 0.9,
					vVelocity = caster:GetForwardVector()*2000,
					bProvidesVision = false,
					bDeleteOnHit = false
				}
				local belle_proj = ProjectileManager:CreateLinearProjectile(projectile_info)
				--[[local curr_speed = 2000
				Timers:CreateTimer(FrameTime(), function()
					if ProjectileManager:IsValidProjectile(belle_proj) then
						curr_speed = curr_speed - 2000*FrameTime()
						ProjectileManager:UpdateLinearProjectileDirection(belle_proj, caster:GetForwardVector(), curr_speed)
						return FrameTime()
					end
				end)]]

				local sin = Physics:Unit(caster)
				caster:SetPhysicsFriction(0)
				caster:SetPhysicsVelocity(direction*2000)
				caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
				caster:SetPhysicsAcceleration(-direction*2000)

				local sin2 = Physics:Unit(chTarget)
				chTarget:SetPhysicsFriction(0)
				chTarget:SetPhysicsVelocity(direction*2000)
				chTarget:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
				chTarget:SetPhysicsAcceleration(-direction*2000)

				Timers:CreateTimer("medusa_bellerophon", {
					endTime = 0.9,
					callback = function()
					caster:OnPreBounce(nil)
					caster:SetBounceMultiplier(0)
					caster:PreventDI(false)
					caster:SetPhysicsVelocity(Vector(0,0,0))
					caster:SetPhysicsAcceleration(Vector(0,0,0))
					FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
					chTarget:OnPreBounce(nil)
					chTarget:SetBounceMultiplier(0)
					chTarget:PreventDI(false)
					chTarget:SetPhysicsVelocity(Vector(0,0,0))
					chTarget:SetPhysicsAcceleration(Vector(0,0,0))
					FindClearSpaceForUnit(chTarget, chTarget:GetAbsOrigin(), true)
					--DestroyLinearProjectile(belle_proj)
				return end
				})

				caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
					Timers:RemoveTimer("medusa_bellerophon")
					unit:OnPreBounce(nil)
					unit:SetBounceMultiplier(0)
					unit:PreventDI(false)
					unit:SetPhysicsVelocity(Vector(0,0,0))
					unit:SetPhysicsAcceleration(Vector(0,0,0))
					FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
					chTarget:OnPreBounce(nil)
					chTarget:SetBounceMultiplier(0)
					chTarget:PreventDI(false)
					chTarget:SetPhysicsVelocity(Vector(0,0,0))
					chTarget:SetPhysicsAcceleration(Vector(0,0,0))
					FindClearSpaceForUnit(chTarget, chTarget:GetAbsOrigin(), true)
					unit:SetAbsOrigin(chTarget:GetAbsOrigin())
					ProjectileManager:DestroyLinearProjectile(belle_proj)
				end)
				chTarget:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
					Timers:RemoveTimer("medusa_bellerophon")
					unit:OnPreBounce(nil)
					unit:SetBounceMultiplier(0)
					unit:PreventDI(false)
					unit:SetPhysicsVelocity(Vector(0,0,0))
					unit:SetPhysicsAcceleration(Vector(0,0,0))
					FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
					caster:OnPreBounce(nil)
					caster:SetBounceMultiplier(0)
					caster:PreventDI(false)
					caster:SetPhysicsVelocity(Vector(0,0,0))
					caster:SetPhysicsAcceleration(Vector(0,0,0))
					FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
					caster:SetAbsOrigin(unit:GetAbsOrigin())
					ProjectileManager:DestroyLinearProjectile(belle_proj)
				end)
			else
				FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
			end
			--giveUnitDataDrivenModifier(caster, caster, "jump_pause_postlock", dmgdelay + 0.3)
		end)
	end)
end

function medusa_bellerophon:OnProjectileHit_ExtraData(hTarget, vLocation, hTable)
    if IsNotNull(hTarget) then
        local hCaster       = self:GetCaster()
        local iCasterTeam   = hCaster:GetTeamNumber()
        local caster = self:GetCaster()
        local enemy = hTarget

        if not self.AttackedTargets[hTarget:entindex()] then
            self.AttackedTargets[hTarget:entindex()] = true
        	DoDamage(hCaster, hTarget, self:GetSpecialValueFor("damage") + (hCaster.RidingAcquired and (self:GetSpecialValueFor("riding_damage") + hCaster:GetAgility()*self:GetSpecialValueFor("agility_multiplier")) or 0), DAMAGE_TYPE_MAGICAL, 0, self, false)
        	enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})

	        local anglevalue = caster:GetRightVector()
	        local right_point = caster:GetAbsOrigin() + anglevalue*100
	        local left_point = caster:GetAbsOrigin() - anglevalue*100

	        local right_len = (right_point - enemy:GetAbsOrigin()):Length2D()
	        local left_len = (left_point - enemy:GetAbsOrigin()):Length2D()

	        if (left_len < right_len) then
	        	anglevalue = -anglevalue
	        end

		    local temptarget = CreateUnitByName("hrunt_illusion", enemy:GetAbsOrigin(), true, nil, nil, caster:GetTeamNumber())
			temptarget:SetModel("models/development/invisiblebox.vmdl")
		    temptarget:SetOriginalModel("models/development/invisiblebox.vmdl")
		    temptarget:SetModelScale(1)
		    local unseen = temptarget:FindAbilityByName("dummy_unit_passive")
		    unseen:SetLevel(1)

		    Timers:CreateTimer(5, function()
				if IsValidEntity(temptarget) and not temptarget:IsNull() then 
		            temptarget:ForceKill(false)
		            temptarget:AddEffects(EF_NODRAW)
		    	end
		    end)

			temptarget:SetForwardVector(anglevalue)

			local kborigin = -temptarget:GetForwardVector()*100 + temptarget:GetAbsOrigin()

			local knockback = { should_stun = false,
	                                knockback_duration = 0.25,
	                                duration = 0.25,
	                                knockback_distance = 300 or 0,
	                                knockback_height = 150,
	                                center_x = kborigin.x,
	                                center_y = kborigin.y,
	                                center_z = kborigin.z }

	    	enemy:AddNewModifier(caster, self, "modifier_knockback", knockback)
        end
    end
end

modifier_medusa_bellerophon = class({})

function modifier_medusa_bellerophon:IsHidden() return true end
function modifier_medusa_bellerophon:IsDebuff() return false end
function modifier_medusa_bellerophon:IsPurgable() return false end
function modifier_medusa_bellerophon:IsPurgeException() return false end
function modifier_medusa_bellerophon:RemoveOnDeath() return true end

--[[function modifier_medusa_bellerophon:CheckState()
    local state =   { 
                        [MODIFIER_STATE_NOT_ON_MINIMAP] = false
                    }
    return state
end]]

function modifier_medusa_bellerophon:DeclareFunctions()
	return {MODIFIER_PROPERTY_PROVIDES_FOW_POSITION}
end

function modifier_medusa_bellerophon:GetModifierProvidesFOWVision()
    return 1
end

function modifier_medusa_bellerophon:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end