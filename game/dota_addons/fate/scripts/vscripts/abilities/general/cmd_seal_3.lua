-- cmd_seal_3 — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

cmd_seal_3 = class({})

LinkLuaModifier("modifier_command_seal_3", "abilities/general/cmd_seal_3", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/master_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnSeal3Start

OnSeal3Start = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if caster:GetHealth() == 1 then
		--caster:SetMana(caster:GetMana()+1) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Master_Not_Enough_Health")
		return 
	end

	if not hero:IsAlive() or  ( IsRevoked(hero) and not hero:HasModifier("modifier_master_intervention")) then
		--caster:SetMana(caster:GetMana()+1) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Revoked_Error")
		return
	elseif hero:GetHealth() == hero:GetMaxHealth() and not hero:GetName() == "npc_dota_hero_beastmaster" then
		--caster:SetMana(caster:GetMana()+1) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#At_Max_Health")
		return
	end

	if hero:GetName() == "npc_dota_hero_doom_bringer" and RandomInt(1, 100) <= 35 then
		EmitGlobalSound("Shiro_Onegai")
	end
	if hero:GetName() == "npc_dota_hero_beastmaster"  then
		hero:FindModifierByName("modifier_karna_armor"):RestoreArmorPercentage(100)
	end
	if hero:GetName() == "npc_dota_hero_spirit_breaker" then
		local modifier = hero:FindModifierByName("modifier_hijikata_laws")
    	if modifier.help_restriction == false then
        	modifier:IncrementStackCount()
			modifier:TakeDamage()
        	modifier.help_restriction = true
    	end
	end
	hero:EmitSound("DOTA_Item.UrnOfShadows.Activate")
	hero.ServStat:useESeal()
	-- Set master 2's mana 
	local master2 = hero.MasterUnit2
	--master2:SetMana(master2:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	-- Set master's health
	caster:SetHealth(caster:GetHealth()-1) 

	local particle = ParticleManager:CreateParticle("particles/items2_fx/urn_of_shadows_heal_c.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
	--hero:ApplyHeal(hero:GetMaxHealth(), hero)
	hero:Heal(hero:GetMaxHealth() - hero:GetHealth(), keys.ability)

	if caster.IsFirstSeal == true then
		keys.ability:EndCooldown()
	else
		caster:FindAbilityByName("cmd_seal_1"):StartCooldown(20)
		caster:FindAbilityByName("cmd_seal_2"):StartCooldown(20)
		caster:FindAbilityByName("cmd_seal_3"):StartCooldown(20)
		caster:FindAbilityByName("cmd_seal_4"):StartCooldown(20)
		hero:AddNewModifier(keys.caster, keys.ability, "modifier_command_seal_3", {})
	end
end


function cmd_seal_3:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: master_ability / OnSeal3Start
	OnSeal3Start({ caster = caster, ability = self, target = caster })
end

modifier_command_seal_3 = class({})

function modifier_command_seal_3:IsDebuff() return true end

function modifier_command_seal_3:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "20" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(20, true)
	end
end

function modifier_command_seal_3:OnRefresh(kv)
	self:OnCreated(kv)
end
