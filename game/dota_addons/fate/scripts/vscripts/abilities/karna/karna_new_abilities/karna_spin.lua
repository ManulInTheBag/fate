karna_spin = class({})
LinkLuaModifier("modifier_karna_self_pause","abilities/karna/karna_new_abilities/karna_spin", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_karna_self_pause_2","abilities/karna/karna_new_abilities/karna_spin", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_karna_ucm_sa_stacking","abilities/karna/karna_new_abilities/karna_spin", LUA_MODIFIER_MOTION_NONE)
function karna_spin:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end
function karna_spin:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("karna_spin_2"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("karna_spin_2"):SetLevel(self:GetLevel())
    end
	if caster:FindAbilityByName("karna_recast_dash"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("karna_recast_dash"):SetLevel(self:GetLevel())
    end
	if caster:FindAbilityByName("karna_push"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("karna_push"):SetLevel(self:GetLevel())
    end
end

modifier_karna_ucm_sa_stacking = class({})


function modifier_karna_ucm_sa_stacking:IsHidden() return false end
function modifier_karna_ucm_sa_stacking:RemoveOnDeath() return true end
function modifier_karna_ucm_sa_stacking:IsDebuff() return true end

modifier_karna_self_pause_2 = class({})
function modifier_karna_self_pause_2:CheckState()
    local state =   { 
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_MUTED] = true,
		
                    }
    return state
end
function modifier_karna_self_pause_2:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_DISABLE_TURNING  }

	return funcs
end

function modifier_karna_self_pause_2:GetModifierDisableTurning() 
	return 1
end
function modifier_karna_self_pause_2:IsHidden() return false end
function modifier_karna_self_pause_2:RemoveOnDeath() return true end



modifier_karna_self_pause = class({})
function modifier_karna_self_pause:CheckState()
    local state =   { 
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_MUTED] = true,
		
                    }
    return state
end
 
function modifier_karna_self_pause:IsHidden() return false end
function modifier_karna_self_pause:RemoveOnDeath() return true end

--phase start 0.1
function karna_spin:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=1.3, activity=ACT_DOTA_CAST_ABILITY_1, rate=1})
end

function karna_spin:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    EndAnimation(caster)
end

function karna_spin:CastFilterResultLocation(location)
    local caster = self:GetCaster()
    if IsServer() and  (caster:FindModifierByName("modifier_karna_self_pause") or caster:FindModifierByName("modifier_karna_self_pause_2")) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function karna_spin:GetCustomCastErrorLocation()
	return "Performing other ability"
end

 

