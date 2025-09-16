local UI = script.Parent
local TrainerDisplay = UI.TrainerDisplay
local UIS = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local tweenService = game:GetService("TweenService")
local Settings = require(game.ReplicatedStorage:WaitForChild("TrainingSystem"):WaitForChild("Settings"))
local Values = Settings.Values
local Events = Settings.Events.Faces
local Config = UI.Config
local Sounds = UI.TrainingSounds
local LocalPlayer = game.Players.LocalPlayer
local FaceTable = {
	["Right face!"] = -90,
	["Left face!"] = 90,
	["About face!"] = 180,
	["Right incline!"] = -45,
	["Left incline!"] = 45
}
local ChatConnection, Button1Connection, Button2Connection, Button3Connection, FaceReception
local Submitted = false
local Difficulty -- int corresponding to the time the trainee has to complete the face
local Score = 0
local Count = 0
local CurrentOrientation = workspace.TrainingAssets.OrientationBar.Orientation.Y

local function endSection()
	Events.EndFaces:FireServer()
	TrainerDisplay.Faces.Visible = false
	Button1Connection:Disconnect()
	Button2Connection:Disconnect()
	Button3Connection:Disconnect()
	ChatConnection:Disconnect()
	Count = 0
end

local function isOrientationValid() -- Written by Claude AI my goat.
	-- Use the specified variables directly
	local Root = LocalPlayer.Character.HumanoidRootPart
	local Reference = workspace.TrainingAssets.OrientationReference
	local Tolerance = Settings.Faces_Orientation_Tolerance 

	-- Extract only the Y rotation from both parts - more efficient than full CFrame operations
	local _, rootY, _ = Root.CFrame:ToEulerAnglesYXZ()
	local _, referenceY, _ = Reference.CFrame:ToEulerAnglesYXZ()

	-- Convert to degrees
	rootY = math.deg(rootY)
	referenceY = math.deg(referenceY)

	-- Calculate the smallest angle difference, handling the wraparound at ±180
	-- This formula efficiently finds the shortest angle between two orientations
	local diff = math.abs((((rootY - referenceY) % 360) + 180) % 360 - 180)

	-- Return both the validation result and the angle difference
	return diff <= Tolerance
end

local function SetTraineeTimer(Time) -- set the ui timer bar for trainees
	print(Time)
	local ProgressBar = UI.TraineeDisplay.TimerBar.ProgressBar
	ProgressBar.Size = UDim2.new(1, -5, 1, -10)
	local x = TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)
	local t = tweenService:Create(ProgressBar, x, {Size = UDim2.new(0, -5, 1, -10)})
	t:Play()
end

local function DisplayTrainerUI() -- displays the trainer UI, connects difficulty and end buttons
	local Frame = TrainerDisplay.Faces
	local Arrow = TrainerDisplay.Faces.Arrow
	Frame.Visible = true
	Button1Connection = Frame.Easy.MouseButton1Click:Connect(function()
		Sounds.ClickSound:Play()
		Difficulty = Settings.Faces_Easy_Time
		Arrow.Position = UDim2.new(0.545, 0, 0.301, 0)
	end)
	Button2Connection = Frame.Medium.MouseButton1Click:Connect(function()
		Sounds.ClickSound:Play()
		Difficulty = Settings.Faces_Medium_Time
		Arrow.Position = UDim2.new(0.545, 0, 0.484, 0)
	end)
	Button3Connection = Frame.Hard.MouseButton1Click:Connect(function()
		Sounds.ClickSound:Play()
		Difficulty = Settings.Faces_Hard_Time
		Arrow.Position = UDim2.new(0.545, 0, 0.632, 0)
	end)
	Frame.End.MouseButton1Click:Once(function()
		Sounds.ClickSound:Play()
		endSection()
	end)
end

local function ValidateCommand(Message: TextChatMessage) -- checks if trainer chat is actually a face command
	local i = FaceTable[Message.Text]
	if i then
		if Count < Settings.Faces_Maximum then
			print('message sent to server')
			Events.SubmitFace:FireServer(i, Difficulty)
			Count += 1
		else
			endSection()
		end
	end
end

local function TraineeDisplay(Title, Contents) -- function for handling trainee display
	local Display = UI.TraineeDisplay
	Display.Visible = true
	Display.Title.Text = Title
	Display.Contents.Text = Contents
end

local function DisplayConfig() -- display and connect the faces start UI
	TrainerDisplay.FacesConfig.Visible = true
	TrainerDisplay.FacesConfig.Start.MouseButton1Click:Once(function()
		Sounds.ClickSound:Play()
		Events.StartFaces:FireServer()
		ChatConnection = TextChatService.SendingMessage:Connect(function(textChatMessage: TextChatMessage)
			if not Submitted then
				Submitted = true
				print('message received')
				ValidateCommand(textChatMessage)
				task.wait(Difficulty + 0.25) -- extra wait time is to make sure the commands aren't being fired too quickly and faces can be properly validated
				Submitted = false
			end
		end)
		TrainerDisplay.FacesConfig.Visible = false
		DisplayTrainerUI()
		Difficulty = Settings.Faces_Easy_Time
	end)
end

local function DisplayTraineeFace(Face, Time)
	TraineeDisplay("CURRENT COMMAND:", Face)
	SetTraineeTimer(Time)
end

Events.StartFaces.OnClientEvent:Connect(function()
	TraineeDisplay("FACES", "Awaiting Command")
	FaceReception = Events.SubmitFace.OnClientEvent:Connect(function(face: int, T) -- face is the orientation in facetable, T is time to complete
		print('face reception on client')
		CurrentOrientation += face
		print('CurrentOrientation:', CurrentOrientation, "Face:", face)
		local Command
		for Index, Rotation in pairs(FaceTable) do -- find appropriate command for the given orientation
			if Rotation == face then
				Command = Index
			end
		end
		UI.TraineeDisplay.Contents.TextColor3 = Color3.new(1, 1, 1)
		TraineeDisplay("FACES", Command)
		print('given T:', T)
		SetTraineeTimer(T)
		coroutine.resume(coroutine.create(function()
			task.wait(T)
			print('checking orientation')
			if isOrientationValid() then
				Score += Settings.Faces_Points
				print('orientation correct!')
				Sounds.CorrectChime:Play()
				UI.TraineeDisplay.Contents.TextColor3 = Color3.new(0.333333, 0.666667, 0)
			end
		end))
	end)
end)

Events.InitFaces.OnClientEvent:Connect(function()
	DisplayConfig()
end)

Events.EndFaces.OnClientEvent:Connect(function() -- teardown the faces section on the client
	print('ending faces on client.', Score)
	Events.SubmitScore:FireServer(Score)
	FaceReception:Disconnect()
	TraineeDisplay("SECTION ENDED", "+"..tostring(Score).." Points!")
	task.wait(1)
	TraineeDisplay(" ", " ")
	UI.TraineeDisplay.Visible = false
	Score = 0
end)