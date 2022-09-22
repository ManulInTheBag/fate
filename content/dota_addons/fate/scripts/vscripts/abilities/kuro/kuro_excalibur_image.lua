kuro_excalibur_image = class({})

function kuro_excalibur_image:GetCooldown(iLevel)
	local cooldown = self:GetSpecialValueFor("cooldown")

	if self:GetCaster():HasModifier("modifier_kuro_projection") then
		cooldown = cooldown - (cooldown * 35 / 100)
	end

	return cooldown
end

function kuro_excalibur_image:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 		
		elseif not self:GetCaster():HasModifier("modifier_projection_active") and not self:GetCaster():HasModifier("modifier_kuro_projection_overpower") then
			return UF_FAIL_CUSTOM
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function kuro_excalibur_image:OnAbilityPhaseStart()
	local caster = self:GetCaster()

	caster:EmitSound("chloe_excalibur")

	return true
end

function kuro_excalibur_image:OnSpellStart()
	local close_ability = self:GetCaster():FindAbilityByName("kuro_spellbook_close")
	close_ability:OnSpellCalled(self)

	local caster = self:GetCaster()
	local hCaster = self:GetCaster()
	local ability = self
	local target_enemy = self:GetCursorTarget()
	local target_point = target_enemy:GetAbsOrigin()

	local point = ability:GetCursorTarget():GetAbsOrigin()
    --local sound_cast = "CD.Cast.Dora"

	local beam_count = 0
	local beam_vector = (target_point - caster:GetAbsOrigin()):Normalized()
	--local diff = target:GetAbsOrigin() - caster:GetAbsOrigin()
	local damage = self:GetSpecialValueFor("damage")
	local wave_damage = self:GetSpecialValueFor("beam_damage")
	local delay = self:GetSpecialValueFor("delay")

	local origin = caster:GetAbsOrigin()	

	if hCaster:HasModifier("modifier_projection_active") then
        if hCaster:HasModifier("modifier_kuro_projection") then
            wave_damage = wave_damage + hCaster:FindAbilityByName("kuro_projection"):GetSpecialValueFor("excalibur_damage")
        end
        if hCaster:HasModifier("modifier_projection_active") and not hCaster:HasModifier("modifier_kuro_projection_overpower") then
            if hCaster:FindModifierByName("modifier_projection_active"):GetStackCount()>1 then      
                hCaster:FindModifierByName("modifier_projection_active"):SetStackCount(hCaster:FindModifierByName("modifier_projection_active"):GetStackCount()-1)
            elseif not hCaster:HasModifier("modifier_kuro_projection_overpower") then
                hCaster:RemoveModifierByName("modifier_projection_active")
            end
        end
    end

	--giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", delay + 0.1)

	local excal = 
	{
		Ability = self,
        EffectName = "",
        iMoveSpeed = 1400,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = 1000,
        fStartRadius = 350,
        fEndRadius = 350,
        Source = caster,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 5.0,
		bDeleteOnHit = false,
		vVelocity = beam_vector * 1400,
		ExtraData = { fDamage = damage}
	}		
	
		if caster:IsAlive() then
			-- Create Particle for projectile
			DoDamage(caster, target_enemy , damage , DAMAGE_TYPE_MAGICAL, 0, ability, false)
			if not target_enemy:IsMagicImmune() then
				--target_enemy:AddNewModifier(caster, target_enemy, "modifier_stunned", { Duration = 0.8 })
			end
			--giveUnitDataDrivenModifier(caster, target, "modifier_stunned", 0.2)

   			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, target_enemy)
   			ParticleManager:SetParticleControl(particle, 3, target_enemy:GetAbsOrigin())

  			caster:EmitSound("Saber.Caliburn")
			local projectile = ProjectileManager:CreateLinearProjectile(excal)
			StartAnimation(caster, {duration = 0.4, activity = ACT_DOTA_ATTACK_EVENT, rate = 3})

			local slashFxIndex = ParticleManager:CreateParticle( "particles/custom/saber/caliburn/slash.vpcf", PATTACH_ABSORIGIN, caster )
			local explodeFxIndex = ParticleManager:CreateParticle( "particles/custom/saber/caliburn/explosion.vpcf", PATTACH_ABSORIGIN, caster )
			caster:EmitSound("chloe_excalibur_sfx")

			--local casterFacing = caster:GetForwardVector()
			local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
			dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
			dummy:SetForwardVector(beam_vector)
			Timers:CreateTimer( function()
				if IsValidEntity(dummy) then
					local newLoc = dummy:GetAbsOrigin() + 1400 * 0.03 * dummy:GetForwardVector()
					dummy:SetAbsOrigin(GetGroundPosition(newLoc,dummy))
					-- DebugDrawCircle(newLoc, Vector(255,0,0), 0.5, keys.StartRadius, true, 0.15)
					return 0.03
				else
					return nil
				end
			end)
			
			local excalFxIndex = ParticleManager:CreateParticle( "particles/custom/kuro/excalibur/excalibur_shockwave.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, dummy )
			ParticleManager:SetParticleControl(excalFxIndex, 4, Vector(350,0,0))

			Timers:CreateTimer( 0.7, function()
				ParticleManager:DestroyParticle( excalFxIndex, true )
				ParticleManager:ReleaseParticleIndex( excalFxIndex )
				ParticleManager:DestroyParticle( slashFxIndex, true )
				ParticleManager:DestroyParticle( explodeFxIndex, true )
				Timers:CreateTimer( 0.5, function()
						dummy:RemoveSelf()
						return nil
					end
				)
				return nil
			end)

			return 
		end

	--[[Timers:CreateTimer(3.0, function()
		ParticleManager:DestroyParticle( slashFxIndex, false )
		ParticleManager:DestroyParticle( explodeFxIndex, false )
		return nil
	end)]]	
end

function kuro_excalibur_image:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	if hTarget == nil or hTarget == self.MainTarget then return end

	local caster = self:GetCaster()
	local damage = tData["fDamage"]
	if not hTarget:IsMagicImmune() then
		DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	end
end