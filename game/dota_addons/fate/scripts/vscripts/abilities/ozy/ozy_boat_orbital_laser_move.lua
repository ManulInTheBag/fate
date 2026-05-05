ozy_boat_orbital_laser_move = class({})


function ozy_boat_orbital_laser_move:OnSpellStart()
	local caster = self:GetCaster()
	caster:FindAbilityByName("ozy_boat_orbital_laser").LaserTargetPoint = self:GetCursorPosition()



end

