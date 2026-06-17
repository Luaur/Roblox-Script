--[[
    Red Glass UI Library v7.1
    Copyright (c) 2025 Luaur
    GitHub: https://github.com/Luaur
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    DISCLAIMER:
    This library is intended for educational and legitimate purposes only.
    The author does not condone or encourage the use of this library for
    exploiting or cheating in Roblox games. Any misuse of this software
    is solely the responsibility of the user.
    By using this library, you agree that you are responsible for complying
    with the terms of service of any platform on which it is used.
--]]

local RedGlass = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ZINDEX = {
    BASE = 1,
    MAIN = 2,
    OVERLAY = 100,
    NOTIFICATION = 200,
    TOOLTIP = 150,
    FLY_BUTTONS = 50,
}

local TWEEN = {
    FAST = 0.15,
    NORMAL = 0.25,
    SLOW = 0.35,
}

local Theme = {
    Primary = Color3.fromRGB(220, 40, 40),
    PrimaryDark = Color3.fromRGB(180, 30, 30),
    PrimaryLight = Color3.fromRGB(255, 80, 80),
    Glass = Color3.fromRGB(255, 255, 255),
    GlassRed = Color3.fromRGB(255, 60, 60),
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(180, 180, 180),
    Background = Color3.fromRGB(20, 20, 20),
    SliderTrack = Color3.fromRGB(60, 60, 60),
    ToggleOff = Color3.fromRGB(80, 80, 80),
    ToggleOn = Color3.fromRGB(255, 70, 70),
    DropdownOption = Color3.fromRGB(50, 15, 15),
    OverlayBorder = Color3.fromRGB(255, 100, 100),
}

local function MakeDraggable(frame, dragHandle, onDragStart, onDragEnd)
    local dragging, startPos, startMouse
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startMouse = input.Position
            startPos = frame.Position
            if onDragStart then onDragStart() end
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startMouse
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                       startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging and onDragEnd then onDragEnd() end
            dragging = false
        end
    end)
end

local function CreateTween(instance, props, duration, easing, dir)
    local tweenInfo = TweenInfo.new(duration or TWEEN.NORMAL, easing or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, props)
    tween:Play()
    return tween
end

local function SmoothScroll(scrollingFrame, targetY, speed)
    speed = speed or 0.3
    local startY = scrollingFrame.CanvasPosition.Y
    local startTime = tick()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        local alpha = math.min(elapsed / speed, 1)
        local eased = 1 - (1 - alpha) * (1 - alpha)
        local currentY = startY + (targetY - startY) * eased
        scrollingFrame.CanvasPosition = Vector2.new(0, currentY)
        if alpha >= 1 then
            connection:Disconnect()
        end
    end)
end

local function CreateGradient(parent, rotation, color1, color2)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1 or Theme.PrimaryDark),
        ColorSequenceKeypoint.new(1, color2 or Theme.PrimaryLight),
    })
    grad.Rotation = rotation or 135
    grad.Parent = parent
    return grad
end

local Fonts = {
    Main = Enum.Font.GothamBold,
    Secondary = Enum.Font.GothamSemibold,
    Normal = Enum.Font.Gotham,
    Mono = Enum.Font.RobotoMono,
}

local function detectAntiCheat()
    local antiCheats = {}
    
    local function addDetection(name, confidence)
        table.insert(antiCheats, {name = name, confidence = confidence})
    end
    
    pcall(function()
        if game:GetService("ScriptContext") then
            addDetection("ScriptContext Active", 90)
        end
    end)
    
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ModuleScript") and (obj.Name:lower():find("anticheat") or obj.Name:lower():find("ac")) then
                addDetection("AntiCheat ModuleScript", 70)
                break
            end
        end
    end)
    
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("ScreenGui") and (obj.Name:lower():find("anticheat") or obj.Name:lower():find("ac")) then
                addDetection("AntiCheat GUI", 80)
                break
            end
        end
    end)
    
    pcall(function()
        if workspace:FindFirstChild("AntiCheat") or workspace:FindFirstChild("AC") then
            addDetection("Workspace AC Object", 75)
        end
    end)
    
    pcall(function()
        for _, event in ipairs(ReplicatedStorage:GetDescendants()) do
            if event:IsA("RemoteEvent") and (event.Name:lower():find("ban") or event.Name:lower():find("kick")) then
                addDetection("Ban/Kick RemoteEvent", 85)
                break
            end
        end
    end)
    
    pcall(function()
        for _, event in ipairs(ReplicatedStorage:GetDescendants()) do
            if event:IsA("RemoteFunction") and (event.Name:lower():find("verify") or event.Name:lower():find("check")) then
                addDetection("Verification RemoteFunction", 80)
                break
            end
        end
    end)
    
    return {
        Detected = #antiCheats > 0,
        List = antiCheats,
        RiskLevel = #antiCheats > 2 and "High" or (#antiCheats > 0 and "Medium" or "Low")
    }
end

local function detectGamepasses()
    local gamepasses = {}
    
    pcall(function()
        local pages = MarketplaceService:GetDeveloperProductsAsync():GetCurrentPage()
        for _, product in ipairs(pages) do
            local owned = false
            pcall(function()
                owned = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, product.ProductId)
            end)
            table.insert(gamepasses, {
                Id = product.ProductId,
                Name = product.Name,
                Price = product.PriceInRobux or 0,
                Owned = owned
            })
        end
    end)
    
    if #gamepasses == 0 then
        pcall(function()
            local info = MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Asset)
            if info and info.AssetTypeId == 9 then
                local gamepassData = MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.GamePass)
                if gamepassData then
                    local owned = false
                    pcall(function()
                        owned = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, gamepassData.ProductId)
                    end)
                    table.insert(gamepasses, {
                        Id = gamepassData.ProductId,
                        Name = gamepassData.Name,
                        Price = gamepassData.PriceInRobux or 0,
                        Owned = owned
                    })
                end
            end
        end)
    end
    
    return gamepasses
end

local function attemptFreeGamepass(gamepassId, gamepassName)
    local results = {
        Success = false,
        Methods = {},
        GamepassName = gamepassName
    }
    
    local function tryMethod(methodName, func)
        local success, err = pcall(func)
        if success then
            table.insert(results.Methods, methodName)
            results.Success = true
            return true
        end
        return false
    end
    
    local function verifyOwnership()
        local owned = false
        pcall(function()
            owned = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, gamepassId)
        end)
        return owned
    end
    
    tryMethod("RemoteEvent Purchase", function()
        local purchaseEvents = {}
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") and (obj.Name:lower():find("purchase") or obj.Name:lower():find("buy") or obj.Name:lower():find("gamepass")) then
                table.insert(purchaseEvents, obj)
            end
        end
        for _, event in ipairs(purchaseEvents) do
            local args = {
                [1] = gamepassId,
                [2] = Player.UserId
            }
            event:FireServer(unpack(args))
        end
        task.wait(0.3)
        if verifyOwnership() then return end
    end)
    
    tryMethod("RemoteFunction Purchase", function()
        local purchaseFunctions = {}
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteFunction") and (obj.Name:lower():find("purchase") or obj.Name:lower():find("buy") or obj.Name:lower():find("gamepass")) then
                table.insert(purchaseFunctions, obj)
            end
        end
        for _, func in ipairs(purchaseFunctions) do
            func:InvokeServer(gamepassId, Player.UserId)
        end
        task.wait(0.3)
        if verifyOwnership() then return end
    end)
    
    tryMethod("Prompt Purchase Method", function()
        MarketplaceService:PromptGamePassPurchase(Player, gamepassId)
        task.wait(1)
        local prompt = Player:WaitForChild("PlayerGui"):FindFirstChild("PurchasePrompt")
        if prompt then prompt:Destroy() end
        if verifyOwnership() then return end
    end)
    
    tryMethod("HTTP Request Method", function()
        local url = "https://economy.roblox.com/v1/purchases/products/" .. gamepassId
        local response = request({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                expectedPrice = 0,
                expectedCurrency = 1
            })
        })
        if response and response.Success then
            if verifyOwnership() then return end
        end
    end)
    
    tryMethod("ProcessReceipt Bypass", function()
        local processReceipt = ReplicatedStorage:FindFirstChild("ProcessReceipt")
        if processReceipt and processReceipt:IsA("RemoteFunction") then
            processReceipt:InvokeServer({
                PlayerId = Player.UserId,
                ProductId = gamepassId,
                PurchaseId = "free_" .. tostring(math.random(100000, 999999))
            })
        end
        task.wait(0.3)
        if verifyOwnership() then return end
    end)
    
    tryMethod("Purchase Verification Bypass", function()
        local verifyEvents = {}
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") and (obj.Name:lower():find("verify") or obj.Name:lower():find("validate")) then
                table.insert(verifyEvents, obj)
            end
        end
        for _, event in ipairs(verifyEvents) do
            event:FireServer(gamepassId, true)
        end
        task.wait(0.3)
        if verifyOwnership() then return end
    end)
    
    tryMethod("Gamepass Grant Method", function()
        local grantEvents = {}
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") and (obj.Name:lower():find("grant") or obj.Name:lower():find("give") or obj.Name:lower():find("add")) then
                table.insert(grantEvents, obj)
            end
        end
        for _, event in ipairs(grantEvents) do
            event:FireServer(Player.UserId, gamepassId)
        end
        task.wait(0.3)
        if verifyOwnership() then return end
    end)
    
    tryMethod("Client-Side Ownership Override", function()
        local playerGui = Player:WaitForChild("PlayerGui")
        local gamepassFrame = playerGui:FindFirstChild("GamepassFrame") or playerGui:FindFirstChild("Shop")
        if gamepassFrame then
            for _, button in ipairs(gamepassFrame:GetDescendants()) do
                if button:IsA("TextButton") and button.Name:lower():find("buy") then
                    local ownedLabel = Instance.new("TextLabel")
                    ownedLabel.Text = "Owned"
                    ownedLabel.Parent = button
                    button.Text = "Owned"
                end
            end
            if verifyOwnership() then return end
        end
    end)
    
    tryMethod("DataStore Manipulation", function()
        local dataEvents = {}
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") and (obj.Name:lower():find("data") or obj.Name:lower():find("save") or obj.Name:lower():find("load")) then
                table.insert(dataEvents, obj)
            end
        end
        for _, event in ipairs(dataEvents) do
            event:FireServer({
                GamepassId = gamepassId,
                Owned = true
            })
        end
        task.wait(0.3)
        if verifyOwnership() then return end
    end)
    
    return results
