-- engine.dll
local m_FindName    = mem.FindPattern("engine.dll", "55 8B EC 81 EC ?? ?? ?? ?? 53 56 8B F1 57 8B FA 85 F6 75 0E") -- XREF: "S_FindName: NULL"
local m_StartSound  = mem.FindPattern("engine.dll", "55 8B EC 83 E4 C0 A1 ?? ?? ?? ?? 81 EC ?? ?? ?? ?? 53 56 57 8B F9 85 C0") -- XREF: "S_StartSound: %s Stopped."
if (m_FindName == nil or m_StartSound == nil) then error("m_FindName/m_StartSound is nullptr.") end

ffi.cdef([[

    typedef struct
    {
        void* vftable;
        int m_namePoolIndex;
	    void* pSource;
    } CSfxTable;

    typedef struct
    {
        int userdata;
        int soundsource;
	    int entchannel;
	    CSfxTable* pSfx;
	    float origin[3];
	    float direction[3]; 
	    float fvol;
	    int soundlevel;
	    int flags;
	    int pitch; 
	    float delay;
	    int speakerentity;
	    int initialStreamPosition;
	    int skipInitialSamples;
	    int m_nQueuedGUID;
	    unsigned int m_nSoundScriptHash;
	    const char* m_pSoundEntryName;
	    void* m_pOperatorsKV;
	    float opStackElapsedTime;
	    float opStackElapsedStopTime;
	    bool staticsound;
	    bool bUpdatePositions;
	    bool fromserver;
	    bool bToolSound;
	    bool m_bIsScriptHandle;
	    bool m_bDelayedStart;
	    bool m_bInEyeSound;
	    bool m_bHRTFFollowEntity;
	    bool m_bHRTFBilinear;
	    bool m_bHRTFLock;
    } StartSoundParams_t;

]])

m_FindName          = ffi.cast("void*(__fastcall*)(const char*, int*)", m_FindName)
m_StartSound        = ffi.cast("void*(__thiscall*)(StartSoundParams_t&)", m_StartSound)

-- SoundParams
local m_SoundParams = ffi.new("StartSoundParams_t")
m_SoundParams.userdata = 0
m_SoundParams.soundsource = 575
m_SoundParams.entchannel = 0
m_SoundParams.fvol = 1.0
m_SoundParams.soundlevel = 0
m_SoundParams.flags = 0
m_SoundParams.pitch = 100
m_SoundParams.delay = 0.0
m_SoundParams.speakerentity = -1
m_SoundParams.initialStreamPosition = 0
m_SoundParams.skipInitialSamples = 0
m_SoundParams.m_nQueuedGUID = -1
m_SoundParams.m_nSoundScriptHash = -1
m_SoundParams.opStackElapsedTime = 0.0
m_SoundParams.opStackElapsedStopTime = 0.0
m_SoundParams.staticsound  = false
m_SoundParams.bUpdatePositions = true
m_SoundParams.fromserver = false
m_SoundParams.bToolSound = false
m_SoundParams.m_bIsScriptHandle = false
m_SoundParams.m_bDelayedStart = false
m_SoundParams.m_bInEyeSound = true
m_SoundParams.m_bHRTFFollowEntity = false
m_SoundParams.m_bHRTFBilinear = false
m_SoundParams.m_bHRTFLock = false

-- Functions
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

local function PlayHitsound(name, x, y, z)
    m_SoundParams.origin[0] = x
    m_SoundParams.origin[1] = y
    m_SoundParams.origin[2] = z
    m_SoundParams.pSfx = m_FindName("hitsound\\" .. name, nil)
    m_StartSound(m_SoundParams)
end

-- Variables
local m_Sounds = TableStringFilter(GetFiles(GetPath(GetModuleFileNameA(0)) ..  "\\csgo\\sound\\hitsound"), ".wav")

-- GUI
local m_Tab = gui.Tab(gui.Reference("Misc"), "bhitsounds_tab", "Hitsounds")

