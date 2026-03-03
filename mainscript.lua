local game = getfenv().game or game
local tick = tick
local getfenv = getfenv
local pcall = pcall
local tostring = tostring
local tonumber = tonumber
local ipairs = ipairs
local pairs = pairs
local table = table
local math = math

local GetService = game.GetService
local FindFirstChild = game.FindFirstChild
local FindFirstChildWhichIsA = game.FindFirstChildWhichIsA
local HttpGet = game.HttpGet

local isfile = isfile
local writefile = writefile
local makefolder = makefolder
local readfile = readfile
local isfolder = isfolder

local cloneref = (getfenv().cloneref or cloneref) or (getfenv().clonereference or clonereference) or function(...) return ... end
local workspace = cloneref(GetService(game, 'Workspace'))
local httpService = cloneref(GetService(game, 'HttpService'))
local runService = cloneref(GetService(game, 'RunService'))
local playersService = cloneref(GetService(game, 'Players'))
local starterGui = cloneref(GetService(game, 'StarterGui'))
local tweenService = cloneref(GetService(game, 'TweenService'))

local SetCore = starterGui.SetCore

local lplr = playersService.LocalPlayer
local char = lplr.Character
local hum = char and char:FindFirstChild("Humanoid")
local root = char and char:FindFirstChild("HumanoidRootPart")

local gameCamera = FindFirstChild(workspace, 'CurrentCamera') or FindFirstChildWhichIsA(workspace, 'Camera')

local exec = ({identifyexecutor()})[1]

if exec:lower():find('sirhurt') then
    lplr:Kick('Sirhurt and its users are cringe.\n(your exploit sucks too)\n')
    return
end

lplr.CharacterAdded:Connect(function(character)
    char = character
    hum = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")
end)

if not isfolder('klient') then
    makefolder('klient')
end

local function downloadFile(file, content)
    local path = "klient/"..tostring(file)
    if not isfile(path) or (isfile(path) and readfile(path) ~= content) then
        writefile(path, content)
    end
    return path
end

local function notif(title, desc, dur)
    SetCore(starterGui, 'SendNotification', {
        Title = tostring(title),
        Text = tostring(desc),
        Duration = dur or 3,
        Icon = getcustomasset(downloadFile('newklientLogo.png', HttpGet(game, 'https://raw.githubusercontent.com/Foxieldev/Klient/refs/heads/main/NewLogo.png')))
    })
end

local function playTween(obj, goal, duration)
    if not obj or not goal then return end
    local info = TweenInfo.new(duration or 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    tweenService:Create(obj, info, goal):Play()
end

if shared.garbage then
    for _, obj in ipairs(shared.garbage) do
        pcall(function() obj:Destroy() end)
        pcall(function() obj:Disconnect() end)
    end
end

shared.garbage = {}
local klientNotifSent = false

local garbage = shared.garbage

local function maid(obj)
    table.insert(garbage, obj)
    return obj
end

local cfg = {}

local function load()
    if not isfolder("klient") then makefolder("klient") return end
    local files = listfiles("klient")
    if not files then return end
    for _, file in ipairs(files) do
        if file:sub(-5) == ".json" then
            local key = file:match("klient[/\\](.+)%.json$")
            if key then
                local suc, res = pcall(function()
                    return httpService:JSONDecode(readfile(file))
                end)
                if suc then cfg[key] = res end
            end
        end
    end
end

load()

local wsConnected = false
local ws = nil
local lastWsRetry = 0

local function connect()
    pcall(function()
        local connect = (syn and syn.websocket and syn.websocket.connect) or (WebSocket and WebSocket.connect)
        if not connect then return end
        ws = connect("ws://localhost:7823")
        if not ws then return end
        wsConnected = true

        ws.OnMessage:Connect(function(msg)
            pcall(function()
                local data = httpService:JSONDecode(msg)
                if type(data) == "table" and data.k ~= nil then
                    cfg[data.k] = data.v
                end
            end)
        end)

        ws.OnClose:Connect(function()
            wsConnected = false
            ws = nil
        end)
    end)
end

connect()

local changeDuration = 0.1

local moduleDefaults = {
    WalkingSpeed = 16,
    FOV = 60
}

local speedWasEnabled
local fovWasEnabled
local function mainFunction()
    local now = tick()

    if not char or not char.Parent then
        char = lplr.Character or lplr.CharacterAdded:Wait()
        hum  = char:FindFirstChild("Humanoid")
        root = char:FindFirstChild("HumanoidRootPart")
    end

    if not wsConnected and now - lastWsRetry >= 2 then
        connect()
        lastWsRetry = now
    end

    task.spawn(function()
        if hum and hum.Health > 0 then
            local enabled = cfg.walkspeed_enabled
            if enabled and not speedWasEnabled then
                moduleDefaults.WalkingSpeed = hum.WalkSpeed
            end
            if enabled then
                hum.WalkSpeed = tonumber(cfg.walkspeed_value) or hum.WalkSpeed
            elseif speedWasEnabled then
                hum.WalkSpeed = moduleDefaults.WalkingSpeed
            end
            speedWasEnabled = enabled
        end
    end)

    task.spawn(function()
        if gameCamera then
            local enabled = cfg.fov_enabled
            if enabled and not fovWasEnabled then
                moduleDefaults.FOV = gameCamera.FieldOfView
            end
            if enabled then
                playTween(gameCamera, {FieldOfView = tonumber(cfg.fov_value) or moduleDefaults.FOV}, changeDuration)
            elseif fovWasEnabled then
                playTween(gameCamera, {FieldOfView = moduleDefaults.FOV}, changeDuration + 0.2)
            end
            fovWasEnabled = enabled
        end
    end)
end

local Main
Main = maid(runService.Heartbeat:Connect(function()
    local suc, res = pcall(mainFunction)
    if not suc then
        if not klientNotifSent then
            klientNotifSent = true
            Main:Disconnect()
            notif('Klient Error', 'Unable to launch, view the logs in console.', 6)
            warn('Klient : '..tostring(res))
        end
    else
        if not klientNotifSent then
            klientNotifSent = true
            notif('Klient', 'Successfully launched', 4)
        end
    end
end))
