LinkLuaModifier("modifier_aoko_intimidation", "abilities/aoko/aoko_intimidation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_intimidation_grab", "abilities/aoko/aoko_intimidation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_intimidation_grab_enemy", "abilities/aoko/aoko_intimidation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_intimidation_slow", "abilities/aoko/aoko_intimidation", LUA_MODIFIER_MOTION_NONE)

aoko_intimidation = class({})

function aoko_intimidation:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("aoko_3_beams"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("aoko_3_beams"):SetLevel(self:GetLevel())
    end
end

function aoko_intimidation:GetManaCost()
	local caster = self:GetCaster()
	local ability = caster:FindAbilityByName("aoko_circuits")

	local stacks = ability:GetStacks()

	local base_manacost = self:GetSpecialValueFor("mana_cost")
	local increment = ability:GetSpecialValueFor("manacost_increase_per_stack")

	local result = math.min(base_manacost*(1 + stacks*increment/100), caster:GetMaxMana())

	return result
end

function aoko_intimidation:OnAbilityPhaseStart()
	self:GetCaster():EmitSound("aoko_intimidation_castpoint_"..math.random(1, 2))
	return true
end

function aoko_intimidation:OnAbilityPhaseInterrupted()
	self:GetCaster():StopSound("aoko_intimidation_castpoint_1")
	self:GetCaster():StopSound("aoko_intimidation_castpoint_2")
end

function aoko_intimidation:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()

	local dir = (target - caster:GetAbsOrigin()):Normalized()
	dir.z = 0
	if not (target == caster:GetAbsOrigin()) then
		caster:SetForwardVector(dir)
	end

	--caster:AddNewModifier(caster, self, "modifier_aoko_intimidation_test", {duration = 0.75})
	caster:AddNewModifier(caster, self, "modifier_aoko_intimidation", {})
end

function aoko_intimidation:Grab(target)
	local caster = self:GetCaster()

	local circuits = caster:FindAbilityByName("aoko_circuits")
	local stacks = self:GetSpecialValueFor("grab_stacks")

	local damage = self:GetSpecialValueFor("grab_damage")

	caster:EmitSound("aoko_intimidation_grab_1")

	local explosion_fx = ParticleManager:CreateParticle("particles/aoko/aoko_intimidation_grab.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(explosion_fx, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(explosion_fx, 1, Vector(500, 0, 0))
	ParticleManager:SetParticleControl(explosion_fx, 2, Vector(0.95, 0, 0))

	ParticleManager:ReleaseParticleIndex(explosion_fx)

	targetindex = target:entindex()

	caster:AddNewModifier(caster, self, "modifier_aoko_intimidation_grab", {targetindex = targetindex})

	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

	circuits:GainStacks(stacks)
end

function aoko_intimidation:GroundHit(target)
	local caster = self:GetCaster()
	local point = caster:GetAbsOrigin()

	local circuits = caster:FindAbilityByName("aoko_circuits")
	local stacks = self:GetSpecialValueFor("impact_stacks")

	local damage = target:GetMaxHealth() * self:GetSpecialValueFor("impact_health_damage")/100
	local radius = self:GetSpecialValueFor("impact_radius")
	local duration = self:GetSpecialValueFor("slow_duration")

	if target:HasModifier("modifier_aoko_sphere_dummy") then
		damage = self:GetSpecialValueFor("impact_aoko_damage")
		target:FindModifierByName("modifier_aoko_sphere_dummy"):IntimidationExplode(point)

		local explosion_fx = ParticleManager:CreateParticle("particles/aoko/aoko_sphere_aoe_area.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(explosion_fx, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(explosion_fx, 2, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(explosion_fx, 7, Vector(radius, 0, 0))

		ParticleManager:ReleaseParticleIndex(explosion_fx)
	end

	--FindClearSpaceForUnit(caster, GetGroundPosition(target:GetAbsOrigin() - caster:GetForwardVector()*75, caster), true)

	--EmitSoundOnLocationWithCaster(point, "Hero_Leshrac.Split_Earth", caster)
	EmitSoundOnLocationWithCaster(point, "aoko_intimidation_ground_hit_sfx", caster)

    local explosion_fx = ParticleManager:CreateParticle("particles/aoko/aoko_intimidation_impact.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(explosion_fx, 0, point)
	ParticleManager:SetParticleControl(explosion_fx, 1, Vector(radius, 0, 0))

	ParticleManager:ReleaseParticleIndex(explosion_fx)

	if caster.HighSpeedIncantationAcquired then
		local abil = caster:FindAbilityByName("aoko_sphere")
		local vision_radius = abil:GetSpecialValueFor("vision_radius")
		local dummy = CreateUnitByName("aoko_sphere", point, false, nil, nil, caster:GetTeamNumber())
		dummy:FindAbilityByName("dummy_unit_passive_fly_pathing"):SetLevel(1)
		dummy:SetDayTimeVisionRange(vision_radius)
		dummy:SetNightTimeVisionRange(vision_radius)
		dummy:SetForwardVector(caster:GetForwardVector())
		dummy:AddNewModifier(caster, abil, "modifier_aoko_sphere_dummy", {Duration  = abil:GetSpecialValueFor("duration"), posx = point.x, posy = point.y, posz = point.z})
	end
 
    local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        point, 
                                        nil, 
                                        radius,--radius, 
                                        DOTA_UNIT_TARGET_TEAM_ENEMY, 
                                        DOTA_UNIT_TARGET_ALL, 
                                        0, 
                                        FIND_ANY_ORDER, 
                                        false)

    local pepega = true

    for _,enemy in ipairs(enemies) do
    	if pepega then
    		pepega = false
    		circuits:GainStacks(stacks)
    	end
    	enemy:AddNewModifier(caster, self, "modifier_aoko_intimidation_slow", {duration = duration})
        DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
    end
end

modifier_aoko_intimidation = class({})

function modifier_aoko_intimidation:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	if IsServer() then
		self.speed = self.ability:GetSpecialValueFor("speed")
		self.distelapsed = self.ability:GetSpecialValueFor("range")

        self.targetpos = self.parent:GetAbsOrigin() + self.parent:GetForwardVector()*self.ability:GetSpecialValueFor("range")

		self:StartIntervalThink(FrameTime())
		self.pepeg = false

		self.hand_fx_1 = ParticleManager:CreateParticle("particles/aoko/aoko_intimidation_hands_trail.vpcf", PATTACH_ABSORIGIN, self.parent)
		ParticleManager:SetParticleControl(self.hand_fx_1, 1, self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_attack1")))

		self.hand_fx_2 = ParticleManager:CreateParticle("particles/aoko/aoko_intimidation_hands_trail.vpcf", PATTACH_ABSORIGIN, self.parent)
		ParticleManager:SetParticleControl(self.hand_fx_2, 1, self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_attack2")))

		self:AddParticle(self.hand_fx_1, false, false, -1, false, false)
		self:AddParticle(self.hand_fx_2, false, false, -1, false, false)
		--[[if self:ApplyHorizontalMotionController() == false then
            self:Destroy()
        end]]
	end
end

function modifier_aoko_intimidation:IsHidden() return true end
function modifier_aoko_intimidation:IsDebuff() return false end
function modifier_aoko_intimidation:RemoveOnDeath() return true end
function modifier_aoko_intimidation:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_aoko_intimidation:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end
function modifier_aoko_intimidation:GetOverrideAnimation()
	return ACT_DOTA_CHANNEL_ABILITY_6
end
function modifier_aoko_intimidation:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    --[MODIFIER_STATE_DISARMED] = true,
                    --[MODIFIER_STATE_SILENCED] = true,
                    --[MODIFIER_STATE_MUTED] = true,
                    [MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY ] = true, }
    
    return state
end
function modifier_aoko_intimidation:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end
function modifier_aoko_intimidation:OnIntervalThink()
	self:UpdateHorizontalMotion(self.parent, FrameTime())

	ParticleManager:SetParticleControl(self.hand_fx_1, 1, self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_attack1")))
	ParticleManager:SetParticleControl(self.hand_fx_2, 1, self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_attack2")))
end
function modifier_aoko_intimidation:UpdateHorizontalMotion(me, dt)
	self.distelapsed = self.distelapsed - dt*self.speed

    if self.distelapsed <= 0 then
        --self:BOOM()

        self:Destroy()
        return nil
    end

    self:Rush(me, dt)
end
function modifier_aoko_intimidation:Rush(me, dt)
    --[[if self.parent:IsStunned() then
        return nil
    end]]

    local pos = self.parent:GetOrigin()
    local targetpos = self.targetpos

    local direction = self.parent:GetForwardVector()--targetpos - pos
    direction.z = 0     
    local target = pos + direction:Normalized() * (self.speed * dt)

    self.parent:SetOrigin(GetGroundPosition(target, self.parent))
    --self.parent:SetForwardVector(direction:Normalized())

    local unitGroup = FindUnitsInRadius(self.parent:GetTeam(), target, nil, 175, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
    for i = 1, #unitGroup do
    	if not self.pepeg and not IsKnockbackImmune(unitGroup[i]) then
    		self.pepeg = true
			self:GetAbility():Grab(unitGroup[i])
			self:Destroy()
		end
	end

	local unitGroup2 = FindUnitsInRadius(self.parent:GetTeam(), target, nil, 175, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
    for i = 1, #unitGroup2 do
    	if unitGroup2[i]:HasModifier("modifier_aoko_sphere_dummy") then
	    	if not self.pepeg then
	    		self.pepeg = true
	    		unitGroup2[i]:AddNewModifier(self.parent, self.parent:FindAbilityByName("aoko_sphere"), "modifier_aoko_sphere_dummy", {duration = 1, unbreakable = 1})
				self:GetAbility():Grab(unitGroup2[i])
				self:Destroy()
			end
		end
	end
end

----

modifier_aoko_intimidation_grab = class({})

function modifier_aoko_intimidation_grab:OnCreated(args)
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	if IsServer() then
		self.enemy = EntIndexToHScript(args.targetindex)
		self.speed = 800--self.ability:GetSpecialValueFor("speed")
		self.distelapsed = 600--self.ability:GetSpecialValueFor("range")

		EmitSoundOn("aoko_intimidation_grab_sfx", self.enemy)

		StartAnimation(self.parent, {duration=1.1, activity=ACT_SCRIPT_CUSTOM_4, rate=1.0})

        self.targetpos = self.parent:GetAbsOrigin() + self.parent:GetForwardVector()*self.ability:GetSpecialValueFor("range")

        self.enemy:AddNewModifier(self.parent, self.ability, "modifier_aoko_intimidation_grab_enemy", {duration = 0.8})
        self.enemy:AddNewModifier(self.parent, self.ability, "modifier_stunned", {duration = 0.8}) -- DOUBLING THIS BECAUSE OF "STUNNED" ANIMATION, DO NOT REMOVE

        --[[self.hand_fx_1 = ParticleManager:CreateParticle("particles/aoko/aoko_intimidation_hands_trail.vpcf", PATTACH_ABSORIGIN, self.parent)
		ParticleManager:SetParticleControl(self.hand_fx_1, 1, self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_attack1")))

		self.hand_fx_2 = ParticleManager:CreateParticle("particles/aoko/aoko_intimidation_hands_trail.vpcf", PATTACH_ABSORIGIN, self.parent)
		ParticleManager:SetParticleControl(self.hand_fx_2, 1, self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_attack2")))

		self:AddParticle(self.hand_fx_1, false, false, -1, false, false)
		self:AddParticle(self.hand_fx_2, false, false, -1, false, false)]]

		self:StartIntervalThink(FrameTime())
		self.ticks = 0
		self.pepeg = false
		--[[if self:ApplyHorizontalMotionController() == false then
            self:Destroy()
        end]]
	end
end

function modifier_aoko_intimidation_grab:IsHidden() return true end
function modifier_aoko_intimidation_grab:IsDebuff() return false end
function modifier_aoko_intimidation_grab:RemoveOnDeath() return true end
function modifier_aoko_intimidation_grab:GetPriority() return MODIFIER_PRIORITY_HIGH end
--[[function modifier_aoko_intimidation_grab:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end
function modifier_aoko_intimidation_grab:GetOverrideAnimation()
	return ACT_DOTA_CHANNEL_ABILITY_6
end]]
function modifier_aoko_intimidation_grab:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    --[MODIFIER_STATE_DISARMED] = true,
                    --[MODIFIER_STATE_SILENCED] = true,
                    --[MODIFIER_STATE_MUTED] = true,
                    [MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY ] = true, }
    
    return state
end
function modifier_aoko_intimidation_grab:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
        FindClearSpaceForUnit(self.parent, GetGroundPosition(self.parent:GetAbsOrigin(), self.parent), true)
        FindClearSpaceForUnit(self.enemy, GetGroundPosition(self.enemy:GetAbsOrigin() + self.parent:GetForwardVector()*100, self.enemy), true)
        self.ability:GroundHit(self.enemy)
    end
end
function modifier_aoko_intimidation_grab:OnIntervalThink()
	self:UpdateHorizontalMotion(self.parent, FrameTime())

	--[[ParticleManager:SetParticleControl(self.hand_fx_1, 1, self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_attack1")))
	ParticleManager:SetParticleControl(self.hand_fx_2, 1, self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_attack2")))]]
end
function modifier_aoko_intimidation_grab:UpdateHorizontalMotion(me, dt)
	self.distelapsed = self.distelapsed - dt*self.speed

    if self.distelapsed <= 0 then
        --self:BOOM()

        self:Destroy()
        return nil
    end

    self:Rush(me, dt)
    self:EnemyRush()
end
function modifier_aoko_intimidation_grab:Rush(me, dt)
    --[[if self.parent:IsStunned() then
        return nil
    end]]

    local pos = self.parent:GetOrigin()
    local targetpos = self.targetpos

    local direction = self.parent:GetForwardVector()--targetpos - pos
    direction.z = 0

    local target = pos + direction:Normalized() * (self.speed * dt)

    if self.ticks < 5 then
    	target = target + Vector(0, 0, 20)
    elseif self.ticks < 17 then
    	target = target + Vector(0, 0, 5)
    else
    	target = target + Vector(0, 0, -10)
    end

    self.parent:SetOrigin(target)

    self.ticks = self.ticks + 1
end
function modifier_aoko_intimidation_grab:EnemyRush()
    --[[if self.parent:IsStunned() then
        return nil
    end]]

    local pos = self.parent:GetOrigin()
    local pos_enemy = self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_attack2"))--pos + self.parent:GetForwardVector()*50
    dir = (pos_enemy - pos):Normalized()
    dir.x = dir.x*500
    dir.y = dir.y*500
    pos_enemy = pos + dir

    --[[local direction = self.parent:GetForwardVector()--targetpos - pos
    direction.z = 0     
    local target = pos + direction:Normalized() * (self.speed * dt)]]

    self.enemy:SetOrigin(pos_enemy)
    dir.z = 0
    self.enemy:SetForwardVector(-dir)
end

modifier_aoko_intimidation_grab_enemy = class({})

function modifier_aoko_intimidation_grab_enemy:IsHidden() return true end
function modifier_aoko_intimidation_grab_enemy:IsDebuff() return false end
function modifier_aoko_intimidation_grab_enemy:RemoveOnDeath() return true end
function modifier_aoko_intimidation_grab_enemy:CheckState()
    local state = { [MODIFIER_STATE_STUNNED] = true}
    
    return state
end

modifier_aoko_intimidation_slow = class({})

function modifier_aoko_intimidation_slow:IsHidden() return false end
function modifier_aoko_intimidation_slow:IsDebuff() return true end
function modifier_aoko_intimidation_slow:RemoveOnDeath() return true end
function modifier_aoko_intimidation_slow:DeclareFunctions()
	return { 
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
           }
end

function modifier_aoko_intimidation_slow:GetModifierMoveSpeedBonus_Percentage(keys)
    return -1*self:GetCaster():FindAbilityByName("aoko_intimidation"):GetSpecialValueFor("slow_pct")
end