function karna_spin:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local ability = self
	local origin = caster:GetAbsOrigin()
	local distance = (targetPoint - origin):Length2D()
	local forward = (targetPoint - origin):Normalized()
	local time = 1.2
	local aoe_radius = self:GetSpecialValueFor("radius")
	local aoe_damage = self:GetSpecialValueFor("damage")
	local bMartialArts = caster.ManaBurstAttribute
	local bArmorRestore = false
	local bArmorRestore2 = false
	local bArmorRestore3 = false
	local bArmorActive = caster:FindModifierByName("modifier_karna_buff_melee")
	local armor_modifier = caster:FindModifierByName("modifier_karna_armor") 
	caster:AddNewModifier(caster, self, "modifier_karna_self_pause", {Duration = 1.2}) 
	local bMartialArts = caster.ManaBurstAttribute
	local physics = Physics:Unit(caster)
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(forward*400)
	caster:OnPreBounce(nil)
	caster:OnPhysicsFrame(nil)
	caster:SetBounceMultiplier(0)
	caster:PreventDI(false)
	local buff_ability = caster:FindAbilityByName("karna_buff_melee")
	Timers:CreateTimer(0.1, function()
		if not caster:IsAlive() then return end
		caster:EmitSound("karna_new_fire_2")
		caster:EmitSound("karna_new_karna_hit_2")
		--local particle = ParticleManager:CreateParticle("particles/karna/karna_spin_slash.vpcf", PATTACH_ABSORIGIN, caster)
		--ParticleManager:ReleaseParticleIndex(particle)
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				DoDamage(caster, v, aoe_damage, self:GetAbilityDamageType(), 0, self, false)
				if not bArmorRestore and  bArmorActive ~= nil then 
					armor_modifier:RestoreArmorPercentage(5)
					bArmorRestore = true
				end
				if bMartialArts then 
					if v:HasModifier("modifier_karna_ucm_sa_stacking") then
						local stacks = v:GetModifierStackCount("modifier_karna_ucm_sa_stacking", caster)
						if stacks == 4 then 
							DoDamage(caster, v, caster:GetIntellect() * 1.5, self:GetAbilityDamageType(), 0, self, false)
							giveUnitDataDrivenModifier(caster, v, "stunned",  0.5)
							v:RemoveModifierByName("modifier_karna_ucm_sa_stacking")
						else
							v:AddNewModifier(caster, self, "modifier_karna_ucm_sa_stacking", { Duration = 2})	
							v:FindModifierByName("modifier_karna_ucm_sa_stacking"):SetStackCount(stacks + 1)
						end
					else
						v:AddNewModifier(caster, self, "modifier_karna_ucm_sa_stacking", { Duration = 2})	
						v:FindModifierByName("modifier_karna_ucm_sa_stacking"):SetStackCount(1)
					end
				end

				if caster:HasModifier("modifier_karna_buff_melee") then
					buff_ability:ApplyBurnStacks(v)
				end
			end
		end
	
	
	end)

	Timers:CreateTimer(0.35, function()
		if not caster:IsAlive() then return end
		caster:EmitSound("karna_new_fire_2")
		caster:EmitSound("karna_new_karna_hit_2")
		--local particle = ParticleManager:CreateParticle("particles/karna/karna_spin_slash_2.vpcf", PATTACH_ABSORIGIN, caster)
		--ParticleManager:ReleaseParticleIndex(particle)
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				DoDamage(caster, v, aoe_damage, self:GetAbilityDamageType(), 0, self, false)
				if not bArmorRestore1 and  bArmorActive ~= nil then 
					armor_modifier:RestoreArmorPercentage(5)
					bArmorRestore1 = true
				end
				if bMartialArts then 
					if v:HasModifier("modifier_karna_ucm_sa_stacking") then
						local stacks = v:GetModifierStackCount("modifier_karna_ucm_sa_stacking", caster)
						if stacks == 4 then 
							DoDamage(caster, v, caster:GetIntellect() * 1.5, self:GetAbilityDamageType(), 0, self, false)
							giveUnitDataDrivenModifier(caster, v, "stunned",  0.5)
							v:RemoveModifierByName("modifier_karna_ucm_sa_stacking")
						else
							v:AddNewModifier(caster, self, "modifier_karna_ucm_sa_stacking", { Duration = 2})	
							v:FindModifierByName("modifier_karna_ucm_sa_stacking"):SetStackCount(stacks + 1)
						end
					else
						v:AddNewModifier(caster, self, "modifier_karna_ucm_sa_stacking", { Duration = 2})	
						v:FindModifierByName("modifier_karna_ucm_sa_stacking"):SetStackCount(1)
					end
				end
				if caster:HasModifier("modifier_karna_buff_melee") then
					buff_ability:ApplyBurnStacks(v)
				end
			end
		end
		
		
	
	end)
 
	Timers:CreateTimer(0.6, function()
	

		caster:SetPhysicsVelocity(Vector(0,0,0))
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		if not caster:IsAlive() then return end
		caster:EmitSound("karna_new_karna_hit_1")
		local enemies = FATE_FindUnitsInLine(
			caster:GetTeamNumber(),
			caster:GetAbsOrigin(),
			caster:GetAbsOrigin() + forward * 600,
			150,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_ALL,
			0,
			FIND_CLOSEST
		)
		for k,v in pairs(enemies) do
			if v:GetName() ~= "npc_dota_ward_base" then
				DoDamage(caster, v, aoe_damage, self:GetAbilityDamageType(), 0, self, false)
				if not bArmorRestore2 and  bArmorActive ~= nil then 
					armor_modifier:RestoreArmorPercentage(5)
					bArmorRestore2 = true
				end
				if bMartialArts then 
					if v:HasModifier("modifier_karna_ucm_sa_stacking") then
						local stacks = v:GetModifierStackCount("modifier_karna_ucm_sa_stacking", caster)
						if stacks == 4 then 
							DoDamage(caster, v, caster:GetIntellect() * 1.5, self:GetAbilityDamageType(), 0, self, false)
							giveUnitDataDrivenModifier(caster, v, "stunned",  0.5)
							v:RemoveModifierByName("modifier_karna_ucm_sa_stacking")
						else
							v:AddNewModifier(caster, self, "modifier_karna_ucm_sa_stacking", { Duration = 2})	
							v:FindModifierByName("modifier_karna_ucm_sa_stacking"):SetStackCount(stacks + 1)
						end
					else
						v:AddNewModifier(caster, self, "modifier_karna_ucm_sa_stacking", { Duration = 2})	
						v:FindModifierByName("modifier_karna_ucm_sa_stacking"):SetStackCount(1)
					end
				end
				if caster:HasModifier("modifier_karna_buff_melee") then
					buff_ability:ApplyBurnStacks(v)
				end
			end
		end

		
		
	end)
	Timers:CreateTimer(0.7, function()
		if caster:GetAbilityByIndex(0):GetName() == "karna_spin"  then
			caster:SwapAbilities("karna_spin", "karna_spin_2", false, true)
			Timers:CreateTimer("karna_spin_window", {
				endTime = 0.4,
				callback = function()
				if caster:GetAbilityByIndex(0):GetName() == "karna_spin_2"  then
					caster:SwapAbilities("karna_spin", "karna_spin_2", true, false)
				end
				return end
			})
		end

		if caster:GetAbilityByIndex(1):GetName() == "karna_slashes"  then
			caster:SwapAbilities("karna_slashes", "karna_recast_dash", false, true)
			Timers:CreateTimer("karna_spin_window_2", {
				endTime = 0.4,
				callback = function()
				if caster:GetAbilityByIndex(1):GetName() == "karna_recast_dash"  then
					caster:SwapAbilities("karna_slashes", "karna_recast_dash", true, false)
				end
				return end
			})
		end


	end)

end
