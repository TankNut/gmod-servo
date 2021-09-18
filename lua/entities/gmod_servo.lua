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

		table.insert(self.NumpadCache, numpad.OnDown(ply, self.Pitch.Forward, "Servo_On", self, "y", 1, self.Pitch.Toggle))
		table.insert(self.NumpadCache, numpad.OnDown(ply, self.Pitch.Back, "Servo_On", self, "y", -1, self.Pitch.Toggle))

		if not self.Pitch.Toggle then
			table.insert(self.NumpadCache, numpad.OnUp(ply, self.Pitch.Forward, "Servo_Off", self, "y", 1))
			table.insert(self.NumpadCache, numpad.OnUp(ply, self.Pitch.Back, "Servo_Off", self, "y", -1))
		end

		table.insert(self.NumpadCache, numpad.OnDown(ply, self.Yaw.Forward, "Servo_On", self, "z", 1, self.Yaw.Toggle))
		table.insert(self.NumpadCache, numpad.OnDown(ply, self.Yaw.Back, "Servo_On", self, "z", -1, self.Yaw.Toggle))

		if not self.Yaw.Toggle then
			table.insert(self.NumpadCache, numpad.OnUp(ply, self.Yaw.Forward, "Servo_Off", self, "z", 1))
			table.insert(self.NumpadCache, numpad.OnUp(ply, self.Yaw.Back, "Servo_Off", self, "z", -1))
		end

		table.insert(self.NumpadCache, numpad.OnDown(ply, self.Roll.Forward, "Servo_On", self, "x", 1, self.Roll.Toggle))
		table.insert(self.NumpadCache, numpad.OnDown(ply, self.Roll.Back, "Servo_On", self, "x", -1, self.Roll.Toggle))

		if not self.Roll.Toggle then
			table.insert(self.NumpadCache, numpad.OnUp(ply, self.Roll.Forward, "Servo_Off", self, "x", 1))
			table.insert(self.NumpadCache, numpad.OnUp(ply, self.Roll.Back, "Servo_Off", self, "x", -1))
		end

		self.Directions = Vector(self.Roll.Start and 1 or 0, self.Pitch.Start and 1 or 0, self.Yaw.Start and 1 or 0)

		local phys = self:GetPhysicsObject()

		phys:SetMass(self.Mass)
	end

	function ENT:UpdatePhys(phys)
		local brake = Vector(self.Roll.Brake and 0 or 1, self.Pitch.Brake and 0 or 1, self.Yaw.Brake and 0 or 1)
		local vel = phys:GetAngleVelocity() * brake
		local dir = Vector(self.Roll.Value * self.Directions.x, self.Pitch.Value * self.Directions.y, self.Yaw.Value * self.Directions.z)

		for _, v in pairs({"x", "y", "z"}) do
			if dir[v] != 0 then
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

		if toggle then
			ent.Directions[axis] = ent.Directions[axis] != 0 and 0 or dir
		else
			ent.Directions[axis] = dir
		end
	end)

	numpad.Register("Servo_Off", function(ply, ent, axis, dir)
		if not IsValid(ent) then return end

		if ent.Directions[axis] == dir then
			ent.Directions[axis] = 0
		end
	end)
end
