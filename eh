local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui


local gameIdsToWaitFor = {15186202290, 9825515356}  
local currentGameId = game.PlaceId  


local scriptExecuted = false

local function findSettingsFrame(gui)
    for _, child in ipairs(gui:GetChildren()) do
        if child.Name == "Settings" then
            return child
        end
        local result = findSettingsFrame(child)
        if result then
            return result
        end
    end
    return nil
end


local function handleSettingsOpened()
    


    if shared.Global.Memory.Settings.IsPrecisionActive == true then
        local Memory = tostring(math.random(shared.Global.Memory.Configuration.Start, shared.Global.Memory.Configuration.End)) .. "." .. tostring(math.random(10, 99)) -- Initialize with a valid memory value
    
       
        game:GetService("RunService").RenderStepped:Connect(function()
            pcall(function()
                for i, v in pairs(game:GetService("CoreGui").RobloxGui.PerformanceStats:GetChildren()) do
                    if v.Name == "PS_Button" then
                        if v.StatsMiniTextPanelClass.TitleLabel.Text == "Mem" then
                            v.StatsMiniTextPanelClass.ValueLabel.Text = tostring(Memory) .. " MB"
                        end
                    end
                end
            end)
    
            pcall(function()
                if game:GetService("CoreGui").RobloxGui.PerformanceStats["PS_Viewer"].Frame.TextLabel.Text == "Memory" then
                    for i, v in pairs(game:GetService("CoreGui").RobloxGui.PerformanceStats["PS_Viewer"].Frame:GetChildren()) do
                        if v.Name == "PS_DecoratedValueLabel" and string.find(v.Label.Text, 'Current') then
                            v.Label.Text = "Current: " .. Memory .. " MB"
                        end
                        if v.Name == "PS_DecoratedValueLabel" and string.find(v.Label.Text, 'Average') then
                            v.Label.Text = "Average: " .. Memory .. " MB"
                        end
                    end
                end
            end)
    
            pcall(function()
                game:GetService("CoreGui").DevConsoleMaster.DevConsoleWindow.DevConsoleUI.TopBar.LiveStatsModule["MemoryUsage_MB"].Text = math.round(tonumber(Memory)) .. " MB"
            end)
        end)
    
        
        task.spawn(function()
            while task.wait(1) do
                local minMemory = shared.Global.Memory.Configuration.Start
                local maxMemory = shared.Global.Memory.Configuration.End
                Memory = tostring(math.random(minMemory, maxMemory)) .. "." .. tostring(math.random(10, 99))
            end
        end)
    end
    
        
        
        
        
        
        
        
        
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Camera = game:GetService("Workspace").CurrentCamera
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local lastClickTime = 0
    local isToggled = false
    local TargetPlayer = nil
    local lastPositions = {}
    local predictionFactor = 0.2  
    
    local config = shared.Global.TriggerBot
    local CooldownTime = config.CooldownTime
    local TriggerKey = config.TriggerKey
    local enableLegitMode = config.ShotControl.EnableLegitMode
    local ignoreKnife = config.ShotControl.Protection.IgnoreKnife
    
    local detectionZone = config.DetectionZone
    
    
    local function mouse1click(x, y)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, false)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, false)
    end
    
    local function getMousePosition()
        local mouse = UserInputService:GetMouseLocation()
        return mouse.X, mouse.Y
    end
    
    local function isWithinViewEra(position)
        local screenPos = Camera:WorldToViewportPoint(position)
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local fovHeight = shared.Global.ViewEra.Vertical * 100
        local fovWidth = shared.Global.ViewEra.Horizontal * 100
        return (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude <= math.sqrt((fovHeight / 2)^2 + (fovWidth / 2)^2)
    end
    
    local function getBodyPartsPosition(character)
        local bodyParts = {}
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("MeshPart") or part:IsA("Part") then
                table.insert(bodyParts, part)
            end
        end
        return bodyParts
    end
    
    local function syncBoxWithTarget(screenPos)
        VirtualInputManager:SendMouseMoveEvent(screenPos.X, screenPos.Y, game)
    end
    
    local function isPlayerKnocked(player)
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if humanoid then
            return humanoid.Health > 0 and humanoid.Health <= 1
        end
        return false
    end
    
    local function isIgnoringKnife()
        local currentTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if currentTool then
            local toolName = currentTool.Name:lower()
            return toolName == "knife" or toolName == "katana" or toolName == "[knife]" or toolName == "[katana]"
        end
        return false
    end
    
    local function isMouseOnTarget(targetPlayer)
        local mouse = LocalPlayer:GetMouse()
        return mouse.Target and mouse.Target:IsDescendantOf(targetPlayer.Character)
    end
    
    local function getRandomPointInCharacter(character)
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            local characterSize = humanoidRootPart.Size
            local characterPos = humanoidRootPart.Position
            
            local randomX = math.random() * characterSize.X - characterSize.X / 2
            local randomY = math.random() * characterSize.Y - characterSize.Y / 2
            local randomZ = math.random() * characterSize.Z - characterSize.Z / 2
            
            return characterPos + Vector3.new(randomX, randomY, randomZ)
        end
        return nil
    end
    
    local function predictTargetPosition(targetPlayer, deltaTime)
        local humanoidRootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            local velocity = humanoidRootPart.AssemblyLinearVelocity
            local distance = (humanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    
            if distance <= 5 then
                predictionFactor = 0.06
            elseif distance <= 25 then
                predictionFactor = 0.2
            elseif distance <= 41 then
                predictionFactor = 0.3
            else
                predictionFactor = 0.2
            end
    
            local prediction = humanoidRootPart.Position + velocity * deltaTime * predictionFactor
    
            local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                local state = humanoid:GetState()
                if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
                    prediction = Vector3.new(prediction.X, prediction.Y + velocity.Y * 0.1, prediction.Z)
                end
            end
    
            table.insert(lastPositions, 1, prediction)
            if #lastPositions > 5 then
                table.remove(lastPositions)
            end
    
            local avgPrediction = Vector3.new(0, 0, 0)
            for _, pos in ipairs(lastPositions) do
                avgPrediction = avgPrediction + pos
            end
    
            return avgPrediction / #lastPositions
        end
        return targetPlayer.Character.HumanoidRootPart.Position
    end
    
    local function airSmoothing(predictedPos, targetPlayer)
        local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            if humanoid:GetState() == Enum.HumanoidStateType.Jumping or humanoid:GetState() == Enum.HumanoidStateType.Physics then
                local velocity = humanoid.RootPart.AssemblyLinearVelocity
                predictedPos = Vector3.new(predictedPos.X, predictedPos.Y + velocity.Y * 0.2, predictedPos.Z)
            end
        end
        return predictedPos
    end
    
    local function aimAtTargetBody(targetPlayer)
        local randomPoint = getRandomPointInCharacter(targetPlayer.Character)
        if randomPoint then
            local predictedPos = predictTargetPosition(targetPlayer, 0.1)
    
            local screenPos, onScreen = Camera:WorldToViewportPoint(randomPoint)
    
            if onScreen and isWithinViewEra(randomPoint) then
                syncBoxWithTarget(screenPos)
    
                if os.clock() - lastClickTime >= CooldownTime then
                    lastClickTime = os.clock()
    
                    if enableLegitMode then
                        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                        if tool and tool:IsA("Tool") and not isIgnoringKnife() then
                            local shootFunction = tool:FindFirstChild("Fire")
                            if shootFunction and shootFunction:IsA("RemoteEvent") then
                                shootFunction:FireServer(TargetPlayer.Character)
                            else
                                local mouseX, mouseY = getMousePosition()
                                mouse1click(mouseX, mouseY)
                            end
                        end
                    else
                        local mouseX, mouseY = getMousePosition()
                        mouse1click(mouseX, mouseY)
                    end
                end
            end
        end
    end
    
    local function TriggerBotAction()
        if TargetPlayer and TargetPlayer.Character then
            local humanoid = TargetPlayer.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 and not isPlayerKnocked(TargetPlayer) then
                if isMouseOnTarget(TargetPlayer) then
                    aimAtTargetBody(TargetPlayer)  
                end
            end
        end
    end
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == TriggerKey then
            isToggled = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == TriggerKey then
            isToggled = false
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if isToggled then
            TriggerBotAction()
        end
    end)

    
        

        
        
        
        
        
        
        
        
        
        
        
        
        
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Mouse = LocalPlayer:GetMouse()
    local RunService = game:GetService("RunService")
    local Camera = game.Workspace.CurrentCamera
    
    local AssistReach = shared.Global.PointAssist.AssistReach
    local TargetPlayer = nil
    local IsTargeting = false
    
    -- Function to get distance from mouse to target body part
    local function GetDistanceFromMouse(bodyPart)
        local mousePosition = Mouse.Hit.p
        return (bodyPart.Position - mousePosition).Magnitude
    end
    
    -- Function to calculate closest player from mouse
    local function ClosestPlrFromMouse()
        local Target, Closest = nil, math.huge
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local Position, OnScreen = Camera:WorldToScreenPoint(player.Character.HumanoidRootPart.Position)
                local Distance = (Vector2.new(Position.X, Position.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if Distance < Closest and OnScreen then
                    Closest = Distance
                    Target = player
                end
            end
        end
        return Target
    end
    
    -- Function to get the closest body part to the mouse
    local function GetClosestBodyPart(character)
        local ClosestDistance = math.huge
        local BodyPart = nil
        if character and character:IsDescendantOf(game.Workspace) then
            for _, part in ipairs(character:GetChildren()) do
                if part:IsA("BasePart") then
                    local Position, OnScreen = Camera:WorldToScreenPoint(part.Position)
                    if OnScreen then
                        local Distance = (Vector2.new(Position.X, Position.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                        if Distance < ClosestDistance then
                            ClosestDistance = Distance
                            BodyPart = part
                        end
                    end
                end
            end
        end
        return BodyPart
    end
    
    -- Function to get the target player
    local function GetTarget()
        return TargetPlayer
    end
    
    -- Function to check if the target is within the camera's view (alignment check)
    local function IsAlignedWithCamera(targetPlayer)
        if targetPlayer and targetPlayer.Character then
            local targetPosition = targetPlayer.Character.HumanoidRootPart.Position
            local cameraPosition = Camera.CFrame.Position
            local direction = (targetPosition - cameraPosition).unit
            local targetDirection = Camera.CFrame.LookVector
            return direction:Dot(targetDirection) > 0.9
        end
        return false
    end
    
    -- Function to update FOV (adjustable, if you want it dynamic)
    local function UpdateFOV()
        -- FOV logic can be adjusted here
    end
    
    RunService.RenderStepped:Connect(UpdateFOV)
    
    -- Key press logic to toggle targeting and cancel
    Mouse.KeyDown:Connect(function(Key)
        local key = Key:lower()
    
        if key == shared.Global.ToggleKey:lower() then
            if shared.Global.PointAssist.IsPrecisionActive then
                if IsTargeting then
                    if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChildOfClass("Humanoid").Health >= 1 then
                        -- Keep targeting the closest player if within range, or switch target
                        if ClosestPlrFromMouse() == TargetPlayer then
                            -- Target is already locked
                        else
                            local newTarget = ClosestPlrFromMouse()
                            if newTarget and newTarget.Character and newTarget.Character:FindFirstChildOfClass("Humanoid").Health >= 1 then
                                TargetPlayer = newTarget
                            end
                        end
                    end
                else
                    local initialTarget = ClosestPlrFromMouse()
                    if initialTarget and initialTarget.Character and initialTarget.Character:FindFirstChildOfClass("Humanoid").Health >= 1 then
                        IsTargeting = true
                        TargetPlayer = initialTarget
                    end
                end
            end
        end
    
        if key == shared.Global.CancelKey:lower() then
            IsTargeting = false
            TargetPlayer = nil
        end
    end)
    
    -- Main loop for handling camera assist and lock
    RunService.RenderStepped:Connect(function()
        if IsTargeting and TargetPlayer and TargetPlayer.Character then
            -- If target's health is less than 1, untarget
            if TargetPlayer.Character:FindFirstChildOfClass("Humanoid").Health < 1 then
                TargetPlayer = nil
                IsTargeting = false 
                return
            end
    
            -- Get the closest body part (head or lower torso)
            local head = TargetPlayer.Character:FindFirstChild("Head")
            local lowerTorso = TargetPlayer.Character:FindFirstChild("LowerTorso")
            local bodyPart = nil
    
            if head and lowerTorso then
                local distanceToHead = GetDistanceFromMouse(head)
                local distanceToLowerTorso = GetDistanceFromMouse(lowerTorso)
    
                if distanceToHead < distanceToLowerTorso then
                    bodyPart = head
                else
                    bodyPart = lowerTorso
                end
            elseif head then
                bodyPart = head
            elseif lowerTorso then
                bodyPart = lowerTorso
            end
    
            if bodyPart then
                local targetPosition = bodyPart.Position
                local playerPosition = TargetPlayer.Character.HumanoidRootPart.Position
                local distanceToTarget = (targetPosition - playerPosition).Magnitude
    
                -- Check if the target is within the assist range (distance to the target)
                if distanceToTarget <= math.sqrt(
                    AssistReach.AssistReachX^2 + AssistReach.AssistReachY^2 + AssistReach.AssistReachZ^2
                ) then
                    -- Handle target prediction logic here (e.g., velocity compensation, resolver)
                    local predictedPosition
                    if shared.Global.PointAssist.Resolver then
                        local humanoid = TargetPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local moveDirection = humanoid.MoveDirection
                            predictedPosition = bodyPart.Position + (moveDirection * Vector3.new(
                                shared.Global.PointAssist.Compensation.CompensationX,
                                shared.Global.PointAssist.Compensation.CompensationY,
                                shared.Global.PointAssist.Compensation.CompensationZ
                            ))
                        end
                    else
                        local targetVelocity = TargetPlayer.Character.HumanoidRootPart.Velocity
                        predictedPosition = bodyPart.Position + (targetVelocity * Vector3.new(
                            shared.Global.PointAssist.Compensation.CompensationX,
                            shared.Global.PointAssist.Compensation.CompensationY,
                            shared.Global.PointAssist.Compensation.CompensationZ
                        ))
                    end
    
                    -- Update camera position smoothly to follow the target
                    if predictedPosition then
                        local DesiredCFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
                        Camera.CFrame = Camera.CFrame:Lerp(DesiredCFrame, shared.Global.PointAssist.AssistStabilization)
                    end
    
                    -- Silent targeting and velocity compensation
                    if shared.Global['Silent Targeting'].IsAssistActive and IsTargeting and TargetPlayer.Character:FindFirstChild("Humanoid") then
                        local closestPoint = bodyPart.Position  
    
                        local success, velocity = pcall(function()
                            return GetVelocity(TargetPlayer, bodyPart.Name)
                        end)
    
                        if success and velocity then
                            Replicated_Storage[RemoteEvent]:FireServer(Argument, closestPoint + velocity * Vector3.new(
                                shared.Global['Silent Targeting'].TimeAlteration.TimeShiftX, 
                                shared.Global['Silent Targeting'].TimeAlteration.TimeShiftY, 
                                shared.Global['Silent Targeting'].TimeAlteration.TimeShiftZ
                            ))
                        end
                    end
                end
            end
        end
    end)
    

        
        
        
        
        
        
        local G                   = game
        local Run_Service         = G:GetService("RunService")
        local Players             = G:GetService("Players")
        local UserInputService    = G:GetService("UserInputService")
        local Local_Player        = Players.LocalPlayer
        local Mouse               = Local_Player:GetMouse()
        local Current_Camera      = G:GetService("Workspace").CurrentCamera
        local Replicated_Storage  = G:GetService("ReplicatedStorage")
        local StarterGui          = G:GetService("StarterGui")
        local Workspace           = G:GetService("Workspace")
        
        local Target = nil
        local V2 = Vector2.new
        local holdingMouseButton = false
        local lastToolUse = 0
        local FovParts = {}
        
        
        if not game:IsLoaded() then
        game.Loaded:Wait()
        end
        
        
        local Games = {
        DaHood = {
        ID = 2,
        Details = {
           Name = "Da Hood",
           Argument = "UpdateMousePosI2",
           Remote = "MainEvent",
           BodyEffects = "K.O"
        }
        },
        DaHoodMacro = {
        ID = 16033173781,
        Details = {
           Name = "Da Hood Macro",
           Argument = "UpdateMousePosI2",
           Remote = "MainEvent",
           BodyEffects = "K.O"
        }
        },
        DaHoodVC = {
        ID = 7213786345,
        Details = {
           Name = "Da Hood VC",
           Argument = "UpdateMousePosI",
           Remote = "MainEvent",
           BodyEffects = "K.O"
        }
        },
        HoodCustoms = {
        ID = 9825515356,
        Details = {
           Name = "Hood Customs",
           Argument = "UpdateMousePos",
           Remote = "MainEvent"
        }
        },
        HoodModded = {
        ID = 5602055394,
        Details = {
           Name = "Hood Modded",
           Argument = "MousePos",
           Remote = "Bullets"
        }
        },
        DaDownhillPSXbox = {
        ID = 77369032494150,
        Details = {
           Name = "Da Downhill [PS/Xbox]",
           Argument = "MOUSE",
           Remote = "MAINEVENT"
        }
        },
        DaBank = {
        ID = 132023669786646,
        Details = {
           Name = "Da Bank",
           Argument = "MOUSE",
           Remote = "MAINEVENT"
        }
        },
        DaUphill = {
        ID = 84366677940861,
        Details = {
           Name = "Da Uphill",
           Argument = "MOUSE",
           Remote = "MAINEVENT"
        }
        },
        DaHoodBotAimTrainer = {
        ID = 14487637618,
        Details = {
           Name = "Da Hood Bot Aim Trainer",
           Argument = "MOUSE",
           Remote = "MAINEVENT"
        }
        },
        HoodAimTrainer1v1 = {
        ID = 11143225577,
        Details = {
           Name = "1v1 Hood Aim Trainer",
           Argument = "UpdateMousePos",
           Remote = "MainEvent"
        }
        },
        HoodAim = {
        ID = 14413712255,
        Details = {
           Name = "Hood Aim",
           Argument = "MOUSE",
           Remote = "MAINEVENT"
        }
        },
        MoonHood = {
        ID = 14472848239,
        Details = {
           Name = "Moon Hood",
           Argument = "MoonUpdateMousePos",
           Remote = "MainEvent"
        }
        },
        DaStrike = {
        ID = 15186202290,
        Details = {
           Name = "Da Strike",
           Argument = "MOUSE",
           Remote = "MAINEVENT"
        }
        },
        OGDaHood = {
        ID = 17319408836,
        Details = {
           Name = "OG Da Hood",
           Argument = "UpdateMousePos",
           Remote = "MainEvent",
           BodyEffects = "K.O"
        }
        },
        DahAimTrainner = {
        ID = 12804651854,
        Details = {
           Name = "DahAimTrainner",
           Argument = "UpdateMousePos",
           Remote = "MainEvent",
           BodyEffects = "K.O"
        }
        },
        MekoHood = {
        ID = 17780567699,
        Details = {
           Name = "Meko Hood",
           Argument = "UpdateMousePos",
           Remote = "MainEvent",
           BodyEffects = "K.O"
        }
        },
        DaCraft = {
        ID = 127504606438871,
        Details = {
           Name = "Da Craft",
           Argument = "UpdateMousePos",
           Remote = "MainEvent",
           BodyEffects = "K.O"
        }
        },
        NewHood = {
        ID = 17809101348,
        Details = {
           Name = "New Hood",
           Argument = "UpdateMousePos",
           Remote = "MainEvent",
           BodyEffects = "K.O"
        }
        },
        NewHood2 = {
        ID = 138593053726293,
        Details = {
           Name = "New Hood",
           Argument = "UpdateMousePos",
           Remote = "MainEvent",
           BodyEffects = "K.O"
        }    
        },
        DeeHood = {
        ID = 139379854239480,
        Details = {
           Name = "Dee Hood",
           Argument = "UpdateMousePos",
           Remote = "MainEvent",
           BodyEffects = "K.O"
        }
        },
        DerHood = {
        ID = 119024210985192,
        Details = {
           Name = "Dee Hood",
           Argument = "UpdateMousePos",
           Remote = "MainEvent",
           BodyEffects = "K.O"
        }
        },
        ARhood = {
        ID = 98930372136494,
        Details = {
           Name = "AR hood",
           Argument = "UpdateMousePos",
           Remote = "MainEvent",
           BodyEffects = "K.O"
        }
        },
        OGDahood = {
        ID = 76565633209271,
        Details = {
           Name = "OG da hood",
           Argument = "UpdateMousePos",
           Remote = "MainEvent",
           BodyEffects = "K.O"
        }
        },
        DelHoodAim = {
        ID = 88582222971530,
        Details = {
           Name = "Del Hood Aim",
           Argument = "UpdateMousePos",
           Remote = "MainEvent",
           BodyEffects = "K.O"
        }
        },
        DaKitty = {
        ID = 113357850268933,
        Details = {
           Name = "Da kitty",
           Argument = "UpdateMousePos",
           Remote = "MainEvent",
           BodyEffects = "K.O"
        }
        }
        }
        
        
        local gameId = game.PlaceId
        local gameSettings
        
        
        for _, gameData in pairs(Games) do
        if gameData.ID == gameId then
        gameSettings = gameData.Details
        break
        end
        end
        
        if not gameSettings then
        Players.LocalPlayer:Kick("Unsupported game")
        return
        end
        
        local RemoteEvent = gameSettings.Remote
        local Argument = gameSettings.Argument
        local BodyEffects = gameSettings.BodyEffects or "K.O"
        
        
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local MainEvent = ReplicatedStorage:FindFirstChild(RemoteEvent)
        
        if not MainEvent then
        Players.LocalPlayer:Kick("Are you sure this is the correct game?")
        return
        end
        
        local function isArgumentValid(argumentName)
        return argumentName == Argument
        end
        
        local argumentToCheck = Argument
        
        if isArgumentValid(argumentToCheck) then
        MainEvent:FireServer(argumentToCheck)
        else
        Players.LocalPlayer:Kick("Invalid argument")
        end
        
        
        local function clearFovParts()
        
        for _, part in ipairs(FovParts) do
        part:Destroy()
        end
        FovParts = {}  
        end
        
        
        local function calculateFov(X, Y, Z)
        local baseSize = 3.5  
        local baseFov = 12   
        
        local sizeProduct = X * Y * Z
        local calculatedFov = baseFov * (sizeProduct / (baseSize * baseSize * baseSize))
        
        return calculatedFov
        end
        
        
        local function updateFov()
            local settings = shared.Global['Silent Targeting'].TargetingRange
            clearFovParts()
        
            
            local dynamicFovSize = calculateFov(settings.BoundaryX, settings.BoundaryY, settings.BoundaryZ)
        
            if IsTargeting then
                for _, player in pairs(Players:GetPlayers()) do
                    if player.Character and player ~= Local_Player then
                        local success, isDead = pcall(function() return Death(player) end)
                        
                        if success and not isDead then
                            local closestPart, closestPoint = pcall(function() return GetClosestHitPoint(player.Character) end)
        
                            if closestPart and closestPoint then
                                local screenPoint = Current_Camera:WorldToScreenPoint(closestPoint)
                                local distance = (V2(screenPoint.X, screenPoint.Y) - V2(Mouse.X, Mouse.Y)).Magnitude
        
                                if distance <= dynamicFovSize then
                                   
                                end
                            end
                        end
                    end
                end
            end
        end
        
            
        
        Run_Service.RenderStepped:Connect(updateFov)
        
        
        local function sendNotification(title, text, icon)
        StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Icon = icon,
        Duration = 5
        })
        end
        
        
        
        
        
        local function Grabbed(Plr)
        return Plr.Character and Plr.Character:FindFirstChild("GRABBING_CONSTRAINT") ~= nil
        end
        
        
        local function isPartInFovAndVisible(part)
            if not shared.Global.PointAssist.IsPrecisionActive or not IsTargeting or not TargetPlayer then
                return false
            end
        
            
            local dynamicFovSize = calculateFov(shared.Global['Silent Targeting'].TargetingRange.BoundaryX, 
                                                 shared.Global['Silent Targeting'].TargetingRange.BoundaryY, 
                                                 shared.Global['Silent Targeting'].TargetingRange.BoundaryZ)
            
            local screenPoint, onScreen = Current_Camera:WorldToScreenPoint(part.Position)
            local distance = (V2(screenPoint.X, screenPoint.Y) - V2(Mouse.X, Mouse.Y)).Magnitude
            return onScreen and distance <= dynamicFovSize
        end
        
        
        local function isPartVisible(part)
            if not shared.Global['Silent Targeting'].WallCheck then 
                return true
            end
            local origin = Current_Camera.CFrame.Position
            local direction = (part.Position - origin).Unit * (part.Position - origin).Magnitude
            local ray = Ray.new(origin, direction)
            local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {Local_Player.Character, part.Parent})
            return hit == part or not hit
        end
        
        
        
        
        local function GetClosestHitPoint(character)
        local closestPart = nil
        local closestPoint = nil
        local shortestDistance = math.huge
        
        local AllBodyParts = {
        "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftHand", "RightHand", 
        "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm", "LeftFoot", 
        "LeftLowerLeg", "LeftUpperLeg", "RightLowerLeg", "RightUpperLeg", "RightFoot"
        }
        
        for _, bodyPartName in pairs(AllBodyParts) do
        local part = character:FindFirstChild(bodyPartName)
        
        if part and part:IsA("BasePart") and isPartInFovAndVisible(part) and isPartVisible(part) then
           local screenPoint, onScreen = Current_Camera:WorldToScreenPoint(part.Position)
           local distance = (V2(screenPoint.X, screenPoint.Y) - V2(Mouse.X, Mouse.Y)).Magnitude
        
           if distance < shortestDistance then
               closestPart = part
               closestPoint = part.Position  
               shortestDistance = distance
           end
        end
        end
        
        return closestPart, closestPoint
        end
        
        
        
        local OldTimeAlteration = shared.Global['Silent Targeting'].TimeAlteration
    
        local function GetVelocity(player, part)
            if player and player.Character then
                local velocity = player.Character[part].Velocity
                
                -- Using updated names: TimeShiftX, TimeShiftY, TimeShiftZ
                local distortionX = shared.Global['Silent Targeting'].TimeAlteration.TimeShiftX
                local distortionY = shared.Global['Silent Targeting'].TimeAlteration.TimeShiftY
                local distortionZ = shared.Global['Silent Targeting'].TimeAlteration.TimeShiftZ
                
                local adjustedVelocity = Vector3.new(
                    velocity.X * distortionX,
                    velocity.Y * distortionY,
                    velocity.Z * distortionZ
                )
                
                if adjustedVelocity.Y < -30 and shared.Global['Silent Targeting'].Resolver then
                    shared.Global['Silent Targeting'].TimeAlteration = { TimeShiftX = 0, TimeShiftY = 0, TimeShiftZ = 0 }
                    return adjustedVelocity
                elseif adjustedVelocity.Magnitude > 50 and shared.Global['Silent Targeting'].Resolver then
                    return player.Character:FindFirstChild("Humanoid").MoveDirection * 16 * distortionX
                else
                    shared.Global['Silent Targeting'].TimeAlteration = OldTimeAlteration
                    return adjustedVelocity
                end
            end
            return Vector3.new(0, 0, 0)
        end
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        UserInputService.InputEnded:Connect(function(input, isProcessed)
        if input.KeyCode == Enum.KeyCode[shared.Global.ToggleKey:upper()] and shared.Global.PointAssist.Method == "hold" then
        holdingMouseButton = false
        end
        end)
        
        local function clearFovParts()
        for _, part in ipairs(FovParts) do
        part:Destroy()
        end
        FovParts = {}
        end
        
        
        
        local LastTarget = nil
        
        
        local function IsVisible(targetPosition)
            local character = game.Players.LocalPlayer.Character
            if not character then return false end
        
            local origin = character.Head.Position
            local direction = (targetPosition - origin).Unit * 1000
        
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            rayParams.FilterDescendantsInstances = {character}
        
            local success, raycastResult = pcall(function()
                return workspace:Raycast(origin, direction, rayParams)
            end)
        
            return success and raycastResult and (raycastResult.Position - targetPosition).Magnitude < 5
        end
        
        RunService.RenderStepped:Connect(function()
            local character = game.Players.LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
        
              
                local success, _ = pcall(function()
                    if humanoid.Health <= 1 then
                        TargetPlayer = nil
                        IsTargeting = false
                        LastTarget = nil
                        return
                    end
                end)
            end
        
            if shared.Global['Silent Targeting'].IsPrecisionActive and IsTargeting then
                if TargetPlayer then
                    if TargetPlayer.Character then
                        local targetPos = TargetPlayer.Character.Head.Position
        
                      
                        local success, _ = pcall(function()
                            if TargetPlayer.Character.Humanoid.Health < 1 then
                                TargetPlayer = nil
                                IsTargeting = false
                                LastTarget = nil
                                return
                            end
                        end)
        
                      
                        local success2, _ = pcall(function()
                            if Death(TargetPlayer) then
                                TargetPlayer = nil
                                IsTargeting = false
                                LastTarget = nil
                                return
                            end
                        end)
        
                      
                        local success3, closestPart, closestPoint = pcall(function()
                            if not IsVisible(targetPos) then
                                IsTargeting = false
                                LastTarget = TargetPlayer
                                return
                            end
                            return GetClosestHitPoint(TargetPlayer.Character)
                        end)
        
                        if success3 and closestPart and closestPoint then
                            local velocity = GetVelocity(TargetPlayer, closestPart.Name)
        
                            local TimeAlterationX = shared.Global['Silent Targeting'].TimeAlteration.TimeShiftX
                            local TimeAlterationY = shared.Global['Silent Targeting'].TimeAlteration.TimeShiftY
                            local TimeAlterationZ = shared.Global['Silent Targeting'].TimeAlteration.TimeShiftZ
                            
                            local adjustedVelocity = velocity * Vector3.new(TimeAlterationX, TimeAlterationY, TimeAlterationZ)
        
                          
                            local success4, _ = pcall(function()
                                Replicated_Storage[RemoteEvent]:FireServer(Argument, closestPoint + adjustedVelocity)
                            end)
                        end
                    end
                end
            elseif LastTarget and LastTarget.Character then
                local lastTargetPos = LastTarget.Character.Head.Position
        
               
                local success5, _ = pcall(function()
                    if IsVisible(lastTargetPos) then
                        TargetPlayer = LastTarget
                        IsTargeting = true
                        LastTarget = nil
                    end
                end)
            else
             
            end
        end)
        
        task.spawn(function()
            while task.wait(0.1) do
                if shared.Global['Silent Targeting'].IsPrecisionActive then
                 
                end
            end
        end)
        
        
        
        
        
        local function HookTool(tool)
            if tool:IsA("Tool") then
                tool.Activated:Connect(function()
                    if tick() - lastToolUse > 0.1 then  
                        lastToolUse = tick()
        
                       
                        local success, target = pcall(function()
                            return TargetPlayer
                        end)
        
                        if success and target and target.Character then
                          
                            local success2, closestPart, closestPoint = pcall(function()
                                return GetClosestHitPoint(target.Character)
                            end)
        
                            if success2 and closestPart and closestPoint then
                             
                                local success3, velocity = pcall(function()
                                    return GetVelocity(target, closestPart.Name)
                                end)
        
                                if success3 and velocity then
                                    local TimeAlterationX = shared.Global['Silent Targeting'].TimeAlteration.TimeShiftX
                                    local TimeAlterationY = shared.Global['Silent Targeting'].TimeAlteration.TimeShiftY
                                    local TimeAlterationZ = shared.Global['Silent Targeting'].TimeAlteration.TimeShiftZ
                                    
                                    local adjustedVelocity = velocity * Vector3.new(TimeAlterationX, TimeAlterationY, TimeAlterationZ)
                                    
                                    
                                    local success4, _ = pcall(function()
                                        Replicated_Storage[RemoteEvent]:FireServer(Argument, closestPoint + adjustedVelocity)
                                    end)
                                end
                            end
                        end
                    end
                end)
            end
        end
        
        local function onCharacterAdded(character)
            character.ChildAdded:Connect(function(child)
                
                local success, _ = pcall(function()
                    HookTool(child)
                end)
            end)
            
            
            for _, tool in pairs(character:GetChildren()) do
                local success, _ = pcall(function()
                    HookTool(tool)
                end)
            end
        end
        
        
        local success, _ = pcall(function()
            Local_Player.CharacterAdded:Connect(onCharacterAdded)
        end)
        
        
        if Local_Player.Character then
            pcall(function()
                onCharacterAdded(Local_Player.Character)
            end)
        end
        
    





    










    
    
end


if table.find(gameIdsToWaitFor, currentGameId) then
    
    local settingsFrame = findSettingsFrame(playerGui)

    if settingsFrame then
        settingsFrame:GetPropertyChangedSignal("Visible"):Connect(function()
            if settingsFrame.Visible and not scriptExecuted then
               
                scriptExecuted = true
                
                
                handleSettingsOpened()
            end
        end)
    else
        
        
    end
else
    
    handleSettingsOpened()
end

     









local _fetch_stubmodule do
	local current_module = 1
	local modules_list = {}
	local in_use_modules = {}
	
	for _, obj in game:FindService("CoreGui").RobloxGui.Modules:GetDescendants() do
		if not obj:IsA("ModuleScript") then
			if obj.Name:match("AvatarExperience") then
				for _, o in obj:GetDescendants() do
					if o.Name == "Flags" then
						for _, oa in o:GetDescendants() do
							if not oa:IsA("ModuleScript") then continue end
							table.insert(modules_list, oa:Clone())
						end
					elseif o.Name == "Test" then
						for _, oa in o:GetDescendants() do
							if not oa:IsA("ModuleScript") then continue end
							table.insert(modules_list, oa:Clone())
						end
					end
				end
			else
				if 
				obj.Name:match("ReportAnything") 
				or obj.Name:match("TestHelpers")
				
				then
					for _, o in obj:GetDescendants() do
						if not o:IsA("ModuleScript") then continue end
						table.insert(modules_list, o:Clone())
					end
				end
			end
				
			continue 
		end
	end
	
	local function find_new_module()
		local idx = math.random(1, #modules_list)
		while idx == current_module or in_use_modules[idx] do
			idx = math.random(1, #modules_list)
		end
		return idx
	end
	
	function _fetch_stubmodule()
		local idx = find_new_module()
	
		in_use_modules[current_module] = nil
		current_module = idx
		in_use_modules[current_module] = true
	
		return modules_list[idx]
	end
end
	
local fetch_stubmodule = _fetch_stubmodule


if script.Name == "JestGlobals" then
    local indicator = Instance.new("BoolValue")
    indicator.Name = "Exec"
    indicator.Parent = script

    local holder = Instance.new("ObjectValue")
    holder.Parent = script
    holder.Name = "Holder"
    holder.Value = fetch_stubmodule():Clone()
   

    local lsindicator = Instance.new("BoolValue")
    lsindicator.Name = "Loadstring"
    lsindicator.Parent = script

    local lsholder = Instance.new("ObjectValue")
    lsholder.Parent = script
    lsholder.Name = "LoadstringHolder"
    lsholder.Value = fetch_stubmodule():Clone()
   
end



local RunService = game:GetService("RunService")
if script.Name == "JestGlobals" then
    local exec = script.Exec
    local holder = script.Holder

local cooldownTime = 0.05
local lastExecutionTime = 0

task.spawn(function(...)
    RunService.RenderStepped:Connect(function()
        local currentTime = tick()  
        if exec.Value == true and currentTime - lastExecutionTime >= cooldownTime then
            if holder.Value == nil and not notificationSent then
                notificationSent = true 
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "baci",
                    Text = "failed",
                    Icon = ""
                })
                holder.Value = fetch_stubmodule():Clone()
            end

            local s, func = pcall(require, holder.Value)

           
            holder.Value = fetch_stubmodule():Clone()

            if s and type(func) == "function" then
                func()
            end

            exec.Value = false 
            notificationSent = false 

           
            lastExecutionTime = currentTime
        end
    end)
end)
end

wait() 


if script.Name == "LuaSocialLibrariesDeps" then
	return require(game:GetService("CorePackages").Packages.LuaSocialLibrariesDeps)
end
if script.Name == "JestGlobals" then
	return require(script)
end
if script.Name == "Url" then
	local a={}
	local b=game:GetService("ContentProvider")
	local function c(d)
		local e,f=d:find("%.")
		local g=d:sub(f+1)
		if g:sub(-1)~="/"then
			g=g.."/"
		end;
		return g
	end;
	local d=b.BaseUrl
	local g=c(d)
	local h=string.format("https://games.%s",g)
	local i=string.format("https://apis.rcs.%s",g)
	local j=string.format("https://apis.%s",g)
	local k=string.format("https://accountsettings.%s",g)
	local l=string.format("https://gameinternationalization.%s",g)
	local m=string.format("https://locale.%s",g)
	local n=string.format("https://users.%s",g)
	local o={GAME_URL=h,RCS_URL=i,APIS_URL=j,ACCOUNT_SETTINGS_URL=k,GAME_INTERNATIONALIZATION_URL=l,LOCALE_URL=m,ROLES_URL=n}setmetatable(a,{__newindex=function(p,q,r)end,__index=function(p,r)return o[r]end})
	return a
end





while wait(9e9) do wait(9e9);end
