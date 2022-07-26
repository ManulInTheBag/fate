modifier_projection_active = class({})

function modifier_projection_active:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_projection_active:IsPurgable()
    return false
end

function modifier_projection_active:IsDebuff()
    return false
end

function modifier_projection_active:RemoveOnDeath()
    return true
end

function modifier_projection_active:GetTexture()
    return "custom/kuro/kuro_attribute_projection"
end

function modifier_projection_active:OnCreated()
	self:GetParent():EmitSound("chloe_crane_1")
end

function modifier_projection_active:OnRefresh()
	if self:GetStackCount() == 2 then
		self:GetParent():EmitSound("chloe_crane_2")
	end
	if self:GetStackCount() == 3 then
		self:GetParent():EmitSound("chloe_crane_3")
	end
	if self:GetStackCount()>3 then
		for i=1,5 do
			if self:GetParent():GetAbilityByIndex(i-1):GetName() ~= "kuro_hrunting" and self:GetParent():GetAbilityByIndex(i-1):GetName() ~= "kuro_crane_wings_combo_tp" then
				self:GetParent():GetAbilityByIndex(i-1):EndCooldown()
			end
		end
		EmitGlobalSound("chloe_crane_4")
		self:GetParent():FindAbilityByName("kuro_rho_aias"):EndCooldown()
		self:GetParent():FindAbilityByName("kuro_gae_bolg"):EndCooldown()
		self:GetParent():FindAbilityByName("kuro_excalibur_image"):EndCooldown()
		self:GetParent():FindAbilityByName("kuro_nine_lives"):EndCooldown()
		self:GetParent():FindAbilityByName("kuro_rosa_ichthys"):EndCooldown()
		self:GetParent():FindAbilityByName("kuro_crane_wings"):EndCooldown()
		self:Destroy()
	end
end
-----------------------------------------------------------------------------------
