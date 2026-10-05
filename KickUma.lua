if getgenv().yurikiskis then
    warn("yuri")
    return
end
function missing(t, f, fallback)
        if type(f) == t then return f end
        return fallback
end
cloneref = missing("function", cloneref, function(...) return ... end)
getconnections = missing("function", getconnections or get_signal_cons)
local Support = {
    Connections = (typeof(getconnections) == "function"),
    FPS = (typeof(setfpscap) == "function"),
    HookMeta = (typeof(hookmetamethod) == "function"),
}
Services = setmetatable({}, {
        __index = function(self, name)
                local success, cache = pcall(function()
                        return cloneref(game:GetService(name))
                end)
                if success then
                        rawset(self, name, cache)
                        return cache
                else
                        error("Invalid Service: " .. tostring(name))
                end
        end
})
local Players = Services.Players
local Plr = Players.LocalPlayer
local RS = Services.ReplicatedStorage
local RunService = Services.RunService
local HttpService = Services.HttpService
local GuiService = Services.GuiService
local TeleportService = Services.TeleportService
local UIS = Services.UserInputService
local VirtualUser = Services.VirtualUser
local executorName = (identifyexecutor and identifyexecutor() or "Unknown"):lower()
local executorDisplayName = (identifyexecutor and identifyexecutor() or "Unknown")
local LimitedExecutors = {"xeno", "solara",}
local isLimitedExecutor = false
for _, name in ipairs(LimitedExecutors) do
    if string.find(executorName, name) then
        isLimitedExecutor = true
        break
    end
end
local repo = "https://raw.githubusercontent.com/iLove-yuri/Linoria/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
getgenv().yurikiskis = true
local Options = Library.Options
local Toggles = Library.Toggles
Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = true
Library.NotifySide = "Left"
local function AddInfo(Window)
    local InfoTab = Window:AddTab("Info")
    local InfoLeft = InfoTab:AddLeftGroupbox("Information")
    local statusText = isLimitedExecutor and "<font color='#FFA500'>Semi-Working</font>" or "<font color='#00FF00'>Working</font>"
    local extraNote = isLimitedExecutor
        and "<b>NOTE:</b> May experiencing bugs for some features!"
        or "All features should works properly!"
    InfoLeft:AddLabel("<b>Executor:</b> " .. executorDisplayName .. "\n<b>Status:</b> " .. statusText .. "\n" .. extraNote, true)
    local InfoRight = InfoTab:AddRightGroupbox("Others")
    InfoRight:AddButton({
        Text = "Join Discord Server",
        Func = function()
            local inviteCode = "6pCsSbVd3E"
            local inviteLink = "https://discord.gg/" .. inviteCode
            local success = false
            if request then
                success = pcall(function()
                    request({
                        Url = "http://127.0.0.1:6463/rpc?v=1",
                        Method = "POST",
                        Headers = {
                            ["Content-Type"] = "application/json",
                            ["Origin"] = "https://discord.com"
                        },
                        Body = HttpService:JSONEncode({
                            cmd = "INVITE_BROWSER",
                            args = { code = inviteCode },
                            nonce = HttpService:GenerateGUID(false)
                        })
                    })
                end)
            end
            if not success and setclipboard then
                setclipboard(inviteLink)
            end
        end,
    })
