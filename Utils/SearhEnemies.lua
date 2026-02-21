-- =====================
-- UTILITIES
-- =====================

local function parseHP(text)
    -- Ejemplo: "1.5M HP" -> numero comparable
    local num, suffix = text:match("([%d%.]+)%s*([KMBTQ]?)%s*HP")
    if not num then return 0 end
    num = tonumber(num) or 0
    local multipliers = {
        K = 1e3, M = 1e6, B = 1e9, T = 1e12, Q = 1e15
    }
    return num * (multipliers[suffix] or 1)
end

local function getEnemyHP(model)
    local billboard = model:FindFirstChild("EnemyBillboard")
    if not billboard then return 0 end
    local amount = billboard:FindFirstChild("Amount")
    if not amount or not amount:IsA("TextLabel") then return 0 end
    return parseHP(amount.Text)
end

local function getEnemyName(model)
    local billboard = model:FindFirstChild("EnemyBillboard")
    if not billboard then return nil end
    local title = billboard:FindFirstChild("Title")
    if not title or not title:IsA("TextLabel") then return nil end
    return title.Text
end

local function isEnemyAlive(enemy)
    -- Verificar que el modelo sigue existiendo en _ENEMIES.Client
    local clientFolder = workspace:FindFirstChild("_ENEMIES") and 
                         workspace._ENEMIES:FindFirstChild("Client")
    if not clientFolder then return false end
    
    -- Si el modelo ya no es hijo de Client, esta muerto
    if enemy.Parent ~= clientFolder then return false end
    
    -- Verificar que aun tiene EnemyBillboard
    local billboard = enemy:FindFirstChild("EnemyBillboard")
    return billboard ~= nil
end

local function getEnemyPosition(model)
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    return hrp.Position
end

local function getDistance(model)
    local pos = getEnemyPosition(model)
    if not pos then return math.huge end
    local player = game.Players.LocalPlayer.Character
    if not player then return math.huge end
    local hrp = player:FindFirstChild("HumanoidRootPart")
    if not hrp then return math.huge end
    return (hrp.Position - pos).Magnitude
end

-- =====================
-- SEARCH ENEMIES
-- =====================

local function searchEnemies()
    local enemiesFolder = workspace:FindFirstChild("_ENEMIES")
    if not enemiesFolder then return {} end

    local clientFolder = enemiesFolder:FindFirstChild("Client")
    if not clientFolder then return {} end

    local enemyNames = {}
    local seen = {}

    for _, model in ipairs(clientFolder:GetChildren()) do
        local name = getEnemyName(model)
        if name and not seen[name] then
            seen[name] = true
            table.insert(enemyNames, name)
        end
    end

    return enemyNames
end

-- =====================
-- GET SORTED ENEMIES
-- =====================

local function getSortedEnemies(selectedNames, priority)
    local enemiesFolder = workspace:FindFirstChild("_ENEMIES")
    if not enemiesFolder then return {} end

    local clientFolder = enemiesFolder:FindFirstChild("Client")
    if not clientFolder then return {} end

    -- Filtrar enemigos vivos y seleccionados
    local enemies = {}
    for _, model in ipairs(clientFolder:GetChildren()) do
        if isEnemyAlive(model) then
            local name = getEnemyName(model)
            if name and (selectedNames == nil or selectedNames[name]) then
                table.insert(enemies, model)
            end
        end
    end

    -- Ordenar segun prioridad
    table.sort(enemies, function(a, b)
        if priority == "Low Hp" then
            return getEnemyHP(a) < getEnemyHP(b)
        elseif priority == "High Hp" then
            return getEnemyHP(a) > getEnemyHP(b)
        elseif priority == "Near" then
            return getDistance(a) < getDistance(b)
        end
        return false
    end)

    return enemies
end

-- =====================
-- MOVE METHODS
-- =====================

local function moveByTP(targetPosition)
    local player = game.Players.LocalPlayer.Character
    if not player then return end
    local humanoid = player:FindFirstChildOfClass("Humanoid")
    local hrp = player:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end
    hrp.CFrame = CFrame.new(targetPosition + Vector3.new(0, 3, 0))
    humanoid:MoveTo(targetPosition)
end

local function moveByTween(targetPosition, speed, onComplete)
    local player = game.Players.LocalPlayer.Character
    if not player then return end
    local hrp = player:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local distance = (hrp.Position - targetPosition).Magnitude
    -- speed va de 0 a 100, convertimos a tiempo real (speed 100 = muy rapido)
    local duration = distance / (speed * 2 + 1)

    local TweenService = game:GetService("TweenService")
    local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(targetPosition + Vector3.new(0, 3, 0))
    })
    tween:Play()
    tween.Completed:Connect(function()
        if onComplete then onComplete() end
    end)
    return tween
end

-- =====================
-- AUTO FARM LOOP
-- =====================

local autoFarmRunning = false
local currentTween = nil

local function stopAutoFarm()
    autoFarmRunning = false
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
end

local function waitForEnemyDeath(enemy, timeout)
    timeout = timeout or 30 -- maximo 30 segundos esperando
    local elapsed = 0
    while elapsed < timeout do
        if not isEnemyAlive(enemy) then
            return true -- murio
        end
        task.wait(0.1)
        elapsed = elapsed + 0.1
    end
    return false -- timeout, asumir muerto o skip
end

local function startAutoFarm(options)
    if autoFarmRunning then return end
    autoFarmRunning = true

    task.spawn(function()
        while autoFarmRunning do
            local enemies = getSortedEnemies(options.selectedNames, options.priority)

            if #enemies == 0 then
                task.wait(1)
            else
                for _, enemy in ipairs(enemies) do
                    if not autoFarmRunning then break end
                    if not isEnemyAlive(enemy) then continue end

                    local pos = getEnemyPosition(enemy)
                    if not pos then continue end

                    -- Moverse al enemigo UNA sola vez
                    if options.method == "Tp" then
                        moveByTP(pos)

                    elseif options.method == "Tween" then
                        local arrived = false
                        currentTween = moveByTween(pos, options.tweenSpeed, function()
                            arrived = true
                        end)

                        -- Esperar a llegar
                        while not arrived and autoFarmRunning do
                            if not isEnemyAlive(enemy) then
                                if currentTween then currentTween:Cancel() end
                                break
                            end
                            task.wait(0.1)
                        end
                        currentTween = nil
                    end

                    -- Esperar a que el enemigo muera
                    print("Waiting for enemy to die...")
                    local timeout = 30
                    local elapsed = 0
                    while autoFarmRunning and isEnemyAlive(enemy) and elapsed < timeout do
                        task.wait(0.1)
                        elapsed += 0.1
                    end

                    print("Enemy dead, next...")
                    task.wait(0.2)
                end
            end

            task.wait(0.2)
        end
    end)
end
-- =====================
-- RETURN
-- =====================

return {
    searchEnemies = searchEnemies,
    startAutoFarm = startAutoFarm,
    stopAutoFarm = stopAutoFarm,
}
