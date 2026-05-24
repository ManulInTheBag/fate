ozy_boat_orbital_laser = class({})
LinkLuaModifier("modifier_ozy_boat_orbital_laser_stacks", "abilities/ozy/ozy_boat_orbital_laser", LUA_MODIFIER_MOTION_NONE)
function ozy_boat_orbital_laser:CastFilterResultLocation(vLocation)
    local hCaster = self:GetCaster()

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if not ( IsServer() and not IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) ) then
            return UF_SUCCESS
        end
    end
    return UF_FAIL_CUSTOM
end

function ozy_boat_orbital_laser:GetCustomCastErrorLocation(vLocation)
	 return "#Wrong_Target_Location"
end
function ozy_boat_orbital_laser:OnChannelThink(fInterval)
    self.ChannelTime = self.ChannelTime + fInterval
    self:GetCaster():FaceTowards(self:GetCursorPosition())
	local manaSpendPerSec = self:GetSpecialValueFor("mana_drain_per_second") + (self:GetSpecialValueFor("mana_drain_increase_per_second")  * self.ChannelTime)
	if self:GetCaster():GetMana() < manaSpendPerSec * fInterval then
		self:GetCaster():Interrupt()
	end

	if (self.LaserTargetPoint - self.LaserPoint):Length2D() > 10 then
		self.LaserPoint = self.LaserPoint + (self.LaserTargetPoint - self.LaserPoint):Normalized() * self:GetSpecialValueFor("move_speed")*fInterval
		if IsNotNull(self.AuraDummy) then
			self.AuraDummy:SetAbsOrigin(self.LaserPoint)
		end
	end
	self.LaserPoint.z = 0
	ParticleManager:SetParticleControl(self.particle, 0, self.LaserPoint + Vector(0,0, 2500))
	ParticleManager:SetParticleControl(self.particle, 1, self.LaserPoint)
	self:GetCaster():SpendMana(manaSpendPerSec * fInterval)
	local tEnemies = FindUnitsInRadius(self:GetCaster():GetTeam(), self.LaserPoint , nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	local additiveStacks = (self:GetSpecialValueFor("damage_per_second_increase") +self:GetCaster().ozy:GetLevel() * self:GetSpecialValueFor("damage_per_second_increase_per_level"))* fInterval 
	for k, v in pairs(tEnemies) do
		self:ApplyLaserStacks(v, additiveStacks)
		DoDamage(self:GetCaster().ozy,v , fInterval* (self:GetCaster().ozy:GetLevel()* self:GetSpecialValueFor("damage_per_second_per_level") +self:GetSpecialValueFor("damage_per_second") + v:GetModifierStackCount("modifier_ozy_boat_orbital_laser_stacks", self:GetCaster().ozy)), self:GetAbilityDamageType(), 0, self, false)
	end
end

function ozy_boat_orbital_laser:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()
	ParticleManager:DestroyParticle(self.particle, true)
	ParticleManager:ReleaseParticleIndex(self.particle)
	caster:SwapAbilities("ozy_boat_orbital_laser", "ozy_boat_orbital_laser_move", true, false)
	self.AuraDummy:StopSound("ozy_orbital_laser")
	self.AuraDummy:RemoveSelf()

	EmitSoundOnLocationWithCaster(self.LaserPoint, "ozy_orbital_laser_end", self:GetCaster())
end

function ozy_boat_orbital_laser:OnSpellStart()
	self.ChannelTime = 0
	self.particle = ParticleManager:CreateParticle("particles/ozy/boat/boat_orbital_laser.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleShouldCheckFoW(self.particle, false)
	local hCaster = self:GetCaster()
	local vTargetPoint = self:GetCursorPosition()
	hCaster:SwapAbilities("ozy_boat_orbital_laser", "ozy_boat_orbital_laser_move", false, true)
	self.LaserPoint = vTargetPoint
	self.LaserTargetPoint = vTargetPoint
	self.AuraDummy = CreateUnitByName("sight_dummy_unit", self.LaserPoint, false, nil, nil, hCaster:GetTeamNumber())
 	self.AuraDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	self.AuraDummy:SetDayTimeVisionRange(0)
	self.AuraDummy:SetNightTimeVisionRange(0)
	EmitSoundOn("ozy_orbital_laser", self.AuraDummy)
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