end
local eh_success, err = pcall(function()
local Flags = {}
local Shared = {
}
local Connections = {
    Player_General = nil,
    Knockback = {},
    Reconnect = nil,
}
local function SafeConnect(key, getSignalFn, handler)
    local ok, signal = pcall(getSignalFn)
    if not ok or not signal then
        return
    end
    Connections[key] = signal:Connect(handler)
end
local function Cleanup(tbl)
    for key, value in pairs(tbl) do
        if typeof(value) == "RBXScriptConnection" then
            value:Disconnect()
            tbl[key] = nil
        elseif typeof(value) == 'thread' then
            task.cancel(value)
            tbl[key] = nil
        elseif type(value) == 'table' then
            Cleanup(value)
        end
    end
end
function Thread(featurePath, featureFunc, isEnabled, ...)
    local pathParts = featurePath:split(".")
    local currentTable = Flags
    for i = 1, #pathParts - 1 do
        local part = pathParts[i]
        if not currentTable[part] then currentTable[part] = {} end
        currentTable = currentTable[part]
    end
    local flagKey = pathParts[#pathParts]
    local activeThread = currentTable[flagKey]
    if isEnabled then
        if not activeThread or coroutine.status(activeThread) == "dead" then
            currentTable[flagKey] = task.spawn(featureFunc, ...)
        end
    else
        if activeThread and typeof(activeThread) == 'thread' then
            task.cancel(activeThread)
            currentTable[flagKey] = nil
        end
    end
end
local function SafeLoop(name, func)
    return function()
        local success, err = pcall(func)
        if not success then
            Library:Notify("Error in ["..name.."]: "..tostring(err), 10)
            warn("Error in ["..name.."]: "..tostring(err))
        end
    end
end
function AddSliderToggle(Config)
    local Toggle = Config.Group:AddToggle(Config.Id, {
        Text = Config.Text,
        Default = Config.DefaultToggle or false,
        Disabled = Config.Disabled,
    })
    local Slider = Config.Group:AddSlider(Config.Id .. "Value", {
        Text = Config.Text,
        Default = Config.Default,
        Min = Config.Min,
        Max = Config.Max,
        Rounding = Config.Rounding or 0,
        Compact = true,
        Visible = false
    })
    Toggle:OnChanged(function()
        Slider:SetVisible(Toggle.Value)
    end)
    return Toggle, Slider
end
local function GetCharacter()
    local c = Plr.Character
    return (c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid")) and c or nil
end
local function TPTo(target, offset)
    local char = GetCharacter()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local cframe
    if typeof(target) == "CFrame" then
        cframe = target
    elseif typeof(target) == "Vector3" then
        cframe = CFrame.new(target)
    elseif typeof(target) == "Instance" then
        if target:IsA("BasePart") then
            cframe = target.CFrame
        elseif target:IsA("Model") then
            cframe = target:GetPivot()
        end
    end
    if not cframe then return false end
    if offset then
        cframe = cframe * CFrame.new(offset)
    end
    hrp.CFrame = cframe
    return true
end
local function FuncTPW()
    while true do
        local delta = RunService.Heartbeat:Wait()
        local char = GetCharacter()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if char and hum and hum.Health > 0 then
            if hum.MoveDirection.Magnitude > 0 then
                local speed = Options.TPWValue.Value
                char:TranslateBy(hum.MoveDirection * speed * delta * 10)
            end
        end
    end
end
local function FuncNoclip()
    while Toggles.Noclip.Value do
        RunService.Stepped:Wait()
        local char = GetCharacter()
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end
function gsc(guiObject)
    if not guiObject then return false end
    local success = false
    pcall(function()
        if Services.GuiService and Services.VirtualInputManager then
            Services.GuiService.SelectedObject = guiObject
            task.wait(0.05)
            local keys = {Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter, Enum.KeyCode.ButtonA}
            for _, key in ipairs(keys) do
                Services.VirtualInputManager:SendKeyEvent(true, key, false, game); task.wait(0.03)
                Services.VirtualInputManager:SendKeyEvent(false, key, false, game); task.wait(0.03)
            end
            Services.GuiService.SelectedObject = nil
            success = true
        end
    end)
    return success
end
local function FirePP(target, teleport)
    if not fireproximityprompt then return end
    if not target or not target:IsA("ProximityPrompt") then return end
    local prevDist = target.MaxActivationDistance
    if teleport then
        local char = GetCharacter()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local part = target.Parent
        local isModel = false
        if part then
            if part:IsA("Model") then
                isModel = true
            elseif not part:IsA("BasePart") then
                part = target:FindFirstAncestorWhichIsA("BasePart")
                if not part then
                    part = target:FindFirstAncestorWhichIsA("Model")
                    if part then
                        isModel = true
                    end
                end
            end
        end
        if hrp and part then
            local partPos = isModel and part:GetPivot().Position or part.Position
            local dist = (hrp.Position - partPos).Magnitude
            if dist > prevDist then
                local partCFrame = isModel and part:GetPivot() or part.CFrame
                hrp.CFrame = partCFrame * CFrame.new(0, 3, 0)
                task.wait(0.175)
            end
        end
    end
    fireproximityprompt(target)
end
local function Serverhop()
    local hopSuccess, hopErr = pcall(function()
        local baseUrl = 'https://games.roblox.com/v1/games/' .. game.PlaceId .. '/servers/Public?sortOrder=Asc&limit=100'
        local servers = {}
        local cursor = ''
        for _ = 1, 3 do
            local url = baseUrl
            if cursor ~= '' then url = url .. '&cursor=' .. cursor end
            local pages = game:HttpGet(url)
            local data = HttpService:JSONDecode(pages)
            for _, server in ipairs(data.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server)
                end
            end
            cursor = data.nextPageCursor
            if not cursor or cursor == '' then break end
        end
        table.sort(servers, function(a, b) return a.playing < b.playing end)
        if #servers == 0 then
            Library:Notify("No servers found to hop to.", 3)
            return
        end
        local best = servers[1]
        for _, server in ipairs(servers) do
            if server.playing > 0 then
                best = server
                break
            end
        end
        TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, Plr)
    end)
    if not hopSuccess then
        Library:Notify("Serverhop failed: " .. tostring(hopErr), 5)
    end
end
local Window = Library:CreateWindow({
        Title = "Yuri",
        Center = true,
        AutoShow = true,
        Resizable = true,
        ShowCustomCursor = false,
        UnlockMouseWhileOpen = false,
        NotifySide = "Left",
        TabPadding = 8,
        MenuFadeTime = 0.2
})
AddInfo(Window)
local Tabs = {
        Main = Window:AddTab("Main"),
    Player = Window:AddTab("Player"),
    Config = Window:AddTab("Config"),
}
local TB = {
    Main = {
        Left = {
            Autofarm = Tabs.Main:AddLeftTabbox(),
        },
        Right = {
            Autofarm = Tabs.Main:AddRightTabbox(),
        },
    },
}
local TB_Tabs = {
    Autofarm = {
        T1 = TB.Main.Left.Autofarm:AddTab("Autofarm"),
    },
    Autofarm2 = {
        T1 = TB.Main.Right.Autofarm:AddTab("Config"),
    },
}
local GB = {
    Player = {
        Left = {
            General = Tabs.Player:AddLeftGroupbox("General"),
            Server  = Tabs.Player:AddLeftGroupbox("Server"),
        },
        Right = {
            Game = Tabs.Player:AddRightGroupbox("Game"),
        },
    },
}
AddSliderToggle({ Group = GB.Player.Left.General, Id = "WS", Text = "WalkSpeed", Default = 16, Min = 16, Max = 1000 })
local TPW_T, TPW_S = AddSliderToggle({ Group = GB.Player.Left.General, Id = "TPW", Text = "TPWalk", Default = 1, Min = 1, Max = 30, Rounding = 1 })
AddSliderToggle({ Group = GB.Player.Left.General, Id = "JP", Text = "JumpPower", Default = 50, Min = 0, Max = 500 })
AddSliderToggle({ Group = GB.Player.Left.General, Id = "HH", Text = "HipHeight", Default = 2, Min = 0, Max = 10, Rounding = 1 })
GB.Player.Left.General:AddToggle("Noclip", { Text = "Noclip" })
AddSliderToggle({ Group = GB.Player.Left.General, Id = "Grav", Text = "Gravity", Default = 196, Min = 0, Max = 500, Rounding = 1})
AddSliderToggle({ Group = GB.Player.Left.General, Id = "Zoom", Text = "Camera Zoom", Default = 128, Min = 128, Max = 10000 })
AddSliderToggle({ Group = GB.Player.Left.General, Id = "FOV", Text = "Field of View", Default = 70, Min = 30, Max = 120 })
GB.Player.Left.Server:AddToggle("AntiAFK", {
    Text = "Anti AFK",
    Default = true,
    Disabled = not Support.Connections,
})
GB.Player.Left.Server:AddButton({ Text = "Serverhop", Func = function() Serverhop() end })
GB.Player.Left.Server:AddButton({ Text = "Rejoin", Func = function() Services.TeleportService:Teleport(game.PlaceId, Plr) end })
GB.Player.Left.Server:AddToggle("AutoServerhop", { Text = "Auto Serverhop" })
GB.Player.Left.Server:AddSlider("AutoHopMins", { Text = "Minutes", Default = 30, Min = 0, Max = 300, Compact = true, Rounding = 0 })
GB.Player.Right.Game:AddToggle("InstantPP", { Text = "Instant Prompt" })
Toggles.TPW:OnChanged(function(v)
    TPW_S:SetVisible(TPW_T.Value)
    Thread("TPW", FuncTPW, v)
end)
Toggles.Noclip:OnChanged(function(v)
    Thread("Noclip", FuncNoclip, v)
end)
Toggles.AutoServerhop:OnChanged(function(state)
    Thread("AutoServerhop", function()
        local lastHop = tick()
        while Toggles.AutoServerhop.Value do
            task.wait(5)
            if not Toggles.AutoServerhop.Value then break end
            if (tick() - lastHop) >= (Options.AutoHopMins.Value * 60) then
                Serverhop()
                break
            end
        end
    end, state)
end)
Connections.Player_General = RunService.Stepped:Connect(function()
    local Hum = Plr.Character and Plr.Character:FindFirstChildOfClass("Humanoid")
    if Hum then
        if Toggles.WS.Value then Hum.WalkSpeed = Options.WSValue.Value end
        if Toggles.JP.Value then Hum.JumpPower = Options.JPValue.Value Hum.UseJumpPower = true end
        if Toggles.HH.Value then Hum.HipHeight = Options.HHValue.Value end
    end
    workspace.Gravity = Toggles.Grav.Value and Options.GravValue.Value or 192
    if Toggles.FOV.Value then workspace.CurrentCamera.FieldOfView = Options.FOVValue.Value end
    if Toggles.Zoom.Value then Plr.CameraMaxZoomDistance = Options.ZoomValue.Value end
end)
local KU = {
    InGame = false,
    KickBusy = false,
    Phase = "idle",
    Plot = nil,
    Session = { Kicks = 0, Success = 0, Fail = 0, Placed = 0, Started = tick() },
}
local Network = nil
local function GetSafeModule(parent, name)
    local obj = parent:FindFirstChild(name)
    if obj and obj:IsA("ModuleScript") then
        local success, result = pcall(require, obj)
        if success then return result end
    end
    return nil
end
local Modules = {
    SpeedData = GetSafeModule(RS.Shared.Data, "SpeedData"),
    WeightsData = GetSafeModule(RS.Shared.Data, "WeightsData"),
    EntitiesData = GetSafeModule(RS.Shared.Data, "EntitiesData"),
    RebirthData = GetSafeModule(RS.Shared.Data, "RebirthData"),
    SlotUpgradesData = GetSafeModule(RS.Shared.Data, "SlotUpgradesData"),
    WeightServiceClient = GetSafeModule(RS.Modules.ServicesLoader, "WeightServiceClient"),
    KickServiceClient = GetSafeModule(RS.Modules.ServicesLoader, "KickServiceClient"),
    ClientBalanceService = GetSafeModule(RS.Modules.ServicesLoader, "ClientBalanceService"),
    SpeedServiceClient = GetSafeModule(RS.Modules.ServicesLoader, "SpeedServiceClient"),
    BaseUpgradesServiceClient = GetSafeModule(RS.Modules.ServicesLoader, "BaseUpgradesServiceClient"),
}
local function ParseNumber(v)
    if type(v) == "number" then
        return v
    end
    if type(v) == "string" then
        local a, b = v:match("^%s*([%-%d%.eE+]+)%s*,%s*([%-%d%.eE+]+)%s*$")
        if a and b then
            local m, e = tonumber(a), tonumber(b)
            if m and e then
                return m * 10 ^ e
            end
        end
        return tonumber(v)
    end
    return nil
end
local function GetBalance()
    local svc = Modules.ClientBalanceService
    if not svc then
        return nil
    end
    return ParseNumber(svc.Balance)
end
local function Fire(name, ...)
    if not Network then
        return false
    end
    local ok, err = pcall(Network.FireServer, name, ...)
    if not ok then
        warn("fire failed", name, tostring(err))
    end
    return ok
end
local function GetPlot()
    local plots = workspace:FindFirstChild("Plots")
    if KU.Plot and KU.Plot.Parent and plots and KU.Plot.Parent == plots then
        return KU.Plot
    end
    if not plots then
        return nil
    end
    for _, model in ipairs(plots:GetChildren()) do
        if model:IsA("Model") then
            local owner = model:GetAttribute("Owner")
            if owner == Plr.Name or owner == tostring(Plr.UserId) or owner == Plr.DisplayName then
                KU.Plot = model
                return model
            end
        end
    end
    return nil
end
local function SlotNumber(slotPart)
    local name = string.gsub(slotPart.Name, "Slot", "")
    return tonumber(name)
end
local function PlacedPart(slotPart)
    return slotPart:FindFirstChildOfClass("Part")
end
local function FreeSlot(plot)
    local slots = plot:FindFirstChild("Slots")
    if not slots then
        return nil, nil
    end
    for _, slotPart in ipairs(slots:GetChildren()) do
        if slotPart:IsA("BasePart") then
            local num = SlotNumber(slotPart)
            if num and not slotPart:FindFirstChildOfClass("Part") then
                return slotPart, num
            end
        end
    end
    return nil, nil
end
local function BrainrotValue(name)
    local entities = Modules.EntitiesData
    local info = entities and entities.Brainrots and entities.Brainrots[name]
    if not info then
        return nil
    end
    return tonumber(info.CPS) or tonumber(info.BasePrice)
end
local function BestPlaceOrReplaceSlot(plot, toolValue, displaced)
    local slots = plot:FindFirstChild("Slots")
    if not slots then
        return nil, nil
    end
    local worstSlot, worstNum, worstValue = nil, nil, nil
    for _, slotPart in ipairs(slots:GetChildren()) do
        if slotPart:IsA("BasePart") then
            local num = SlotNumber(slotPart)
            if num then
                local placed = PlacedPart(slotPart)
                if not placed then
                    return slotPart, num
                end
                local id = placed:GetAttribute("ID")
                if id and displaced and displaced[id] then
                else
                    local value = id and BrainrotValue(id)
                    if value and value < toolValue then
                        if not worstValue or value < worstValue then
                            worstSlot, worstNum, worstValue = slotPart, num, value
                        end
                    end
                end
            end
        end
    end
    return worstSlot, worstNum
end
local function IsUmaTool(tool)
    if not (tool and tool:IsA("Tool")) then
        return false
    end
    local entities = Modules.EntitiesData
    if entities and entities.Types then
        if entities.Types.Brainrot[tool.Name] or entities.Types.LuckyBlock[tool.Name] then
            return true
        end
    end
    local okA, a = pcall(function()
        return tool:HasTag("EntityTool")
    end)
    local okB, b = pcall(function()
        return tool:HasTag("LuckyBlockTool")
    end)
    return (okA and a == true) or (okB and b == true)
end
local function PartContains(part, pos)
    if not (part and part:IsA("BasePart") and pos) then
        return false
    end
    local rel = part.CFrame:PointToObjectSpace(pos)
    local half = part.Size * 0.5
    return math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z
end
local function EscapeWave()
    local char = GetCharacter()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local zones = workspace:FindFirstChild("Zones")
    local collect = zones and zones:FindFirstChild("CollectZone")
    if hrp and collect and collect:IsA("BasePart") and PartContains(collect, hrp.Position) then
        task.wait()
    end
    local areas = workspace:FindFirstChild("Areas")
    local kickReady = areas and areas:FindFirstChild("KickReady")
    if kickReady and kickReady:IsA("BasePart") then
        if collect and collect:IsA("BasePart") then
            TPTo(collect, Vector3.new(0, 7, 0))
        else
            TPTo(kickReady, Vector3.new(0, 7, 0))
        end
    end
end
local function WaitGameEnd(timeout)
    local t0 = tick()
    while KU.InGame and tick() - t0 < (timeout or 70) do
        task.wait()
    end
end
TB_Tabs.Autofarm.T1:AddToggle("AutoKick", { Text = "Auto Kick", Default = false })
TB_Tabs.Autofarm.T1:AddToggle("AutoEscape", { Text = "Auto Escape", Default = false })
TB_Tabs.Autofarm.T1:AddToggle("AutoBonus", { Text = "Auto Bonus", Default = false })
TB_Tabs.Autofarm.T1:AddToggle("AutoSpeedUp", { Text = "Auto Run Speed", Default = false })
TB_Tabs.Autofarm.T1:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false })
TB_Tabs.Autofarm.T1:AddToggle("AutoSlots", { Text = "Auto Slots", Default = false })
TB_Tabs.Autofarm.T1:AddToggle("AutoPlace", { Text = "Auto Place", Default = false })
TB_Tabs.Autofarm.T1:AddToggle("AutoCollect", { Text = "Auto Collect", Default = false })
TB_Tabs.Autofarm.T1:AddToggle("AutoUpgradeUmas", { Text = "Auto Upgrade Umas", Default = false })
TB_Tabs.Autofarm.T1:AddToggle("AutoBuyWeight", { Text = "Auto Weight", Default = false })
TB_Tabs.Autofarm2.T1:AddSlider("MaxUpgradeLevel", { Text = "Max Upgrade Level", Default = 75, Min = 1, Max = 75, Rounding = 0 })
TB_Tabs.Autofarm2.T1:AddInput("CollectThreshold", { Text = "Collect Threshold", Default = "0" })
local function FuncAutoEscape()
    while Toggles.AutoEscape.Value do
        local ok, err = pcall(function()
            if not KU.InGame then
                KU.Phase = "idle"
                return
            end
            local char = Plr.Character
            local pp = char and char.PrimaryPart
            if KU.Phase == "idle" then
                if pp and pp.Anchored then
                    KU.Phase = "anchored"
                end
            elseif KU.Phase == "anchored" then
                if pp and not pp.Anchored then
                    KU.Phase = "run"
                    EscapeWave()
                end
            end
        end)
        if not ok then
            warn("autoescape error", tostring(err))
        end
        task.wait(0.25)
    end
    KU.Phase = "idle"
