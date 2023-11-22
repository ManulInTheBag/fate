modifier_lu_bu_relentless_assault_three = class({})
LinkLuaModifier( "modifier_lu_bu_relentless_assault_three_root", "abilities/lu_bu/modifiers/modifier_lu_bu_relentless_assault_three_root", LUA_MODIFIER_MOTION_NONE )
--------------------------------------------------------------------------------
-- Classifications
function modifier_lu_bu_relentless_assault_three:IsHidden()
	return false
end

function modifier_lu_bu_relentless_assault_three:IsDebuff()
	return false
end

function modifier_lu_bu_relentless_assault_three:IsPurgable()
	return false
end

function modifier_lu_bu_relentless_assault_three:DestroyOnExpire()
	return false
end
--------------------------------------------------------------------------------
-- Initializations
function modifier_lu_bu_relentless_assault_three:OnCreated( kv )
	-- references
	self.tick = self:GetAbility():GetSpecialValueFor( "blade_fury_damage_tick" ) -- special value
	self.radius = self:GetAbility():GetSpecialValueFor( "blade_fury_radius" ) -- special value
	self.dps = self:GetAbility():GetSpecialValueFor( "blade_fury_damage" ) -- special value
	
	self.max_count = kv.duration/self.tick
	self.count = 0

	-- Start interval
	if IsServer() then
		-- precache damagetable
		self.damageTable = {
			-- victim = target,
			attacker = self:GetParent(),
			damage = self.dps * self.tick,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility(), --Optional.
		}

		self:StartIntervalThink( self.tick )
	end

	-- PlayEffects
	self:PlayEffects()
end

function modifier_lu_bu_relentless_assault_three:OnRefresh( kv )
	-- references
	self.tick = self:GetAbility():GetSpecialValueFor( "blade_fury_damage_tick" ) -- special value
	self.radius = self:GetAbility():GetSpecialValueFor( "blade_fury_radius" ) -- special value
	self.dps = self:GetAbility():GetSpecialValueFor( "blade_fury_damage" ) -- special value
	self.count = 0

	if IsServer() then
		self.damageTable.damage = self.dps * self.tick
	end
end

function modifier_lu_bu_relentless_assault_three:OnDestroy( kv )
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_lu_bu_relentless_assault_three:CheckState()
	local state = {
		--[MODIFIER_STATE_ROOTED] = false, 
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		--[MODIFIER_STATE_MUTED] = false,
	}

	return state
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_lu_bu_relentless_assault_three:OnIntervalThink()
	-- Find enemies in radius
	
	local caster = self:GetCaster()
	
	caster:EmitSound("relentless_assault_three")
	
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		self:GetParent():GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	-- damage enemies
	for _,enemy in pairs(enemies) do
		self.damageTable.victim = enemy
		ApplyDamage( self.damageTable )

		-- Play effects
		self:PlayEffects2( enemy )
	end

	-- counter
	self.count = self.count+1
	if self.count>= self.max_count then
		self:Destroy()
	end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_lu_bu_relentless_assault_three:PlayEffects()
		-- Get Resources
	local particle_cast = "particles/custom/lu_bu/assault_three_spin.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControl( effect_cast, 5, Vector( self.radius, 0, 0 ) )
	
	local sound_cast = "relentless_assault_three"

	-- buff particle
	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false
	)

	-- Emit sound
	EmitSoundOn( sound_cast, self:GetParent() )
end

function modifier_lu_bu_relentless_assault_three:PlayEffects2( target )
	local particle_cast = "particles/custom/lu_bu/assault_three_spin_target.vpcf"
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:ReleaseParticleIndex( effect_cast )
end
