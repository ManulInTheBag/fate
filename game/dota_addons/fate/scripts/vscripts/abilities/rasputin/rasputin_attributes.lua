LinkLuaModifier("modifier_rasputin_curse_counter", "abilities/rasputin/rasputin_bk", LUA_MODIFIER_MOTION_NONE)

rasputin_combat_movement = class({})
rasputin_territory_creation = class({})
rasputin_bk_curses = class({})
rasputin_keys = class({})


local function TakeAttribute(ability, flag)

	local caster = ability:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero[flag] = true


	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - ability:GetManaCost(ability:GetLevel()))

end


function rasputin_combat_movement:OnSpellStart()
	TakeAttribute(self, "IsRasputinCombatMovementAcquired")
end


function rasputin_territory_creation:OnSpellStart()
	TakeAttribute(self, "IsRasputinTerritoryAcquired")
end


function rasputin_bk_curses:OnSpellStart()

	TakeAttribute(self, "IsRasputinBkCursesAcquired")


	local hero = self:GetCaster():GetPlayerOwner():GetAssignedHero()

	local finisher = hero:FindAbilityByName("rasputin_finisher")

	if finisher and not hero:HasModifier("modifier_rasputin_curse_counter") then

		hero:AddNewModifier(
			hero,
			finisher,
			"modifier_rasputin_curse_counter",
			{}
		)

	end

end


function rasputin_keys:OnSpellStart()
	TakeAttribute(self, "IsRasputinKeysAcquired")
end
