LinkLuaModifier("modifier_khsn_mde", "abilities/kinghassan/khsn_mde", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_mde_active", "abilities/kinghassan/khsn_mde", LUA_MODIFIER_MOTION_NONE)

khsn_mde = class({})

function khsn_mde:GetIntrinsicModifierName() return "modifier_khsn_mde" end
function khsn_mde:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_khsn_mde_active", {duration = self:GetSpecialValueFor("duration")})
	caster:EmitSound("Hero_Necrolyte.SpiritForm.Cast")
	--caster:Heal(self:GetSpecialValueFor("heal"), caster)
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then		
		if caster:FindAbilityByName("khsn_azrael"):IsCooldownReady() 
			and caster:FindAbilityByName("khsn_combo"):IsCooldownReady()  
	    	and caster:GetAbilityByIndex(5):GetName() == "khsn_azrael" then
			caster:SwapAbilities("khsn_mde", "khsn_mde_end", false, true)
			Timers:CreateTimer(3, function()
				if caster:GetAbilityByIndex(1):GetName() ~= "khsn_mde" then
					caster:SwapAbilities("khsn_mde", "khsn_mde_end", true, false)
				end
			end)
		end
	end
end

khsn_mde_end = class({})

function khsn_mde_end:OnSpellStart()
	local caster = self:GetCaster()
	caster:SwapAbilities("khsn_azrael", "khsn_combo", false, true)
	caster:SwapAbilities("khsn_mde_end", "khsn_mde", false, true)
	Timers:CreateTimer(3, function()
		caster:SwapAbilities("khsn_azrael", "khsn_combo", true, false)
	end)
end

modifier_khsn_mde = class({})

function modifier_khsn_mde:IsHidden() 
	return true
end

function modifier_khsn_mde:IsPermanent()
	return true
end

function modifier_khsn_mde:RemoveOnDeath()
	return false
end

function modifier_khsn_mde:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_khsn_mde:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
end

function modifier_khsn_mde:DeclareFunctions()
	return {	--MODIFIER_EVENT_ON_ATTACK_LANDED
		}
end

function modifier_khsn_mde:OnAttackLanded(args)
	if args.attacker ~= self.parent then return end

	local attacker = args.attacker
	local target = args.target
	local damage = self.ability:GetSpecialValueFor("damage_percent")/100*target:GetMaxHealth()

	DoDamage(self.parent, target, damage, self.parent.BoundaryAcquired and DAMAGE_TYPE_PURE or DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
end

modifier_khsn_mde_active = class({})

--[[function modifier_khsn_mde_active:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE]	= true,
		[MODIFIER_STATE_DISARMED]		= true
	}
end]]

function modifier_khsn_mde_active:OnCreated()
	self.parent = self:GetParent()
	if self.parent.PresenceAcquired then
		self:StartIntervalThink(1)
		local enemies2 = FindUnitsInRadius(  self.parent:GetTeamNumber(),
                                            self.parent:GetAbsOrigin(), 
                                            nil, 
                                            self:GetAbility():GetSpecialValueFor("attr_radius"), 
                                            DOTA_UNIT_TARGET_TEAM_ENEMY, 
                                            DOTA_UNIT_TARGET_ALL, 
                                            0, 
                                            FIND_ANY_ORDER, 
                                            false)
		for _,enemy in ipairs(enemies2) do
			DoDamage(self.parent, enemy, self:GetAbility():GetSpecialValueFor("attr_dps"), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
	    end
	end
	--[[if self.parent:GetAbilityByIndex(1):GetName() ~= "khsn_mde_end" then
		self.parent:SwapAbilities("khsn_mde", "khsn_mde_end", false, true)
	end]]
end

function modifier_khsn_mde_active:OnDestroy()
	--[[if self.parent:GetAbilityByIndex(1):GetName() ~= "khsn_mde" then
		self.parent:SwapAbilities("khsn_mde", "khsn_mde_end", true, false)
	end]]
end

function modifier_khsn_mde_active:OnIntervalThink()
	local enemies2 = FindUnitsInRadius(  self.parent:GetTeamNumber(),
                                            self.parent:GetAbsOrigin(), 
                                            nil, 
                                            self:GetAbility():GetSpecialValueFor("attr_radius"), 
                                            DOTA_UNIT_TARGET_TEAM_ENEMY, 
                                            DOTA_UNIT_TARGET_ALL, 
                                            0, 
                                            FIND_ANY_ORDER, 
                                            false)
	for _,enemy in ipairs(enemies2) do
		DoDamage(self.parent, enemy, self:GetAbility():GetSpecialValueFor("attr_dps"), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
    end
end

function modifier_khsn_mde_active:IsHidden() return false end
function modifier_khsn_mde_active:IsDebuff() return false end

function modifier_khsn_mde_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		--MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		--MODIFIER_PROPERTY_OVERRIDE_ANIMATION
	}
end

--[[function modifier_khsn_mde_active:GetOverrideAnimation()
    return ACT_DOTA_CAST_ABILITY_2
end]]

function modifier_khsn_mde_active:GetModifierConstantHealthRegen()
	local regen = (self:GetAbility():GetSpecialValueFor("hp_regen") + (self:GetCaster().BattleContinuationAcquired and 40 or 0))
	return regen
end

function modifier_khsn_mde_active:GetModifierPhysicalArmorBonus()
	local bonus_armor = (self:GetAbility():GetSpecialValueFor("bonus_armor") + (self:GetCaster().BattleContinuationAcquired and 25 or 0))
	return bonus_armor
end

function modifier_khsn_mde_active:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("ms_bonus")
end

--[[function modifier_khsn_mde_active:GetAbsoluteNoDamagePhysical()
	return 1
end]]
function modifier_khsn_mde_active:GetEffectName()
	return "particles/kinghassan/pugna_decrepify.vpcf"
end

function modifier_khsn_mde_active:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end