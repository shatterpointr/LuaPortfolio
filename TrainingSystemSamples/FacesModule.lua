local FacesModule = {}
local Settings = require(game.ReplicatedStorage:WaitForChild("TrainingSystem"):WaitForChild("Settings"))
local TrainingModule = require(script.Parent.TrainingModule)
local Events = Settings.Events.Faces
local Values = Settings.Values
local PlayerCache = {}
local FaceSubmissionConnection, Host, ScoreSubmissionConnection
local Active = false

local function BroadcastFace(face, difficulty)
	for Player, Score in PlayerCache do
		local PlayerObj = game.Players:FindFirstChild(Player)
		if not PlayerObj then continue end
		Events.SubmitFace:FireClient(PlayerObj, face, difficulty)
	end
end

FacesModule.EndFaces = function()
	for Player, Score in pairs(PlayerCache) do
		local PlayerObj = game.Players:FindFirstChild(Player)
		if not PlayerObj then continue end
		TrainingModule.AddPoints(PlayerObj, Score)
	end
	FaceSubmissionConnection:Disconnect()
	ScoreSubmissionConnection:Disconnect()
	PlayerCache = {}
	Active = false
	Host = nil
	Events.TeardownFaces:Fire()
	Events.Parent.General.UpdateBoards:Fire()
end

FacesModule.BeginFaces = function(Players, HostPlayer)
	local TrainingFolder = Values:FindFirstChildOfClass("Folder")
	Host = HostPlayer
	if not TrainingFolder or not Host then
		warn("No trainingfolder or host found")
		return
	end
	for i, Player in pairs(Players) do
		PlayerCache[Player.Name] = 0
		Events.StartFaces:FireClient(Player)
		local Character = Player.Character
		local RootPart = Character.HumanoidRootPart
		RootPart.CFrame = CFrame.new(RootPart.Position) * workspace.TrainingAssets.OrientationBar.CFrame.Rotation -- align players with sts lines
	end
	FaceSubmissionConnection = Events.SubmitFace.OnServerEvent:Connect(function(source, face, difficulty)
		if source ~= Host then
			warn("source of faces input not the host")
			return 
		end
		BroadcastFace(face, difficulty)
		local OrientationReference = workspace.TrainingAssets.OrientationReference
		OrientationReference.Orientation += Vector3.new(0, face, 0)
	end)
	ScoreSubmissionConnection = Events.SubmitScore.OnServerEvent:Connect(function(source, score)
		PlayerCache[source.Name] = score
	end)
	Events.EndFaces.OnServerEvent:Once(function(source)
		for Player, Score in pairs(PlayerCache) do
			local PlayerObject = game.Players:FindFirstChild(Player)
			if PlayerObject then
				Events.EndFaces:FireClient(PlayerObject)
			end
		end
		task.wait(2)
		FacesModule.EndFaces()
	end)
end

return FacesModule
