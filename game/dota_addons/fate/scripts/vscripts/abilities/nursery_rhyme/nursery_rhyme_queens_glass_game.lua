nursery_rhyme_queens_glass_game = class({})
nursery_rhyme_queens_glass_game_activate = class({})
modifier_queens_glass_game_aura = class({})
modifier_queens_glass_game = class({})
modifier_queens_glass_game_dummy = class({})

LinkLuaModifier("modifier_queens_glass_game_aura", "abilities/nursery_rhyme/nursery_rhyme_queens_glass_game", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_queens_glass_game", "abilities/nursery_rhyme/nursery_rhyme_queens_glass_game", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_queens_glass_game_dummy", "abilities/nursery_rhyme/nursery_rhyme_queens_glass_game", LUA_MODIFIER_MOTION_NONE)

function nursery_rhyme_queens_glass_game:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function nursery_rhyme_queens_glass_game:OnSpellStart()
	local hCaster = self:GetCaster()
	local tParams = {Duration = self:GetSpecialValueFor("duration")}

	hCaster.GlassGameOrigin = hCaster:GetAbsOrigin()	
	hCaster.GlassGameAura = CreateUnitByName("sight_dummy_unit", hCaster:GetAbsOrigin(), false, nil, nil, hCaster:GetTeamNumber())
	hCaster.GlassGameAura:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	hCaster.GlassGameAura:SetDayTimeVisionRange(25)
	hCaster.GlassGameAura:SetNightTimeVisionRange(25)

	hCaster.GlassGameAura:AddNewModifier(hCaster, self, "modifier_queens_glass_game_aura", tParams)
	hCaster.GlassGameAura:AddNewModifier(hCaster, self, "modifier_kill", tParams)

	local hAbility1 = hCaster:GetAbilityByIndex(0)
	local hAbility2 = hCaster:GetAbilityByIndex(1)
	local hAbility3 = hCaster:GetAbilityByIndex(2)

	hCaster.HealthOnActivate = hCaster:GetHealth()
	hCaster.ManaOnActivate = hCaster:GetMana()
	hCaster.QCooldown = hAbility1:GetCooldownTimeRemaining()
	hCaster.WCooldown = hAbility2:GetCooldownTimeRemaining()
	hCaster.ECooldown = hAbility3:GetCooldownTimeRemaining()

	EmitGlobalSound("NR.Chronosphere")
	EmitGlobalSound("NR.GlassGame.Begin")

	if hCaster:GetStrength() >= 29.1 and hCaster:GetAgility() >= 29.1 and hCaster:GetIntellect() >= 29.1 then
		if hCaster:FindAbilityByName("nursery_rhyme_story_for_somebodys_sake"):IsCooldownReady() 
			and hCaster:GetAbilityByIndex(4):GetName() == "nursery_rhyme_nameless_forest"
			and not hCaster:HasModifier("modifier_alice_tea_party_cd") 
			and (GameRules:GetGameTime() < 60 + _G.RoundStartTime) then
			hCaster:SwapAbilities("nursery_rhyme_nameless_forest", "nursery_rhyme_story_for_somebodys_sake", false, true)
			Timers:CreateTimer({
				endTime = 2,
				callback = function()
					hCaster:SwapAbilities("nursery_rhyme_nameless_forest", "nursery_rhyme_story_for_somebodys_sake", true, false)
				end
			})
		end
	end
	if hCaster:GetStrength() >= 29.1 and hCaster:GetAgility() >= 29.1 and hCaster:GetIntellect() >= 29.1 then
		if hCaster:FindAbilityByName("alice_tea_party"):IsCooldownReady() and not hCaster:HasModifier("modifier_story_for_someones_sake_cooldown") and hCaster:GetAbilityByIndex(3):GetName() == "nursery_rhyme_shapeshift" then
			hCaster:SwapAbilities("nursery_rhyme_shapeshift", "alice_tea_party", false, true)
			Timers:CreateTimer({
				endTime = 6,
				callback = function()
					hCaster:SwapAbilities("nursery_rhyme_shapeshift", "alice_tea_party", true, false)
				end
			})
		end
	end
end

