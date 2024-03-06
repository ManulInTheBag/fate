LinkLuaModifier("modifier_aoko_dailin", "abilities/aoko/aoko_dailin", LUA_MODIFIER_MOTION_NONE)

aoko_dailin = class({})

function aoko_dailin:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_aoko_dailin", {})
end

function aoko_dailin:Kick(target)
	local caster = self:GetCaster()
	local target = target

	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 1.43)

	FindClearSpaceForUnit(caster, GetGroundPosition(target:GetAbsOrigin() - caster:GetForwardVector()*75, caster), true)

	Timers:CreateTimer(FrameTime(), function()
		local dir = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Normalized()
		dir.z = 0

		caster:SetForwardVector(-dir)
	end)

	target:AddNewModifier(caster, self, "modifier_stunned", {duration = 2})

	DoDamage(caster, target, 200, DAMAGE_TYPE_MAGICAL, 0, self, false)
	self:Effects(target)

	--[[StartAnimation(caster, {duration=0.77, activity=ACT_SCRIPT_CUSTOM_0, rate=1.0})
	Timers:CreateTimer(0.13, function ()
		DoDamage(caster, target, 200, DAMAGE_TYPE_MAGICAL, 0, self, false)
		target:AddNewModifier(caster, self, "modifier_stunned", {duration = 2})
	end)]]
	Timers:CreateTimer(0.2, function()
		StartAnimation(caster, {duration=0.47, activity=ACT_SCRIPT_CUSTOM_0, rate=1.0})
		Timers:CreateTimer(0.13, function()
			DoDamage(caster, target, 200, DAMAGE_TYPE_MAGICAL, 0, self, false)
			self:Effects(target)
			target:AddNewModifier(caster, self, "modifier_stunned", {duration = 2})
		end)
	end)
	Timers:CreateTimer(0.45, function()
		StartAnimation(caster, {duration=0.50, activity=ACT_SCRIPT_CUSTOM_1, rate=1.0})
		Timers:CreateTimer(0.1, function()
			DoDamage(caster, target, 200, DAMAGE_TYPE_MAGICAL, 0, self, false)
			self:Effects(target)
			target:AddNewModifier(caster, self, "modifier_stunned", {duration = 2})
		end)
	end)
	Timers:CreateTimer(0.6, function()
		StartAnimation(caster, {duration=1.0, activity=ACT_SCRIPT_CUSTOM_2, rate=1.0})
		Timers:CreateTimer(0.17, function()
			DoDamage(caster, target, 200, DAMAGE_TYPE_MAGICAL, 0, self, false)
			self:Effects(target)
			target:AddNewModifier(caster, self, "modifier_stunned", {duration = 2})
		end)
	end)
end

