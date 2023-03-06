LinkLuaModifier("modifier_edmon_dash", "abilities/edmon/edmon_dash", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_edmon_dash_particle", "abilities/edmon/edmon_dash", LUA_MODIFIER_MOTION_NONE)

edmon_dash = class({})

function edmon_dash:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_edmon_dash_particle", {duration = 5})

	return true
end

function edmon_dash:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_edmon_dash_particle")
end

function edmon_dash:GetBehavior()
	if self:GetCaster().EscapeAcquired then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
	end
	return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING + DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES
end

function edmon_dash:GetCastRange()
	return self:GetSpecialValueFor("range")
end

function edmon_dash:OnSpellStart()
	local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    if IsSpellBlocked(target) then caster:RemoveModifierByName("modifier_edmon_dash_particle") return end
	caster:AddNewModifier(caster, self, "modifier_edmon_dash", {})
end

modifier_edmon_dash_particle = class({})

function modifier_edmon_dash_particle:IsHidden() return true end

function modifier_edmon_dash_particle:OnCreated()
	self.parent = self:GetParent()

	self.fx = ParticleManager:CreateParticle("particles/edmon/edmon_dash.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControl(self.fx, 0, self.parent:GetAbsOrigin())
	self:AddParticle(self.fx, false, false, -1, false, false)
end

modifier_edmon_dash = class({})

function modifier_edmon_dash:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	if IsServer() then
		self.target = self.ability:GetCursorTarget()
		self.speed = self.ability:GetSpecialValueFor("speed")
		self.flytopoint = false

		self.fx = ParticleManager:CreateParticle("particles/edmon/edmon_dash_cone.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:SetParticleControl(self.fx, 0, self.parent:GetAbsOrigin())
		self:AddParticle(self.fx, false, false, -1, false, false)

        self.targetpos = self.target:GetAbsOrigin()

		self:StartIntervalThink(FrameTime())
		--[[if self:ApplyHorizontalMotionController() == false then
            self:Destroy()
        end]]
	end
end

function modifier_edmon_dash:IsHidden() return true end
function modifier_edmon_dash:IsDebuff() return false end
function modifier_edmon_dash:RemoveOnDeath() return true end
function modifier_edmon_dash:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_edmon_dash:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end
function modifier_edmon_dash:GetOverrideAnimation()
	return ACT_DOTA_CAST_ABILITY_4_END
end
function modifier_edmon_dash:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    --[MODIFIER_STATE_DISARMED] = true,
                    --[MODIFIER_STATE_SILENCED] = true,
                    --[MODIFIER_STATE_MUTED] = true,
                    [MODIFIER_STATE_STUNNED] = true, }

    if self.target and not self.target:IsNull() and self.target:HasFlyMovementCapability() then
        state[MODIFIER_STATE_FLYING] = true
    else
        state[MODIFIER_STATE_FLYING] = false
    end
    
    return state
end
function modifier_edmon_dash:OnRefresh(hui)
    self:OnCreated(hui)
end
function modifier_edmon_dash:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
        self.parent:RemoveModifierByName("modifier_edmon_dash_particle")
        if self.parent:HasModifier("jump_pause_nosilence") then
        	self.parent:RemoveModifierByName("jump_pause_nosilence")
        end

        if self.ability.particle_kappa then
            ParticleManager:DestroyParticle(self.ability.particle_kappa, false)
            ParticleManager:ReleaseParticleIndex(self.ability.particle_kappa)
        end
    end
end
function modifier_edmon_dash:OnIntervalThink()
	self:UpdateHorizontalMotion(self.parent, FrameTime())
end
function modifier_edmon_dash:UpdateHorizontalMotion(me, dt)
    --[[local UFilter = UnitFilter( self.target,
                                self.ability:GetAbilityTargetTeam(),
                                self.ability:GetAbilityTargetType(),
                                self.ability:GetAbilityTargetFlags(),
                                self.parent:GetTeamNumber() )

    if UFilter ~= UF_SUCCESS then
        self:Destroy()

        return nil
    end]]

    if not self.target or not self.target:IsAlive() then
    	--self:Destroy()
    	self.flytopoint = true

    	--return nil
    end

    if (self.targetpos - self.target:GetAbsOrigin()):Length2D() > 300 then
        --self:Destroy()
        self.flytopoint = true

        --return nil
    end

    if not self.flytopoint then
    	self.targetpos = self.target:GetAbsOrigin()
    end

    if (self.targetpos - self.parent:GetOrigin()):Length2D() < 200 then
        self:BOOM()

        self:Destroy()
        return nil
    end

    self:Rush(me, dt)
end
function modifier_edmon_dash:BOOM()
    local position = self.target:GetAbsOrigin()
    local damage = self.damage

    if IsSpellBlocked(self.target) then return end

   	--[[local duck = 0
   	if self.parent.RampageAcquired then
   		duck = 1
   	end

    local knockback = { should_stun = duck,
                        knockback_duration = 0.5,
                        duration = 1.0,
                        knockback_distance = 150,
                        knockback_height = 50,
                        center_x = self.parent:GetAbsOrigin().x,
                        center_y = self.parent:GetAbsOrigin().y,
                        center_z = self.parent:GetAbsOrigin().z }

	self.target:AddNewModifier(self.parent, self.ability, "modifier_knockback", knockback)

    local enemies = FindUnitsInRadius(  self.parent:GetTeamNumber(),
                                        position,
                                        nil,
                                        self.ability:GetSpecialValueFor("radius"),
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_NONE,
                                        FIND_ANY_ORDER,
                                        false)

    local blow_fx =     ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_blast_off.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
                        ParticleManager:SetParticleControl(blow_fx, 0, position)
                        ParticleManager:ReleaseParticleIndex(blow_fx)

    if self.parent:HasModifier("pedigree_off") and self.parent.RampageAcquired then
	    for _, enemy in pairs(enemies) do
	        if enemy and not enemy:IsNull() and IsValidEntity(enemy) and enemy ~= self.target and not enemy:IsMagicImmune() then
	            DoDamage(self.parent, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
	        end
	    end
	end
	
	if not self.target:IsMagicImmune() then
		DoDamage(self.parent, self.target, damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
	end

    EmitSoundOnLocationWithCaster(position, "Archer.HruntHit", self.parent)]]
end
function modifier_edmon_dash:Rush(me, dt)
    --[[if self.parent:IsStunned() then
        return nil
    end]]

    local pos = self.parent:GetOrigin()
    local targetpos = self.targetpos

    local direction = targetpos - pos
    direction.z = 0     
    local target = pos + direction:Normalized() * (self.speed * dt)

    self.parent:SetOrigin(target)
    self.parent:SetForwardVector(direction:Normalized())
end
--[[function modifier_edmon_dash:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end]]