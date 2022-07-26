hanging_gardens_summon_skeletons = class({})

function hanging_gardens_summon_skeletons:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function hanging_gardens_summon_skeletons:OnSpellStart()
	local caster = self:GetCaster()
	local location = self:GetCursorPosition()
	local max_skeletons = self:GetSpecialValueFor("skeleton_num")
	local cur_skeleton = 1

	local skellyName = "semiramis_skeleton_warrior"

	if self:GetLevel() == 2 then
		skellyName = "semiramis_skeleton_warrior_upg"
	end

	Timers:CreateTimer(function()
		if cur_skeleton <= max_skeletons then
			cur_skeleton = cur_skeleton + 1

			local skeleton_loc = RandomPointInCircle(targetPoint, self:GetAOERadius)
			local skelly =  CreateUnitByName(skellyName, skeleton_loc, true, nil, nil, caster:GetTeamNumber())	
			skelly:EmitSound("spawn_skeleton")

			return 0.2
		else
			return
		end			
	end)
end