end
local function FuncAutoKick()
    while Toggles.AutoKick.Value do
        local ok, err = pcall(function()
            if KU.InGame then
                WaitGameEnd(70)
                KU.KickBusy = false
                task.wait(1)
                return
            end
            local char = Plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then
                task.wait(1)
                return
            end
            local areas = workspace:FindFirstChild("Areas")
            local kickReady = areas and areas:FindFirstChild("KickReady")
            if not (kickReady and kickReady:IsA("BasePart")) then
                task.wait(1)
                return
            end
            KU.KickBusy = true
            hrp.CFrame = kickReady.CFrame * CFrame.new(0, 4, 0)
            task.wait(0.2)
            local fired = false
            if not KU.InGame then
                fired = Fire("KickEvent", 1e99)
                local t0 = tick()
                while not KU.InGame and tick() - t0 < 1 do
                    task.wait(0.1)
                end
            end
            if not KU.InGame then
                KU.KickBusy = false
                warn("kick not accepted")
                task.wait(1)
                return
            end
            if fired then
                KU.Session.Kicks = KU.Session.Kicks + 1
            end
            WaitGameEnd(70)
            KU.KickBusy = false
            task.wait()
        end)
        if not ok then
            KU.KickBusy = false
            Library:Notify("Error in [AutoKick]: " .. tostring(err), 8)
            warn("autokick error", tostring(err))
            task.wait(1)
        end
    end
    KU.KickBusy = false
