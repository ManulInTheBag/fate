-----------------------------
--    Modifier: Multishot    --
-----------------------------

modifier_robin_multishot = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_robin_multishot:IsHidden()
	return false
end

function modifier_robin_multishot:IsDebuff()
	return false
end

function modifier_robin_multishot:IsStunDebuff()
	return false
end

function modifier_robin_multishot:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_robin_multishot:OnCreated( kv )
	-- references
	local count = self:GetAbility():GetSpecialValueFor( "arrow_count" )
	local range = self:GetAbility():GetSpecialValueFor( "arrow_range" )
	local width = 200
	self.speed = 3000--self:GetAbility():GetSpecialValueFor( "arrow_speed" )
	-- self.angle = self:GetAbility():GetSpecialValueFor( "arrow_angle" )
	self.angle = 33

	if not IsServer() then return end

	-- none provided in kv file. shame on you volvo
	local vision = 100
	local delay = 0.1
	local wave = 1
	local wave_interval = 0.55
	self.arrow_delay = 0.033

	-- calculate stuff
	self.arrows = 12
	self.wave_delay = 0.033

	-- get projectile main direction
	local point = Vector(kv.x, kv.y, kv.z)
	self.direction = point-self:GetCaster():GetOrigin()
	self.direction.z = 0
	self.direction = self.direction:Normalized()

	-- set states
	self.state = STATE_SALVO
	self.current_arrows = 0
	self.current_wave = 0
	self.frost = false

	-- precache projectile
	local caster = self:GetCaster()
	local projectile_name = "particles/custom/robin/robin_multishot_arrow.vpcf"

	self.info = {
		Source = caster,
		Ability = self:GetAbility(),
		vSpawnOrigin = caster:GetAttachmentOrigin( caster:ScriptLookupAttachment( "attach_attack1" ) ),
		
	    bDeleteOnHit = true,
	    
	    iUnitTargetTeam = self:GetAbility():GetAbilityTargetTeam(),
	    iUnitTargetType = self:GetAbility():GetAbilityTargetType(),
	    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,

	    EffectName = projectile_name,
	    fDistance = range,
	    fStartRadius = width,
	    fEndRadius = width,
		bHasFrontalCone = false,
		bVisibleToEnemies = true,
		bReplaceExisting = false,
		fExpireTime = GameRules:GetGameTime() + 10.0,
		-- vVelocity = projectile_direction * self.speed,
	
		bProvidesVision = true,
		iVisionRadius = vision,
		iVisionTeamNumber = caster:GetTeamNumber()
	}
	-- ProjectileManager:CreateLinearProjectile(info)

	-- Start interval
	self:StartIntervalThink( delay )

	-- play effects
	local sound_cast = "Hero_DrowRanger.Multishot.Channel"
	EmitSoundOn( sound_cast, caster )
end

function modifier_robin_multishot:OnRefresh( kv )
end

function modifier_robin_multishot:OnRemoved()
end

function modifier_robin_multishot:OnDestroy()
	if not IsServer() then return end

	-- stop effects
	local sound_cast = "Hero_DrowRanger.Multishot.Channel"
	StopSoundOn( sound_cast, self:GetCaster() )
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_robin_multishot:OnIntervalThink()
	if self.current_arrows > 12 then
	return end
	-- count arrows
	if self.current_arrows<self.arrows then

		self:StartIntervalThink( self.arrow_delay )
	else
	return
	end

	-- calculate relative angle of current arrow against cast direction
	local step = self.angle/(self.arrows-1)
	local angle = -self.angle/2 + self.current_arrows*step

	-- calculate actual direction
	local projectile_direction = RotatePosition( Vector(0,0,0), QAngle( 0, angle, 0 ), self.direction )

	-- launch projectile
	self.info.vVelocity = projectile_direction * self.speed
	self.info.ExtraData = {
		arrow = self.current_arrows,
		wave = self.current_wave,
		frost = self.frost,
	}
	ProjectileManager:CreateLinearProjectile(self.info)

	self:PlayEffects()

	self.current_arrows = self.current_arrows+1
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_robin_multishot:PlayEffects()
	-- Get Resources
	local sound_cast

	sound_cast = "Hero_DrowRanger.Multishot.FrostArrows"

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetCaster() )
end