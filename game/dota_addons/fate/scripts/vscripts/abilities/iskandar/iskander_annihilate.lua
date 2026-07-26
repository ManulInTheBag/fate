-- iskander_annihilate — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/iskandar/iskandar_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

iskander_annihilate = class({})

LinkLuaModifier("modifier_annihilate_cooldown", "abilities/iskandar/iskander_annihilate", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_annihilate_caster", "abilities/iskandar/iskander_annihilate", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_annihilate", "abilities/iskandar/iskander_annihilate", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_annihilate_mute", "abilities/iskandar/iskander_annihilate", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/iskander_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnAnnihilateStart

OnAnnihilateStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())

	local marbleCenter = 0
	if hero.IsAOTKDominant then marbleCenter = aotkCenter else marbleCenter = ubwCenter end
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(keys.ability:GetCooldown(1))
	caster:AddNewModifier(caster, ability, "modifier_annihilate_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})

	caster:AddNewModifier(caster, ability, "modifier_annihilate_caster", {})
	EmitGlobalSound("Iskander.Annihilate")
	Timers:CreateTimer(2.0, function()
		EmitGlobalSound("Iskander.Aye")
	end)
	EmitGlobalSound("Hero_LegionCommander.PressTheAttack")
	-- Remove soldiers 
	for i=1, #caster.AOTKSoldiers do
		if IsValidEntity(caster.AOTKSoldiers[i]) then
			if caster.AOTKSoldiers[i]:IsAlive() then
				caster.AOTKSoldiers[i]:AddNewModifier(caster, keys.ability, "modifier_annihilate", {})
			end
		end
	end

	-- Mute
	Timers:CreateTimer(1.0, function()
		local targets = FindUnitsInRadius(caster:GetTeam(), marbleCenter, nil, 2000
           	 , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			if v:GetUnitName() ~= "gille_gigantic_horror" and v:GetUnitName() ~= "caster_5th_territory_improved" and v:GetUnitName() ~= "caster_5th_territory" then
				v:AddNewModifier(caster, keys.ability, "modifier_annihilate_mute", {})
			end
   		end
		--local particle = ParticleManager:CreateParticle("particles/custom/iskandar/iskandar_combo_mute.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		--ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
		--ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin()+Vector(3000,0,0))
   	end)

    -- Arrows
    local tableOfSounds = {"Iskander.ArrowFly1","Iskander.ArrowFly2","Iskander.ArrowLand1","Iskander.ArrowLand3"}
	local nVolleys = 0
	local nHit = 0
	Timers:CreateTimer(3.0, function() -- Empirical testing; 500 arrows fired with each arrow being 200 aoe, each servant will get hit by 6-7 arrows on average.
		if caster:IsAlive() and caster:GetAbsOrigin().y < -3500 then
			for i=0,4 do
				local targetPoint = RandomPointInCircle(marbleCenter, 2000)
				local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, keys.ArrowAoE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
				-- DebugDrawCircle(targetPoint, Vector(255,0,0), 0.5, flamePillarRadius, true, 30)
				for k,v in pairs(targets) do
					nHit = nHit + 1
					if not v:HasModifier("modifier_protection_from_arrows_active") then
						DoDamage(caster, v, keys.ArrowDamage , DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
					end
				end
				--GenerateArrowParticle(keys,targetPoint,marbleCenter)
			end
			nVolleys = nVolleys + 1
			if nVolleys%3 == 0 and nVolleys <=95 then EmitGlobalSound(tableOfSounds[math.random(4)]) end
			--print("rawr")
			if nVolleys == 100 then
				print(nHit)
				return
			else
				return 0.04
			end
		else
			return
		end
	end)
end


function iskander_annihilate:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: iskander_ability / OnAnnihilateStart
	OnAnnihilateStart({
		caster = caster,
		ability = self,
		target = caster,
		ArrowDamage = self:GetSpecialValueFor("damage"),
		ArrowAoE = self:GetSpecialValueFor("aoe")
	})
end

modifier_annihilate_cooldown = class({})

function modifier_annihilate_cooldown:IsDebuff() return true end
function modifier_annihilate_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

modifier_annihilate_caster = class({})

function modifier_annihilate_caster:IsHidden() return true end

function modifier_annihilate_caster:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "12.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(12.0, true)
	end
end

function modifier_annihilate_caster:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_annihilate = class({})

function modifier_annihilate:GetEffectName() return "particles/custom/iskandar/iskandar_combo_invul.vpcf" end
function modifier_annihilate:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_annihilate:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
	}
end

function modifier_annihilate:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "12.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(12.0, true)
	end
end

function modifier_annihilate:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_annihilate_mute = class({})

function modifier_annihilate_mute:IsDebuff() return true end

function modifier_annihilate_mute:CheckState()
	return {
		[MODIFIER_STATE_MUTED] = true,
	}
end

function modifier_annihilate_mute:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_annihilate_mute:OnRefresh(kv)
	self:OnCreated(kv)
end
