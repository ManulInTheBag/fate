jtr_mtr_new = class({})

LinkLuaModifier("modifier_mtr_night_checker", "abilities/jtr/modifiers/modifier_mtr_night_checker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mtr_night_checker_tick", "abilities/jtr/modifiers/modifier_mtr_night_checker_tick", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mtr_particle", "abilities/jtr/modifiers/modifier_mtr_particle", LUA_MODIFIER_MOTION_NONE)

function jtr_mtr_new:GetCastPoint()
	if self:GetCaster():HasModifier("modifier_murderer_mist_invis") then
		return self:GetSpecialValueFor("reduced_cast_point")
	else
		return self:GetSpecialValueFor("cast_point")
	end
end

function jtr_mtr_new:GetBehavior()
    --[[if self:GetCaster():HasModifier("modifier_mtr_night_checker_tick") then
        return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE + DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
    end]]
    return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
end

--[[function jtr_mtr_new:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end]]

--castfilters are ALWAYS crashing if not simple logic

--[[function jtr_mtr_new:CastFilterResultLocation(hLoc)
	if IsServer() then
		local caster = self:GetCaster()
		if not IsInSameRealm(caster:GetAbsOrigin(), hLoc) then
			return UF_FAIL_CUSTOM
		end
		local pepega = UF_FAIL_CUSTOM
		local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
		                                        hLoc,
		                                        nil,
		                                        self:GetSpecialValueFor("radius"),
		                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
		                                        DOTA_UNIT_TARGET_HERO,
		                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		                                        FIND_FARTHEST,
		                                        false)
		for i = 1,100000 do
			for _, enemy in pairs(enemies) do
				if enemy and not enemy:IsNull() and IsValidEntity(enemy) and IsFemaleServant(enemy) then
					pepega = UF_SUCCESS
				end
			end
		end
		return pepega
	end
end]]

function jtr_mtr_new:CastFilterResultTarget(hTarget)
	if hTarget:GetName() == "npc_dota_ward_base" then 
		return UF_FAIL_CUSTOM
	end

	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self:GetCaster():GetTeamNumber())
	
	return filter
end

function jtr_mtr_new:GetIntrinsicModifierName()
	return "modifier_mtr_night_checker" --screw volvo
end

function jtr_mtr_new:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_mtr_night_checker_tick") then
		return "custom/jtr/maria_the_ripper_sequence"
	else
		return "custom/jtr/maria_the_ripper"
	end
end

function jtr_mtr_new:GetCastRange(vLocation, hTarget)
	if self:GetCaster():HasModifier("modifier_mtr_night_checker_tick") then
		return self:GetSpecialValueFor("attribute_cast_range")
	end
	return self:GetSpecialValueFor("cast_range")
end

function jtr_mtr_new:GetCustomCastErrorTarget(hTarget)
	return "Cannot Target Wards"
end

--[[function jtr_mtr_new:GetCustomCastErrorLocation(hLoc)
	if not IsInSameRealm(self:GetCaster():GetAbsOrigin(), hLoc) then
		return "Not In Same Realm"
	end
	return "No Females Here"
end]]

