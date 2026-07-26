-- cmd_seal_4 — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

cmd_seal_4 = class({})

LinkLuaModifier("modifier_command_seal_4", "abilities/general/cmd_seal_4", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/master_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnSeal4Start

OnSeal4Start = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero:GetName() == "npc_dota_hero_juggernaut" then
		--caster:SetMana(caster:GetMana()+1) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Recover_Mana")
		return 
	elseif caster:GetHealth() == 1 then
		--caster:SetMana(caster:GetMana()+1) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Master_Not_Enough_Health")
		return 
	elseif not hero:IsAlive() or  ( IsRevoked(hero) and not hero:HasModifier("modifier_master_intervention"))  then
		--caster:SetMana(caster:GetMana()+1) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Revoked_Error")
		return
	elseif hero:GetMana() == hero:GetMaxMana() then
		--caster:SetMana(caster:GetMana()+1) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#At_Max_Mana")
		return
	end
	hero.ServStat:useRSeal()
	-- Set master 2's mana 
	local master2 = hero.MasterUnit2
	--master2:SetMana(master2:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	-- Set master's health
	caster:SetHealth(caster:GetHealth()-1) 

	if hero:GetName() == "npc_dota_hero_doom_bringer" and RandomInt(1, 100) <= 35 then
		EmitGlobalSound("Shiro_Onegai")
	end
	if hero:GetName() == "npc_dota_hero_spirit_breaker" then
		local modifier = hero:FindModifierByName("modifier_hijikata_laws")
    	if modifier.help_restriction == false then
        	modifier:IncrementStackCount()
			modifier:TakeDamage()
        	modifier.help_restriction = true
    	end
	end
	-- Particle
	hero:EmitSound("Hero_KeeperOfTheLight.ChakraMagic.Target")
	local particle = ParticleManager:CreateParticle("particles/items_fx/arcane_boots.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())


	hero:SetMana(hero:GetMaxMana()) 


	if caster.IsFirstSeal == true then
		keys.ability:EndCooldown()
	else
		caster:FindAbilityByName("cmd_seal_1"):StartCooldown(10)
		caster:FindAbilityByName("cmd_seal_2"):StartCooldown(10)
		caster:FindAbilityByName("cmd_seal_3"):StartCooldown(10)
		caster:FindAbilityByName("cmd_seal_4"):StartCooldown(10)
		hero:AddNewModifier(keys.caster, keys.ability, "modifier_command_seal_4", {})
	end
end


function cmd_seal_4:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: master_ability / OnSeal4Start
	OnSeal4Start({ caster = caster, ability = self, target = caster })
end

modifier_command_seal_4 = class({})

function modifier_command_seal_4:IsDebuff() return true end

function modifier_command_seal_4:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "10" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(10, true)
	end
end

function modifier_command_seal_4:OnRefresh(kv)
	self:OnCreated(kv)
end
