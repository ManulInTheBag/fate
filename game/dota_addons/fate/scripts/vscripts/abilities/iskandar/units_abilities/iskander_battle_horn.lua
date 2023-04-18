iskander_battle_horn = class({})
LinkLuaModifier("modifier_battle_horn_pct_armor_reduction", "abilities/iskandar/units_abilities/iskander_battle_horn", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_battle_horn_movespeed_buff", "abilities/iskandar/units_abilities/iskander_battle_horn", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_battle_horn_movespeed_debuff", "abilities/iskandar/units_abilities/iskander_battle_horn", LUA_MODIFIER_MOTION_NONE)
function iskander_battle_horn:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local targetPoint = self:GetCursorPosition()
	caster:EmitSound("Hero_LegionCommander.PressTheAttack")
	local marbleCenter = 0
	local aotkCenter = Vector(288,-4564, 261)
	local ubwCenter = Vector(5926, -4837, 222)
	if hero.IsAOTKDominant then marbleCenter = aotkCenter else marbleCenter = ubwCenter end
	for i=1, #hero.AOTKSoldiers do
		if IsValidEntity(hero.AOTKSoldiers[i]) then
			if hero.AOTKSoldiers[i]:IsAlive() then
				hero.AOTKSoldiers[i]:AddNewModifier(caster, self, "modifier_battle_horn_movespeed_buff", { duration = 4 })
				ExecuteOrderFromTable({
			        UnitIndex = hero.AOTKSoldiers[i]:entindex(),
			        OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
			        Position = targetPoint
			    })
			end
		end
	end
	local targets = FindUnitsInRadius(caster:GetTeam(), marbleCenter, nil, 3000
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
		v:AddNewModifier(caster, self, "modifier_battle_horn_pct_armor_reduction", {duration = self:GetSpecialValueFor("duration")})
		v:AddNewModifier(caster, self, "modifier_battle_horn_movespeed_debuff", { duration = 4 })
    end
		
    
end


modifier_battle_horn_pct_armor_reduction = class({})

function modifier_battle_horn_pct_armor_reduction:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
 
    return funcs
end

function modifier_battle_horn_pct_armor_reduction:GetModifierPhysicalArmorBonus() 
    local ability = self:GetAbility()
    local pct_armor_reduction = ability:GetSpecialValueFor("pct_armor_reduction")
    local parent_armor = self:GetParent():GetPhysicalArmorBaseValue()

    return pct_armor_reduction / 100 * parent_armor
end
 
function modifier_battle_horn_pct_armor_reduction:IsDebuff()
    return true
end

function modifier_battle_horn_pct_armor_reduction:RemoveOnDeath()
    return true
end

function modifier_battle_horn_pct_armor_reduction:GetTexture()
    return "legion_commander_press_the_attack"
end




modifier_battle_horn_movespeed_buff = class({})

function modifier_battle_horn_movespeed_buff:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_battle_horn_movespeed_buff:GetModifierMoveSpeedBonus_Percentage()
	return 50
end

function modifier_battle_horn_movespeed_buff:IsHidden()
	return true 
end

function modifier_battle_horn_movespeed_buff:GetEffectName()
    return "particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf"
end






modifier_battle_horn_movespeed_debuff = class({})

function modifier_battle_horn_movespeed_debuff:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_battle_horn_movespeed_debuff:GetModifierMoveSpeedBonus_Percentage()
	return -30
end

function modifier_battle_horn_movespeed_debuff:IsHidden()
	return true 
end

function modifier_battle_horn_movespeed_debuff:GetEffectName()
    return "particles/custom/rider/rider_breaker_gorgon_debuff.vpcf"
end