function jtr_mtr_new:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if IsSpellBlocked(target) then return end

	--[[if not target then
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
		                                        self:GetCursorPosition(),
		                                        nil,
		                                        self:GetSpecialValueFor("radius"),
		                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
		                                        DOTA_UNIT_TARGET_HERO,
		                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		                                        FIND_FARTHEST,
		                                        false)

		for _, enemy in pairs(enemies) do
			if enemy and not enemy:IsNull() and IsValidEntity(enemy) and IsFemaleServant(enemy) then
				target = enemy
			end
		end
	end]]
		
	--if target then
		self:NotTrue(caster, target)
	--[[else
		self:EndCooldown()
    	caster:GiveMana(self:GetManaCost(-1))
    end]]

	--[[if self:GetCaster():HasModifier("modifier_mtr_night_checker_tick") then
		if IsFemaleServant(target) then
			caster:AddNewModifier(caster, self, "modifier_mtr_particle", {duration = 0.95})
			caster:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.95})
			giveUnitDataDrivenModifier(caster, caster, "dragged", 0.95)
			giveUnitDataDrivenModifier(caster, caster, "revoked", 0.95)
			giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.95)
			--target:EmitSound("jtr_maria_the_ripper_pre")
			--caster:EmitSound("jtr_maria_the_ripper_pre")
			Timers:CreateTimer(0.05, function()
				if target:IsAlive() and caster:IsAlive() then 	--not target:HasModifier("modifier_a_scroll") and not target:HasModifier("modifier_magic_resistance_ex_shield") and 
					EmitGlobalSound("jtr_maria_the_ripper_true")
					Timers:CreateTimer(0.3, function()
						local currentpoint = caster:GetAbsOrigin()
            			local newpoint = currentpoint+vectorsV2[math.random(1,3)]*0.5
            			caster:SetAbsOrigin(newpoint)
            			local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail.vpcf", PATTACH_CUSTOMORIGIN, caster )
           				ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
            			ParticleManager:SetParticleControl( trailFx, 0, newpoint ) 
					end)
					Timers:CreateTimer(0.6, function()
						local currentpoint = caster:GetAbsOrigin()
            			local newpoint = currentpoint+vectorsV2[math.random(4,6)]*0.5
            			caster:SetAbsOrigin(newpoint)
            			local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail.vpcf", PATTACH_CUSTOMORIGIN, caster )
           				ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
            			ParticleManager:SetParticleControl( trailFx, 0, newpoint )  
					end)
					Timers:CreateTimer(0.9, function()
						local currentpoint = caster:GetAbsOrigin()
            			local newpoint = target:GetAbsOrigin()
            			caster:SetAbsOrigin(newpoint)
						FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
						--target:Kill(self, caster)
						local damage_true = self:GetSpecialValueFor("damage_per_hit")*4

						if caster:HasModifier("modifier_efficient_killer") then
							damage_true = damage_true + caster:GetAgility() * 2.0
						end
						DoDamage(caster, target, damage_true, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self, false)
						local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail.vpcf", PATTACH_CUSTOMORIGIN, caster )
           				ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
            			ParticleManager:SetParticleControl( trailFx, 0, newpoint ) 
					end)
				else
					caster:RemoveModifierByName("modifier_mtr_particle")
					if caster:IsAlive() and target:IsAlive() then
						self:NotTrue(caster, target)
					end
				end
			end)
		else
			self:NotTrue(caster, target)
		end
	else
		self:NotTrue(caster, target)
	end]]
end

