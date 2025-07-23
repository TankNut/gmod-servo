AddCSLuaFile()
DEFINE_BASECLASS("base_gmodentity")

ENT.PrintName 	= "Servo"
ENT.Author 		= "TankNut"

if SERVER then
	function ENT:Initialize()
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)

		self.NumpadCache = {}
		self.Directions = Vector()
	end

	function ENT:OnRemove()
		for _, v in pairs(self.NumpadCache) do
			numpad.Remove(v)
		end
	end

	function ENT:Update(ply)
		for _, v in pairs(self.NumpadCache) do
			numpad.Remove(v)
		end

		table.Empty(self.NumpadCache)

		-- insert numpad actions for each axis and its two directions
		for axis, axisTable in pairs( { x = self.Roll, y = self.Pitch, z = self.Yaw } ) do
			for direction, key in pairs( { [ -1 ] = axisTable.Forward, [ 1 ] = axisTable.Back } ) do
				local tog = axisTable.Toggle
				table.insert( self.NumpadCache, numpad.OnDown(ply, key, "Servo_On", self, axis, direction, tog) or nil )
				table.insert(self.NumpadCache, not tog and numpad.OnUp(ply, key, "Servo_Off", self, axis, direction) or nil )
			end
		end

		self.Directions = Vector(self.Roll.Start and 1 or 0, self.Pitch.Start and 1 or 0, self.Yaw.Start and 1 or 0)

		self:GetPhysicsObject():SetMass(self.Mass)
	end

	function ENT:UpdatePhys(phys)
		local brake = Vector(self.Roll.Brake and 0 or 1, self.Pitch.Brake and 0 or 1, self.Yaw.Brake and 0 or 1)
		local vel = phys:GetAngleVelocity() * brake
		local dir = Vector(self.Roll.Value * self.Directions.x, self.Pitch.Value * self.Directions.y, self.Yaw.Value * self.Directions.z)

		for _, v in pairs({"x", "y", "z"}) do
			if dir[v] ~= 0 then
				vel[v] = dir[v]
			end
		end

		phys:AddAngleVelocity(vel - phys:GetAngleVelocity())
		phys:Wake()
	end

	function ENT:Think()
		BaseClass.Think(self)

		local phys = self:GetPhysicsObject()

		if IsValid(phys) and not self:IsPlayerHolding() then
			self:UpdatePhys(phys)
		end

		self:NextThink(CurTime() + 0.01)

		return true
	end

	numpad.Register("Servo_On", function(ply, ent, axis, dir, toggle)
		if not IsValid(ent) then return end

		ent.Directions[axis] = ( toggle and ent.Directions[axis] ~= 0 ) and 0 or dir
	end)

	numpad.Register("Servo_Off", function(ply, ent, axis, dir)
		if not IsValid(ent) then return end

		if ent.Directions[axis] == dir then
			ent.Directions[axis] = 0
		end
	end)
end