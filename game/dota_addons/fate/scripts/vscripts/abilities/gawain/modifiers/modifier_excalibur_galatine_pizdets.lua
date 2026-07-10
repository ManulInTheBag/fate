modifier_excalibur_galatine_pizdets = class({})

function modifier_excalibur_galatine_pizdets:DeclareFunctions()
	local func = { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, MODIFIER_PROPERTY_PROVIDES_FOW_POSITION}
	return func
end

function modifier_excalibur_galatine_pizdets:OnCreated(args)
	if IsServer() then
		local hero_armor = self:GetParent():GetPhysicalArmorValue(false)
		self.armor_debuff = (0.01 * args.armor_debuff) * hero_armor * -1
		self.magic_debuff = -1 * args.magic_debuff
		self:SetHasCustomTransmitterData(true)
	end
end

-- args зависят от дистанции при наложении, поэтому значения шлём клиенту
-- через transmitter data (kv-таблица на клиенте пустая)
function modifier_excalibur_galatine_pizdets:AddCustomTransmitterData()
	return { armor_debuff = self.armor_debuff, magic_debuff = self.magic_debuff }
end

function modifier_excalibur_galatine_pizdets:HandleCustomTransmitterData(data)
	self.armor_debuff = data.armor_debuff
	self.magic_debuff = data.magic_debuff
end

function modifier_excalibur_galatine_pizdets:GetModifierPhysicalArmorBonus()
    return self.armor_debuff or 0
end

function modifier_excalibur_galatine_pizdets:GetModifierMagicalResistanceBonus()
	return self.magic_debuff or 0
end

function modifier_excalibur_galatine_pizdets:GetModifierProvidesFOWVision()
	if self:GetParent():HasModifier("modifier_murderer_mist_in") then
		return 0
	end
    return 1
end

function modifier_excalibur_galatine_pizdets:IsDebuff()
    return true
end

function modifier_excalibur_galatine_pizdets:RemoveOnDeath()
    return true
end

function modifier_excalibur_galatine_pizdets:IsHidden()
    return false
end