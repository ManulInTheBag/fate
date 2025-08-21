
--------------------------------------------------------------------------------
scathach_gait_one = class({})

LinkLuaModifier( "modifier_scathach_gait_one_knockback", "abilities/scathach/modifiers/modifier_scathach_gait_one_knockback", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier( "modifier_scathach_gait_two_window", "abilities/scathach/modifiers/modifier_scathach_gait_two_window", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier("modifier_stachach_gae_bolg_curse", "abilities/scathach/scathach_gae_bolg", LUA_MODIFIER_MOTION_NONE)
--------------------------------------------------------------------------------
-- Ability Start
function scathach_gait_one:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local two_point = caster:GetForwardVector()

	-- load data
	local radius = self:GetSpecialValueFor("radius")
	local angle = self:GetSpecialValueFor("angle")/2
	local duration = self:GetSpecialValueFor("knockback_duration")
	local root duration = self:GetSpecialValueFor("root_duration")
	local distance = self:GetSpecialValueFor("knockback_distance")
	local damage = self:GetSpecialValueFor("damage")
	local agi_scale = self:GetSpecialValueFor("agi_scale")
	if caster:HasModifier("modifier_scathach_primeval_rune_attribute") then
		damage = damage + caster:GetAgility() * agi_scale
	end
	
	caster:EmitSound("scathach_gait_1")

	-- find units
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),	-- int, your team number
		caster:GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)
	
	StartAnimation(caster, {duration = 1.0, activity=ACT_DOTA_CAST_ABILITY_2, rate = 1.5})

	Timers:CreateTimer(0.1, function()
		two_point = caster:GetForwardVector()
		origin = caster:GetOrigin()
		cast_direction = caster:GetForwardVector()
		cast_angle = VectorToAngles( cast_direction ).y
		
		self:PlayEffects1( caught, (two_point):Normalized() )
		if caster:IsAlive() then
			local caught = false
			caster:EmitSound("scathach_gait_attack_1")
				for _,enemy in pairs(enemies) do
					-- check within cast angle
				local enemy_direction = (enemy:GetOrigin() - origin):Normalized()
				local enemy_angle = VectorToAngles( enemy_direction ).y
				local angle_diff = math.abs( AngleDiff( cast_angle, enemy_angle ) )
				if angle_diff<=angle then
				-- attack
				DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				enemy:AddNewModifier(caster, self, "modifier_stachach_gae_bolg_curse", {duration = 10})
				-- if enemy:GetMaxMana() > 0 then
				-- 	enemy:Script_ReduceMana(50, nil)
				-- end
				--enemy:AddNewModifier(caster, self, "modifier_scathach_gait_one_armor_reduction", { Duration = armor_reduction_duration })
				if not IsKnockbackImmune(enemy) then
					enemy:AddNewModifier(
						caster, -- player source
						self, -- ability source
						"modifier_scathach_gait_one_knockback", -- modifier name
						{
							duration = duration,
							distance = distance,
							height = 30,
							direction_x = enemy_direction.x,
							direction_y = enemy_direction.y,
						} -- kv
					)
				end

			caught = true
			-- play effects
			--self:PlayEffects2( enemy, origin, cast_direction )
			end
		end
		end
	end)
	
	Timers:CreateTimer(0.5, function()
		two_point = caster:GetForwardVector()
		origin = caster:GetOrigin()
		cast_direction = caster:GetForwardVector()
		cast_angle = VectorToAngles( cast_direction ).y
		
		self:PlayEffects3( caught, (two_point):Normalized() )
		if caster:IsAlive() then
			local caught = false
			caster:EmitSound("scathach_gait_attack_2")
				for _,enemy in pairs(enemies) do
					-- check within cast angle
				local enemy_direction = (enemy:GetOrigin() - origin):Normalized()
				local enemy_angle = VectorToAngles( enemy_direction ).y
				local angle_diff = math.abs( AngleDiff( cast_angle, enemy_angle ) )
				if angle_diff<=angle then
				-- attack
				DoDamage(caster, enemy, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
				enemy:AddNewModifier(caster, self, "modifier_stachach_gae_bolg_curse", {duration = 10})
				enemy:AddNewModifier(caster, self, "modifier_rooted", {duration = self:GetSpecialValueFor("root_duration")})
				-- if enemy:GetMaxMana() > 0 then
				-- 	enemy:Script_ReduceMana(50, nil)
				-- end
				if not IsKnockbackImmune(enemy) then
					enemy:AddNewModifier(
						caster, -- player source
						self, -- ability source
						"modifier_scathach_gait_one_knockback", -- modifier name
						{
							duration = duration,
							distance = distance,
							height = 30,
							direction_x = enemy_direction.x,
							direction_y = enemy_direction.y,
						} -- kv
					)
				end

			caught = true
			-- play effects
			--self:PlayEffects2( enemy, origin, cast_direction )
			end
		end
		end
	end)
	
	Timers:CreateTimer(0.5, function()
		if caster:IsAlive() then
			
			caster:AddNewModifier(caster, self, "modifier_scathach_gait_two_window", { Duration = self:GetSpecialValueFor("activity_duration") })
		end
	end)

	-- play effects
end

--------------------------------------------------------------------------------
-- Play Effects
function scathach_gait_one:PlayEffects1( caught, direction )
	-- Get Resources
	local particle_cast = "particles/custom/scathach/scathach_gait_one.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast, 0, direction )
	--ParticleManager:ReleaseParticleIndex( effect_cast )
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( effect_cast, false )
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end)

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast, self:GetCaster() )
end

function scathach_gait_one:PlayEffects2( target, origin, direction )
	-- Get Resources
	local particle_cast = "particles/custom/lu_bu/assault_two_crit.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( effect_cast, 0, target:GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 1, target:GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast, 1, direction )
	--ParticleManager:ReleaseParticleIndex( effect_cast )
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( effect_cast, false )
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end)

	-- Create Sound
	EmitSoundOn( sound_cast, target )
end

function scathach_gait_one:PlayEffects3( caught, direction )
	-- Get Resources
	local particle_cast = "particles/custom/scathach/scathach_gait_one_second_swing.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast, 0, direction )
	--ParticleManager:ReleaseParticleIndex( effect_cast )
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( effect_cast, false )
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end)

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast, self:GetCaster() )
end

function scathach_gait_one:OnUpgrade()
    local scathach_gait_two = self:GetCaster():FindAbilityByName("scathach_gait_two")
	local scathach_gait_three = self:GetCaster():FindAbilityByName("scathach_gait_three")
	
    scathach_gait_two:SetLevel(self:GetLevel())
	scathach_gait_three:SetLevel(self:GetLevel())
end