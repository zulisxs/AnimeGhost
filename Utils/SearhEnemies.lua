local function searchEnemies()
    local enemiesFolder = workspace:FindFirstChild("_ENEMIES")
    if not enemiesFolder then return {} end

    local clientFolder = enemiesFolder:FindFirstChild("Client")
    if not clientFolder then return {} end

    local enemyNames = {}
    local seen = {}

    for _, model in ipairs(clientFolder:GetChildren()) do
        local billboard = model:FindFirstChild("EnemyBillboard")
        if billboard then
            local title = billboard:FindFirstChild("Title")
            if title and title:IsA("TextLabel") and title.Text ~= "" then
                local name = title.Text
                if not seen[name] then
                    seen[name] = true
                    table.insert(enemyNames, name)
                end
            end
        end
    end

    return enemyNames
end
