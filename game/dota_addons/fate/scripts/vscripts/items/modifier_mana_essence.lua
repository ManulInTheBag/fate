modifier_mana_essence = class({})

function modifier_mana_essence:OnCreated(args)
	self.fHealthRegen = args.fHealthRegen
	self.fManaRegen = args.fManaRegen

	if IsServer() then
		if self:GetParent():GetName() == "npc_dota_hero_juggernaut" or self:GetParent():GetName() == "npc_dota_hero_shadow_shaman" then
			self.fManaRegen = 0
		end	
		
		CustomNetTables:SetTableValue("sync","mana_essence", { hp_regen = self.fHealthRegen,
															   mana_regen = self.fManaRegen })
	end
end

function modifier_mana_essence:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		--MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
	return funcs
end

function modifier_mana_essence:GetModifierConstantHealthRegen()
	if IsServer() then
		return self.fHealthRegen
	elseif IsClient() then
		local hp_regen = CustomNetTables:GetTableValue("sync","mana_essence").hp_regen
        return hp_regen 
	end
end

function modifier_mana_essence:GetModifierConstantManaRegen()
	if IsServer() then
		return self.fManaRegen
	elseif IsClient() then
		local mana_regen = CustomNetTables:GetTableValue("sync","mana_essence").mana_regen
        return mana_regen 
	end
end

function modifier_mana_essence:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_mana_essence:OnTakeDamage(args)
	if args.unit == self:GetParent() then
		--if args.inflictor and args.inflictor:GetName() == "vlad_passive_rending" then
		--	return true
		--else
		self:Destroy()
		--end		
	--return true
	end
end

function modifier_mana_essence:GetEffectName()
	return "particles/items_fx/healing_flask.vpcf"
end

function modifier_mana_essence:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_mana_essence:GetTexture()
	return "custom/mana_essence"
end
