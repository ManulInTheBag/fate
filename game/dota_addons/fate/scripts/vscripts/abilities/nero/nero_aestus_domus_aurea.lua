nero_aestus_domus_aurea = class({})

LinkLuaModifier("modifier_nero_aestus_cooldown", "abilities/nero/nero_aestus_domus_aurea", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aestus_domus_aurea_enemy", "abilities/nero/modifiers/modifier_aestus_domus_aurea_enemy", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aestus_domus_aurea_ally", "abilities/nero/modifiers/modifier_aestus_domus_aurea_ally", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aestus_domus_aurea_nero", "abilities/nero/modifiers/modifier_aestus_domus_aurea_nero", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spellbook_active_tracker", "abilities/nero/modifiers/modifier_spellbook_active_tracker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_laus_saint_ready_checker", "abilities/nero/modifiers/modifier_laus_saint_ready_checker", LUA_MODIFIER_MOTION_NONE)

function nero_aestus_domus_aurea:GetAOERadius()
	local radius = self:GetSpecialValueFor("radius")
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_sovereign_attribute") then
		radius = radius + 150
	end

	return radius
end

function nero_aestus_domus_aurea:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local soundQueue = math.random(1,5)

	local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
    if #enemies == 0 then 
        caster:EmitSound("nero_aestus_cast_" .. soundQueue)
    else
        caster:EmitSound("nero_aestus_cast_" .. soundQueue)
    end

	return true
end

function nero_aestus_domus_aurea:CastFilterResult()
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_aestus_domus_aurea_nero") then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end

function nero_aestus_domus_aurea:GetCustomCastError()
	return "#Aestus_Domus_is_Active"
end