end

local mainGui = nil
local function GetMainGui()
    if not mainGui then
        mainGui = Instance.new("ScreenGui")
        mainGui.Name = "R" .. tostring(math.random(10000, 99999))
        mainGui.ResetOnSpawn = false
        mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        mainGui.DisplayOrder = 999
        mainGui.IgnoreGuiInset = true
        
        if syn and syn.protect_gui then
            syn.protect_gui(mainGui)
            mainGui.Parent = CoreGui
        elseif gethui then
            mainGui.Parent = gethui()
        else
            mainGui.Parent = CoreGui
        end
    end
    return mainGui
end

function RedGlass:CreateWindow(config)
    config = config or {}
    local title = config.Title or "Red Glass UI"
    local size = config.Size or UDim2.new(0, math.min(Camera.ViewportSize.X * 0.5, 600), 0, math.min(Camera.ViewportSize.Y * 0.7, 450))
    local position = config.Position or UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
    local scale = config.Scale or 1

    local gui = GetMainGui()
    local connections = {}

    local function connectEvent(event, func)
        local conn = event:Connect(func)
        table.insert(connections, conn)
        return conn
    end

    local themedElements = {}
    local function registerThemedElement(element, property, colorKey)
        table.insert(themedElements, {element = element, property = property, colorKey = colorKey})
    end

    local components = {}
    local function registerComponent(id, compType, getFn, setFn)
        table.insert(components, { id = id, type = compType, get = getFn, set = setFn })
    end

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "M" .. tostring(math.random(10000, 99999))
    MainFrame.Size = size
    MainFrame.Position = position
    MainFrame.BackgroundColor3 = Theme.Glass
    MainFrame.BackgroundTransparency = 0.92
    MainFrame.BorderSizePixel = 0
    MainFrame.ZIndex = ZINDEX.MAIN
    MainFrame.Parent = gui
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = scale
    uiScale.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = MainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.PrimaryLight
    stroke.Thickness = 1.2
    stroke.Transparency = 0.5
    stroke.ZIndex = ZINDEX.MAIN
    stroke.Parent = MainFrame

    local glassGrad = CreateGradient(MainFrame, 135, Theme.Glass, Theme.GlassRed)
    glassGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.5, 0.6),
        NumberSequenceKeypoint.new(1, 0.8),
    })

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 36)
    TitleBar.BackgroundTransparency = 1
    TitleBar.ZIndex = ZINDEX.MAIN
    TitleBar.Parent = MainFrame

    local titleBg = Instance.new("Frame")
    titleBg.Size = UDim2.fromScale(1, 1)
    titleBg.BackgroundColor3 = Theme.Primary
    titleBg.BackgroundTransparency = 0.85
    titleBg.BorderSizePixel = 0
    titleBg.ZIndex = ZINDEX.MAIN
    titleBg.Parent = TitleBar
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBg

    local titleGrad = CreateGradient(titleBg, 90, Theme.Primary, Theme.PrimaryDark)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = title
    TitleLabel.Size = UDim2.new(1, -70, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.Font = Fonts.Main
    TitleLabel.TextSize = 15
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = ZINDEX.MAIN
    TitleLabel.Parent = TitleBar

    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Size = UDim2.new(0, 28, 0, 28)
    MinimizeButton.Position = UDim2.new(1, -66, 0, 4)
    MinimizeButton.BackgroundColor3 = Theme.Primary
    MinimizeButton.BackgroundTransparency = 0.7
    MinimizeButton.Text = "-"
    MinimizeButton.TextColor3 = Theme.Text
    MinimizeButton.Font = Fonts.Main
    MinimizeButton.TextSize = 18
    MinimizeButton.ZIndex = ZINDEX.MAIN
    MinimizeButton.Parent = TitleBar
    Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 6)

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 28, 0, 28)
    CloseButton.Position = UDim2.new(1, -34, 0, 4)
    CloseButton.BackgroundColor3 = Theme.Primary
    CloseButton.BackgroundTransparency = 0.7
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Theme.Text
    CloseButton.Font = Fonts.Main
    CloseButton.TextSize = 14
    CloseButton.ZIndex = ZINDEX.MAIN
    CloseButton.Parent = TitleBar
    Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 6)

    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(0, 140, 1, -42)
    TabContainer.Position = UDim2.new(0, 8, 0, 38)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ZIndex = ZINDEX.MAIN
    TabContainer.Parent = MainFrame
    local TabList = Instance.new("UIListLayout")
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Padding = UDim.new(0, 6)
    TabList.Parent = TabContainer

    local ContentArea = Instance.new("Frame")
    ContentArea.Size = UDim2.new(1, -156, 1, -46)
    ContentArea.Position = UDim2.new(0, 148, 0, 40)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ZIndex = ZINDEX.MAIN
    ContentArea.Parent = MainFrame

    local ContentScroll = Instance.new("ScrollingFrame")
    ContentScroll.Size = UDim2.fromScale(1, 1)
    ContentScroll.BackgroundTransparency = 1
    ContentScroll.ScrollBarThickness = 3
    ContentScroll.ScrollBarImageColor3 = Theme.Primary
    ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentScroll.ZIndex = ZINDEX.MAIN
    ContentScroll.Parent = ContentArea
    ContentScroll.ScrollingEnabled = true
    ContentScroll.ScrollBarImageTransparency = 0.5
    
    local ContentList = Instance.new("UIListLayout")
    ContentList.SortOrder = Enum.SortOrder.LayoutOrder
    ContentList.Padding = UDim.new(0, 6)
    ContentList.Parent = ContentScroll

    local isMinimized = false
    local originalSize = size
    local originalPosition = position
    local minimizedSize = UDim2.new(size.X.Scale, size.X.Offset, 0, 36)
    local restoreConn = nil

    local function minimize()
        if isMinimized then return end
        isMinimized = true
        originalPosition = MainFrame.Position
        CreateTween(MainFrame, {Size = minimizedSize}, TWEEN.FAST)
        MinimizeButton.Text = "+"
        if restoreConn then
            restoreConn:Disconnect()
            for i, conn in ipairs(connections) do
                if conn == restoreConn then table.remove(connections, i) break end
            end
            restoreConn = nil
        end
        restoreConn = connectEvent(TitleBar.InputBegan, function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and isMinimized then
                restore()
            end
        end)
    end

    local function restore()
        if not isMinimized then return end
        isMinimized = false
        CreateTween(MainFrame, {Size = originalSize, Position = originalPosition}, TWEEN.FAST)
        MinimizeButton.Text = "-"
        if restoreConn then
            restoreConn:Disconnect()
            for i, conn in ipairs(connections) do
                if conn == restoreConn then table.remove(connections, i) break end
            end
            restoreConn = nil
        end
    end

    connectEvent(MinimizeButton.MouseButton1Click, function()
        if isMinimized then restore() else minimize() end
    end)

    local function onDragEnd()
        originalPosition = MainFrame.Position
    end
    MakeDraggable(MainFrame, TitleBar, nil, onDragEnd)

    local activeOverlays = {}
    local function registerOverlay(overlay, closeFunc)
        table.insert(activeOverlays, {overlay = overlay, close = closeFunc})
    end
    local function unregisterOverlay(overlay)
        for i, ov in ipairs(activeOverlays) do
            if ov.overlay == overlay then
                table.remove(activeOverlays, i)
                break
            end
        end
    end
    local function closeAllOverlays()
        for _, ov in ipairs(activeOverlays) do
            if ov.overlay and ov.overlay.Parent then
                ov.close()
            end
        end
        activeOverlays = {}
    end
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            closeAllOverlays()
        end
    end)

    local flyLoop, noclipLoop, skywalkLoop
    local flySpeed = 50
    local upCount, downCount = 0, 0
    local flyEnabled, noclipEnabled, skywalkEnabled = false, false, false
    local flyButtons = nil
    local walkSpeedVal = 50
    local infiniteJumpEnabled = false
    local jumpConnection = nil

    local function removeMobileFlyButtons()
        if flyButtons then flyButtons:Destroy(); flyButtons = nil end
    end

    local function createMobileFlyButtons()
        if not UserInputService.TouchEnabled then return end
        removeMobileFlyButtons()
        flyButtons = Instance.new("Frame")
        flyButtons.Size = UDim2.new(0, 120, 0, 60)
        flyButtons.Position = UDim2.new(1, -130, 1, -70)
        flyButtons.BackgroundTransparency = 1
        flyButtons.ZIndex = ZINDEX.FLY_BUTTONS
        flyButtons.Parent = gui

        local upBtn = Instance.new("TextButton")
        upBtn.Size = UDim2.new(0, 50, 0, 50)
        upBtn.Position = UDim2.new(0, 35, 0, 0)
        upBtn.Text = "^"
        upBtn.Font = Fonts.Main
        upBtn.TextSize = 20
        upBtn.BackgroundColor3 = Theme.Primary
        upBtn.BackgroundTransparency = 0.6
        upBtn.ZIndex = ZINDEX.FLY_BUTTONS
        upBtn.Parent = flyButtons
        Instance.new("UICorner", upBtn).CornerRadius = UDim.new(1, 0)

        local downBtn = Instance.new("TextButton")
        downBtn.Size = UDim2.new(0, 50, 0, 50)
        downBtn.Position = UDim2.new(0, 35, 0, 10)
        downBtn.Text = "v"
        downBtn.Font = Fonts.Main
        downBtn.TextSize = 20
        downBtn.BackgroundColor3 = Theme.Primary
        downBtn.BackgroundTransparency = 0.6
        downBtn.ZIndex = ZINDEX.FLY_BUTTONS
        downBtn.Parent = flyButtons
        Instance.new("UICorner", downBtn).CornerRadius = UDim.new(1, 0)

        connectEvent(upBtn.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                upCount += 1
            end
        end)
        connectEvent(upBtn.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                upCount = math.max(0, upCount - 1)
            end
        end)
        connectEvent(downBtn.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                downCount += 1
            end
        end)
        connectEvent(downBtn.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                downCount = math.max(0, downCount - 1)
            end
        end)
    end

    local function startFly()
        flyEnabled = true
        if flyLoop then flyLoop:Disconnect() end
        flyLoop = RunService.Heartbeat:Connect(function()
            local char = Player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if not root or not hum or hum.Health <= 0 then return end
            local vel = hum.MoveDirection * flySpeed
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) or upCount > 0 then
                vel += Vector3.new(0, flySpeed, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or downCount > 0 then
                vel -= Vector3.new(0, flySpeed, 0)
            end
            root.Velocity = vel
            hum.PlatformStand = true
        end)
        if UserInputService.TouchEnabled then
            createMobileFlyButtons()
        end
    end

    local function stopFly()
        flyEnabled = false
        if flyLoop then flyLoop:Disconnect(); flyLoop = nil end
        removeMobileFlyButtons()
        upCount = 0
        downCount = 0
        local char = Player.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = false end
        end
    end

    local function startNoclip()
        noclipEnabled = true
        if noclipLoop then noclipLoop:Disconnect() end
        noclipLoop = RunService.Stepped:Connect(function()
            if not noclipEnabled then return end
            local char = Player.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end

    local function stopNoclip()
        noclipEnabled = false
        if noclipLoop then noclipLoop:Disconnect(); noclipLoop = nil end
        local char = Player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end

    local function startSkywalk()
        skywalkEnabled = true
        if skywalkLoop then skywalkLoop:Disconnect() end
        skywalkLoop = RunService.Heartbeat:Connect(function()
            local char = Player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if not root or not hum or hum.Health <= 0 then return end
            root.Velocity = Vector3.new(0, 30, 0)
            hum.PlatformStand = true
        end)
    end

    local function stopSkywalk()
        skywalkEnabled = false
        if skywalkLoop then skywalkLoop:Disconnect(); skywalkLoop = nil end
        local char = Player.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = false end
        end
    end

    connectEvent(Player.CharacterAdded, function(char)
        if flyEnabled then
            stopFly()
            startFly()
        end
        if noclipEnabled then
            stopNoclip()
            startNoclip()
        end
        if skywalkEnabled then
            stopSkywalk()
            startSkywalk()
        end
        if walkSpeedVal then
            local hum = char:WaitForChild("Humanoid")
            hum.WalkSpeed = walkSpeedVal
        end
    end)

    local function destroyUI()
        if flyLoop then flyLoop:Disconnect(); flyLoop = nil end
        if noclipLoop then noclipLoop:Disconnect(); noclipLoop = nil end
        if skywalkLoop then skywalkLoop:Disconnect(); skywalkLoop = nil end
        removeMobileFlyButtons()
        for _, conn in ipairs(connections) do conn:Disconnect() end
        connections = {}
        closeAllOverlays()
        MainFrame:Destroy()
        if mainGui and #mainGui:GetChildren() == 0 then
            mainGui:Destroy()
            mainGui = nil
        end
    end
    connectEvent(CloseButton.MouseButton1Click, destroyUI)

    local Window = {}

    function Window:Notification(data)
        local text = data.Text or data
        local duration = data.Duration or 2.5
        local notifType = data.Type or "info"
        local colorMap = {
            info = Color3.fromRGB(70, 130, 220),
            success = Color3.fromRGB(60, 200, 80),
            warning = Color3.fromRGB(255, 170, 40),
            error = Color3.fromRGB(255, 70, 70),
        }
        local bgColor = colorMap[notifType] or colorMap.info

        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 250, 0, 0)
        notif.Position = UDim2.new(0.5, -125, 1, -10)
        notif.BackgroundColor3 = bgColor
        notif.BackgroundTransparency = 0.25
        notif.BorderSizePixel = 0
        notif.ZIndex = ZINDEX.NOTIFICATION
        notif.ClipsDescendants = true
        notif.Parent = gui

        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)

        CreateGradient(notif, 90, bgColor, bgColor:Lerp(Color3.new(0,0,0), 0.3))

        local notifLabel = Instance.new("TextLabel")
        notifLabel.Text = text
        notifLabel.Size = UDim2.fromScale(1, 1)
        notifLabel.BackgroundTransparency = 1
        notifLabel.TextColor3 = Theme.Text
        notifLabel.Font = Fonts.Secondary
        notifLabel.TextSize = 14
        notifLabel.ZIndex = ZINDEX.NOTIFICATION
        notifLabel.Parent = notif

        CreateTween(notif, {Size = UDim2.new(0, 250, 0, 42), Position = UDim2.new(0.5, -125, 1, -52)}, TWEEN.FAST)
        task.delay(duration, function()
            CreateTween(notif, {Size = UDim2.new(0, 250, 0, 0), Position = UDim2.new(0.5, -125, 1, -10)}, TWEEN.FAST)
            task.wait(TWEEN.FAST)
            notif:Destroy()
        end)
    end

    function Window:AddTooltip(element, text)
        local tooltip
        connectEvent(element.MouseEnter, function()
            if tooltip then tooltip:Destroy() end
            tooltip = Instance.new("Frame")
            tooltip.Size = UDim2.new(0, 200, 0, 26)
            tooltip.Position = UDim2.new(0, element.AbsolutePosition.X + element.AbsoluteSize.X + 5, 0, element.AbsolutePosition.Y)
            tooltip.BackgroundColor3 = Theme.Background
            tooltip.BackgroundTransparency = 0.2
            tooltip.BorderSizePixel = 0
            tooltip.ZIndex = ZINDEX.TOOLTIP
            tooltip.Parent = gui
            Instance.new("UICorner", tooltip).CornerRadius = UDim.new(0, 4)
            local toolLabel = Instance.new("TextLabel")
            toolLabel.Text = text
            toolLabel.Size = UDim2.fromScale(1, 1)
            toolLabel.BackgroundTransparency = 1
            toolLabel.TextColor3 = Theme.Text
            toolLabel.Font = Fonts.Normal
            toolLabel.TextSize = 13
            toolLabel.ZIndex = ZINDEX.TOOLTIP
            toolLabel.Parent = tooltip
        end)
        connectEvent(element.MouseLeave, function()
            if tooltip then tooltip:Destroy() tooltip = nil end
        end)
    end

    function Window:SetTheme(newTheme)
        for k, v in pairs(newTheme) do
            Theme[k] = v
        end
        for _, item in ipairs(themedElements) do
            local col = Theme[item.colorKey]
            if col and item.element then
                item.element[item.property] = col
            end
        end
    end

    function Window:CreateConfig()
        local cfg = {}
        for _, comp in ipairs(components) do
            local value = comp.get()
            if comp.type == "color" then
                value = { R = value.R * 255, G = value.G * 255, B = value.B * 255 }
            elseif comp.type == "keybind" then
                value = value.Name
            end
            cfg[comp.id] = { type = comp.type, value = value }
        end
        return cfg
    end

    function Window:SaveConfig(fileName)
        local config = Window:CreateConfig()
        local jsonSuccess, json = pcall(function()
            return HttpService:JSONEncode(config)
        end)
        if jsonSuccess then
            if writefile then
                writefile(fileName or "RedGlass_Config.json", json)
                Window:Notification({ Text = "Config saved to " .. (fileName or "RedGlass_Config.json"), Type = "success" })
            else
                setclipboard(json)
                Window:Notification({ Text = "Config copied to clipboard", Type = "warning" })
            end
        else
            Window:Notification({ Text = "Failed to encode config", Type = "error" })
        end
    end

    function Window:LoadConfig(input)
        local json
        if type(input) == "string" then
            local success, result = pcall(function() return readfile(input) end)
            if success then
                json = result
            else
                local clip = getclipboard and getclipboard()
                if clip and clip ~= "" then
                    json = clip
                else
                    Window:Notification({ Text = "File not found and clipboard empty", Type = "error" })
                    return
                end
            end
        else
            json = input
        end
        local success, config = pcall(function()
            return HttpService:JSONDecode(json)
        end)
        if success then
            for _, comp in ipairs(components) do
                local saved = config[comp.id]
                if saved then
                    local val = saved.value
                    if comp.type == "color" then
                        val = Color3.fromRGB(val.R, val.G, val.B)
                    elseif comp.type == "keybind" then
                        val = Enum.KeyCode[val] or Enum.KeyCode.F
                    end
                    comp.set(val)
                end
            end
            Window:Notification({ Text = "Config loaded", Type = "success" })
        else
            Window:Notification({ Text = "Invalid config data", Type = "error" })
        end
    end

    function Window:BoostFPS()
        local settings = {
            Rendering = { QualityLevel = 1, EnableFRME = false, EnableLighting = false, EnableShadows = false, EnablePostFx = false, EnableFullscreenEffects = false, EnableGPULightCulling = true },
            Material = { TerrainQuality = 1, TrussDetail = 1 },
            Physics = { EnvironmentalPhysicsThrottle = Enum.EnviromentalPhysicsThrottle.Disabled },
        }
        for category, options in pairs(settings) do
            for key, value in pairs(options) do
                pcall(function() UserSettings()[category][key] = value end)
            end
        end
        local lighting = game:GetService("Lighting")
        lighting.GlobalShadows = false
        lighting.FogEnd = 1e9
        lighting.Brightness = 1
        pcall(function() workspace:FindFirstChildOfClass("Terrain").WaterWaveSize = 0 end)
        Window:Notification({ Text = "FPS Boost activated! Low graphics mode.", Type = "success", Duration = 3 })
    end

    function Window:DetectAntiCheat()
        return detectAntiCheat()
    end

    local function createOverlay(anchorFrame, height, closeFunc)
        local absPos = anchorFrame.AbsolutePosition
        local absSize = anchorFrame.AbsoluteSize
        local overlay = Instance.new("Frame")
        overlay.Size = UDim2.new(0, absSize.X, 0, height)
        overlay.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y)
        overlay.BackgroundColor3 = Theme.DropdownOption
        overlay.BackgroundTransparency = 0.15
        overlay.BorderSizePixel = 0
        overlay.ZIndex = ZINDEX.OVERLAY
        overlay.Parent = gui
        Instance.new("UICorner", overlay).CornerRadius = UDim.new(0, 6)
        local ovStroke = Instance.new("UIStroke")
        ovStroke.Color = Theme.OverlayBorder
        ovStroke.Thickness = 1
        ovStroke.Transparency = 0.3
        ovStroke.ZIndex = ZINDEX.OVERLAY
        ovStroke.Parent = overlay
        registerOverlay(overlay, closeFunc)
        return overlay
    end

    local tabs = {}
    local currentTabPage = nil

    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"
        local tabIcon = tabConfig.Icon or ""

        local tabButton = Instance.new("TextButton")
        tabButton.Size = UDim2.new(1, 0, 0, 34)
        tabButton.BackgroundColor3 = Theme.Primary
        tabButton.BackgroundTransparency = 0.85
        tabButton.Text = tabIcon .. "  " .. tabName
        tabButton.TextColor3 = Theme.Text
        tabButton.Font = Fonts.Secondary
        tabButton.TextSize = 13
        tabButton.TextXAlignment = Enum.TextXAlignment.Left
        tabButton.ZIndex = ZINDEX.MAIN
        tabButton.Parent = TabContainer
        Instance.new("UICorner", tabButton).CornerRadius = UDim.new(0, 6)
        CreateGradient(tabButton, 90, Theme.Primary, Theme.PrimaryDark)
        registerThemedElement(tabButton, "BackgroundColor3", "Primary")

        local tabPage = Instance.new("Frame")
        tabPage.Size = UDim2.fromScale(1, 1)
        tabPage.BackgroundTransparency = 1
        tabPage.Visible = false
        tabPage.ZIndex = ZINDEX.MAIN
        tabPage.Parent = ContentScroll

        local pageList = Instance.new("UIListLayout")
        pageList.SortOrder = Enum.SortOrder.LayoutOrder
        pageList.Padding = UDim.new(0, 6)
        pageList.Parent = tabPage

        local function selectTab()
            for _, child in ipairs(ContentScroll:GetChildren()) do
                if child:IsA("Frame") then child.Visible = false end
            end
            for _, child in ipairs(TabContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    CreateTween(child, {BackgroundTransparency = 0.85}, TWEEN.FAST)
                end
            end
            tabPage.Visible = true
            CreateTween(tabButton, {BackgroundTransparency = 0.5}, TWEEN.FAST)
            ContentScroll.CanvasSize = UDim2.new(0, 0, 0, pageList.AbsoluteContentSize.Y + 10)
            pageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                ContentScroll.CanvasSize = UDim2.new(0, 0, 0, pageList.AbsoluteContentSize.Y + 10)
            end)
            SmoothScroll(ContentScroll, 0, 0.2)
            currentTabPage = tabPage
        end

        connectEvent(tabButton.MouseButton1Click, selectTab)
        if #tabs == 0 then selectTab() end
        table.insert(tabs, {Button = tabButton, Page = tabPage, List = pageList})

        local Tab = {}

        local function addElement(frame)
            frame.Parent = currentTabPage
            ContentScroll.CanvasSize = UDim2.new(0, 0, 0, pageList.AbsoluteContentSize.Y + 10)
        end

        local function createBaseElement(height)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -8, 0, height)
            frame.BackgroundColor3 = Theme.Primary
            frame.BackgroundTransparency = 0.85
            frame.BorderSizePixel = 0
            frame.ZIndex = ZINDEX.MAIN
            addElement(frame)
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
            local grad = CreateGradient(frame, 90, Theme.Primary, Theme.PrimaryDark)
            registerThemedElement(frame, "BackgroundColor3", "Primary")
            return frame
        end

        function Tab:CreateButton(config)
            local name = config.Name or "Button"
            local callback = config.Callback or function() end
            local frame = createBaseElement(38)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.fromScale(1, 1)
            btn.BackgroundTransparency = 1
            btn.Text = name
            btn.TextColor3 = Theme.Text
            btn.Font = Fonts.Main
            btn.TextSize = 14
            btn.ZIndex = ZINDEX.MAIN
            btn.Parent = frame
            connectEvent(btn.MouseEnter, function() CreateTween(frame, {BackgroundTransparency = 0.7}, TWEEN.FAST) end)
            connectEvent(btn.MouseLeave, function() CreateTween(frame, {BackgroundTransparency = 0.85}, TWEEN.FAST) end)
            connectEvent(btn.MouseButton1Click, function()
                CreateTween(frame, {BackgroundTransparency = 0.5}, TWEEN.FAST)
                task.wait(TWEEN.FAST)
                CreateTween(frame, {BackgroundTransparency = 0.85}, TWEEN.FAST)
                callback()
            end)
            if config.Tooltip then Window:AddTooltip(btn, config.Tooltip) end
            return btn
        end

        function Tab:CreateToggle(config)
            local name = config.Name or "Toggle"
            local default = config.Default or false
            local callback = config.Callback or function() end
            local state = default

            local frame = createBaseElement(38)
            local label = Instance.new("TextLabel")
            label.Text = name
            label.Size = UDim2.new(0.65, 0, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Theme.Text
            label.Font = Fonts.Secondary
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = ZINDEX.MAIN
            label.Parent = frame

            local switchFrame = Instance.new("Frame")
            switchFrame.Size = UDim2.new(0, 44, 0, 22)
            switchFrame.Position = UDim2.new(1, -52, 0.5, -11)
            switchFrame.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
            switchFrame.BorderSizePixel = 0
            switchFrame.ZIndex = ZINDEX.MAIN
            switchFrame.Parent = frame
            Instance.new("UICorner", switchFrame).CornerRadius = UDim.new(1, 0)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 18, 0, 18)
            knob.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
            knob.BackgroundColor3 = Theme.Text
            knob.BorderSizePixel = 0
            knob.ZIndex = ZINDEX.MAIN
            knob.Parent = switchFrame
            Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Size = UDim2.fromScale(1, 1)
            toggleBtn.BackgroundTransparency = 1
            toggleBtn.Text = ""
            toggleBtn.ZIndex = ZINDEX.MAIN
            toggleBtn.Parent = frame

            local function updateVisual()
                if state then
                    CreateTween(switchFrame, {BackgroundColor3 = Theme.ToggleOn}, TWEEN.FAST)
                    CreateTween(knob, {Position = UDim2.new(1, -20, 0.5, -9)}, TWEEN.FAST)
                else
                    CreateTween(switchFrame, {BackgroundColor3 = Theme.ToggleOff}, TWEEN.FAST)
                    CreateTween(knob, {Position = UDim2.new(0, 2, 0.5, -9)}, TWEEN.FAST)
                end
            end

            connectEvent(toggleBtn.MouseButton1Click, function()
                state = not state
                updateVisual()
                callback(state)
            end)
            updateVisual()
            registerComponent(name, "toggle", function() return state end, function(val) state = val; updateVisual(); callback(state) end)
            return toggleBtn
        end

        function Tab:CreateSlider(config)
            local name = config.Name or "Slider"
            local min = config.Min or 0
            local max = config.Max or 100
            local default = config.Default or 50
            local callback = config.Callback or function() end

            local value = math.clamp(default, min, max)
            local frame = createBaseElement(52)

            local label = Instance.new("TextLabel")
            label.Text = name
            label.Size = UDim2.new(1, -50, 0, 20)
            label.Position = UDim2.new(0, 10, 0, 5)
            label.BackgroundTransparency = 1
            label.TextColor3 = Theme.Text
            label.Font = Fonts.Secondary
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = ZINDEX.MAIN
            label.Parent = frame

            local valueLabel = Instance.new("TextLabel")
            valueLabel.Text = tostring(value)
            valueLabel.Size = UDim2.new(0, 40, 0, 20)
            valueLabel.Position = UDim2.new(1, -45, 0, 5)
            valueLabel.BackgroundTransparency = 1
            valueLabel.TextColor3 = Theme.Text
            valueLabel.Font = Fonts.Mono
            valueLabel.TextSize = 13
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.ZIndex = ZINDEX.MAIN
            valueLabel.Parent = frame

            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -20, 0, 6)
            track.Position = UDim2.new(0, 10, 0, 32)
            track.BackgroundColor3 = Theme.SliderTrack
            track.BorderSizePixel = 0
            track.ZIndex = ZINDEX.MAIN
            track.Parent = frame
            Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = Theme.Primary
            fill.BorderSizePixel = 0
            fill.ZIndex = ZINDEX.MAIN
            fill.Parent = track
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
            registerThemedElement(fill, "BackgroundColor3", "Primary")

            local sliderBtn = Instance.new("TextButton")
            sliderBtn.Size = UDim2.fromScale(1, 1)
            sliderBtn.BackgroundTransparency = 1
            sliderBtn.Text = ""
            sliderBtn.ZIndex = ZINDEX.MAIN
            sliderBtn.Parent = frame

            local function updateVisual()
                local percent = (value - min) / (max - min)
                fill.Size = UDim2.new(percent, 0, 1, 0)
                valueLabel.Text = tostring(value)
            end

            local moveConn, endConn
            local function updateFromInput(input)
                local mousePos = input.Position.X
                local trackStart = track.AbsolutePosition.X
                local trackWidth = track.AbsoluteSize.X
                local percent = math.clamp((mousePos - trackStart) / trackWidth, 0, 1)
                value = math.floor(min + (max - min) * percent)
                updateVisual()
                callback(value)
            end

            connectEvent(sliderBtn.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    updateFromInput(input)
                    if moveConn then moveConn:Disconnect() end
                    if endConn then endConn:Disconnect() end
                    moveConn = connectEvent(UserInputService.InputChanged, function(moveInput)
                        if moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch then
                            updateFromInput(moveInput)
                        end
                    end)
                    endConn = connectEvent(UserInputService.InputEnded, function(endInput)
                        if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                            if moveConn then moveConn:Disconnect() end
                            if endConn then endConn:Disconnect() end
                        end
                    end)
                end
            end)

            registerComponent(name, "slider", function() return value end, function(val) value = math.clamp(val, min, max); updateVisual(); callback(value) end)
            return sliderBtn
        end

        function Tab:CreateDropdown(config)
            local name = config.Name or "Dropdown"
            local options = config.Options or {}
            local default = config.Default or (options[1] or "")
            local callback = config.Callback or function() end
            local selected = default
            local isOpen = false
            local overlay, outsideClickConn

            local frame = createBaseElement(38)
            local mainBtn = Instance.new("TextButton")
            mainBtn.Size = UDim2.fromScale(1, 1)
            mainBtn.BackgroundTransparency = 1
            mainBtn.Text = name .. " : " .. selected
            mainBtn.TextColor3 = Theme.Text
            mainBtn.Font = Fonts.Secondary
            mainBtn.TextSize = 13
            mainBtn.TextXAlignment = Enum.TextXAlignment.Left
            mainBtn.ZIndex = ZINDEX.MAIN
            mainBtn.Parent = frame

            local arrow = Instance.new("TextLabel")
            arrow.Text = "v"
            arrow.Size = UDim2.new(0, 20, 1, 0)
            arrow.Position = UDim2.new(1, -25, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.TextColor3 = Theme.Text
            arrow.Font = Fonts.Main
            arrow.TextSize = 12
            arrow.ZIndex = ZINDEX.MAIN
            arrow.Parent = frame

            local function close()
                if not isOpen then return end
                isOpen = false
                CreateTween(arrow, {Rotation = 0}, TWEEN.FAST)
                if outsideClickConn then outsideClickConn:Disconnect(); outsideClickConn = nil end
                if overlay then
                    unregisterOverlay(overlay)
                    overlay:Destroy()
                    overlay = nil
                end
            end

            local function open()
                if isOpen then close() end
                isOpen = true
                CreateTween(arrow, {Rotation = 180}, TWEEN.FAST)
                overlay = createOverlay(frame, #options * 32, close)
                local optList = Instance.new("UIListLayout")
                optList.SortOrder = Enum.SortOrder.LayoutOrder
                optList.Parent = overlay
                for _, opt in ipairs(options) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, 0, 0, 30)
                    optBtn.BackgroundTransparency = 1
                    optBtn.Text = opt
                    optBtn.TextColor3 = Theme.Text
                    optBtn.Font = Fonts.Normal
                    optBtn.TextSize = 13
                    optBtn.ZIndex = ZINDEX.OVERLAY
                    optBtn.Parent = overlay
                    connectEvent(optBtn.MouseEnter, function()
                        optBtn.BackgroundTransparency = 0.7
                        optBtn.BackgroundColor3 = Theme.Primary
                    end)
                    connectEvent(optBtn.MouseLeave, function()
                        optBtn.BackgroundTransparency = 1
                        optBtn.BackgroundColor3 = Theme.DropdownOption
                    end)
                    connectEvent(optBtn.MouseButton1Click, function()
                        selected = opt
                        mainBtn.Text = name .. " : " .. selected
                        callback(opt)
                        close()
                    end)
                end
                outsideClickConn = connectEvent(UserInputService.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local mousePos = UserInputService:GetMouseLocation()
                        local ovPos = overlay.AbsolutePosition
                        local ovSize = overlay.AbsoluteSize
                        if mousePos.X < ovPos.X or mousePos.X > ovPos.X + ovSize.X or
                           mousePos.Y < ovPos.Y or mousePos.Y > ovPos.Y + ovSize.Y then
                            close()
                        end
                    end
                end)
            end

            connectEvent(mainBtn.MouseButton1Click, function()
                if isOpen then close() else open() end
            end)
            registerComponent(name, "dropdown", function() return selected end, function(val)
                if table.find(options, val) then
                    selected = val
                    mainBtn.Text = name .. " : " .. selected
                    callback(selected)
                end
            end)
            return mainBtn
        end

        function Tab:CreateListBox(config)
            local name = config.Name or "ListBox"
            local options = config.Options or {}
            local multiSelect = config.MultiSelect or false
            local callback = config.Callback or function() end
            local selectedItems = {}
            local isOpen = false
            local overlay, outsideClickConn

            local frame = createBaseElement(38)
            local mainBtn = Instance.new("TextButton")
            mainBtn.Size = UDim2.fromScale(1, 1)
            mainBtn.BackgroundTransparency = 1
            mainBtn.Text = name .. " : None"
            mainBtn.TextColor3 = Theme.Text
            mainBtn.Font = Fonts.Secondary
            mainBtn.TextSize = 13
            mainBtn.TextXAlignment = Enum.TextXAlignment.Left
            mainBtn.ZIndex = ZINDEX.MAIN
            mainBtn.Parent = frame

            local arrow = Instance.new("TextLabel")
            arrow.Text = "v"
            arrow.Size = UDim2.new(0, 20, 1, 0)
            arrow.Position = UDim2.new(1, -25, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.TextColor3 = Theme.Text
            arrow.Font = Fonts.Main
            arrow.TextSize = 12
            arrow.ZIndex = ZINDEX.MAIN
            arrow.Parent = frame

            local function updateText()
                if #selectedItems == 0 then mainBtn.Text = name .. " : None"
                else
                    local str = table.concat(selectedItems, ", ")
                    if #str > 20 then str = str:sub(1, 20) .. "..." end
                    mainBtn.Text = name .. " : " .. str
                end
            end

            local function close()
                if not isOpen then return end
                isOpen = false
                CreateTween(arrow, {Rotation = 0}, TWEEN.FAST)
                if outsideClickConn then outsideClickConn:Disconnect(); outsideClickConn = nil end
                if overlay then
                    unregisterOverlay(overlay)
                    overlay:Destroy()
                    overlay = nil
                end
            end

            local function open()
                if isOpen then close() end
                isOpen = true
                CreateTween(arrow, {Rotation = 180}, TWEEN.FAST)
                overlay = createOverlay(frame, math.min(#options * 30, 180), close)
                local scrolling = Instance.new("ScrollingFrame")
                scrolling.Size = UDim2.fromScale(1, 1)
                scrolling.BackgroundTransparency = 1
                scrolling.ScrollBarThickness = 2
                scrolling.ScrollBarImageColor3 = Theme.Primary
                scrolling.CanvasSize = UDim2.new(0, 0, 0, #options * 30)
                scrolling.ZIndex = ZINDEX.OVERLAY
                scrolling.Parent = overlay
                local optList = Instance.new("UIListLayout")
                optList.SortOrder = Enum.SortOrder.LayoutOrder
                optList.Parent = scrolling

                for _, opt in ipairs(options) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, 0, 0, 30)
                    optBtn.BackgroundTransparency = 1
                    optBtn.Text = (table.find(selectedItems, opt) and "[x] " or "[ ] ") .. opt
                    optBtn.TextColor3 = Theme.Text
                    optBtn.Font = Fonts.Normal
                    optBtn.TextSize = 13
                    optBtn.ZIndex = ZINDEX.OVERLAY
                    optBtn.Parent = scrolling
                    connectEvent(optBtn.MouseEnter, function() optBtn.BackgroundTransparency = 0.7; optBtn.BackgroundColor3 = Theme.Primary end)
                    connectEvent(optBtn.MouseLeave, function() optBtn.BackgroundTransparency = 1; optBtn.BackgroundColor3 = Theme.DropdownOption end)
                    connectEvent(optBtn.MouseButton1Click, function()
                        if multiSelect then
                            local idx = table.find(selectedItems, opt)
                            if idx then table.remove(selectedItems, idx) else table.insert(selectedItems, opt) end
                        else
                            selectedItems = {opt}
                            close()
                        end
                        updateText()
                        callback(selectedItems)
                        if overlay and overlay.Parent then
                            for _, child in ipairs(scrolling:GetChildren()) do
                                if child:IsA("TextButton") then
                                    local optText = child.Text:gsub("%[. %] ", "")
                                    child.Text = (table.find(selectedItems, optText) and "[x] " or "[ ] ") .. optText
                                end
                            end
                        end
                    end)
                end

                outsideClickConn = connectEvent(UserInputService.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local mousePos = UserInputService:GetMouseLocation()
                        local ovPos = overlay.AbsolutePosition
                        local ovSize = overlay.AbsoluteSize
                        if mousePos.X < ovPos.X or mousePos.X > ovPos.X + ovSize.X or
                           mousePos.Y < ovPos.Y or mousePos.Y > ovPos.Y + ovSize.Y then
                            close()
                        end
                    end
                end)
            end

            connectEvent(mainBtn.MouseButton1Click, function() if isOpen then close() else open() end end)
            registerComponent(name, "listbox", function() return selectedItems end, function(val) selectedItems = type(val) == "table" and val or {val}; updateText(); callback(selectedItems) end)
            return mainBtn
        end

        function Tab:CreateKeybind(config)
            local name = config.Name or "Keybind"
            local default = config.Default or Enum.KeyCode.F
            local mode = config.Mode or "Toggle"
            local callback = config.Callback or function() end
            local currentKey = default
            local binding = false
            local bindConn
            local toggled = false

            local frame = createBaseElement(38)
            local label = Instance.new("TextLabel")
            label.Text = name .. " (" .. mode .. ")"
            label.Size = UDim2.new(0.55, 0, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Theme.Text
            label.Font = Fonts.Secondary
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = ZINDEX.MAIN
            label.Parent = frame

            local keyDisplay = Instance.new("TextButton")
            keyDisplay.Size = UDim2.new(0, 80, 0, 26)
            keyDisplay.Position = UDim2.new(1, -90, 0.5, -13)
            keyDisplay.BackgroundColor3 = Theme.Primary
            keyDisplay.BackgroundTransparency = 0.7
            keyDisplay.Text = currentKey.Name
            keyDisplay.TextColor3 = Theme.Text
            keyDisplay.Font = Fonts.Main
            keyDisplay.TextSize = 12
            keyDisplay.ZIndex = ZINDEX.MAIN
            keyDisplay.Parent = frame
            Instance.new("UICorner", keyDisplay).CornerRadius = UDim.new(0, 4)

            local function stopBinding()
                if bindConn then bindConn:Disconnect(); bindConn = nil end
                binding = false
            end

            connectEvent(keyDisplay.MouseButton1Click, function()
                stopBinding()
                binding = true
                keyDisplay.Text = "..."
                bindConn = connectEvent(UserInputService.InputBegan, function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        keyDisplay.Text = currentKey.Name
                        stopBinding()
                    end
                end)
            end)

            if mode == "Toggle" then
                connectEvent(UserInputService.InputBegan, function(input, gameProcessed)
                    if gameProcessed then return end
                    if not binding and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
                        toggled = not toggled
                        CreateTween(keyDisplay, {BackgroundTransparency = toggled and 0.4 or 0.7}, TWEEN.FAST)
                        callback(toggled)
                    end
                end)
            elseif mode == "Hold" then
                connectEvent(UserInputService.InputBegan, function(input, gameProcessed)
                    if gameProcessed then return end
                    if not binding and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
                        CreateTween(keyDisplay, {BackgroundTransparency = 0.4}, TWEEN.FAST)
                        callback(true)
                    end
                end)
                connectEvent(UserInputService.InputEnded, function(input)
                    if not binding and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
                        CreateTween(keyDisplay, {BackgroundTransparency = 0.7}, TWEEN.FAST)
                        callback(false)
                    end
                end)
            end
            registerComponent(name, "keybind", function() return currentKey end, function(val) currentKey = val; keyDisplay.Text = currentKey.Name end)
            return keyDisplay
        end

        function Tab:CreateColorPicker(config)
            local name = config.Name or "Color"
            local default = config.Default or Color3.fromRGB(255, 0, 0)
            local callback = config.Callback or function() end
            local currentColor = default
            local frame = createBaseElement(38)

            local label = Instance.new("TextLabel")
            label.Text = name
            label.Size = UDim2.new(0.6, 0, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Theme.Text
            label.Font = Fonts.Secondary
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = ZINDEX.MAIN
            label.Parent = frame

            local colorPreview = Instance.new("TextButton")
            colorPreview.Size = UDim2.new(0, 36, 0, 36)
            colorPreview.Position = UDim2.new(1, -50, 0.5, -18)
            colorPreview.BackgroundColor3 = currentColor
            colorPreview.BorderSizePixel = 0
            colorPreview.Text = ""
            colorPreview.ZIndex = ZINDEX.MAIN
            colorPreview.Parent = frame
            Instance.new("UICorner", colorPreview).CornerRadius = UDim.new(0, 6)
            local prevStroke = Instance.new("UIStroke")
            prevStroke.Color = Theme.PrimaryLight
            prevStroke.Thickness = 1
            prevStroke.Transparency = 0.4
            prevStroke.ZIndex = ZINDEX.MAIN
            prevStroke.Parent = colorPreview

            local pickerOpen = false
            local pickerOverlay, outsideConn, indicator

            local function closePicker()
                if pickerOpen then
                    pickerOpen = false
                    if outsideConn then outsideConn:Disconnect(); outsideConn = nil end
                    if pickerOverlay then
                        unregisterOverlay(pickerOverlay)
                        pickerOverlay:Destroy()
                        pickerOverlay = nil
                    end
                end
            end

            local function openPicker()
                closePicker()
                pickerOpen = true
                pickerOverlay = createOverlay(frame, 200, closePicker)
                pickerOverlay.Size = UDim2.new(0, 200, 0, 200)

                local hueGrad = Instance.new("UIGradient")
                hueGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
                    ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255,255,0)),
                    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0,255,0)),
                    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0,255,255)),
                    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0,0,255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,255)),
                })
                hueGrad.Parent = pickerOverlay
                local satGrad = Instance.new("UIGradient")
                satGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                })
                satGrad.Parent = pickerOverlay

                indicator = Instance.new("Frame")
                indicator.Size = UDim2.new(0, 8, 0, 8)
                indicator.BackgroundColor3 = Color3.new(1,1,1)
                indicator.BorderSizePixel = 0
                indicator.ZIndex = ZINDEX.OVERLAY + 1
                indicator.Parent = pickerOverlay
                Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
                local indStroke = Instance.new("UIStroke")
                indStroke.Color = Color3.new(0,0,0)
                indStroke.Thickness = 1
                indStroke.Parent = indicator

                local function updateIndicator(input)
                    local mousePos = UserInputService:GetMouseLocation()
                    local absPos = pickerOverlay.AbsolutePosition
                    local absSize = pickerOverlay.AbsoluteSize
                    local xPercent = math.clamp((mousePos.X - absPos.X) / absSize.X, 0, 1)
                    local yPercent = math.clamp((mousePos.Y - absPos.Y) / absSize.Y, 0, 1)
                    indicator.Position = UDim2.new(xPercent, -4, yPercent, -4)
                    local hue = xPercent
                    local sat = 1 - yPercent
                    local val = 1
                    local r, g, b = Color3.fromHSV(hue, sat, val)
                    currentColor = Color3.new(r, g, b)
                    colorPreview.BackgroundColor3 = currentColor
                    callback(currentColor)
                end

                local pickBtn = Instance.new("TextButton")
                pickBtn.Size = UDim2.fromScale(1, 1)
                pickBtn.BackgroundTransparency = 1
                pickBtn.Text = ""
                pickBtn.ZIndex = ZINDEX.OVERLAY
                pickBtn.Parent = pickerOverlay
                connectEvent(pickBtn.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        updateIndicator(input)
                        local moveConn, endConn
                        moveConn = connectEvent(UserInputService.InputChanged, function(moveInput)
                            if moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch then
                                updateIndicator(moveInput)
                            end
                        end)
                        endConn = connectEvent(UserInputService.InputEnded, function(endInput)
                            if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                                moveConn:Disconnect()
                                endConn:Disconnect()
                            end
                        end)
                    end
                end)

                outsideConn = connectEvent(UserInputService.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local mousePos = UserInputService:GetMouseLocation()
                        local ovPos = pickerOverlay.AbsolutePosition
                        local ovSize = pickerOverlay.AbsoluteSize
                        if mousePos.X < ovPos.X or mousePos.X > ovPos.X + ovSize.X or
                           mousePos.Y < ovPos.Y or mousePos.Y > ovPos.Y + ovSize.Y then
                            closePicker()
                        end
                    end
                end)
            end

            connectEvent(colorPreview.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if pickerOpen then closePicker() else openPicker() end
                end
            end)
            registerComponent(name, "color", function() return currentColor end, function(val) currentColor = val; colorPreview.BackgroundColor3 = currentColor; callback(currentColor) end)
            return colorPreview
        end

        function Tab:CreateSection(config)
            local text = config.Name or "Section"
            local secFrame = Instance.new("Frame")
            secFrame.Size = UDim2.new(1, -8, 0, 28)
            secFrame.BackgroundTransparency = 1
            secFrame.ZIndex = ZINDEX.MAIN
            addElement(secFrame)
            local secLabel = Instance.new("TextLabel")
            secLabel.Text = text
            secLabel.Size = UDim2.fromScale(1, 1)
            secLabel.BackgroundTransparency = 1
            secLabel.TextColor3 = Theme.Text
            secLabel.Font = Fonts.Main
            secLabel.TextSize = 15
            secLabel.TextTransparency = 0.4
            secLabel.ZIndex = ZINDEX.MAIN
            secLabel.Parent = secFrame
            return secFrame
        end

        function Tab:CreateLabel(config)
            local text = config.Text or "Label"
            local lblFrame = Instance.new("Frame")
            lblFrame.Size = UDim2.new(1, -8, 0, 26)
            lblFrame.BackgroundTransparency = 1
            lblFrame.ZIndex = ZINDEX.MAIN
            addElement(lblFrame)
            local lbl = Instance.new("TextLabel")
            lbl.Text = text
            lbl.Size = UDim2.fromScale(1, 1)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = Theme.Text
            lbl.Font = Fonts.Normal
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = ZINDEX.MAIN
            lbl.Parent = lblFrame
            return lbl
        end

        function Tab:CreateTextBox(config)
            local name = config.Name or "TextBox"
            local placeholder = config.Placeholder or ""
            local callback = config.Callback or function() end
            local frame = createBaseElement(38)
            local textBox = Instance.new("TextBox")
            textBox.Size = UDim2.new(1, -10, 1, 0)
            textBox.Position = UDim2.new(0, 5, 0, 0)
            textBox.BackgroundTransparency = 1
            textBox.Text = ""
            textBox.PlaceholderText = placeholder
            textBox.TextColor3 = Theme.Text
            textBox.PlaceholderColor3 = Theme.TextDark
            textBox.Font = Fonts.Mono
            textBox.TextSize = 13
            textBox.ClearTextOnFocus = false
            textBox.ZIndex = ZINDEX.MAIN
            textBox.Parent = frame
            connectEvent(textBox.FocusLost, function(enterPressed)
                if enterPressed then callback(textBox.Text) end
            end)
            return textBox
        end

        return Tab
    end

    if config.DefaultConfigTab ~= false then
        local ConfigTab = Window:CreateTab({ Name = "Config" })
        ConfigTab:CreateSection({ Name = "Config Manager" })
        ConfigTab:CreateButton({ Name = "Create Config", Callback = function()
            local cfg = Window:CreateConfig()
            local json = HttpService:JSONEncode(cfg)
            print(json)
            Window:Notification({ Text = "Config printed to output", Type = "info" })
        end })
        ConfigTab:CreateButton({ Name = "Save Config", Callback = function()
            Window:SaveConfig("RedGlass_Config.json")
        end })
        ConfigTab:CreateButton({ Name = "Load Config", Callback = function()
            if readfile then
                Window:LoadConfig("RedGlass_Config.json")
            else
                local clip = getclipboard and getclipboard()
                if clip and clip ~= "" then
                    Window:LoadConfig(clip)
                else
                    Window:Notification({ Text = "No config found", Type = "error" })
                end
            end
        end })
        ConfigTab:CreateSection({ Name = "Performance" })
        ConfigTab:CreateButton({ Name = "Boost FPS", Callback = function()
            Window:BoostFPS()
        end, Tooltip = "Lower graphics for maximum FPS" })
    end

    local antiCheatData = Window:DetectAntiCheat()
    local PlayerTab = Window:CreateTab({ Name = "Player" })
    
    if antiCheatData.Detected then
        PlayerTab:CreateSection({ Name = "Anti-Cheat Warning" })
        PlayerTab:CreateLabel({ Text = "Risk Level: " .. antiCheatData.RiskLevel })
        for _, ac in ipairs(antiCheatData.List) do
            PlayerTab:CreateLabel({ Text = "Detected: " .. ac.name .. " (" .. ac.confidence .. "%)" })
        end
    end
    
    PlayerTab:CreateToggle({
        Name = "Infinite Jump",
        Default = false,
        Callback = function(value)
            infiniteJumpEnabled = value
            local char = Player.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    if value then
                        hum.JumpPower = 100
                        if jumpConnection then jumpConnection:Disconnect() end
                        jumpConnection = UserInputService.JumpRequest:Connect(function()
                            if not infiniteJumpEnabled then return end
                            local c = Player.Character
                            if c then
                                local h = c:FindFirstChild("Humanoid")
                                if h and h:GetState() ~= Enum.HumanoidStateType.PlatformStanding and h:GetState() ~= Enum.HumanoidStateType.Ragdoll then
                                    h:ChangeState(Enum.HumanoidStateType.Jumping)
                                end
                            end
                        end)
                        connectEvent(jumpConnection, function() end)
                    else
                        hum.JumpPower = 50
                        if jumpConnection then jumpConnection:Disconnect(); jumpConnection = nil end
                    end
                end
            end
        end
    })

    PlayerTab:CreateSlider({
        Name = "Walk Speed",
        Min = 16,
        Max = 200,
        Default = 50,
        Callback = function(value)
            walkSpeedVal = value
            local char = Player.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then hum.WalkSpeed = value end
            end
        end
    })

    PlayerTab:CreateToggle({
        Name = "Fly",
        Default = false,
        Callback = function(value)
            if value then startFly() else stopFly() end
        end
    })

    PlayerTab:CreateToggle({
        Name = "Noclip",
        Default = false,
        Callback = function(value)
            if value then startNoclip() else stopNoclip() end
        end
    })

    PlayerTab:CreateToggle({
        Name = "Skywalk",
        Default = false,
        Callback = function(value)
            if value then startSkywalk() else stopSkywalk() end
        end
    })

    PlayerTab:CreateSlider({
        Name = "Fly Speed",
        Min = 10,
        Max = 200,
        Default = 50,
        Callback = function(value) flySpeed = value end
    })

    local TeleportTab = Window:CreateTab({ Name = "Teleport" })
    local getPlayerOptions = function()
        local opts = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player then table.insert(opts, plr.Name) end
        end
        return opts
    end

    local selectedTarget = nil
    local teleportDropdown

    local function createTeleportDropdown()
        if teleportDropdown then teleportDropdown:Destroy() end
        local options = getPlayerOptions()
        if #options == 0 then
            options = {"No players found"}
        end
        teleportDropdown = TeleportTab:CreateDropdown({
            Name = "Target Player",
            Options = options,
            Default = options[1] or "",
            Callback = function(name) 
                if name ~= "No players found" then
                    selectedTarget = name 
                end
            end
        })
    end

    createTeleportDropdown()
    
    TeleportTab:CreateButton({
        Name = "Refresh Players",
        Callback = function()
            createTeleportDropdown()
            Window:Notification({ Text = "Player list refreshed", Type = "info" })
        end
    })
    
    TeleportTab:CreateButton({
        Name = "Teleport to Player",
        Callback = function()
            if not selectedTarget then
                Window:Notification({ Text = "Select a player first", Type = "warning" })
                return
            end
            local target = Players:FindFirstChild(selectedTarget)
            if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
                Window:Notification({ Text = "Player not available", Type = "error" })
                return
            end
            local myChar = Player.Character
            if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then
                Window:Notification({ Text = "You are not spawned", Type = "error" })
                return
            end
            myChar.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(2, 0, 0)
            Window:Notification({ Text = "Teleported to " .. selectedTarget, Type = "success" })
        end
    })
    
    TeleportTab:CreateTextBox({
        Name = "Waypoint (x,y,z)",
        Placeholder = "e.g. 100,50,200",
        Callback = function(text)
            local x, y, z = text:match("([%d.-]+)%s*,%s*([%d.-]+)%s*,%s*([%d.-]+)")
            if x then
                local char = Player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = CFrame.new(tonumber(x), tonumber(y), tonumber(z))
                    Window:Notification({ Text = "Teleported to waypoint!", Type = "success" })
                else
                    Window:Notification({ Text = "Character not found", Type = "error" })
                end
            else
                Window:Notification({ Text = "Invalid format. Use x,y,z", Type = "error" })
            end
        end
    })

    local ExploitTab = Window:CreateTab({ Name = "Exploit" })
    
    local function checkGamepassAvailability()
        local gamepasses = detectGamepasses()
        if #gamepasses > 0 then
            ExploitTab:CreateSection({ Name = "Gamepasses (" .. #gamepasses .. " found)" })
            for _, gp in ipairs(gamepasses) do
                local status = gp.Owned and " (Owned)" or " (Price: " .. gp.Price .. " R$)"
                ExploitTab:CreateButton({
                    Name = gp.Name .. status,
                    Callback = function()
                        if gp.Owned then
                            Window:Notification({ Text = "Already owned!", Type = "warning" })
                            return
                        end
                        Window:Notification({ Text = "Attempting to get: " .. gp.Name, Type = "info" })
                        local result = attemptFreeGamepass(gp.Id, gp.Name)
                        if result.Success then
                            Window:Notification({ Text = "Gamepass acquired: " .. gp.Name .. " (Methods: " .. table.concat(result.Methods, ", ") .. ")", Type = "success" })
                        else
                            Window:Notification({ Text = "Failed to get gamepass: " .. gp.Name, Type = "error" })
                        end
                    end
                })
            end
        else
            ExploitTab:CreateSection({ Name = "No Gamepasses Detected" })
            ExploitTab:CreateLabel({ Text = "This game may not have gamepasses" })
            ExploitTab:CreateLabel({ Text = "or they are hidden/encrypted" })
        end
    end
    
    checkGamepassAvailability()
    
    ExploitTab:CreateButton({
        Name = "Refresh Gamepasses",
        Callback = function()
            for _, child in ipairs(ExploitTab.Page:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end
            checkGamepassAvailability()
            Window:Notification({ Text = "Gamepass list refreshed", Type = "info" })
        end
    })

    connectEvent(UserInputService.InputBegan, function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.RightShift then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    return Window
end

return RedGlass