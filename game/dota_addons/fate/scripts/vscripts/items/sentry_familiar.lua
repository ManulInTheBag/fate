item_sentry_familiar = class({})

function item_sentry_familiar:OnSpellStart()
	local targetPoint = self:GetCursorPosition()

	local caster = self:GetCaster()
	local ability = self
	local iCurrentCharges = self:GetCurrentCharges()

	local hero = caster:GetPlayerOwner():GetAssignedHero()
	
	if caster:HasModifier("jump_pause_nosilence") then
		RefundItem(caster, ability)
		return
	end

	hero.ServStat:useWard()

	caster.ward = CreateUnitByName("sentry_familiar", targetPoint, true, caster, caster, caster:GetTeamNumber())

	caster.ward:SetDayTimeVisionRange(self:GetSpecialValueFor("vision_range"))
	caster.ward:SetNightTimeVisionRange(self:GetSpecialValueFor("vision_range"))

	caster.ward:AddNewModifier(caster, caster, "modifier_invisible", {})
	caster.ward:AddNewModifier(caster, caster, "modifier_item_ward_true_sight", { true_sight_range = self:GetSpecialValueFor("truesight_range"), duration = self:GetSpecialValueFor("duration")})
    caster.ward:AddNewModifier(caster, caster, "modifier_kill", {duration = self:GetSpecialValueFor("duration")})
    giveUnitDataDrivenModifier(caster.ward, caster.ward, "modifier_ward_dmg_reduce", {duration = self:GetSpecialValueFor("duration")})
    EmitSoundOnLocationForAllies(targetPoint,"DOTA_Item.ObserverWard.Activate",caster)

    if iCurrentCharges == 1 then caster:RemoveItem(self) else self:SetCurrentCharges(iCurrentCharges - 1) end
end