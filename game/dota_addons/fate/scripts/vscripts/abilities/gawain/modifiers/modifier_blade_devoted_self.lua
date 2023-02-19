modifier_blade_devoted_self = class({})

function modifier_blade_devoted_self:DeclareFunctions() 
	local funcs = { --MODIFIER_EVENT_ON_ATTACK_LANDED, 
				    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
				    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
				} 
    return funcs
end

if IsServer() then
	function modifier_blade_devoted_self:OnRefresh(args)
		self:OnCreated(args)
	end

	function modifier_blade_devoted_self:OnCreated(args)
		self.MovespeedBonus = args.MovespeedBonus
		self.StunDuration = args.StunDuration
		self.Damage = args.Damage
		self.SubDamage = args.SubDamage
		self.FirstHit = true

		CustomNetTables:SetTableValue("sync","blade_devoted_stats", { bonus_damage = self.SubDamage,
																	  movespeed_bonus = self.MovespeedBonus })
	end

	function modifier_blade_devoted_self:OnAttackLanded(args)	
		if args.attacker ~= self:GetParent() then return end

		local caster = self:GetParent()
		local target = args.target
		local ability = caster:FindAbilityByName("gawain_blade_of_the_devoted")
		
		if not target:IsMagicImmune() and not target:HasModifier("modifier_master_intervention") then
	        		    target:AddNewModifier(caster, target, "modifier_stunned", {Duration = self.StunDuration})
	    end

		if caster.IsBeltAcquired then
			local aoeTargets = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, 250, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

	        for k, v in pairs(aoeTargets) do
	        	if v ~= target then
	        		DoDamage(caster, v, self.Damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	        		if not target:IsMagicImmune() and not target:HasModifier("modifier_master_intervention") then
	        		    target:AddNewModifier(caster, target, "modifier_stunned", {Duration = self.StunDuration})
	        		end
	        	end
	        end
	        
	        local cooldown = ability:GetCooldownTimeRemaining()
	        ability:EndCooldown()

	        if cooldown - 1 > 0 then	        	
	        	ability:StartCooldown(math.max(1, cooldown))
	        end	        
		end

		if self.FirstHit then
			local soundQueue = math.random(1,3)
			target:EmitSound("Hero_Invoker.ColdSnap")
			caster:EmitSound("Gawain_Attack" .. soundQueue)
			DoDamage(caster, target, self.Damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			local sunAbility = caster:FindAbilityByName("gawain_artificial_sun")
			sunAbility:GenerateArtificialSun(caster, target:GetAbsOrigin(), true, ability:GetName())
			self.Damage = self.SubDamage
			self.StunDuration = 0.01
			self.FirstHit = false
		else
			target:EmitSound("Hero_Invoker.ColdSnap.Freeze")
		end	
		
		local lightFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_sun_strike_beam.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
		ParticleManager:SetParticleControl( lightFx1, 0, target:GetAbsOrigin())
		local flameFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_fire_spirit_ground.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
		ParticleManager:SetParticleControl( flameFx1, 0, target:GetAbsOrigin())
		Timers:CreateTimer( 2.0, function()
			ParticleManager:DestroyParticle( lightFx1, false )
			ParticleManager:ReleaseParticleIndex( lightFx1 )
			ParticleManager:DestroyParticle( flameFx1, false )
			ParticleManager:ReleaseParticleIndex( flameFx1 )
		end)
	end
end

function modifier_blade_devoted_self:GetModifierPreAttack_BonusDamage()
	if IsServer() then
	 	return self.SubDamage
 	elseif IsClient() then
 		local bonus_damage = CustomNetTables:GetTableValue("sync","blade_devoted_stats").bonus_damage
 		return bonus_damage 
 	end
end

function modifier_blade_devoted_self:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then		
	 	return self.MovespeedBonus
 	elseif IsClient() then
 		local movespeed_bonus = CustomNetTables:GetTableValue("sync","blade_devoted_stats").movespeed_bonus
 		return movespeed_bonus 
 	end
end

-----------------------------------------------------------------------------------

function modifier_blade_devoted_self:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_blade_devoted_self:IsPurgable()
    return true
end

function modifier_blade_devoted_self:IsDebuff()
    return false
end

function modifier_blade_devoted_self:RemoveOnDeath()
    return true
end

function modifier_blade_devoted_self:GetTexture()
    return "custom/gawain_blade_of_the_devoted"
end

-----------------------------------------------------------------------------------
