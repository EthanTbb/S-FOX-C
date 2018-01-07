--[[--
游戏命令
]]

local cmd = cmd or {}

--游戏标识
cmd.KIND_ID                 = 238

--游戏人数
cmd.PLAYER_COUNT            = 4
--非法视图
cmd.INVALID_VIEWID          = 0

cmd.INVALID_CHAIRID         = 65535
--左边玩家视图
cmd.LEFT_VIEWID             = 4
--自己玩家视图
cmd.MY_VIEWID               = 1
--右边玩家视图
cmd.RIGHT_VIEWID            = 2
--上面玩家视图
cmd.TOP_VIEWID            = 3


cmd.FULL_COUNT                 = 52                                  --全牌数目
cmd.DISPATCH_COUNT             = 52                                  --发牌数目
cmd.MAX_COUNT                  = 13                                    --地主牌数
cmd.MAX_CARD_COUNT             = 13                                  
cmd.NORMAL_COUNT               = 13                                  --常规牌数
cmd.PUBLIC_CARD_COUNT          = 0                                   --底牌



--游戏状态

cmd.GAME_GAME_FREE            = 0                    --等待开始
cmd.GAME_XUAN_ZHAN            = 100                    --宣战
cmd.GAME_FIND_FRIEND          = 101          --找同盟
cmd.GAME_ASK_FRIEND           = 102          --询问同盟
cmd.GAME_ADD_TIMES            = 103          --加倍
cmd.GAME_SCENE_PLAY           = 104          --游戏进行

--服务器命令结构
cmd.SUB_S_GAME_START        = 100           --游戏开始
cmd.SUB_S_XUAN_ZHAN         = 101           --用户宣战
cmd.SUB_S_FIND_FRIEND       = 102           --用户找同盟
cmd.SUB_S_ASK_FRIEND        = 103           --用户问同盟
cmd.SUB_S_ADD_TIMES         = 104           --用户加倍
cmd.SUB_S_OUT_CARD          = 105           --用户出牌
cmd.SUB_S_PASS_CARD         = 106           --用户放弃
cmd.SUB_S_GAME_CONCLUDE     = 107           --游戏结束
cmd.SUB_S_TRUSTEE           = 108           --用户托管
cmd.SUB_S_SET_BASESCORE     = 109           --设置基数

-- 倒计时
cmd.TAG_COUNTDOWN_READY     = 1
cmd.TAG_COUNTDOWN_DECLAREWAR = 2
cmd.TAG_COUNTDOWN_FIND_FRIEND   = 3
cmd.TAG_COUNTDOWN_ASK_FRIEND   = 4
cmd.TAG_COUNTDOWN_ADD_TIMES   = 5
cmd.TAG_COUNTDOWN_OUTCARD   = 6
-- 游戏倒计时


cmd.COUNTDOWN_READY         = 30            -- 准备倒计时
cmd.COUNTDOWN_DECLAREWAR = 2                -- 宣战倒计时
cmd.COUNTDOWN_FINDFRIEND = 2                -- 寻找好友倒计时
cmd.COUNTDOWN_ASKFRIEND = 2                 -- 询问好友倒计时
cmd.COUNTDOWN_ADDTIME = 2                   -- 加倍倒计时
cmd.COUNTDOWN_OUTCARD       = 20            -- 出牌倒计时
cmd.COUNTDOWN_HANDOUTTIME   = 30            -- 首出倒计时

--询问好友标志
cmd.FRIEDN_FLAG_DECLAREWAR = 1 ----宣战
cmd.FRIEDN_FLAG_MINGDU = 3  ----明独
cmd.FRIEDN_FLAG_NORMAL = 4  ----正常

-- 游戏胜利方
cmd.kDefault                = -1
cmd.kLanderWin              = 0
cmd.kLanderLose             = 1
cmd.kFarmerWin              = 2
cmd.kFarmerLose             = 3

-- 春天标记
cmd.kFlagDefault            = 0
cmd.kFlagChunTian           = 1
cmd.kFlagFanChunTian        = 2
---------------------------------------------------------------------------------------

------
--服务端消息结构
------

