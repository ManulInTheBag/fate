-----------------------------
--    Invisible Air    --
-----------------------------

artoria_invisible_air = class({})

LinkLuaModifier("modifier_artoria_upstream", "abilities/artoria/artoria_invisible_air", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

function artoria_invisible_air:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
    local player = caster:GetPlayerOwner()
	
	self.vStartPosition = self:GetCaster():GetOrigin()
	self.vProjectileLocation = self.vStartPosition
	
	local vDirection = self:GetCursorPosition() - self.vStartPosition
	vDirection.z = 0.0
	
	local vDirection = ( vDirection:Normalized() ) * 1500
	self.vTargetPosition = self.vStartPosition + vDirection
	
	caster:EmitSound("artoria_invisible_air")
	
	if IsValidEntity(player) and not player:IsNull() then
        if  not caster:CanEntityBeSeenByMyTeam(target) or caster:GetRangeToUnit(target) > 1500  or not IsInSameRealm(caster:GetAbsOrigin(), target:GetAbsOrigin()) then 
            Say(player, "Invisible Air Failed.", true)
            return
        end
    end

	self.invisible_air_reach_target = false
	
	local tProjectile = {
        Target = target,
        Source = caster,
        Ability = self,
        EffectName = "",
        iMoveSpeed = 1200,
        vSourceLoc = caster:GetAbsOrigin(),
        level = 3,
        bDodgeable = true,
        bIsAttack = true,
        flExpireTime = GameRules:GetGameTime() + 10,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
    }
	
    FATE_ProjectileManager:CreateTrackingProjectile(tProjectile)
	self.bRetracting = false
	self.hVictim = nil
	self.bDiedInInvisibleAir = false
	
	local movespeed = 1200
	
	local particleName = "particles/custom/saber/saber_invisible_air.vpcf"
	local fxIndex = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( fxIndex, 3, caster:GetAbsOrigin() )
	
	local dist = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
	
	caster:EmitSound("Ability.Focusfire")
	
	if dist > 250 then 
		caster.invisible_air_pos = caster:GetAbsOrigin() + (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized() * 150
	else
		caster.invisible_air_pos = caster:GetAbsOrigin() + (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized() * dist * 0.6
	end
	
	local invisAirCounter = 0
	Timers:CreateTimer( function() 
			-- If over 3 seconds
			if invisAirCounter > 1.5 then
				ParticleManager:DestroyParticle( fxIndex, false )
				ParticleManager:ReleaseParticleIndex( fxIndex )
				return
			end
				
			local forwardVec = ( target:GetAbsOrigin() - caster.invisible_air_pos ):Normalized()
				
			caster.invisible_air_pos = caster.invisible_air_pos + forwardVec * movespeed * FrameTime()
				
			ParticleManager:SetParticleControl( fxIndex, 3, caster.invisible_air_pos )
			
			-- Reach first
			if self.invisible_air_reach_target then
				ParticleManager:DestroyParticle( fxIndex, false )
				ParticleManager:ReleaseParticleIndex( fxIndex )
				return nil
			else
				invisAirCounter = invisAirCounter + FrameTime()
				return FrameTime()
			end
		end
	)
end

function artoria_invisible_air:OnProjectileHit_ExtraData(target, vLocation, tData)
	if target == nil then return end
	
	local caster = self:GetCaster()

	self.invisible_air_reach_target = true

	damage = self:GetSpecialValueFor( "damage" )  
	wind_speed = self:GetSpecialValueFor( "wind_speed" )

	vision_radius = self:GetSpecialValueFor( "vision_radius" )  
	vision_duration = self:GetSpecialValueFor( "vision_duration" )

    if target == nil then
        return 
    end

	
	if IsSpellBlocked(target) -- Linken's
		or target:IsMagicImmune() -- Magic immunity
		or target:HasModifier("modifier_wind_protection_passive") 
		or (target:GetAbsOrigin() - self.vProjectileLocation):Length2D() > (self:GetSpecialValueFor("range") + 100)
	then
		return
	end

    if self.bRetracting == false then
		if target ~= nil and ( not ( target:IsCreep() or target:IsConsideredHero() ) ) then
			Msg( "Target was invalid")
			return false
		end

		local bTargetPulled = false
		if target ~= nil then

			--target:AddNewModifier( caster, self, "modifier_stunned", {Duration = 1} )
			
			if target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
				--ScreenShake(target:GetOrigin(), 5, 1.0, 2, 3000, 0, true)
				
				local stacks = 1
				
				caster = self:GetCaster()
				
				if caster:HasModifier("modifier_artoria_strike_air_attribute") then
					damage = damage + 75
					caster:AddNewModifier( caster, self, "modifier_artoria_upstream", {Duration = 5} )
				end
				
				DoDamage(caster, target , damage , DAMAGE_TYPE_MAGICAL, 0, self, false)

				if not target:IsMagicImmune() then
					target:Interrupt()
				end
			end
			
			if not target:HasModifier("modifier_wind_protection_passive") and not IsKnockbackImmune(target) then
				local caster_position = self.vStartPosition
				local target_position = target:GetAbsOrigin()
				
				local pull_target = Physics:Unit(target)
				local distance = (caster_position - target_position):Length2D()
				target:PreventDI()
				target:SetPhysicsFriction(0)
				target:SetPhysicsVelocity((caster_position - target_position):Normalized() * distance * 2.2)
				target:SetNavCollisionType(PHYSICS_NAV_NOTHING)
				target:FollowNavMesh(true)
				target:SetAutoUnstuck(false)
			
			Timers:CreateTimer({
				endTime = 0.4,
				callback = function()
				
				target:PreventDI(false)
				target:SetPhysicsVelocity(Vector(0,0,0))
				target:OnPhysicsFrame(nil)
				FindClearSpaceForUnit(target, target:GetAbsOrigin(), true)
			end})
			
			end

			

			AddFOWViewer( self:GetCaster():GetTeamNumber(), target:GetOrigin(), vision_radius, vision_duration, false )
			self.hVictim = target
			bTargetPulled = true
		end
	end
	return true
end

modifier_artoria_upstream = class({})

function modifier_artoria_upstream:IsHidden() return true end
function modifier_artoria_upstream:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end

	local caster = self:GetParent()
	local target = args.target
	local ability = self:GetAbility()
	local damage = caster:GetAverageTrueAttackDamage(caster) * 0.3 + 75
	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	ApplyAirborne(caster, target, 1.25)
	local sound = RandomInt(1,2)
	if sound == 1 then caster:EmitSound("Saber.StrikeAir_Release1") else caster:EmitSound("Saber.StrikeAir_Release2") end
	local upstreamFx = ParticleManager:CreateParticle( "particles/custom/saber/strike_air_upstream/strike_air_upstream.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl( upstreamFx, 0, target:GetAbsOrigin() )
	self:Destroy()
end