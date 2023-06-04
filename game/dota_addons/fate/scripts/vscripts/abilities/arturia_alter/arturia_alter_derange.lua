arturia_alter_derange = class({})

LinkLuaModifier("modifier_derange", "abilities/arturia_alter/arturia_alter_derange", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_catalyst", "abilities/arturia_alter/arturia_alter_derange", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arturia_alter_combo_window", "abilities/arturia_alter/arturia_alter_derange", LUA_MODIFIER_MOTION_NONE)

function arturia_alter_derange:OnToggle()
    local caster = self:GetCaster()
	self.mana_drain = self:GetCaster():GetMaxMana()*0.01

    caster:GetAbilityByIndex(0):EndCooldown() 
	
	if self:GetToggleState() then

		caster:AddNewModifier(caster, self, "modifier_derange", {})

		caster:EmitSound("Saber_Alter.Derange")
		caster:EmitSound("saber_alter_other_01")

		caster:AddNewModifier(caster, self, "modifier_arturia_alter_combo_window", {duration = 3})

	else

		caster:RemoveModifierByName("modifier_derange")
		caster:EmitSound("Saber_Alter.Derange")

		caster:RemoveModifierByName("modifier_arturia_alter_combo_window")

		self:StartCooldown(self:GetCooldown(self:GetLevel()-1) - (caster.GodIsGreatAcquired and 4 or 0))

	end

end

function arturia_alter_derange:OnUpgrade()
    local Caster = self:GetCaster() 
		Caster:FindAbilityByName("arturia_alter_mana_discharge"):SetLevel(self:GetLevel())
end

modifier_arturia_alter_combo_window = class({})
function modifier_arturia_alter_combo_window:IsHidden() return true end
function modifier_arturia_alter_combo_window:IsDebuff() return false end
function modifier_arturia_alter_combo_window:RemoveOnDeath() return true end

function arturia_alter_derange:GetIntrinsicModifierName()
    return "modifier_catalyst"
end

modifier_derange = class({})

function modifier_derange:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODFIER_EVENT_ON_RESPAWN,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end

function modifier_derange:IsHidden() return false end
function modifier_derange:IsDebuff() return false end
function modifier_derange:RemoveOnDeath() return true end
function modifier_derange:OnCreated()
	if IsServer() then
		self.parent = self:GetParent()
		self.ability = self:GetAbility()
		self.mana = self:GetParent():GetMaxMana()
		self.abilitycd = self.parent:GetAbilityByIndex(0):GetCooldown(self.parent:GetAbilityByIndex(0):GetLevel()-1)
		self.cringe = 0
		self.counter = self.parent:FindModifierByNameAndCaster("modifier_catalyst", self.parent)
		self:StartIntervalThink(0.25)
	end
end


function modifier_derange:OnIntervalThink()
	if not IsServer() then return end

	if self.ability:GetToggleState() == true then

	self:GetParent():SpendMana(self:GetAbility().mana_drain, self)
	if self.parent:GetMana() < self:GetAbility().mana_drain then
        self.parent:RemoveModifierByName("modifier_derange")
        self.parent:GetAbilityByIndex(0):StartCooldown(self.abilitycd)
    end

    if self:GetParent().IsManaBlastAcquired == true then
    	self.cringe = self.cringe+(self:GetParent():GetMaxMana()*0.01)
    	if (self.cringe >= 200 and self.counter:GetStackCount() < 9)
    		then self.cringe = self.cringe - 200
    		self.counter:SetStackCount(self.counter:GetStackCount()+1)
		end
	end
	else
		self.parent:RemoveModifierByName("modifier_derange")
	end
end

function modifier_derange:OnDestroy()
	if IsServer() then
        if self.ability:GetToggleState() then
            self.ability:ToggleAbility()
        end
    end
end

function modifier_derange:OnRespawn()
    self.Destroy()
end

function modifier_derange:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("as") + self:GetParent():GetMaxMana()*self:GetAbility():GetSpecialValueFor("mana_drain_percentage_1")/100
end

function modifier_derange:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("ms") + self:GetParent():GetMaxMana()*self:GetAbility():GetSpecialValueFor("mana_drain_percentage_2")/100
end

function modifier_derange:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("dmg") + self:GetParent():GetMaxMana()*self:GetAbility():GetSpecialValueFor("mana_drain_percentage_3")/100
end

function modifier_derange:GetModifierPhysicalArmorBonus()
	if self:GetParent().IsManaShroudImproved == true then
		return self:GetAbility():GetSpecialValueFor("armor_bonus")
	else
		return 0
	end
end

function modifier_derange:GetModifierMagicalResistanceBonus()
	if self:GetParent().IsManaShroudImproved == true then
		return self:GetAbility():GetSpecialValueFor("mr_bonus")
	else
		return 0
	end
end

function modifier_derange:GetTexture()
	return "custom/saber_alter_derange"
end

function modifier_derange:GetEffectName()
	return "particles/items2_fx/satanic_buff.vpcf"
end

modifier_catalyst = class({})
function modifier_catalyst:IsHidden() 
	if self:GetStackCount() > 0 then
		return false
	else
		return true
	end
end
function modifier_catalyst:IsDebuff() return false end
function modifier_catalyst:RemoveOnDeath() return true end
function modifier_catalyst:OnCreated()
	if IsServer() then
		self.parent = self:GetParent()
		self.ability = self:GetAbility()
		local counter = self.parent:FindModifierByNameAndCaster("modifier_catalyst", self.parent)
		counter:SetStackCount(0)
	end
end

function modifier_catalyst:DeclareFunctions()
	return { MODIFIER_EVENT_ON_DEATH,}		 
end

function modifier_catalyst:GetTexture()
	return "custom/arturia_alter/catalyst"
end

function modifier_catalyst:OnDeath(keys)
	if IsServer() then
	    local counter = self.parent:FindModifierByNameAndCaster("modifier_catalyst", self.parent) 
	       if keys.unit == self:GetParent() then 
	    	counter:SetStackCount(0)
		end
	end
end