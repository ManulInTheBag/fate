LinkLuaModifier("modifier_medusa_breaker_not_facing","abilities/medusa/medusa_breaker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_medusa_breaker_facing","abilities/medusa/medusa_breaker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_medusa_breaker_facing_stack","abilities/medusa/medusa_breaker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_medusa_breaker_window","abilities/medusa/medusa_breaker", LUA_MODIFIER_MOTION_NONE)

medusa_breaker = class({})

function medusa_breaker:OnAbilityPhaseStart()
    self:GetCaster():EmitSound("medusa_breaker_"..math.random(1,3))
    return true
end

function medusa_breaker:OnAbilityPhaseInterrupted()
    self:GetCaster():StopSound("medusa_breaker_1")
    self:GetCaster():StopSound("medusa_breaker_2")
    self:GetCaster():StopSound("medusa_breaker_3")
end

function medusa_breaker:OnSpellStart()
	local caster = self:GetCaster()
	local caster_loc = caster:GetAbsOrigin()
	local dir = (Vector(self:GetCursorPosition().x, self:GetCursorPosition().y, 0) - Vector(caster_loc.x, caster_loc.y, 0)):Normalized()
	caster:SetForwardVector(dir)
	local caster_dir = caster:GetForwardVector()
	local radius = self:GetSpecialValueFor("radius")
	local angle = self:GetSpecialValueFor("angle")

	local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        radius,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_NONE,
                                        FIND_ANY_ORDER,
                                        false)

	local cast_angle = VectorToAngles( caster_dir ).y

	local casted = false

	EmitSoundOn("medusa_magic1", self:GetCaster())

	for _,enemy in pairs(enemies) do
		local enemy_direction = (enemy:GetAbsOrigin() - caster_loc):Normalized()
		local enemy_angle = VectorToAngles( enemy_direction ).y
		local angle_diff = math.abs( AngleDiff( cast_angle, enemy_angle ) )
		if angle_diff<=angle/2 then
			if not IsFacingUnit(enemy, caster, 180) then
				enemy:AddNewModifier(caster, self, "modifier_medusa_breaker_not_facing", {duration = self:GetSpecialValueFor("slow_duration")})
			else
				if not enemy:HasModifier("modifier_medusa_breaker_facing_stack") then
					local modifier = enemy:AddNewModifier(caster, self, "modifier_medusa_breaker_facing_stack", {duration = self:GetSpecialValueFor("slow_duration")})
					modifier:IncrementStackCount()
					if casted == false then
						casted = true
						caster:AddNewModifier(caster, self, "modifier_medusa_breaker_window", {duration = self:GetSpecialValueFor("window_duration")})
					end
				elseif not enemy:HasModifier("modifier_medusa_breaker_facing") then
					local modifier = enemy:FindModifierByName("modifier_medusa_breaker_facing_stack")
					modifier:IncrementStackCount()
					if modifier:GetStackCount() >= self:GetSpecialValueFor("stack_count") then
						enemy:RemoveModifierByName("modifier_medusa_breaker_facing_stack")
						enemy:AddNewModifier(caster, self, "modifier_medusa_breaker_facing", {duration = self:GetSpecialValueFor("stun_duration")})
						if caster:GetAbilityByIndex(4):GetName() == "medusa_monstrous_strength" and caster.GorgonRushAcquired then
							caster:SwapAbilities("medusa_monstrous_strength", "medusa_gorgon_rush", false, true)
							Timers:CreateTimer("medusa_rush_window", {
								endTime = 2,
								callback = function()
								caster:SwapAbilities("medusa_monstrous_strength", "medusa_gorgon_rush", true, false)
							return end
							})
						elseif caster:GetAbilityByIndex(4):GetName() == "medusa_gorgon_rush" and caster.GorgonRushAcquired then
							Timers:RemoveTimer("medusa_rush_window")
							Timers:CreateTimer("medusa_rush_window", {
								endTime = 2,
								callback = function()
								caster:SwapAbilities("medusa_monstrous_strength", "medusa_gorgon_rush", true, false)
							return end
							})
						end
					end
				end
			end
		end
	end

	local eye_particle1 = ParticleManager:CreateParticle("particles/medusa/medusa_breaker_eye.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(eye_particle1, 1, caster, PATTACH_POINT_FOLLOW, "attach_righteye", Vector(0,0,0), true)
	local eye_particle2 = ParticleManager:CreateParticle("particles/medusa/medusa_breaker_eye.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(eye_particle2, 1, caster, PATTACH_POINT_FOLLOW, "attach_lefteye", Vector(0,0,0), true)

	local effect_cast = ParticleManager:CreateParticle( "particles/medusa/medusa_breaker_cone.vpcf", PATTACH_WORLDORIGIN, caster )
	ParticleManager:SetParticleControl( effect_cast, 0, caster_loc )
	ParticleManager:SetParticleControlForward( effect_cast, 0, caster_dir )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	Timers:CreateTimer(0.3, function()
		ParticleManager:DestroyParticle(eye_particle1, false)
		ParticleManager:ReleaseParticleIndex(eye_particle1)
		ParticleManager:DestroyParticle(eye_particle2, false)
		ParticleManager:ReleaseParticleIndex(eye_particle2)
	end)

	--caster:AddNewModifier(caster, self, "modifier_medusa_breaker_gorgon_caster", {duration = 2})
end

modifier_medusa_breaker_not_facing = class({})

function modifier_medusa_breaker_not_facing:IsHidden() return false end
function modifier_medusa_breaker_not_facing:IsDebuff() return true end
function modifier_medusa_breaker_not_facing:IsPurgable() return false end
function modifier_medusa_breaker_not_facing:IsPurgeException() return false end
function modifier_medusa_breaker_not_facing:RemoveOnDeath() return true end

function modifier_medusa_breaker_not_facing:DeclareFunctions()
	return { MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
				}
end

function modifier_medusa_breaker_not_facing:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("ms_slow")
end

function modifier_medusa_breaker_not_facing:GetModifierTurnRate_Percentage()
	return -1*self:GetAbility():GetSpecialValueFor("turn_rate")
end

function modifier_medusa_breaker_not_facing:OnCreated()
	local particle_cast = "particles/units/heroes/hero_medusa/medusa_stone_gaze_debuff_stoned.vpcf"
	local sound_cast = "Hero_Medusa.StoneGaze.Stun"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		self.center_unit,
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		Vector( 0,0,0 ), -- unknown
		true -- unknown, true
	)

	-- buff particle
	self:AddParticle(
		effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)
end

modifier_medusa_breaker_facing_stack = class({})

function modifier_medusa_breaker_facing_stack:IsHidden() return false end
function modifier_medusa_breaker_facing_stack:IsDebuff() return true end
function modifier_medusa_breaker_facing_stack:IsPurgable() return false end
function modifier_medusa_breaker_facing_stack:IsPurgeException() return false end
function modifier_medusa_breaker_facing_stack:RemoveOnDeath() return true end

function modifier_medusa_breaker_facing_stack:DeclareFunctions()
	return { MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
				}
end

function modifier_medusa_breaker_facing_stack:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("ms_slow")
end

function modifier_medusa_breaker_facing_stack:GetModifierTurnRate_Percentage()
	return -1*self:GetAbility():GetSpecialValueFor("turn_rate")
end

function modifier_medusa_breaker_facing_stack:OnCreated()
	local particle_cast = "particles/units/heroes/hero_medusa/medusa_stone_gaze_debuff_stoned.vpcf"
	local sound_cast = "Hero_Medusa.StoneGaze.Stun"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		self.center_unit,
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		Vector( 0,0,0 ), -- unknown
		true -- unknown, true
	)

	-- buff particle
	self:AddParticle(
		effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)
