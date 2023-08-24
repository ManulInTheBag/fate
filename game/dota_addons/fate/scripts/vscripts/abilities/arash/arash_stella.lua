arash_stella = class({})

LinkLuaModifier("modifier_arash_stella_stacks", "abilities/arash/arash_stella", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arash_stella_slow_1", "abilities/arash/arash_stella", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arash_stella_slow_2", "abilities/arash/arash_stella", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arash_stella_slow_3", "abilities/arash/arash_stella", LUA_MODIFIER_MOTION_NONE)
 

function arash_stella:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return UF_FAIL_CUSTOM
    elseif IsServer() and caster:FindModifierByName("modifier_arash_star_arrow") then
    	return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function arash_stella:GetCustomCastErrorLocation(hLocation)
	local caster = self:GetCaster()
	if caster:FindModifierByName("modifier_arash_star_arrow") then
		return "#Star arrow active"
	end
    return "#Must be in same realm"
end

 

function arash_stella:GetIntrinsicModifierName()
	return  "modifier_arash_stella_stacks"
end
function arash_stella:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end
function arash_stella:OnSpellStart()
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
	EmitGlobalSound("Arash_stella")
	caster:FindAbilityByName("arash_arrow_construction"):GetConstructionBuff()
	Timers:CreateTimer(0.2, function()
		local point_particle = ParticleManager:CreateParticle("particles/arash/arash_stella_groundvpcf.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(point_particle, 0,  target_point )
		ParticleManager:SetParticleControl(point_particle, 1,  Vector(small_radius,mid_radius,large_radius) )
		----- self debuff
		StartAnimation(caster, {duration=delay - 0.2, activity=ACT_DOTA_DIE, rate=0.3})

		DoDamage(caster, caster, caster:GetHealth() *self:GetSpecialValueFor("self_damage_percentage")/100 , DAMAGE_TYPE_MAGICAL, 0, self, false)

		------


		Timers:CreateTimer(2.0, function()
			ParticleManager:DestroyParticle(point_particle, false)
			ParticleManager:ReleaseParticleIndex(point_particle)
		end)
		return
	end)
	

 
	Timers:CreateTimer(delay, function()  



 

        local particle = ParticleManager:CreateParticle("particles/arash/arash_stella_explosion.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, target_point) 
		ParticleManager:SetParticleShouldCheckFoW(particle, false)
		ParticleManager:SetParticleAlwaysSimulate(particle)
		Timers:CreateTimer(0.3, function()
			EmitGlobalSound("Arash_stella_drop")
			local targets = FindUnitsInRadius(caster:GetTeam(), target_point, nil, small_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			local mid_targets = FindUnitsInRadius(caster:GetTeam(), target_point, nil, mid_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			local outer_targets = FindUnitsInRadius(caster:GetTeam(), target_point, nil, large_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	
			for i = 1, #targets do
				DoDamage(caster, targets[i], full_damage - damage_mid, DAMAGE_TYPE_MAGICAL, 0, self, false)
				targets[i]:AddNewModifier(caster, self, "modifier_arash_stella_slow_1", {duration  = 1})
			end 
	
			for i = 1, #mid_targets do
				DoDamage(caster, mid_targets[i], damage_mid - damage_outer, DAMAGE_TYPE_MAGICAL, 0, self, false)
				mid_targets[i]:AddNewModifier(caster, self, "modifier_arash_stella_slow_2", {duration  = 1})
			end 
	
			for i = 1, #outer_targets do
				DoDamage(caster, outer_targets[i], damage_outer, DAMAGE_TYPE_MAGICAL, 0, self, false)
				outer_targets[i]:AddNewModifier(caster, self, "modifier_arash_stella_slow_3", {duration  = 1})
			end 
			if #outer_targets > 0 then 
				caster:SetModifierStackCount("modifier_arash_stella_stacks", caster, caster:GetModifierStackCount("modifier_arash_stella_stacks", caster) + 1)
			end
		end)


		Timers:CreateTimer(2, function()
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
			ParticleManager:DestroyParticle(arrow_particle, false)
			ParticleManager:ReleaseParticleIndex(arrow_particle)
 

			return
		end)

        return 
    end)
end


modifier_arash_stella_stacks = class({})

 
function modifier_arash_stella_stacks:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_RESPAWN,
		MODIFIER_EVENT_ON_DEATH
	}
end

function modifier_arash_stella_stacks:OnDeath(args)
	local caster = self:GetCaster() 
    if(caster ~= args.unit) then return end
	if caster.ArashSelfSacrifice then
		if caster:HasModifier("modifier_arash_stella_stacks") then
			stacks = caster:GetModifierStackCount("modifier_arash_stella_stacks", caster)
		end
		local mr = caster:FindAbilityByName("arash_toughness"):GetSpecialValueFor("base_mr") + caster:FindAbilityByName("arash_toughness"):GetSpecialValueFor("mr_per_stack") * stacks
		local armor = caster:FindAbilityByName("arash_toughness"):GetSpecialValueFor("base_armor") + caster:FindAbilityByName("arash_toughness"):GetSpecialValueFor("armor_per_stack") * stacks	
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 20000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false) 
		for k,v in pairs(targets) do
			if IsInSameRealm(caster:GetAbsOrigin(), v:GetAbsOrigin()) then
				v:AddNewModifier(caster, caster:FindAbilityByName("arash_toughness"), "modifier_arash_toughness", {duration = 5, mr = mr, armor = armor})
				v:Heal(800, caster)
			end
		end
	end
end

function modifier_arash_stella_stacks:OnRespawn(args)
	local caster = self:GetCaster() 
    if(caster ~= args.unit) then return end
	caster:RemoveNoDraw()
end

 

function modifier_arash_stella_stacks:IsDebuff()                                                             return false end
function modifier_arash_stella_stacks:IsPurgable()                                                           return false end
function modifier_arash_stella_stacks:IsPurgeException()                                                     return false end
function modifier_arash_stella_stacks:RemoveOnDeath()                                                        return false end
function modifier_arash_stella_stacks:IsHidden()															  return false end

 
 

modifier_arash_stella_slow_1 = class({})

function modifier_arash_stella_slow_1:IsDebuff() return true end
function modifier_arash_stella_slow_1:IsHidden() return false end
function modifier_arash_stella_slow_1:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function modifier_arash_stella_slow_1:GetModifierMoveSpeedBonus_Percentage()
	return -30
end

modifier_arash_stella_slow_2 = class({})

function modifier_arash_stella_slow_2:IsDebuff() return true end
function modifier_arash_stella_slow_2:IsHidden() return false end
function modifier_arash_stella_slow_2:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function modifier_arash_stella_slow_2:GetModifierMoveSpeedBonus_Percentage()
	return -30
end

modifier_arash_stella_slow_3 = class({})

function modifier_arash_stella_slow_3:IsDebuff() return true end
function modifier_arash_stella_slow_3:IsHidden() return false end
function modifier_arash_stella_slow_3:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function modifier_arash_stella_slow_3:GetModifierMoveSpeedBonus_Percentage()
	return -50
end

