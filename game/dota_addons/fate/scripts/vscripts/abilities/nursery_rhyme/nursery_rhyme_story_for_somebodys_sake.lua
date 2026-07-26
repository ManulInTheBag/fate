-- nursery_rhyme_story_for_somebodys_sake — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/nursery_rhyme/nursery_rhyme_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

nursery_rhyme_story_for_somebodys_sake = class({})

LinkLuaModifier("modifier_story_for_someones_sake", "abilities/nursery_rhyme/nursery_rhyme_story_for_somebodys_sake", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_story_for_someones_sake_enemy", "abilities/nursery_rhyme/nursery_rhyme_story_for_somebodys_sake", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_story_for_someones_sake_cooldown", "abilities/nursery_rhyme/nursery_rhyme_story_for_somebodys_sake", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/nursery_rhyme_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnNRComboStart, OnNRComboDeath, OnNRComboEnd

OnNRComboStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability	
	local cooldown = keys.ability:GetCooldown(1)
	
	if GameRules:GetGameTime() > 60 + _G.RoundStartTime then
		ability:EndCooldown()
		caster:GiveMana(ability:GetManaCost(1)) 
		caster:Stop()
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Be_Cast_Now")
		return 
	end
	if caster.bIsQGGImproved then 
		ReduceCooldown(ability, 70)
		cooldown = cooldown - 70
	end
	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(cooldown)
	caster:AddNewModifier(caster, ability, "modifier_story_for_someones_sake_cooldown", {duration = cooldown})
	
	caster.bIsNRComboSuccessful = false
	caster.nNRComboQuoteCount = 1

	-- apply timer modifier for caster and all enemy heroes
	caster:AddNewModifier(caster, ability, "modifier_story_for_someones_sake", {})
    LoopOverPlayers(function(player, playerID, playerHero)
    	if playerHero ~= caster then
    		playerHero:AddNewModifier(caster, ability, "modifier_story_for_someones_sake_enemy", {})
    	end
    end)

    GameRules:SendCustomMessage("<font color='#FF0000'>You feel the very fabric of time being twisted.</font>", 0, 0)

    EmitGlobalSound("NR.GlobalPing")
    --EmitGlobalSound("Piano")
    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.music == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Piano"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
    caster:EmitSound("NR.Tick")
end

OnNRComboDeath = function(keys)
	local caster = keys.caster
	local ability = keys.ability

	caster:StopSound("NR.Tick")
	StopGlobalSound("Piano")

    --[[LoopOverPlayers(function(player, playerID, playerHero)
    	if playerHero ~= caster then
    		playerHero:RemoveModifierByName("modifier_story_for_someones_sake_enemy")
    	end
    end)]]
	EmitGlobalSound("Hero_Wisp.Tether.Stun")
    GameRules:SendCustomMessage("<font color='#58ACFA'>The fabric of time has become normal again.</font>", 0, 0)
end

OnNRComboEnd = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:StopSound("NR.Tick")
	if caster:IsAlive() and _G.CurrentGameState == "FATE_ROUND_ONGOING" then 
		caster.bIsNRComboSuccessful = true 
		GameRules:SendCustomMessage("<font color='#FF0000'>Once again denying reality to the reader.</font>", 0, 0)
		EmitGlobalSound("Hero_Wisp.Tether.Stun")
		EmitGlobalSound("Nursery_Rhyme_Combo_4")

		local RedScreenFx = ParticleManager:CreateParticle("particles/custom/screen_red_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
	end
end


function nursery_rhyme_story_for_somebodys_sake:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: nursery_rhyme_ability / OnNRComboStart
	OnNRComboStart({
		caster = caster,
		ability = self,
		target = caster,
		TimeLimit = self:GetSpecialValueFor("time_limit")
	})
end

modifier_story_for_someones_sake = class({})

function modifier_story_for_someones_sake:GetEffectName() return "particles/units/heroes/hero_abaddon/abaddon_borrowed_time.vpcf" end
function modifier_story_for_someones_sake:GetEffectAttachType() return PATTACH_ABSORIGIN end

function modifier_story_for_someones_sake:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_story_for_someones_sake:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "29.8" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(29.8, true)
	end
	self:StartIntervalThink(5)
end

function modifier_story_for_someones_sake:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_story_for_someones_sake:OnDestroy()
	if not IsServer() then return end
	-- DD RunScript: nursery_rhyme_ability / OnNRComboEnd
	OnNRComboEnd({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

function modifier_story_for_someones_sake:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: nursery_rhyme_ability / PingLocationForEnemies
	PingLocationForEnemies({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

function modifier_story_for_someones_sake:OnDeath(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: nursery_rhyme_ability / OnNRComboDeath
	OnNRComboDeath({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker
	})
end

modifier_story_for_someones_sake_enemy = class({})

function modifier_story_for_someones_sake_enemy:IsDebuff() return true end
function modifier_story_for_someones_sake_enemy:GetEffectName() return "particles/econ/items/wraith_king/wraith_king_ti6_bracer/wraith_king_ti6_witness_ambient_body.vpcf" end
function modifier_story_for_someones_sake_enemy:GetEffectAttachType() return PATTACH_ABSORIGIN end

function modifier_story_for_someones_sake_enemy:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "29.8" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(29.8, true)
	end
end

function modifier_story_for_someones_sake_enemy:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_story_for_someones_sake_cooldown = class({})

function modifier_story_for_someones_sake_cooldown:IsDebuff() return true end
function modifier_story_for_someones_sake_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end
