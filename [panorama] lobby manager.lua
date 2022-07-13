local function Register_HandleChatCommand()
    panorama.RunScript([[

        var m_gResponseChat = function(msg)
        {
            msg = msg.split(' ').join('\u{00A0}')
            PartyListAPI.SessionCommand('Game::Chat', 'run all xuid ' + MyPersonaAPI.GetXuid() + ' chat ->\u2029' + msg);
        }

        var m_gFindPlayer = function(str)
        {
            // Name
            for (var i=0; PartyListAPI.GetCount() > i; ++i) 
            {
                var xuid        = PartyListAPI.GetXuidByIndex(i);
                var username    = PartyListAPI.GetFriendName(xuid);
                if (username.toLowerCase().indexOf(str) != -1) 
                    return username;
            }

            // Index
            for (var i=0; PartyListAPI.GetCount() > i; ++i) 
            {
                if (parseInt(str) == i) 
                    return PartyListAPI.GetFriendName(PartyListAPI.GetXuidByIndex(i));
            }

            return '';
        }

        var m_gHandleChatCommand = function(username, msg)
        {
            var args = msg.toLowerCase().split(' ');
            var target = (args.length > 1 ? m_gFindPlayer(args[1]) : username)
            if (target.length == 0) target = username;

            if (args[0] == '!help' || args[0] == '!cmds')
            {
                var cmds = [ 
                    '!iq <partial:name>|<lobbyindex>', '!dick <partial:name>|<lobbyindex>', '!gay <partial:name>|<lobbyindex>',
                    '!8ball <question>',
                    '!loc <partial:name>',
                    '!startq (start queue)', '!stopq (stop queue)', 
                    '!norris (chuck norris joke)',
                ];

                msg = '\u2029';
                for (var i = 0; cmds.length > i; ++i)
                    msg += cmds[i] + '\u2029';

                return m_gResponseChat(msg);
            }

            if (args[0] == '!iq')
                return m_gResponseChat('IQ of ' + target + ' is ' +  Math.floor(Math.random() * 420) + '.');

            if (args[0] == '!dick')
                return m_gResponseChat('Dick size of ' + target + ' is ' +  Math.floor(Math.random() * 40) + ' cm.');

            if (args[0] == '!gay')
                return m_gResponseChat(target + ' is ' +  Math.floor(Math.random() * 101) + '% gay.');

            if (args[0] == '!8ball')
            {
                if (args.length > 1 && args[1].length > 1)
                {
                    var array = [ 
                        'It is certain.', 'It is decidedly so.', 'Without a doubt.', 'Yes definitely.', 'You may rely on it.', 'As I see it, yes.', 'Most likely.', 'Outlook good.', 'Yes.', 'Signs point to yes.',
                        'Reply hazy, try again.', 'Ask again later.', 'Better not tell you now.', 'Cannot predict now.', 'Concentrate and ask again.',
                        'Don\'t count on it.', 'My reply is no.', 'My sources say no.', 'Outlook not so good.', 'Very doubtful.'
                    ];

                    m_gResponseChat('[❽] ' + array[Math.floor(Math.random() * array.length)]);
                }
                else
                    m_gResponseChat('[❽] Maybe ask some question?');

                return;
            }
                
            if (args[0] == '!loc')
            {
                msg = '';

                var settings = LobbyAPI.GetSessionSettings();
                for (var i = 0; settings.members.numMachines > i; ++i) 
                {
                    var player = settings.members[`machine${i}`];

                    if (args.length > 1)
                    {
                        if (player.player0.name.toLowerCase().indexOf(target) != -1)
                        {
                            msg = player.player0.name + ' is from ' + player.player0.game.loc;
                            break;
                        }
                    }
                    else
                        msg += player.player0.name + ' is from ' + player.player0.game.loc + '\u2029';
                }

                return m_gResponseChat(msg);
            }

            if (args[0] == '!startq')
                return LobbyAPI.StartMatchmaking( '', '', '', '' );

            if (args[0] == '!stopq')
                return LobbyAPI.StopMatchmaking();

            if (args[0] == '!norris')
            {
                $.AsyncWebRequest('https://api.chucknorris.io/jokes/random', 
                { 
                    type: "GET", complete:function(e) 
                    {
                        if (e.status == 200) 
                            m_gResponseChat(JSON.parse(e.responseText.substring(0, e.responseText.length - 1)).value)
                    }
                });
                return;
            }
        }

    ]])
end

