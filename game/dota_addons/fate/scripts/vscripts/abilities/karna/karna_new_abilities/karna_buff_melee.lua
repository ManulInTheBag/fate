karna_buff_melee = class({})

LinkLuaModifier("modifier_karna_buff_melee", "abilities/karna/karna_new_abilities/karna_buff_melee", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_karna_melee_buff_burn", "abilities/karna/karna_new_abilities/karna_buff_melee", LUA_MODIFIER_MOTION_NONE)
function karna_buff_melee:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("karna_brahmastra_kundala_new"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("karna_brahmastra_kundala_new"):SetLevel(self:GetLevel())
    end

end

function karna_buff_melee:CastFilterResult()
    local caster = self:GetCaster()
    if IsServer() and  (caster:FindModifierByName("modifier_karna_self_pause") or caster:FindModifierByName("modifier_karna_self_pause_2")) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function karna_buff_melee:GetCustomCastError()
	return "Performing other ability"
end
function karna_buff_melee:ApplyBurnStacks(target)
	local caster = self:GetCaster()
	local stacks = 0

	if not target or not target:IsAlive() or target:IsNull() then return end

	if target:HasModifier("modifier_karna_melee_buff_burn") then
		stacks = target:FindModifierByName("modifier_karna_melee_buff_burn"):GetStackCount()
	end
	if target:GetName() == "npc_dota_hero_nevermore" then
		target:FindAbilityByName("demon_king_materialization"):ProckSpellAmpBonus()
	end

	target:AddNewModifier(caster, self, "modifier_karna_melee_buff_burn", {duration = self:GetSpecialValueFor("burn_duration")})
	target:FindModifierByName("modifier_karna_melee_buff_burn"):SetStackCount(stacks + 1)

end
function karna_buff_melee:OnSpellStart()
	local caster = self:GetCaster()
		caster:EmitSound("karna_new_fire_1")
		caster:EmitSound("karna_new_karna_buff_voice")
	if (self.fx) then	
		ParticleManager:DestroyParticle( self.fx, true )
		ParticleManager:ReleaseParticleIndex( self.fx )
		Timers:RemoveTimer("karna_buff_melee_fx")
	end
	self.fx = ParticleManager:CreateParticle("particles/karna/karna_test_jopa_main.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
    ParticleManager:SetParticleControlEnt(self.fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_weapon_base", caster:GetAbsOrigin(), false )
	ParticleManager:SetParticleControlEnt(self.fx, 1, caster, PATTACH_POINT_FOLLOW, "attach_weapon_end", caster:GetAbsOrigin(), false )
	local armor_modifier = caster:FindModifierByName("modifier_karna_armor")
	armor_modifier:RestoreArmorPercentage(self:GetSpecialValueFor("armor_restore_percentage"))
	caster:EmitSound("Hero_EmberSpirit.FireRemnant.Cast")
	local lightFx1 = ParticleManager:CreateParticle("particles/karna/karna_buff_activation.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( lightFx1, 0, caster:GetAbsOrigin())
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( lightFx1, false )
		ParticleManager:ReleaseParticleIndex( lightFx1 )
	end)	

	caster:AddNewModifier(caster, self, "modifier_karna_buff_melee", { Duration = self:GetSpecialValueFor("duration"),
																		 MovespeedBonus = self:GetSpecialValueFor("movespeed_bonus"),
																		 Damage = self:GetSpecialValueFor("damage"),
	})	
 
	Timers:CreateTimer("karna_buff_melee_fx", {
		endTime =  self:GetSpecialValueFor("duration"),
		callback = function()
			ParticleManager:DestroyParticle( self.fx, false )
			ParticleManager:ReleaseParticleIndex( self.fx )
			self.fx2  = ParticleManager:CreateParticle("particles/karna/karna_spear_buff_endcap.vpcf", PATTACH_POINT_FOLLOW , caster )
			ParticleManager:SetParticleControlEnt(self.fx2, 0, caster, PATTACH_POINT_FOLLOW, "attach_weapon_base", caster:GetOrigin(), true)
			ParticleManager:SetParticleControlEnt(self.fx2, 1, caster, PATTACH_POINT_FOLLOW, "attach_weapon_end", caster:GetOrigin(), true)
	return end
	})
end

modifier_karna_buff_melee = class({})

function modifier_karna_buff_melee:DeclareFunctions() 
	local funcs = { MODIFIER_EVENT_ON_ATTACK_LANDED, 
				    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
				} 
    return funcs
end

if IsServer() then
	function modifier_karna_buff_melee:OnRefresh(args)
		self:OnCreated(args)
	end

	function modifier_karna_buff_melee:OnCreated(args)
		self.MovespeedBonus = args.MovespeedBonus
		self.Damage = args.Damage

		CustomNetTables:SetTableValue("sync","karna_buff_melee_stats", { movespeed_bonus = self.MovespeedBonus })
	end

	function modifier_karna_buff_melee:OnAttackLanded(args)	
		if args.attacker ~= self:GetParent() then return end

		local caster = self:GetParent()
		local target = args.target
		local ability = self:GetAbility()

		if not target:HasModifier("modifier_master_intervention") then
			DoDamage(caster, target, self.Damage, self:GetParent():FindAbilityByName("karna_buff_melee"):GetAbilityDamageType(), 0, ability, false)
			ability:ApplyBurnStacks(target)
			--target:AddNewModifier(caster, target, "modifier_stunned", {Duration = self.StunDuration})
		end
		 
	end
end

 

function modifier_karna_buff_melee:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then		
	 	return self.MovespeedBonus
 	elseif IsClient() then
 		local movespeed_bonus = CustomNetTables:GetTableValue("sync","karna_buff_melee_stats").movespeed_bonus
 		return movespeed_bonus 
 	end
end

-----------------------------------------------------------------------------------

function modifier_karna_buff_melee:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


function modifier_karna_buff_melee:IsDebuff()
    return false
end

function modifier_karna_buff_melee:RemoveOnDeath()
    return true
end

function modifier_karna_buff_melee:GetTexture()
    return "custom/karna/karna_buff_melee"
end

-----------------------------------------------------------------------------------
modifier_karna_melee_buff_burn = class({})
function modifier_karna_melee_buff_burn:GetEffectName()
    return "particles/karna/karna_buff_burn.vpcf"
end
function modifier_karna_melee_buff_burn:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
function modifier_karna_melee_buff_burn:IsDebuff() return true end
function modifier_karna_melee_buff_burn:OnCreated(args)
	self.caster = self:GetCaster()
	self.target = self:GetParent()
	self.damage_per_stack = self:GetAbility():GetSpecialValueFor("burn_damage_per_stack")
    self:StartIntervalThink(0.5)
end
function modifier_karna_melee_buff_burn:OnRefresh(args)

end
function modifier_karna_melee_buff_burn:OnIntervalThink()
    if(not IsServer() ) then return end

    DoDamage(self.caster, self.target, self.damage_per_stack * self:GetStackCount(), self.caster:FindAbilityByName("karna_buff_melee"):GetAbilityDamageType(), 0, self:GetAbility(), false)
	if self.target:GetName() == "npc_dota_hero_nevermore" then
		self.target:FindAbilityByName("demon_king_materialization"):ProckSpellAmpBonus()
	end


end
