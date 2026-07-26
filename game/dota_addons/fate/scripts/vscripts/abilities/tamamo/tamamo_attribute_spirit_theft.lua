-- tamamo_attribute_spirit_theft — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/tamamo/tamamo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

tamamo_attribute_spirit_theft = class({})

-- Логика перенесена из scripts/vscripts/tamamo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnSpiritTheftAcquired

OnSpiritTheftAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then 
		hero = caster.HeroUnit
	end

	hero.IsSpiritTheftAcquired = true
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(caster:GetMana())
end


function tamamo_attribute_spirit_theft:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: tamamo_ability / OnSpiritTheftAcquired
	OnSpiritTheftAcquired({ caster = caster, ability = self, target = caster })
end
