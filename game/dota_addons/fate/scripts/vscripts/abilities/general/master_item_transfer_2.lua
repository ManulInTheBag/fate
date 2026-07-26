-- master_item_transfer_2 — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

master_item_transfer_2 = class({})

function master_item_transfer_2:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: items / TransferItem
	TransferItem({ caster = caster, ability = self, target = caster, Slot = 2 })
end