--空闲状态
cmd.CMD_S_StatusFree = 
{
    --游戏属性
    {k = "cbTimeStart", t = "byte"}, --开始时间                             --基础积分
    {k = "cbTimeOutCard", t = "byte"},  --出牌时间                        --出牌时间
    {k = "cbTimeXuanZhan", t = "byte"}, --宣战时间

    {k = "cbTimeFindFriend", t = "byte"},  --寻找时间                        --出牌时间
    {k = "cbTimeAskFriend", t = "byte"}, --询问时间 
    {k = "cbTimeAddTimes", t = "byte"},  --加倍时间 

    {k = "b2Biggest", t = "bool"}, --开启2最大                        --叫分时间                     --首出时间

    --历史积分
    {k = "lTurnScore", t = "score", l = {cmd.PLAYER_COUNT}},    --积分信息
    {k = "lCollectScore", t = "score", l = {cmd.PLAYER_COUNT}}, --积分信息

    {k = "lCellScore", t = "int"}, --基础积分
}




--游戏状态
cmd.CMD_S_StatusPlay = 
{
     --游戏属性
    {k = "cbTimeStart", t = "byte"}, --开始时间                             --基础积分
    {k = "cbTimeOutCard", t = "byte"},  --出牌时间                        --出牌时间
    {k = "cbTimeXuanZhan", t = "byte"}, --宣战时间

    {k = "cbTimeFindFriend", t = "byte"},  --寻找时间                        --出牌时间
    {k = "cbTimeAskFriend", t = "byte"}, --询问时间 
    {k = "cbTimeAddTimes", t = "byte"},  --加倍时间 

    {k = "b2Biggest", t = "bool"}, --开启2最大  

    {k = "cbGameStatus", t = "byte"},  --游戏状态
    {k = "bEnabledAskFriend", t = "bool"}, 
    {k = "bEnabledAddTimes", t = "bool"}, 

    --历史积分
    {k = "bTrustee", t = "bool", l = {cmd.PLAYER_COUNT}},  --托管信息
    {k = "lTurnScore", t = "score", l = {cmd.PLAYER_COUNT}}, --积分信息
    {k = "lCollectScore", t = "score", l = {cmd.PLAYER_COUNT}}, --积分信息 
    {k = "cbTunrScore", t = "byte"}, --当前牌分
    {k = "cbGameScore", t = "int", l = {cmd.PLAYER_COUNT}}, --游戏得分
    {k = "bAddTimes", t = "bool", l = {cmd.PLAYER_COUNT}},  --是否加倍
    {k = "wFriend", t = "word", l = {cmd.PLAYER_COUNT}},  --队友  
    {k = "wXuanZhanUser", t = "word"}, --宣战玩家
    --{k = "bMingDu", t = "bool"}, 
    {k = "cbFriendFlag", t = "byte"}, --队友标记 
    --游戏变量
    {k = "lCellScore", t = "int"},                              --单元积分
    {k = "wBankerUser", t = "word"},                            --庄家用户
    {k = "wCurrentUser", t = "word"},                           --当前庄家
    {k = "cbBaseTimes", t = "byte"},                          --基础倍数


    --出牌信息
    {k = "wTurnWiner", t = "word"},                             --胜利玩家
    {k = "cbTurnCardCount", t = "byte"},                        --出牌数目
    {k = "cbTurnCardData", t = "byte", l = {cmd.MAX_COUNT}},    --出牌数据

    --扑克信息
    {k = "cbHandCardData", t = "byte", l = {cmd.MAX_COUNT}},    --手上扑克
    {k = "cbHandCardCount", t = "byte", l = {cmd.PLAYER_COUNT}},--扑克数目
}

--发送扑克/游戏开始
cmd.CMD_S_GameStart = 
{
    {k = "b2Biggest", t = "bool"},                             --开始玩家
    {k = "wBanker", t = "word"},                           
    {k = "wCurrentUser", t = "word"},                        
    {k = "cbCardData", t = "byte", l = {cmd.NORMAL_COUNT}},     
}

--用户宣战
cmd.CMD_S_XuanZhan = 
{
    {k = "wXuanZhanUser", t = "word"},                           --宣战玩家
    {k = "bXuanZhan", t = "bool"},                         --是否宣战玩家
    {k = "wCurrentUser", t = "word"},                         --当前宣战
    {k = "cbFriendFlag", t = "byte"},                        --
}

--用户找同盟
cmd.CMD_S_FindFriend = 
{
    {k = "wFindUser", t = "word"},                           --操作玩家
    {k = "wCurrentUser", t = "word"},                         --当前玩家
    {k = "bEnabled", t = "bool"},                         --庄家能不能问
}

