sanya_book_open = class({})
sanya_book_close = class({})


function sanya_book_open:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self

    if caster:FindAbilityByName("iskander_phalanx"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("iskander_phalanx"):SetLevel(self:GetLevel())
    end
    if caster:FindAbilityByName("iskander_archers"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("iskander_archers"):SetLevel(self:GetLevel())
    end
    if caster:FindAbilityByName("iskander_cavalry"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("iskander_cavalry"):SetLevel(self:GetLevel())
    end

end


local tStandardAbilities = {
    "iskander_forward",
    "iskander_thunder",
    "sanya_book_open",
    "iskandar_charisma",
    
}

local tStandardAbilitiyMarbleWithSa = {
    "iskander_forward",
    "iskander_thunder",
    "sanya_book_open",
    "iskander_summon_waver",
    
}
 

local tSanyaBook = {
    "iskander_phalanx",
    "iskander_archers",
    "sanya_book_close",
    "iskander_cavalry",
}

function sanya_book_open:OnSpellStart()
    local hCaster = self:GetCaster()
    if hCaster.IsAOTKActive == true and hCaster.IsBeyondTimeAcquired then
        self:OpenSpellbookMarble()
    else
        self:OpenSpellbook()
    end
end

function sanya_book_open:OpenSpellbook()
    local hCaster = self:GetCaster()
    hCaster:SwapAbilities(tStandardAbilities[1], tSanyaBook[1], false, true)
    hCaster:SwapAbilities(tStandardAbilities[2], tSanyaBook[2], false, true)
    hCaster:SwapAbilities(tStandardAbilities[3], tSanyaBook[3], false, true)
    hCaster:SwapAbilities(tStandardAbilities[4], tSanyaBook[4], false, true)

end
function sanya_book_open:OpenSpellbookMarble()
    local hCaster = self:GetCaster()
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[1], tSanyaBook[1], false, true)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[2], tSanyaBook[2], false, true)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[3], tSanyaBook[3], false, true)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[4], tSanyaBook[4], false, true)

end

function sanya_book_close:OnSpellStart()
    local hCaster = self:GetCaster()
    if hCaster.IsAOTKActive == true and hCaster.IsBeyondTimeAcquired then
        self:CloseSpellbookMarble()
    else
        self:CloseSpellbook()
    end
end

function sanya_book_close:CloseSpellbook()
    local hCaster = self:GetCaster()
    hCaster:SwapAbilities(tStandardAbilities[1], tSanyaBook[1], true, false)
    hCaster:SwapAbilities(tStandardAbilities[2], tSanyaBook[2], true, false)
    hCaster:SwapAbilities(tStandardAbilities[3], tSanyaBook[3], true, false)
    hCaster:SwapAbilities(tStandardAbilities[4], tSanyaBook[4], true, false)

end
 
function sanya_book_close:CloseSpellbookMarble()
    local hCaster = self:GetCaster()
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[1], tSanyaBook[1], true, false)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[2], tSanyaBook[2], true, false)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[3], tSanyaBook[3], true, false)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[4], tSanyaBook[4], true, false)

end