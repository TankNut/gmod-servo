TOOL.Category = "Construction"
TOOL.Name = "#tool.servo.name"

TOOL.Information = {
	{name = "left"},
	{name = "right"},
	{name = "reload"}
}

TOOL.ClientConVar["model"] = "models/hunter/blocks/cube025x025x025.mdl"

TOOL.ClientConVar["pitch"] = 10
TOOL.ClientConVar["pitch_forward"] = 45
TOOL.ClientConVar["pitch_back"] = 42
TOOL.ClientConVar["pitch_brake"] = 0
TOOL.ClientConVar["pitch_start"] = 0
TOOL.ClientConVar["pitch_toggle"] = 0

TOOL.ClientConVar["yaw"] = 0
TOOL.ClientConVar["yaw_forward"] = 0
TOOL.ClientConVar["yaw_back"] = 0
TOOL.ClientConVar["yaw_brake"] = 0
TOOL.ClientConVar["yaw_start"] = 0
TOOL.ClientConVar["yaw_toggle"] = 0

TOOL.ClientConVar["roll"] = 0
TOOL.ClientConVar["roll_forward"] = 0
TOOL.ClientConVar["roll_back"] = 0
TOOL.ClientConVar["roll_brake"] = 0
TOOL.ClientConVar["roll_start"] = 0
TOOL.ClientConVar["roll_toggle"] = 0

TOOL.ClientConVar["mass"] = 100

cleanup.Register("servos")

function TOOL:LeftClick(trace)
	local ent = trace.Entity
	if IsValid(ent) and ent:IsPlayer() then
		return false
	end

	if CLIENT then
		return true
	end

	local ply = self:GetOwner()

	local mdl = self:GetClientInfo("model")

	local pitch = {
		Value = self:GetClientNumber("pitch"),
		Forward = self:GetClientNumber("pitch_forward"),
		Back = self:GetClientNumber("pitch_back"),
		Brake = tobool(self:GetClientNumber("pitch_brake")),
		Start = tobool(self:GetClientNumber("pitch_start")),
		Toggle = tobool(self:GetClientNumber("pitch_toggle"))
	}

	local yaw = {
		Value = self:GetClientNumber("yaw"),
		Forward = self:GetClientNumber("yaw_forward"),
		Back = self:GetClientNumber("yaw_back"),
		Brake = tobool(self:GetClientNumber("yaw_brake")),
		Start = tobool(self:GetClientNumber("yaw_start")),
		Toggle = tobool(self:GetClientNumber("yaw_toggle"))
	}

	local roll = {
		Value = self:GetClientNumber("roll"),
		Forward = self:GetClientNumber("roll_forward"),
		Back = self:GetClientNumber("roll_back"),
		Brake = tobool(self:GetClientNumber("roll_brake")),
		Start = tobool(self:GetClientNumber("roll_start")),
		Toggle = tobool(self:GetClientNumber("roll_toggle"))
	}

	local mass = self:GetClientNumber("mass")

	if IsValid(ent) and ent:GetClass() == "gmod_servo" then
		ent.Pitch = pitch
		ent.Yaw = yaw
		ent.Roll = roll

		ent.Mass = mass

		ent:Update(ply)

		return true
	end

	if not self:GetSWEP():CheckLimit("wheels") then return false end

	if not util.IsValidModel(mdl) then return false end
	if not util.IsValidProp(mdl) then return false end

	local ang = trace.HitNormal:Angle()

	ang.pitch = ang.pitch + 90

	local servo = MakeServo(ply, mdl, ang, trace.HitPos, pitch, yaw, roll, mass)

	servo:SetPos(trace.HitPos - trace.HitNormal * servo:OBBMins())

	undo.Create("Servo")
		undo.AddEntity(servo)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup("servos", servo)

	return true
end

function TOOL:RightClick(trace)
	local ent = trace.Entity

	if IsValid(ent) and not ent:IsWorld() then
		local ply = self:GetOwner()

		ply:ConCommand("servo_model " .. ent:GetModel())

		ply:SendLua("notification.AddLegacy(language.GetPhrase('tool.servo.copymodel') .. '" .. ent:GetModel() .. "', NOTIFY_GENERIC, 2)")
		ply:SendLua("surface.PlaySound('ambient/water/drip" .. math.random(1, 4) .. ".wav')")
	end

	return true
end

