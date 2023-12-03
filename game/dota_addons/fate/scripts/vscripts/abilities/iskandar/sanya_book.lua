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

function sanya_book_open:GetCustomCastError()
	return "Stop it please"
end

function sanya_book_open:CastFilterResult()
	local caster = self:GetCaster()
	
	if caster:HasModifier("pause_sealdisabled") then
		return UF_FAIL_CUSTOM
	end

	return UF_SUCCESS
end



local tStandardAbilities = {
    "iskander_thunder",
    "sanya_book_open",
    "iskandar_charisma",
    "fate_empty1",
    
}

local tStandardAbilitiyMarbleWithSa = {
    "iskander_thunder",
    "sanya_book_open",
    "iskander_summon_waver",
    "iskander_summon_hephaestion",
    
}
local tStandardAbilitiyMarbleNoSa = {
    "iskander_thunder",
    "sanya_book_open",
    "iskandar_charisma",
    "iskander_summon_hephaestion",
    
}
  

local tSanyaBook = {
    "iskander_phalanx",
    "iskander_archers",
    "iskander_cavalry",
    "sanya_book_close",
}

function sanya_book_open:OnSpellStart()
    local hCaster = self:GetCaster()
    if hCaster.IsAOTKActive == true and hCaster.IsBeyondTimeAcquired then
        self:OpenSpellbookMarbleSA()
    elseif hCaster.IsAOTKActive == true then
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
    if hCaster:GetAbilityByIndex(4):GetName() == "iskander_ionioi" then
        hCaster:SwapAbilities("iskander_ionioi", tSanyaBook[4], false, true)
    else
        hCaster:SwapAbilities(tStandardAbilities[4], tSanyaBook[4], false, true)
    end
    

end
function sanya_book_open:OpenSpellbookMarble()
    local hCaster = self:GetCaster()
    hCaster:SwapAbilities(tStandardAbilitiyMarbleNoSa[1], tSanyaBook[1], false, true)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleNoSa[2], tSanyaBook[2], false, true)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleNoSa[3], tSanyaBook[3], false, true)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleNoSa[4], tSanyaBook[4], false, true)

end

function sanya_book_open:OpenSpellbookMarbleSA()
    local hCaster = self:GetCaster()
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[1], tSanyaBook[1], false, true)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[2], tSanyaBook[2], false, true)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[3], tSanyaBook[3], false, true)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[4], tSanyaBook[4], false, true)

end

function sanya_book_close:OnSpellStart()
    local hCaster = self:GetCaster()
    if hCaster.IsAOTKActive == true and hCaster.IsBeyondTimeAcquired then
        self:CloseSpellbookMarbleSA()
    elseif hCaster.IsAOTKActive == true then
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
 
function sanya_book_close:CloseSpellbookMarbleSA()
    local hCaster = self:GetCaster()
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[1], tSanyaBook[1], true, false)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[2], tSanyaBook[2], true, false)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[3], tSanyaBook[3], true, false)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleWithSa[4], tSanyaBook[4], true, false)

end

function sanya_book_close:CloseSpellbookMarble()
    local hCaster = self:GetCaster()
    hCaster:SwapAbilities(tStandardAbilitiyMarbleNoSa[1], tSanyaBook[1], true, false)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleNoSa[2], tSanyaBook[2], true, false)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleNoSa[3], tSanyaBook[3], true, false)
    hCaster:SwapAbilities(tStandardAbilitiyMarbleNoSa[4], tSanyaBook[4], true, false)

end