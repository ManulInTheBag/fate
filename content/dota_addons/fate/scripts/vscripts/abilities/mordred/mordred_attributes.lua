LinkLuaModifier("modifier_mordred_bc", "abilities/mordred/mordred_attributes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mordred_bc_cooldown", "abilities/mordred/mordred_attributes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mordred_rampage", "abilities/mordred/mordred_attributes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mordred_rampage_stack", "abilities/mordred/mordred_attributes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mordred_overload", "abilities/mordred/mordred_attributes", LUA_MODIFIER_MOTION_NONE)

mordred_overload_attribute = class({})

function mordred_overload_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_mordred_overload", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

mordred_pedigree_attribute = class({})

function mordred_pedigree_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero:FindAbilityByName("mordred_pedigree"):SetLevel(2)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

mordred_curse_attribute = class({})

function mordred_curse_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	hero:SwapAbilities("fate_empty1", "mordred_curse_passive", false, true)

	hero.CurseOfRetributionAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

mordred_bc_attribute = class({})

function mordred_bc_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_mordred_bc", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

mordred_rampage_attribute = class({})

function mordred_rampage_attribute:OnSpellStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
	    	hero:AddNewModifier(hero, self, "modifier_mordred_rampage", {})
			return nil
		else
			return 1
		end
	end)

	hero.RampageAcquired = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - self:GetManaCost(self:GetLevel()))
end

modifier_mordred_bc = class({})

function modifier_mordred_bc:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_TAKEDAMAGE,
			 }
end

function modifier_mordred_bc:IsHidden() 
	return true 
end

function modifier_mordred_bc:IsPermanent()
	return true
end

function modifier_mordred_bc:RemoveOnDeath()
	return false
end

function modifier_mordred_bc:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_mordred_bc:OnTakeDamage(args)
	self.parent = self:GetParent()
	local caster = self:GetParent()
	if args.unit ~= self.parent then return end
	if args.damage > 1500 then return end
	if caster:HasModifier("modifier_mordred_bc_cooldown") then return end

	if self.parent:GetHealth()<=0 then
		local ability = caster:FindAbilityByName("mordred_rush")
		local damage = ability:GetSpecialValueFor("damage") + 2*ability:GetSpecialValueFor("damage_per_second")
		local speed = ability:GetSpecialValueFor("speed") + 2*ability:GetSpecialValueFor("speed_per_second")
		self.parent:SetHealth(args.damage)
		caster:AddNewModifier(caster, caster:FindAbilityByName("mordred_pedigree"), "modifier_mordred_bc_cooldown", {duration = 99})
		StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_CAST_ABILITY_4_END, rate=1.0})

		caster:EmitSound("mordred_rush")
		caster.debil = args.attacker
		caster:AddNewModifier(caster, ability, "modifier_mordred_rush", {damage = damage,
																	speed = speed,
																	dolbayob_factor = 1})

		giveUnitDataDrivenModifier(caster, caster, "jump_pause_nosilence", 99999)
	end
end

modifier_mordred_rampage = class({})

function modifier_mordred_rampage:IsHidden() 
	return true 
end

function modifier_mordred_rampage:IsPermanent()
	return true
end

function modifier_mordred_rampage:RemoveOnDeath()
	return false
end

function modifier_mordred_rampage:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_mordred_rampage:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED,
			 }
end

function modifier_mordred_rampage:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end

	self.parent = self:GetParent()
	args.target:AddNewModifier(self.parent, self.parent:FindAbilityByName("mordred_pedigree"), "modifier_mordred_rampage_stack", {duration = 10})
	if IsServer() then
		DoDamage(self.parent, args.target, args.target:FindModifierByName("modifier_mordred_rampage_stack"):GetStackCount()*10, DAMAGE_TYPE_MAGICAL, 0, self.parent:FindAbilityByName("mordred_pedigree"), false)
	end
end

modifier_mordred_rampage_stack = class({})

function modifier_mordred_rampage_stack:GetTexture()
	return "custom/mordred/mordred_rampage"
end

function modifier_mordred_rampage_stack:IsHidden() return false end

function modifier_mordred_rampage_stack:IsDebuff() return true end

function modifier_mordred_rampage_stack:OnCreated()
	self:SetStackCount((self:GetStackCount() or 0) + 1)
end

function modifier_mordred_rampage_stack:OnRefresh()
	self:OnCreated()
end

modifier_mordred_bc_cooldown = class({})

function modifier_mordred_bc_cooldown:GetTexture()
	return "custom/mordred/mordred_battle_continuation"
end

function modifier_mordred_bc_cooldown:IsHidden()
	return false 
end

function modifier_mordred_bc_cooldown:RemoveOnDeath()
	return false
end

function modifier_mordred_bc_cooldown:IsDebuff()
	return true 
end

function modifier_mordred_bc_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

modifier_mordred_overload = class({})

function modifier_mordred_overload:IsHidden() 
	return true
end

function modifier_mordred_overload:IsPermanent()
	return true
end

function modifier_mordred_overload:RemoveOnDeath()
	return false
end

function modifier_mordred_overload:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_mordred_overload:Doom()
	local caster = self:GetParent()
	local radius = 400
	local kappa = (caster:FindAbilityByName("mordred_slash"):GetLevel()+caster:FindAbilityByName("mordred_mana_burst_hit"):GetLevel()+caster:FindAbilityByName("mordred_rush"):GetLevel())
	local damage = kappa*10

	local iPillarFx = ParticleManager:CreateParticle("particles/custom/mordred/purge_the_unjust/ruler_purge_the_unjust_a.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl( iPillarFx, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl( iPillarFx, 1, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl( iPillarFx, 2, caster:GetAbsOrigin())

    Timers:CreateTimer(1.0, function()
        ParticleManager:DestroyParticle(iPillarFx, false)
        ParticleManager:ReleaseParticleIndex(iPillarFx)
    end)

    --[[if caster.CurseOfRetributionAcquired then
        caster:FindAbilityByName("mordred_curse_passive"):ShieldCharge()
    end]]

    local visiondummy = SpawnVisionDummy(caster, caster:GetAbsOrigin(), radius, 2, true)

    local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
    for k,v in pairs(targets) do
    	if not v:IsMagicImmune() then           
	        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, caster:FindAbilityByName("mordred_pedigree"), false)
	        v:AddNewModifier(caster, self, "modifier_stunned", {Duration = kappa*0.05})
	        EmitSoundOn("mordred_lightning", v)
	        Timers:CreateTimer(0.01, function()
	            local particle = ParticleManager:CreateParticle("particles/custom/mordred/zuus_lightning_bolt.vpcf", PATTACH_WORLDORIGIN, v)
	            local target_point = v:GetAbsOrigin()
	            ParticleManager:SetParticleControl(particle, 0, Vector(target_point.x, target_point.y, target_point.z))
	            ParticleManager:SetParticleControl(particle, 1, Vector(target_point.x, target_point.y, 2000))
	            ParticleManager:SetParticleControl(particle, 2, Vector(target_point.x, target_point.y, target_point.z))
	        end)     
	    end
    end
end