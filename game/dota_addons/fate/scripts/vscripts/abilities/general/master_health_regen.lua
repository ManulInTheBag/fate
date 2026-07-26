-- master_health_regen — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

master_health_regen = class({})

-- Логика перенесена из scripts/vscripts/master_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnHPRegenGain

OnHPRegenGain = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero.HPREGgained == nil then
		hero.HPREGgained = 1
	elseif hero.BaseHPRegen == nil then
		hero.BaseHPRegen = hero:GetBaseHealthRegen()
	else 
		if hero.HPREGgained < 30 then
			hero.HPREGgained = hero.HPREGgained + 1
		else
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Get_Over_30_Stats")
			caster:GiveMana(1)
			return
		end
	end 
	hero.ServStat:addHPregen()
	-- Bandaid balance for health regen.
	hero:SetBaseHealthRegen(hero.BaseHPRegen + (3.0 * hero.HPREGgained)) --down here attributes.txt is useless, and this line is working.
	hero:CalculateStatBonus(true)

	--print(hero:GetHealthRegenMultiplier())
	-- Set master 1's mana 
	local master1 = hero.MasterUnit
	master1:SetMana(master1:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable )
end


function master_health_regen:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: master_ability / OnHPRegenGain
	OnHPRegenGain({ caster = caster, ability = self, target = caster })
end
