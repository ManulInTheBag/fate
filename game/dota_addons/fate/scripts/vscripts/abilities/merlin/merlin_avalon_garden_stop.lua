 
merlin_avalon_garden_stop = class({})
 

function merlin_avalon_garden_stop:OnSpellStart()
    local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_merlin_avalon_self")
	StartAnimation(caster, {duration=  0.05, activity=ACT_DOTA_CAST_ABILITY_7, rate=1 })
	StopGlobalSound("avalon_flowers") 
	if caster:HasModifier("modifier_hero_selection_skin") then
		caster:SetBodygroup(0, 0)
		caster:SetModelScale(1.1)
	end
end

 