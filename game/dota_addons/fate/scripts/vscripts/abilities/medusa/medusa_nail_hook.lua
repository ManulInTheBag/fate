medusa_nail_hook = class({})

LinkLuaModifier("modifier_medusa_hook_movement","abilities/medusa/medusa_nail_hook", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_medusa_hook_particle_control","abilities/medusa/medusa_nail_hook", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_medusa_new_combo_window", "abilities/medusa/medusa_nail_hook", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_medusa_bleed","abilities/medusa/medusa_nail_hook", LUA_MODIFIER_MOTION_NONE)

function medusa_nail_hook:GetCastRange()
	return self:GetSpecialValueFor("range")
end

function medusa_nail_hook:OnSpellStart()
	if self.launched == true then
		self:GetCaster():GiveMana(self:GetManaCost(-1))
		self:EndCooldown()
		return
	end

	self.launched = true

	local caster = self:GetCaster()
	local ability = self
	local pepepos = caster:GetAbsOrigin()

	caster:EmitSound("Rider.NailSwing")

	if caster:HasModifier("modifier_medusa_new_combo_window") then
		if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
	    	if caster:FindAbilityByName("medusa_bellerophon_2"):IsCooldownReady() and caster:FindAbilityByName("medusa_bellerophon"):IsCooldownReady() and caster:IsAlive() and caster:GetAbilityByIndex(5):GetName() ~= "medusa_bellerophon_2" then	    		
	    		caster:SwapAbilities("medusa_bellerophon_2", "medusa_bellerophon", true, false)
	    		Timers:CreateTimer(4, function()
	    			caster:SwapAbilities("medusa_bellerophon_2", "medusa_bellerophon", false, true)
	    	    end)   		
	    	end
	    end
	end

	local target_position = GetGroundPosition(self:GetCursorPosition(), caster)

	if target_position == caster:GetAbsOrigin() then
		target_position = target_position + self:GetCaster():GetForwardVector()
	end

	local direction = (Vector(target_position.x, target_position.y, 0) - Vector(caster:GetAbsOrigin().x, caster:GetAbsOrigin().y, 0)):Normalized()

	local range = (target_position - caster:GetAbsOrigin()):Length2D()
	if range > self:GetSpecialValueFor("range") then
		range = self:GetSpecialValueFor("range")
		target_position = caster:GetAbsOrigin() + direction*self:GetSpecialValueFor("range")
	end

	local fly_speed = self:GetSpecialValueFor("fly_speed")
	local damage = self:GetSpecialValueFor("damage")

	local hook_speed = self:GetSpecialValueFor("speed")

	caster:SetForwardVector(direction)
	StartAnimation(caster, {duration=1.26, activity=ACT_DOTA_CAST_ABILITY_1, rate=2})

	local chTarget = CreateUnitByName("hrunt_illusion", self:GetCaster():GetAbsOrigin(), true, nil, nil, self:GetCaster():GetTeamNumber())
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

	local vKillswitch = Vector(((self:GetCastRange() / hook_speed) * 2) + 10, 0, 0)

	local hook_particle1 = ParticleManager:CreateParticle("particles/medusa/medusa_hook_chain.vpcf", PATTACH_CUSTOMORIGIN, caster)
	--ParticleManager:SetParticleAlwaysSimulate(hook_particle1)
	ParticleManager:SetParticleControlEnt(hook_particle1, 0, caster, PATTACH_POINT_FOLLOW, "attach_hand1", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(hook_particle1, 3, chTarget:GetAbsOrigin() + Vector(0, 0, 96))
	ParticleManager:SetParticleControl(hook_particle1, 8, Vector(1, 0, 0))

	local hook_particle2 = ParticleManager:CreateParticle("particles/medusa/medusa_hook_chain.vpcf", PATTACH_CUSTOMORIGIN, caster)
	--ParticleManager:SetParticleAlwaysSimulate(hook_particle2)
	ParticleManager:SetParticleControlEnt(hook_particle2, 0, caster, PATTACH_POINT_FOLLOW, "attach_hand2", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(hook_particle2, 3, chTarget:GetAbsOrigin() + Vector(0, 0, 96))
	ParticleManager:SetParticleControl(hook_particle2, 8, Vector(0, 0, 0))

	local particle_modifier = chTarget:AddNewModifier(caster, ability, "modifier_medusa_hook_particle_control", {particle1 = hook_particle1,
																												particle2 = hook_particle2})

	--print(caster:GetForwardVector())

	local sin = Physics:Unit(chTarget)
	chTarget:SetPhysicsFriction(0)
	chTarget:SetPhysicsVelocity(direction*hook_speed)
	chTarget:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

	Timers:CreateTimer("medusa_hook", {
		endTime = range/hook_speed,
		callback = function()
		self:GetCaster():EmitSound("Rider.NailSwing")
		chTarget:OnPreBounce(nil)
		chTarget:SetBounceMultiplier(0)
		chTarget:PreventDI(false)
		chTarget:SetPhysicsVelocity(Vector(0,0,0))
		FindClearSpaceForUnit(chTarget, chTarget:GetAbsOrigin(), true)
		target_position = chTarget:GetAbsOrigin()
		chTarget:RemoveModifierByName("modifier_medusa_hook_particle_control")
		ParticleManager:SetParticleControl(hook_particle1, 3, chTarget:GetAbsOrigin() + Vector(0, 0, 48))
		ParticleManager:SetParticleControl(hook_particle2, 3, chTarget:GetAbsOrigin() + Vector(0, 0, 48))
		ParticleManager:SetParticleControl(hook_particle1, 8, Vector(0, 0, 0))
		ParticleManager:SetParticleControl(hook_particle2, 8, Vector(0, 0, 0))
		caster:RemoveModifierByName("modifier_medusa_chain_movement")
		if (caster:GetAbsOrigin() - pepepos):Length2D() > 1700 or not caster:IsAlive() then
			ParticleManager:DestroyParticle(hook_particle1, false)
    		ParticleManager:ReleaseParticleIndex(hook_particle1)
    		ParticleManager:DestroyParticle(hook_particle2, false)
    		ParticleManager:ReleaseParticleIndex(hook_particle2)
    		self.launched = false
			return
		end
		caster:AddNewModifier(caster, ability, "modifier_medusa_hook_movement", {	target_position_x = target_position.x, 
																				target_position_y = target_position.y,
																				target_position_z = target_position.z,
																				particle1 = hook_particle1,
																				particle2 = hook_particle2,
																				range = range,
																				fly_speed = fly_speed,
																				damage = damage
																				})
	return end
	})

	chTarget:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		Timers:RemoveTimer("medusa_hook")
		self:GetCaster():EmitSound("Rider.NailSwing")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
		target_position = unit:GetAbsOrigin()
		unit:RemoveModifierByName("modifier_medusa_hook_particle_control")
		ParticleManager:SetParticleControl(hook_particle1, 8, Vector(0, 0, 0))
		ParticleManager:SetParticleControl(hook_particle2, 8, Vector(0, 0, 0))
		ParticleManager:SetParticleControl(hook_particle1, 3, unit:GetAbsOrigin() + Vector(0, 0, 48))
		ParticleManager:SetParticleControl(hook_particle2, 3, unit:GetAbsOrigin() + Vector(0, 0, 48))
		caster:RemoveModifierByName("modifier_medusa_chain_movement")
		if (caster:GetAbsOrigin() - pepepos):Length2D() > 1700 or not caster:IsAlive() then
			ParticleManager:DestroyParticle(hook_particle1, false)
    		ParticleManager:ReleaseParticleIndex(hook_particle1)
    		ParticleManager:DestroyParticle(hook_particle2, false)
    		ParticleManager:ReleaseParticleIndex(hook_particle2)
    		self.launched = false
			return
		end
		caster:AddNewModifier(caster, ability, "modifier_medusa_hook_movement", {	target_position_x = target_position.x, 
																				target_position_y = target_position.y,
																				target_position_z = target_position.z,
																				particle1 = hook_particle1,
																				particle2 = hook_particle2,
																				range = range,
																				fly_speed = fly_speed,
																				damage = damage
																				})
	end)
end

modifier_medusa_hook_movement = class({})
function modifier_medusa_hook_movement:IsHidden() return true end
function modifier_medusa_hook_movement:IsDebuff() return false end
function modifier_medusa_hook_movement:IsPurgable() return false end
function modifier_medusa_hook_movement:IsPurgeException() return false end
function modifier_medusa_hook_movement:RemoveOnDeath() return true end
function modifier_medusa_hook_movement:CheckState()
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
function modifier_medusa_hook_movement:OnCreated(args)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    if IsServer() then
    	self.particle1 = args.particle1
    	self.particle2 = args.particle2
        self.speed          = args.fly_speed
        self.damage         = args.damage
        self.firstHit = false

        self.point          = Vector(args.target_position_x, args.target_position_y, args.target_position_z)
        self.distance = (self.point - self.parent:GetAbsOrigin()):Length2D()
        self.direction      = (self.point - self.parent:GetAbsOrigin()):Normalized()
        self.direction.z    = 0

        self.AttackedTargets    = {}

        self:StartIntervalThink(FrameTime())
    end
end
function modifier_medusa_hook_movement:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_medusa_hook_movement:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_medusa_hook_movement:UpdateHorizontalMotion(me, dt)
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
function modifier_medusa_hook_movement:PlayEffects()
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
            if self.parent.ChainMasteryAcquired and not self.firstHit then
            	self.firstHit = true
            	self.ability:EndCooldown()
            	self.ability:StartCooldown(self.ability:GetSpecialValueFor("reduced_cooldown"))
            end

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
	                                knockback_duration = 0.05,
	                                duration = 0.05,
	                                knockback_distance = 50 or 0,
	                                knockback_height = 30,
	                                center_x = kborigin.x,
	                                center_y = kborigin.y,
	                                center_z = kborigin.z }

	    	enemy:AddNewModifier(caster, self.ability, "modifier_knockback", knockback)

            DoDamage(self.parent, enemy, self.damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)

            if self.parent.ChainMasteryAcquired then
            	enemy:AddNewModifier(self.parent, self.ability, "modifier_medusa_bleed", {duration = self.parent.MasterUnit2:FindAbilityByName("medusa_chain_attribute"):GetSpecialValueFor("duration")})
            	self.parent:PerformAttack(enemy, true, true, true, true, false, false, false)
            end
        end
    end
end
function modifier_medusa_hook_movement:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_medusa_hook_movement:OnDestroy()
    if IsServer() then
    	ParticleManager:DestroyParticle(self.particle1, false)
    	ParticleManager:ReleaseParticleIndex(self.particle1)
    	ParticleManager:DestroyParticle(self.particle2, false)
    	ParticleManager:ReleaseParticleIndex(self.particle2)
        self.parent:InterruptMotionControllers(true)
        EndAnimation(self.parent)
        if not ((self.parent:GetAbsOrigin() - self.point):Length2D() > 1700) then
        	FindClearSpaceForUnit(self.parent, self.point, true)
        else
        	FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
        end
        self.ability.launched = false
    end
end

modifier_medusa_hook_particle_control = class({})

function modifier_medusa_hook_particle_control:OnCreated(args)
	if IsServer() then
		self.parent = self:GetCaster()
		self.ability = self:GetAbility()
		self.damage = self.ability:GetSpecialValueFor("damage")

		self.AttackedTargets    = {}

		self.particle1 = args.particle1
		self.particle2 = args.particle2
		self:StartIntervalThink(FrameTime())
	end
end

function modifier_medusa_hook_particle_control:OnIntervalThink()
	if IsServer() then
		ParticleManager:SetParticleControl(self.particle1, 3, self:GetParent():GetAbsOrigin() + Vector(0, 0, 96))
		ParticleManager:SetParticleControl(self.particle2, 3, self:GetParent():GetAbsOrigin() + Vector(0, 0, 96))
		--self:PlayEffects()
	end
end
function modifier_medusa_hook_particle_control:PlayEffects()
	local enemies = FindUnitsInRadius(  self.parent:GetTeamNumber(),
                                        self:GetParent():GetAbsOrigin(),
                                        nil,
                                        20,
                                       	DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        0,
                                        FIND_CLOSEST,
                                        false)

    for _, enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() and IsValidEntity(enemy) and enemy ~= self.parent and not self.AttackedTargets[enemy:entindex()] then
            self.AttackedTargets[enemy:entindex()] = true

            DoDamage(self.parent, enemy, self.damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
        end
    end
end

modifier_medusa_new_combo_window = class({})

function modifier_medusa_new_combo_window:IsHidden()
	return true 
end

function modifier_medusa_new_combo_window:RemoveOnDeath()
	return false
end

function modifier_medusa_new_combo_window:IsDebuff()
	return true 
end

function modifier_medusa_new_combo_window:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

modifier_medusa_bleed = class({})

function modifier_medusa_bleed:IsHidden()
	return false 
end

function modifier_medusa_bleed:RemoveOnDeath()
	return true
end

function modifier_medusa_bleed:IsDebuff()
	return true 
end

function modifier_medusa_bleed:OnCreated()
	if IsServer() then
		self.parent = self:GetParent()
		self.caster = self:GetCaster()
		self.ability = self:GetAbility()
		self.damage = self.caster.MasterUnit2:FindAbilityByName("medusa_chain_attribute"):GetSpecialValueFor("damage")
		self:SetStackCount(1)
		self:StartIntervalThink(0.5)
	end
end

function modifier_medusa_bleed:OnRefresh()
	if IsServer() then
		self:SetStackCount(self:GetStackCount() + 1)
	end
end

function modifier_medusa_bleed:OnIntervalThink()
	if IsServer() then
		DoDamage(self.caster, self.parent, self.damage/2*self:GetStackCount(), DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
	end
end