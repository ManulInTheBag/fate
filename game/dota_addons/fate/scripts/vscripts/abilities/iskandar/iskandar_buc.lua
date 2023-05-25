iskandar_buc = class({})

LinkLuaModifier("modifier_iskandar_buc", "abilities/iskandar/iskandar_buc", LUA_MODIFIER_MOTION_NONE)
function iskandar_buc:CastFilterResult()
	if self:GetCaster():HasModifier("modifier_iskandar_buc") then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end

function iskandar_buc:GetCustomCastError()
	return "Already Riding"
end

function iskandar_buc:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_iskandar_buc", {duration = self:GetSpecialValueFor("duration") })
	caster:EmitSound("Hero_Magnataur.Skewer.Cast")
    	caster:EmitSound("Hero_Zuus.GodsWrath")
    	caster:EmitSound("iskander_buc")
		local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(particle, 3, caster:GetAbsOrigin())
		local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    	ParticleManager:SetParticleControl(particle2, 1, caster:GetAbsOrigin())
    	local particle3 = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_thunder_strike_bolt.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    	ParticleManager:SetParticleControl(particle3, 0, caster:GetAbsOrigin())
    	ParticleManager:SetParticleControl(particle3, 1, caster:GetAbsOrigin())
   	 	ParticleManager:SetParticleControl(particle3, 2, caster:GetAbsOrigin())
		Timers:CreateTimer( 2.0, function()
			ParticleManager:DestroyParticle( particle, false )
			ParticleManager:ReleaseParticleIndex( particle )
			ParticleManager:DestroyParticle( particle2, false )
			ParticleManager:ReleaseParticleIndex( particle2 )
			ParticleManager:DestroyParticle( particle3, false )
			ParticleManager:ReleaseParticleIndex( particle3 )
		end)
		if caster:FindAbilityByName("iskander_jump"):IsHidden() then
			caster:SwapAbilities(self:GetName(), "iskander_jump", false, true) 
			caster:FindAbilityByName("iskander_jump"):EndCooldown()
		end
		
	
end


modifier_iskandar_buc = class({})



function modifier_iskandar_buc:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			 MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
			 
			 }
end

function modifier_iskandar_buc:GetModifierIgnoreMovespeedLimit()
	return 1
end



function modifier_iskandar_buc:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then        
        return self.Movespeed
    elseif IsClient() then
        local movespeed = CustomNetTables:GetTableValue("sync","iskandar_buc").movespeed
        return movespeed 
    end
end



function modifier_iskandar_buc:CheckState()
    local state = { [MODIFIER_STATE_UNSLOWABLE ] = true,
    	[MODIFIER_STATE_NO_UNIT_COLLISION] = true
                }
    return state
end



function modifier_iskandar_buc:OnCreated(args)
	self.Movespeed = 60
	if(IsServer() ) then
		CustomNetTables:SetTableValue("sync","iskandar_buc", {movespeed = self.Movespeed})
	end
	local ability = self:GetAbility()
	local caster = self:GetParent()
	--caster.OriginalModel = "models/sanya/sanya.vmdl"
	caster.IsRiding = true
	local counter = 0
	local duration = ability:GetSpecialValueFor("duration")
	local radius = ability:GetSpecialValueFor("radius")
	local damage = ability:GetSpecialValueFor("damage")
	if(IsServer()) then
		caster:SetModel("models/sanya/sanya_buc.vmdl")
		caster:SetOriginalModel("models/sanya/sanya_buc.vmdl")
		caster:SetModelScale(50)

	

		Timers:CreateTimer(0.0, function() 
			if caster.IsRiding and counter < 16 then 
				if(IsServer() ) then
					CustomNetTables:SetTableValue("sync","iskandar_buc", {movespeed = self.Movespeed})
				end
				if not caster:IsStunned() then
					local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		 			for k,v in pairs(targets) do
						DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
						v:EmitSound("Hero_Juggernaut.OmniSlash.Damage")
		 			end
				end
		 		counter = counter+1
		 		return 0.5
	 		else
		 		return
	 		end
 		end)
	end
		   

end

function modifier_iskandar_buc:OnDestroy()
	local caster = self:GetParent()
	local ability = self:GetAbility()
	caster.OriginalModel = "models/sanya/sanya.vmdl"
	caster.IsRiding = false
	if(IsServer()) then
		Timers:CreateTimer( 0.5, function()
			caster:SetModel("models/sanya/sanya.vmdl")
			caster:SetOriginalModel("models/sanya/sanya.vmdl")
			caster:SetModelScale(1)
		end)
		if  ability:IsHidden()   and caster.IsAOTKActive then
			caster:SwapAbilities(ability:GetName(), "iskander_jump", true, false) 
			caster:FindAbilityByName("iskander_jump"):EndCooldown()
		elseif not caster.IsAOTKActive  and  ability:IsHidden() then
			caster:SwapAbilities("iskandar_gordius_wheel", "iskander_jump", true, false) 
		end

	end
end
 

