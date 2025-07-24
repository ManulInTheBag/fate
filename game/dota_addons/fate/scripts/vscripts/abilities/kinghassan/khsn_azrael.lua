--1.630 3.250 1.380 2.210 (1.370 hit maybe) bell 2.040
LinkLuaModifier("modifier_khsn_azrael", "abilities/kinghassan/khsn_azrael", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_death_door", "abilities/kinghassan/khsn_azrael", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_death_door_pepeg", "abilities/kinghassan/khsn_azrael", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_azrael_move", "abilities/kinghassan/khsn_azrael", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_azrael_stun", "abilities/kinghassan/khsn_azrael", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_azrael_particle", "abilities/kinghassan/khsn_azrael", LUA_MODIFIER_MOTION_NONE)

khsn_azrael = class({})

function khsn_azrael:GetIntrinsicModifierName() return "modifier_khsn_azrael" end 

function khsn_azrael:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("khsn_mde"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("khsn_mde"):SetLevel(self:GetLevel())
    end
end

function khsn_azrael:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if IsSpellBlocked(target) then return end
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.zlodemon == true     then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_kh_r" })
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)

	caster:AddNewModifier(caster, self, "modifier_azrael_stun", {duration = 1.37})
	caster:AddNewModifier(caster, self, "modifier_azrael_particle", {duration = 1.37})

	local damage = self:GetSpecialValueFor("damage")
	local modifier_damage = 0
	local modifier_death = target:FindModifierByName("modifier_death_door")

	local flag = DOTA_DAMAGE_FLAG_NONE
	
	if modifier_death then
		modifier_damage = modifier_death.received_damage
	end
		
	if target and not target:IsNull() and target:IsAlive() then
		local certain_execute = false

		--[[if target:GetHealth() < self:GetSpecialValueFor("health_threshold")/100*target:GetMaxHealth() then
			certain_execute = true
		end]]
		
		local light_index = ParticleManager:CreateParticle("particles/kinghassan/khsn_domus_ray.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:SetParticleControl( light_index, 0, target:GetAbsOrigin())
		ParticleManager:SetParticleControl( light_index, 7, target:GetAbsOrigin())
		
		EmitGlobalSound("azrael_finish")
		
		StartAnimation(caster, {duration=2.21, activity=ACT_DOTA_CAST_ABILITY_4_END, rate=1.0})
		
		Timers:CreateTimer(1.370, function()
			if target and not target:IsNull() and target:IsAlive() then
				if not target:IsMagicImmune() then
					DoDamage(caster, target, damage + modifier_damage, DAMAGE_TYPE_MAGICAL, flag, self, false)
				end
			
				--[[if not target:IsMagicImmune() then
					DoDamage(caster, target, modifier_damage, caster.AzraelAcquired and DAMAGE_TYPE_PURE or DAMAGE_TYPE_MAGICAL, flag, self, false)
				end]]
			
				target:RemoveModifierByName("modifier_death_door")
				caster:RemoveModifierByName("jump_pause_nosilence")
				
				local targetpos = target:GetAbsOrigin() + target:GetForwardVector()*300
				FindClearSpaceForUnit(caster, targetpos, true)
            	caster:FaceTowards(target:GetAbsOrigin())
				
				local slashFx = ParticleManager:CreateParticle("particles/kinghassan/khsn_feathers.vpcf", PATTACH_ABSORIGIN, target )
				ParticleManager:SetParticleControl( slashFx, 0, target:GetAbsOrigin() + Vector(0,0,300))

				Timers:CreateTimer( 2.0, function()
					ParticleManager:DestroyParticle( slashFx, false )
					ParticleManager:ReleaseParticleIndex( slashFx )
				end)
			
				EmitGlobalSound("azrael_bell")
				Timers:CreateTimer(2.0, function()
					EmitGlobalSound("azrael_bell")
				end)
				Timers:CreateTimer(4.0, function()
					EmitGlobalSound("azrael_bell")
				end)
			
				if (target:GetHealth() < self:GetSpecialValueFor("health_threshold")/100*target:GetMaxHealth()) then
					target:Execute(self, caster, { bExecution = true })
				end
				if target:IsAlive() then
					caster:RemoveModifierByName("modifier_khsn_mde_active")
				end
			else
				caster:RemoveModifierByName("jump_pause_nosilence")
				caster:RemoveModifierByName("modifier_azrael_particle")
				--[[if caster.AzraelAcquired then
					self:EndCooldown()
					caster:GiveMana(800)
				end]]
			end
		end)
	else
		caster:RemoveModifierByName("jump_pause_nosilence")
		caster:RemoveModifierByName("modifier_azrael_particle")
	end
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
																			damage = args.damage})
end

modifier_death_door = class({})

