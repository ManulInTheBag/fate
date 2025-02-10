karna_brahmastra_new = class({})

LinkLuaModifier("modifier_brahmastra_stun", "abilities/karna/modifiers/modifier_brahmastra_stun", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_karna_slow_jopa", "abilities/karna/karna_new_abilities/karna_brahmastra_new", LUA_MODIFIER_MOTION_NONE)
--[[function karna_brahmastra:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end]]
function karna_brahmastra_new:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("karna_slashes"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("karna_slashes"):SetLevel(self:GetLevel())
    end

end

function karna_brahmastra_new:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function karna_brahmastra_new:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=0.9, activity=ACT_DOTA_CAST_DRAGONBREATH, rate=1})
end

function karna_brahmastra_new:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    EndAnimation(caster)
end

function karna_brahmastra_new:AngleToRadians(angle)
	return angle*math.pi / 180
end

function karna_brahmastra_new:OnSpellStart()
	local aoe = self:GetSpecialValueFor("beam_aoe")
	local range = self:GetSpecialValueFor("range")	
	self.damage = self:GetSpecialValueFor("damage")

	local caster = self:GetCaster()
	if caster.IndraAttribute then
		self.damage  = self.damage  + (caster.IndraAttribute and 1 * caster:GetIntellect() or 0)
	end
	local targetPoint = self:GetCursorPosition()
	local forward = (targetPoint - caster:GetAbsOrigin()):Normalized()
	if forward:Length2D() < 1 then
		forward = caster:GetForwardVector()
	end
	local forward2 = forward
	forward2.z = 0
	caster:SetForwardVector(forward2)
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.5) 
	self.Laser = ParticleManager:CreateParticle("particles/karna/brahmastra_laser/brahmastra_laser_powered.vpcf", PATTACH_CUSTOMORIGIN, nil)
	local counter = 0
	self.AttackedTargets    = {}
	--[[
	local a = forward
	local b = Vector(1,0,0)
	local a_dot_b = a.x *b.x + a.y*b.y + a.z* b.z
	local math_value =  a_dot_b / (a:Length() * b:Length())
	if math_value < 0 then math_value = math_value  * -1 end
	local vector_between_vectors  = math.acos(math_value)
	local total_time = 0.4
	local total_angle = 60

	local start_angle = self:AngleToRadians(-30)  + vector_between_vectors
	
	local angle_per_frame = self:AngleToRadians(total_angle/frames) --5 

	t = FrameTime()
	]]
	local frames = 13

	local right_vector = caster:GetRightVector()
	right_vector.z = 0
	local right_component_scale = -1
	local forward_component_scale = 0
	local gain = 1/(frames -1)*2
	local initial_damage = self.damage
	ParticleManager:SetParticleControlEnt(self.Laser, 1, caster, PATTACH_POINT_FOLLOW, "attach_right_eye", caster:GetOrigin(), true)
	ParticleManager:SetParticleControl(self.Laser, 9, caster:GetAbsOrigin() + forward*range + right_component_scale * right_vector*range*0.7+  -1* math.pow(right_component_scale, 2)* forward*range)
	Timers:CreateTimer(function()
		if counter >= frames  then 
			--ParticleManager:DestroyParticle( self.Laser, true )
			ParticleManager:ReleaseParticleIndex( self.Laser )
			return
		else
			local parabola_midpoint = caster:GetAbsOrigin() + forward*range
			local position_vector = parabola_midpoint + right_component_scale * right_vector*range*0.7+  -1* math.pow(right_component_scale, 2)* forward*range
			position_vector.z = GetGroundPosition(position_vector, caster).z + 150
			right_component_scale = right_component_scale + gain
			ParticleManager:SetParticleControl(self.Laser, 9, position_vector)
			if counter >=6 then
				forward_component_scale = forward_component_scale -  gain
			else
				forward_component_scale = forward_component_scale + gain
			end
			
			local hEnemies =   FindUnitsInLine(
													caster:GetTeamNumber(),
													caster:GetAbsOrigin(),
													position_vector,
													nil,
													100,
													DOTA_UNIT_TARGET_TEAM_ENEMY,
													DOTA_UNIT_TARGET_ALL,
													DOTA_UNIT_TARGET_FLAG_NONE
												)
			for k,v in pairs(hEnemies) do
				if v:GetName() ~= "npc_dota_ward_base" then
					if not self.AttackedTargets[v:entindex()] then
						self.AttackedTargets[v:entindex()] = true
					
						DoDamage(caster, v, self.damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
						v:AddNewModifier(caster, self, "modifier_karna_slow_jopa", {duration = self:GetSpecialValueFor("slow_duration")})
					end
				end
			end

		if caster.IndraAttribute then 
			self.damage = self.damage + initial_damage * 0.03
		end
		counter = counter + 1
		return FrameTime()
		end
	end)
	caster:EmitSound("karna_brahmastra_" .. math.random(1,4))
 
	caster:EmitSound("karna_brahmastra_laser")
	caster:EmitSound("karna_new_karna_beam_1")
	caster:EmitSound("karna_new_karna_beam_2")
end

 
 
 

 
modifier_karna_slow_jopa = class({})

function modifier_karna_slow_jopa:IsDebuff() return true end
function modifier_karna_slow_jopa:IsHidden() return false end
function modifier_karna_slow_jopa:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function modifier_karna_slow_jopa:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_percentage")
end


