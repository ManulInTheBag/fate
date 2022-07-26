modifier_pc_invis = class({})

LinkLuaModifier("modifier_pc_bonus_damage", "abilities/lishuwen/modifiers/modifier_pc_bonus_damage", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pc_nss_cooldown_recovery", "abilities/lishuwen/modifiers/modifier_pc_nss_cooldown_recovery", LUA_MODIFIER_MOTION_NONE)


function modifier_pc_invis:OnCreated(keys)
	local caster = self:GetParent()
	
	self.Break = false
	self.BreakDelay = keys.BreakDelay
	self.HealthRegenPct = keys.HealthRegenPct
	self.ManaRegenPct = keys.ManaRegenPct
	self.BonusDamage = keys.BonusDamage
	self.AttackCount = keys.AttackCount
	self.AttackBuffDuration = keys.AttackBuffDuration

	if IsServer() then
		CustomNetTables:SetTableValue("sync","lishuwen_presence_conceal", { health_regen = self.HealthRegenPct,
																			mana_regen = self.ManaRegenPct })
	end
end

function modifier_pc_invis:GetModifierTotalPercentageManaRegen()
	if IsServer() then
		return self.ManaRegenPct
	elseif IsClient() then
		local mana_regen = CustomNetTables:GetTableValue("sync","lishuwen_presence_conceal").mana_regen
		return mana_regen
	end	
end

function modifier_pc_invis:GetModifierHealthRegenPercentage()
	if IsServer() then
		return self.HealthRegenPct
	elseif IsClient() then
		local health_regen = CustomNetTables:GetTableValue("sync","lishuwen_presence_conceal").health_regen
		return health_regen
	end	
end

function modifier_pc_invis:CheckState()
	return { [MODIFIER_STATE_INVISIBLE] = true, }
end

function modifier_pc_invis:DeclareFunctions()
	local funcs = {	MODIFIER_EVENT_ON_ATTACK_START,
					MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
					MODIFIER_EVENT_ON_UNIT_MOVED,
					--MODIFIER_EVENT_ON_TAKEDAMAGE,
					MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
					MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE }
	return funcs
end

function modifier_pc_invis:OnAttackStart(keys)
	if IsServer() then
		local caster = self:GetParent()
		if keys.attacker ~= caster then return end
		self:Destroy()
	end	
end

function modifier_pc_invis:OnAbilityFullyCast(keys)
	if IsServer() then
		local caster = self:GetParent()
		
		if keys.unit == caster then 
			 if keys.ability:GetName() ~= "lishuwen_presence_concealment" then
                self:Destroy()
            end
		end
	end	
end

function modifier_pc_invis:OnTakeDamage(keys)
	if IsServer() then
		local caster = self:GetParent()
		if keys.unit ~= caster then return end
		self:Destroy()
	end	
end

function modifier_pc_invis:OnUnitMoved(keys)
	if IsServer() then
		local caster = self:GetParent()
		if keys.unit ~= caster then return end

		if not self.Break then
			self:StartIntervalThink(self.BreakDelay)
			self.Break = true
		end
	end
end

function modifier_pc_invis:OnIntervalThink()
	self:Destroy()
end

function modifier_pc_invis:OnDestroy()
	if IsServer() then
		local caster = self:GetParent()

		caster:AddNewModifier(caster, self:GetAbility(), "modifier_pc_bonus_damage", {
	        Duration = self.AttackBuffDuration,
	        BonusDamage = self.BonusDamage,
	        AttackCount = self.AttackCount
	    })

	    if caster:HasModifier("modifier_pc_nss_cooldown_recovery") then
	    	caster:RemoveModifierByName("modifier_pc_nss_cooldown_recovery")
	    end
	end
end

function modifier_pc_invis:IsHidden()
	return false
end

function modifier_pc_invis:IsDebuff()
	return false
end

function modifier_pc_invis:RemoveOnDeath()
	return true
end

function modifier_pc_invis:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_pc_invis:GetEffectName()
	return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_pc_invis:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_pc_invis:GetTexture()
	return "custom/lishuwen_concealment"
end