function jtr_mtr_new:NotTrue(caster, target)
	StartAnimation(caster, {duration = 1.2, activity= ACT_DOTA_CAST_ABILITY_4 , rate=1.5})

	caster:AddNewModifier(caster, nil, "modifier_phased", {duration = 1.1})
	giveUnitDataDrivenModifier(caster, caster, "dragged", 1.0)
	giveUnitDataDrivenModifier(caster, caster, "revoked", 1.0)
	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 1.1)

    target:EmitSound("jtr_maria_slashes")
	EmitGlobalSound("jtr_maria_the_ripper")

	local currentpoint2 = caster:GetAbsOrigin()

	--print(target:GetLocalAngles().y)
	local pepega_angle = QAngle(0, target:GetLocalAngles().y + 45, 0)
	caster:SetAbsOrigin(target:GetAbsOrigin())
	caster:SetAbsAngles(0, pepega_angle.y, 0)

	local initorigin = caster:GetForwardVector()*300 + caster:GetAbsOrigin()
	caster:SetAbsOrigin(initorigin)
	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	caster:SetForwardVector(Vector(diff.x, diff.y, 0))

	if caster:HasModifier("modifier_jtr_bloody_thirst_active") then
	    local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail_red.vpcf", PATTACH_CUSTOMORIGIN, caster )
	    ParticleManager:SetParticleControl( trailFx, 1, currentpoint2 )
	    ParticleManager:SetParticleControl( trailFx, 0, initorigin )
	else
		local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail.vpcf", PATTACH_CUSTOMORIGIN, caster )
	    ParticleManager:SetParticleControl( trailFx, 1, currentpoint2 )
	    ParticleManager:SetParticleControl( trailFx, 0, initorigin )
	end

	Timers:CreateTimer(0.05, function()  
		if caster:IsAlive() and target:IsAlive() then
			local currentpoint = caster:GetAbsOrigin()

			local newpoint = caster:GetForwardVector()*300 + target:GetAbsOrigin()
            caster:SetAbsOrigin(newpoint)
            local diff2 = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
			caster:SetForwardVector(Vector(diff.x, diff.y, 0))

			if caster:HasModifier("modifier_jtr_bloody_thirst_active") then	
	            local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail_red.vpcf", PATTACH_CUSTOMORIGIN, caster )
	           	ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
	            ParticleManager:SetParticleControl( trailFx, 0, newpoint ) 
	        else
	        	local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail.vpcf", PATTACH_CUSTOMORIGIN, caster )
	           	ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
	            ParticleManager:SetParticleControl( trailFx, 0, newpoint ) 
	        end
	        giveUnitDataDrivenModifier(caster, target, "locked", self:GetSpecialValueFor("duration"))
			self:PerformSlash(caster, target, FrameTime())
		else
			caster:RemoveModifierByName("jump_pause")
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		end
		return 
	end)

	Timers:CreateTimer(0.175, function()
		if caster:IsAlive() and target:IsAlive() then
			local currentpoint = caster:GetAbsOrigin()
			local pepega_angle2 = QAngle(0, target:GetLocalAngles().y + 135, 0)
			caster:SetAbsOrigin(target:GetAbsOrigin())
			caster:SetAbsAngles(0, pepega_angle2.y, 0)

			local initorigin2 = caster:GetForwardVector()*300 + caster:GetAbsOrigin()
			caster:SetAbsOrigin(initorigin2)
			local diff2 = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
			caster:SetForwardVector(Vector(diff2.x, diff2.y, 0))
			if caster:HasModifier("modifier_jtr_bloody_thirst_active") then
				local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail_red.vpcf", PATTACH_CUSTOMORIGIN, caster )
	           	ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
	            ParticleManager:SetParticleControl( trailFx, 0, initorigin2 ) 
	        else
	        	local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail.vpcf", PATTACH_CUSTOMORIGIN, caster )
	           	ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
	            ParticleManager:SetParticleControl( trailFx, 0, initorigin2 ) 
	        end
		else
			caster:RemoveModifierByName("jump_pause")
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		end
		return
	end)

	Timers:CreateTimer(0.3, function()  
		if caster:IsAlive() and target:IsAlive() then
			local currentpoint = caster:GetAbsOrigin()

			local newpoint = caster:GetForwardVector()*300 + target:GetAbsOrigin()
            caster:SetAbsOrigin(newpoint)
            local diff2 = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
			caster:SetForwardVector(Vector(diff.x, diff.y, 0))

			if caster:HasModifier("modifier_jtr_bloody_thirst_active") then
	            local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail_red.vpcf", PATTACH_CUSTOMORIGIN, caster )
	           	ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
	            ParticleManager:SetParticleControl( trailFx, 0, newpoint ) 
	        else
	        	local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail.vpcf", PATTACH_CUSTOMORIGIN, caster )
	           	ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
	            ParticleManager:SetParticleControl( trailFx, 0, newpoint ) 
	        end
	        giveUnitDataDrivenModifier(caster, target, "locked", self:GetSpecialValueFor("duration"))
			self:PerformSlash(caster, target, FrameTime())
		else
			caster:RemoveModifierByName("jump_pause")
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		end
		return 
	end)

	Timers:CreateTimer(0.425, function()
		if caster:IsAlive() and target:IsAlive() then
			local currentpoint = caster:GetAbsOrigin()

			local initorigin2 = target:GetForwardVector()*300 + target:GetAbsOrigin()
			caster:SetAbsOrigin(initorigin2)
			local diff2 = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
			caster:SetForwardVector(Vector(diff2.x, diff2.y, 0))
			if caster:HasModifier("modifier_jtr_bloody_thirst_active") then
				local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail_red.vpcf", PATTACH_CUSTOMORIGIN, caster )
	           	ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
	            ParticleManager:SetParticleControl( trailFx, 0, initorigin2 )
	        else
	        	local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail.vpcf", PATTACH_CUSTOMORIGIN, caster )
	           	ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
	            ParticleManager:SetParticleControl( trailFx, 0, initorigin2 )
	        end
		else
			caster:RemoveModifierByName("jump_pause")
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		end
		return
	end)

	Timers:CreateTimer(0.55, function()  
		if caster:IsAlive() and target:IsAlive() then
			StartAnimation(caster, {duration = 1.2, activity= ACT_DOTA_CAST_ABILITY_4_END , rate=1.5})
			local currentpoint = caster:GetAbsOrigin()

			local newpoint = caster:GetForwardVector()*100 + target:GetAbsOrigin()
            caster:SetAbsOrigin(newpoint)
            local diff2 = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
			caster:SetForwardVector(Vector(diff.x, diff.y, 0))

			if caster:HasModifier("modifier_jtr_bloody_thirst_active") then
	            local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail_red.vpcf", PATTACH_CUSTOMORIGIN, caster )
	           	ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
	            ParticleManager:SetParticleControl( trailFx, 0, newpoint ) 
	        else
	        	local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail.vpcf", PATTACH_CUSTOMORIGIN, caster )
	           	ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
	            ParticleManager:SetParticleControl( trailFx, 0, newpoint )
	        end
	        giveUnitDataDrivenModifier(caster, target, "locked", self:GetSpecialValueFor("duration"))
			self:PerformSlash(caster, target, FrameTime())
		else
			caster:RemoveModifierByName("jump_pause")
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		end
		return 
	end)

	Timers:CreateTimer(0.8, function()  
		if caster:IsAlive() and target:IsAlive() then
			giveUnitDataDrivenModifier(caster, target, "locked", self:GetSpecialValueFor("duration"))
			self:PerformEmpoweredSlash(caster, target, 0.125)
		else
			caster:RemoveModifierByName("jump_pause")
		end

		return 
	end)
