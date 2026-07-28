require("abilities/barghest/barghest_shared")

barghest_e_release = class({})

--[[ Кнопка «отпустить рывок». Пока Barghest заряжает Chain Hunt, она подменяет
     собой E; нажатие снимает зарядку, а сам рывок пускает OnDestroy модификатора
     зарядки — так одинаково обрабатываются и ранний сброс, и истечение времени.
     Скрытая, ненаращиваемая, игнорирует сайленс (иначе из зарядки не выйти).
]]

function barghest_e_release:OnSpellStart()
    if not IsServer() then return end
    local hCaster = self:GetCaster()
    hCaster:RemoveModifierByName("modifier_barghest_e_charge")
end
