nursery_rhyme_tempest_double = class({})
nursery_rhyme_tempest_double_activate = class({})
modifier_tempest_double_active = class({})
modifier_tempest_double_illusion = class({})

LinkLuaModifier( "modifier_tempest_double_illusion", "abilities/nursery_rhyme/nursery_rhyme_tempest_double", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_rhyme_flying_book", "abilities/nursery_rhyme/modifiers/modifier_flying_book.lua", LUA_MODIFIER_MOTION_NONE)

function nursery_rhyme_tempest_double:CastFilterResult()
	if self:GetCaster():HasModifier("modifier_tempest_double_active") then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end

function nursery_rhyme_tempest_double:GetCustomCastError()
	return "I am you, you are me is active!"
end

function nursery_rhyme_tempest_double:OnSpellStart()	
	local hCaster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")

	local hDouble = CreateUnitByName(hCaster:GetName(), hCaster:GetAbsOrigin(), true, hCaster, nil, hCaster:GetTeamNumber())
	hDouble:SetPlayerID(hCaster:GetPlayerID())
	hDouble:AddNewModifier(hCaster, self, "modifier_tempest_double_illusion", { duration = duration})
	hDouble:AddNewModifier(hCaster, self, "modifier_kill", { duration = duration})
	hDouble:AddNewModifier(hCaster, hCaster:FindAbilityByName("nursery_rhyme_queens_glass_game"), "modifier_rhyme_flying_book", {})
	hDouble:MakeIllusion()
	hDouble:SetControllableByPlayer(hCaster:GetPlayerID(), false)
	hDouble.IsNurseryClone = true

	for i=1, (hCaster:GetLevel() - 1) do
		hDouble:HeroLevelUp(false)
	end

	--hDouble:SetLevel(hCaster:GetLevel())
	FindClearSpaceForUnit(hDouble, hDouble:GetAbsOrigin(), false)	
	FindClearSpaceForUnit(hCaster, hCaster:GetAbsOrigin(), false)

	local hQAbility = hDouble:FindAbilityByName("nursery_rhyme_white_queens_enigma")
	hQAbility:SetLevel(hCaster:FindAbilityByName("nursery_rhyme_white_queens_enigma"):GetLevel())
	hQAbility:SetActivated(true)
	local hWAbility = hDouble:FindAbilityByName("nursery_rhyme_the_plains_of_water")
	hWAbility:SetLevel(hCaster:FindAbilityByName("nursery_rhyme_the_plains_of_water"):GetLevel())
	hWAbility:SetActivated(true)
	local hBaseHpBonus = hDouble:FindAbilityByName("hero_base_stats_bonus")
	hBaseHpBonus:SetLevel(1)
	local hBonusStats = hDouble:FindAbilityByName("attribute_bonus_custom")
	hBonusStats:SetLevel(hCaster:FindAbilityByName("attribute_bonus_custom"):GetLevel())
	
	hDouble:FindAbilityByName("nursery_rhyme_queens_glass_game"):SetActivated(false)
	hDouble:FindAbilityByName("nursery_rhyme_story_for_somebodys_sake"):SetActivated(false)

	for item_id = 0, 5 do
		local item_in_caster = hCaster:GetItemInSlot(item_id)
		if item_in_caster ~= nil then
			local item_name = item_in_caster:GetName()
			if not (item_name == "item_shard_of_anti_magic" or item_name == "item_shard_of_replenishment" ) then
				local item_created = CreateItem( item_in_caster:GetName(), hDouble, hDouble)
				hDouble:AddItem(item_created)
				item_created:SetCurrentCharges(item_in_caster:GetCurrentCharges()) 
			end
		end
	end

	hDouble:SetHealth(hCaster:GetHealth())
	hDouble:SetMana(hCaster:GetMana())

	hDouble:SetMaximumGoldBounty(0)
	hDouble:SetMinimumGoldBounty(0)
	hDouble:SetDeathXP(0)
	hDouble:SetAbilityPoints(0) 

	hDouble:SetHasInventory(false)
	hDouble:SetCanSellItems(false)

	hDouble:SetBaseStrength(hCaster:GetBaseStrength())
	hDouble:SetBaseIntellect(hCaster:GetBaseIntellect())
	hDouble:ModifyAgility(0)
	hDouble:SetBaseAgility(hCaster:GetBaseAgility())

	hDouble:AddNewModifier(hCaster, self, "modifier_attributes_hp", {})
	hDouble:AddNewModifier(hCaster, self, "modifier_attributes_mp", {})

	hCaster:EmitSound("Hero_Terrorblade.ConjureImage")
	local cloneFx = ParticleManager:CreateParticle( "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf", PATTACH_CUSTOMORIGIN, hCaster );
	ParticleManager:SetParticleControl( cloneFx, 0, hCaster:GetAbsOrigin())
	Timers:CreateTimer( 0.7, function()
		ParticleManager:DestroyParticle( cloneFx, false )
		ParticleManager:ReleaseParticleIndex( cloneFx )
	end)

	hCaster:AddNewModifier(hCaster, self, "modifier_tempest_double_active", { duration = duration })
	hCaster.TempestDouble = hDouble
	hDouble.NurseryRhyme = hCaster
end

function nursery_rhyme_tempest_double_activate:OnSpellStart()
	local hCaster = self:GetCaster()
	local hDouble = hCaster.TempestDouble

	if hDouble and not hDouble:IsNull() then
		local vCasterLoc = hCaster:GetOrigin()
		local vDoubleLoc = hDouble:GetOrigin()

		hCaster:SetOrigin(vDoubleLoc)
		hDouble:SetOrigin(vCasterLoc)

		local iParticleIndex = ParticleManager:CreateParticle("particles/custom/nursery_rhyme/nursery_timelapse.vpcf", PATTACH_CUSTOMORIGIN, hDouble)
		ParticleManager:SetParticleControl(iParticleIndex, 0, vCasterLoc)
		ParticleManager:SetParticleControl(iParticleIndex, 2, vDoubleLoc)

		local iParticleIndex2 = ParticleManager:CreateParticle("particles/custom/nursery_rhyme/nursery_timelapse.vpcf", PATTACH_CUSTOMORIGIN, hCaster)
		ParticleManager:SetParticleControl(iParticleIndex2, 0, vDoubleLoc)
		ParticleManager:SetParticleControl(iParticleIndex2, 2, vCasterLoc)

		Timers:CreateTimer(1.5, function()
			ParticleManager:DestroyParticle(iParticleIndex, false)
			ParticleManager:DestroyParticle(iParticleIndex2, false)
			ParticleManager:ReleaseParticleIndex(iParticleIndex)
			ParticleManager:ReleaseParticleIndex(iParticleIndex2)
			return
		end)
	end
end

if IsServer() then
	function modifier_tempest_double_illusion:OnDestroy()
		local hCaster = self:GetCaster()
		hCaster:RemoveModifierByName("modifier_tempest_double_active")
	end
end


function modifier_tempest_double_illusion:DeclareFunctions()
	return {MODIFIER_PROPERTY_SUPER_ILLUSION, MODIFIER_PROPERTY_ILLUSION_LABEL, MODIFIER_PROPERTY_TEMPEST_DOUBLE }
end

function modifier_tempest_double_illusion:GetModifierTempestDouble()
	return true
end

function modifier_tempest_double_illusion:GetIsIllusion()
	return true
end

function modifier_tempest_double_illusion:GetModifierSuperIllusion()
	return true
end

function modifier_tempest_double_illusion:GetModifierIllusionLabel()
	return true
end

function modifier_tempest_double_illusion:IsHidden()
	return true
end

function modifier_tempest_double_illusion:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end
if IsServer() then
	function modifier_tempest_double_active:OnCreated(arg)
		local hCaster = self:GetParent()
		hCaster:SwapAbilities("nursery_rhyme_tempest_double", "nursery_rhyme_tempest_double_activate", false, true)
	end

	function modifier_tempest_double_active:OnRefresh(arg)
	end

	function modifier_tempest_double_active:OnDestroy()
		local hCaster = self:GetParent()
		hCaster:SwapAbilities("nursery_rhyme_tempest_double", "nursery_rhyme_tempest_double_activate", true, false)
	end
end