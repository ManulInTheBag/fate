arash_max_stella = class({})

LinkLuaModifier("modifier_arash_stella_stacks", "abilities/arash/arash_stella", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arash_stella_slow_1", "abilities/arash/arash_stella", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arash_stella_slow_2", "abilities/arash/arash_stella", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arash_stella_slow_3", "abilities/arash/arash_stella", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arash_combo_cd", "abilities/arash/arash_max_stella", LUA_MODIFIER_MOTION_NONE)

function arash_max_stella:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return UF_FAIL_CUSTOM
    elseif IsServer() and caster:FindModifierByName("modifier_arash_star_arrow") then
    	return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function arash_max_stella:GetCustomCastErrorLocation(hLocation)
	local caster = self:GetCaster()
	if caster:FindModifierByName("modifier_arash_star_arrow") then
		return "#Star arrow active"
	end
    return "#Must be in same realm"
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
	ParticleManager:SetParticleShouldCheckFoW(arrow_particle, false)
	ParticleManager:SetParticleAlwaysSimulate(arrow_particle)
	local visiondummy = SpawnVisionDummy(caster, target_point, mid_radius, delay + 1, false)
	giveUnitDataDrivenModifier(caster,  caster, "stunned", delay)
	EmitGlobalSound("arash_pre_stella")
	caster:AddNewModifier(caster, self, "modifier_arash_combo_cd", {duration = self:GetCooldown(1)})
	Timers:CreateTimer(1.75, function()
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
		if #targets ~= 1 or not caster.ArashSelfSacrifice then
			if caster:IsAlive() then
				caster:AddNoDraw()
				caster:Execute(self, caster, { bExecution = true })
			end

			local pos = caster:GetAbsOrigin()
			------
			local death_particle = ParticleManager:CreateParticle("particles/arash/arash_death.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl(death_particle, 3,  caster:GetAbsOrigin() + Vector(0,0,50) )
			--ParticleManager:SetParticleControl(point_particle, 1,  Vector(radius,0,0) )
	
			Timers:CreateTimer(delay, function()
				ParticleManager:DestroyParticle(death_particle, false)
				ParticleManager:ReleaseParticleIndex(death_particle)
			end)

			Timers:CreateTimer({
					endTime = 1,
					callback = function()
					if IsTeamWiped(caster) == false and caster.ArashSelfSacrifice and _G.CurrentGameState == "FATE_ROUND_ONGOING" then					
						local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
						caster:SetRespawnPosition(pos)
						caster:RespawnHero(false,false)
						caster:SetRespawnPosition(caster.RespawnPos)

					end
				end})	
		else
			giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 2.0)
			Timers:CreateTimer(1.5, function()
				if caster:IsAlive() then
					caster:AddNoDraw()
					caster:Execute(self, caster, { bExecution = true })
				end
				------
				local pos = caster:GetAbsOrigin()
				local death_particle = ParticleManager:CreateParticle("particles/arash/arash_death.vpcf", PATTACH_CUSTOMORIGIN, nil)
				ParticleManager:SetParticleControl(death_particle, 3,  pos + Vector(0,0,50) )
				--ParticleManager:SetParticleControl(point_particle, 1,  Vector(radius,0,0) )
		
				Timers:CreateTimer(delay, function()
					ParticleManager:DestroyParticle(death_particle, false)
					ParticleManager:ReleaseParticleIndex(death_particle)
				end)
				Timers:CreateTimer({
					endTime = 1,
					callback = function()
					if IsTeamWiped(caster) == false and caster.ArashSelfSacrifice and _G.CurrentGameState == "FATE_ROUND_ONGOING" then						
						local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
						caster:SetRespawnPosition(pos)
						caster:RespawnHero(false,false)
						caster:SetRespawnPosition(caster.RespawnPos)

					end
				end})	
			
			
			end)

		end
		
		return
	end)
	

 
	Timers:CreateTimer(delay, function()  



      

        local particle = ParticleManager:CreateParticle("particles/arash/arash_stella_explosion_combo.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, target_point) 
		ParticleManager:SetParticleShouldCheckFoW(particle, false)
		ParticleManager:SetParticleAlwaysSimulate(particle)
		Timers:CreateTimer(0.3, function()
			EmitGlobalSound("Arash_stella_drop")
			local targets = FindUnitsInRadius(caster:GetTeam(), target_point, nil, small_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			local mid_targets = FindUnitsInRadius(caster:GetTeam(), target_point, nil, mid_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			local outer_targets = FindUnitsInRadius(caster:GetTeam(), target_point, nil, large_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

			local stellatargets = {}

			for i = 1, #targets do

				stellatargets[targets[i]:entindex()] = (stellatargets[targets[i]:entindex()] or 0) + targets[i]:GetHealth() * (full_damage - damage_mid)/100
				--DoDamage(caster, targets[i], targets[i]:GetHealth() * (full_damage - damage_mid)/100, DAMAGE_TYPE_PURE, 0, self, false)
				targets[i]:AddNewModifier(caster, self, "modifier_arash_stella_slow_1", {duration  = 3})
			end 
	
			for i = 1, #mid_targets do
				stellatargets[mid_targets[i]:entindex()] = (stellatargets[mid_targets[i]:entindex()] or 0) + mid_targets[i]:GetHealth() * (damage_mid - damage_outer)/100
				--DoDamage(caster, mid_targets[i], mid_targets[i]:GetHealth() * (damage_mid - damage_outer)/100, DAMAGE_TYPE_PURE, 0, self, false)
				mid_targets[i]:AddNewModifier(caster, self, "modifier_arash_stella_slow_2", {duration  = 3})
			end 
	
			for i = 1, #outer_targets do
				stellatargets[outer_targets[i]:entindex()] = (stellatargets[outer_targets[i]:entindex()] or 0) + outer_targets[i]:GetHealth() * damage_outer/100
				--DoDamage(caster, outer_targets[i], health * damage_outer/100, DAMAGE_TYPE_PURE, 0, self, false)
				outer_targets[i]:AddNewModifier(caster, self, "modifier_arash_stella_slow_3", {duration  = 3})
			end

			for k,v in pairs(stellatargets) do
				local entity = EntIndexToHScript(k)
				entity:RemoveModifierByName("modifier_master_intervention")
				DoDamage(caster, entity, v, DAMAGE_TYPE_PURE, 0, self, false)
			end
		end) 

		Timers:CreateTimer(2, function()
			ParticleManager:ReleaseParticleIndex(particle)
			ParticleManager:DestroyParticle(arrow_particle, false)
			ParticleManager:ReleaseParticleIndex(arrow_particle)

			return
		end)

        return 
    end)
end

 