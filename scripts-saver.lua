-- Hash
local function BadHash(key)
    local hash = 0
    for i = 1, #key do
            hash = hash + string.byte(key, i)
            hash = hash + bit.lshift(hash, 10)
            hash = hash + bit.rshift(hash, 6)
    end
    hash = hash + bit.lshift(hash, 3)
    hash = hash + bit.rshift(hash, 11)
    hash = hash + bit.lshift(hash, 15)
    return hash
end

-- GUI
local m_Tab         = gui.Tab(gui.Reference("Settings"), "scriptsaver_tab", "[LUA] Saver")
local m_Groupbox    = gui.Groupbox(m_Tab, "Select", 16, 16)

local m_Scripts = {}

file.Enumerate(function(filename) 
    if (string.find(filename, ".lua") == nil) then return end
    if (filename == "autorun.lua") then return end
    if (filename == GetScriptName()) then return end

    table.insert(m_Scripts, { gui.Checkbox(m_Groupbox, "scriptsaver_" .. tostring(BadHash(filename)), filename, false), filename, nil })
end)

local m_Menu = gui.Reference("Menu")
callbacks.Register("Draw", function() 
    if (not m_Menu:IsActive()) then return end

    for i=1,#m_Scripts do
        local m_CurrentScript = m_Scripts[i]
        if (m_CurrentScript[1]:GetValue() ~= m_CurrentScript[3]) then
            m_CurrentScript[3] = m_CurrentScript[1]:GetValue()

            if (m_CurrentScript[3]) then
                LoadScript(m_CurrentScript[2])
            else
                UnloadScript(m_CurrentScript[2])
            end
        end
    end
end)