function nursery_rhyme_queens_glass_game_activate:OnSpellStart()
	local hCaster = self:GetCaster()
	local hAbility1 = hCaster:GetAbilityByIndex(0)
	local hAbility2 = hCaster:GetAbilityByIndex(1)
	local hAbility3 = hCaster:GetAbilityByIndex(2)

	hAbility1:EndCooldown()
	hAbility2:EndCooldown()
	hAbility3:EndCooldown()

	hCaster:SetHealth(hCaster.HealthOnActivate)
	hCaster:SetMana(hCaster.ManaOnActivate)

	if hCaster.bIsQGGImproved then
		for i=0, 5 do
			local hItem = hCaster:GetItemInSlot(i)
			if hItem ~= nil then
				hItem:EndCooldown()
			end
		end
	else		
		hAbility1:StartCooldown(hCaster.QCooldown)
		hAbility2:StartCooldown(hCaster.WCooldown)
		hAbility3:StartCooldown(hCaster.ECooldown)
	end

	hCaster:EmitSound("Hero_Weaver.TimeLapse")
	local iParticleIndex = ParticleManager:CreateParticle("particles/custom/nursery_rhyme/nursery_timelapse.vpcf", PATTACH_CUSTOMORIGIN, hCaster)
	ParticleManager:SetParticleControl(iParticleIndex, 0, hCaster.GlassGameOrigin)
	ParticleManager:SetParticleControl(iParticleIndex, 2, hCaster:GetAbsOrigin())

	Timers:CreateTimer(1.5, function()
		ParticleManager:DestroyParticle(iParticleIndex, false)
		ParticleManager:ReleaseParticleIndex(iParticleIndex)
		return
	end)

	hCaster:SetAbsOrigin(hCaster.GlassGameOrigin)
end

function nursery_rhyme_queens_glass_game_activate:CastFilterResult()
	if self:GetCaster():HasModifier("modifier_queens_glass_game") then 
		return UF_SUCCESS
	else
		return UF_FAIL_CUSTOM
	end
end

if IsServer() then
	function modifier_queens_glass_game_aura:OnCreated(args)
		local hParent = self:GetParent()
		local hAbility = self:GetAbility()
		local fAOE = hAbility:GetSpecialValueFor("radius")

		self.iParticleIndex1 = ParticleManager:CreateParticle( "particles/custom/nursery_rhyme/queens_glass_game/queens_glass_game_aoe.vpcf", PATTACH_CUSTOMORIGIN, hParent);
		ParticleManager:SetParticleControl(self.iParticleIndex1, 0, hParent:GetOrigin())
		ParticleManager:SetParticleControl(self.iParticleIndex1, 1, Vector(fAOE, fAOE, fAOE))
		ParticleManager:SetParticleControl(self.iParticleIndex1, 3, Vector(fAOE, fAOE, fAOE))
		self.iParticleIndex2 = ParticleManager:CreateParticle( "particles/custom/nursery_rhyme/queens_glass_game/queens_glass_game_bookswirl.vpcf", PATTACH_CUSTOMORIGIN, hParent);
		ParticleManager:SetParticleControl(self.iParticleIndex2, 1, hParent:GetOrigin())
		ParticleManager:SetParticleControl(self.iParticleIndex2, 3, Vector(1,1,1))
	end

	function modifier_queens_glass_game_aura:OnDestroy()
		ParticleManager:DestroyParticle(self.iParticleIndex1, false)
		ParticleManager:ReleaseParticleIndex(self.iParticleIndex1)
		ParticleManager:DestroyParticle(self.iParticleIndex2, false)
		ParticleManager:ReleaseParticleIndex(self.iParticleIndex2)
	end

	function modifier_queens_glass_game:OnCreated(args)
		local hCaster = self:GetParent()
		if hCaster == self:GetCaster() and hCaster:GetName() == "npc_dota_hero_windrunner" then
			hCaster:SwapAbilities("nursery_rhyme_queens_glass_game", "nursery_rhyme_queens_glass_game_activate", false, true)
			hCaster:EmitSound("NR.Tick")
			hCaster:AddNewModifier(hCaster, self:GetAbility(), "modifier_queens_glass_game_dummy", { Duration = self:GetAbility():GetSpecialValueFor("duration")})
		end
	end

	function modifier_queens_glass_game:OnDestroy()		
		local hCaster = self:GetParent()
		if hCaster == self:GetCaster() and hCaster:GetName() == "npc_dota_hero_windrunner" then
			hCaster:SwapAbilities("nursery_rhyme_queens_glass_game", "nursery_rhyme_queens_glass_game_activate", true, false)
			hCaster:StopSound("NR.Tick")
			local hModifier = self:GetParent().GlassGameAura		

			if hModifier then hModifier:Destroy() end			
			hCaster:RemoveModifierByName("modifier_queens_glass_game_dummy")
		end
	end
end

function modifier_queens_glass_game:IsHidden()
	return true 
end

function modifier_queens_glass_game_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_queens_glass_game_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_queens_glass_game_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_queens_glass_game_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_queens_glass_game_aura:GetModifierAura()
	return "modifier_queens_glass_game"
end

function modifier_queens_glass_game_aura:IsHidden()
	return true 
end

function modifier_queens_glass_game_aura:RemoveOnDeath()
	return true
end

function modifier_queens_glass_game_aura:IsDebuff()
	return false 
end

function modifier_queens_glass_game_aura:IsAura()
	return true 
end