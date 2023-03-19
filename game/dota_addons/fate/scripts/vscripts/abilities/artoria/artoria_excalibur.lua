-----------------------------
--    Excalibur    --
-----------------------------

artoria_excalibur = class({})

LinkLuaModifier("modifier_excalibur_slow", "abilities/artoria/artoria_excalibur", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

function artoria_excalibur:OnAbilityPhaseStart()
    StartAnimation(self:GetCaster(), {duration=2.7, activity=ACT_DOTA_CAST_ABILITY_4, rate=1.0})
    return true
end

function artoria_excalibur:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end

function artoria_excalibur:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local ability = self
	local delay = self:GetSpecialValueFor("cast_delay")
	local speed = self:GetSpecialValueFor("speed")
	local width = self:GetSpecialValueFor("width")

	EmitGlobalSound("Saber.Excalibur_Ready")

	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 2.7)

	EmitGlobalSound("Saber_Ex")
	Timers:CreateTimer(0.55, function()
		EmitGlobalSound("saber_effect")
	end) 		

	local chargeFxIndex = ParticleManager:CreateParticle( "particles/custom/artoria/artoria_excalibur_charge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )

	Timers:CreateTimer(delay, function() 
		if caster:IsAlive() then
			EmitGlobalSound("Saber_Kalibar")
		end
		ParticleManager:DestroyParticle( chargeFxIndex, false )
		ParticleManager:ReleaseParticleIndex( chargeFxIndex )
	end)
	
	local enemy = PickRandomEnemy(caster)

    if enemy then
        caster:AddNewModifier(enemy, nil, "modifier_vision_provider", { Duration = 2 })
    end
	
	local range = self:GetSpecialValueFor("range") - width -- We need this to take end radius of projectile into account
	--giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 2)
	--StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_CAST_ABILITY_6, rate=1})
	local excal = 
	{
		Ability = self,
        EffectName = "",
        iMoveSpeed = speed,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = range,
        fStartRadius = width,
        fEndRadius = width,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 5.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * speed
	}

	-- Create linear projectile
	Timers:CreateTimer(delay, function()
		if caster:IsAlive() then
			excal.vSpawnOrigin = caster:GetAbsOrigin() 
			excal.vVelocity = caster:GetForwardVector() * speed/0.3
			local counter = 10
			Timers:CreateTimer(0, function()        
            counter = counter -1
            if not caster:IsAlive() then return end
            local projectile = ProjectileManager:CreateLinearProjectile(excal)
            	if(counter == 0) then
                return  
            	end
            return 0.08
        	end)
 
			ScreenShake(caster:GetOrigin(), 5, 0.1, 2, 20000, 0, true)
			AddFOWViewer(2,Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 200) + caster:GetForwardVector()*100, 10, 1, false)
    		AddFOWViewer(3,Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 200) + caster:GetForwardVector()*100, 10, 1, false)
			local excalFxIndex = ParticleManager:CreateParticle("particles/saber/saber_excalibur_beam.vpcf", PATTACH_ABSORIGIN, caster)
			local pepega_end = GetGroundPosition(caster:GetAbsOrigin() + caster:GetForwardVector()*(range + width-100), caster)
			local pepega_vec = (pepega_end - caster:GetAbsOrigin()):Normalized()
   			ParticleManager:SetParticleControl(excalFxIndex, 0, Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 200) + caster:GetForwardVector()*100)
   			ParticleManager:SetParticleControl(excalFxIndex, 1, caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.0 + Vector(0, 0, 266)) 
		   	Timers:CreateTimer(0.8, function()
		   		ParticleManager:DestroyParticle( excalFxIndex, false )
				ParticleManager:ReleaseParticleIndex( excalFxIndex )
			end)
			Timers:CreateTimer(0.1, function()
				AddFOWViewer(2,caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.0 + Vector(0, 0, 266), 10, 1, false)
    			AddFOWViewer(3,caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.0 + Vector(0, 0, 266), 10, 1, false)
				local excalpepegFxIndex = ParticleManager:CreateParticle("particles/saber/saber_excalibur_beam_pepeg.vpcf", PATTACH_ABSORIGIN, caster)
   				ParticleManager:SetParticleControl(excalpepegFxIndex, 0, caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.0 + Vector(0, 0, 266))
   				ParticleManager:SetParticleControl(excalpepegFxIndex, 1, pepega_end + Vector(0,0,400)) 
			   	Timers:CreateTimer(0.8, function()
			   		ParticleManager:DestroyParticle( excalpepegFxIndex, false )
					ParticleManager:ReleaseParticleIndex( excalpepegFxIndex )
				end)
			end)
		else
			StopGlobalSound("saber_effect")
		end
	end)
	
	-- for i=0,1 do
		Timers:CreateTimer(delay - 0.3, function() -- Adjust 2.5 to 3.2 to match the sound
			if caster:IsAlive() then
				-- Create Particle for projectile
				local casterFacing = caster:GetForwardVector()
				local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
				dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
				dummy:SetForwardVector(casterFacing)
				Timers:CreateTimer( function()
						if IsValidEntity(dummy) then
							local newLoc = dummy:GetAbsOrigin() + speed * 0.03 * casterFacing
							dummy:SetAbsOrigin(GetGroundPosition(newLoc,dummy))
							-- DebugDrawCircle(newLoc, Vector(255,0,0), 0.5, keys.StartRadius, true, 0.15)
							return 0.03
						else
							return nil
						end
					end
				)
				
				--local excalFxIndex = ParticleManager:CreateParticle( "particles/custom/saber/excalibur/shockwave.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, dummy )
				--ParticleManager:SetParticleControl(excalFxIndex, 4, Vector(keys.StartRadius,0,0))

				Timers:CreateTimer( 1.65, function()
						--ParticleManager:DestroyParticle( excalFxIndex, false )
						--ParticleManager:ReleaseParticleIndex( excalFxIndex )
						Timers:CreateTimer( 0.5, function()
								dummy:RemoveSelf()
								return nil
							end
						)
						return nil
					end
				)
				return 
			end
		end)
	-- end
end

function artoria_excalibur:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	if hTarget == nil then return end
	
	if hTarget:IsMagicImmune() then
		return
	end

	local caster = self:GetCaster()
	local target = hTarget 
	local damage = self:GetSpecialValueFor("damage")
	local player = caster:GetPlayerOwner()

	if caster:HasModifier("modifier_artoria_improve_excalibur_attribute") then
		 damage = damage + (caster:GetMaxMana()*  self:GetSpecialValueFor("manaScaling")/100)/10
	end

	target:AddNewModifier(caster, self, "modifier_excalibur_slow", {Duration = 0.5})
	giveUnitDataDrivenModifier(caster, target, "locked", 0.5)
	
	if target:GetUnitName() == "gille_gigantic_horror" then damage = damage * 1.5 end
	
	DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, self, false)
end

modifier_excalibur_slow = class({})

function modifier_excalibur_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_excalibur_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_excalibur_slow:IsHidden()
	return true 
end