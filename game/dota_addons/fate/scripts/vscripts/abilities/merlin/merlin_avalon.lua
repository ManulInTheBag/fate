LinkLuaModifier("modifier_merlin_avalon","abilities/merlin/merlin_avalon", LUA_MODIFIER_MOTION_NONE)
merlin_avalon = class({})
 

function merlin_avalon:OnSpellStart()
    local caster = self:GetCaster()
	HardCleanse(caster)
	self.flowers_fx = ParticleManager:CreateParticle("particles/merlin/merlin_avalon_flowers.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(self.flowers_fx, 0, caster:GetAbsOrigin()     ) 
	caster:AddNewModifier(caster, self, "modifier_merlin_avalon", { Duration =  self:GetSpecialValueFor("duration")})
	caster:FindAbilityByName("merlin_charisma"):AttStack() 
 	caster:SwapAbilities("merlin_avalon", "merlin_avalon_release", false, true)
	 Timers:CreateTimer(1.5, function()   
		if(caster:GetAbilityByIndex(3):GetName()~= "merlin_avalon") then
			caster:SwapAbilities("merlin_avalon", "merlin_avalon_release", true, false)
		end

	 end)
	 caster:AddEffects(EF_NODRAW)
	 caster:Stop()
	 if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then      
    	if caster:FindAbilityByName("merlin_garden_of_avalon"):IsCooldownReady()  then
             
    		caster:SwapAbilities("merlin_garden_of_avalon", "merlin_illusion", true, false)

    		Timers:CreateTimer('merlin_trigger_window',{
		        endTime = 1,
		        callback = function()
		        if caster:GetAbilityByIndex(2):GetName() ~= "merlin_illusion"  then
					caster:SwapAbilities("merlin_garden_of_avalon", "merlin_illusion", false, true)
		       	end
		    end
		    })
 
        end
    end
 
end

modifier_merlin_avalon = class({})

function modifier_merlin_avalon:CheckState()
    local state =   { 
					[MODIFIER_STATE_UNSELECTABLE] = true,
					[MODIFIER_STATE_INVULNERABLE] = true,
					[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
					[MODIFIER_STATE_NO_HEALTH_BAR] = true,
					[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
					[MODIFIER_STATE_STUNNED] = true,
                    }
    return state
end


function modifier_merlin_avalon:OnDestroy()
 if(IsServer()) then
	local caster = self:GetCaster()
	if(self:GetAbility().flowers_fx ~= nil) then 
		ParticleManager:DestroyParticle(self:GetAbility().flowers_fx, true)
		ParticleManager:ReleaseParticleIndex(self:GetAbility().flowers_fx) 
	end
	if(caster:GetAbilityByIndex(3):GetName()~= "merlin_avalon") then
		caster:SwapAbilities("merlin_avalon", "merlin_avalon_release", true, false)
	end
	caster:RemoveEffects(EF_NODRAW)
 end
end
 
function modifier_merlin_avalon:IsHidden() return false end
function modifier_merlin_avalon:RemoveOnDeath() return true end