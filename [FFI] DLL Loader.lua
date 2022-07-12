-- Note:
-- dlls are placed under '%csgo_folder%\lua\dlls' create folder there.

ffi.cdef([[
    uint32_t GetModuleHandleA(const char* pModuleName);
    uint32_t GetModuleFileNameA(uint32_t hModule, char* lpFilename, uint32_t nSize);

    typedef struct
    {
        uint32_t dwFileAttributes;
        uint32_t ftCreationTime[2];
        uint32_t ftLastAccessTime[2];
        uint32_t ftLastWriteTime[2];
        uint32_t nFileSizeHigh;
        uint32_t nFileSizeLow;
        uint32_t dwReserved0;
        uint32_t dwReserved1;
        char cFileName[260];
        char cAlternateFileName[14];
    } WIN32_FIND_DATA;

    uint32_t FindFirstFileA(const char* lpFileName, WIN32_FIND_DATA* lpFindFileData);
    int FindNextFileA(uint32_t hFindFile, WIN32_FIND_DATA* lpFindFileData);
    bool FindClose(uint32_t hFindFile);
]])

local function GetModuleFileNameA(module)
    local name = ffi.new("char[260]")
    return ffi.string(name, ffi.C.GetModuleFileNameA(0, name, 260))
end

local function GetPath(path)
    local pathend = string.len(path) - string.find(string.reverse(path), "\\")

    return string.sub(path, 1, pathend)
end

local function GetFiles(path)
    local files = { }

    local m_Data   = ffi.new("WIN32_FIND_DATA")
    local m_Find   = ffi.C.FindFirstFileA(path .. "\\*", m_Data);
    if (m_Find ~= -1) then

        while (ffi.C.FindNextFileA(m_Find, m_Data) ~= 0) do
            if (ffi.string(m_Data.cFileName, 1) ~= ".") then
                table.insert(files, ffi.string(m_Data.cFileName))
            end
        end

        ffi.C.FindClose(m_Find)
    end

    return files
end

local function TableStringFilter(tbl, str)
    local newtbl = {}

    for i = 1, #tbl do
        if (string.find(tbl[i], str) ~= nil) then
            table.insert(newtbl, tbl[i])
        end
    end

    return newtbl
end

local m_DllPath     = GetPath(GetModuleFileNameA(0)) .. "\\lua\\dlls"
local m_DllFiles    = TableStringFilter(GetFiles(m_DllPath), ".dll")

if (#m_DllFiles == 0) then
    print("lua/dlls - nothing found!")
    UnloadScript(GetScriptName())
    return
end

-- GUI
local m_Window  = gui.Window("dll_window", "DLL Loader", 32, 32, 160, 150)
local m_Combo   = gui.Combobox(m_Window, "dll_select", "Select", unpack(m_DllFiles))
local m_Menu    = gui.Reference("Menu")

-- Loader
ffi.cdef([[
    bool VirtualProtect(void* lpAddress, uint32_t dwSize, uint32_t flNewProtect, uint32_t* lpflOldProtect);
    uint32_t LoadLibraryA(const char* lpLibFileName);
]])

local m_OldProtect = ffi.new("uint32_t[1]")
local function VirtualProtect(address, size, newprotect)
	return ffi.C.VirtualProtect(address, size, newprotect, m_OldProtect)
end

local m_NtOpenFile = ffi.cast("uint8_t*", mem.FindPattern("csgo.exe", "1B F6 45 0C 20") - 0x1)

gui.Button(m_Window, "Load", function()
    local dllname = m_DllFiles[m_Combo:GetValue() + 1]
    if (ffi.C.GetModuleHandleA(dllname) == 0) then
        local oldvalue = m_NtOpenFile[0]

        if (VirtualProtect(m_NtOpenFile, 0x1, 0x40)) then

            m_NtOpenFile[0] = 0xEB

            ffi.C.LoadLibraryA(m_DllPath .. "\\" .. dllname)

            m_NtOpenFile[0] = oldvalue

            VirtualProtect(m_NtOpenFile, 0x1, m_OldProtect[0])
        end

        client.Command("playvol ui\\beepclear 0.5", true)
    end
end)


callbacks.Register("Draw", function() 
    m_Window:SetActive(m_Menu:IsActive())
end)
