lishuwen_cosmic_orbit = class({})

LinkLuaModifier("modifier_cosmic_orbit", "abilities/lishuwen/modifiers/modifier_cosmic_orbit", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_lishuwen_combo_seq", "abilities/lishuwen/modifiers/modifier_lishuwen_combo_seq", LUA_MODIFIER_MOTION_NONE)

function lishuwen_cosmic_orbit:GetTexture()
	return "custom/lishuwen_cosmic_orbit"
end

function lishuwen_cosmic_orbit:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self	


	ProjectileManager:ProjectileDodge(caster)
	--if not self:CheckCombo() then
	caster:EmitSound("Hero_Sven.WarCry")
	caster:AddNewModifier(caster, ability, "modifier_cosmic_orbit", { Duration = self:GetSpecialValueFor("duration"),
																   Stacks = self:GetSpecialValueFor("number_of_attacks"),
																   AttackSpeedBonus = self:GetSpecialValueFor("attack_speed"),
																   BonusDamage = self:GetSpecialValueFor("damage"),
																   MovespeedDuration = self:GetSpecialValueFor("movespeed_duration"),
																   DamageType = DAMAGE_TYPE_MAGICAL
																   })

	self:CheckCombo()
	--else
		--self:EndCooldown()
		--caster:GiveMana(self:GetManaCost(self:GetLevel()))
	--end	
end

function lishuwen_cosmic_orbit:CheckCombo()
	local caster = self:GetCaster()
	local ability = self
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then      
    	if caster:FindAbilityByName("lishuwen_raging_dragon_strike"):IsCooldownReady() 
    		and caster:FindAbilityByName("lishuwen_tiger_strike"):IsCooldownReady() 
    		and not caster:HasModifier("modifier_tiger_strike_tracker") then

    		caster:SwapAbilities("lishuwen_combo_trigger", "lishuwen_cosmic_orbit", true, false)

    		Timers:CreateTimer('dragon_trigger_window',{
		        endTime = 2,
		        callback = function()
		        if caster:GetAbilityByIndex(1):GetName() ~= "lishuwen_cosmic_orbit" then
		       		caster:SwapAbilities("lishuwen_combo_trigger", "lishuwen_cosmic_orbit", false, true)
		       	end
		    end
		    })


    		--[[if not caster:HasModifier("modifier_lishuwen_combo_seq") then
    			caster:AddNewModifier(caster, self, "modifier_lishuwen_combo_seq", {Duration = 5})
    			self:EndCooldown()
    			caster:GiveMana(self:GetManaCost(self:GetLevel()))
    			return false
    		end]]

    		
            --return true
        end
    end

    --return false
end