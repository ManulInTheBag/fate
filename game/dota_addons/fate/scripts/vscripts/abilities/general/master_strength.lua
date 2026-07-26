-- master_strength — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

master_strength = class({})

-- Логика перенесена из scripts/vscripts/master_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnStrengthGain

OnStrengthGain = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero.STRgained == nil then
		hero.STRgained = 1
	else 
		if hero.STRgained < 30 then
			hero.STRgained = hero.STRgained + 1
		else
			caster:GiveMana(1)
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Get_Over_30_Stats")
			return
		end
	end 
	hero.ServStat:addStr()
	hero:SetBaseStrength(hero:GetBaseStrength()+1) 
	hero:CalculateStatBonus(true)
	-- Set master 1's mana 
	local master1 = hero.MasterUnit
	master1:SetMana(master1:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable )
end


function master_strength:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: master_ability / OnStrengthGain
	OnStrengthGain({ caster = caster, ability = self, target = caster })
end
