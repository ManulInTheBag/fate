arturia_alter_vortigern = class({})

LinkLuaModifier("modifier_vortigern_ferocity", "abilities/arturia_alter/modifiers/modifier_vortigern_ferocity", LUA_MODIFIER_MOTION_NONE)

function arturia_alter_vortigern:GetManaCost(iLevel)
	local caster = self:GetCaster()	

	if caster:HasModifier("modifier_vortigern_ferocity") then
		return 200
	else
		return 400
	end
end

function arturia_alter_vortigern:GetCastAnimation()
	if self:CheckVortigernSequence() == 1 then
		return ACT_DOTA_ATTACK
	else
		return ACT_DOTA_CAST_ABILITY_3
	end
end

function arturia_alter_vortigern:CalculateDamage(projectile_number)
	local base_damage = self:GetSpecialValueFor("damage")

	if caster:HasModifier("modifier_hammer_attribute") then
		local sequence = self:CheckVortigernSequence()
		local multiplier = 1.33 - sequence * 0.33

		base_damage = base_damage * multiplier 
	end

	base_damage = base_damage * (80 + projectile_number * 5) / 100

	return base_damage
end

function arturia_alter_vortigern:CheckVortigernSequence()
	local caster = self:GetCaster()
	local stacks = 0

	if caster:HasModifier("modifier_vortigern_ferocity") then
		local ferocity_modifier = caster:FindModifierByName("modifier_vortigern_ferocity")
		stacks = ferocity_modifier:GetStackCount()
	end

	return stacks 
end

function arturia_alter_vortigern:HammerAttributeAction()
	local caster = self:GetCaster()
	
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
		local ferocity_modifier = caster:AddNewModifier(caster, ability, "modifier_vortigern_ferocity", { Duration = 3 })
		ferocity_modifier:SetStackCount(2)
		self:EndCooldown()
	end	
end

function arturia_alter_vortigern:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self

	local angle = 120
	local increment_factor = 30

	if caster:HasModifier("modifier_hammer_attribute") then
		self:HammerAttributeAction()
	end

	if self:CheckVortigernSequence() == 1 then
		increment_factor = -30
	end

	local forward = (self:GetCursorPosition() - caster:GetAbsOrigin() ):Normalized() -- caster:GetForwardVector() 
	
	local origin = caster:GetAbsOrigin()
	local destination = origin + forward

	if (math.abs(destination.x - origin.x) < 0.01) and (math.abs(destination.y - origin.y) < 0.01) then
		destination = caster:GetForwardVector() + caster:GetAbsOrigin()
	end
	
	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 0.70) -- Beam interval * 9 + 0.44
	EmitGlobalSound("Saber_Alter.Vortigern")	


	vortigernCount = 0
	Timers:CreateTimer(function()
		-- Finish spell, need to include the last angle as well
		-- Note that the projectile limit is currently at 9, to increment this, need to create either dummy or thinker to store them
		if vortigernCount == 9 then return end
		
		-- Start rotating
		local theta = ( angle - vortigernCount * increment_factor ) * math.pi / 180
		local px = math.cos( theta ) * ( destination.x - origin.x ) - math.sin( theta ) * ( destination.y - origin.y ) + origin.x
		local py = math.sin( theta ) * ( destination.x - origin.x ) + math.cos( theta ) * ( destination.y - origin.y ) + origin.y

		local new_forward = ( Vector( px, py, origin.z ) - origin ):Normalized()

		-- Fire the projectile
		vortigernCount = vortigernCount + 1

		local damage = self:CalculateDamage(vortigernCount)

		self:FireProjectile(caster:GetAbsOrigin(), caster, new_forward * 3000, vortigernCount, damage)
		
		-- Create particles
		local fxIndex1 = ParticleManager:CreateParticle( "particles/custom/saber_alter/saber_alter_vortigern_line.vpcf", PATTACH_CUSTOMORIGIN, caster )
		ParticleManager:SetParticleControl( fxIndex1, 0, caster:GetAbsOrigin() )
		ParticleManager:SetParticleControl( fxIndex1, 1, vortigernBeam.vVelocity )
		ParticleManager:SetParticleControl( fxIndex1, 2, Vector( 0.2, 0.2, 0.2 ) )
		
		Timers:CreateTimer( 0.2, function()
			ParticleManager:DestroyParticle( fxIndex1, false )
			ParticleManager:ReleaseParticleIndex( fxIndex1 )
			return nil
		end)
		
		return 0.06
	end)	
end

function arturia_alter_vortigern:FireProjectile(spawn_origin, source, velocity, projectile_number, projectile_damage)
	local stunDur = 0

	if projectile_number == 1 then
		stunDur = self:GetSpecialValueFor("min_stun")
	elseif projectile_number == 9 then
		stunDur = self:GetSpecialValueFor("max_stun")
	else
		stunDur = (self:GetSpecialValueFor("max_stun") - self:GetSpecialValueFor("min_stun") / 7) + self:GetSpecialValueFor("min_stun")
	end

	local vortigernBeam =
	{
		Ability = self,
		EffectName = "particles/units/heroes/hero_magnataur/magnataur_shockwave.vpcf",
		iMoveSpeed = 3000,
		vSpawnOrigin = spawn_origin,
		fDistance = 600,
		Source = source,
		fStartRadius = 75,
        fEndRadius = 120,
		bHasFrontialCone = true,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		fExpireTime = GameRules:GetGameTime() + 0.7,
		bDeleteOnHit = false,
		vVelocity = velocity,
		ExtraData = { stun_duration = stunDur, damage = projectile_damage }
	}

	ProjectileManager:CreateLinearProjectile( vortigernBeam )
end

function arturia_alter_vortigern:OnProjectileHit_ExtraData(hTarget, vLocation, tExtraData)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	
	local damage = tExtraData["projectile_damage"]
	local StunDuration = tExtraData["stun_duration"]	
	
	if hTarget.IsVortigernHit ~= true then
		hTarget.IsVortigernHit = true
		Timers:CreateTimer(0.54, function() hTarget.IsVortigernHit = false return end)
		DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		hTarget:AddNewModifier(caster, caster, "modifier_stunned", {Duration = StunDuration})
		print(damage)		
	end
end