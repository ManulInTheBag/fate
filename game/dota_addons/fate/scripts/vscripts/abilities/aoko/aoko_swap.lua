aoko_swap = class({})

local ying = {
    "aoko_beam",
    "aoko_punch",
    "aoko_jumpback",
    "aoko_swap",
    "fate_empty1",
    "aoko_dailin",
    "attribute_bonus_custom"
}

local yang = {
    "aoko_beam",
    "aoko_sphere",
    "aoko_lazers",
    "aoko_swap",
    "fate_empty1",
    "aoko_dailin",
    "attribute_bonus_custom"
}

function aoko_swap:OnSpellStart()
    local caster = self:GetCaster()
    
    if not self.form then
    	self.form = 1
    end

    if self.form == 1 then
    	UpdateAbilityLayout(caster, yang)
    	self.form = 2
    else
    	UpdateAbilityLayout(caster, ying)
    	self.form = 1
    end
end