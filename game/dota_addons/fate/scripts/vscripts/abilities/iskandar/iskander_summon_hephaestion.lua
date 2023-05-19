iskander_summon_hephaestion = class({})
LinkLuaModifier("modifier_iskander_units_bonus_dmg", "abilities/iskandar/iskander_ionioi", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_iskander_units_bonus_dmg_clickable", "abilities/iskandar/iskander_ionioi", LUA_MODIFIER_MOTION_NONE)
function iskander_summon_hephaestion:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local targetPoint = self:GetCursorPosition()
	caster:EmitSound("Hero_KeeperOfTheLight.SpiritForm")
	local aotkAbilityHandle = caster:FindAbilityByName("iskander_ionioi")
	if not caster.CavalrySummoned then
		for i=0,5 do
			local soldier = CreateUnitByName("iskander_cavalry", targetPoint + Vector(200, -200 + i*100), true, nil, nil, caster:GetTeamNumber())
			--soldier:SetBaseMaxHealth(soldier:GetHealth() + ) 

			--soldier:AddNewModifier(caster, nil, "modifier_phased", {})
			soldier:SetOwner(caster)
			table.insert(caster.AOTKSoldiers, soldier)
			--table.insert(caster.AOTKCavalryTable, soldier)
			--caster.AOTKSoldierCount = caster.AOTKSoldierCount + 1
			soldier:AddNewModifier(caster, self, "modifier_iskander_units_bonus_dmg", {duration = 16, dmg = aotkAbilityHandle:GetSpecialValueFor("cavalry_bonus_damage")})

		end
	end

	caster.CavalrySummoned = true
	local hepha = CreateUnitByName("iskander_hephaestion", targetPoint, true, nil, nil, caster:GetTeamNumber())
	hepha:SetControllableByPlayer(caster:GetPlayerID(), true)
	hepha:SetOwner(caster)
	hepha:FindAbilityByName("iskander_hammer_and_anvil"):SetLevel(aotkAbilityHandle:GetLevel())
	table.insert(caster.AOTKSoldiers, hepha)
	hepha:AddNewModifier(caster, self, "modifier_iskander_units_bonus_dmg_clickable", {duration = 16, dmg = aotkAbilityHandle:GetSpecialValueFor("hepha_bonus_damage")})

	
end