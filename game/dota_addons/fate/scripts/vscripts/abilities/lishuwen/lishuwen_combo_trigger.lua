lishuwen_combo_trigger = class({})

function lishuwen_combo_trigger:OnSpellStart()
	local caster = self:GetCaster()
	--local ability = self

	if caster:GetAbilityByIndex(2):GetName() == "lishuwen_tiger_strike" then
    	caster:SwapAbilities("lishuwen_raging_dragon_strike", "lishuwen_tiger_strike", true, false)
    	caster:SwapAbilities("lishuwen_combo_trigger", "lishuwen_cosmic_orbit", false, true)
    end
    
    Timers:CreateTimer('raging_dragon_timer',{
        endTime = 5,
        callback = function()
        if not caster.bIsCurrentDSCycleFinished and caster.bIsCurrentDSCycleStarted then
        	local abil = caster:FindAbilityByName("lishuwen_raging_dragon_strike")
        	local remainingCD = abil:GetCooldownTimeRemaining() 
		    abil:EndCooldown()
		    abil:StartCooldown(remainingCD * 0.25)
        	
        	local masterabil = caster.MasterUnit2:FindAbilityByName("lishuwen_raging_dragon_strike")
			masterabil:EndCooldown()
			masterabil:StartCooldown(masterabil:GetCooldown(1)*0.25)            	
        end	
		local currentAbil = caster:GetAbilityByIndex(2)	
		caster:SwapAbilities("lishuwen_tiger_strike",currentAbil:GetAbilityName() , true, false)
		caster.bIsCurrentDSCycleStarted = false
    end
    })
end