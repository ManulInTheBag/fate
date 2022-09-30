LinkLuaModifier("pedigree_off", "abilities/mordred/mordred_pedigree", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_clarent_slow", "abilities/mordred/mordred_clarent", LUA_MODIFIER_MOTION_NONE)

mordred_clarent = class({})

function mordred_clarent:OnAbilityPhaseStart()
	--local caster = self:GetCaster()
    --EmitGlobalSound("mordred_clarent")
    return true
end

function mordred_clarent:OnAbilityPhaseInterrupted()
    --StopGlobalSound("mordred_clarent")
end

function mordred_clarent:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local ability = self
	EmitGlobalSound("mordred_clarent")
	caster:AddNewModifier(caster, caster:FindAbilityByName("mordred_pedigree"), "pedigree_off", {duration = caster:FindAbilityByName("mordred_pedigree"):GetSpecialValueFor("duration")})
	caster:FindAbilityByName("mordred_pedigree"):StartCooldown(caster:FindAbilityByName("mordred_pedigree"):GetCooldown(caster:FindAbilityByName("mordred_pedigree"):GetLevel()))
	local range = self:GetSpecialValueFor("range") - self:GetSpecialValueFor("width") -- We need this to take end radius of projectile into account
	local width = self:GetSpecialValueFor("width")
	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 2.05)
	StartAnimation(caster, {duration=2.05, activity=ACT_DOTA_CAST_ABILITY_3_END, rate=0.6})
	local excal = 
	{
		Ability = self,
        EffectName = "",
        iMoveSpeed = 180000,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = range,
        fStartRadius = self:GetSpecialValueFor("width"),
        fEndRadius = self:GetSpecialValueFor("width"),
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 5.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector()--self:GetSpecialValueFor("speed")
	}		

	-- Create linear projectile
	Timers:CreateTimer(1.25, function()
		if caster:IsAlive() then
			excal.vSpawnOrigin = caster:GetAbsOrigin() 
			excal.vVelocity = caster:GetForwardVector() * self:GetSpecialValueFor("speed")/0.3

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
			local excalFxIndex = ParticleManager:CreateParticle("particles/mordred/mordred_clarent_beam.vpcf", PATTACH_ABSORIGIN, caster)
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
				local excalpepegFxIndex = ParticleManager:CreateParticle("particles/mordred/mordred_clarent_beam_pepeg.vpcf", PATTACH_ABSORIGIN, caster)
   				ParticleManager:SetParticleControl(excalpepegFxIndex, 0, caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.0 + Vector(0, 0, 266))
   				ParticleManager:SetParticleControl(excalpepegFxIndex, 1, pepega_end + Vector(0,0,400)) 
			   	Timers:CreateTimer(0.8, function()
			   		ParticleManager:DestroyParticle( excalpepegFxIndex, false )
					ParticleManager:ReleaseParticleIndex( excalpepegFxIndex )
				end)
			end)
		end
	end)

	if caster:HasModifier("pedigree_off") and caster:HasModifier("modifier_mordred_overload") then
    	local kappa = caster:FindModifierByName("modifier_mordred_overload")
    	kappa:Doom()
   	end
	
	-- for i=0,1 do
		Timers:CreateTimer(0.01, function() -- Adjust 2.5 to 3.2 to match the sound
			if caster:IsAlive() then
				-- Create Particle for projectile
				local casterFacing = caster:GetForwardVector()
				local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
				dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
				dummy:SetForwardVector(casterFacing)
				Timers:CreateTimer( function()
						if IsValidEntity(dummy) then
							local newLoc = dummy:GetAbsOrigin() + self:GetSpecialValueFor("speed") * 0.03 * casterFacing
							dummy:SetAbsOrigin(GetGroundPosition(newLoc,dummy))
							-- DebugDrawCircle(newLoc, Vector(255,0,0), 0.5, keys.StartRadius, true, 0.15)
							return 0.03
						else
							return nil
						end
					end
				)
				
				--[[local excalFxIndex = ParticleManager:CreateParticle( "particles/custom/mordred/excalibur/shockwave.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, dummy )
				ParticleManager:SetParticleControl(excalFxIndex, 4, Vector(self:GetSpecialValueFor("width"),0,0))]]

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
end

function mordred_clarent:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local target = hTarget 
	local damage = self:GetSpecialValueFor("damage") + caster:GetMaxMana()*self:GetSpecialValueFor("mana_percent")/1000
	if caster:HasModifier("modifier_mordred_overload") then
		damage = damage + caster:GetMaxMana()*1/25
	end

	target:AddNewModifier(caster, self, "modifier_clarent_slow", {Duration = self:GetSpecialValueFor("slow_duration")})
	giveUnitDataDrivenModifier(caster, target, "locked", self:GetSpecialValueFor("lock_duration"))

	local ply = caster:GetPlayerOwner()
	if target:GetUnitName() == "gille_gigantic_horror" then damage = damage*1.3 end
	if target:GetName() == "npc_dota_hero_legion_commander" or target:GetName() == "npc_dota_hero_spectre" then damage = damage + 20 end
	
	DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, self, false)
end

modifier_clarent_slow = class({})

function modifier_clarent_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_clarent_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_clarent_slow:IsHidden()
	return true 
end