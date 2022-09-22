cu_chulain_relentless_spear = class({})

LinkLuaModifier("modifier_relentless_spear", "abilities/cu_chulain/modifiers/modifier_relentless_spear", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wesen_window", "abilities/cu_chulain/modifiers/modifier_wesen_window", LUA_MODIFIER_MOTION_NONE)

function cu_chulain_relentless_spear:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function cu_chulain_relentless_spear:OnChannelThink(flInterval)
	local caster = self:GetCaster()
	local distance = (caster:GetAbsOrigin() - self.target:GetAbsOrigin()):Length2D()

	if not self:GetCaster():IsAlive() or not self.target:IsAlive() or distance > 450 then
		local stopOrder = {
	 		UnitIndex = caster:entindex(), 
	 		OrderType = DOTA_UNIT_ORDER_STOP
	 	}

	 	ExecuteOrderFromTable(stopOrder) 
		self:EndChannel(true)
	end
end

function cu_chulain_relentless_spear:OnSpellStart()
	local caster = self:GetCaster()
	self.target = self:GetCursorTarget()

	caster:EmitSound("cu_skill_" .. math.random(1,4))

	self.target:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.15})
	caster:AddNewModifier(caster, self, "modifier_relentless_spear", { Duration = self:GetSpecialValueFor("duration") + 0.1,
																	   DamagePct = self:GetSpecialValueFor("damage") })

	local modifier = caster:FindModifierByName("modifier_rune_of_ferocity")
	if modifier then
		modifier:OnIntervalThink()
	end

	self:CheckCombo()
end

function cu_chulain_relentless_spear:CheckCombo()
	local caster = self:GetCaster()

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if caster:FindAbilityByName("cu_chulain_gae_bolg"):IsCooldownReady() 
		and caster:FindAbilityByName("cu_chulain_gae_bolg_combo"):IsCooldownReady() then
			caster:AddNewModifier(caster, self, "modifier_wesen_window", { Duration = 4 })
		end
	end
end

function cu_chulain_relentless_spear:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_relentless_spear")
end

function cu_chulain_relentless_spear:EndChannel(bInterrupted)
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_relentless_spear")
end