end
local function GetSlotPrompt(slotPart)
    local attachment = slotPart:FindFirstChildOfClass("Attachment")
    return attachment and attachment:FindFirstChildOfClass("ProximityPrompt")
end
local function PlaceUma(tool, slotPart)
    local char = Plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not (hum and hrp and tool and slotPart) then
        return false
    end
    local backpack = Plr:FindFirstChildOfClass("Backpack")
    if tool.Parent == backpack then
        hum:EquipTool(tool)
        local t0 = tick()
        while tool.Parent ~= char and tool.Parent and tick() - t0 < 1 do
            task.wait(0.05)
        end
    end
    if tool.Parent ~= char then
        return false
    end
    local prompt = GetSlotPrompt(slotPart)
    if not prompt then
        return false
    end
    while tool.Parent == char do
        FirePP(prompt, true)
        task.wait(0.1)
    end
    return tool.Parent ~= char
end
local function FuncAutoPlace()
    while Toggles.AutoPlace.Value do
        local ok, err = pcall(function()
            local plot = GetPlot()
            if not plot then
                task.wait(2)
                return
            end
            local backpack = Plr:FindFirstChildOfClass("Backpack")
            if not backpack then
                task.wait(1)
                return
            end
            local placedCount = 0
            local displaced = {}
            local toolList = backpack:GetChildren()
            for _, tool in ipairs(toolList) do
                if placedCount >= 6 then
                    break
                end
                if tool.Parent == backpack and IsUmaTool(tool) then
                    if displaced[tool.Name] then
                        continue
                    end
                    local entities = Modules.EntitiesData
                    local toolType = entities and entities.GetTypeFromName and entities.GetTypeFromName(tool.Name)
                    local slotPart, slotNum
                    if toolType == "Brainrot" then
                        local toolValue = BrainrotValue(tool.Name)
                        if toolValue then
                            slotPart, slotNum = BestPlaceOrReplaceSlot(plot, toolValue, displaced)
                        else
                            slotPart, slotNum = FreeSlot(plot)
                        end
                    else
                        slotPart, slotNum = FreeSlot(plot)
                    end
                    local char = Plr.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not (hum and hrp) then
                        break
                    end
                    if not slotPart then
                        continue
                    end
                    local occupiedAtFire = PlacedPart(slotPart)
                    local occupiedId = occupiedAtFire and occupiedAtFire:GetAttribute("ID")
                    if occupiedAtFire and occupiedId == tool.Name then
                        continue
                    end
                    if occupiedAtFire then
                        local occValue = occupiedId and BrainrotValue(occupiedId)
                        local toolValue = BrainrotValue(tool.Name)
                        if not (occValue and toolValue) or occValue >= toolValue then
                            continue
                        end
                        displaced[occupiedId] = true
                    end
                    local confirmed = PlaceUma(tool, slotPart)
                    if confirmed then
                        KU.Session.Placed = KU.Session.Placed + 1
                        placedCount = placedCount + 1
                    else
                        if occupiedId then
                            displaced[occupiedId] = nil
                        end
                    end
                end
            end
        end)
        if not ok then
            Library:Notify("Error in [AutoPlace]: " .. tostring(err), 8)
        end
        task.wait()
    end
