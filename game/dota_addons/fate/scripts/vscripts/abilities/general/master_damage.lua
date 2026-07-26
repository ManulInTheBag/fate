-- master_damage — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

master_damage = class({})

-- Логика перенесена из scripts/vscripts/master_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnDamageGain

OnDamageGain = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero.DMGgained == nil then
		hero.DMGgained = 1
	else 
		if hero.DMGgained < 30 then
			hero.DMGgained = hero.DMGgained + 1
		else
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Get_Over_30_Stats")
			caster:GiveMana(1)
			return
		end
	end 
	hero.ServStat:addAtk()
	local primaryStat = 0
	local attr = hero:GetPrimaryAttribute() -- 0 strength / 1 agility / 2 intelligence
	if attr == 0 then
		primaryStat = hero:GetStrength()
	elseif attr == 1 then
		primaryStat = hero:GetAgility()
	elseif attr == 2 then
		primaryStat = hero:GetIntellect()
	elseif attr == 3 then
		primaryStat = (hero:GetStrength() + hero:GetAgility() + hero:GetIntellect())*0.7
	end

	hero:SetBaseDamageMax(hero:GetBaseDamageMax() - math.floor(primaryStat) + 3)
	hero:SetBaseDamageMin(hero:GetBaseDamageMin() - math.floor(primaryStat) + 3)
	hero:CalculateStatBonus(true)

	--[[local minDmg = hero:GetBaseDamageMin() - primaryStat
	local maxDmg = hero:GetBaseDamageMax() - primaryStat

	print("Current base damage : " .. minDmg  .. " to " .. maxDmg)]]
	-- Set master 1's mana 
	local master1 = hero.MasterUnit
	master1:SetMana(master1:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable )
end


function master_damage:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: master_ability / OnDamageGain
	OnDamageGain({ caster = caster, ability = self, target = caster })
end
