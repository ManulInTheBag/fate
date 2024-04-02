
--------------------------------------------------------------------------------
lu_bu_relentless_assault_two = class({})
LinkLuaModifier( "modifier_lu_bu_relentless_assault_two", "abilities/lu_bu/modifiers/modifier_lu_bu_relentless_assault_two", LUA_MODIFIER_MOTION_NONE )
--LinkLuaModifier( "modifier_lu_bu_relentless_assault_two_armor_reduction", "abilities/lu_bu/modifiers/modifier_lu_bu_relentless_assault_two_armor_reduction", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lu_bu_relentless_assault_two_knockback", "abilities/lu_bu/modifiers/modifier_lu_bu_relentless_assault_two_knockback", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier( "modifier_lu_bu_relentless_assault_two_damage_reduction", "abilities/lu_bu/lu_bu_relentless_assault_two", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function lu_bu_relentless_assault_two:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	-- load data
	local radius = self:GetSpecialValueFor("radius")
	local angle = self:GetSpecialValueFor("angle")/2
	local duration = self:GetSpecialValueFor("knockback_duration")
	--local armor_reduction_duration = self:GetSpecialValueFor("armor_reduction_duration")
	local distance = self:GetSpecialValueFor("knockback_distance")
	local damage = self:GetSpecialValueFor("damage")
	local damage_debuff_duration = self:GetSpecialValueFor("debuff_duration")
	caster:EmitSound("lu_bu_relentless_assault_one")

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

	-- precache
	local origin = caster:GetOrigin()
	local cast_direction = (point-origin):Normalized()
	cast_direction.z = 0
	local cast_angle = VectorToAngles( cast_direction ).y
	
	StartAnimation(caster, {duration = 1.0, activity=ACT_DOTA_RAZE_3, rate = 2.2})

	Timers:CreateTimer(0.1, function()
		if caster:IsAlive() then
			local caught = false
				for _,enemy in pairs(enemies) do
					-- check within cast angle
				local enemy_direction = (enemy:GetOrigin() - origin):Normalized()
				local enemy_angle = VectorToAngles( enemy_direction ).y
				local angle_diff = math.abs( AngleDiff( cast_angle, enemy_angle ) )
				if angle_diff<=angle then
				-- attack
				DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				--enemy:AddNewModifier(caster, self, "modifier_lu_bu_relentless_assault_two_armor_reduction", { Duration = armor_reduction_duration })
				enemy:AddNewModifier(caster, self, "modifier_lu_bu_relentless_assault_two_damage_reduction", { Duration = damage_debuff_duration })
				-- knockback if not having spear stun
				if not enemy:HasModifier( "modifier_lu_bu_halberd_throw_debuff" ) and not IsKnockbackImmune(enemy) then
					enemy:AddNewModifier(
						caster, -- player source
						self, -- ability source
						"modifier_lu_bu_relentless_assault_two_knockback", -- modifier name
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
			self:PlayEffects2( enemy, origin, cast_direction )
			end
		end
		end
	end)
	
	Timers:CreateTimer(0.1, function()
		if caster:IsAlive() then
			self:PlayEffects1( caught, cast_direction )
		end
	end)
	
	caster:RemoveModifierByName("modifier_assault_skillswap_2")
	caster:RemoveModifierByName("modifier_relentless_assault_blocker")
	local relentless_assault = caster:FindModifierByName("modifier_lu_bu_relentless_assault")
	relentless_assault:SetStackCount(1)
	
	Timers:CreateTimer(0.5, function()
		if caster:IsAlive() then
			local caught = false
				for _,enemy in pairs(enemies) do
					-- check within cast angle
				local enemy_direction = (enemy:GetOrigin() - origin):Normalized()
				local enemy_angle = VectorToAngles( enemy_direction ).y
				local angle_diff = math.abs( AngleDiff( cast_angle, enemy_angle ) )
				if angle_diff<=angle then
				-- attack
				DoDamage(caster, enemy, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)

				-- knockback if not having spear stun
				if not enemy:HasModifier( "modifier_lu_bu_halberd_throw_debuff" ) and not IsKnockbackImmune(enemy) then
					enemy:AddNewModifier(
						caster, -- player source
						self, -- ability source
						"modifier_lu_bu_relentless_assault_two_knockback", -- modifier name
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
			self:PlayEffects2( enemy, origin, cast_direction )
			end
		end
		end
	end)
	
	Timers:CreateTimer(0.5, function()
		if caster:IsAlive() then
			self:PlayEffects1( caught, cast_direction )
		end
	end)

	-- play effects
end

--------------------------------------------------------------------------------
-- Play Effects
function lu_bu_relentless_assault_two:PlayEffects1( caught, direction )
	-- Get Resources
	local particle_cast = "particles/custom/lu_bu/assault_two_normal.vpcf"
	local sound_cast = "relentless_assault_two"
	if not caught then
		local sound_cast = "relentless_assault_two"
	end

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	--ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
	ParticleManager:SetParticleControlTransformForward( effect_cast, 0, self:GetCaster():GetOrigin(), direction )
	ParticleManager:ReleaseParticleIndex( effect_cast )
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( effect_cast, false )
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end)

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast, self:GetCaster() )
end

function lu_bu_relentless_assault_two:PlayEffects2( target, origin, direction )
	-- Get Resources
	local particle_cast = "particles/custom/lu_bu/assault_two_crit.vpcf"
	local sound_cast = "relentless_assault_two"

	-- Create Particle
	local effect_cast2 = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, target )
	ParticleManager:SetParticleControl( effect_cast2, 0, target:GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast2, 1, target:GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast2, 1, direction )
	ParticleManager:ReleaseParticleIndex( effect_cast2 )
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( effect_cast2, false )
		ParticleManager:ReleaseParticleIndex( effect_cast2 )
	end)

	-- Create Sound
	EmitSoundOn( sound_cast, target )
end



modifier_lu_bu_relentless_assault_two_damage_reduction = modifier_lu_bu_relentless_assault_two_damage_reduction or class({})

function modifier_lu_bu_relentless_assault_two_damage_reduction:IsHidden()                                                                     return false end
function modifier_lu_bu_relentless_assault_two_damage_reduction:IsDebuff()                                                                     return true end
function modifier_lu_bu_relentless_assault_two_damage_reduction:IsPurgable()                                                                   return true end
function modifier_lu_bu_relentless_assault_two_damage_reduction:IsPurgeException()                                                             return false end
function modifier_lu_bu_relentless_assault_two_damage_reduction:RemoveOnDeath()                                                                return true end
function modifier_lu_bu_relentless_assault_two_damage_reduction:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
                    }
    return tFunc
end
function modifier_lu_bu_relentless_assault_two_damage_reduction:GetModifierTotalDamageOutgoing_Percentage(keys)
    if IsNotNull(self.hCaster)
        and IsNotNull(self.hParent) then
        if IsClient() or bit.band(keys.damage_type or DAMAGE_TYPE_NONE, DAMAGE_TYPE_MAGICAL) ~= 0 then
            return -self.reduction
        end
    end
end
function modifier_lu_bu_relentless_assault_two_damage_reduction:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
    self.reduction = self.hAbility:GetSpecialValueFor("magical_damage_reduction")
end
function modifier_lu_bu_relentless_assault_two_damage_reduction:OnRefresh(tTable)
    self:OnCreated(tTable)
end