end
local function FuncAutoCollect()
    while Toggles.AutoCollect.Value do
        local ok, err = pcall(function()
            local plot = GetPlot()
            if not plot then
                task.wait(2)
                return
            end
            local slots = plot:FindFirstChild("Slots")
            if not slots then
                task.wait(2)
                return
            end
            local buttons = plot:FindFirstChild("Buttons")
            for _, slotPart in ipairs(slots:GetChildren()) do
                if not Toggles.AutoCollect.Value then
                    break
                end
                if slotPart:IsA("BasePart") then
                    local num = SlotNumber(slotPart)
                    local placedPart = PlacedPart(slotPart)
                    if num and placedPart then
                        local coins = ParseNumber(placedPart:GetAttribute("Coins")) or 0
                        local minCollect = tonumber(Options.CollectThreshold.Value) or 0
                        if coins ~= 0 and coins >= minCollect then
                            local char = Plr.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            if not hrp then
                                break
                            end
                            local button = buttons and buttons:FindFirstChild(slotPart.Name)
                            local target = slotPart
                            if button and button:IsA("BasePart") then
                                target = button
                            end
                            local destCFrame = target.CFrame * CFrame.new(0, 3, 0)
                            if (hrp.Position - destCFrame.Position).Magnitude > 20 then
                                hrp.CFrame = destCFrame
                                task.wait(0.12)
                            end
                            Fire("B_Collect", num)
                            task.wait()
                        end
                    end
                end
            end
        end)
        if not ok then
            Library:Notify("Error in [AutoCollect]: " .. tostring(err), 8)
            warn("autocollect error", tostring(err))
        end
        task.wait(1)
    end
