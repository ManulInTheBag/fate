LinkLuaModifier("modifier_arash_arrow_construction", "abilities/arash/arash_arrow_construction", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_max_stella_window", "abilities/arash/arash_arrow_construction", LUA_MODIFIER_MOTION_NONE)
arash_arrow_construction = class({})

function arash_arrow_construction:OnSpellStart()
	--self:GetConstructionBuff()
	local caster = self:GetCaster()
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then      
    	if caster:FindAbilityByName("arash_max_stella"):IsCooldownReady() then
    		caster:AddNewModifier(caster, self, "modifier_max_stella_window", { Duration = 4 })
        end
    end
end

modifier_max_stella_window = class({})

if IsServer() then
	function modifier_max_stella_window:OnCreated(args)
		local hero = self:GetParent()
		hero:SwapAbilities("arash_stella", "arash_max_stella", false, true) 
	end

	function modifier_max_stella_window:OnRefresh(args)
	end

	function modifier_max_stella_window:OnDestroy()	
		local hero = self:GetParent()

		hero:SwapAbilities("arash_stella", "arash_max_stella", true, false) 
	end
end

function modifier_max_stella_window:IsHidden()
	return true 
end

function modifier_max_stella_window:RemoveOnDeath()
	return true
end


function arash_arrow_construction:GetConstructionBuff()
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage") + caster:GetLevel()*self:GetSpecialValueFor("damage_per_level") + (caster.ArashLoadMagicalEnergy and caster.MasterUnit2:FindAbilityByName("arash_load_magical_energy"):GetSpecialValueFor("agi_scale") * caster:GetAgility() or 0)
	local range = self:GetSpecialValueFor("range") + (caster.ArashLoadMagicalEnergy and caster.MasterUnit2:FindAbilityByName("arash_load_magical_energy"):GetSpecialValueFor("bonus_range") or 0)
	local buffDuration = self:GetSpecialValueFor("duration")
	caster:AddNewModifier(caster, self, "modifier_arash_arrow_construction", {duration  = buffDuration, damage = damage, range = range})
end

modifier_arash_arrow_construction = class({})

function modifier_arash_arrow_construction:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROJECTILE_NAME,
		MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,

	}
end


function modifier_arash_arrow_construction:OnCreated(args)
	if not IsServer() then return end
	self.range = args.range
	self.damage = args.damage
	self.speed = self.range * 2
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.projectile = "particles/arash/arash_base_attack_buffed.vpcf"
end

function modifier_arash_arrow_construction:GetModifierProjectileName()
	return self.projectile
end

function modifier_arash_arrow_construction:GetModifierProjectileSpeedBonus()
	return self.speed
end

function modifier_arash_arrow_construction:GetModifierAttackRangeBonus()
	return self.range
end

function modifier_arash_arrow_construction:OnAttackLanded(args)
	if args.attacker ~= self.parent then return end
	DoDamage(self.parent, args.target, self.damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
	args.target:EmitSound("arash_attack_hit")
	if self.parent.ArashLoadMagicalEnergy then
		local cd1 = self.parent:FindAbilityByName("arash_star_arrow"):GetCooldownTimeRemaining()
		self.parent:FindAbilityByName("arash_star_arrow"):EndCooldown()
		if cd1 > 2 then 
			self.parent:FindAbilityByName("arash_star_arrow"):StartCooldown(cd1 - 2)
		end
		local cd2 = self.parent:FindAbilityByName("arash_curved_fire"):GetCooldownTimeRemaining()
		self.parent:FindAbilityByName("arash_curved_fire"):EndCooldown()
		if cd2 > 2 then 
			self.parent:FindAbilityByName("arash_curved_fire"):StartCooldown(cd2 - 2)
		end
		local cd3 = self.parent:FindAbilityByName("arash_independent_action"):GetCooldownTimeRemaining()
		self.parent:FindAbilityByName("arash_independent_action"):EndCooldown()
		if cd3 > 2 then 
			self.parent:FindAbilityByName("arash_independent_action"):StartCooldown(cd3 - 2)
		end
		local cd4 = self.parent:FindAbilityByName("arash_stella"):GetCooldownTimeRemaining()
		self.parent:FindAbilityByName("arash_stella"):EndCooldown()
		if cd4 > 2 then 
			self.parent:FindAbilityByName("arash_stella"):StartCooldown(cd4 - 2)
		end
	end
	self:Destroy()
end

function modifier_arash_arrow_construction:IsDebuff()                                                             return false end
function modifier_arash_arrow_construction:IsPurgable()                                                           return false end
function modifier_arash_arrow_construction:IsPurgeException()                                                     return false end
function modifier_arash_arrow_construction:RemoveOnDeath()                                                        return true end
function modifier_arash_arrow_construction:IsHidden()															  return false end