-- tamamo_attribute_tamamo_escape — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/tamamo/tamamo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

tamamo_attribute_tamamo_escape = class({})

-- Логика перенесена из scripts/vscripts/tamamo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnPCFAcquired

OnPCFAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero.IsCastrationFistAcquired = true
	hero:FindAbilityByName("tamamo_castration_fist"):OnHeroLevelUp()

	--[[if hero:GetLevel() < 8 then
		SetLevel(1)
	elseif hero:GetLevel >= 8 and hero:GetLevel() < 16 then
		hero:FindAbilityByName("tamamo_castration_fist"):SetLevel(1)
	elseif hero:GetLevel() >= 16 then
		hero:FindAbilityByName("tamamo_castration_fist"):SetLevel(1)
	end	]]

	--[[if hero:GetStrength() < 19.1 or hero:GetAgility() < 19.1 or hero:GetIntellect() < 19.1 then
		FireGameEvent( 'custom_error_show', { player_ID = caster:GetPlayerOwnerID(), _error = "Must Acquire 20 Stats" } )
		keys.ability:EndCooldown()
		caster:SetMana(caster:GetMana()+keys.ability:GetManaCost(1))
		return
	end]]
	--[[hero.IsEscapeAcquired = true
	hero:RemoveAbility("tamamo_polygamist_castration_fist")
	hero:AddAbility("tamamo_polygamist_castration_fist_2")
	hero:FindAbilityByName("tamamo_polygamist_castration_fist_2"):SetLevel(1)
	hero:FindAbilityByName("tamamo_polygamist_castration_fist_2").IsResetable = false
	Timers:CreateTimer(0.033, function()
		hero:SwapAbilities("fate_empty1", "tamamo_polygamist_castration_fist_2", false, true)
		-- Checks if Tamamo is on the verge of casting Castration Fist when PCF attribute is acquired to avoid SwapAbilities-ing to oblivion.
		if hero:GetAbilityByIndex(3):GetName() == "fate_empty1" then
			 hero:SwapAbilities("fate_empty1", "tamamo_polygamist_castration_fist_2", false, true)
		end
	end)]]

    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(caster:GetMana())
end


function tamamo_attribute_tamamo_escape:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: tamamo_ability / OnPCFAcquired
	OnPCFAcquired({ caster = caster, ability = self, target = caster })
end