function aoko_dailin:Effects(target)
	local caster = self:GetCaster()
	EmitSoundOn("edmon_fast_melee", caster)

	local groundFx = ParticleManager:CreateParticle( "particles/aoko/aoko_blast.vpcf", PATTACH_ABSORIGIN, caster )
	--ParticleManager:SetParticleControl( groundFx, 0, caster:GetForwardVector())
	ParticleManager:SetParticleControl( groundFx, 5, target:GetAttachmentOrigin(target:ScriptLookupAttachment("attach_hitloc")))

	if not IsKnockbackImmune(target) then
		local casterfacing = caster:GetForwardVector()
		local pushTarget = Physics:Unit(target)
		local casterOrigin = caster:GetAbsOrigin()
		local initialUnitOrigin = target:GetAbsOrigin()
		target:PreventDI()
		target:SetPhysicsFriction(0)
		target:SetPhysicsVelocity(casterfacing:Normalized() * 1000)
		target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
		target:OnPhysicsFrame(function(unit) 
			local unitOrigin = unit:GetAbsOrigin()
			local diff = unitOrigin - initialUnitOrigin
			local n_diff = diff:Normalized()
			unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) 
			if diff:Length() > 10 then
				unit:PreventDI(false)
				unit:SetPhysicsVelocity(Vector(0,0,0))
				unit:OnPhysicsFrame(nil)
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
			end
		end)

		target:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
			unit:SetBounceMultiplier(0)
			unit:PreventDI(false)
			unit:SetPhysicsVelocity(Vector(0,0,0))
			--[[if not target:IsMagicImmune() then
				giveUnitDataDrivenModifier(caster, target, "stunned", ability:GetSpecialValueFor("stun_duration"))
				target:EmitSound("Hero_EarthShaker.Fissure")
				DoDamage(caster, target, self.collide_damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			end]]
		end)

		casterfacing = caster:GetForwardVector()
		pushTarget = Physics:Unit(caster)
		casterOrigin = caster:GetAbsOrigin()
		initialUnitOrigin = caster:GetAbsOrigin()
		caster:PreventDI()
		caster:SetPhysicsFriction(0)
		caster:SetPhysicsVelocity(casterfacing:Normalized() * 1000)
		caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
		caster:OnPhysicsFrame(function(unit) 
			local unitOrigin = unit:GetAbsOrigin()
			local diff = unitOrigin - initialUnitOrigin
			local n_diff = diff:Normalized()
			unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) 
			if diff:Length() > 10 then
				unit:PreventDI(false)
				unit:SetPhysicsVelocity(Vector(0,0,0))
				unit:OnPhysicsFrame(nil)
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
			end
		end)

		caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
			unit:SetBounceMultiplier(0)
			unit:PreventDI(false)
			unit:SetPhysicsVelocity(Vector(0,0,0))
			--[[if not target:IsMagicImmune() then
				giveUnitDataDrivenModifier(caster, target, "stunned", ability:GetSpecialValueFor("stun_duration"))
				target:EmitSound("Hero_EarthShaker.Fissure")
				DoDamage(caster, target, self.collide_damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			end]]
		end)
	end
end

modifier_aoko_dailin = class({})

function modifier_aoko_dailin:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	if IsServer() then
		self.speed = self.ability:GetSpecialValueFor("speed")
		self.distelapsed = self.ability:GetSpecialValueFor("range")

        self.targetpos = self.parent:GetAbsOrigin() + self.parent:GetForwardVector()*self.ability:GetSpecialValueFor("range")

		self:StartIntervalThink(FrameTime())
		self.pepeg = false
		--[[if self:ApplyHorizontalMotionController() == false then
            self:Destroy()
        end]]
	end
end

function modifier_aoko_dailin:IsHidden() return true end
function modifier_aoko_dailin:IsDebuff() return false end
function modifier_aoko_dailin:RemoveOnDeath() return true end
function modifier_aoko_dailin:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_aoko_dailin:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end
function modifier_aoko_dailin:GetOverrideAnimation()
	return ACT_DOTA_CHANNEL_ABILITY_6
end
function modifier_aoko_dailin:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    --[MODIFIER_STATE_DISARMED] = true,
                    --[MODIFIER_STATE_SILENCED] = true,
                    --[MODIFIER_STATE_MUTED] = true,
                    [MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY ] = true, }
    
    return state
end
function modifier_aoko_dailin:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end
function modifier_aoko_dailin:OnIntervalThink()
	self:UpdateHorizontalMotion(self.parent, FrameTime())
end
function modifier_aoko_dailin:UpdateHorizontalMotion(me, dt)
	self.distelapsed = self.distelapsed - dt*self.speed

    if self.distelapsed <= 0 then
        --self:BOOM()

        self:Destroy()
        return nil
    end

    self:Rush(me, dt)
end
function modifier_aoko_dailin:Rush(me, dt)
    --[[if self.parent:IsStunned() then
        return nil
    end]]

    local pos = self.parent:GetOrigin()
    local targetpos = self.targetpos

    local direction = self.parent:GetForwardVector()--targetpos - pos
    direction.z = 0     
    local target = pos + direction:Normalized() * (self.speed * dt)

    self.parent:SetOrigin(target)
    --self.parent:SetForwardVector(direction:Normalized())

    local unitGroup = FindUnitsInRadius(self.parent:GetTeam(), target, nil, 175, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
    for i = 1, #unitGroup do
    	if not self.pepeg then
    		self.pepeg = true
			self:GetAbility():Kick(unitGroup[i])
			self:Destroy()
		end
	end
end
--[[function modifier_edmon_enfer:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end]]
