local Fluent, SaveManager, InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"))()
local searchEnemies = loadstring(game:HttpGet("https://raw.githubusercontent.com/zulisxs/AnimeGhost/refs/heads/main/Utils/SearhEnemies.lua"))()

local Window = Fluent:CreateWindow({
    Title = "zUlisxs Hub",
    SubTitle = "Script v1",
    TitleIcon = "home",
    TabWidth = 180,
    Size = UDim2.fromOffset(700, 550),
    Acrylic = true,
    Theme = "Dark",
    Search = true,
    MinimizeKey = Enum.KeyCode.LeftControl,
})


local Tabs = {
    Farm = Window:AddTab({ Title = "Farm", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- Farm Tab

local AutoFarmSection = Tabs.Farm:AddSection("Auto Farm")

local selectenemiesDropdown = AutoFarmSection:AddDropdown("selectenemiesDropdown", {
    Title = "select enemies", Description = "Select option",
    Values = { "" },
    Default = {""},
    Multi = true,
    Search = true, Icon = "list",
    Callback = function(Value)
        print("select enemies changed:", Value)
    end
})

AutoFarmSection:AddButton({
    Title = "Reset enemies", Icon = "sparkles",
    Callback = function()
        selectenemiesDropdown:SetValues(searchEnemies())
    end
})

local PrioridadDropdown = AutoFarmSection:AddDropdown("PrioridadDropdown", {
    Title = "Prioridad",
    Values = { "Low hp", "High Hp", "Near" },
    Default = "High Hp",
    Multi = false,
    Search = true, Icon = "list",
    Callback = function(Value)
        print("Prioridad changed:", Value)
    end
})

local FarmMethodDropdown = AutoFarmSection:AddDropdown("FarmMethodDropdown", {
    Title = "Farm Method",
    Values = { "Tween", "Tp" },
    Default = "Tween",
    Multi = false,
    Search = true, Icon = "list",
    Callback = function(Value)
        print("Farm Method changed:", Value)
    end
})

local TweenSpeedSlider = AutoFarmSection:AddSlider("TweenSpeedSlider", {
    Title = "Tween Speed",
    Default = 30,
    Min = 1,
    Max = 200,
    Rounding = 1, Icon = "slider",
    Callback = function(Value)
        print("Tween Speed changed:", Value)
    end
})

local TpspeedSlider = AutoFarmSection:AddSlider("TpspeedSlider", {
    Title = "Tp speed",
    Default = 80,
    Min = 1,
    Max = 100,
    Rounding = 1, Icon = "slider",
    Callback = function(Value)
        print("Tp speed changed:", Value)
    end
})

local AutoFarmToggle = AutoFarmSection:AddToggle("AutoFarmToggle", {
    Title = "Auto Farm",
    Default = false, Icon = "toggle-right",
    Callback = function(Value)
        if Value then
            local selectedNames = nil
            local selected = Options.selectenemiesDropdown.Value
            if selected and selected ~= "" then
                selectedNames = { [selected] = true }
            end

            EnemiesFunctions.startAutoFarm({
                selectedNames = selectedNames,
                priority      = Options.PrioridadDropdown.Value,
                method        = Options.FarmMethodDropdown.Value,
                tweenSpeed    = Options.TweenSpeedSlider.Value,
                tpSpeed       = Options.TpspeedSlider.Value,
            })
        else
            EnemiesFunctions.stopAutoFarm()
        end
    end
})

local AutoFarmOpeneggToggle = AutoFarmSection:AddToggle("AutoFarmOpeneggToggle", {
    Title = "Auto Farm + Open egg",
    Default = false, Icon = "toggle-right",
    Callback = function(Value)
        print("Auto Farm + Open egg changed:", Value)
    end
})

-- SaveManager & InterfaceManager Configuration
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentPlusSettings")
SaveManager:SetFolder("FluentPlusSettings/Configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

SaveManager:LoadAutoloadConfig()

Fluent:Notify({
    Title = "Fluent Plus",
    Content = "Script Loaded Successfully",
    Duration = 5
})
