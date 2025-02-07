LinkLuaModifier("modifier_karna_dash", "abilities/karna/karna_new_abilities/karna_jump", LUA_MODIFIER_MOTION_BOTH)
karna_jump = class({})


function karna_jump:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("karna_upper_slash"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("karna_upper_slash"):SetLevel(self:GetLevel())
    end
	if caster:FindAbilityByName("karna_spears_barrage"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("karna_spears_barrage"):SetLevel(self:GetLevel())
    end
end

function karna_jump:CastFilterResultLocation(location)
    local caster = self:GetCaster()
    if IsServer() and  (caster:FindModifierByName("modifier_karna_self_pause") or caster:FindModifierByName("modifier_karna_self_pause_2")) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function karna_jump:GetCustomCastErrorLocation()
	return "Performing other ability"
end
--phase start 0.1
function karna_jump:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=1.2, activity=ACT_DOTA_CAST_ABILITY_5, rate=1})
end

function karna_jump:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    EndAnimation(caster)
end

function karna_jump:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end


function karna_jump:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local ability = self
	local origin = caster:GetAbsOrigin()
	local buff_ability = caster:FindAbilityByName("karna_buff_melee")
	local distance = (targetPoint - origin):Length2D()
	local forward = (targetPoint - origin):Normalized()
	local jump_time = 1
	local aoe_radius = self:GetSpecialValueFor("radius")
	local aoe_damage = self:GetSpecialValueFor("damage")
	local height = 750
	local mid_position_in_air = caster:GetAbsOrigin() + distance/3 * forward + Vector(0,0,height)
	local forward2 = forward
	forward2.z = 0
	caster:SetForwardVector(forward2)
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 1.2)  
	local vector_to_mid_position = (mid_position_in_air - origin):Normalized()
	EmitSoundOn("karna_new_dash_2", caster)
	caster:AddNewModifier(caster, self, "modifier_karna_dash", {duration = 0.55, distance = ((mid_position_in_air - origin):Length()), height = height, dashType = 0,
																x = vector_to_mid_position.x, y = vector_to_mid_position.y, z = vector_to_mid_position.z})
	
	Timers:CreateTimer(0.5, function()

		local  pos = caster:GetAbsOrigin()
		EmitSoundOn("karna_new_dash_1", caster)
		caster:RemoveModifierByName("modifier_karna_dash")
		caster:SetAbsOrigin(pos)
		local vector_to_end_position = (targetPoint - pos):Normalized()
		caster:AddNewModifier(caster, self, "modifier_karna_dash", {duration = 0.5, distance = (targetPoint - caster:GetAbsOrigin()):Length(), height = height, dashType = 1,
									x = vector_to_end_position.x, y = vector_to_end_position.y, z = vector_to_end_position.z})
	
	end)
	Timers:CreateTimer(0.75, function()
		caster:EmitSound("karna_new_explosion_2")
	end)
	Timers:CreateTimer(0.95, function()
	if caster:IsAlive() then
		local effect_ground_hit = ParticleManager:CreateParticle("particles/custom_game/heroes/guts/guts_sword_hit_ground/guts_sword_hit_ground.vpcf", PATTACH_WORLDORIGIN, caster)
		ParticleManager:SetParticleControl(effect_ground_hit, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*100)
		ParticleManager:ReleaseParticleIndex(effect_ground_hit)
		local effect_ground_hit_2 = ParticleManager:CreateParticle("particles/econ/items/invoker/invoker_apex/invoker_sun_strike_ground_immortal1.vpcf", PATTACH_WORLDORIGIN, caster)
		ParticleManager:SetParticleControl(effect_ground_hit_2, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*100)
		ParticleManager:ReleaseParticleIndex(effect_ground_hit_2)
		local effect_ground_hit_3 = ParticleManager:CreateParticle("particles/karna/karna_jump_ground_hit.vpcf", PATTACH_WORLDORIGIN, caster)
		ParticleManager:SetParticleControl(effect_ground_hit_3, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*100)
		ParticleManager:SetParticleControl(effect_ground_hit_3, 1, caster:GetAbsOrigin() + caster:GetForwardVector()*100)
		ParticleManager:ReleaseParticleIndex(effect_ground_hit_3)

		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
					DoDamage(caster, v, aoe_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
						giveUnitDataDrivenModifier(caster, v, "rooted", self:GetSpecialValueFor("duration"))
						giveUnitDataDrivenModifier(caster, v, "locked", self:GetSpecialValueFor("duration"))
					if caster:HasModifier("modifier_karna_buff_melee") then
						buff_ability:ApplyBurnStacks(v)
					end
					
			end
		end
		

		if caster:GetAbilityByIndex(5):GetName() == "karna_jump"  then
			caster:SwapAbilities("karna_jump", "karna_upper_slash", false, true)
			Timers:CreateTimer("karna_jump_ab_change_window", {
				endTime = 0.6,
				callback = function()
				if caster:GetAbilityByIndex(5):GetName() == "karna_upper_slash"  then
					caster:SwapAbilities("karna_jump", "karna_upper_slash", true, false)
				end
				return end
			})
		end

	end
	
	
	end)

end


modifier_karna_dash = class({})
function modifier_karna_dash:IsHidden() return true end
function modifier_karna_dash:IsDebuff() return false end
function modifier_karna_dash:IsPurgable() return false end
function modifier_karna_dash:IsPurgeException() return false end
function modifier_karna_dash:RemoveOnDeath() return true end
function modifier_karna_dash:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_karna_dash:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_karna_dash:CheckState()
    local state =   { 
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
						[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                    }
    return state
end

function modifier_karna_dash:OnCreated(table)
	if IsServer() then
		self.caster = self:GetCaster()
		self.parent = self:GetParent()
		self.ability = self:GetAbility()
		self.dashType = table.dashType
		self.height = table.height
		self.ticker = 0

			self.distance = table.distance

		--self.normalfv = self.caster:GetForwardVector()
		self.vector = Vector(table.x, table.y, table.z)
		
		if self.dashType == 0 then
			if IsServer() then
				self.speed          = self.distance*2
				self.point          = self.caster:GetAbsOrigin() +  self.vector * self.distance    
				self.direction      =  (self.point - self.caster:GetAbsOrigin()):Normalized()
				--self.parent:SetForwardVector(self.direction)
				self:StartIntervalThink(FrameTime())

			end
		else
			self.speed          = self.distance*3.33
			self.point          = self.caster:GetAbsOrigin() +  self.vector * self.distance     
			self.direction      =  (self.point - self.caster:GetAbsOrigin() ):Normalized()
			--self.parent:SetForwardVector(self.direction)
			self:StartIntervalThink(FrameTime())
		
		end
	end
end
function modifier_karna_dash:OnIntervalThink()
	self.ticker = self.ticker + FrameTime()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())

end
function modifier_karna_dash:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_karna_dash:UpdateHorizontalMotion(me, dt)
	if self.dashType == 1 and self.ticker < 0.2 then
	
	else
		if IsServer() then
				local units_per_dt = self.speed * dt
				local parent_pos = self.parent:GetAbsOrigin()
				local next_pos = parent_pos + self.direction * units_per_dt
				self.parent:SetOrigin(next_pos )
				--self.parent:SetForwardVector(self.direction )
		end
	end
end
 
function modifier_karna_dash:OnHorizontalMotionInterrupted()
    if IsServer() then
        --self:Destroy()
    end
end
function modifier_karna_dash:OnDestroy()

 
    if IsServer() then
        --self.parent:InterruptMotionControllers(true)
    end
end