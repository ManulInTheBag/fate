arash_max_stella = class({})

LinkLuaModifier("modifier_arash_stella_stacks", "abilities/arash/arash_stella", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arash_stella_slow_1", "abilities/arash/arash_stella", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arash_stella_slow_2", "abilities/arash/arash_stella", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arash_stella_slow_3", "abilities/arash/arash_stella", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arash_combo_cd", "abilities/arash/arash_max_stella", LUA_MODIFIER_MOTION_NONE)
function arash_max_stella:CastFilterResult()
    local caster = self:GetCaster()
    if IsServer() and  caster:FindModifierByName("modifier_arash_star_arrow") then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function arash_max_stella:GetCustomCastError()
	return "Star arrow active"
end
function arash_max_stella:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end
modifier_arash_combo_cd = class({})

 

function modifier_arash_combo_cd:IsHidden()
    return false 
end

function modifier_arash_combo_cd:RemoveOnDeath()
    return false
end

function modifier_arash_combo_cd:IsDebuff()
    return true 
end

function modifier_arash_combo_cd:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function arash_max_stella:OnSpellStart()
	local caster = self:GetCaster()
	local target_point = self:GetCursorPosition()
	local small_radius = self:GetSpecialValueFor("small_radius")
	local mid_radius = self:GetSpecialValueFor("mid_radius")
	local large_radius = self:GetSpecialValueFor("radius")
	local full_damage = self:GetSpecialValueFor("damage") + caster:GetModifierStackCount("modifier_arash_stella_stacks",caster) * self:GetSpecialValueFor("damage_per_stella_stack")
	local delay = self:GetSpecialValueFor("delay")
	local damage_mid = full_damage * self:GetSpecialValueFor("mid_damage_pct")/100
	local damage_outer = full_damage * self:GetSpecialValueFor("outer_damage_pct")/100
	local arrow_particle = ParticleManager:CreateParticle("particles/arash/arash_stella_arrow.vpcf", PATTACH_CUSTOMORIGIN, nil)
	local vSpawnLoc = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1"))
	ParticleManager:SetParticleControl(arrow_particle, 0,  vSpawnLoc )
	ParticleManager:SetParticleControl(arrow_particle, 1,  target_point  + Vector(0,0,2000) + caster:GetForwardVector( ) * 500)
	ParticleManager:SetParticleControl(arrow_particle, 2,  Vector(1500,0,0) )
	local visiondummy = SpawnVisionDummy(caster, target_point, mid_radius, delay + 1, false)
	giveUnitDataDrivenModifier(caster,  caster, "stunned", delay)
	EmitGlobalSound("arash_pre_stella")
	caster:AddNewModifier(caster, self, "modifier_arash_combo_cd", {duration = self:GetCooldown(1)})
	Timers:CreateTimer(2, function()
		EmitGlobalSound("Arash_stella")
	
	end) 

	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(self:GetCooldown(1))


	Timers:CreateTimer(0.2, function()
		local point_particle = ParticleManager:CreateParticle("particles/arash/arash_stella_ground_combo.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(point_particle, 0,  target_point )
		ParticleManager:SetParticleControl(point_particle, 1,  Vector(small_radius,mid_radius,large_radius) )
		----- self debuff
		Timers:CreateTimer(delay, function()
			ParticleManager:DestroyParticle(point_particle, false)
			ParticleManager:ReleaseParticleIndex(point_particle)
		end)
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 20000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_ANY_ORDER, false) 
		if #targets ~= 1 then
			if caster:IsAlive() then
				caster:AddNoDraw()
				caster:Execute(self, caster, { bExecution = true })
			end
			------
			local death_particle = ParticleManager:CreateParticle("particles/arash/arash_death.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl(death_particle, 3,  caster:GetAbsOrigin() + Vector(0,0,50) )
			--ParticleManager:SetParticleControl(point_particle, 1,  Vector(radius,0,0) )
	
			Timers:CreateTimer(delay, function()
				ParticleManager:DestroyParticle(death_particle, false)
				ParticleManager:ReleaseParticleIndex(death_particle)
			end)
		else
			giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 3.5)
			Timers:CreateTimer(3.5, function()
				if caster:IsAlive() then
					caster:AddNoDraw()
					caster:Execute(self, caster, { bExecution = true })
				end
				------
				local death_particle = ParticleManager:CreateParticle("particles/arash/arash_death.vpcf", PATTACH_CUSTOMORIGIN, nil)
				ParticleManager:SetParticleControl(death_particle, 3,  caster:GetAbsOrigin() + Vector(0,0,50) )
				--ParticleManager:SetParticleControl(point_particle, 1,  Vector(radius,0,0) )
		
				Timers:CreateTimer(delay, function()
					ParticleManager:DestroyParticle(death_particle, false)
					ParticleManager:ReleaseParticleIndex(death_particle)
				end)
			
			end)

		end
		
		return
	end)
	

 
	Timers:CreateTimer(delay, function()  



        self.Dummy = CreateUnitByName("dummy_unit", target_point, false, nil, nil, caster:GetTeamNumber())
		self.Dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)

        local particle = ParticleManager:CreateParticle("particles/arash/arash_stella_explosion_combo.vpcf", PATTACH_ABSORIGIN, self.Dummy)
		ParticleManager:SetParticleControl(particle, 0, target_point) 
		Timers:CreateTimer(0.2, function()
			EmitGlobalSound("Arash_stella_drop")
			local targets = FindUnitsInRadius(caster:GetTeam(), target_point, nil, small_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			local mid_targets = FindUnitsInRadius(caster:GetTeam(), target_point, nil, mid_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			local outer_targets = FindUnitsInRadius(caster:GetTeam(), target_point, nil, large_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	
			for i = 1, #targets do
				DoDamage(caster, targets[i], full_damage - damage_mid, DAMAGE_TYPE_PURE, 0, self, false)
				targets[i]:AddNewModifier(caster, self, "modifier_arash_stella_slow_1", {duration  = 3})
			end 
	
			for i = 1, #mid_targets do
				DoDamage(caster, mid_targets[i], damage_mid - damage_outer, DAMAGE_TYPE_PURE, 0, self, false)
				mid_targets[i]:AddNewModifier(caster, self, "modifier_arash_stella_slow_2", {duration  = 3})
			end 
	
			for i = 1, #outer_targets do
				DoDamage(caster, outer_targets[i], damage_outer, DAMAGE_TYPE_PURE, 0, self, false)
				outer_targets[i]:AddNewModifier(caster, self, "modifier_arash_stella_slow_3", {duration  = 3})
			end 
		end) 

		Timers:CreateTimer(2, function()
			ParticleManager:ReleaseParticleIndex(particle)
			ParticleManager:DestroyParticle(arrow_particle, false)
			ParticleManager:ReleaseParticleIndex(arrow_particle)
			self.Dummy:RemoveSelf()

			return
		end)

        return 
    end)
end

 