end
function jtr_mtr_new:True(caster, target)
	StartAnimation(caster, {duration = 0.9, activity= ACT_DOTA_CAST_ABILITY_4 , rate=2.0})

	caster:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.9})
	giveUnitDataDrivenModifier(caster, caster, "dragged", 0.75)
	giveUnitDataDrivenModifier(caster, caster, "revoked", 0.75)
	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.75)

    --target:EmitSound("jtr_maria_slashes")
	--EmitGlobalSound("jtr_maria_the_ripper")

	Timers:CreateTimer(0.175, function()  
		if caster:IsAlive() and target:IsAlive() then
			self:PerformSlash(caster, target)
		else
			caster:RemoveModifierByName("jump_pause")
		end
		return 
	end)

	Timers:CreateTimer(0.35, function()  
		if caster:IsAlive() and target:IsAlive() then
			self:PerformSlash(caster, target)
		else
			caster:RemoveModifierByName("jump_pause")
		end
		return 
	end)

	Timers:CreateTimer(0.525, function()  
		if caster:IsAlive() and target:IsAlive() then
			StartAnimation(caster, {duration = 1.2, activity= ACT_DOTA_CAST_ABILITY_4_END , rate=1.5})
			self:PerformSlash(caster, target)
		else
			caster:RemoveModifierByName("jump_pause")
		end
		return 
	end)

	Timers:CreateTimer(0.7, function()  
		if caster:IsAlive() and target:IsAlive() then
			self:PerformSlash(caster, target)
		end

		caster:RemoveModifierByName("jump_pause")
		return 
	end)