function TOOL:Reload(trace)
	local ent = trace.Entity

	if not IsValid(ent) or ent:GetClass() != "gmod_servo" then
		return false
	end

	local ply = self:GetOwner()

	ply:ConCommand("servo_pitch " .. ent.Pitch.Value)
	ply:ConCommand("servo_pitch_forward " .. ent.Pitch.Forward)
	ply:ConCommand("servo_pitch_back " .. ent.Pitch.Back)
	ply:ConCommand("servo_pitch_brake " .. (ent.Pitch.Brake and 1 or 0))
	ply:ConCommand("servo_pitch_start " .. (ent.Pitch.Start and 1 or 0))
	ply:ConCommand("servo_pitch_toggle " .. (ent.Pitch.Toggle and 1 or 0))

	ply:ConCommand("servo_yaw " .. ent.Yaw.Value)
	ply:ConCommand("servo_yaw_forward " .. ent.Yaw.Forward)
	ply:ConCommand("servo_yaw_back " .. ent.Yaw.Back)
	ply:ConCommand("servo_yaw_brake " .. (ent.Yaw.Brake and 1 or 0))
	ply:ConCommand("servo_yaw_start " .. (ent.Yaw.Start and 1 or 0))
	ply:ConCommand("servo_yaw_toggle " .. (ent.Yaw.Toggle and 1 or 0))

	ply:ConCommand("servo_roll " .. ent.Roll.Value)
	ply:ConCommand("servo_roll_forward " .. ent.Roll.Forward)
	ply:ConCommand("servo_roll_back " .. ent.Roll.Back)
	ply:ConCommand("servo_roll_brake " .. (ent.Roll.Brake and 1 or 0))
	ply:ConCommand("servo_roll_start " .. (ent.Roll.Start and 1 or 0))
	ply:ConCommand("servo_roll_toggle " .. (ent.Roll.Toggle and 1 or 0))

	ply:ConCommand("servo_mass " .. ent.Mass)

	ply:SendLua("notification.AddLegacy(language.GetPhrase('tool.servo.copysettings'), NOTIFY_GENERIC, 2)")
	ply:SendLua("surface.PlaySound('ambient/water/drip" .. math.random(1, 4) .. ".wav')")

	return true
end

if SERVER then
	function MakeServo(ply, mdl, ang, pos, pitch, yaw, roll, mass)
		if IsValid(ply) and not ply:CheckLimit("wheels") then
			return false
		end

		local servo = ents.Create("gmod_servo")

		if not IsValid(servo) then
			return false
		end

		servo:SetModel(mdl)
		servo:SetAngles(ang)
		servo:SetPos(pos)

		servo:Spawn()

		servo.Pitch = pitch
		servo.Yaw = yaw
		servo.Roll = roll

		servo.Mass = mass

		servo:Update(ply)

		DoPropSpawnedEffect(servo)

		return servo
	end

	duplicator.RegisterEntityClass("gmod_servo", MakeServo, "Model", "Ang", "Pos", "Pitch", "Yaw", "Roll", "Mass")
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("header", {Description = "#tool.servo.desc"})
	CPanel:AddControl("combobox", {MenuButton = 1, Folder = "servo", Options = {["#preset.default"] = ConVarsDefault}, CVars = table.GetKeys(ConVarsDefault)})

	CPanel:AddControl("textbox", {Label = "#tool.servo.model", Command = "servo_model"})

	CPanel:AddControl("header", {Description = "#tool.servo.desc1"})

	CPanel:AddControl("numpad", {Label = "#tool.servo.forward", Command = "servo_pitch_forward", Label2 = "#tool.servo.back", Command2 = "servo_pitch_back"})
	CPanel:AddControl("slider", {Label = "#tool.servo.rotation", Command = "servo_pitch", Type = "Float", Min = -360, Max = 360})
	CPanel:AddControl("checkBox", {Label = "#tool.servo.brake", Command = "servo_pitch_brake"})
	CPanel:AddControl("checkBox", {Label = "#tool.servo.starton", Command = "servo_pitch_start"})
	CPanel:AddControl("checkBox", {Label = "#tool.servo.toggle", Command = "servo_pitch_toggle"})

	CPanel:AddControl("header", {Description = "#tool.servo.desc2"})

	CPanel:AddControl("numpad", {Label = "#tool.servo.forward", Command = "servo_yaw_forward", Label2 = "#tool.servo.back", Command2 = "servo_yaw_back"})
	CPanel:AddControl("slider", {Label = "#tool.servo.rotation", Command = "servo_yaw", Type = "Float", Min = -360, Max = 360})
	CPanel:AddControl("checkBox", {Label = "#tool.servo.brake", Command = "servo_yaw_brake"})
	CPanel:AddControl("checkBox", {Label = "#tool.servo.starton", Command = "servo_yaw_start"})
	CPanel:AddControl("checkBox", {Label = "#tool.servo.toggle", Command = "servo_yaw_toggle"})

	CPanel:AddControl("header", {Description = "#tool.servo.desc3"})

	CPanel:AddControl("numpad", {Label = "#tool.servo.forward", Command = "servo_roll_forward", Label2 = "#tool.servo.back", Command2 = "servo_roll_back"})
	CPanel:AddControl("slider", {Label = "#tool.servo.rotation", Command = "servo_roll", Type = "Float", Min = -360, Max = 360})
	CPanel:AddControl("checkBox", {Label = "#tool.servo.brake", Command = "servo_roll_brake"})
	CPanel:AddControl("checkBox", {Label = "#tool.servo.starton", Command = "servo_roll_start"})
	CPanel:AddControl("checkBox", {Label = "#tool.servo.toggle", Command = "servo_roll_toggle"})

	CPanel:AddControl("header", {Description = "#tool.servo.desc4"})

	CPanel:AddControl("slider", {Label = "#tool.servo.mass", Command = "servo_mass", Type = "Int", Min = 1, Max = 10000})
end
