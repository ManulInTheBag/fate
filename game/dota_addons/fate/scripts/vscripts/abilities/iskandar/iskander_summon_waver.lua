iskander_summon_waver = class({})
LinkLuaModifier("modifier_iskander_units_bonus_dmg", "abilities/iskandar/iskander_ionioi", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_iskander_units_bonus_dmg_clickable", "abilities/iskandar/iskander_ionioi", LUA_MODIFIER_MOTION_NONE)
function iskander_summon_waver:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local targetPoint = self:GetCursorPosition()
	caster:EmitSound("Hero_Silencer.Curse.Cast")
	local aotkAbilityHandle = caster:FindAbilityByName("iskander_ionioi")
	if not caster.WaverSummoned then
		for i=0,5 do
		
			local soldier = CreateUnitByName("iskander_mage", targetPoint + Vector(200, -200 + i*100), true, nil, nil, caster:GetTeamNumber())
			--soldier:AddNewModifier(caster, nil, "modifier_phased", {})
			soldier:SetOwner(caster)
			table.insert(caster.AOTKSoldiers, soldier)
			--caster.AOTKSoldierCount = caster.AOTKSoldierCount + 1
			soldier:AddNewModifier(caster, self, "modifier_iskander_units_bonus_dmg", {duration = 16, dmg = aotkAbilityHandle:GetSpecialValueFor("mage_bonus_damage")})
		end
	end
	caster.WaverSummoned = true
	local waver = CreateUnitByName("iskander_waver", targetPoint, true, nil, nil, caster:GetTeamNumber())
	waver:SetControllableByPlayer(caster:GetPlayerID(), true)
	waver:SetOwner(caster)
	waver:FindAbilityByName("iskander_brilliance_of_the_king"):SetLevel(aotkAbilityHandle:GetLevel())
	table.insert(caster.AOTKSoldiers, waver)
	--caster.AOTKSoldierCount = caster.AOTKSoldierCount + 1
	waver:AddNewModifier(caster, self, "modifier_iskander_units_bonus_dmg_clickable", {duration = 16, dmg = aotkAbilityHandle:GetSpecialValueFor("waver_bonus_damage")})
end