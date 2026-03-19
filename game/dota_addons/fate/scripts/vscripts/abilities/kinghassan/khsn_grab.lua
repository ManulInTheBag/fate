LinkLuaModifier("modifier_khsn_grab", "abilities/kinghassan/khsn_grab", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_grab_target", "abilities/kinghassan/khsn_grab", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_grab_dummy", "abilities/kinghassan/khsn_grab", LUA_MODIFIER_MOTION_NONE)

khsn_grab = class({})

function khsn_grab:OnSpellStart()
	local caster = self:GetCaster()
	self.target = self:GetCursorTarget()

	local stopOrder_self = {
		UnitIndex = caster:entindex(), 
		OrderType = DOTA_UNIT_ORDER_STOP
	}

	if IsSpellBlocked(self.target) then
		ExecuteOrderFromTable(stopOrder_self)
		return
	end

	local stopOrder = {
 		UnitIndex = self.target:entindex(), 
 		OrderType = DOTA_UNIT_ORDER_STOP
 	}

 	ExecuteOrderFromTable(stopOrder) 

 	caster:EmitSound("khsn_grab")

	caster:AddNewModifier(caster, self, "modifier_khsn_grab", {duration = self:GetSpecialValueFor("channel_duration")})
	self.target:AddNewModifier(caster, self, "modifier_khsn_grab_target", {duration = self:GetSpecialValueFor("channel_duration")})
end

function khsn_grab:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()

	caster:RemoveModifierByName("modifier_khsn_grab")
	self.target:RemoveModifierByName("modifier_khsn_grab_target")
end



modifier_khsn_grab_target = class({})

function modifier_khsn_grab_target:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true }
end

function modifier_khsn_grab_target:DeclareFunctions()
    return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end
function modifier_khsn_grab_target:GetModifierMagicalResistanceBonus()
	return -self:GetAbility():GetSpecialValueFor("mr_reduction")
end

-- function modifier_khsn_grab_target:GetModifierHealAmplify_PercentageTarget()
-- 	return -1*self:GetAbility():GetSpecialValueFor("heal_reduction")
-- end

-- function modifier_khsn_grab_target:GetModifierHPRegenAmplify_Percentage()
-- 	return -1*self:GetAbility():GetSpecialValueFor("heal_reduction")
-- end

function modifier_khsn_grab_target:IsHidden() return false end
function modifier_khsn_grab_target:IsDebuff() return true end

function modifier_khsn_grab_target:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()

	local duration = self.ability:GetSpecialValueFor("channel_duration")

	self.damage = self.ability:GetSpecialValueFor("damage_per_second")
	local unitName1 ="kh_grab_unit"
	local unitName2 = "kh_grab_unit_mirror"
	local unitName3 = "kh_grab_unit_back"
	local vec1 = self.parent:GetForwardVector()
	local vec2 = self.parent:GetForwardVector()
	if self.caster:HasModifier("modifier_hero_selection_skin") then
		unitName1 = "kh_grab_unit_yujiro"
		unitName2 = "kh_grab_unit_yujiro"
		unitName3 = "kh_grab_unit_yujiro"
		vec1 = self.parent:GetRightVector()* -1
		vec2 = self.parent:GetRightVector() 
	end
	self.dummy_1 = CreateUnitByName(unitName1, self.parent:GetAbsOrigin() - 50*self.parent:GetForwardVector() + 100*self.parent:GetRightVector(), false, nil, nil, self.caster:GetTeamNumber())
	self.dummy_1:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	self.dummy_1:SetDayTimeVisionRange(300)
	self.dummy_1:SetNightTimeVisionRange(300)
	self.dummy_1:SetForwardVector(vec1)
	self.dummy_1:AddNewModifier(self.caster, self, "modifier_khsn_grab_dummy", {duration  = duration+0.1})

	local fx1 = ParticleManager:CreateParticle("particles/kinghassan/khsn_grab_dummy_smoke_appear.vpcf", PATTACH_ABSORIGIN, self.dummy_1)
	ParticleManager:ReleaseParticleIndex(fx1)

	self.dummy_1:EmitSound("hassanchik_laugh")

	self.dummy_2 = CreateUnitByName(unitName2, self.parent:GetAbsOrigin() - 50*self.parent:GetForwardVector() - 100*self.parent:GetRightVector(), false, nil, nil, self.caster:GetTeamNumber())
	self.dummy_2:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	self.dummy_2:SetDayTimeVisionRange(300)
	self.dummy_2:SetNightTimeVisionRange(300)
	self.dummy_2:SetForwardVector(vec2)
	self.dummy_2:AddNewModifier(self.caster, self, "modifier_khsn_grab_dummy", {duration  = duration+0.1})

	local fx2 = ParticleManager:CreateParticle("particles/kinghassan/khsn_grab_dummy_smoke_appear.vpcf", PATTACH_ABSORIGIN, self.dummy_2)
	ParticleManager:ReleaseParticleIndex(fx2)

	Timers:CreateTimer(FrameTime(), function()
		self.dummy_2:EmitSound("hassanchik_laugh")
	end)

	self.dummy_3 = CreateUnitByName(unitName3, self.parent:GetAbsOrigin() - 100*self.parent:GetForwardVector(), false, nil, nil, self.caster:GetTeamNumber())
	self.dummy_3:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	self.dummy_3:SetDayTimeVisionRange(300)
	self.dummy_3:SetNightTimeVisionRange(300)
	self.dummy_3:SetForwardVector(self.parent:GetForwardVector())
	self.dummy_3:AddNewModifier(self.caster, self, "modifier_khsn_grab_dummy", {duration  = duration+0.1})

	local fx3 = ParticleManager:CreateParticle("particles/kinghassan/khsn_grab_dummy_smoke_appear.vpcf", PATTACH_ABSORIGIN, self.dummy_3)
	ParticleManager:ReleaseParticleIndex(fx3)

	Timers:CreateTimer(0.0, function()
		self.dummy_3:EmitSound("hassanchik_laugh")
	end)

	self:StartIntervalThink(0.1)
end

function modifier_khsn_grab_target:OnIntervalThink()
	if not IsServer() then return end

	DoDamage(self.caster, self.parent, self.damage*0.1, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
end

function modifier_khsn_grab_target:OnDestroy()
	if not IsServer() then return end

	if self.dummy_1 then
		self.dummy_1:RemoveSelf()
	end
	if self.dummy_2 then
		self.dummy_2:RemoveSelf()
	end
	if self.dummy_3 then
		self.dummy_3:RemoveSelf()
	end
end

modifier_khsn_grab_dummy = class({})

function modifier_khsn_grab_dummy:OnDestroy()
	if not IsServer() then return end

	local fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_grab_dummy_smoke.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	ParticleManager:ReleaseParticleIndex(fx)

	if self:GetParent() then
		self:GetParent():RemoveSelf()
	end
end

function modifier_khsn_grab_dummy:GetStatusEffectName()
    return "particles/kinghassan/kinghassan_grab_dummy_status.vpcf"
end




modifier_khsn_grab = class({})

function modifier_khsn_grab:GetEffectName()
	return "particles/custom/kinghassan/kinghassan_lahm/kinghassan_lahm.vpcf"
end

function modifier_khsn_grab:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_khsn_grab:IsHidden() return true end
function modifier_khsn_grab:IsDebuff() return false end