end
local function FuncAutoUpgradeUmas()
    while Toggles.AutoUpgradeUmas.Value do
        local ok, err = pcall(function()
            local entities = Modules.EntitiesData
            local plot = GetPlot()
            if not (entities and plot) then
                task.wait(2)
                return
            end
            local slots = plot:FindFirstChild("Slots")
            if not slots then
                task.wait(2)
                return
            end
            local levelCap = math.min(Options.MaxUpgradeLevel.Value, entities.MAX_LEVEL or 75)
            local candidates = {}
            for _, slotPart in ipairs(slots:GetChildren()) do
                if slotPart:IsA("BasePart") then
                    local num = SlotNumber(slotPart)
                    local placedPart = PlacedPart(slotPart)
                    if num and placedPart then
                        local id = placedPart:GetAttribute("ID")
                        local level = tonumber(placedPart:GetAttribute("Level")) or 1
                        if id and level < levelCap then
                            local mutation = placedPart:GetAttribute("Mutation")
                            local costOk, cost = pcall(entities.GetCostForUpgrade, id, level, mutation)
                            if costOk then
                                cost = ParseNumber(cost)
                                if cost then
                                    table.insert(candidates, { SlotPart = slotPart, Num = num, Cost = cost })
                                end
                            end
                        end
                    end
                end
            end
            table.sort(candidates, function(a, b)
                return a.Cost < b.Cost
            end)
            local balance = GetBalance()
            if not balance then
                warn("ClientBalanceService.Balance not readable")
                task.wait(3)
                return
            end
            local bought = 0
            for _, candidate in ipairs(candidates) do
                if bought >= 2 or not Toggles.AutoUpgradeUmas.Value then
                    break
                end
                if candidate.Cost <= balance then
                    local char = Plr.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then
                        break
                    end
                    if (hrp.Position - candidate.SlotPart.Position).Magnitude > 15 then
                        hrp.CFrame = candidate.SlotPart.CFrame * CFrame.new(0, 4, 0)
                        task.wait(0.12)
                    end
                    Fire("B_Upgrade", candidate.Num)
                    bought = bought + 1
                    task.wait()
                end
            end
        end)
        if not ok then
            Library:Notify("Error in [AutoUpgradeUmas]: " .. tostring(err), 8)
            warn("autoupgrade error", tostring(err))
        end
        task.wait()
    end
end
local function FuncAutoSpeedUp()
    while Toggles.AutoSpeedUp.Value do
        local ok, err = pcall(function()
            local speedData = Modules.SpeedData
            if not speedData then
                task.wait(3)
                return
            end
            local speedService = Modules.SpeedServiceClient
            local level = speedService and tonumber(speedService.Level)
            local balance = GetBalance()
            if not (level and balance) then
                warn("SpeedServiceClient.Level or ClientBalanceService.Balance not readable")
                task.wait(3)
                return
            end
            local count, sum = 0, 0
            while count < 500 do
                local cost = ParseNumber(speedData:GetCostForLevel(level + count + 1)) or math.huge
                if sum + cost > balance then
                    break
                end
                sum = sum + cost
                count = count + 1
            end
            if count > 0 then
                Fire("SPEED_UPGRADE", count)
                task.wait(0.5)
            end
        end)
        if not ok then
            Library:Notify("Error in [AutoSpeedUp]: " .. tostring(err), 8)
            warn("autospeedup error", tostring(err))
        end
        task.wait(2)
    end
end
local function FuncAutoBonus()
    while Toggles.AutoBonus.Value do
        local ok, err = pcall(function()
            local playerGui = Plr:FindFirstChild("PlayerGui")
            local kickUpgrades = playerGui and playerGui:FindFirstChild("KickUpgrades")
            if not kickUpgrades then
                warn("PlayerGui.KickUpgrades not found")
                task.wait(2)
                return
            end
            for _, child in ipairs(kickUpgrades:GetChildren()) do
                if child.Name == "Bonus" and child:IsA("GuiButton") and child.Visible then
                    warn("clicking visible Bonus button")
                    gsc(child)
                    task.wait(0.2)
                end
            end
        end)
        if not ok then
            Library:Notify("Error in [AutoBonus]: " .. tostring(err), 8)
            warn("autobonus error", tostring(err))
        end
        task.wait(0.5)
    end
