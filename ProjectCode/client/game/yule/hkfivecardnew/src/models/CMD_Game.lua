local cmd = {}

--[[
******
* 结构体描述
* {k = "key", t = "type", s = len, l = {}}
* k 表示字段名,对应C++结构体变量名
* t 表示字段类型,对应C++结构体变量类型
* s 针对string变量特有,描述长度
* l 针对数组特有,描述数组长度,以table形式,一维数组表示为{N},N表示数组长度,多维数组表示为{N,N},N表示数组长度
* d 针对table类型,即该字段为一个table类型
* ptr 针对数组,此时s必须为实际长度

** egg
* 取数据的时候,针对一维数组,假如有字段描述为 {k = "a", t = "byte", l = {3}}
* 则表示为 变量a为一个byte型数组,长度为3
* 取第一个值的方式为 a[1][1],第二个值a[1][2],依此类推

* 取数据的时候,针对二维数组,假如有字段描述为 {k = "a", t = "byte", l = {3,3}}
* 则表示为 变量a为一个byte型二维数组,长度都为3
* 则取第一个数组的第一个数据的方式为 a[1][1], 取第二个数组的第一个数据的方式为 a[2][1]
******
]]

--游戏版本
cmd.VERSION 					= appdf.VersionValue(6,7,0,1)
--游戏标识
cmd.KIND_ID						= 25
	
--游戏人数
cmd.GAME_PLAYER					= 5

--房间名长度
cmd.SERVER_LEN					= 32

--游戏记录长度
cmd.RECORD_LEN					= 5

--视图位置
cmd.MY_VIEWID					= 3

--状态定义
cmd.GAME_SCENE_FREE             = 0   --等待开始
cmd.GAME_SCENE_PLAY             = 100   --游戏开始

--命令定义
cmd.SUB_S_GAME_START            = 100               --游戏开始
cmd.SUB_S_ADD_SCORE             = 101               --用户加注
cmd.SUB_S_GIVE_UP               = 102               --用户放弃
cmd.SUB_S_SEND_CARD             = 103               --发送扑克
cmd.SUB_S_GAME_END              = 104               --游戏结束
cmd.SUB_S_GET_WINNER            = 105               --获取信息
cmd.SUB_S_TRUE_END              = 106               --结束消息

--****************定时器标识******************--
--开始定时器
cmd.IDI_START_GAME              = 200
--加注定时器
cmd.IDI_USER_ADD_SCORE          = 201
--选比牌用户定时器
cmd.IDI_USER_COMPARE_CARD       = 202
--过滤定时器
cmd.IDI_DISABLE                 = 203
--*****************时间标识*****************--
--开始定时器
cmd.TIME_START_GAME             = 30
--加注定时器
cmd.TIME_USER_ADD_SCORE         = 30
--比牌定时器
cmd.TIME_USER_COMPARE_CARD      = 30

--空闲状态
cmd.CMD_S_SatatusFree   =
{
    --游戏属性
    {k="lCellScore",t="int"},                           --基础积分
    --历史积分
    {k="lTurnScore",t="score",l={cmd.GAME_PLAYER}},       --积分信息
    {k="lCollectScore",t="score",l={cmd.GAME_PLAYER}},    --积分信息
    --机器人信息
    {k="lRobotScoreMin",t="score"},                     --积分低于取款
    {k="lRobotScoreMax",t="score"},                     --积分高于存款
    {k="lRobotBankTake",t="score",l={2}},                 --取款额度
    {k="lRobotBankSave",t="score"}                      --存款额度
}