local function Register_HandleChatMessage()
    panorama.RunScript([[

        var m_gHandleChatMessage = function(should_handle)
        { 
            var m_gPartyChat = $.GetContextPanel().FindChildTraverse("PartyChat")
            if (!m_gPartyChat) return;
            
            var m_gChatLines = m_gPartyChat.FindChildTraverse("ChatLinesContainer")
            if (!m_gChatLines) return;
            
            m_gChatLines.Children().forEach(el => 
            {
                var child = el.GetChild(0)
                if (child && child.BHasClass('left-right-flow') && child.BHasClass('horizontal-align-left')) 
                {
                    if (!child.BHasClass('aw_handled')) 
                    {
                        child.AddClass('aw_handled');

                        try 
                        {
                            var InnerChild = child.GetChild(child.GetChildCount() - 1);
                            if (InnerChild && InnerChild.text) 
                            {
                                var Sender = $.Localize('{s:player_name}', InnerChild);
                                var Message = $.Localize('{s:msg}', InnerChild);
                                if (should_handle && Message[0] == '!')
                                    m_gHandleChatCommand(Sender, Message);
                            }
                        } 
                        catch(err) { }
                    }
                }
            })
        }

        // set old msgs as handled
        m_gHandleChatMessage(false);
    ]])
end

-- Functions
local function IsInGame()
    if (entities.GetByIndex(0) == nil) then 
        return false 
    end

    return true
end

-- Variables
local m_NextChatMessageCheck = 0.0

-- GUI
local m_Tab         = gui.Tab(gui.Reference("Settings"), "lobbymgr_tab", "[PANORAMA] Lobby Manager")

local m_Options     = gui.Groupbox(m_Tab, "Options", 16, 16, 300)
local m_AutoAccept          = gui.Checkbox(m_Options, "lobbymgr_autoaccept", "Auto-Accept", true)
local m_AutoAcceptValue     = false
local m_Commands            = gui.Checkbox(m_Options, "lobbymgr_commands", "Commands", true)
gui.Button(m_Options, "Create Session", function() panorama.RunScript("FriendsListAPI.ActionInviteFriend('0', '');") end)

local m_Troll       = gui.Groupbox(m_Tab, "Troll", 300 + 16 + 5, 16, 300)
local m_PlayerIndex = gui.Slider(m_Troll, "lobbymgr_playerindex", "Player Index (Host - 0)", 0, 0, 4)
local m_ActionType  = gui.Listbox(m_Troll, "lobbymgr_actiontype", 125, "VAC ban", "Red Trust Factor", "Yellow Trust Factor")
gui.Button(m_Troll, "Action", function()
    local m_ActionTypeValue = m_ActionType:GetValue()

    if (m_ActionTypeValue == 0) then
        panorama.RunScript("PartyListAPI.SessionCommand('Game::ChatReportError', 'run all xuid ' + PartyListAPI.GetXuidByIndex(" .. m_PlayerIndex:GetValue() .. ") + ' error #SFUI_QMM_ERROR_X_VacBanned');")
    elseif (m_ActionTypeValue == 1) then
        panorama.RunScript("PartyListAPI.SessionCommand('Game::ChatReportError', 'run all xuid ' + PartyListAPI.GetXuidByIndex(" .. m_PlayerIndex:GetValue() .. ") + ' error #SFUI_QMM_ERROR_X_AccountWarningTrustMajor');")
    elseif (m_ActionTypeValue == 2) then
        panorama.RunScript("PartyListAPI.SessionCommand('Game::ChatReportYellow', 'run all xuid ' + PartyListAPI.GetXuidByIndex(" .. m_PlayerIndex:GetValue() .. ") + ' yellow #SFUI_QMM_ERROR_X_AccountWarningTrustMinor');")
    end
end)

gui.Button(m_Troll, "Spam Popup", function()
    for i=1,100 do
        panorama.RunScript("PartyListAPI.SessionCommand('Game::HostEndGamePlayAgain', 'run all xuid ' + MyPersonaAPI.GetXuid());")
    end
end)

gui.Button(m_Troll, "Close Popups", function()
    panorama.RunScript("UiToolkitAPI.CloseAllVisiblePopups();")
end)

local m_RegisterHandles = true
callbacks.Register("Draw", function()
    if (IsInGame()) then 
        m_RegisterHandles = true
        return 
    end

    if (m_RegisterHandles) then
        m_RegisterHandles = false

        Register_HandleChatCommand()
        Register_HandleChatMessage()

        m_AutoAcceptValue = (not m_AutoAccept:GetValue())
    end
    
    local m_RealTime = globals.RealTime()
    if (m_RealTime > m_NextChatMessageCheck) then
        m_NextChatMessageCheck = m_RealTime + 0.1
        panorama.RunScript("m_gHandleChatMessage(" .. tostring(m_Commands:GetValue()) .. ");")
    end

    if (m_AutoAccept:GetValue() ~= m_AutoAcceptValue) then
        m_AutoAcceptValue = m_AutoAccept:GetValue()

        if (m_AutoAcceptValue) then
            panorama.RunScript([[

                var m_gHandleAccept = function() 
                {
                    if (typeof(m_gAcceptTime) == 'undefined' || Date.now() - m_gAcceptTime > 1500)
                    {
                        m_gAcceptTime = Date.now()
                        $.DispatchEvent('MatchAssistedAccept');
                    }
                }

                $.RegisterForUnhandledEvent('PanoramaComponent_Lobby_ReadyUpForMatch', m_gHandleAccept);

            ]])
        else
            panorama.RunScript([[

                m_gHandleAccept = function() { return; }

            ]])
        end
    end
end)