local m_Groupbox_Hit = gui.Groupbox(m_Tab, "On Hit", 16, 16) m_Groupbox_Hit:SetWidth(300)
local m_Hitsound_Hit                = gui.Combobox(m_Groupbox_Hit, "bhitsounds_hit", "Select", "None", unpack(m_Sounds))
local m_Hitsound_HitVolume          = gui.Slider(m_Groupbox_Hit, "bhitsounds_hitvol", "Volume", 50, 0, 100)
local m_Hitsound_HitPitch           = gui.Slider(m_Groupbox_Hit, "bhitsounds_hitpitch", "Pitch", 0, -25, 25)
local m_Hitsound_Hit3D              = gui.Checkbox(m_Groupbox_Hit, "bhitsounds_hit3d", "3D Sound", false)
local m_Hitsound_Hit3DSndLevel      = gui.Slider(m_Groupbox_Hit, "bhitsounds_hit3dsndlvl", "3D Sound Level", 0, 0, 20)

local m_Groupbox_Death = gui.Groupbox(m_Tab, "On Death", 16, 16) m_Groupbox_Death:SetWidth(300) m_Groupbox_Death:SetPosX(325)
local m_Hitsound_Death              = gui.Combobox(m_Groupbox_Death, "bhitsounds_death", "Select", "None", unpack(m_Sounds))
local m_Hitsound_DeathVolume        = gui.Slider(m_Groupbox_Death, "bhitsounds_deathvol", "Volume", 50, 0, 100)
local m_Hitsound_DeathPitch         = gui.Slider(m_Groupbox_Death, "bhitsounds_deathpitch", "Pitch", 0, -25, 25)
local m_Hitsound_Death3D            = gui.Checkbox(m_Groupbox_Death, "bhitsounds_death3d", "3D Sound", false)
local m_Hitsound_Death3DSndLevel    = gui.Slider(m_Groupbox_Death, "bhitsounds_death3dsndlvl", "3D Sound Level", 0, 0, 20)

if (#m_Sounds == 0) then
    m_Hitsound_Hit:SetInvisible(true)
    m_Hitsound_Death:SetInvisible(true)
    gui.Text(m_Groupbox, "Couldn't find any .wav files inside folder: 'csgo\\sound\\hitsound'.")
end

-- Callback
client.AllowListener("player_death")
callbacks.Register("FireGameEvent", function(event)
    if (event:GetName() ~= "player_hurt") then return end

    local LocalPlayerIndex  = client.GetLocalPlayerIndex()
    local EntityIndex       = client.GetPlayerIndexByUserID(event:GetInt("userid"))
    if (client.GetPlayerIndexByUserID(event:GetInt("attacker")) ~= LocalPlayerIndex or LocalPlayerIndex == EntityIndex) then return end

    local Entity = entities.GetByIndex(EntityIndex)
    if (Entity == nil) then return end

    local Hitsound_Index = m_Hitsound_Death:GetValue()
    local Hitsound_Death = true
    if (event:GetInt("health") ~= 0 or Hitsound_Index == 0) then
        Hitsound_Index = m_Hitsound_Hit:GetValue()
        Hitsound_Death = false
    end

    if (Hitsound_Index ~= 0) then
        local Hitsound_3D       = false 
        local Hitsound_Volume   = (Hitsound_Death and m_Hitsound_DeathVolume:GetValue() or m_Hitsound_HitVolume:GetValue()) * 0.01
        if (Hitsound_Death) then 
            Hitsound_3D = m_Hitsound_Death3D:GetValue()
        else
            Hitsound_3D = m_Hitsound_Hit3D:GetValue()
        end

        m_SoundParams.fvol      = (Hitsound_Death and m_Hitsound_DeathVolume:GetValue() or m_Hitsound_HitVolume:GetValue()) * 0.01
        m_SoundParams.pitch     = 100 + (Hitsound_Death and m_Hitsound_DeathPitch:GetValue() or m_Hitsound_HitPitch:GetValue())

        if (Hitsound_3D) then
            m_SoundParams.soundlevel = 60 + (Hitsound_Death and m_Hitsound_Death3DSndLevel:GetValue() or m_Hitsound_Hit3DSndLevel:GetValue())

            local EntityOrigin = Entity:GetAbsOrigin()
            PlayHitsound(m_Sounds[Hitsound_Index], EntityOrigin.x, EntityOrigin.y, EntityOrigin.z)
        else
            m_SoundParams.soundlevel = 0

            local Origin = entities.GetLocalPlayer():GetAbsOrigin()
            PlayHitsound(m_Sounds[Hitsound_Index], Origin.x, Origin.y, Origin.z)
        end
    end
end)
