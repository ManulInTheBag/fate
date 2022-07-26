emiya_barrage_confine = class({})

LinkLuaModifier("modifier_sword_barrage_confine", "abilities/emiya/modifiers/modifier_sword_barrage_confine", LUA_MODIFIER_MOTION_NONE)

function emiya_barrage_confine:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local targetPoint = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local delay = self:GetSpecialValueFor("delay")
	local ply = caster:GetPlayerOwner()
	local duration = self:GetSpecialValueFor("trap_duration")
	local damage = self:GetSpecialValueFor("damage")

	Timers:CreateTimer(delay-0.2, function() --this is for playing the particle
		EmitGlobalSound("FA.Quickdraw")
		for i=1,8 do
			local swoosh = ParticleManager:CreateParticleForTeam("particles/custom/archer/ubw/confine_ring_trail.vpcf", PATTACH_CUSTOMORIGIN, nil, caster:GetTeamNumber())
	   		ParticleManager:SetParticleControl( swoosh, 0, Vector(targetPoint.x + math.cos(i*0.8) * (radius-30), targetPoint.y + math.sin(i*0.8) * (radius-30), targetPoint.z + 400))
	    	--ParticleManager:SetParticleControl( caster.barrageMarker, 1, Vector(0,0,300))
	    	Timers:CreateTimer( 0.2, function()
	        	ParticleManager:DestroyParticle( swoosh, false )
	        	ParticleManager:ReleaseParticleIndex( swoosh )
	    	end)
		end
	end)

	Timers:CreateTimer(delay, function()
		--ability:ApplyDataDrivenModifier(caster, caster, "modifier_sword_barrage_confine", {})
		for i=1,8 do
			local confineDummy = CreateUnitByName("ubw_sword_confine_dummy", Vector(targetPoint.x + math.cos(i*0.8) * (radius-30), targetPoint.y + math.sin(i*0.8) * (radius-30), 5000)  , false, caster, caster, caster:GetTeamNumber())
			confineDummy:FindAbilityByName("dummy_visible_unit_passive_no_fly"):SetLevel(1)
			confineDummy:SetForwardVector(Vector(0,0,-1))

			confineDummy:SetAbsOrigin(confineDummy:GetAbsOrigin() - Vector(0,0,-100)) 
			Timers:CreateTimer(duration, function()
				if confineDummy:IsNull() == false then
					confineDummy:RemoveSelf()
				end
			end)
		end
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
	        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	        v:AddNewModifier(caster, v, "modifier_stunned", {duration = 0.1})
	        --v:EmitSound("FA.Quickdraw")
	        if caster:HasModifier("modifier_projection_attribute") then 
	        	v:AddNewModifier(caster, self, "modifier_sword_barrage_confine", { Duration = 2.5 })
				giveUnitDataDrivenModifier(caster, v, "locked", 2.5)
			end
	    end
	end)
end