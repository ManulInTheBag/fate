LinkLuaModifier("modifier_medusa_gorgon_rush","abilities/medusa/medusa_gorgon_rush", LUA_MODIFIER_MOTION_NONE)

medusa_gorgon_rush = class({})

function medusa_gorgon_rush:GetCastRange()
	return self:GetSpecialValueFor("range")
end

function medusa_gorgon_rush:OnAbilityPhaseStart()
    self:GetCaster():EmitSound("medusa_gorgon_rush")
    return true
end

function medusa_gorgon_rush:OnAbilityPhaseInterrupted()
    self:GetCaster():StopSound("medusa_gorgon_rush")
end

function medusa_gorgon_rush:OnSpellStart()
	local caster = self:GetCaster()
	local target_position = self:GetCastRange()*caster:GetForwardVector() + caster:GetAbsOrigin()
	local range = self:GetCastRange()
	local fly_speed = self:GetSpecialValueFor("speed")
	local damage = self:GetSpecialValueFor("damage") + caster:GetAgility() * self:GetSpecialValueFor("damage_per_agi")
	caster:EmitSound("medusa_whooshrs")

	caster:AddNewModifier(caster, self, "modifier_medusa_gorgon_rush", {target_position_x = target_position.x, 
																				target_position_y = target_position.y,
																				target_position_z = target_position.z,
																				range = range,
																				fly_speed = fly_speed,
																				damage = damage})
end

modifier_medusa_gorgon_rush = class({})
function modifier_medusa_gorgon_rush:IsHidden() return true end
function modifier_medusa_gorgon_rush:IsDebuff() return false end
function modifier_medusa_gorgon_rush:IsPurgable() return false end
function modifier_medusa_gorgon_rush:IsPurgeException() return false end
function modifier_medusa_gorgon_rush:RemoveOnDeath() return true end
function modifier_medusa_gorgon_rush:CheckState()
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
function modifier_medusa_gorgon_rush:OnCreated(args)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    local caster = self:GetParent()
    local origin = caster:GetAbsOrigin()

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
        self.trail_fx = ParticleManager:CreateParticle( "particles/medusa/medusa_trail_test_2.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self.parent )
		ParticleManager:SetParticleControlEnt( self.trail_fx, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetAbsOrigin(), true )
        --self.trail_fx = ParticleManager:CreateParticle("particles/medusa/medusa_trail_test.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        --ParticleManager:SetParticleControl(self.trail_fx, 6, self.parent:GetAbsOrigin() + Vector(0, 0, 96))
    end
end
function modifier_medusa_gorgon_rush:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_medusa_gorgon_rush:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_medusa_gorgon_rush:UpdateHorizontalMotion(me, dt)
    if IsServer() then
        if self.distance >= 0 then
            local units_per_dt = self.speed * dt
            local parent_pos = self.parent:GetAbsOrigin()

            local next_pos = parent_pos + self.direction * units_per_dt
            next_pos = GetGroundPosition(next_pos, self.parent)
            local distance_will = self.distance - units_per_dt
            if not GridNav:IsTraversable(next_pos) or GridNav:IsBlocked(next_pos) then
            	self.parent:RemoveModifierByName("modifier_medusa_gorgon_rush")
            	self:PlayEffects()
            	--DoDamage(self.parent, self.parent, distance_will, DAMAGE_TYPE_PHYSICAL, 128, self.ability, false)
            	self:Destroy()
            	return
            end

            if not (distance_will < 0) then
            	self.parent:SetForwardVector((Vector(self.point.x, self.point.y, 0) - Vector(parent_pos.x, parent_pos.y, 0)):Normalized())
            end

            self.parent:SetOrigin(next_pos)

            self:PlayEffects()

            self.distance = self.distance - units_per_dt
        else
            self.parent:RemoveModifierByName("modifier_medusa_gorgon_rush")
            self:Destroy()
        end
    end
end
function modifier_medusa_gorgon_rush:PlayEffects()
	local caster = self.parent
	--ParticleManager:SetParticleControl(self.trail_fx, 6, self.parent:GetAbsOrigin() + Vector(0, 0, 96))
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
	                                knockback_duration = 0.15,
	                                duration = 0.15,
	                                knockback_distance = 150 or 0,
	                                knockback_height = 90,
	                                center_x = kborigin.x,
	                                center_y = kborigin.y,
	                                center_z = kborigin.z }

	    	enemy:AddNewModifier(caster, self.ability, "modifier_knockback", knockback)

            DoDamage(self.parent, enemy, self.damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
        end
    end
end
function modifier_medusa_gorgon_rush:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_medusa_gorgon_rush:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
        --EndAnimation(self.parent)
        FindClearSpaceForUnit(self.parent, self.parent:GetAbsOrigin(), true)
        Timers:CreateTimer(FrameTime(), function()
	        ParticleManager:DestroyParticle(self.trail_fx, false)
	    	ParticleManager:ReleaseParticleIndex(self.trail_fx)
	    end)
    end
end