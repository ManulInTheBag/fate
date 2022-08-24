muramasa_dance_stop = class({})
 

 

 
muramasa_dance_stop = class({})
 

function muramasa_dance_stop:OnSpellStart()
    local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_merlin_self_pause")
	caster:SwapAbilities("muramasa_dance", "muramasa_dance_stop", true, false)
	local attackscompleted
	if(caster.lastdance == false) then 
		  attackscompleted = caster:FindAbilityByName("muramasa_dance_upgraded").attacks_completed
	else
		  attackscompleted = caster:FindAbilityByName("muramasa_dance").attacks_completed
	end
	if(attackscompleted < 2) then
		Timers:RemoveTimer("muramasa_attack_1")
	end
	if( attackscompleted < 3) then
		Timers:RemoveTimer("muramasa_attack_2")
	end
	if( attackscompleted < 4) then
		Timers:RemoveTimer("muramasa_attack_3")
	end
	if( attackscompleted < 5) then
		Timers:RemoveTimer("muramasa_attack_4")
	end
end

 