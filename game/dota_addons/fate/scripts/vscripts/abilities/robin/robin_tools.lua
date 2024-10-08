-----------------------------
--    Robin Tools    --
-----------------------------

robin_tools = class({})
robin_tools_close = class({})

local tNormalSkills = {
    "robin_backflip",
    "robin_multishot",
    "robin_tools",
    "robin_faceless_king",
    "robin_may_king",
    "robin_yew_bow",
    "attribute_bonus_custom"
}

local tConstruct = {
    "robin_tools_its_a_trap",
    "robin_tools_mysterious_substance",
    "robin_tools_pitfall",
    "robin_faceless_king",
    "robin_tools_close",
    "robin_tools_wolfs_bane",
    "attribute_bonus_custom"
}

function robin_tools:CastFilterResult()
	if self:GetCaster():HasModifier("modifier_robin_yew_bow_combo_window") then
		return UF_FAIL_CUSTOM
	else
		return filter
	end
end

function robin_tools:GetCustomCastError()
	if self:GetCaster():HasModifier("modifier_robin_yew_bow_combo_window") then
		return "#You_Are_In_Combo"
	else
		return "#Cannot_Cast"
	end
end

function robin_tools:OnSpellStart()
	local hCaster = self:GetCaster()
	local level = self:GetLevel()
	
	if 1 < level and level < 3 then
	hCaster:FindAbilityByName("robin_tools"):SetLevel(2)
	hCaster:FindAbilityByName("robin_tools_its_a_trap"):SetLevel(2)
    hCaster:FindAbilityByName("robin_tools_mysterious_substance"):SetLevel(2)
    hCaster:FindAbilityByName("robin_tools_pitfall"):SetLevel(2)
    hCaster:FindAbilityByName("robin_tools_wolfs_bane"):SetLevel(2)
	end
	
	if 2 < level and level < 4 then
	hCaster:FindAbilityByName("robin_tools"):SetLevel(3)
	hCaster:FindAbilityByName("robin_tools_its_a_trap"):SetLevel(3)
    hCaster:FindAbilityByName("robin_tools_mysterious_substance"):SetLevel(3)
    hCaster:FindAbilityByName("robin_tools_pitfall"):SetLevel(3)
    hCaster:FindAbilityByName("robin_tools_wolfs_bane"):SetLevel(3)
	end
	
	if 3 < level and level < 5 then
	hCaster:FindAbilityByName("robin_tools"):SetLevel(4)
	hCaster:FindAbilityByName("robin_tools_its_a_trap"):SetLevel(4)
    hCaster:FindAbilityByName("robin_tools_mysterious_substance"):SetLevel(4)
    hCaster:FindAbilityByName("robin_tools_pitfall"):SetLevel(4)
    hCaster:FindAbilityByName("robin_tools_wolfs_bane"):SetLevel(4)
	end
	
	if level >=5  then
	hCaster:FindAbilityByName("robin_tools"):SetLevel(5)
	hCaster:FindAbilityByName("robin_tools_its_a_trap"):SetLevel(5)
    hCaster:FindAbilityByName("robin_tools_mysterious_substance"):SetLevel(5)
    hCaster:FindAbilityByName("robin_tools_pitfall"):SetLevel(5)
    hCaster:FindAbilityByName("robin_tools_wolfs_bane"):SetLevel(5)
	end

	UpdateAbilityLayout(hCaster, tConstruct)
end

function robin_tools:CloseSpellbook(flCooldown)
	local hCaster = self:GetCaster()
	
	UpdateAbilityLayout(hCaster, tNormalSkills)
end

function robin_tools_close:OnSpellStart()
	local caster = self:GetCaster()
	caster:FindAbilityByName("robin_tools"):CloseSpellbook(1)
end