--[[ Атрибуты Billy the Kid. Покупаются героем, платятся маной Мастера. Каждый
     ставит флаг hero.BillyAttrNAcquired, способности ветвятся по Billy_HasAttr
     (billy_shared). Игровые числа лежат в KV той способности, которую атрибут
     усиливает; в KV атрибута — копия для тултипа (как у cu_alter).
       1  Young Outlaw Leader    -> награда за голову цели из топ-бара (billy_wanted.lua)
       2  Quick Solver           -> Reload (F): скорость + срез КД
       3  Here Is an Old Trick   -> −КД Trickshot (Q), хедшот-стаки и крит
       4  Different Approach     -> Highnoon (R): Protection from Wind, уворот, слоу
       5  Natural Perception     -> Q: урон за ловкость, W: дым, R: −входящий урон ]]
require("abilities/billy/billy_shared")

billy_attribute_1 = class({})
billy_attribute_2 = class({})
billy_attribute_3 = class({})
billy_attribute_4 = class({})
billy_attribute_5 = class({})

local function acquire(self, n)
    local hero = self:GetCaster():GetPlayerOwner():GetAssignedHero()
    hero["BillyAttr" .. n .. "Acquired"] = true

    -- маску для клиента обновит думалка пуль; если герой жив — сразу
    if hero:IsAlive() then
        local m = hero:FindModifierByName("modifier_billy_attributes")
            or hero:AddNewModifier(hero, nil, "modifier_billy_attributes", {})
        if m then m:SetStackCount(Billy_AttrMask(hero)) end
    end

    local master = hero.MasterUnit
    if master then
        master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
    end
    return hero
end

function billy_attribute_1:OnSpellStart() Billy_WantedOnAcquire(acquire(self, 1)) end
function billy_attribute_2:OnSpellStart() acquire(self, 2) end
function billy_attribute_3:OnSpellStart() acquire(self, 3) end
function billy_attribute_4:OnSpellStart() acquire(self, 4) end
function billy_attribute_5:OnSpellStart() acquire(self, 5) end
