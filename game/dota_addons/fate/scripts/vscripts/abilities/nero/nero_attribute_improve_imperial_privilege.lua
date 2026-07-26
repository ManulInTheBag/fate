-- nero_attribute_improve_imperial_privilege — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/nero/nero_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

nero_attribute_improve_imperial_privilege = class({})

-- Логика перенесена из scripts/vscripts/nero_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnPrivilegeImproved

OnPrivilegeImproved = function(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsPrivilegeImproved = true

    hero:FindAbilityByName("nero_imperial_open"):SetLevel(2)

    hero:FindAbilityByName("nero_imperial_close"):SetLevel(2)
    hero:FindAbilityByName("nero_imperial_activate"):SetLevel(2)

    Timers:CreateTimer(function()
		if hero:IsAlive() then 
			hero:AddNewModifier(hero, self, "modifier_eagle_eye", {})
			return nil
		else
			return 1
		end
	end)


    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function nero_attribute_improve_imperial_privilege:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: nero_ability / OnPrivilegeImproved
	OnPrivilegeImproved({ caster = caster, ability = self, target = caster })
end
