require("abilities/barghest/barghest_shared")

--[[ Атрибуты Barghest.

     ⚠️ Кастует их МАСТЕР, а не сам Слуга: способности выдаются мастеру в
     AddMasterAbility -> LoopThroughAttr (master_ability.lua), и мана списывается
     из его пула. Поэтому герой берётся через владельца, а не через GetCaster.

     Каждый атрибут только поднимает флаг на герое — эффект читают сами
     способности. Так же сделано у cu_alter (`CuAlterAttrNAcquired`).

       1  Hound's Wake      -> удары связки оставляют послеобразы чёрного пса
                               (ЗАГОТОВКА: флаг есть, эффекта нет)
       2  Blood of the Beast-> поднимает пассивку F до 2 уровня (РАБОТАЕТ)
       3  Galatine's Ember  -> дот горения с веток R, прибавка ко ВСЕМ веткам
                               от силы героя, и ветки R заряжаются даже с
                               промаха (РАБОТАЕТ)
       4  Fang Unbound      -> рывок E скейлится от силы, стан цепей не короче
                               chain_stun_min (РАБОТАЕТ, будет дописан)

     ⚠️ Флаг живёт на ГЕРОЕ, а не на способности: способность у мастера, а
     читать её будут скиллы Слуги. Имена флагов менять нельзя, не поправив
     чтение в barghest_q / barghest_r / barghest_f.
]]

barghest_attribute_1 = class({})
barghest_attribute_2 = class({})
barghest_attribute_3 = class({})
barghest_attribute_4 = class({})

--[[ Поднять флаг на герое и списать цену с маны Мастера. ]]
local function Acquire(self, sFlag)
    local hOwner = self:GetCaster():GetPlayerOwner()
    if hOwner == nil then return nil end
    local hHero = hOwner:GetAssignedHero()
    if not Barghest_Alive(hHero) then return nil end

    hHero[sFlag] = true

    local hMaster = hHero.MasterUnit
    if hMaster then
        hMaster:SetMana(hMaster:GetMana() - self:GetManaCost(self:GetLevel()))
    end
    return hHero
end

-- 1 — послеобразы чёрного пса на ударах связки: бегут на цель со случайной
-- стороны и кусают на hound_str_pct % от силы героя. Читается в barghest_q.
function barghest_attribute_1:OnSpellStart()
    Acquire(self, "BarghestAttr1Acquired")
end

-- 2 — усиление пассивки: Blood of the Beast уходит на 2 уровень, где у неё
-- свои числа (см. AbilityValues у barghest_f). Работает целиком здесь.
function barghest_attribute_2:OnSpellStart()
    local hHero = Acquire(self, "BarghestAttr2Acquired")
    if hHero == nil then return end
    local hF = hHero:FindAbilityByName("barghest_f")
    if Barghest_Alive(hF) then
        hF:SetLevel(2)
    end
end

-- 3 — дот горения с веток R, прибавка ко всем веткам от силы и зарядка
-- продолжения даже с промаха. Всё читается в barghest_r / barghest_shared.
function barghest_attribute_3:OnSpellStart()
    Acquire(self, "BarghestAttr3Acquired")
end

-- 4 — рывок E: урон от силы и пол длительности цепей. Читается в barghest_e.
-- TODO: сюда допишем остальные эффекты, когда договорим состав атрибута.
function barghest_attribute_4:OnSpellStart()
    Acquire(self, "BarghestAttr4Acquired")
end
