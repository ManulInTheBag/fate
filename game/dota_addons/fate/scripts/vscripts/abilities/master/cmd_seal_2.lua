cmd_seal_2 = class({})

LinkLuaModifier("modifier_command_seal_2", "abilities/master/modifiers/modifier_command_seal_2", LUA_MODIFIER_MOTION_NONE)

--[[function cmd_seal_2:CastFilterResult()
	local caster = self:GetCaster()

	if caster:GetHealth() == 1 then
		return UF_FAIL_CUSTOM
	end

	return UF_SUCCESS
end]]

function cmd_seal_2:GetCustomCastError()
	return "#Master_Not_Enough_Health"
end

function cmd_seal_2:GetManaCost(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_command_seal_1") then
		return 1
	else
		return 2
	end
end

function cmd_seal_2:GetCooldown(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_command_seal_1") then
		return 0
	else
		return 30
	end
end

function cmd_seal_2:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()
	local currentMana = caster:GetMana()

	if caster:GetHealth() == 1 then
		self:EndCooldown() 
		caster:SetMana(caster:GetMana() + self:GetManaCost(1))
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Master_Not_Enough_Health")
		return 
	elseif not hero:IsAlive() or IsRevoked(hero) then
		self:EndCooldown()
		caster:SetMana(caster:GetMana() + self:GetManaCost(1))
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Revoked_Error")
		return
	end

	hero.ServStat:useWSeal()
	-- pay mana cost
	
	local master2 = hero.MasterUnit2
	master2:SetMana(caster:GetMana())
	-- pay health cost
	caster:SetHealth(caster:GetHealth() - 1) 

	ResetAbilities(hero)
	ResetItems(hero)
	IncrementCharges(hero)

	-- Particle
	hero:EmitSound("Refresher_Orb_Sound")
	local particle = ParticleManager:CreateParticle("particles/items2_fx/refresher.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())

	if hero:GetName() == "npc_dota_hero_doom_bringer" and RandomInt(1, 100) <= 35 then
		EmitGlobalSound("Shiro_Onegai")
	end
 
	if(hero:GetName() == "npc_dota_hero_terrorblade") then
		hero:FindModifierByName("modifier_saito_fdb"):SetStackCount(hero:FindModifierByName("modifier_saito_fdb"):GetMaxStackCount())
		if(hero:HasModifier("modifier_saito_formlessness_tracker")) then
			hero:FindAbilityByName("saito_formlessness").isRefreshed = 1
		end
		 
	end

	-- Set cooldown
	if not caster:HasModifier("modifier_command_seal_1") then
		caster:FindAbilityByName("cmd_seal_1"):StartCooldown(30)
		--caster:FindAbilityByName("cmd_seal_2"):StartCooldown(30)
		caster:FindAbilityByName("cmd_seal_3"):StartCooldown(30)
		caster:FindAbilityByName("cmd_seal_4"):StartCooldown(30)
		hero:AddNewModifier(caster, self, "modifier_command_seal_2", { Duration = self:GetCooldown(1) })
	end


	--[[if caster.IsFirstSeal == true then
		keys.ability:EndCooldown()
		if currentMana ~= 1 then
			caster:SetMana(caster:GetMana()+1)  --refund 1 mana
			master2:SetMana(caster:GetMana())
		end
	else
		caster:FindAbilityByName("cmd_seal_1"):StartCooldown(30)
		caster:FindAbilityByName("cmd_seal_2"):StartCooldown(30)
		caster:FindAbilityByName("cmd_seal_3"):StartCooldown(30)
		caster:FindAbilityByName("cmd_seal_4"):StartCooldown(30)
		--keys.ability:ApplyDataDrivenModifier(keys.caster, hero, "modifier_command_seal_2",{})
	end]]
end