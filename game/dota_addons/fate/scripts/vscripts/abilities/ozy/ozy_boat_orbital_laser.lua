ozy_boat_orbital_laser = class({})
LinkLuaModifier("modifier_ozy_boat_orbital_laser_stacks", "abilities/ozy/ozy_boat_orbital_laser", LUA_MODIFIER_MOTION_NONE)
function ozy_boat_orbital_laser:OnChannelThink(fInterval)
    self.ChannelTime = self.ChannelTime + fInterval
    self:GetCaster():FaceTowards(self:GetCursorPosition())
	local manaSpendPerSec = self:GetSpecialValueFor("mana_drain_per_second") + (self:GetSpecialValueFor("mana_drain_increase_per_second")  * self.ChannelTime)
	if self:GetCaster():GetMana() < manaSpendPerSec * fInterval then
		--self:GetCaster():Interrupt()
	end
	ParticleManager:SetParticleControl(self.particle, 0, self.LaserPoint + Vector(0,0, 2500))
	ParticleManager:SetParticleControl(self.particle, 1, self.LaserPoint)
	self:GetCaster():SpendMana(manaSpendPerSec * fInterval)
	local tEnemies = FindUnitsInRadius(self:GetCaster():GetTeam(), self.LaserPoint , nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	local additiveStacks = self:GetSpecialValueFor("damage_per_second_increase") * fInterval
	for k, v in pairs(tEnemies) do
		self:ApplyLaserStacks(v, additiveStacks)
		DoDamage(self:GetCaster().ozy,v , fInterval* (self:GetSpecialValueFor("damage_per_second") + v:GetModifierStackCount("modifier_ozy_boat_orbital_laser_stacks", self:GetCaster().ozy)), self:GetAbilityDamageType(), 0, self, false)
	end
end

function ozy_boat_orbital_laser:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()
	ParticleManager:DestroyParticle(self.particle, false)
	ParticleManager:ReleaseParticleIndex(self.particle)
	

end

function ozy_boat_orbital_laser:OnSpellStart()
	self.ChannelTime = 0
	self.particle = ParticleManager:CreateParticle("particles/econ/items/faceless_void/faceless_void_jewel_of_aeons/phoenix_sunray.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleShouldCheckFoW(self.particle, false)
	local hCaster = self:GetCaster()
	local vTargetPoint = self:GetCursorPosition()
	self.LaserPoint = vTargetPoint
	-- local ozymandias = hCaster.ozy
	-- local boatOrigin = hCaster:GetAbsOrigin()
	-- local ozyOrigin = ozymandias:GetAbsOrigin()
	-- local direction = self:GetAnimeVectorTargetingMainDirection()
	-- self.direction = direction
	-- local width = self:GetSpecialValueFor("width")
	-- local range = self:GetAnimeVectorTargetingRange()
	-- local speed = 1000
	-- local timeToEnd = range/speed




end

function ozy_boat_orbital_laser:ApplyLaserStacks(target, stacksToAdd)
	local caster = self:GetCaster().ozy
	local stacks = 0

	if not target or not target:IsAlive() or target:IsNull() then return end

	if target:HasModifier("modifier_ozy_boat_orbital_laser_stacks") then
		stacks = target:FindModifierByName("modifier_ozy_boat_orbital_laser_stacks"):GetStackCount()
	end
	if target:GetName() == "npc_dota_hero_nevermore" then
		target:FindAbilityByName("demon_king_materialization"):ProckSpellAmpBonus()
	end

	target:AddNewModifier(caster, self, "modifier_ozy_boat_orbital_laser_stacks", {duration = self:GetSpecialValueFor("stacks_duration")})
	target:FindModifierByName("modifier_ozy_boat_orbital_laser_stacks"):SetStackCount(stacks + stacksToAdd)

end

modifier_ozy_boat_orbital_laser_stacks = class({})
function modifier_ozy_boat_orbital_laser_stacks:GetEffectName()
    return "particles/karna/karna_buff_burn.vpcf"
end
function modifier_ozy_boat_orbital_laser_stacks:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
function modifier_ozy_boat_orbital_laser_stacks:IsDebuff() return true end
function modifier_ozy_boat_orbital_laser_stacks:OnCreated(args)
end
function modifier_ozy_boat_orbital_laser_stacks:OnRefresh(args)

end