function nero_aestus_domus_aurea:OnSpellStart()
	local caster = self:GetCaster()
	local delay = self:GetSpecialValueFor("form_delay")
	local ability = self	
	local radius = self:GetSpecialValueFor("radius")


	caster:FindAbilityByName("nero_heat"):EndCooldown()
	--[[if caster:HasModifier("modifier_laus_saint_ready_checker") then
		caster:RemoveModifierByName("modifier_laus_saint_ready_checker")
	end]]

	if caster:HasModifier("modifier_sovereign_attribute") then
		radius = radius + 150
	end

	caster:SwapAbilities("nero_aestus_domus_aurea", "nero_heat", false, true)

	giveUnitDataDrivenModifier(caster, caster, "locked", delay)

	caster:AddNewModifier(caster, ability, "modifier_nero_aestus_cooldown", {Duration = self:GetCooldown(1)})
	local masterCombo = caster.MasterUnit2:FindAbilityByName(ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(ability:GetCooldown(1))

	Timers:CreateTimer(delay, function()
		if caster:IsAlive() then
			if caster.IsISAcquired then
				HardCleanse(caster)
			end		
			--self:ReduceCooldown()
			caster:EmitSound("Hero_LegionCommander.Duel.Victory")
			caster.CircleDummy = CreateUnitByName("sight_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
			caster.CircleDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
			caster.CircleDummy:SetDayTimeVisionRange(radius)
			caster.CircleDummy:SetNightTimeVisionRange(radius)

			caster.CircleDummy:SetAbsOrigin(GetGroundPosition(caster:GetAbsOrigin(), nil))
			
			ability.FxDestroyed = false	

			--[[ability.TheatreRingFx = ParticleManager:CreateParticle("particles/custom/nero/nero_domus_ring_border.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster.CircleDummy)
			ParticleManager:SetParticleControl(ability.TheatreRingFx, 0, Vector(radius + 100,0,0))	
			ParticleManager:SetParticleControl(ability.TheatreRingFx, 1, Vector(radius + 100,0,0))]]

			ability.TheatreRingFx = ParticleManager:CreateParticle("particles/nero/nero_chronosphere.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleShouldCheckFoW(ability.TheatreRingFx, false)
			ParticleManager:SetParticleControl(ability.TheatreRingFx, 0, caster.CircleDummy:GetAbsOrigin())	
			ParticleManager:SetParticleControl(ability.TheatreRingFx, 1, Vector(radius, 1, 500))
			ParticleManager:SetParticleControl(ability.TheatreRingFx, 2, Vector(self:GetSpecialValueFor("duration") + 5, 0, 0))
			

			--ability:CreateBannerInCircle(caster, caster:GetAbsOrigin(), radius)
			ability.ColosseumParticle = ParticleManager:CreateParticle("particles/custom/nero/colosseum_ring.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleShouldCheckFoW(ability.ColosseumParticle, false)
			ParticleManager:SetParticleControl(ability.ColosseumParticle, 0, caster.CircleDummy:GetAbsOrigin())
			ParticleManager:SetParticleControl(ability.ColosseumParticle, 1, Vector(radius + 100, 0, 0))
			ParticleManager:SetParticleControl(ability.ColosseumParticle, 2, caster:GetAbsOrigin())

			local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			local allies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

			for i = 1, #enemies do
				if enemies[i]:IsAlive() then
					enemies[i]:AddNewModifier(caster, ability, "modifier_aestus_domus_aurea_enemy", { ResistReduc = ability:GetSpecialValueFor("resist_reduc"),
																									  ArmorReduc = ability:GetSpecialValueFor("armor_reduc"),
																									  MovespeedReduc = ability:GetSpecialValueFor("movespeed_reduc"),
																									  TheatreCenterX = caster:GetAbsOrigin().x,
																									  TheatreCenterY = caster:GetAbsOrigin().y,
																									  TheatreCenterZ = caster:GetAbsOrigin().z,
																									  TheatreSize = radius,
																									  Duration = ability:GetSpecialValueFor("duration")})
				end
			end

			for i = 1, #allies do
				if allies[i]:IsAlive() and allies[i] ~= caster then
					print(allies[i]:GetName())
					allies[i]:AddNewModifier(caster, ability, "modifier_aestus_domus_aurea_ally", { TheatreCenterX = caster:GetAbsOrigin().x,
																									TheatreCenterY = caster:GetAbsOrigin().y,
																									TheatreCenterZ = caster:GetAbsOrigin().z,
																									TheatreSize = radius,
																									Duration = ability:GetSpecialValueFor("duration")})
				end
			end

			caster:AddNewModifier(caster, ability, "modifier_aestus_domus_aurea_nero", { Resist = ability:GetSpecialValueFor("resist_reduc"),
																						 Armor = ability:GetSpecialValueFor("armor_reduc"),
																						 Movespeed = ability:GetSpecialValueFor("movespeed_reduc"),
																						 TheatreCenterX = caster:GetAbsOrigin().x,
																						 TheatreCenterY = caster:GetAbsOrigin().y,
																						 TheatreCenterZ = caster:GetAbsOrigin().z,
																					  	 TheatreSize = radius,
																					  	 Duration = ability:GetSpecialValueFor("duration")})

			--ability:CheckCombo()

			--[[Timers:CreateTimer(6.0, function()
				if caster:HasModifier("modifier_aestus_domus_aurea_nero") then
					caster:AddNewModifier(caster, ability, "modifier_laus_saint_ready_checker", { Duration = 6})
				end
			end)]]
		else 
			return
		end
	end)

	Timers:CreateTimer(delay + 0.5, function()
		if caster:IsAlive() then
			EmitGlobalSound("Nero.NP2.1")
		end
	end)
end

--[[function nero_aestus_domus_aurea:ReduceCooldown()
	local caster = self:GetCaster()

	if caster:FindAbilityByName("nero_tres_fontaine_ardent"):GetCooldownTimeRemaining() > 1 then
		caster:FindAbilityByName("nero_tres_fontaine_ardent"):EndCooldown()
		caster:FindAbilityByName("nero_tres_fontaine_ardent"):StartCooldown(1)
	end

	if caster:FindAbilityByName("nero_gladiusanus_blauserum"):GetCooldownTimeRemaining() > 1 then
		caster:FindAbilityByName("nero_gladiusanus_blauserum"):EndCooldown()
		caster:FindAbilityByName("nero_gladiusanus_blauserum"):StartCooldown(1)
	end

	if caster:FindAbilityByName("nero_rosa_ichthys"):GetCooldownTimeRemaining() > 1 then
		caster:FindAbilityByName("nero_rosa_ichthys"):EndCooldown()
		caster:FindAbilityByName("nero_rosa_ichthys"):StartCooldown(1)
	end
end]]

function nero_aestus_domus_aurea:DebugPR(string)
	local table =
    {
        text = string
    }
    CustomGameEventManager:Send_ServerToAllClients( "player_chat_lua", table )
end

function nero_aestus_domus_aurea:OnOwnerDied()	
	--self:DebugPR("NADA1")
	if not self.FxDestroyed then
		self:DestroyFx()
	end
	--self:DebugPR("NADA2")

	local caster = self:GetCaster()
	local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 3500, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	--self:DebugPR("NADA3")

	for i = 1, #units do
		if units[i]:HasModifier("modifier_aestus_domus_aurea_enemy") or units[i]:HasModifier("modifier_aestus_domus_aurea_ally") then
			units[i]:RemoveModifierByName("modifier_aestus_domus_aurea_enemy")
			units[i]:RemoveModifierByName("modifier_aestus_domus_aurea_ally")
		end
	end
	--self:DebugPR("NADA4")
end

function nero_aestus_domus_aurea:DestroyFx()
	local caster = self:GetCaster()

	ParticleManager:DestroyParticle(self.TheatreRingFx, false)
	ParticleManager:ReleaseParticleIndex(self.TheatreRingFx)
	ParticleManager:DestroyParticle(self.ColosseumParticle, false)
	ParticleManager:ReleaseParticleIndex(self.ColosseumParticle)
	--FxDestroyer(caster.TheatreRingFx, false)

	if IsValidEntity(caster.CircleDummy) then
		caster.CircleDummy:RemoveSelf()
	end

	self.FxDestroyed = true
end

function nero_aestus_domus_aurea:CreateBannerInCircle(handle, center, multiplier)
	local vCenterLoc = Vector(center.x, center.y, 0)
	vCenterLoc = GetGroundPosition(vCenterLoc, nil)
	self.ColosseumParticle = ParticleManager:CreateParticle("particles/custom/nero/colosseum_ring.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster())
	ParticleManager:SetParticleControl(self.ColosseumParticle, 1, Vector(self:GetAOERadius() + 100, 0, 0))
	ParticleManager:SetParticleControl(self.ColosseumParticle, 2, vCenterLoc)
end

function nero_aestus_domus_aurea:CheckCombo()
	local caster = self:GetCaster()

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
    	if caster:FindAbilityByName("nero_laus_saint_claudius"):IsCooldownReady() and caster:IsAlive() then
    		--if not caster:HasModifier("modifier_spellbook_active_tracker") then
    		caster:SwapAbilities("nero_laus_saint_claudius", "nero_aestus_domus_aurea", true, false)
    		--end

    		Timers:CreateTimer(3, function()
    			if caster:GetAbilityByIndex(5):GetName() ~= "nero_aestus_domus_aurea" then
    				caster:SwapAbilities("nero_laus_saint_claudius", "nero_aestus_domus_aurea", false, true)
    			end
    		end)
    	end
    end
end

modifier_nero_aestus_cooldown = class({})

function modifier_nero_aestus_cooldown:GetTexture()
	return "custom/nero_aestus_domus_aurea"
end

function modifier_nero_aestus_cooldown:IsHidden()
	return false 
end

function modifier_nero_aestus_cooldown:RemoveOnDeath()
	return false
end

function modifier_nero_aestus_cooldown:IsDebuff()
	return true 
end

function modifier_nero_aestus_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end