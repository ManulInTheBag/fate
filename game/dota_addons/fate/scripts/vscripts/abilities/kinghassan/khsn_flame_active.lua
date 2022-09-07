LinkLuaModifier("modifier_khsn_eternal_frame", "abilities/kinghassan/khsn_flame_active", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_flame1", "abilities/kinghassan/khsn_stab", LUA_MODIFIER_MOTION_NONE)

khsn_flame_active = class({})

 
function khsn_flame_active:OnSpellStart()
    local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_khsn_eternal_frame", {Duration = self:GetSpecialValueFor("duration") })
end

modifier_khsn_eternal_frame = class({})

function modifier_khsn_eternal_frame:IsHidden() return false end
function modifier_khsn_eternal_frame:IsDebuff() return false end
function modifier_khsn_eternal_frame:RemoveOnDeath() return true end
function modifier_khsn_eternal_frame:OnCreated()
	self.duration_pepeg = 0.1
	self.parent = self:GetParent()
	if IsServer() then
		self:StartIntervalThink(0.1)
	end
end
function modifier_khsn_eternal_frame:OnIntervalThink()
	if IsServer() then
		self.duration_pepeg = self.duration_pepeg + 0.1
		if self.duration_pepeg >= 8 then
			self.parent:RemoveModifierByName("modifier_khsn_toggle_mana")
		end
		local enemies = FindUnitsInRadius(  self.parent:GetTeamNumber(),
	                                        self.parent:GetAbsOrigin(),
	                                        nil,
	                                        99999,
	                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
	                                        DOTA_UNIT_TARGET_ALL,
	                                        DOTA_UNIT_TARGET_FLAG_NONE,
	                                        FIND_ANY_ORDER,
	                                        false)

		for _, enemy in pairs(enemies) do
		    if enemy and not enemy:IsNull() and IsValidEntity(enemy) and not enemy:IsMagicImmune() and enemy:HasModifier("modifier_death_door") then
		        local ability = self.parent:FindAbilityByName("khsn_azrael")
		        local new_modifier = enemy:AddNewModifier(self.parent, ability, "modifier_khsn_flame1", {duration = 0.2})
		    end
		end
	end
end
