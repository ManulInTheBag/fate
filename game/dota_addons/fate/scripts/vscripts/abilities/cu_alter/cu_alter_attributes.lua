-- Attributes for Cú Chulainn Alter. Cast by the hero, paid from the Master's mana pool.
-- Each sets a flag the abilities branch on (and levels its additional ability where relevant):
--   1  Ríastrad          -> War Cry (D) to lvl 2; end-barrier grows with damage taken during it
--   2  Cursed Gáe Bolg   -> Spear Throw (W) applies uncleansable heal reduction (tier 3)
--   3  Roar of the Hound -> Roar (F) to lvl 2; enemies who endure the whole roar are feared
--   4  Battle Continuation-> survive an otherwise lethal blow; Battle Stance (E) grants a barrier

LinkLuaModifier("modifier_cu_alter_battle_cont",    "abilities/cu_alter/cu_alter_attributes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cu_alter_battle_cont_cd", "abilities/cu_alter/cu_alter_attributes", LUA_MODIFIER_MOTION_NONE)
-- fear modifier is defined in cu_alter_roar.lua; Battle Continuation reuses it for its desperate roar
LinkLuaModifier("modifier_cu_alter_fear", "abilities/cu_alter/cu_alter_roar", LUA_MODIFIER_MOTION_NONE)

cu_alter_attribute_1 = class({})
cu_alter_attribute_2 = class({})
cu_alter_attribute_3 = class({})
cu_alter_attribute_4 = class({})

local function acquire(self, flag)
	local hero = self:GetCaster():GetPlayerOwner():GetAssignedHero()
	hero[flag] = true

	-- pay from Master 1's mana pool
	local master = hero.MasterUnit
	if master then
		master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
	end
	return hero
end

function cu_alter_attribute_1:OnSpellStart()
	local hero = acquire(self, "CuAlterAttr1Acquired")
	local d = hero:FindAbilityByName("cu_alter_warcry")
	if d then d:SetLevel(2) end
end

function cu_alter_attribute_2:OnSpellStart()
	acquire(self, "CuAlterAttr2Acquired")
end

function cu_alter_attribute_3:OnSpellStart()
	local hero = acquire(self, "CuAlterAttr3Acquired")
	local f = hero:FindAbilityByName("cu_alter_roar")
	if f then f:SetLevel(2) end
end

function cu_alter_attribute_4:OnSpellStart()
	local hero = acquire(self, "CuAlterAttr4Acquired")
	if not hero:HasModifier("modifier_cu_alter_battle_cont") then
		hero:AddNewModifier(hero, self, "modifier_cu_alter_battle_cont", {})
	end
end

---------------------------------------------------------------------------------------------------
-- Battle Continuation: the first lethal blow (while ready) leaves Cú Chulainn alive; he is healed
-- back up, spears burst out of him, then it goes on cooldown.
modifier_cu_alter_battle_cont = modifier_cu_alter_battle_cont or class({})

function modifier_cu_alter_battle_cont:IsHidden()      return true end
function modifier_cu_alter_battle_cont:IsDebuff()      return false end
function modifier_cu_alter_battle_cont:IsPurgable()    return false end
function modifier_cu_alter_battle_cont:RemoveOnDeath() return false end

function modifier_cu_alter_battle_cont:OnCreated()
	self.ready = true
end

function modifier_cu_alter_battle_cont:DeclareFunctions()
	return { MODIFIER_PROPERTY_MIN_HEALTH }
end

function modifier_cu_alter_battle_cont:GetMinHealth()
	if not IsServer() then return end
	local parent = self:GetParent()
	if not self.ready or not parent:IsAlive() or not parent:IsRealHero() then
		return nil
	end

	-- a blow that would drop him to (near) death instead triggers Battle Continuation
	if parent:GetHealth() <= 2 then
		self.ready = false
		local ability = self:GetAbility()

		HardCleanse(parent)
		parent:EmitSound("cu_alter_sfx_roar_weak")	-- weakened roar as he refuses to die
		local reviveHp = parent:GetMaxHealth() * ability:GetSpecialValueFor("revive_heal_pct") / 100
		parent:SetHealth(math.max(parent:GetHealth(), reviveHp))

		local fx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_spears_burst.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControl(fx, 0, parent:GetAbsOrigin() + Vector(0, 0, 80))
		Timers:CreateTimer(0.6, function()
			ParticleManager:DestroyParticle(fx, true)
			ParticleManager:ReleaseParticleIndex(fx)
		end)

		-- desperate roar: refusing to die, he lets out a roar that fears nearby enemies (reuses the
		-- Roar of the Hound fear modifier). A ríastrad-flavoured breather when he cheats death.
		local waveFx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_roar_wind.vpcf", PATTACH_ABSORIGIN, parent)
		Timers:CreateTimer(1.5, function()
			ParticleManager:DestroyParticle(waveFx, false)
			ParticleManager:ReleaseParticleIndex(waveFx)
		end)
		local enemies = FindUnitsInRadius(
			parent:GetTeamNumber(),
			parent:GetAbsOrigin(),
			nil,
			ability:GetSpecialValueFor("bc_fear_radius"),
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false)
		for _, enemy in pairs(enemies) do
			if IsNotNull(enemy) then
				enemy:AddNewModifier(parent, ability, "modifier_cu_alter_fear", { duration = ability:GetSpecialValueFor("bc_fear_duration") })
			end
		end

		-- visible cooldown icon so the player can see when Battle Continuation is ready again.
		-- Its expiry re-arms the passive (no separate timer needed).
		parent:AddNewModifier(parent, ability, "modifier_cu_alter_battle_cont_cd", { duration = ability:GetSpecialValueFor("cooldown") })
	end

	return 1
end

---------------------------------------------------------------------------------------------------
-- Visible cooldown for Battle Continuation. Shows a debuff-style timer icon; when it ends it re-arms
-- the passive above.
modifier_cu_alter_battle_cont_cd = modifier_cu_alter_battle_cont_cd or class({})

function modifier_cu_alter_battle_cont_cd:IsHidden()      return false end
function modifier_cu_alter_battle_cont_cd:IsDebuff()      return true end
function modifier_cu_alter_battle_cont_cd:IsPurgable()    return false end
function modifier_cu_alter_battle_cont_cd:RemoveOnDeath() return false end

function modifier_cu_alter_battle_cont_cd:GetTexture()
	return "custom/cu_alter/sa3"
end

function modifier_cu_alter_battle_cont_cd:OnDestroy()
	if not IsServer() then return end
	local bc = self:GetParent():FindModifierByName("modifier_cu_alter_battle_cont")
	if bc then bc.ready = true end
end
