LinkLuaModifier("pedigree_off", "abilities/mordred/mordred_pedigree", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("pedigree_buff", "abilities/mordred/mordred_pedigree", LUA_MODIFIER_MOTION_NONE)

mordred_pedigree = class({})

function mordred_pedigree:GetIntrinsicModifierName()
	return "pedigree_buff"
end

function mordred_pedigree:OnSpellStart()
	--[[if not self:GetCaster():HasModifier("pedigree_off") then
		self:GetCaster():SwapAbilities("mordred_clarent", "mordred_rush", true, false)
	end]]
	EmitSoundOn("mordred_koros", self:GetCaster())
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "pedigree_off", {duration = self:GetSpecialValueFor("duration")})
	if self:GetCaster():HasModifier("mordred_combo_window") and self:GetCaster():GetAbilityByIndex(2):GetName()~="mordred_mmb_lightning" then
		self:GetCaster():SwapAbilities("mordred_clarent", "mordred_mmb_lightning", false, true)
		Timers:CreateTimer(4, function()
			self:GetCaster():SwapAbilities("mordred_clarent", "mordred_mmb_lightning", true, false)
		end)
	end
end

pedigree_off = class({})

function pedigree_off:DeclareFunctions()
	return { MODIFIER_PROPERTY_MODEL_CHANGE,
			 }
end

function pedigree_off:GetModifierModelChange()
	self.model_fx = "models/updated_by_seva_and_hudozhestvenniy_film_spizdili/mordred/mordred_unanim_face.vmdl"
	return self.model_fx
end

function pedigree_off:RemoveOnDeath() return false end

function pedigree_off:OnDestroy()
	--[[if IsServer() then
		self:GetParent():SwapAbilities("mordred_clarent", "mordred_rush", false, true)
	end]]
end

pedigree_buff = class({})

function pedigree_buff:OnCreated()
	self.MagicResist = self:GetAbility():GetSpecialValueFor("magic_resist")
	self.Armor = self:GetAbility():GetSpecialValueFor("armor")
	self:StartIntervalThink(FrameTime())
end

function pedigree_buff:OnIntervalThink()
	if self:GetParent():HasModifier("pedigree_off") then
		self.MagicResist = 0
		self.Armor = 0
	else
		self.MagicResist = self:GetAbility():GetSpecialValueFor("magic_resist")
		self.Armor = self:GetAbility():GetSpecialValueFor("armor")
	end
end

function pedigree_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			 MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function pedigree_buff:GetModifierMagicalResistanceBonus()
	return self.MagicResist
end

function pedigree_buff:GetModifierPhysicalArmorBonus()
	return self.Armor
end

function pedigree_buff:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function pedigree_buff:IsHidden()
	if self:GetParent():HasModifier("pedigree_off") then return true end
	return false
end