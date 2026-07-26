-- caster_5th_item_construction — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_item_construction = class({})

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnItemStart

OnItemStart = function(keys)
	local caster = keys.caster
	local randomitem = math.random(100)
	local item = nil

	if (caster.IsTerritoryPresent and (caster.Territory:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() < 500) or caster.IsPrivilegeImproved then 
		if randomitem <= 33 then 
			item = CreateItem("item_s_scroll", nil, nil) 
		elseif randomitem <= 66 then
			item = CreateItem("item_a_scroll", nil, nil) 
		elseif randomitem <= 100 then
			item = CreateItem("item_b_scroll", nil, nil) 
		end	
	else 
		if randomitem <= 25 then 
			item = CreateItem("item_s_scroll", nil, nil) 
		elseif randomitem <= 55 then
			item = CreateItem("item_a_scroll", nil, nil) 
		elseif randomitem <= 100 then
			item = CreateItem("item_b_scroll", nil, nil) 
		end
	end

	caster:AddItem(item)
	CheckItemCombination(caster)

    SaveStashState(caster)
end


function caster_5th_item_construction:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: caster_ability / OnItemStart
	OnItemStart({ caster = caster, ability = self, target = caster })
end
