saber_alter_vortigern = class({})

LinkLuaModifier("modifier_vortigern_ferocity", "abilities/arturia_alter/modifiers/modifier_vortigern_ferocity", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_self_pause", "abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)

function saber_alter_vortigern:OnSpellStart()
	local caster = self:GetCaster()
	ArsenalReturnMana(caster)
	local forward = ( self:GetCursorPosition() - caster:GetAbsOrigin() ):Normalized()
	local angle = 120
	local increment_factor = 30
	local origin = caster:GetAbsOrigin()
	local destination = origin + forward

	if (math.abs(destination.x - origin.x) < 0.01) and (math.abs(destination.y - origin.y) < 0.01) then
		destination = caster:GetForwardVector() + caster:GetAbsOrigin()
	end
	caster:AddNewModifier(caster, self, "modifier_merlin_self_pause", {Duration = 0.70}) -- Beam interval * 9 + 0.44
	EmitGlobalSound("Saber_Alter.Vortigern")
	local vortigernBeam =
	{
		Ability = self,
		EffectName = "particles/units/heroes/hero_magnataur/magnataur_shockwave.vpcf",
		iMoveSpeed = 3000,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = 600,
		Source = caster,
		fStartRadius = 75,
		fEndRadius = 120,
		bHasFrontialCone = true,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		fExpireTime = GameRules:GetGameTime() + 0.4,
		bDeleteOnHit = false,
		vVelocity = 0,
	}

	if caster.IsFerocityImproved then
		if caster:HasModifier("modifier_vortigern_ferocity") then
			local ferocity_modifier = caster:FindModifierByName("modifier_vortigern_ferocity")
			local stacks = ferocity_modifier:GetStackCount()
			if stacks > 1 then
				self:EndCooldown()
				ferocity_modifier:SetStackCount(stacks - 1)
			else
				caster:RemoveModifierByName("modifier_vortigern_ferocity")
			end
		else
			local ferocity_modifier = caster:AddNewModifier(caster, self, "modifier_vortigern_ferocity", { Duration = 3 })
			self:EndCooldown()
			ferocity_modifier:SetStackCount(2)
		end
	end

	-- 9 beams fired in a fan; damage/stun of each hit scale up with the number
	-- of beams already out (see OnProjectileHit)
	self.vortigernCount = 0
	Timers:CreateTimer( function()
			-- Note that the projectile limit is currently at 9, to increment this, need to create either dummy or thinker to store them
			if self.vortigernCount == 9 then return end

			-- Start rotating
			local theta = ( angle - self.vortigernCount * increment_factor ) * math.pi / 180
			local px = math.cos( theta ) * ( destination.x - origin.x ) - math.sin( theta ) * ( destination.y - origin.y ) + origin.x
			local py = math.sin( theta ) * ( destination.x - origin.x ) + math.cos( theta ) * ( destination.y - origin.y ) + origin.y

			local new_forward = ( Vector( px, py, origin.z ) - origin ):Normalized()
			vortigernBeam.vVelocity = new_forward * 3000
			vortigernBeam.fExpireTime = GameRules:GetGameTime() + 0.4

			-- Fire the projectile
			ProjectileManager:CreateLinearProjectile( vortigernBeam )
			self.vortigernCount = self.vortigernCount + 1

			-- Create particles
			local fxIndex1 = ParticleManager:CreateParticle( "particles/custom/saber_alter/saber_alter_vortigern_line.vpcf", PATTACH_CUSTOMORIGIN, caster )
			ParticleManager:SetParticleControl( fxIndex1, 0, caster:GetAbsOrigin() )
			ParticleManager:SetParticleControl( fxIndex1, 1, vortigernBeam.vVelocity )
			ParticleManager:SetParticleControl( fxIndex1, 2, Vector( 0.2, 0.2, 0.2 ) )

			Timers:CreateTimer( 0.2, function()
					ParticleManager:DestroyParticle( fxIndex1, false )
					ParticleManager:ReleaseParticleIndex( fxIndex1 )
					return nil
				end
			)

			return 0.06
		end
	)
end

function saber_alter_vortigern:OnProjectileHit(hTarget, vLocation)
	if not hTarget then return end
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local StunDuration = self:GetSpecialValueFor("stun_duration")
	local vortSwingDamage = 5
	local vortigernCount = self.vortigernCount or 0

	damage = damage * (80 + vortigernCount * vortSwingDamage) / 100

	if caster.ImproveKnightOfOwner then
		StunDuration = StunDuration + 0.2
	end
	StunDuration = StunDuration * (80 + vortigernCount * 5)/100
	if hTarget.IsVortigernHit ~= true then
		hTarget.IsVortigernHit = true
		Timers:CreateTimer(0.54, function() hTarget.IsVortigernHit = false return end)
		DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		hTarget:AddNewModifier(caster, caster, "modifier_stunned", {Duration = StunDuration})
	end
end
