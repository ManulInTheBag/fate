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
	end
	return 2
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
	elseif not hero:IsAlive() or ( IsRevoked(hero) and not hero:HasModifier("modifier_master_intervention")) then
		self:EndCooldown()
		caster:SetMana(caster:GetMana() + self:GetManaCost(1))
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Revoked_Error")
		return
	end

	-- if hero:GetName() == "npc_dota_hero_night_stalker" then
	-- self:EndCooldown() 
	-- caster:SetMana(caster:GetMana() + self:GetManaCost(1))
	-- 			SendErrorMessage(caster:GetPlayerOwnerID(), "#NANAYA_INCIDENT")
	-- 			return
	-- end

	hero.ServStat:useWSeal()
	-- pay mana cost
	
	local master2 = hero.MasterUnit2
	master2:SetMana(caster:GetMana())
	-- pay health cost
	caster:SetHealth(caster:GetHealth() - 1) 
	master2:SetHealth(caster:GetHealth())
	if(hero:GetName() == "npc_dota_hero_terrorblade") then
		hero:FindModifierByName("modifier_saito_fds_cast_controller"):BreakCombo()
		 
	end
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

	if(hero:GetName() == "npc_dota_hero_gyrocopter"  ) then
		if(hero:FindAbilityByName("nobu_dash"):GetCurrentAbilityCharges() ~= hero:FindAbilityByName("nobu_dash"):GetMaxAbilityCharges(-1)) then
			
			hero:FindAbilityByName("nobu_dash"):SetCurrentAbilityCharges(hero:FindAbilityByName("nobu_dash"):GetCurrentAbilityCharges() + 1)
		end
	end

	if(hero:GetName() == "npc_dota_hero_ursa"  ) then
		if(hero:FindAbilityByName("atalanta_jump"):GetCurrentAbilityCharges() ~= hero:FindAbilityByName("atalanta_jump"):GetMaxAbilityCharges(-1)) then
			
			hero:FindAbilityByName("atalanta_jump"):SetCurrentAbilityCharges(hero:FindAbilityByName("atalanta_jump"):GetCurrentAbilityCharges() + 1)
		end
	end

	if(hero:GetName() == "npc_dota_hero_faceless_void"  ) then
		if(hero:FindAbilityByName("altera_dash"):GetCurrentAbilityCharges() ~= hero:FindAbilityByName("altera_dash"):GetMaxAbilityCharges(-1)) then
			
			hero:FindAbilityByName("altera_dash"):SetCurrentAbilityCharges(hero:FindAbilityByName("altera_dash"):GetCurrentAbilityCharges() + 1)
		end
	end

	if(hero:GetName() == "npc_dota_hero_riki"  ) then
		if(hero:FindAbilityByName("jtr_dagger_throw"):GetCurrentAbilityCharges() ~= hero:FindAbilityByName("jtr_dagger_throw"):GetMaxAbilityCharges(-1)) then
			
			hero:FindAbilityByName("jtr_dagger_throw"):SetCurrentAbilityCharges(hero:FindAbilityByName("jtr_dagger_throw"):GetCurrentAbilityCharges() + 1)
		end
	end


	if(hero:GetName() == "npc_dota_hero_phantom_assassin"  ) then
		if(hero:FindAbilityByName("ryougi_knife_fan"):GetCurrentAbilityCharges() ~= hero:FindAbilityByName("ryougi_knife_fan"):GetMaxAbilityCharges(-1)) then
			
			hero:FindAbilityByName("ryougi_knife_fan"):SetCurrentAbilityCharges(hero:FindAbilityByName("ryougi_knife_fan"):GetMaxAbilityCharges(-1))
		end
	end
 


	-- Set cooldown
	if not caster:HasModifier("modifier_command_seal_1") then
		--aster:FindAbilityByName("cmd_seal_1"):StartCooldown(30)
		--caster:FindAbilityByName("cmd_seal_2"):StartCooldown(30)
		--caster:FindAbilityByName("cmd_seal_3"):StartCooldown(30)
		--caster:FindAbilityByName("cmd_seal_4"):StartCooldown(30)
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