end
local function FuncAutoRebirth()
    while Toggles.AutoRebirth.Value do
        local ok, err = pcall(function()
            local rebirthData = Modules.RebirthData
            if not rebirthData then
                warn("RebirthData module not loaded yet")
                task.wait(3)
                return
            end
            local stats = Plr:FindFirstChild("leaderstats")
            local rebirthStat = stats and stats:FindFirstChild("Rebirths")
            if not rebirthStat then
                warn("leaderstats.Rebirths not found")
                task.wait(3)
                return
            end
            local kickService = Modules.KickServiceClient
            local kickLevel = kickService and tonumber(kickService.Level)
            if not kickLevel then
                warn("KickServiceClient.Level not readable")
                task.wait(3)
                return
            end
            local maxR = tonumber(rebirthData.MAX_REBIRTH) or 10
            if rebirthStat.Value < maxR then
                local req = ParseNumber(rebirthData:GetKickRequirement(rebirthStat.Value + 1)) or math.huge
                warn("tick, Rebirth=", tostring(rebirthStat.Value), "KickLevel=", tostring(kickLevel), "req=", tostring(req))
                if kickLevel >= req then
                    warn("requesting rebirth")
                    Fire("RebirthRequest")
                    task.wait(2)
                end
            else
                warn("max rebirth reached")
            end
        end)
        if not ok then
            Library:Notify("Error in [AutoRebirth]: " .. tostring(err), 8)
            warn("autorebirth error", tostring(err))
        end
        task.wait(2)
    end
end
local function FuncAutoSlots()
    while Toggles.AutoSlots.Value do
        local ok, err = pcall(function()
            local slotData = Modules.SlotUpgradesData
            if not slotData then
                task.wait(3)
                return
            end
            local slotsService = Modules.BaseUpgradesServiceClient
            local addedSlots = slotsService and tonumber(slotsService.AddedSlots)
            local balance = GetBalance()
            if not (addedSlots and balance) then
                warn("BaseUpgradesServiceClient.AddedSlots or ClientBalanceService.Balance not readable")
                task.wait(3)
                return
            end
            if addedSlots < 20 then
                local price = ParseNumber(slotData:GetPrice(addedSlots + 1))
                if price and price <= balance then
                    Fire("bs_upgrade")
                    task.wait(1)
                end
            end
        end)
        if not ok then
            Library:Notify("Error in [AutoSlots]: " .. tostring(err), 8)
            warn("autoslots error", tostring(err))
        end
        task.wait(1)
    end
end
local function FuncAutoBuyWeight()
    while Toggles.AutoBuyWeight.Value do
        local ok, err = pcall(function()
            local weights = Modules.WeightsData
            if not (weights and weights.Weights) then
                warn("WeightsData module not loaded yet")
                task.wait(3)
                return
            end
            local weightService = Modules.WeightServiceClient
            local balance = GetBalance()
            if not (weightService and type(weightService.Equipped) == "string" and type(weightService.Owned) == "table" and balance) then
                warn("WeightServiceClient.Equipped/Owned or ClientBalanceService.Balance not readable")
                task.wait(3)
                return
            end
            local weightEquipped = weightService.Equipped
            local weightOwned = weightService.Owned
            warn("tick, Balance=", tostring(balance), "Equipped=", tostring(weightEquipped), "Owned=", table.concat(weightOwned, ","))
            local entries = {}
            for name, info in pairs(weights.Weights) do
                table.insert(entries, {
                    Name = name,
                    PPS = tonumber(info.PPS) or 0,
                    Cost = ParseNumber(info.Cost) or math.huge,
                })
            end
            table.sort(entries, function(a, b)
                return a.Cost < b.Cost
            end)
            for _, entry in ipairs(entries) do
                if not table.find(weightOwned, entry.Name) then
                    warn("next unowned =", entry.Name, "cost=", tostring(entry.Cost), "balance=", tostring(balance))
                    if entry.Cost <= balance then
                        local shops = workspace:FindFirstChild("Shops")
                        local weightShop = shops and shops:FindFirstChild("WeightShop")
                        local touchPart = weightShop and weightShop:FindFirstChild("TouchPart")
                        if touchPart then
                            warn("teleporting to WeightShop TouchPart")
                            TPTo(touchPart, Vector3.new(0, 3, 0))
                            task.wait(0.2)
                        else
                            warn("WeightShop TouchPart not found, buying without teleport")
                        end
                        warn("buying", entry.Name)
                        Fire("Shop_Buy", "WeightShop", entry.Name)
                        task.wait(1)
                    else
                        warn("cannot afford", entry.Name, "yet")
                    end
                    break
                end
            end
            local current = weights.Weights[weightEquipped]
            local bestPPS = current and tonumber(current.PPS) or -1
            local bestName = nil
            for _, name in ipairs(weightOwned) do
                local info = weights.Weights[name]
                if info then
                    local pps = tonumber(info.PPS) or 0
                    if pps > bestPPS then
                        bestPPS = pps
                        bestName = name
                    end
                end
            end
            if bestName then
                warn("equipping", bestName, "(better than", tostring(weightEquipped), ")")
                Fire("WeightEquip", bestName)
                task.wait(1)
            end
        end)
        if not ok then
            Library:Notify("Error in [AutoBuyWeight]: " .. tostring(err), 8)
            warn("autobuyweight error", tostring(err))
        end
        task.wait(2)
    end
end
local function Connect(name, handler)
    SafeConnect("" .. name, function()
        return Network.OnClientEvent(name)
    end, handler)