end


modifier_medusa_breaker_facing = class({})

function modifier_medusa_breaker_facing:IsHidden() return false end
function modifier_medusa_breaker_facing:IsDebuff() return true end
function modifier_medusa_breaker_facing:IsPurgable() return false end
function modifier_medusa_breaker_facing:IsPurgeException() return false end
function modifier_medusa_breaker_facing:RemoveOnDeath() return true end

function modifier_medusa_breaker_facing:DeclareFunctions()
	return { MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
				}
end

function modifier_medusa_breaker_facing:CheckState()
    local state =   { 
                        [MODIFIER_STATE_STUNNED] = true,
                        [MODIFIER_STATE_FROZEN] = true
                    }
    return state
end

function modifier_medusa_breaker_facing:GetStatusEffectName()
	return "particles/medusa/medusa_breaker_status.vpcf"
end
function modifier_medusa_breaker_facing:StatusEffectPriority(  )
	return MODIFIER_PRIORITY_ULTRA
end

function modifier_medusa_breaker_facing:OnCreated()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_medusa/medusa_stone_gaze_debuff_stoned.vpcf"
	local sound_cast = "Hero_Medusa.StoneGaze.Stun"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		self.center_unit,
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		Vector( 0,0,0 ), -- unknown
		true -- unknown, true
	)

	-- buff particle
	self:AddParticle(
		effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)

	-- Create Sound
	--EmitSoundOnClient( sound_cast, self:GetParent():GetPlayerOwner() )
end

function modifier_medusa_breaker_facing:OnTakeDamage(args)
	if not args.unit == self:GetParent() then return end
	if args.original_damage >= self:GetAbility():GetSpecialValueFor("break_cap") then
		local caster = self:GetCaster()
		local target = args.unit
		local damage = target:GetMaxHealth()*self:GetAbility():GetSpecialValueFor("break_damage")/100
		local destroy_fx = ParticleManager:CreateParticle("particles/medusa/medusa_breaker_break.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(destroy_fx, 0, self:GetParent():GetAbsOrigin())
		Timers:CreateTimer(2, function()
			ParticleManager:DestroyParticle(destroy_fx, false)
			ParticleManager:ReleaseParticleIndex(destroy_fx)
		end)

		self:Destroy()

		DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
	end
end

modifier_medusa_breaker_window = class({})

function modifier_medusa_breaker_window:IsHidden() return false end
function modifier_medusa_breaker_window:IsDebuff() return false end
function modifier_medusa_breaker_window:IsPurgable() return false end
function modifier_medusa_breaker_window:IsPurgeException() return false end
function modifier_medusa_breaker_window:RemoveOnDeath() return true end

function modifier_medusa_breaker_window:OnCreated()
	if IsServer() then
		self.ability = self:GetAbility()
		self.ability:EndCooldown()
		self.ability:StartCooldown(1)
	end
end

function modifier_medusa_breaker_window:OnRefresh()
	self:OnCreated()
end

function modifier_medusa_breaker_window:OnDestroy()
	if IsServer() then
		if self:GetAbility():GetCooldownTimeRemaining() < 1 then
			self.ability:StartCooldown(self.ability:GetCooldown(self.ability:GetLevel() - 1))
		end
	end
end