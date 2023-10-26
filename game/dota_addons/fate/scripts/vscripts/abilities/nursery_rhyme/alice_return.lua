LinkLuaModifier("modifier_alice_return", "abilities/nursery_rhyme/alice_return", LUA_MODIFIER_MOTION_NONE)

alice_return = class({})

function alice_return:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_alice_return", {duration = self:GetSpecialValueFor("duration")})
end

alice_return_activate = class({})

function alice_return_activate:OnSpellStart()
	local caster = self:GetCaster()

	caster:RemoveModifierByName("modifier_alice_return")
end

modifier_alice_return = class({})

function modifier_alice_return:OnCreated()
	if not IsServer() then return end

	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.initloc = self.parent:GetAbsOrigin()

	self.damage_taken = 0

	if self.parent:GetAbilityByIndex(3):GetName() == "alice_return" then	    		
		self.parent:SwapAbilities("alice_return_activate", "alice_return", true, false)	
	end
end

function modifier_alice_return:OnTakeDamage(args)
	if args.unit ~= self:GetParent() then return end

	self.damage_taken = self.damage_taken + args.damage
end

function modifier_alice_return:OnDestroy()
	if not IsServer() then return end

	if self.parent:GetAbilityByIndex(3):GetName() == "alice_return_activate" then	    		
		self.parent:SwapAbilities("alice_return_activate", "alice_return", false, true)	
	end

	local currloc = self.parent:GetAbsOrigin()

	local stun_dur = self.ability:GetSpecialValueFor("stun_duration")
	local damage = self.ability:GetSpecialValueFor("damage")
	local mult = self.ability:GetSpecialValueFor("heal_perc")/100

	if self.parent and self.parent:IsAlive() then
		self.parent:EmitSound("Hero_Weaver.TimeLapse")

		self.parent:Heal(self.damage_taken * mult, self.parent)
		HardCleanse(self.parent)

		FindClearSpaceForUnit(self.parent, self.initloc, true)
	
		local iParticleIndex = ParticleManager:CreateParticle("particles/custom/nursery_rhyme/nursery_timelapse.vpcf", PATTACH_CUSTOMORIGIN, self.parent)
		ParticleManager:SetParticleControl(iParticleIndex, 0, self.initloc)
		ParticleManager:SetParticleControl(iParticleIndex, 2, currloc)

		Timers:CreateTimer(1.5, function()
			ParticleManager:DestroyParticle(iParticleIndex, false)
			ParticleManager:ReleaseParticleIndex(iParticleIndex)
			return
		end)

		local enemies = FATE_FindUnitsInLine(
								        self.parent:GetTeamNumber(),
								        self.initloc,
								        currloc,
								        150,
										DOTA_UNIT_TARGET_TEAM_ENEMY,
										DOTA_UNIT_TARGET_ALL,
										DOTA_UNIT_TARGET_FLAG_NONE,
										FIND_CLOSEST
    								)

		if enemies and #enemies>0 then
		    for _, enemy in pairs(enemies) do
		       	enemy:AddNewModifier(self.parent, self.ability, "modifier_stunned", { duration = stun_dur })
			    DoDamage(self.parent, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
			    --EmitSoundOn("ryougi_hit", enemy)
		    end
		end
	end
end