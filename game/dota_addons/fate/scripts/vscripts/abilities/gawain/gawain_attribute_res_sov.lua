-- gawain_attribute_res_sov — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/gawain/gawain_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

gawain_attribute_res_sov = class({})

-- Логика перенесена из scripts/vscripts/gawain_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnSoVAcquired

OnSoVAcquired = function(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsSoVAcquired = true

    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function gawain_attribute_res_sov:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: gawain_ability / OnSoVAcquired
	OnSoVAcquired({ caster = caster, ability = self, target = caster })
end
