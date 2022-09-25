nero_rosa_new = class({})

LinkLuaModifier("modifier_rosa_slow", "abilities/nero/modifiers/modifier_rosa_slow", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_nero_rosa_window", "abilities/nero/nero_rosa_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nero_rosa_new", "abilities/nero/nero_rosa_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nero_rosa_motion_enemy", "abilities/nero/nero_rosa_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nero_rosa_motion", "abilities/nero/nero_rosa_new", LUA_MODIFIER_MOTION_NONE)

function nero_rosa_new:GetCastRange(vLocation, hTarget)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_nero_performance") then
		return 9999
	else
		return self:GetSpecialValueFor("range")
	end
end

function nero_rosa_new:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
   	if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
    	return UF_FAIL_CUSTOM
    else
    	return UF_SUCCESS
    end
end

function nero_rosa_new:GetCustomCastErrorLocation(hLocation)
	local caster = self:GetCaster()
  	if not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
    	return "#Wrong_Target_Location"
    end
end

function nero_rosa_new:GetBehavior()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_nero_performance") then
		return DOTA_ABILITY_BEHAVIOR_POINT
	end
	return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
end

function nero_rosa_new:OnUpgrade()
    local hCaster = self:GetCaster()
    
    hCaster:FindAbilityByName("nero_rosa_buffed"):SetLevel(self:GetLevel())
end

function nero_rosa_new:CastFilterResultTarget(hTarget)
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self:GetCaster():GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 
		--elseif self:GetCaster():HasModifier("modifier_aestus_domus_aurea_nero") and not hTarget:HasModifier("modifier_aestus_domus_aurea_enemy") then
		--	return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function nero_rosa_new:GetCustomCastErrorTarget(hTarget)
	--if self:GetCaster():HasModifier("modifier_aestus_domus_aurea_nero") and not hTarget:HasModifier("modifier_aestus_domus_aurea_enemy") then
	--	return "Outside Theatre"
	--else
	return "#Invalid_Target"
	--end    
end

--[[function nero_rosa_ichthys:GetCooldown(iLevel)
	local caster = self:GetCaster()
	--if caster:HasModifier("modifier_aestus_domus_aurea_nero") and caster:HasModifier("modifier_sovereign_attribute") then
	--	return self:GetSpecialValueFor("aestus_cooldown")
	--else
		return self:GetSpecialValueFor("cooldown")
	--end
end]]

function nero_rosa_new:OnSpellStart()
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_nero_spectaculi_initium")
	if caster:HasModifier("modifier_nero_performance") or (self:GetCursorTarget() == nil) then
		if not caster:HasModifier("modifier_nero_rosa_window") then
	        caster:AddNewModifier(caster, self, "modifier_nero_rosa_window", {duration = self:GetSpecialValueFor("window_duration")})
	    else
	        caster:RemoveModifierByName("modifier_nero_rosa_window")
	    end

	    local target_point = self:GetCursorPosition()
	    local target = nil
	    if caster:HasModifier("modifier_aestus_domus_aurea_nero") then
	    	local modifier = caster:FindModifierByName("modifier_aestus_domus_aurea_nero")
	    	local ori = caster:GetAbsOrigin()
			local center_point = Vector(modifier.TheatreCenterX, modifier.TheatreCenterY, modifier.TheatreCenterZ)
			local enemies = FindUnitsInRadius(caster:GetTeam(), center_point, nil, caster:FindAbilityByName("nero_aestus_domus_aurea"):GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		    local dist = 99999
		    for i = 1, #enemies do
		    	print((ori - enemies[i]:GetAbsOrigin()):Length2D())
		    	print(dist)
				if enemies[i]:IsAlive() and enemies[i]:CanBeSeenByAnyOpposingTeam() and (ori - enemies[i]:GetAbsOrigin()):Length2D() < dist then
					target = enemies[i]
					dist = (ori - enemies[i]:GetAbsOrigin()):Length2D()
				end
			end
			if not target then
				enemies = FindUnitsInRadius(caster:GetTeam(), center_point, nil, caster:FindAbilityByName("nero_aestus_domus_aurea"):GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
				for i = 1, #enemies do
					if enemies[i]:IsAlive() and enemies[i]:CanBeSeenByAnyOpposingTeam() and (ori - enemies[i]:GetAbsOrigin()):Length2D() < dist then
						target = enemies[i]
						dist = (ori - enemies[i]:GetAbsOrigin()):Length2D()
					end
				end
			end
		else
		    local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
		    for i = 1, #enemies do
				if enemies[i]:IsAlive() and enemies[i]:CanBeSeenByAnyOpposingTeam() then
					target = enemies[i]
					break
				end
			end
			if not target then
				enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
				for i = 1, #enemies do
					if enemies[i]:IsAlive() and enemies[i]:CanBeSeenByAnyOpposingTeam() then
						target = enemies[i]
						break
					end
				end
			end
		end

		if not target then return end

	    caster:EmitSound("nero_e2")
	    target:EmitSound("nero_e2")

	    local heat_abil = caster:FindAbilityByName("nero_heat")
        heat_abil:IncreaseHeat(caster)
		--caster:FaceTowards(Vector(target:GetAbsOrigin().x, target:GetAbsOrigin().y, caster:GetAbsOrigin().z))
		--[[caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:SetPhysicsAcceleration(Vector(0,0,0))
		caster:OnPhysicsFrame(nil)
		caster:Hibernate(true)]]
		caster:FindAbilityByName("nero_heat"):PausePerformance(self:GetSpecialValueFor("motion_time"))
		Physics:Unit(target)
		target:PreventDI(false)
		target:SetPhysicsVelocity(Vector(0,0,0))
		target:SetPhysicsAcceleration(Vector(0,0,0))
		target:OnPhysicsFrame(nil)
		target:Hibernate(true)

		local tar_loc = target:GetAbsOrigin() - (target:GetAbsOrigin() - target_point):Normalized()*50
		caster:SetAbsOrigin(Vector(target:GetAbsOrigin().x, target:GetAbsOrigin().y, caster:GetAbsOrigin().z))
		local distance = 1000
		if caster:HasModifier("modifier_aestus_domus_aurea_nero") then
			print((target:GetAbsOrigin() - target_point):Length2D())
			distance = (target:GetAbsOrigin() - target_point):Length2D()
		else
			distance = math.min((target:GetAbsOrigin() - target_point):Length2D(), self:GetSpecialValueFor("motion_distance"))
		end
		caster:AddNewModifier(caster, self, "modifier_nero_rosa_motion", {destination_x = target_point.x, destination_y = target_point.y, destination_z = target_point.z, distance = distance, entindex = target:entindex()})
		target:AddNewModifier(caster, self, "modifier_nero_rosa_motion_enemy", {})
	else
		local target = self:GetCursorTarget()
		if IsSpellBlocked(target) then return end
		caster:EmitSound("Nero.Skill1")
		if not caster:HasModifier("modifier_nero_rosa_window") then
	        caster:AddNewModifier(caster, self, "modifier_nero_rosa_window", {duration = self:GetSpecialValueFor("window_duration")})
	    else
	        caster:RemoveModifierByName("modifier_nero_rosa_window")
	    end

	    local heat_abil = caster:FindAbilityByName("nero_heat")
        heat_abil:IncreaseHeat(caster)

		local damage = self:GetSpecialValueFor("damage") + self:GetSpecialValueFor("damage_per_stack")*caster:FindModifierByName("modifier_nero_heat").rank + (caster:HasModifier("modifier_sovereign_attribute") and caster:GetAverageTrueAttackDamage(caster)*self:GetSpecialValueFor("damage_scale")/100 or 0)

		local diff = target:GetAbsOrigin() - caster:GetAbsOrigin()
		CreateSlashFx(caster, caster:GetAbsOrigin(), caster:GetAbsOrigin() + diff:Normalized() * diff:Length2D())
		caster:SetAbsOrigin(target:GetAbsOrigin() + diff:Normalized() * 150)
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		--caster:FaceTowards(target:GetAbsOrigin())
		StartAnimation(caster, {duration = 1, activity = ACT_DOTA_CAST_ABILITY_3_END, rate = 1.5})	
		caster:MoveToTargetToAttack(target)

		

		--caster:AddNewModifier(caster,self,"modifier_rosa_buffer", {})

		 if not target:IsMagicImmune() then
			DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end

		--[[if not target:HasModifier("modifier_rosa_buffer") then
			target:AddNewModifier(caster, self, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration") })
		end

		caster:RemoveModifierByName("modifier_rosa_buffer")]]
			
		target:EmitSound("Hero_Lion.FingerOfDeath")
		--target:EmitSound("nero_w")

		local slashFx = ParticleManager:CreateParticle("particles/kinghassan/nero_scorched_earth_child_embers_rosa.vpcf", PATTACH_ABSORIGIN, target )
		ParticleManager:SetParticleControl( slashFx, 0, target:GetAbsOrigin() + Vector(0,0,300))

		Timers:CreateTimer( 2.0, function()
			ParticleManager:DestroyParticle( slashFx, false )
			ParticleManager:ReleaseParticleIndex( slashFx )
		end)

		--[[if caster:HasModifier("modifier_sovereign_attribute") and caster:HasModifier("modifier_aestus_domus_aurea_nero") then               
	        if not target:HasModifier("modifier_rosa_buffer") then
	        	target:AddNewModifier(caster, self, "modifier_rosa_buffer", { Duration = 3 })
	        end
	    end]]

	    -- Too dumb to make particles, just call cleave function 4head
	    DoCleaveAttack(caster, target, self, 0, 200, 400, 500, "particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave_gods_strength.vpcf")

	    local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	    ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin() + Vector(0, 0, 80))
	    ParticleManager:SetParticleControl(slash_fx, 5, Vector(300, 1, 1))
	    ParticleManager:SetParticleControl(slash_fx, 10, Vector(RandomInt(-10, 10), 0, 0))

	    Timers:CreateTimer(0.4, function()
	    	ParticleManager:DestroyParticle(slash_fx, false)
	    	ParticleManager:ReleaseParticleIndex(slash_fx)
	    end)

	    self.Target = target

	    local slash = 
		{
			Ability = self,
	        EffectName = "",
	        iMoveSpeed = 99999,
	        vSpawnOrigin = caster:GetAbsOrigin(),
	        fDistance = 500,
	        fStartRadius = 200,
	        fEndRadius = 400,
	        Source = caster,
	        bHasFrontalCone = true,
	        bReplaceExisting = true,
	        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
	        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
	        fExpireTime = GameRules:GetGameTime() + 2.0,
			bDeleteOnHit = false,
			vVelocity = caster:GetForwardVector() * 500
		}

		local projectile = ProjectileManager:CreateLinearProjectile(slash)

		if target:HasModifier("modifier_airborne_marker") and (math.abs(target:GetPhysicsVelocity()[3]) > 0 or math.abs(target:GetPhysicsAcceleration()[3]) > 0) then
			local duration = 1.5 - target:FindModifierByName("modifier_airborne_marker").elapsed
			local knockupSpeed = target:GetPhysicsVelocity()[3]
			local knockupAcc = target:GetPhysicsAcceleration()[3]
			--caster:AddNewModifier(caster, self, "modifier_nero_rosa_new", {duration = duration})
			caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x, caster:GetAbsOrigin().y, target:GetAbsOrigin().z))
			caster:FindAbilityByName("nero_heat"):StartPerformance(knockupSpeed, -knockupAcc)
			--[[Physics:Unit(caster)
			caster:PreventDI()
	    	caster:SetPhysicsVelocity(Vector(0,0,knockupSpeed))
	    	caster:SetPhysicsAcceleration(Vector(0,0,knockupAcc))
	    	caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
	    	caster:FollowNavMesh(false)
	    	caster:Hibernate(false)

		    Timers:CreateTimer(duration, function()
		        caster:PreventDI(false)
		        caster:SetPhysicsVelocity(Vector(0,0,0))
		        caster:SetPhysicsAcceleration(Vector(0,0,0))
		        caster:OnPhysicsFrame(nil)
		        caster:Hibernate(true)
		    end)]]
	    end
	end
end

function nero_rosa_new:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil or hTarget == self.Target then return end

	local damage = self:GetSpecialValueFor("damage")
	local hCaster = self:GetCaster()

	if not hCaster.IsPTBAcquired then
		damage = damage / 2
	end

	DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	--[[if hCaster:HasModifier("modifier_sovereign_attribute") and hCaster:HasModifier("modifier_aestus_domus_aurea_nero") then               
        if not target:HasModifier("modifier_rosa_buffer") then
        	hTarget:AddNewModifier(hCaster, self, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration") })
        	hTarget:AddNewModifier(hCaster, self, "modifier_rosa_buffer", { Duration = 3 })
        end
    end]]
	
	--hTarget:AddNewModifier(caster, self, "modifier_rosa_buffer", { Duration = 5 })
end

modifier_nero_rosa_motion_enemy = class({})
function modifier_nero_rosa_motion_enemy:IsHidden() return true end
function modifier_nero_rosa_motion_enemy:IsDebuff() return false end
function modifier_nero_rosa_motion_enemy:IsPurgable() return false end
function modifier_nero_rosa_motion_enemy:IsPurgeException() return false end
function modifier_nero_rosa_motion_enemy:RemoveOnDeath() return true end
function modifier_nero_rosa_motion_enemy:CheckState()
    local state =   { 
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                    }
    return state
end

modifier_nero_rosa_motion = class({})
function modifier_nero_rosa_motion:IsHidden() return true end
function modifier_nero_rosa_motion:IsDebuff() return false end
function modifier_nero_rosa_motion:IsPurgable() return false end
function modifier_nero_rosa_motion:IsPurgeException() return false end
function modifier_nero_rosa_motion:RemoveOnDeath() return true end
--function modifier_nero_rosa_motion:GetPriority() return MODIFIER_PRIORITY_HIGH end
--function modifier_nero_rosa_motion:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_nero_rosa_motion:CheckState()
    local state =   { 
                        --[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                    }
    return state
end
--[[function modifier_nero_tres_new:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_OVERRIDE_ANIMATION, 
                    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,}
    return func
end
function modifier_nero_tres_new:GetOverrideAnimation()
    return ACT_DOTA_ATTACK_EVENT
end
function modifier_nero_tres_new:GetOverrideAnimationRate()
    return 2.0
end]]
function modifier_nero_rosa_motion:OnCreated(args)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    --self.heat_abil = self.parent:FindAbilityByName("nero_heat")

    if IsServer() then
    	self.target = EntIndexToHScript(args.entindex)
        self.motion_time          = self.ability:GetSpecialValueFor("motion_time")
        self.distance       = args.distance
        self.speed = self.distance/self.motion_time
        self.damage         = self.ability:GetSpecialValueFor("damage_per_hit") + self.ability:GetSpecialValueFor("damage_per_hit_per_stack")*self.parent:FindModifierByName("modifier_nero_heat").rank + (self.parent:HasModifier("modifier_sovereign_attribute") and self.parent:GetAverageTrueAttackDamage(self.parent)*self.ability:GetSpecialValueFor("damage_per_hit_scale")/100 or 0)
        self.sequence = 0
        --self.crit           = self.ability:GetSpecialValueFor("crit")
        --self.delay_duration = self.ability:GetSpecialValueFor("delay_duration")

        --self.second_targets_damage = self.ability:GetSpecialValueFor("second_targets_damage") * 0.01

        self.direction      = (Vector(args.destination_x, args.destination_y, 0) - Vector(self.parent:GetAbsOrigin().x, self.parent:GetAbsOrigin().y, 0)):Normalized()
        self.point          = self.parent:GetAbsOrigin() + self.direction * self.distance

        --self.parent:SetForwardVector(self.direction)

        self.AttackedTargets    = {}
        self.FirstTarget        = nil

        self.time_elapsed = 9999

        --[[local dash_fx = ParticleManager:CreateParticle("particles/okita/okita_vendetta_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(dash_fx, 0, self.parent:GetAbsOrigin())

        self:AddParticle(dash_fx, false, false, -1, true, false)

        self.dash_fx2 = ParticleManager:CreateParticle("particles/okita/okita_surge_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(self.dash_fx2, 0, self.parent:GetAbsOrigin())

        self:AddParticle(self.dash_fx2, false, false, -1, true, false)]]

        self:StartIntervalThink(FrameTime())
        
        --[[if self:ApplyHorizontalMotionController() == false then 
            self:Destroy()
        end]]
    end
end
function modifier_nero_rosa_motion:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_nero_rosa_motion:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_nero_rosa_motion:UpdateHorizontalMotion(me, dt)
    if IsServer() then
        if self.distance >= 0 then
        	--self.direction = self.parent:GetForwardVector()
            local units_per_dt = self.speed * dt
            local parent_pos = self.parent:GetAbsOrigin()

            local next_pos = parent_pos + self.direction * units_per_dt

            if not self.parent:HasModifier("modifier_inside_marble") then
	            if next_pos.x > 8160 then
					next_pos.x = 8160
				end
				if next_pos.x < -8160 then
					next_pos.x = -8160
				end
				if next_pos.y > 7000 then
					next_pos.y = 7000
				end
				if next_pos.y < -1568 then
					next_pos.y = -1568
				end
			end
            local distance_will = self.distance - units_per_dt

            self.time_elapsed = self.time_elapsed + dt

            --[[if distance_will < 0 then
                next_pos = self.point
            end]]

            --[[print(self.parent:GetAbsOrigin())
            print(next_pos)]]

            self.parent:SetOrigin(next_pos)
            self.target:SetOrigin(next_pos + self.direction*190)
            --self.parent:FaceTowards(self.point)

            if self.time_elapsed > 0.3 then
            	self:PlayEffects()
            	self.time_elapsed = 0
            end

            self.distance = self.distance - units_per_dt
        else
            self:Destroy()
        end
    end
end
function modifier_nero_rosa_motion:PlayEffects()
	if self.sequence == 0 then
		StartAnimation(self.parent, {duration = 0.5, activity = ACT_DOTA_ATTACK, rate = 2})
		self.sequence = self.sequence + 1
	elseif self.sequence == 1 then
		StartAnimation(self.parent, {duration = 0.5, activity = ACT_DOTA_ATTACK2, rate = 2})
		self.sequence = self.sequence + 1
	else
		StartAnimation(self.parent, {duration = 1, activity = ACT_DOTA_CAST_ABILITY_3_END, rate = 1.5})
	end
	local vector = RandomVector(300)
	CreateSlashFx(self.parent, self.target:GetAbsOrigin()+vector, self.target:GetAbsOrigin()-vector)
	local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
    ParticleManager:SetParticleControl(slash_fx, 0, self.parent:GetAbsOrigin() + Vector(0, 0, 80))
    ParticleManager:SetParticleControl(slash_fx, 5, Vector(300, 1, 1))
    ParticleManager:SetParticleControl(slash_fx, 10, Vector(RandomInt(-60, 60), 0, 0))
    EmitSoundOn("nero_fast_slash", self.target)

    Timers:CreateTimer(0.4, function()
    	ParticleManager:DestroyParticle(slash_fx, false)
    	ParticleManager:ReleaseParticleIndex(slash_fx)
    end)

	if not self.target:IsMagicImmune() then
		DoDamage(self.parent, self.target, self.damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
	end

    if self.parent.AttributeNamePlaceholderAcquired then
       	self.parent:PerformAttack(enemy, true, true, false, true, true, false, false)
    end
end
function modifier_nero_rosa_motion:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_nero_rosa_motion:OnDestroy()
    if IsServer() then
        --self.parent:InterruptMotionControllers(true)
        if self.parent.IsISAcquired then
			HardCleanse(self.parent)
		end
        self.target:RemoveModifierByName("modifier_nero_rosa_motion_enemy")
    end
end

modifier_nero_rosa_new = class({})
function modifier_nero_rosa_new:IsHidden() return false end
function modifier_nero_rosa_new:IsDebuff() return false end
function modifier_nero_rosa_new:IsPurgable() return false end
function modifier_nero_rosa_new:IsPurgeException() return false end
function modifier_nero_rosa_new:RemoveOnDeath() return true end
function modifier_nero_rosa_new:CheckState()
    local state =   { 
                        --[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        --[MODIFIER_STATE_FLYING] = true,
                        --[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        --[MODIFIER_STATE_DISARMED] = true,
                        --[MODIFIER_STATE_SILENCED] = true,
                        --[MODIFIER_STATE_MUTED] = true,
                    }
    return state
end

modifier_nero_rosa_window = class({})

function modifier_nero_rosa_window:IsHidden() return false end
function modifier_nero_rosa_window:IsDebuff() return false end
function modifier_nero_rosa_window:IsPurgable() return false end
function modifier_nero_rosa_window:IsPurgeException() return false end
function modifier_nero_rosa_window:RemoveOnDeath() return true end

function modifier_nero_rosa_window:OnCreated()
	if IsServer() then
		self.ability = self:GetAbility()
		self.ability:EndCooldown()
	end
end

function modifier_nero_rosa_window:OnDestroy()
	if IsServer() then
		self.ability:StartCooldown(self.ability:GetCooldown(self.ability:GetLevel()))
	end
end