--用户问同盟
cmd.CMD_S_ASKFriend = 
{
    {k = "wAskUser", t = "word"},                           --询问玩家
    {k = "bAsk", t = "bool"},                         
    {k = "wCurrentUser", t = "word"}, 
    {k = "wFriend", t = "word", l = {cmd.PLAYER_COUNT}},     --队友 
    {k = "wXuanZhanUser", t = "word"},     
    {k = "bMingDu", t = "bool"},  
    {k = "cbFriendFlag", t = "byte"},                    
}

--用户加倍
cmd.CMD_S_AddTimes = 
{
    {k = "wAddTimesUser", t = "word"},                           --加倍玩家
    {k = "bAddTimes", t = "bool"},                         
    {k = "wCurrentUser", t = "word"},                         
}



--庄家信息
cmd.CMD_S_BankerInfo = 
{
    {k = "wBankerUser", t = "word"},                            --庄家玩家
    {k = "wCurrentUser", t = "word"},                           --当前玩家
    {k = "cbBankerScore", t = "byte"},                          --庄家叫分
    {k = "cbBankerCard", t = "byte", l = {3}},                  --庄家扑克
}

--用户出牌
cmd.CMD_S_OutCard = 
{
    {k = "cbCardCount", t = "byte"},                            --出牌数目
    {k = "wCurrentUser", t = "word"},                           --当前玩家
    {k = "wOutCardUser", t = "word"},                           --出牌玩家
    {k = "cbCurTurnScore", t = "byte"},                          
    {k = "cbCardData", t = "byte", l = {cmd.MAX_COUNT}},      --扑克列表
    {k = "bTrusteeOut", t = "bool"},                            --是否系统托管出牌
}

--放弃出牌
cmd.CMD_S_PassCard = 
{
    {k = "cbTurnOver", t = "byte"},                             --一轮结束
    {k = "wCurrentUser", t = "word"},                           --当前玩家
    {k = "wPassCardUser", t = "word"},                          --放弃玩家
    {k = "cbTurnWinnerScore", t = "byte"},                      
    {k = "wTurnWinner", t = "word"},                         
    {k = "bTrusteePass", t = "bool"},
}

--用户托管
cmd.CMD_S_Trustee = 
{
    {k = "wChair", t = "word"},                             
    {k = "bTrustee", t = "bool"},                          
}

--游戏结束
cmd.CMD_S_GameConclude = 
{
    --积分变量
    {k = "lCellScore", t = "int"},                              --单元积分
    {k = "lGameScore", t = "score", l = {cmd.PLAYER_COUNT}},    --游戏输赢分
    {k = "cbBaseTimes", t = "byte"},
    {k = "cbScore", t = "int", l = {cmd.PLAYER_COUNT}},     --得分
    {k = "cbUserTimes", t = "byte", l = {cmd.PLAYER_COUNT}},     --玩家倍数
    --游戏信息
    {k = "cbCardCount", t = "byte", l = {cmd.PLAYER_COUNT}},      --扑克数目
    {k = "cbHandCardData", t = "byte", l = {cmd.FULL_COUNT}},   --扑克列表
}

--客户端命令结构
cmd.SUB_C_XUAN_ZHAN        = 1               --用户宣战
cmd.SUB_C_FIND_FRIEND          = 2           --用户选同盟
cmd.SUB_C_ASK_FRIEND         = 3             --用户问同盟
cmd.SUB_C_ADD_TIMES         = 4              --用户加倍                     
cmd.SUB_C_OUT_CARD          = 5              --用户出牌                   
cmd.SUB_C_PASS_CARD         = 6              --用户放弃                                    
cmd.SUB_C_TRUSTEE           = 7              --用户托管                     

------
--客户端消息结构
------

--用户宣战
cmd.CMD_C_XuanZhan = 
{
    {k = "bXuanZhan", t = "bool"},                            --是否宣战
}

--用户找同盟
cmd.CMD_C_FindFriend = 
{
    {k = "cbCardData", t = "byte"},                            --选的牌5,10,k
}

--用户问同盟
cmd.CMD_C_AskFriend = 
{
    {k = "bAsk", t = "bool"},                            --是否问
}

--用户加倍
cmd.CMD_C_AddTimes = 
{
    {k = "bAddTimes", t = "bool"},                            --是否加倍
}

--用户出牌
cmd.CMD_C_OutCard = 
{
    {k = "cbCardCount", t = "byte"},                            --出牌数目
    {k = "cbCardData", t = "byte", l = {cmd.MAX_COUNT}},        --扑克数据
}

cmd.CMD_C_Trustee = 
{
    {k = "bTrustee", t = "bool"},                            --是否托管
}

return cmd