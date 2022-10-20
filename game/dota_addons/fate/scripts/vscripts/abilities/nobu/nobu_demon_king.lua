nobu_demon_king_open = class({})
nobu_demon_king_close = class({})

nobu_dow = class({})
nobu_dogab = class({})
nobu_fool_of_owari = class({})
nobu_king_of_innovation = class({})

nobu_dow_passive = class({})

local tStandardAbilities = {
    "nobu_shot",
    "nobu_dash",
    "nobu_double_shots",
    "nobu_3000",
    
}
 

local tDemonKingAbilities = {
    "nobu_dow",
    "nobu_dogab",
    "nobu_fool_of_owari",
    "nobu_king_of_innovation",
}
function nobu_dow:OnSpellStart()
    local hCaster = self:GetCaster()
    hCaster:SwapAbilities(tStandardAbilities[1], tDemonKingAbilities[1], true, false)
    hCaster:SwapAbilities(tStandardAbilities[2], tDemonKingAbilities[2], true, false)
    if( hCaster:HasModifier("modifier_nobu_turnlock") ) then
        hCaster:SwapAbilities("nobu_double_shots_stop", tDemonKingAbilities[3], true, false)
    else
        hCaster:SwapAbilities(tStandardAbilities[3], tDemonKingAbilities[3], true, false)
    end
    
    hCaster:SwapAbilities(tStandardAbilities[4], tDemonKingAbilities[4], true, false)
  
    hCaster.ISDOW = true
    if(hCaster.Expanded) then
        hCaster:SwapAbilities("nobu_demon_king_close", "nobu_divinity_mark", false, true)
    else
        hCaster:SwapAbilities("nobu_demon_king_close", "nobu_dow_passive", false, true)
    end
end
function nobu_dogab:OnSpellStart()
    local hCaster = self:GetCaster()
    hCaster:SwapAbilities(tStandardAbilities[1], tDemonKingAbilities[1], true, false)
    hCaster:SwapAbilities(tStandardAbilities[2], tDemonKingAbilities[2], true, false)
    if( hCaster:HasModifier("modifier_nobu_turnlock") ) then
        hCaster:SwapAbilities("nobu_double_shots_stop", tDemonKingAbilities[3], true, false)
    else
        hCaster:SwapAbilities(tStandardAbilities[3], tDemonKingAbilities[3], true, false)
    end
    hCaster:SwapAbilities(tStandardAbilities[4], tDemonKingAbilities[4], true, false)
    hCaster:SwapAbilities("nobu_demon_king_close", "nobu_divinity_mark", false, true)
    if(hCaster.Expanded) then
        hCaster.isCharisma = true
    end
end
function nobu_fool_of_owari:OnSpellStart()
    local hCaster = self:GetCaster()
    hCaster:SwapAbilities(tStandardAbilities[1], tDemonKingAbilities[1], true, false)
    hCaster:SwapAbilities(tStandardAbilities[2], tDemonKingAbilities[2], true, false)
    if( hCaster:HasModifier("modifier_nobu_turnlock") ) then
        hCaster:SwapAbilities("nobu_double_shots_stop", tDemonKingAbilities[3], true, false)
    else
        hCaster:SwapAbilities(tStandardAbilities[3], tDemonKingAbilities[3], true, false)
    end
    hCaster:SwapAbilities(tStandardAbilities[4], tDemonKingAbilities[4], true, false)
   
    hCaster.isCharisma = true
    if(hCaster.Expanded) then
        hCaster:SwapAbilities("nobu_demon_king_close", "nobu_leader_of_innovation", false, true)
    else
        hCaster:SwapAbilities("nobu_demon_king_close", "nobu_charisma", false, true)
    end
end
function nobu_king_of_innovation:OnSpellStart()
    local hCaster = self:GetCaster()
    hCaster:SwapAbilities(tStandardAbilities[1], tDemonKingAbilities[1], true, false)
    hCaster:SwapAbilities(tStandardAbilities[2], tDemonKingAbilities[2], true, false)
    if( hCaster:HasModifier("modifier_nobu_turnlock") ) then
        hCaster:SwapAbilities("nobu_double_shots_stop", tDemonKingAbilities[3], true, false)
    else
        hCaster:SwapAbilities(tStandardAbilities[3], tDemonKingAbilities[3], true, false)
    end
    hCaster:SwapAbilities(tStandardAbilities[4], tDemonKingAbilities[4], true, false)
    hCaster:SwapAbilities("nobu_demon_king_close", "nobu_leader_of_innovation", false, true)
    if(hCaster.Expanded) then 
        hCaster.ISDOW = true
    end
end
 

function nobu_demon_king_open:OnSpellStart()
    local hCaster = self:GetCaster()
    hCaster:SwapAbilities(tStandardAbilities[1], tDemonKingAbilities[1], false, true)
    hCaster:SwapAbilities(tStandardAbilities[2], tDemonKingAbilities[2], false, true)
    if( hCaster:GetAbilityByIndex(2):GetName() ~= "nobu_double_shots" ) then
        hCaster:SwapAbilities("nobu_double_shots_stop", tDemonKingAbilities[3], false, true)
        print("1")
    else
        hCaster:SwapAbilities(tStandardAbilities[3], tDemonKingAbilities[3], false, true)
        print("11")
    end
    
    hCaster:SwapAbilities(tStandardAbilities[4], tDemonKingAbilities[4], false, true)
    
    hCaster:SwapAbilities("nobu_demon_king_close", "nobu_demon_king_open", true, false)
end
 
function nobu_demon_king_close:OnSpellStart()
    local hCaster = self:GetCaster()
    hCaster:SwapAbilities("nobu_demon_king_close", "nobu_demon_king_open", false, true)
    hCaster:SwapAbilities(tStandardAbilities[1], tDemonKingAbilities[1], true, false)
    hCaster:SwapAbilities(tStandardAbilities[2], tDemonKingAbilities[2], true, false)
    if( hCaster:HasModifier("modifier_nobu_turnlock") ) then
        hCaster:SwapAbilities("nobu_double_shots_stop", tDemonKingAbilities[3], true, false)
    else
        hCaster:SwapAbilities(tStandardAbilities[3], tDemonKingAbilities[3], true, false)
    end
    hCaster:SwapAbilities(tStandardAbilities[4], tDemonKingAbilities[4], true, false)
end

 
function nobu_dow:GetAbilityTextureName()
    if(self:GetCaster():HasModifier("modifier_nobu_expanding_attribute")) then
        return   "custom/nobu/nobu_option_1"
    else
        return   "custom/nobu/nobu_dow"
    end
end

function nobu_dogab:GetAbilityTextureName()
    if(self:GetCaster():HasModifier("modifier_nobu_expanding_attribute")) then
        return   "custom/nobu/nobu_option_2"
    else
        return   "custom/nobu/nobu_dogab"
    end
end

function nobu_fool_of_owari:GetAbilityTextureName()
    if(self:GetCaster():HasModifier("modifier_nobu_expanding_attribute")) then
        return   "custom/nobu/nobu_option_3"
    else
        return   "custom/nobu/nobu_fool_of_owari"
    end
end

function nobu_king_of_innovation:GetAbilityTextureName()
    if(self:GetCaster():HasModifier("modifier_nobu_expanding_attribute")) then
        return   "custom/nobu/nobu_option_4"
    else
        return   "custom/nobu/nobu_king_of_innovation"
    end
end
 