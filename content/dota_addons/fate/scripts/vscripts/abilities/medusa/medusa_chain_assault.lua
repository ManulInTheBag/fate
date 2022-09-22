medusa_chain_assault = class({})

LinkLuaModifier("modifier_medusa_chain_movement_enemy","abilities/medusa/medusa_chain_assault", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_medusa_chain_movement","abilities/medusa/medusa_chain_assault", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_medusa_new_combo_window", "abilities/medusa/medusa_nail_hook", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_medusa_bleed","abilities/medusa/medusa_nail_hook", LUA_MODIFIER_MOTION_NONE)

function medusa_chain_assault:GetCastRange()
	return self:GetSpecialValueFor("range")
end

function medusa_chain_assault:CastFilterResultLocation(hLocation)
    if self.launched then
    	return UF_FAIL_CUSTOM
    else
    	return UF_SUCCESS
    end
end

function medusa_chain_assault:GetCustomCastErrorLocation(hLocation)
    if self.launched then
    	return "#Already active"
    end
end

function medusa_chain_assault:OnSpellStart()
	self.launched = true

	local caster = self:GetCaster()
	local ability = self
	local caster_loc = caster:GetAbsOrigin()

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		caster:AddNewModifier(caster, self, "modifier_medusa_new_combo_window", {duration = 4})
	end

	local target_position = GetGroundPosition(self:GetCursorPosition(), caster)

	if target_position == caster:GetAbsOrigin() then
		target_position = target_position + self:GetCaster():GetForwardVector()
	end

	local direction = (Vector(target_position.x, target_position.y, 0) - Vector(caster_loc.x, caster_loc.y, 0)):Normalized()

	local range = (target_position - caster_loc):Length2D()
	if range > self:GetSpecialValueFor("range") then
		range = self:GetSpecialValueFor("range")
		target_position = caster_loc + direction*self:GetSpecialValueFor("range")
	end

	local fly_speed = self:GetSpecialValueFor("fly_speed")
	local damage = self:GetSpecialValueFor("damage")

	local hook_speed = self:GetSpecialValueFor("speed")
	local hook_dmg = self:GetSpecialValueFor("damage")
	local hook_width = self:GetSpecialValueFor("width")

	--caster:SetForwardVector(direction)
	--StartAnimation(caster, {duration=1.26, activity=ACT_DOTA_CAST_ABILITY_1, rate=2})

	local vKillswitch = Vector(((self:GetCastRange() / hook_speed) * 2) + 10, 0, 0)

	local hook_particle1 = ParticleManager:CreateParticle("particles/medusa/medusa_hook_chain.vpcf", PATTACH_CUSTOMORIGIN, caster)
	--ParticleManager:SetParticleAlwaysSimulate(hook_particle1)
	ParticleManager:SetParticleControlEnt(hook_particle1, 0, caster, PATTACH_POINT_FOLLOW, "attach_hand1", caster_loc, true)
	ParticleManager:SetParticleControl(hook_particle1, 3, caster_loc + Vector(0, 0, 96))
	ParticleManager:SetParticleControl(hook_particle1, 8, Vector(2, 0, 0))

	local hook_particle2 = ParticleManager:CreateParticle("particles/medusa/medusa_hook_chain.vpcf", PATTACH_CUSTOMORIGIN, caster)
	--ParticleManager:SetParticleAlwaysSimulate(hook_particle2)
	ParticleManager:SetParticleControlEnt(hook_particle2, 0, caster, PATTACH_POINT_FOLLOW, "attach_hand2", caster_loc, true)
	ParticleManager:SetParticleControl(hook_particle2, 3, caster_loc + Vector(0, 0, 96))
	ParticleManager:SetParticleControl(hook_particle2, 8, Vector(2, 0, 0))

	self.AttackedTargets    = {}
	self.firstHit = false

	caster:EmitSound("medusa_chain1")
	caster:EmitSound("medusa_power2")
	--EmitSoundOn("medusa_w"..math.random(1,2), self:GetCaster())

	local chTarget = CreateUnitByName("hrunt_illusion", self:GetCaster():GetAbsOrigin(), true, self:GetCaster(), nil, self:GetCaster():GetTeamNumber())
	chTarget:SetModel("models/development/invisiblebox.vmdl")
    chTarget:SetOriginalModel("models/development/invisiblebox.vmdl")
    chTarget:SetModelScale(1)
    local unseen = chTarget:FindAbilityByName("dummy_unit_passive")
    unseen:SetLevel(1)

    Timers:CreateTimer(30, function()
		if IsValidEntity(chTarget) and not chTarget:IsNull() then 
            chTarget:ForceKill(false)
            chTarget:AddEffects(EF_NODRAW)
    	end
    end)

	local projectile_info = {
		Ability = self,
		EffectName = nil,
		vSpawnOrigin = caster_loc,
		fDistance = self:GetCastRange(),
		fStartRadius = hook_width,
		fEndRadius = hook_width,
		Source = self:GetCaster(),
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = nil,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO,
		fExpireTime = GameRules:GetGameTime() + (self:GetCastRange() / hook_speed),
		vVelocity = (target_position - self:GetCaster():GetAbsOrigin()):Normalized() * hook_speed * Vector(1, 1, 0),
		bProvidesVision = false,
		bDeleteOnHit = true,
		ExtraData = {
			hook_width = hook_width,
			hook_dmg = hook_dmg,
			hook_spd = hook_speed,
			pfx_index1 = hook_particle1,
			pfx_index2 = hook_particle2,
			direction_x = direction.x,
			direction_y = direction.y,
			direction_z = direction.z,
			pepetimer = self:GetCastRange()/hook_speed,
			pepetime = GameRules:GetGameTime(),
			firstHit = false,
			chTargetind = chTarget:entindex()
		}
	}

	Timers:CreateTimer("medusa_chain_particle", {
					endTime = self:GetCastRange() / hook_speed + FrameTime(),
					callback = function()
					self.launched = false
					ParticleManager:DestroyParticle(hook_particle1, false)
					ParticleManager:ReleaseParticleIndex(hook_particle1)
					ParticleManager:DestroyParticle(hook_particle2, false)
					ParticleManager:ReleaseParticleIndex(hook_particle2)
				return end
				})

	local vRightVector  = caster:GetRightVector()
    local vAttachPoint1 = caster_loc + vRightVector * hook_width

    projectile_info.vSpawnOrigin = vAttachPoint1

    local hook_projectile_1 = ProjectileManager:CreateLinearProjectile(projectile_info)

    --LEFT
    local vLeftVector   = -caster:GetRightVector()
    local vAttachPoint2 = caster_loc + vLeftVector * hook_width

    projectile_info.vSpawnOrigin = vAttachPoint2

    local hook_projectile_2 = ProjectileManager:CreateLinearProjectile(projectile_info)
end

function medusa_chain_assault:OnProjectileThink_ExtraData(vLocation, hTable)
	if self.firstHit then return end
	local chTarget = EntIndexToHScript(hTable.chTargetind)
	local p_direction = Vector(hTable.direction_x, hTable.direction_y, hTable.direction_z)

	chTarget:SetAbsOrigin(vLocation)
	chTarget:SetForwardVector(p_direction)

	local pepega_angle1 = QAngle(0, chTarget:GetLocalAngles().y - 90, 0)
	local pepega_angle2 = QAngle(0, chTarget:GetLocalAngles().y + 90, 0)
	
	chTarget:SetAbsAngles(0, pepega_angle1.y, 0)
	local pos1 = vLocation + chTarget:GetForwardVector()*20
	chTarget:SetAbsAngles(0, pepega_angle2.y, 0)
	local pos2 = vLocation + chTarget:GetForwardVector()*20

	ParticleManager:SetParticleControl(hTable.pfx_index1, 3, pos1 + Vector(0, 0, 96))
	ParticleManager:SetParticleControl(hTable.pfx_index2, 3, pos2 + Vector(0, 0, 96))
end
function medusa_chain_assault:OnProjectileHit_ExtraData(hTarget, vLocation, hTable)
    if IsNotNull(hTarget) then
        local hCaster       = self:GetCaster()
        local iCasterTeam   = hCaster:GetTeamNumber()
        local fDamage       = hTable.hook_dmg
        local remaining_time = hTable.pepetimer - (GameRules:GetGameTime() - hTable.pepetime)
        local fly_speed = self:GetSpecialValueFor("fly_speed")
        --local vDirection = Vector(hTable.vDirection_X, hTable.vDirection_Y, hTable.vDirection_Z)

        if not self.AttackedTargets[hTarget:entindex()] then
            self.AttackedTargets[hTarget:entindex()] = true
        	DoDamage(hCaster, hTarget, fDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
        	if hCaster.ChainMasteryAcquired then
            	hTarget:AddNewModifier(hCaster, self, "modifier_medusa_bleed", {duration = hCaster.MasterUnit2:FindAbilityByName("medusa_chain_attribute"):GetSpecialValueFor("duration")})
            	hCaster:PerformAttack(hTarget, true, true, true, true, false, false, true)
            end
        	--if not hTarget:HasModifier("modifier_medusa_chain_movement_enemy") then
        	--end
        end

        if not hTarget:HasModifier("modifier_medusa_chain_movement_enemy") and hTarget:IsAlive() and self.firstHit == false then
        	self.firstHit = true
        	Timers:RemoveTimer("medusa_chain_particle")
        	if GridNav:IsNearbyTree( hTarget:GetAbsOrigin(), 120, false) then
        		if IsNotNull(hTarget) then
					hTarget:AddNewModifier(hCaster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("collide_stun_duration")})

					local target_position = hTarget:GetAbsOrigin()
					local range = (target_position - hCaster:GetAbsOrigin()):Length2D()
					local direction = (target_position - hCaster:GetAbsOrigin()):Normalized()
					target_position = hTarget:GetAbsOrigin() - direction*130


					local modifier = hCaster:AddNewModifier(hCaster, self, "modifier_medusa_chain_movement", {	target_position_x = target_position.x, 
																							target_position_y = target_position.y,
																							target_position_z = target_position.z,
																							particle1 = hTable.pfx_index1,
																							particle2 = hTable.pfx_index2,
																							range = range,
																							fly_speed = fly_speed,
																							damage = fDamage
																							})
					modifier.primary_enemy = hTarget
				end
			else
	        	local chTarget = CreateUnitByName("hrunt_illusion", hTarget:GetAbsOrigin(), true, hCaster, nil, hCaster:GetTeamNumber())
				chTarget:SetModel("models/development/invisiblebox.vmdl")
			    chTarget:SetOriginalModel("models/development/invisiblebox.vmdl")
			    chTarget:SetModelScale(1)
			    local unseen = chTarget:FindAbilityByName("dummy_unit_passive")
			    unseen:SetLevel(1)

			    Timers:CreateTimer(10, function()
					if IsValidEntity(chTarget) and not chTarget:IsNull() then 
			            chTarget:ForceKill(false)
			            chTarget:AddEffects(EF_NODRAW)
			    	end
			    end)

	            chTarget.modifier_zalupa = hTarget:AddNewModifier(hCaster, self, "modifier_medusa_chain_movement_enemy", {particle1 = hTable.pfx_index1,
																							particle2 = hTable.pfx_index2,
																							chTargetind = hTable.chTargetind,
																							direction_x = hTable.direction_x,
																							direction_y = hTable.direction_y,
																							direction_z = hTable.direction_z})
	            chTarget.modifier_zalupa.chTarget = chTarget
	            local sin = Physics:Unit(chTarget)
				chTarget:SetPhysicsFriction(0)
				chTarget:SetPhysicsVelocity(Vector(hTable.direction_x, hTable.direction_y, hTable.direction_z)*self:GetSpecialValueFor("speed"))
				chTarget:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

				Timers:CreateTimer("medusa_chain", {
					endTime = remaining_time,
					callback = function()
					chTarget:OnPreBounce(nil)
					chTarget:SetBounceMultiplier(0)
					chTarget:PreventDI(false)
					chTarget:SetPhysicsVelocity(Vector(0,0,0))
					FindClearSpaceForUnit(chTarget, chTarget:GetAbsOrigin(), true)
					self.launched = false
					ParticleManager:DestroyParticle(hTable.pfx_index1, false)
					ParticleManager:ReleaseParticleIndex(hTable.pfx_index1)
					ParticleManager:DestroyParticle(hTable.pfx_index2, false)
					ParticleManager:ReleaseParticleIndex(hTable.pfx_index2)
					if chTarget.modifier_zalupa then
						chTarget.modifier_zalupa:Destroy()
					end
				return end
				})

				chTarget:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
					Timers:RemoveTimer("medusa_chain")
					unit:OnPreBounce(nil)
					unit:SetBounceMultiplier(0)
					unit:PreventDI(false)
					unit:SetPhysicsVelocity(Vector(0,0,0))
					FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
					if IsNotNull(hTarget) and hTarget:IsAlive() then
						hTarget:AddNewModifier(hCaster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("collide_stun_duration")})

						local target_position = hTarget:GetAbsOrigin()
						local range = (target_position - hCaster:GetAbsOrigin()):Length2D()
						local direction = (target_position - hCaster:GetAbsOrigin()):Normalized()
						target_position = hTarget:GetAbsOrigin() - direction*130

						local modifier = hCaster:AddNewModifier(hCaster, self, "modifier_medusa_chain_movement", {	target_position_x = target_position.x, 
																								target_position_y = target_position.y,
																								target_position_z = target_position.z,
																								particle1 = hTable.pfx_index1,
																								particle2 = hTable.pfx_index2,
																								range = range,
																								fly_speed = fly_speed,
																								damage = fDamage
																								})
						modifier.primary_enemy = hTarget
					else
						self.launched = false
						ParticleManager:DestroyParticle(hTable.pfx_index1, false)
						ParticleManager:ReleaseParticleIndex(hTable.pfx_index1)
						ParticleManager:DestroyParticle(hTable.pfx_index2, false)
						ParticleManager:ReleaseParticleIndex(hTable.pfx_index2)
					end
					if unit.modifier_zalupa then
						unit.modifier_zalupa:Destroy()
					end
				end)
			end
        end
        return true
    end
