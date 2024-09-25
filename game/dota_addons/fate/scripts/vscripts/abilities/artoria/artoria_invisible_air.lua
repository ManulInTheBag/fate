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

	if self.fxIndex then
		ParticleManager:DestroyParticle( self.fxIndex, false )
		ParticleManager:ReleaseParticleIndex( self.fxIndex )
	end
	
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
        iMoveSpeed = 1800,
        vSourceLoc = caster:GetAbsOrigin(),
        level = 3,
        bDodgeable = false,
        bIsAttack = true,
        flExpireTime = GameRules:GetGameTime() + 3,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
    }
	
    FATE_ProjectileManager:CreateTrackingProjectile(tProjectile)
	self.bRetracting = false
	self.hVictim = nil
	self.bDiedInInvisibleAir = false
	
	local movespeed = 1800
	
	local particleName = "particles/custom/saber/saber_invisible_air.vpcf"
	self.fxIndex = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( self.fxIndex, 3, caster:GetAbsOrigin() )
	
	caster:EmitSound("Ability.Focusfire")
	
	local invisAirCounter = 0
	Timers:CreateTimer(function()
		if invisAirCounter >= 3 then
			ParticleManager:DestroyParticle( self.fxIndex, false )
			ParticleManager:ReleaseParticleIndex( self.fxIndex )
			return
		end
		invisAirCounter = invisAirCounter + FrameTime()

		ParticleManager:SetParticleControl( self.fxIndex, 3, caster:GetAbsOrigin())
		return FrameTime()
	end)
end

function artoria_invisible_air:OnProjectileThink_ExtraData(vLocation, table)
	local caster = self:GetCaster()

	vLocation = GetGroundPosition(vLocation, nil)

	caster:SetAbsOrigin(vLocation)
	caster:SetForwardVector(self.target:GetAbsOrigin() - caster:GetAbsOrigin())
end

function artoria_invisible_air:OnProjectileHit_ExtraData(target, vLocation, tData)
	if target == nil then return end
	
	local caster = self:GetCaster()

	self.invisible_air_reach_target = true

	ParticleManager:DestroyParticle( self.fxIndex, false )
	ParticleManager:ReleaseParticleIndex( self.fxIndex )

	FindClearSpaceForUnit(caster, caster:GetAbsOrigin() - caster:GetForwardVector()*150, true)

	damage = self:GetSpecialValueFor( "damage" )  
	wind_speed = self:GetSpecialValueFor( "wind_speed" )

	vision_radius = self:GetSpecialValueFor( "vision_radius" )  
	vision_duration = self:GetSpecialValueFor( "vision_duration" )
	
	if IsSpellBlocked(target) -- Linken's
		or target:IsMagicImmune() -- Magic immunity
		or target:HasModifier("modifier_wind_protection_passive") 
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