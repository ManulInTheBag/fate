--1.630 3.250 1.380 2.210 (1.370 hit maybe) bell 2.040
LinkLuaModifier("modifier_khsn_azrael", "abilities/kinghassan/khsn_azrael", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_death_door", "abilities/kinghassan/khsn_azrael", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_death_door_pepeg", "abilities/kinghassan/khsn_azrael", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_azrael_move", "abilities/kinghassan/khsn_azrael", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_azrael_stun", "abilities/kinghassan/khsn_azrael", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_azrael_particle", "abilities/kinghassan/khsn_azrael", LUA_MODIFIER_MOTION_NONE)

khsn_azrael = class({})

function khsn_azrael:GetIntrinsicModifierName() return "modifier_khsn_azrael" end 

function khsn_azrael:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if IsSpellBlocked(target) then return end

	--giveUnitDataDrivenModifier(caster, caster, "jump_pause_nosilence", 9999)
	caster:AddNewModifier(caster, self, "modifier_azrael_stun", {duration = 1.37})
	--caster:AddNewModifier(caster, self, "modifier_azrael_move", {duration = 1.63+3.25})
	--caster:AddNewModifier(caster, self, "modifier_azrael_particle", {duration = 6.26 + 2.210})
	caster:AddNewModifier(caster, self, "modifier_azrael_particle", {duration = 1.37})
	--[[EmitGlobalSound("azrael_start")
	Timers:CreateTimer(1.63, function()
		if target and not target:IsNull() and target:IsAlive() then
			EmitGlobalSound("azrael_middle")
		end
	end)

	Timers:CreateTimer(1.63 + 3.25, function()
		if target and not target:IsNull() and target:IsAlive() then
			target:AddNewModifier(caster, self, "modifier_azrael_stun", {duration = 2.75})
			EmitGlobalSound("azrael_end")
		end
	end)]]

	local damage = self:GetSpecialValueFor("damage") + (caster.AzraelAcquired and 100 or 0)
	local modifier_damage = 0
	local modifier_death = target:FindModifierByName("modifier_death_door")
	if target:HasModifier("modifier_death_door_pepeg") then
		modifier_death = target:FindModifierByName("modifier_death_door_pepeg")
	end
	local flag = DOTA_DAMAGE_FLAG_NONE
	if caster.AzraelAcquired then
        flag = DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY
    end
	local multiplier = self:GetSpecialValueFor("dmg_percent")/100 + (caster.AzraelAcquired and 0.1 or 0)
	if modifier_death then
		modifier_damage = modifier_death.recieved_damage*multiplier
	end

	--StartAnimation(caster, {duration=6.26, activity=ACT_DOTA_CAST_ABILITY_4, rate=0.4})

	--Timers:CreateTimer(6.26, function()
		if target and not target:IsNull() and target:IsAlive() then
			local light_index = ParticleManager:CreateParticle("particles/kinghassan/khsn_domus_ray.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl( light_index, 0, target:GetAbsOrigin())
			ParticleManager:SetParticleControl( light_index, 7, target:GetAbsOrigin())
			EmitGlobalSound("azrael_finish")
			StartAnimation(caster, {duration=2.21, activity=ACT_DOTA_CAST_ABILITY_4_END, rate=1.0})
			Timers:CreateTimer(1.370, function()
				if target and not target:IsNull() and target:IsAlive() then
					--[[if not target:IsRealHero() then
						target:Kill(self, caster)
						caster:RemoveModifierByName("jump_pause_nosilence")
						caster:RemoveModifierByName("modifier_azrael_particle")
						return
					end]]
					DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, flag, self, false)
					DoDamage(caster, target, modifier_damage, caster.AzraelAcquired and DAMAGE_TYPE_PURE or DAMAGE_TYPE_MAGICAL, flag, self, false)
					caster:RemoveModifierByName("jump_pause_nosilence")
					EmitGlobalSound("azrael_bell")
					local targetpos = target:GetAbsOrigin() + target:GetForwardVector()*300
					FindClearSpaceForUnit(caster, targetpos, true)
            		caster:FaceTowards(target:GetAbsOrigin())
					local slashFx = ParticleManager:CreateParticle("particles/kinghassan/khsn_feathers.vpcf", PATTACH_ABSORIGIN, target )
					ParticleManager:SetParticleControl( slashFx, 0, target:GetAbsOrigin() + Vector(0,0,300))

					Timers:CreateTimer( 2.0, function()
						ParticleManager:DestroyParticle( slashFx, false )
						ParticleManager:ReleaseParticleIndex( slashFx )
					end)
					Timers:CreateTimer(2.0, function()
						EmitGlobalSound("azrael_bell")
					end)
					Timers:CreateTimer(4.0, function()
						EmitGlobalSound("azrael_bell")
					end)
					if target:GetHealth() < self:GetSpecialValueFor("health_threshold")/100*target:GetMaxHealth() and caster.AzraelAcquired then
						--[[target:AddNewModifier(caster, self, "modifier_death_door_pepeg", {duration = self:GetSpecialValueFor("sequence_duration"),
																							damage = damage})]]
						target:Execute(self, caster, { bExecution = true })
					end
					--[[if not target:IsAlive() and caster.AzraelAcquired then
						self:EndCooldown()
					end]]
				else
					caster:RemoveModifierByName("jump_pause_nosilence")
					caster:RemoveModifierByName("modifier_azrael_particle")
				end
			end)
		else
			caster:RemoveModifierByName("jump_pause_nosilence")
			caster:RemoveModifierByName("modifier_azrael_particle")
		end
	--end)
end

modifier_khsn_azrael = class({})

function modifier_khsn_azrael:IsHidden() 
	return true
end

function modifier_khsn_azrael:IsPermanent()
	return true
end

function modifier_khsn_azrael:RemoveOnDeath()
	return false
end

function modifier_khsn_azrael:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_khsn_azrael:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
end

function modifier_khsn_azrael:DeclareFunctions()
	return {	--MODIFIER_EVENT_ON_TAKEDAMAGE
		}
end

function modifier_khsn_azrael:OnTakeDamage(args)
	if args.attacker ~= self.parent then return end

	local target = args.unit
	target:AddNewModifier(self.parent, self.ability, "modifier_death_door", {duration = self.ability:GetSpecialValueFor("death_door_duration"),
																			damage = (target:FindModifierByName("modifier_death_door") and target:FindModifierByName("modifier_death_door").recieved_damage or args.damage)})
end

modifier_death_door = class({})

function modifier_death_door:IsHidden() return false end
function modifier_death_door:IsDebuff() return true end
function modifier_death_door:RemoveOnDeath() return true end
function modifier_death_door:DeclareFunctions()
	return {	--MODIFIER_EVENT_ON_TAKEDAMAGE,
				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
				MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE	}
end

function modifier_death_door:GetModifierTotalDamageOutgoing_Percentage()
	return -20
end

function modifier_death_door:OnCreated(kappa)
	self.parent = self:GetParent()
	self.recieved_damage = kappa.damage
end
function modifier_death_door:OnTakeDamage(args)
	if args.unit ~= self.parent then return end
	if args.attacker ~= self:GetCaster() then return end

	self.recieved_damage = self.recieved_damage + args.damage
end
function modifier_death_door:GetModifierMoveSpeedBonus_Percentage()
	return -(self:GetCaster():FindAbilityByName("khsn_azrael"):GetSpecialValueFor("death_door_slow") + (self:GetCaster().AzraelAcquired and 10 or 0))
end

modifier_death_door_pepeg = class({})

function modifier_death_door_pepeg:IsHidden() return false end
function modifier_death_door_pepeg:IsDebuff() return true end
function modifier_death_door_pepeg:RemoveOnDeath() return true end
function modifier_death_door_pepeg:DeclareFunctions()
	return {	--MODIFIER_EVENT_ON_TAKEDAMAGE,
				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE	}
end
function modifier_death_door_pepeg:OnCreated(kappa)
	self.parent = self:GetParent()
	self.recieved_damage = kappa.damage
	if IsServer() then
		self:StartIntervalThink(FrameTime())
	end
end
function modifier_death_door_pepeg:OnTakeDamage(args)
	if args.unit ~= self.parent then return end
	if args.attacker ~= self:GetCaster() then return end

	self.recieved_damage = self.recieved_damage + args.damage
end
function modifier_death_door_pepeg:GetModifierMoveSpeedBonus_Percentage()
	return -10
end
function modifier_death_door_pepeg:OnIntervalThink()
	if self.parent:GetHealth()/self.parent:GetMaxHealth()*100 < 22 then
		self.parent:Kill(self:GetAbility(), self:GetCaster())
	end
end

modifier_azrael_move = class({})

function modifier_azrael_move:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	if IsServer() then
		self.target = self:GetAbility():GetCursorTarget()
		self.speed = 100

		self:StartIntervalThink(FrameTime())
		if self:ApplyHorizontalMotionController() == false then
            self:Destroy()
        end
	end
end

function modifier_azrael_move:IsHidden() return true end
function modifier_azrael_move:IsDebuff() return false end
function modifier_azrael_move:RemoveOnDeath() return true end
function modifier_azrael_move:GetPriority() return MODIFIER_PRIORITY_HIGH end

function modifier_azrael_move:CheckState()
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
function modifier_azrael_move:OnRefresh()
    self:OnCreated()
end
function modifier_azrael_move:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end
function modifier_azrael_move:UpdateHorizontalMotion(me, dt)
    local UFilter = UnitFilter( self.target,
                                self.ability:GetAbilityTargetTeam(),
                                self.ability:GetAbilityTargetType(),
                                self.ability:GetAbilityTargetFlags(),
                                self.parent:GetTeamNumber() )

    if UFilter ~= UF_SUCCESS then
        self:Destroy()

        return nil
    end

    if (self.target:GetOrigin() - self.parent:GetOrigin()):Length2D() < 300 then
        return nil
    end

    self:Rush(me, dt)
end
function modifier_azrael_move:Rush(me, dt)
    local pos = self.parent:GetOrigin()
    local targetpos = self.target:GetOrigin()

    local direction = targetpos - pos
    direction.z = 0     
    local target = pos + direction:Normalized() * (self.speed * dt)

    self.parent:FaceTowards(target)
    self.parent:SetOrigin(target)
end
function modifier_azrael_move:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end

modifier_azrael_stun = class({})
function modifier_azrael_stun:IsHidden() return false end
function modifier_azrael_stun:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true}
end

