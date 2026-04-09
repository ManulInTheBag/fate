scathach_mentor = class({})
LinkLuaModifier("modifier_scathach_pupil", "abilities/scathach/scathach_mentor", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_pupil_buff", "abilities/scathach/scathach_mentor", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_pupil_scatha_buff", "abilities/scathach/scathach_mentor", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_pupil_str_quest", "abilities/scathach/scathach_mentor", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_pupil_agi_quest", "abilities/scathach/scathach_mentor", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scathach_pupil_int_quest", "abilities/scathach/scathach_mentor", LUA_MODIFIER_MOTION_NONE)

function scathach_mentor:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if target:GetName() == "gille_gigantic_horror" or target:GetName() == "f16_at_vinta" or target:GetName() == "caster_5th_ancient_dragon" or target:GetName() == "npc_dota_hero_monkey_king" or target:GetName() == "npc_dota_hero_target_dummy" then
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
	self.isFinished = 0
end

function modifier_scathach_pupil:IsHidden()
	return false 
end

function modifier_scathach_pupil:RemoveOnDeath()
	return false
end
function modifier_scathach_pupil:CheckForConditions()
	local parent = self:GetParent()
	if self.str_bonus == 5 and self.agi_bonus == 5 and self.int_bonus == 5 then
		local caster_name =  PlayerResource:GetPlayerName(self:GetParent():GetPlayerID())
		GameRules:SendCustomMessage("".. caster_name .." completed all their trainings!", 0, 0)
		self.isFinished = 1
		self:StartIntervalThink(0.5)
	end
	if parent:GetName() == "npc_dota_hero_juggernaut" then 
		if self.str_bonus == 5 and self.agi_bonus == 5 then
			local caster_name =  PlayerResource:GetPlayerName(self:GetParent():GetPlayerID())
			GameRules:SendCustomMessage("".. caster_name .." completed all their trainings!", 0, 0)
			self.isFinished = 1
			self:StartIntervalThink(0.5)
		end

	end
end

function modifier_scathach_pupil:OnIntervalThink()
	if self.isFinished ~= 1 then return end
	local distance = (self:GetCaster():GetAbsOrigin() - self:GetParent():GetAbsOrigin()):Length2D()
	if distance <= 1200 then 
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_scathach_pupil_buff", {duration = 0.75})
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_scathach_pupil_scatha_buff", {duration = 0.75})
	end
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
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, }
end





modifier_scathach_pupil_str_quest = class({})

function modifier_scathach_pupil_str_quest:OnCreated()
	
	self.damage_taken_total = 0
	self.damage_taken_request = 30000
	self:SetStackCount(0)
end



function modifier_scathach_pupil_str_quest:OnTakeDamage(args)
	if args.unit ~= self:GetParent() then return end
	if self:GetStackCount() >= 100 then 
		self:GetParent():FindModifierByName("modifier_scathach_pupil").str_bonus = 5
		local caster_name =  PlayerResource:GetPlayerName(self:GetParent():GetPlayerID())
		GameRules:SendCustomMessage("".. caster_name .." just completed strength training!", 0, 0)
		if IsServer() then
			self:GetParent():FindModifierByName("modifier_scathach_pupil"):CheckForConditions()
		end
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
	self.assist_request = 12
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
			if IsServer() then
				self:GetParent():FindModifierByName("modifier_scathach_pupil"):CheckForConditions()
			end
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
	self.mana_spent_request = 20000
	self:SetStackCount(0)
end

function modifier_scathach_pupil_int_quest:OnSpentMana(args)
	if args.unit ~= self:GetParent() then return end
	self.mana_spent = self.mana_spent + args.ability:GetManaCost(args.ability:GetLevel()) 
	self:SetStackCount(100 * self.mana_spent / self.mana_spent_request)
	--print(self.mana_spent)
	if self:GetStackCount() >= 100 then 
			self:GetParent():FindModifierByName("modifier_scathach_pupil").int_bonus = 5
			local caster_name =  PlayerResource:GetPlayerName(self:GetParent():GetPlayerID())
			GameRules:SendCustomMessage("".. caster_name .." just completed intellect training!", 0, 0)
			if IsServer() then
				self:GetParent():FindModifierByName("modifier_scathach_pupil"):CheckForConditions()
			end
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




modifier_scathach_pupil_buff = class({})





function modifier_scathach_pupil_buff:IsHidden()
	return false 
end

function modifier_scathach_pupil_buff:RemoveOnDeath()
	return true
end

function modifier_scathach_pupil_buff:IsDebuff()
	return false 
end



function modifier_scathach_pupil_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end



function modifier_scathach_pupil_buff:GetModifierMagicalResistanceBonus()
	return 10
end

 

function modifier_scathach_pupil_buff:GetModifierPhysicalArmorBonus()
	return 4
end


modifier_scathach_pupil_scatha_buff = class({})





function modifier_scathach_pupil_scatha_buff:IsHidden()
	return false 
end

function modifier_scathach_pupil_scatha_buff:RemoveOnDeath()
	return true
end

function modifier_scathach_pupil_scatha_buff:IsDebuff()
	return false 
end



function modifier_scathach_pupil_scatha_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, }
end


function modifier_scathach_pupil_scatha_buff:GetModifierTotalDamageOutgoing_Percentage()
	return 10
end


 
