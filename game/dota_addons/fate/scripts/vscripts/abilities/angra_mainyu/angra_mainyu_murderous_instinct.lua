angra_mainyu_murderous_instinct = class({})
modifier_murderous_instinct = class({})
modifier_murderous_instinct_crit = class({})
modifier_murderous_instinct_passive = class({})

LinkLuaModifier("modifier_murderous_instinct", "abilities/angra_mainyu/angra_mainyu_murderous_instinct", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_murderous_instinct_crit", "abilities/angra_mainyu/angra_mainyu_murderous_instinct", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_murderous_instinct_passive", "abilities/angra_mainyu/angra_mainyu_murderous_instinct", LUA_MODIFIER_MOTION_NONE)

function angra_mainyu_murderous_instinct:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_murderous_instinct", { Duration = self:GetSpecialValueFor("duration") })
end

function angra_mainyu_murderous_instinct:OnUpgrade()
	self:GetCaster():FindAbilityByName("avenger_unlimited_remains"):SetLevel(self:GetLevel())
end

function angra_mainyu_murderous_instinct:GetIntrinsicModifierName()
	return "modifier_murderous_instinct_passive"
end

--Murderous Instinct buff 

function modifier_murderous_instinct:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_TAKEDAMAGE,
			 MODIFIER_EVENT_ON_ATTACK_START,
			MODIFIER_EVENT_ON_ATTACK_LANDED }
end

if IsServer() then 
	function modifier_murderous_instinct:OnAttackStart(args)
		if args.attacker ~= self:GetParent() then return end

		local crit_damage = self:GetAbility():GetSpecialValueFor("crit_multiplier")
		local bonus_crit_damage = self:GetAbility():GetSpecialValueFor("bonus_crit_damage") * (100 - self:GetParent():GetHealthPercent())
		local crit_chance = self:GetAbility():GetSpecialValueFor("critical_rate")
		local bonus_crit_rate = self:GetAbility():GetSpecialValueFor("bonus_crit_chance") * (100 - self:GetParent():GetHealthPercent())

		if math.random(1, 100) <= crit_chance + bonus_crit_rate then
			self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_murderous_instinct_crit", { Duration = 1, CritDamage = crit_damage + bonus_crit_damage })
		end
	end

	function modifier_murderous_instinct:OnTakeDamage(args)
		if args.unit ~= self:GetParent() then return end

		local mana_conversion = self:GetAbility():GetSpecialValueFor("mana_conversion")
		local caster = self:GetParent()
		local attacker = args.attacker
		caster:GiveMana(args.damage * mana_conversion / 100)
	end
end

if IsServer() then
	function modifier_murderous_instinct_crit:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end
		DoDamage(args.attacker, args.target, self:GetSpecialValueFor("on_attack_damage"), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
	end
end


function modifier_murderous_instinct:IsHidden()
	return false 
end

function modifier_murderous_instinct:IsPermanent()
	return true 
end

--Crit buff

function modifier_murderous_instinct_crit:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
			 --MODIFIER_EVENT_ON_ATTACK_LANDED
			  }
end

function modifier_murderous_instinct_crit:OnCreated(args)
	self.CritDamage = args.CritDamage
end

if IsServer() then
	function modifier_murderous_instinct_crit:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end
		
		args.target:EmitSound("DOTA_Item.Daedelus.Crit")
		self:Destroy()
	end
end

function modifier_murderous_instinct_crit:GetModifierPreAttack_CriticalStrike()
	return self.CritDamage
end

function modifier_murderous_instinct_crit:IsHidden()
	return true 
end

function modifier_murderous_instinct_crit:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

--Passve for other checkers

function modifier_murderous_instinct_passive:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED
	 }
end

if IsServer() then
	function modifier_murderous_instinct_passive:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() return end

		if args.target:GetName() == "avenger_remain" then
			DoDamage(args.attacker, args.target, 200, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
		end
	end
end

function modifier_murderous_instinct_passive:IsHidden()
	return true
end