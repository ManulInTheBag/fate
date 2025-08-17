scathach_mentor = class({})
LinkLuaModifier("modifier_scathach_pupil", "abilities/scathach/scathach_mentor", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_pupil_str_quest", "abilities/scathach/scathach_mentor", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_pupil_agi_quest", "abilities/scathach/scathach_mentor", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_pupil_int_quest", "abilities/scathach/scathach_mentor", LUA_MODIFIER_MOTION_NONE)

function scathach_mentor:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if target:GetName() == "gille_gigantic_horror" or target:GetName() == "f16_at_vinta" or target:GetName() == "caster_5th_ancient_dragon" or target:GetName() == "npc_dota_hero_monkey_king" then
		self:StartCooldown(10)
		return 
	end
	target:AddNewModifier(caster, self, "modifier_scathach_pupil", {duration = -1})
	target:AddNewModifier(caster, self, "modifier_scathach_pupil_str_quest", {duration = -1})
	target:AddNewModifier(caster, self, "modifier_scathach_pupil_agi_quest", {duration = -1})
	if target:GetName() ~= "npc_dota_hero_juggernaut" then
		target:AddNewModifier(caster, self, "modifier_scathach_pupil_int_quest", {duration = -1})
	end
	caster:SwapAbilities("scathach_mentor", "scathach_wisdom_of_dun_scaith", false, true)
	local caster_name =  PlayerResource:GetPlayerName(caster:GetPlayerID())
	local target_name =  PlayerResource:GetPlayerName(target:GetPlayerID())
	
	GameRules:SendCustomMessage("<font color='#800125ff'>".. caster_name .."</font> selected <font color='#0083E3'>".. target_name .."</font> as her pupil!", 0, 0)
end


modifier_scathach_pupil = class({})

function modifier_scathach_pupil:OnCreated()
	self.str_bonus = 0
	self.agi_bonus = 0
	self.int_bonus = 0
end

function modifier_scathach_pupil:IsHidden()
	return false 
end

function modifier_scathach_pupil:RemoveOnDeath()
	return false
end

function modifier_scathach_pupil:IsDebuff()
	return false 
end

function modifier_scathach_pupil:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_scathach_pupil:GetModifierBonusStats_Strength()
	return  self.str_bonus
end
function modifier_scathach_pupil:GetModifierBonusStats_Agility()
	return  self.agi_bonus
end
function modifier_scathach_pupil:GetModifierBonusStats_Intellect()
	return  self.int_bonus
end

function modifier_scathach_pupil:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, 
	MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,  }
end

modifier_scathach_pupil_str_quest = class({})

function modifier_scathach_pupil_str_quest:OnCreated()
	
	self.damage_taken_total = 0
	self.damage_taken_request = 5000
	self:SetStackCount(0)
end



function modifier_scathach_pupil_str_quest:OnTakeDamage(args)
	if args.unit ~= self:GetParent() then return end
	if self:GetStackCount() >= 100 then 
		self:GetParent():FindModifierByName("modifier_scathach_pupil").str_bonus = 5
		local caster_name =  PlayerResource:GetPlayerName(self:GetParent():GetPlayerID())
		GameRules:SendCustomMessage("".. caster_name .." just completed strength training!", 0, 0)
		self:Destroy()
		return
	end
	self.damage_taken_total = self.damage_taken_total + math.min(args.original_damage, self:GetParent():GetMaxHealth())
	self:SetStackCount(100 * self.damage_taken_total/self.damage_taken_request)
	--print(self.damage_taken_total)
end


function modifier_scathach_pupil_str_quest:IsHidden()
	return false 
end

function modifier_scathach_pupil_str_quest:RemoveOnDeath()
	return false
end

function modifier_scathach_pupil_str_quest:IsDebuff()
	return false 
end

function modifier_scathach_pupil_str_quest:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end



modifier_scathach_pupil_agi_quest = class({})

function modifier_scathach_pupil_agi_quest:OnCreated()
	self.asisst_count = 0
	self.assist_request = 10
	self:SetStackCount(0)
	self:StartIntervalThink(3)
end

function modifier_scathach_pupil_agi_quest:OnIntervalThink()
	if not IsServer() then return end
	self.assist_count = self:GetParent():GetKills() + self:GetParent():GetAssists()/2
	self:SetStackCount(100 * self.assist_count / self.assist_request)
	if self:GetStackCount() >= 100 then 
			self:GetParent():FindModifierByName("modifier_scathach_pupil").agi_bonus = 5
			local caster_name =  PlayerResource:GetPlayerName(self:GetParent():GetPlayerID())
			GameRules:SendCustomMessage("".. caster_name .." just completed agility training!", 0, 0)
			self:Destroy()
		return
	end
end

function modifier_scathach_pupil_agi_quest:IsHidden()
	return false 
end

function modifier_scathach_pupil_agi_quest:RemoveOnDeath()
	return false
end

function modifier_scathach_pupil_agi_quest:IsDebuff()
	return false 
end

function modifier_scathach_pupil_agi_quest:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


modifier_scathach_pupil_int_quest = class({})

function modifier_scathach_pupil_int_quest:OnCreated()
	self.mana_spent = 0
	self.mana_spent_request = 5000
	self:SetStackCount(0)
end

function modifier_scathach_pupil_int_quest:OnSpentMana(args)
	self.mana_spent = self.mana_spent + args.ability:GetManaCost(args.ability:GetLevel()) 
	self:SetStackCount(100 * self.mana_spent / self.mana_spent_request)
	--print(self.mana_spent)
	if self:GetStackCount() >= 100 then 
			self:GetParent():FindModifierByName("modifier_scathach_pupil").int_bonus = 5
			local caster_name =  PlayerResource:GetPlayerName(self:GetParent():GetPlayerID())
			GameRules:SendCustomMessage("".. caster_name .." just completed intellect training!", 0, 0)
			self:Destroy()
		return
	end
end
function modifier_scathach_pupil_int_quest:IsHidden()
	return false 
end

function modifier_scathach_pupil_int_quest:Getmodifier()
	return false 
end
function modifier_scathach_pupil_int_quest:DeclareFunctions()
	return { MODIFIER_EVENT_ON_SPENT_MANA ,
		}
end

function modifier_scathach_pupil_int_quest:RemoveOnDeath()
	return false
end

function modifier_scathach_pupil_int_quest:IsDebuff()
	return false 
end

function modifier_scathach_pupil_int_quest:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