end

modifier_medusa_chain_movement_enemy = class({})

function modifier_medusa_chain_movement_enemy:IsHidden() return true end
function modifier_medusa_chain_movement_enemy:IsDebuff() return true end
function modifier_medusa_chain_movement_enemy:IsPurgable() return false end
function modifier_medusa_chain_movement_enemy:IsPurgeException() return false end
function modifier_medusa_chain_movement_enemy:RemoveOnDeath() return true end

function modifier_medusa_chain_movement_enemy:OnCreated(args)
	if IsServer() then
		self.particle1 = args.particle1
		self.particle2 = args.particle2
		self.direction = Vector(args.direction_x, args.direction_y, args.direction_z)
		self.chTarget2 = EntIndexToHScript(args.chTargetind)
		self.parent = self:GetParent()
		self.ability = self:GetAbility()
		self:StartIntervalThink(FrameTime())
	end
end

function modifier_medusa_chain_movement_enemy:OnIntervalThink()
	if IsServer() then
		if self.chTarget2 then
			self.chTarget2:SetAbsOrigin(self.chTarget:GetAbsOrigin())
			self.chTarget2:SetForwardVector(self.direction)

			local pepega_angle1 = QAngle(0, self.chTarget2:GetLocalAngles().y - 90, 0)
			local pepega_angle2 = QAngle(0, self.chTarget2:GetLocalAngles().y + 90, 0)
			
			self.chTarget2:SetAbsAngles(0, pepega_angle1.y, 0)
			local pos1 = self.chTarget:GetAbsOrigin() + self.chTarget2:GetForwardVector()*20
			self.chTarget2:SetAbsAngles(0, pepega_angle2.y, 0)
			local pos2 = self.chTarget:GetAbsOrigin() + self.chTarget2:GetForwardVector()*20

			ParticleManager:SetParticleControl(self.particle1, 3, pos1 + Vector(0, 0, 96))
			ParticleManager:SetParticleControl(self.particle2, 3, pos2 + Vector(0, 0, 96))
		end
		if self.chTarget then
			self.parent:SetAbsOrigin(self.chTarget:GetAbsOrigin())
			if GridNav:IsNearbyTree( self.chTarget:GetAbsOrigin(), 120, false) then
				Timers:RemoveTimer("medusa_chain")
				self.chTarget:OnPreBounce(nil)
				self.chTarget:SetBounceMultiplier(0)
				self.chTarget:PreventDI(false)
				self.chTarget:SetPhysicsVelocity(Vector(0,0,0))
				FindClearSpaceForUnit(self.chTarget, self.chTarget:GetAbsOrigin(), true)
				if IsNotNull(self.parent) then
					self.parent:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_stunned", {duration = self:GetAbility():GetSpecialValueFor("collide_stun_duration")})
					local target_position = self.parent:GetAbsOrigin()
					local range = (target_position - self:GetCaster():GetAbsOrigin()):Length2D()
					local direction = (target_position - self:GetCaster():GetAbsOrigin()):Normalized()
					target_position = self.parent:GetAbsOrigin() - direction*130

					local modifier = self:GetCaster():AddNewModifier(self:GetCaster(), self.ability, "modifier_medusa_chain_movement", {	target_position_x = target_position.x, 
																							target_position_y = target_position.y,
																							target_position_z = target_position.z,
																							particle1 = self.particle1,
																							particle2 = self.particle2,
																							range = range,
																							fly_speed = self.ability:GetSpecialValueFor("fly_speed"),
																							damage = self.ability:GetSpecialValueFor("damage")
																							})
					modifier.primary_enemy = self.parent
				end
				self:Destroy()
			end
		end
	end
