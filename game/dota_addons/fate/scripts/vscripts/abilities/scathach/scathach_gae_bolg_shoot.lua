scathach_gae_bolg_shoot = class({})


function scathach_gae_bolg_shoot:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("scathach_gae_bolg_spawn"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("scathach_gae_bolg_spawn"):SetLevel(self:GetLevel())
    end
end

function scathach_gae_bolg_shoot:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	local modifier = caster:FindModifierByName("modifier_scat_gae_bolg_replicas")
	if IsServer() then
		if not IsNotNull(modifier) then
			print("something went wrong")
			self:RestoreAbilityLayout()
			return
		end
	end
	modifier:ShootGaeBolg(target)
end

function scathach_gae_bolg_shoot:RestoreAbilityLayout()
	if IsServer() then 
		local caster = self:GetCaster()
		if caster:GetAbilityByIndex(5):GetName() == "scathach_gae_bolg_shoot"  then
			caster:SwapAbilities("scathach_gae_bolg_spawn", "scathach_gae_bolg_shoot", true, false)
		end
	end
end