end
function jtr_mtr_new:PerformSlash(caster, target, delay)
	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized()
	local damage = self:GetSpecialValueFor("damage_per_hit")

	target:EmitSound("Hero_Riki.Backstab")

	if caster:HasModifier("modifier_efficient_killer") then
		damage = damage + caster:GetAgility() * (IsFemaleServant(target) and 0.75 or 0.6)
		target:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.1 })
	end

	--caster:SetAbsOrigin(target:GetAbsOrigin() - diff * 100) 

	local slashIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_backstab.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl(slashIndex, 0, target:GetAbsOrigin())

	--FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

	Timers:CreateTimer(0.25, function()  
		ParticleManager:DestroyParticle(slashIndex, false)
		ParticleManager:ReleaseParticleIndex(slashIndex)
		return 
	end)

	--if IsSpellBlocked(target) then return end

	Timers:CreateTimer(delay, function()
		if target and target:IsAlive() then
			DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_NONE, self, false)
		end
	end)
end
function jtr_mtr_new:PerformEmpoweredSlash(caster, target, delay)
	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized()
	local damage = self:GetSpecialValueFor("final_damage")

	target:EmitSound("Hero_Riki.Backstab")

	if caster:HasModifier("modifier_efficient_killer") then
		damage = damage + caster:GetAgility() * (IsFemaleServant(target) and 1 or 0.75)
	end

	--caster:SetAbsOrigin(target:GetAbsOrigin() - diff * 100) 

	local slashIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_backstab.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl(slashIndex, 0, target:GetAbsOrigin())

	--FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

	Timers:CreateTimer(0.25, function()  
		ParticleManager:DestroyParticle(slashIndex, false)
		ParticleManager:ReleaseParticleIndex(slashIndex)
		return 
	end)

	--if IsSpellBlocked(target) then return end

	local sound_cast = "Hero_PhantomAssassin.CoupDeGrace"

	Timers:CreateTimer(0.075, function()
		if target and target:IsAlive() then
			EmitSoundOn(sound_cast, target)
		end
	end)

	Timers:CreateTimer(delay, function()
		if target and not target:IsAlive() then
			StopSoundOn(sound_cast, target)
		end

		local currentpoint = caster:GetAbsOrigin()

		local newpoint = -100*target:GetForwardVector() + target:GetAbsOrigin()
        caster:SetAbsOrigin(newpoint)
        local diff2 = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
		caster:SetForwardVector(Vector(diff.x, diff.y, 0))

		if caster:HasModifier("modifier_jtr_bloody_thirst_active") then
	        local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail_red.vpcf", PATTACH_CUSTOMORIGIN, caster )
	        ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
	        ParticleManager:SetParticleControl( trailFx, 0, newpoint )
	    else
	    	local trailFx = ParticleManager:CreateParticle( "particles/jtr/mtr_trail.vpcf", PATTACH_CUSTOMORIGIN, caster )
	        ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
	        ParticleManager:SetParticleControl( trailFx, 0, newpoint )
	    end

		local coup_pfx = ParticleManager:CreateParticle("particles/jtr/phantom_assassin_crit_impact.vpcf", PATTACH_CUSTOMORIGIN, target)
		ParticleManager:SetParticleControlEnt(coup_pfx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(coup_pfx, 1, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(coup_pfx)

		if target and target:IsAlive() then
			if caster:HasModifier("modifier_efficient_killer") then
				target:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.1 })
			end
			DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_NONE, self, false)
		end
		caster:RemoveModifierByName("jump_pause")
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	end)
end