end

function modifier_medusa_chain_movement_enemy:OnDestroy()
	if IsServer() then
		FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
	end
end

function modifier_medusa_chain_movement_enemy:CheckState()
    local state =   { 
                        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_STUNNED] = true,
                    }
    return state
end

modifier_medusa_chain_movement = class({})
function modifier_medusa_chain_movement:IsHidden() return true end
function modifier_medusa_chain_movement:IsDebuff() return false end
function modifier_medusa_chain_movement:IsPurgable() return false end
function modifier_medusa_chain_movement:IsPurgeException() return false end
function modifier_medusa_chain_movement:RemoveOnDeath() return true end
function modifier_medusa_chain_movement:CheckState()
    local state =   { 
                        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        --[MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                    }
    return state
end
function modifier_medusa_chain_movement:OnCreated(args)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    if IsServer() then
    	self.particle1 = args.particle1
    	self.particle2 = args.particle2
        self.speed          = args.fly_speed
        self.damage         = args.damage

        self.point          = Vector(args.target_position_x, args.target_position_y, args.target_position_z)
        self.distance = (self.point - self.parent:GetAbsOrigin()):Length2D()
        self.direction      = (self.point - self.parent:GetAbsOrigin()):Normalized()
        self.direction.z    = 0

        self.AttackedTargets    = {}

        self:StartIntervalThink(FrameTime())
    end
end
function modifier_medusa_chain_movement:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_medusa_chain_movement:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_medusa_chain_movement:UpdateHorizontalMotion(me, dt)
    if IsServer() then
        if self.distance >= 0 then
            local units_per_dt = self.speed * dt
            local parent_pos = self.parent:GetAbsOrigin()

            local next_pos = parent_pos + self.direction * units_per_dt
            next_pos = GetGroundPosition(next_pos, self.parent)
            local distance_will = self.distance - units_per_dt

            if not (distance_will < 0) then
            	self.parent:SetForwardVector((Vector(self.point.x, self.point.y, 0) - Vector(parent_pos.x, parent_pos.y, 0)):Normalized())
            end

            self.parent:SetOrigin(next_pos)

            self:PlayEffects()

            self.distance = self.distance - units_per_dt
        else
            self.parent:RemoveModifierByName("modifier_medusa_hook_movement")
            self:Destroy()
        end
    end
end
function modifier_medusa_chain_movement:PlayEffects()
	local caster = self.parent
	local enemies = FindUnitsInRadius(  self.parent:GetTeamNumber(),
                                        self.parent:GetAbsOrigin(),
                                        nil,
                                        self.parent:Script_GetAttackRange(),
                                       	DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        0,
                                        FIND_CLOSEST,
                                        false)

    for _, enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() and IsValidEntity(enemy) and enemy ~= self.parent and not self.AttackedTargets[enemy:entindex()] then
            self.AttackedTargets[enemy:entindex()] = true

            local anglevalue = caster:GetRightVector()
	        local right_point = caster:GetAbsOrigin() + anglevalue*100
	        local left_point = caster:GetAbsOrigin() - anglevalue*100

	        local right_len = (right_point - enemy:GetAbsOrigin()):Length2D()
	        local left_len = (left_point - enemy:GetAbsOrigin()):Length2D()

	        if (left_len < right_len) then
	        	anglevalue = -anglevalue
	        end

		    local temptarget = CreateUnitByName("hrunt_illusion", enemy:GetAbsOrigin(), true, caster, nil, caster:GetTeamNumber())
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
	                                knockback_duration = 0.05,
	                                duration = 0.05,
	                                knockback_distance = 50 or 0,
	                                knockback_height = 30,
	                                center_x = kborigin.x,
	                                center_y = kborigin.y,
	                                center_z = kborigin.z }
	        if enemy ~= self.primary_enemy then
	        --	print("pepeg")
	    		enemy:AddNewModifier(caster, self.ability, "modifier_knockback", knockback)
	    	end
	    	--print("zuzup")

            DoDamage(self.parent, enemy, self.damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
            if self.parent.ChainMasteryAcquired then
            	enemy:AddNewModifier(self.parent, self.ability, "modifier_medusa_bleed", {duration = self.parent.MasterUnit2:FindAbilityByName("medusa_chain_attribute"):GetSpecialValueFor("duration")})
            	self.parent:PerformAttack(enemy, true, true, true, true, false, false, false)
            end
        end
    end
end
function modifier_medusa_chain_movement:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_medusa_chain_movement:OnDestroy()
    if IsServer() then
    	self.ability.launched = false
    	ParticleManager:DestroyParticle(self.particle1, false)
    	ParticleManager:ReleaseParticleIndex(self.particle1)
    	ParticleManager:DestroyParticle(self.particle2, false)
    	ParticleManager:ReleaseParticleIndex(self.particle2)
        self.parent:InterruptMotionControllers(true)
        EndAnimation(self.parent)
        FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
        self.ability.launched = false
    end
end