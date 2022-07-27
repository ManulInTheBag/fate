 
merlin_avalon_garden_stop = class({})
 

function merlin_avalon_garden_stop:OnSpellStart()
    local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_merlin_avalon_self")
	StartAnimation(caster, {duration=  0.05, activity=ACT_DOTA_CAST_ABILITY_7, rate=1 })
	StopGlobalSound("avalon_flowers") 
end

 