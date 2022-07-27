alice_tea_party = class({})

LinkLuaModifier("modifier_tea_party_enemy", "abilities/nursery_rhyme/modifiers/modifier_tea_party_enemy", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tea_party_model", "abilities/nursery_rhyme/modifiers/modifier_tea_party_enemy", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tea_party_alice", "abilities/nursery_rhyme/modifiers/modifier_tea_party_alice", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_alice_tea_party_cd", "abilities/nursery_rhyme/modifiers/modifier_alice_tea_party_cd", LUA_MODIFIER_MOTION_NONE)

function alice_tea_party:GetAOERadius()
	local radius = self:GetSpecialValueFor("radius")
	local caster = self:GetCaster()

	return radius
end

function alice_tea_party:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	--[[local soundQueue = math.random(1,5)

	local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
    if #enemies == 0 then 
        caster:EmitSound("nero_aestus_cast_" .. soundQueue)
    else
        caster:EmitSound("nero_aestus_cast_" .. soundQueue)
    end]]

	return true
end

function alice_tea_party:OnSpellStart()
	local caster = self:GetCaster()
	local delay = self:GetSpecialValueFor("form_delay")
	local ability = self	
	local radius = self:GetSpecialValueFor("radius")

	giveUnitDataDrivenModifier(caster, caster, "locked", delay)

	caster:AddNewModifier(caster, ability, "modifier_alice_tea_party_cd", {	 Duration = ability:GetCooldown(1)})

	Timers:CreateTimer(delay, function()
		if caster:IsAlive() then					
			--caster:EmitSound("Hero_LegionCommander.Duel.Victory")
			caster.CircleDummy = CreateUnitByName("alice_tea_table", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
			caster.CircleDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
			caster.CircleDummy:SetDayTimeVisionRange(radius)
			caster.CircleDummy:SetNightTimeVisionRange(radius)

			caster.CircleDummy:SetAbsOrigin(GetGroundPosition(caster:GetAbsOrigin(), nil))

			LoopOverPlayers(function(player, playerID, playerHero)
        			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Aeriality"})
   			 end)

			self.GroundParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_eyesintheforest.vpcf", PATTACH_ABSORIGIN, caster.CircleDummy)
			ParticleManager:SetParticleControl(self.GroundParticle, 0, caster.CircleDummy:GetAbsOrigin())	
			ParticleManager:SetParticleControl(self.GroundParticle, 1, Vector(radius + 0,0,0))	

			Timers:CreateTimer(ability:GetSpecialValueFor("duration"), function()
				ParticleManager:DestroyParticle(self.GroundParticle, false)
				ParticleManager:ReleaseParticleIndex(self.GroundParticle)
				caster.CircleDummy:RemoveSelf()
				CustomGameEventManager:Send_ServerToAllClients("stop_horn_sound", {})
				LoopOverPlayers(function(player, playerID, playerHero)
        		if playerHero.gachi == true then
            		CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound = "lyonya_stol"})
       			end
    		end)
			end)

			local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

			for i = 1, #enemies do
				if enemies[i]:IsAlive() then
					enemies[i]:AddNewModifier(caster, ability, "modifier_tea_party_enemy", { 		  PartyCenterX = caster:GetAbsOrigin().x,
																									  PartyCenterY = caster:GetAbsOrigin().y,
																									  PartyCenterZ = caster:GetAbsOrigin().z,
																									  PartySize = radius,
																									  Duration = ability:GetSpecialValueFor("duration")})
				end
			end

			caster:AddNewModifier(caster, ability, "modifier_tea_party_alice", { 		 PartyCenterX = caster:GetAbsOrigin().x,
																						 PartyCenterY = caster:GetAbsOrigin().y,
																						 PartyCenterZ = caster:GetAbsOrigin().z,
																					  	 PartySize = radius,
																					  	 Duration = ability:GetSpecialValueFor("duration")})
		else 
			return
		end
	end)
end

function alice_tea_party:OnOwnerDied()	
	local caster = self:GetCaster()
	ParticleManager:DestroyParticle(self.GroundParticle, false)
	ParticleManager:ReleaseParticleIndex(self.GroundParticle)

	CustomGameEventManager:Send_ServerToAllClients("stop_horn_sound", {})

	LoopOverPlayers(function(player, playerID, playerHero)
    if playerHero.gachi == true then
    CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound = "lyonya_stol"})
    end
   	end)

	if IsValidEntity(caster.CircleDummy) then
		caster.CircleDummy:RemoveSelf()
	end

	local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 3500, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	for i = 1, #units do
		if units[i]:HasModifier("modifier_tea_party_enemy") then
			units[i]:RemoveModifierByName("modifier_tea_party_enemy")
		end
	end
end