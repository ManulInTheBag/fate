LinkLuaModifier("modifier_mordred_rush", "abilities/mordred/mordred_rush", LUA_MODIFIER_MOTION_HORIZONTAL)

mordred_rush = class({})

--[[function mordred_rush:OnUpgrade()
    local clarent = self:GetCaster():FindAbilityByName("mordred_clarent")
    clarent:SetLevel(self:GetLevel())
end]]

function mordred_rush:OnSpellStart()
	self.ChannelTime = 0
    self:GetCaster().RageRushTarget = self:GetCursorTarget()
	self.particle_kappa = ParticleManager:CreateParticle("particles/custom/mordred/max_excalibur/charge.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
end

function mordred_rush:OnChannelThink(fInterval)
    self.ChannelTime = self.ChannelTime + fInterval
    self:GetCaster():FaceTowards(self:GetCursorTarget():GetAbsOrigin())
end

function mordred_rush:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()

	StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_CAST_ABILITY_4_END, rate=1.0})

	caster:EmitSound("mordred_rush")

	if caster:HasModifier("pedigree_off") and caster:HasModifier("modifier_mordred_overload") then
    	local kappa = caster:FindModifierByName("modifier_mordred_overload")
    	kappa:Doom()
   	end

	self.damage = self:GetSpecialValueFor("damage") + self:GetSpecialValueFor("damage_per_second")*self.ChannelTime
	self.speed = self:GetSpecialValueFor("speed") + self:GetSpecialValueFor("speed_per_second")*self.ChannelTime
	caster:AddNewModifier(caster, self, "modifier_mordred_rush", {damage = self.damage,
																	speed = self.speed,
																	dolbayob_factor = 0})
	--[[self.range = self:GetSpecialValueFor("distance")*self.ChannelTime/2

	local qdProjectile = 
	{
		Ability = self,
        EffectName = nil,
        iMoveSpeed = 1800,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = self.range,
        fStartRadius = 300,
        fEndRadius = 300,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 1800
	}

	local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 1.0)
	caster:EmitSound("Hero_PhantomLancer.Doppelwalk") 
	local sin = Physics:Unit(caster)
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(caster:GetForwardVector() * 1800)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

	Timers:CreateTimer("mordred_rush", {
		endTime = self.range/self:GetSpecialValueFor("distance"),
		callback = function()
		caster:OnPreBounce(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	return end
	})

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		Timers:RemoveTimer("mordred_rush")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end)]]
end

--[[function mordred_rush:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	if self.damage == nil then self.damage = self:GetSpecialValueFor("damage") + self:GetSpecialValueFor("damage_per_second")*2 end
	--print(self.damage)

	--giveUnitDataDrivenModifier(caster, hTarget, "rooted", duration)
	--giveUnitDataDrivenModifier(caster, hTarget, "locked", duration)

	DoDamage(caster, hTarget, self.damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
end]]
modifier_mordred_rush = class({})

function modifier_mordred_rush:OnCreated(hui)
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	if IsServer() then
		if hui.dolbayob_factor == 1 then
			self.target = self.parent.debil
		else
			self.target = self.parent.RageRushTarget
		end
		self.damage = hui.damage
		self.speed = hui.speed

        self.targetpos = self.target:GetAbsOrigin()

		self:StartIntervalThink(FrameTime())
		if self:ApplyHorizontalMotionController() == false then
            self:Destroy()
        end
	end
end

function modifier_mordred_rush:IsHidden() return true end
function modifier_mordred_rush:IsDebuff() return false end
function modifier_mordred_rush:RemoveOnDeath() return true end
function modifier_mordred_rush:GetPriority() return MODIFIER_PRIORITY_HIGH end

function modifier_mordred_rush:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    --[MODIFIER_STATE_DISARMED] = true,
                    --[MODIFIER_STATE_SILENCED] = true,
                    --[MODIFIER_STATE_MUTED] = true,
                    [MODIFIER_STATE_COMMAND_RESTRICTED] = true, }

    if self.target and not self.target:IsNull() and self.target:HasFlyMovementCapability() then
        state[MODIFIER_STATE_FLYING] = true
    else
        state[MODIFIER_STATE_FLYING] = false
    end
    
    return state
end
function modifier_mordred_rush:OnRefresh(hui)
    self:OnCreated(hui)
end
function modifier_mordred_rush:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
        if self.parent:HasModifier("jump_pause_nosilence") then
        	self.parent:RemoveModifierByName("jump_pause_nosilence")
        end

        if self.ability.particle_kappa then
            ParticleManager:DestroyParticle(self.ability.particle_kappa, false)
            ParticleManager:ReleaseParticleIndex(self.ability.particle_kappa)
        end
    end
end
function modifier_mordred_rush:UpdateHorizontalMotion(me, dt)
    local UFilter = UnitFilter( self.target,
                                self.ability:GetAbilityTargetTeam(),
                                self.ability:GetAbilityTargetType(),
                                self.ability:GetAbilityTargetFlags(),
                                self.parent:GetTeamNumber() )

    if UFilter ~= UF_SUCCESS then
        self:Destroy()

        return nil
    end

    if (self.targetpos - self.target:GetAbsOrigin()):Length2D() > 300 then
        self:Destroy()

        return nil
    end

    self.targetpos = self.target:GetAbsOrigin() 

    if (self.target:GetOrigin() - self.parent:GetOrigin()):Length2D() < 150 then
        self:BOOM()

        self:Destroy()
        return nil
    end

    self:Rush(me, dt)
end
function modifier_mordred_rush:BOOM()
    local position = self.target:GetAbsOrigin()
    local damage = self.damage

    if IsSpellBlocked(self.target) then return end

    if self.parent:HasModifier("pedigree_off") and self.parent:HasModifier("modifier_mordred_overload") then
    	local kappa = self.parent:FindModifierByName("modifier_mordred_overload")
    	kappa:Doom()
   	end

   	local duck = 0
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

    EmitSoundOnLocationWithCaster(position, "Archer.HruntHit", self.parent)
end
function modifier_mordred_rush:Rush(me, dt)
    --[[if self.parent:IsStunned() then
        return nil
    end]]

    local pos = self.parent:GetOrigin()
    local targetpos = self.target:GetOrigin()

    local direction = targetpos - pos
    direction.z = 0     
    local target = pos + direction:Normalized() * (self.speed * dt)

    self.parent:SetOrigin(target)
    self.parent:FaceTowards(targetpos)
end
function modifier_mordred_rush:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end