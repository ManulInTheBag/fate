-- false_assassin_windblade — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/sasaki/sasaki_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

false_assassin_windblade = class({})

LinkLuaModifier("modifier_wb_baseattack_reduction", "abilities/sasaki/false_assassin_windblade", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/fa_ability.lua, scripts/vscripts/lancelot_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnWBStart, ArsenalReturnMana

OnWBStart = function(keys)
	ArsenalReturnMana(keys.caster)
	EmitGlobalSound("FA.Windblade" )
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local ability = keys.ability
	local radius = keys.Radius
	local casterInitOrigin = caster:GetAbsOrigin() 

	-- make FA's damage zero 
	caster:AddNewModifier(caster, ability, "modifier_wb_baseattack_reduction", {})

	if caster:GetName() == "npc_dota_hero_juggernaut" and not caster.IsGanryuAcquired then
		caster:FindAbilityByName("false_assassin_gate_keeper"):StartCooldown(keys.GCD) 

		-- 1.24 change : Vitrification removes GCD from Heart regardless
		if not caster.IsVitrificationAcquired then 
			caster:FindAbilityByName("false_assassin_heart_of_harmony"):StartCooldown(keys.GCD) 
		end		

		caster:FindAbilityByName("false_assassin_tsubame_gaeshi"):StartCooldown(keys.GCD) 
	end

	local targets = FindUnitsInRadius(caster:GetTeam(), casterInitOrigin, nil, radius
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)

	if caster.IsGanryuAcquired then
		Timers:CreateTimer(0.1, function()
			for i=1, #targets do
				if targets[i]:IsAlive() and targets[i]:GetName() ~= "npc_dota_ward_base" then
					--local diff = (caster:GetAbsOrigin() - targets[i]:GetAbsOrigin()):Normalized()
					caster:SetAbsOrigin(targets[i]:GetAbsOrigin() - targets[i]:GetForwardVector():Normalized()*100)
					FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
					break
				end
			end
		return end)
	end

	for k,v in pairs(targets) do
		--if (v:GetName() == "npc_dota_hero_bounty_hunter" and v.IsPFWAcquired) or 
		if v:GetUnitName() == "ward_familiar" then 
			-- do nothing
		else
			DoDamage(caster, v, keys.Damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
			caster:PerformAttack(v, true, true, true, true, false, false, false )
			local slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )
		    ParticleManager:SetParticleControl(slashIndex, 0, v:GetAbsOrigin())
		    ParticleManager:SetParticleControl(slashIndex, 1, Vector(500,0,150))
		    ParticleManager:SetParticleControl(slashIndex, 2, Vector(0.2,0,0))
		    if not v:HasModifier("modifier_wind_protection_passive") then
		    	giveUnitDataDrivenModifier(caster, v, "drag_pause", 0.5)
				local pushback = Physics:Unit(v)
				v:PreventDI()
				v:SetPhysicsFriction(0)
				v:SetPhysicsVelocity((v:GetAbsOrigin() - casterInitOrigin):Normalized() * 300)
				v:SetNavCollisionType(PHYSICS_NAV_NOTHING)
				v:FollowNavMesh(false)
				Timers:CreateTimer(0.5, function()  
					v:PreventDI(false)
					v:SetPhysicsVelocity(Vector(0,0,0))
					v:OnPhysicsFrame(nil)
					FindClearSpaceForUnit(v, v:GetAbsOrigin(), true)
				return end)
			end
		end
	end

	local risingWindFx = ParticleManager:CreateParticle("particles/custom/false_assassin/fa_thunder_clap.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	-- Destroy particle after delay
	Timers:CreateTimer( 2.0, function()
			ParticleManager:DestroyParticle( risingWindFx, false )
			ParticleManager:ReleaseParticleIndex( risingWindFx )
			return nil
	end)
end

ArsenalReturnMana = function(caster)
    if caster:GetName() == "npc_dota_hero_sven" and caster.ArsenalLevel == 2 then
        caster:GiveMana(caster:FindAbilityByName("lancelot_knight_of_honor_arsenal"):GetSpecialValueFor("mana_return"))
    end
end


function false_assassin_windblade:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: fa_ability / OnWBStart
	OnWBStart({
		caster = caster,
		ability = self,
		target = caster,
		Damage = self:GetSpecialValueFor("damage"),
		Radius = self:GetSpecialValueFor("radius"),
		GCD = self:GetSpecialValueFor("global_cooldown")
	})
end

modifier_wb_baseattack_reduction = class({})

function modifier_wb_baseattack_reduction:IsHidden() return true end

function modifier_wb_baseattack_reduction:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
	}
end

function modifier_wb_baseattack_reduction:GetModifierBaseDamageOutgoing_Percentage()
	return -100
end

function modifier_wb_baseattack_reduction:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "0.033" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(0.033, true)
	end
end

function modifier_wb_baseattack_reduction:OnRefresh(kv)
	self:OnCreated(kv)
end
