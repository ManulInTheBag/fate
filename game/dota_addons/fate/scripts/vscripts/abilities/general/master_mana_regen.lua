-- master_mana_regen — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

master_mana_regen = class({})

-- Логика перенесена из scripts/vscripts/master_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnManaRegenGain

OnManaRegenGain = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero:GetName() == "npc_dota_hero_juggernaut" then
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Acquire_Mana_Regeneration")
		caster:GiveMana(1)
		return
	end

	if hero.MPREGgained == nil then
		hero.MPREGgained = 1
	elseif hero.BaseMPRegen == nil then
		hero.BaseMPRegen = hero:GetBaseManaRegen()
	else 
		if hero.MPREGgained < 30 then
			hero.MPREGgained = hero.MPREGgained + 1
		else
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Get_Over_30_Stats")
			caster:GiveMana(1)
			return
		end
	end 
	hero.ServStat:addMPregen()	
	hero:SetBaseManaRegen(hero.BaseMPRegen + (1.75 * hero.MPREGgained)) --down here attributes.txt is useless, and this line is working.
	hero:CalculateStatBonus(true)

	-- Set master 1's mana 
	local master1 = hero.MasterUnit
	master1:SetMana(master1:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable )
end


function master_mana_regen:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: master_ability / OnManaRegenGain
	OnManaRegenGain({ caster = caster, ability = self, target = caster })
end
