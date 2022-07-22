jtr_maria_the_ripper = class({})

LinkLuaModifier("modifier_mtr_night_checker", "abilities/jtr/modifiers/modifier_mtr_night_checker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mtr_night_checker_tick", "abilities/jtr/modifiers/modifier_mtr_night_checker_tick", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mtr_particle", "abilities/jtr/modifiers/modifier_mtr_particle", LUA_MODIFIER_MOTION_NONE)

function jtr_maria_the_ripper:GetCastPoint()
	if self:GetCaster():HasModifier("modifier_murderer_mist_invis") then
		return self:GetSpecialValueFor("reduced_cast_point")
	else
		return self:GetSpecialValueFor("cast_point")
	end
end

function jtr_maria_the_ripper:CastFilterResultTarget(hTarget)
	if hTarget:GetName() == "npc_dota_ward_base" then 
		return UF_FAIL_CUSTOM
	end

	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self:GetCaster():GetTeamNumber())
	
	return filter
end

function jtr_maria_the_ripper:GetIntrinsicModifierName()
	return "modifier_mtr_night_checker" --screw volvo
end

function jtr_maria_the_ripper:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_mtr_night_checker_tick") then
		return "custom/jtr/maria_the_ripper_sequence"
	else
		return "custom/jtr/maria_the_ripper"
	end
end

function jtr_maria_the_ripper:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function jtr_maria_the_ripper:GetCustomCastErrorTarget(hTarget)
	return "Cannot Target Wards"
end

function jtr_maria_the_ripper:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if self:GetCaster():HasModifier("modifier_mtr_night_checker_tick") then
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
					self:True(caster, target)
					--[[Timers:CreateTimer(0.3, function()
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
					end)]]
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
	end
end

function jtr_maria_the_ripper:NotTrue(caster, target)
	StartAnimation(caster, {duration = 1.2, activity= ACT_DOTA_CAST_ABILITY_4 , rate=1.5})

	caster:AddNewModifier(caster, nil, "modifier_phased", {duration = 1.1})
	giveUnitDataDrivenModifier(caster, caster, "dragged", 1.0)
	giveUnitDataDrivenModifier(caster, caster, "revoked", 1.0)
	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 1.1)

    target:EmitSound("jtr_maria_slashes")
	EmitGlobalSound("jtr_maria_the_ripper")

	Timers:CreateTimer(0.25, function()  
		if caster:IsAlive() and target:IsAlive() then
			self:PerformSlash(caster, target)
		else
			caster:RemoveModifierByName("jump_pause")
		end
		return 
	end)

	Timers:CreateTimer(0.5, function()  
		if caster:IsAlive() and target:IsAlive() then
			self:PerformSlash(caster, target)
		else
			caster:RemoveModifierByName("jump_pause")
		end
		return 
	end)

	Timers:CreateTimer(0.75, function()  
		if caster:IsAlive() and target:IsAlive() then
			StartAnimation(caster, {duration = 1.2, activity= ACT_DOTA_CAST_ABILITY_4_END , rate=1.5})
			self:PerformSlash(caster, target)
		else
			caster:RemoveModifierByName("jump_pause")
		end
		return 
	end)

	Timers:CreateTimer(1, function()  
		if caster:IsAlive() and target:IsAlive() then
			self:PerformSlash(caster, target)
		end

		caster:RemoveModifierByName("jump_pause")
		return 
	end)
end
function jtr_maria_the_ripper:True(caster, target)
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
function jtr_maria_the_ripper:PerformSlash(caster, target)
	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized()
	local damage = self:GetSpecialValueFor("damage_per_hit")
	if IsFemaleServant(target) then
		damage = damage + self:GetSpecialValueFor("female_damage")
	end

	target:EmitSound("Hero_Riki.Backstab")

	if caster:HasModifier("modifier_efficient_killer") then
		damage = damage + caster:GetAgility() * (IsFemaleServant(target) and 1 or 0.75)
		target:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.1 })
	end

	caster:SetAbsOrigin(target:GetAbsOrigin() - diff * 100) 

	local slashIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_backstab.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl(slashIndex, 0, target:GetAbsOrigin())

	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

	Timers:CreateTimer(0.25, function()  
		ParticleManager:DestroyParticle(slashIndex, false)
		ParticleManager:ReleaseParticleIndex(slashIndex)
		return 
	end)

	if IsSpellBlocked(target) then return end

	if IsFemaleServant(target) then
		DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_NONE, self, false)
	else 
		DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_NONE, self, false)
	end	
end