-- ward familiar: 3000 phys block, magic immune, no collision, chip-damage on hit
modifier_ward_dmg_reduce = class({})

function modifier_ward_dmg_reduce:IsPurgable() return false end

function modifier_ward_dmg_reduce:CheckState()
	return { [MODIFIER_STATE_MAGIC_IMMUNE] = true,
	         [MODIFIER_STATE_NO_UNIT_COLLISION] = true }
end

function modifier_ward_dmg_reduce:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK, MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_ward_dmg_reduce:GetModifierPhysical_ConstantBlock() return 3000 end

function modifier_ward_dmg_reduce:OnTakeDamage(args)
	if not IsServer() then return end
	local ward = self:GetParent()
	if args.unit ~= ward then return end
	-- any damage instance chips a fixed amount off the ward, with a short
	-- cooldown so multi-hit spells count as one hit
	if ward.dmgcooldown == true then return end
	ward.dmgcooldown = true
	local dmg = 2
	if args.attacker:GetClassname() == "npc_dota_base_additive" then
		dmg = 1
	end
	ApplyDamage({
		attacker = args.attacker,
		victim = ward,
		damage = dmg,
		damage_type = DAMAGE_TYPE_PURE,
	})
	Timers:CreateTimer(0.05, function()
		ward.dmgcooldown = false
	end)
end