function modifier_azrael_stun:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

modifier_azrael_particle = class({})

function modifier_azrael_particle:OnCreated()
	self.ParticleDummy = CreateUnitByName("dummy_unit", self:GetParent():GetAbsOrigin(), false, self:GetParent(), self:GetParent(), self:GetParent():GetTeamNumber())
	self.ParticleDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	self.Particle = ParticleManager:CreateParticle("particles/kinghassan/khsn_shadow.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self.ParticleDummy)
    ParticleManager:SetParticleControl(self.Particle, 1, self.ParticleDummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.Particle, 2, self.ParticleDummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.Particle, 3, self.ParticleDummy:GetAbsOrigin() + Vector(20, 4, 205))
    ParticleManager:SetParticleControl(self.Particle, 4, self.ParticleDummy:GetAbsOrigin())
    self:StartIntervalThink(0.033)
end
function modifier_azrael_particle:OnIntervalThink()
	self.ParticleDummy:SetAbsOrigin(self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(self.Particle, 1, self.ParticleDummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.Particle, 2, self.ParticleDummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.Particle, 3, self.ParticleDummy:GetAbsOrigin() + Vector(20, 4, 205))
    ParticleManager:SetParticleControl(self.Particle, 4, self.ParticleDummy:GetAbsOrigin())
end
function modifier_azrael_particle:OnDestroy()
	ParticleManager:DestroyParticle(self.Particle, true)
	ParticleManager:ReleaseParticleIndex(self.Particle)
	self.ParticleDummy:RemoveSelf()
end