--游戏状态
cmd.CMD_S_SatatusPlay   =
{
    --游戏属性
    {k="lCellScore",t="int"},                           --基础积分
    {k="lServiceCharge",t="int"},                       --服务费
    --加注信息
    {k="lDrawMaxScore",t="score"},                      --最大下注
    {k="lTurnMaxScore",t="score"},                      --最大下注
    {k="lTurnLessScore",t="score"},                     --最小下注
    {k="lUserScore",t="score",l={cmd.GAME_PLAYER}},     --用户下注
    {k="lTableScore",t="score",l={cmd.GAME_PLAYER}},    --桌面下注
    --状态信息
    {k="cbShowHand",t="byte"},                          --梭哈标志
    {k="wCurrentUser",t="word"},                        --当前玩家
    {k="cbPlayStatus",t="byte",l={cmd.GAME_PLAYER}},    --游戏状态
    --扑克信息
    {k="cbCardCount",t="byte",l={cmd.GAME_PLAYER}},      --扑克数目
    {k="cbHandCardData",t="byte",l={cmd.GAME_PLAYER,cmd.GAME_PLAYER,cmd.GAME_PLAYER,cmd.GAME_PLAYER,cmd.GAME_PLAYER}}, --桌面扑克
    --历史积分
    {k="lTurnScore",t="score",l={cmd.GAME_PLAYER}},      --积分信息 
    {k="lCollectScore",t="score",l={cmd.GAME_PLAYER}},   --积分信息
    --机器人信息
    {k="lRobotScoreMin",t="score"},                     --积分低于取款
    {k="lRobotScoreMax",t="score"},                     --积分高于存款
    {k="lRobotBankTake",t="score",l={2}},                 --取款额度
    {k="lRobotBankSave",t="score"}                      --存款额度
}

--游戏开始
cmd.CMD_S_GAMEStart =
{
    --游戏属性
    {k="lCellScore",t="int"},                           --单位下注
    {k="lServiceCharge",t="int"},                       --服务费
    --下注信息
    {k="lDrawMaxScore",t="score"},                      --最大下注
    {k="lTurnMaxScore",t="score"},                      --最大下注
    {k="lTurnLessScore",t="score"},                     --最小下注
    --用户信息
    {k="wCurrentUser",t="word"},                        --当前玩家
    --扑克数据
    {k="cbObscureCard",t="byte"},                       --底牌扑克
    {k="cbCardData",t="byte",l={cmd.GAME_PLAYER}},      --用户扑克
    {k="cbHandCardData",t="byte",l={cmd.GAME_PLAYER,cmd.GAME_PLAYER,cmd.GAME_PLAYER,cmd.GAME_PLAYER,cmd.GAME_PLAYER}} --用户扑克
}

--用户放弃
cmd.CMD_S_GiveUp    =
{
    {k="wGiveUpUser",t="word"},                         --放弃用户
    {k="wCurrentUser",t="word"},                        --当前用户
    {k="lDrawMaxScore",t="score"},                      --最大下注
    {k="lTurnMaxScore",t="score"}                       --最大下注
}

--用户下注
cmd.CMD_S_AddScore  =
{
    {k="wCurrentUser",t="word"},                        --当前用户
    {k="wAddScoreUser",t="word"},                       --加注用户
    {k="lTurnLessScore",t="score"},                     --最少加注
    {k="lUserScoreCount",t="score"},                    --加注数目
}

--发送扑克
cmd.CMD_S_SendScore  =
{
    --游戏信息
    {k="wCurrentUser",t="word"},                        --当前用户
    {k="wStartChairID",t="word"},                       --开始用户
    {k="lTurnMaxScore",t="score"},                      --最大下注
    --扑克信息
    {k="cbSendCardCount",t="byte"},                     --发牌数目
    {k="cbCardData",t="byte",l={cmd.GAME_PLAYER,cmd.GAME_PLAYER}}      --发牌数目
}

--游戏结束
cmd.CMD_S_GameEnd    =
{
    {k="cbCardData",t="byte",l={cmd.GAME_PLAYER}},      --用户扑克
    {k="lGameScore",t="score",l={cmd.GAME_PLAYER}},     --游戏积分
    {k="cbDelayOverGame",t="byte"}
}

--获取赢家
cmd.CMD_S_GetWinner =
{
    {k="wOrderCount",t="word"},                         --玩家数
    {k="wChairOrder",t="word",l={GAME_PLAYER}}          --玩家名次
}

--命令定义
cmd.SUB_C_GIVE_UP               = 1                     --用户放弃
cmd.SUB_C_ADD_SCORE             = 2                     --用户加注
cmd.SUB_C_GET_WINNER            = 3                     --获取信息
cmd.SUB_C_ADD_SCORE_TIME        = 4                     --完成动画

--用户加注
cmd.CMD_C_AddScore  =
{
    {k="lScore",t="score"}
}

cmd.RES_PATH 					= 	"game/yule/hkfivecardnew/res/"
print("********************************************************load cmd");
return cmd