end
Toggles.AutoEscape:OnChanged(function(state)
    Thread("AutoEscape", FuncAutoEscape, state)
end)
Toggles.AutoKick:OnChanged(function(state)
    Thread("AutoKick", FuncAutoKick, state)
end)
Toggles.AutoPlace:OnChanged(function(state)
    Thread("AutoPlace", FuncAutoPlace, state)
end)
Toggles.AutoCollect:OnChanged(function(state)
    Thread("AutoCollect", FuncAutoCollect, state)
end)
Toggles.AutoUpgradeUmas:OnChanged(function(state)
    Thread("AutoUpgradeUmas", FuncAutoUpgradeUmas, state)
end)
Toggles.AutoBonus:OnChanged(function(state)
    Thread("AutoBonus", FuncAutoBonus, state)
end)
Toggles.AutoSpeedUp:OnChanged(function(state)
    Thread("AutoSpeedUp", FuncAutoSpeedUp, state)
end)
Toggles.AutoRebirth:OnChanged(function(state)
    Thread("AutoRebirth", FuncAutoRebirth, state)
end)
Toggles.AutoSlots:OnChanged(function(state)
    Thread("AutoSlots", FuncAutoSlots, state)
end)
Toggles.AutoBuyWeight:OnChanged(function(state)
    Thread("AutoBuyWeight", FuncAutoBuyWeight, state)
end)
if Toggles.AutoEscape.Value then
    Thread("AutoEscape", FuncAutoEscape, true)
end
local net = GetSafeModule(RS.Shared.Packages, "Network")
if not net or type(net.FireServer) ~= "function" or type(net.OnClientEvent) ~= "function" then
    Library:Notify("Network module failed to load", 6)
    warn("network module failed")
    return
end
Network = net
Connect("KickEvent", function()
    KU.InGame = true
end)
Connect("KickEventEnded", function(result)
    KU.InGame = false
    if result == true then
        KU.Session.Success = KU.Session.Success + 1
    else
        KU.Session.Fail = KU.Session.Fail + 1
    end
end)
Connect("PlotAdded", function(plotName)
    if type(plotName) == "string" then
        local plots = workspace:FindFirstChild("Plots")
        local model = plots and plots:FindFirstChild(plotName)
        if model then
            KU.Plot = model
        end
    end
end)
local antiAFKConn = nil
local function RunAntiAFK()
    if antiAFKConn then antiAFKConn:Enable() return end
    local GC = getconnections or get_signal_cons
    if GC then
        local conns = GC(Players.LocalPlayer.Idled)
        local target = conns and conns[1]
        if target and target.Disable then
            target:Disable()
            antiAFKConn = target
            return
        end
        for _, c in pairs(conns or {}) do
            if c.Disable then
                c:Disable()
                antiAFKConn = c
                return
            elseif c.Disconnect then
                c:Disconnect()
                return
            end
        end
    end
    Players.LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
Toggles.AntiAFK:OnChanged(function(state)
    if state then
        RunAntiAFK()
    elseif antiAFKConn and antiAFKConn.Enable then
        antiAFKConn:Enable()
    end
end)
if Toggles.AntiAFK.Value then RunAntiAFK() end
local MenuGroup = Tabs.Config:AddLeftGroupbox("Menu")
MenuGroup:AddToggle("AutoShowUI", {
    Text = "Auto Show UI",
    Default = true,
})
MenuGroup:AddToggle("KeybindMenuOpen", {
        Default = Library.KeybindFrame.Visible,
        Text = "Open Keybind Menu",
        Callback = function(value)
                Library.KeybindFrame.Visible = value
        end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
        Text = "Custom Cursor",
        Default = false,
        Callback = function(Value)
                Library.ShowCustomCursor = Value
        end,
})
MenuGroup:AddDropdown("NotificationSide", {
        Values = { "Left", "Right" },
        Default = "Right",
        Text = "Notification Side",
        Callback = function(Value)
                Library:SetNotifySide(Value)
        end,
})
MenuGroup:AddDropdown("DPIDropdown", {
        Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
        Default = "100%",
        Text = "DPI Scale",
        Callback = function(Value)
                Value = Value:gsub("%%", "")
                local DPI = tonumber(Value)
                Library:SetDPIScale(DPI)
        end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
        :AddKeyPicker("MenuKeybind", { Default = "U", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function()
    getgenv().yurikiskis = false
    Shared.Farm = false
    if antiAFKConn and antiAFKConn.Enable then pcall(function() antiAFKConn:Enable() end) end
    if Support.FPS then pcall(function() setfpscap(2000) end) end
    Cleanup(Connections)
    Cleanup(Flags)
        Library:Unload()
end)
Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:SetFolder("Yuri")
SaveManager:SetFolder("Yuri/KickUma")
SaveManager:BuildConfigSection(Tabs.Config)
ThemeManager:ApplyToTab(Tabs.Config)
task.defer(function()
    SaveManager:LoadAutoloadConfig()
end)
SaveManager:SetLoadingOrder(true, {"Dropdown", "Slider", "ColorPicker", "KeyPicker", "Input", "Toggle"})
if UIS.TouchEnabled and not UIS.KeyboardEnabled then
    Library:SetDPIScale(75)
elseif UIS.KeyboardEnabled then
    Library:SetDPIScale(100)
end
Library:Notify("Script loaded.", 2)
Library:Notify("Yuri!", 5)
end)
if not eh_success then
    Library:Notify("ERROR: " .. tostring(err), 4)
    warn("ERROR: " .. tostring(err))
end
