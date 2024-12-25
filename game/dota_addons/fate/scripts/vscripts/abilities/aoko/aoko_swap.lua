aoko_swap = class({})

local melee = {
    "aoko_shield",
    "aoko_facebreaker",
    "aoko_short_beam",
    "aoko_swap",
    "aoko_circuits",
    "aoko_intimidation",
    "attribute_bonus_custom"
}

local range = {
    "aoko_jumpback",
    "aoko_sphere",
    "aoko_lazers",
    "aoko_swap",
    "aoko_circuits",
    "aoko_3_beams",
    "attribute_bonus_custom"
}

function aoko_swap:OnSpellStart()
    local caster = self:GetCaster()
    
    if not self.form then
    	self.form = 1
    end

    if self.form == 1 then
    	UpdateAbilityLayout(caster, range)
    	self.form = 2
    else
    	UpdateAbilityLayout(caster, melee)
    	self.form = 1
    end
end