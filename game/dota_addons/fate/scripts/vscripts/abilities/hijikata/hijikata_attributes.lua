hijikata_shinsengumi_attribute = class({})
hijikata_battle_continuation_attribute = class({})
hijikata_eternal_madness_attribute = class({})
hijikata_tactics_attribute = class({})
hijikata_fierce_sincerity_attribute = class({})

LinkLuaModifier("modifier_hijikata_haori", "abilities/hijikata/hijikata_attributes", LUA_MODIFIER_MOTION_NONE)


function hijikata_shinsengumi_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()


	Timers:CreateTimer(function()
		if hero:IsAlive() then 
			hero:AddNewModifier(hero, self, "modifier_hijikata_haori", {})
			return nil
		else
			return 1
		end
	end)

	hero.IsShinsengumiAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end


modifier_hijikata_haori = modifier_hijikata_haori or class({})

function modifier_hijikata_haori:IsHidden()                                                                       return true end
function modifier_hijikata_haori:IsDebuff()                                                                       return false end
function modifier_hijikata_haori:IsPurgable()                                                                     return false end
function modifier_hijikata_haori:IsPurgeException()                                                               return false end
function modifier_hijikata_haori:RemoveOnDeath()                                                                  return false end
function modifier_hijikata_haori:IsDimensionException()                                                           return true end
function modifier_hijikata_haori:AllowIllusionDuplicate()                                                         return true end
function modifier_hijikata_haori:GetPriority()                                                                    return MODIFIER_PRIORITY_LOW end
function modifier_hijikata_haori:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_MODEL_CHANGE
                    }
    return tFunc
end
function modifier_hijikata_haori:GetModifierModelChange(keys)
    return self.sModelName
end
function modifier_hijikata_haori:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    if IsServer() then
        self.sModelName = "models/hijikata/hijikata_0_14_idle_haori.vmdl"
    end
end
function modifier_hijikata_haori:OnRefresh(hTable)
    self:OnCreated(hTable)
end
--========================================--

function hijikata_battle_continuation_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()	
	
	hero.IsHijikataBcAcquired = true
	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function hijikata_eternal_madness_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero:FindAbilityByName("hijikata_laws"):SetLevel(2)


	hero.IsHijikataEternalMadnessAcquired = true
	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function hijikata_tactics_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()


	hero.IsHijikataTacticsAcquired = true
	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

function hijikata_fierce_sincerity_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()


	hero.IsHijikataSincerityAcquired = true
	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end