function modifier_death_door:IsHidden() return false end
function modifier_death_door:IsDebuff() return true end
function modifier_death_door:RemoveOnDeath() return true end
function modifier_death_door:DeclareFunctions()
	return {	--MODIFIER_EVENT_ON_TAKEDAMAGE,
				--MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
			}
end

--[[function modifier_death_door:GetModifierTotalDamageOutgoing_Percentage()
	if(self:GetCaster().PresenceAcquired == true) then
		return -self:GetAbility():GetSpecialValueFor("damage_reduction")
	else return 0
	end
end]]

function modifier_death_door:OnCreated(kappa)
	if not IsServer() then return end

	self.parent = self:GetParent()
	self.ability = self:GetAbility()

	self.mult = self.ability:GetSpecialValueFor("dmg_percent")
	self.threshold = self.ability:GetSpecialValueFor("health_threshold")
	self.max_store = self.ability:GetSpecialValueFor("maximum_stored")

	self.received_damage = kappa.damage*self.mult/100

	self.fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_azrael_skull/khsn_death_door_overhead_dynamic.vpcf", PATTACH_OVERHEAD_FOLLOW, self.parent)
	ParticleManager:SetParticleControl(self.fx, 1, Vector(0, 0, 0)) --x enables particle (radius), y 0 == base skull 1 == exploding skull (seq), z == shaking strength (0 stop, 1 do)
	ParticleManager:SetParticleControl(self.fx, 2, Vector(0, 0, 0)) --color, 0 240 0 green 240 0 0 red

	self:AddParticle(self.fx, false, false, -1, false, false)

	self:StartIntervalThink(FrameTime())
end

function modifier_death_door:OnRefresh()
end

function modifier_death_door:OnIntervalThink()
	if not IsServer() then return end

	local execute_check = self.threshold/100*self.parent:GetMaxHealth()
	local health_check = CalculateDamagePostReduction(DAMAGE_TYPE_MAGICAL, self.received_damage, self.parent) + execute_check

	if self.parent:GetHealth() < execute_check then
		ParticleManager:SetParticleControl(self.fx, 1, Vector(1, 1, 1))
		ParticleManager:SetParticleControl(self.fx, 2, Vector(240, 0, 0))
	elseif self.parent:GetHealth() < health_check then
		ParticleManager:SetParticleControl(self.fx, 1, Vector(1, 0, 0))
		ParticleManager:SetParticleControl(self.fx, 2, Vector(0, 240, 0))
	else
		ParticleManager:SetParticleControl(self.fx, 1, Vector(0, 0, 0))
		ParticleManager:SetParticleControl(self.fx, 2, Vector(0, 0, 0))
	end
end

function modifier_death_door:OnTakeDamage(args)
	if args.unit ~= self.parent then return end
	if args.attacker ~= self:GetCaster() then return end

	self.max_store = self.ability:GetSpecialValueFor("maximum_stored") --refresh in case of in-fight level up

	self.received_damage = self.received_damage + args.damage*self.mult/100
	
	if self.max_store < self.received_damage then
		self.received_damage = self.max_store
	end
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
	self.received_damage = kappa.damage
	if IsServer() then
		self:StartIntervalThink(FrameTime())
	end
end
function modifier_death_door_pepeg:OnTakeDamage(args)
	if args.unit ~= self.parent then return end
	if args.attacker ~= self:GetCaster() then return end

	self.received_damage = self.received_damage + args.damage
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
	if not IsServer() then return nil end
	self.ParticleDummy = self:GetParent()--CreateUnitByName("dummy_unit", self:GetParent():GetAbsOrigin(), false, nil, nil, self:GetParent():GetTeamNumber())
	--self.ParticleDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	self.Particle = ParticleManager:CreateParticle("particles/kinghassan/khsn_shadow.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self.ParticleDummy)
    ParticleManager:SetParticleControl(self.Particle, 1, self.ParticleDummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.Particle, 2, self.ParticleDummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.Particle, 3, self.ParticleDummy:GetAbsOrigin() + Vector(20, 4, 205))
    ParticleManager:SetParticleControl(self.Particle, 4, self.ParticleDummy:GetAbsOrigin())
    self:StartIntervalThink(0.033)
end
function modifier_azrael_particle:OnIntervalThink()
	if not IsServer() then return nil end
	self.ParticleDummy:SetAbsOrigin(self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(self.Particle, 1, self.ParticleDummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.Particle, 2, self.ParticleDummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.Particle, 3, self.ParticleDummy:GetAbsOrigin() + Vector(20, 4, 205))
    ParticleManager:SetParticleControl(self.Particle, 4, self.ParticleDummy:GetAbsOrigin())
end
function modifier_azrael_particle:OnDestroy()
	if type(self.Particle) == "number" then
		ParticleManager:DestroyParticle(self.Particle, false)
		ParticleManager:ReleaseParticleIndex(self.Particle)
		--self.ParticleDummy:RemoveSelf()

		self.Particle = nil
	end
end