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
cmd.KIND_ID						= 104
	
--游戏人数
cmd.GAME_PLAYER					= 100

--房间名长度
cmd.SERVER_LEN					= 32

--游戏记录长度
cmd.RECORD_LEN					= 4

--占座索引
cmd.SEAT_LEFT1_INDEX            = 0                                 --左一
cmd.SEAT_LEFT2_INDEX            = 1                                 --左二
cmd.SEAT_LEFT3_INDEX            = 2                                 --左三
cmd.SEAT_RIGHT1_INDEX           = 3                                 --右一
cmd.SEAT_RIGHT2_INDEX           = 4                                 --右二
cmd.SEAT_RIGHT3_INDEX           = 5                                 --右三
cmd.MAX_OCCUPY_SEAT_COUNT       = 6                                 --最大占位个数
cmd.SEAT_INVALID_INDEX          = 7                                 --无效索引

--空闲状态
cmd.GAME_SCENE_FREE				= 0
--下注状态
cmd.GAME_SCENE_JETTON			= 100
--游戏结束
cmd.GAME_SCENE_END				= 101

--发牌状态
cmd.GAME_SEND_CARD				= 10
--显示牌点
cmd.GAME_SHOW_POINT				= 11


--区域索引
cmd.ID_TIAN_MEN					= 1									--天
cmd.ID_DI_MEN					= 2									--地
cmd.ID_XUAN_MEN					= 3									--玄
cmd.ID_HUANG_MEN				= 4									--黄

cmd.AREA_COUNT					= 4									--区域数目

--服务器命令结构
cmd.SUB_S_GAME_FREE				= 99								--游戏空闲
cmd.SUB_S_GAME_START			= 100								--游戏开始							
cmd.SUB_S_PLACE_JETTON			= 101								--用户下注	
cmd.SUB_S_GAME_END				= 102								--游戏结束	
cmd.SUB_S_APPLY_BANKER			= 103								--申请庄家	
cmd.SUB_S_CHANGE_BANKER			= 104								--切换庄家
cmd.SUB_S_CHANGE_USER_SCORE		= 105								--更新积分			
cmd.SUB_S_SEND_RECORD			= 106								--游戏记录
cmd.SUB_S_PLACE_JETTON_FAIL		= 107								--下注失败
cmd.SUB_S_CANCEL_BANKER			= 108								--取消申请

cmd.SUB_S_ADVANCE_OPENCARD		= 113								--提前开牌
cmd.SUB_S_SUPERROB_BANKER		= 114								--超级抢庄
cmd.SUB_S_CURSUPERROB_LEAVE		= 115								--超级抢庄玩家离开

cmd.SUB_S_OCCUPYSEAT            = 116								--占位
cmd.SUB_S_OCCUPYSEAT_FAIL       = 117								--占位失败
cmd.SUB_S_UPDATE_OCCUPYSEAT     = 118								--更新占位


--超级抢庄配置

--超级抢庄
cmd.SUPERBANKER_VIPTYPE = 0;
cmd.SUPERBANKER_CONSUMETYPE = 1;

--会员
cmd.VIP1_INDEX = 1;
cmd.VIP2_INDEX = 2;
cmd.VIP3_INDEX = 3;
cmd.VIP4_INDEX = 4;
cmd.VIP5_INDEX = 5;
cmd.VIP_INVALID = 6;

--配置结构
cmd.SUPERBANKERCONFIG = 
{
    --抢庄类型
    {k = "superbankerType", t = "int"},
    --vip索引
    {k = "enVipIndex", t = "int"},
    --抢庄消耗
    {k = "lSuperBankerConsume", t = "score"},
}

--当前庄家类型
cmd.ORDINARY_BANKER = 0;    --普通玩家
cmd.SUPERROB_BANKER = 1;    --超级抢庄玩家
cmd.INVALID_SYSBANKER = 2;  --无效类型(系统庄家)
------

------
--占位配置
cmd.OCCUPYSEAT_VIPTYPE = 0          --会员占位
cmd.OCCUPYSEAT_CONSUMETYPE = 1      --消耗金币占位
cmd.OCCUPYSEAT_FREETYPE = 2         --免费占位

--记录信息
cmd.tagServerGameRecord = 
{	
	{k = "bWinTianMen", t = "bool"},		--天门胜利
	{k = "bWinDiMen", t = "bool"},			--地门胜利
	{k = "bWinXuanMen", t = "bool"},		--玄门胜利
	{k = "bWinHuangMen", t = "bool"},		--黄门胜利
}

--占位配置结构
cmd.OCCUPYSEATCONFIG = 
{
    --占位类型
    {k = "occupyseatType", t = "int"},
    --vip索引
    {k = "enVipIndex", t = "int"},
    --占位消耗
    {k = "lOccupySeatConsume", t = "score"},
    --免费占位金币上限
    {k = "lOccupySeatFree", t = "score"},
    --强制站立条件
    {k = "lForceStandUpCondition", t = "score"},
}

--超级抢庄
cmd.CMD_S_SuperRobBanker = 
{
    {k = "bSucceed", t = "bool"},
    {k = "wApplySuperRobUser", t = "word"},     		--申请玩家
    {k = "wCurSuperRobBankerUser", t = "word"},			--当前玩家
}

--超级抢庄玩家离开
cmd.CMD_S_CurSuperRobLeave = 
{
    {k = "wCurSuperRobBankerUser", t = "word"},
}

--下注失败
cmd.CMD_S_PlaceJettonFail =
{
	{k = "wPlaceUser", t = "word"},						--下注玩家
	{k = "lJettonArea", t = "byte"},					--下注区域
	{k = "lPlaceScore", t = "score"},					--当前下注
}

--更新积分
cmd.CMD_S_ChangeUserScore =
{
	{k = "wChairID", t = "word"},						--椅子号码
	{k = "lScore", t = "double"},						--玩家积分
	{k = "wCurrentBankerChairID", t = "word"},			--当前庄家
	{k = "cbBankerTime", t = "byte"},					--庄家局数
	{k = "lCurrentBankerScore", t = "double"},			--庄家分数
}

--申请庄家
cmd.CMD_S_ApplyBanker =
{
	{k = "wApplyUser", t = "word"},						--申请玩家
}

--取消申请
cmd.CMD_S_CancelBanker =
{
	{k = "wCancelUser", t = "word"},					--取消玩家
}

--切换庄家
cmd.CMD_S_ChangeBanker =
{
	{k = "wBankerUser", t = "word"},					--当庄玩家
	{k = "lBankerScore", t = "score"},					--庄家金币
}

--游戏状态
cmd.CMD_S_StatusFree =
{
	--全局信息
	{k = "cbTimeLeave", t = "byte"},								--剩余时间

	--玩家信息
	{k = "lUserMaxScore", t = "score"},								--玩家金币

	--庄家信息
	{k = "wBankerUser", t = "word"},								--当前庄家
	{k = "cbBankerTime", t = "word"},								--庄家局数
	{k = "lBankerWinScore", t = "score"},							--庄家成绩
	{k = "lBankerScore", t = "score"},								--庄家分数
	{k = "nEndGameMul", t = "int"},									--提前开牌百分比
	{k = "bEnableSysbanker", t = "bool"},							--系统坐庄

	--控制信息
	{k = "lApplyBankerCondition", t = "score"},						--申请条件	
	{k = "lAreaLimitScore", t = "score"},							--区域限制

	--房间信息
	{k = "szGameRoomName", t = "string", s = cmd.SERVER_LEN},		--房间名称
	{k = "bGenreEducate", t = "bool"},								--练习模式
	--抢庄配置
    {k = "superbankerConfig", t = "table", d = cmd.SUPERBANKERCONFIG}, 
    {k = "wCurSuperRobBankerUser", t = "word"},
    --庄家类型
    {k = "typeCurrentBanker", t = "int"},

    --占位配置
    {k = "occupyseatConfig", t = "table", d = cmd.OCCUPYSEATCONFIG},
    --占位椅子id MAX_OCCUPY_SEAT_COUNT
    {k = "wOccupySeatChairID", t = "word", l = {cmd.MAX_OCCUPY_SEAT_COUNT}},
}

--游戏状态
cmd.CMD_S_StatusPlay =
{
	--全局下注
	{k = "lAllJettonScore", t = "score", l = {cmd.AREA_COUNT+1}},	--全体总注
	--玩家下注
	{k = "lUserJettonScore", t = "score", l = {cmd.AREA_COUNT+1}},	--个人总注

	--玩家积分
	{k = "lUserMaxScore", t = "score"},								--最大下注

	--控制信息
	{k = "lApplyBankerCondition", t = "score"},						--申请条件	
	{k = "lAreaLimitScore", t = "score"},							--区域限制

	--扑克信息
	{k = "cbTableCardArray", t = "byte", l = {5, 5, 5, 5, 5}},				--桌面扑克

	--庄家信息
	{k = "wBankerUser", t = "word"},								--当前庄家
	{k = "cbBankerTime", t = "word"},								--庄家局数
	{k = "lBankerWinScore", t = "score"},							--庄家成绩
	{k = "lBankerScore", t = "score"},								--庄家分数
	{k = "nEndGameMul", t = "int"},									--提前开牌百分比
	{k = "bEnableSysbanker", t = "bool"},							--系统坐庄

	--结束信息
	{k = "lEndBankerScore", t = "score"},							--庄家成绩
	{k = "lEndUserScore", t = "score"},								--玩家成绩
	{k = "lEndUserReturnScore", t = "score"},						--返回积分
	{k = "lEndRevenue", t = "score"},								--游戏税收

	--全局信息
	{k = "cbTimeLeave", t = "byte"},								--剩余时间
	{k = "cbGameStatus", t = "byte"},								--游戏状态

	--房间信息
	{k = "szGameRoomName", t = "string", s = cmd.SERVER_LEN},		--房间名称
	{k = "bGenreEducate", t = "bool"},								--练习模式
	--抢庄配置
    {k = "superbankerConfig", t = "table", d = cmd.SUPERBANKERCONFIG}, 
    {k = "wCurSuperRobBankerUser", t = "word"},
    --庄家类型
    {k = "typeCurrentBanker", t = "int"},

    --占位配置
    {k = "occupyseatConfig", t = "table", d = cmd.OCCUPYSEATCONFIG},
    --占位椅子id MAX_OCCUPY_SEAT_COUNT
    {k = "wOccupySeatChairID", t = "word", l = {cmd.MAX_OCCUPY_SEAT_COUNT}},
    --占位玩家成绩
    {k = "lOccupySeatUserWinScore", t = "score", l = {cmd.MAX_OCCUPY_SEAT_COUNT}},
}

--游戏空闲
cmd.CMD_S_GameFree =
{
	{k = "cbTimeLeave", t = "byte"},					--剩余时间
	{k = "nListUserCount", t = "score"},				--列表人数
	{k = "lStorageStart", t = "score"},					
}

--游戏开始
cmd.CMD_S_GameStart =
{
	{k = "wBankerUser", t = "word"},								--庄家位置
	{k = "lBankerScore", t = "score"},								--庄家金币
	{k = "lUserMaxScore", t = "score"},								--我的金币
	{k = "cbTimeLeave", t = "byte"},								--剩余时间
	{k = "bContinueCard", t = "bool"},								--继续发牌
	{k = "nChipRobotCount", t = "int"},								--人数上限(下注机器人)
	{k = "nAndroidApplyCount", t = "int"},							--机器人列表人数
	{k = "szGameRoomName", t = "string", s = cmd.SERVER_LEN},		--房间名称
}

--用户下注
cmd.CMD_S_PlaceJetton =
{
	{k = "wChairID", t = "word"},						--用户位置
	{k = "cbJettonArea", t = "byte"},					--筹码区域
	{k = "lJettonScore", t = "score"},					--加注数目	
	{k = "bIsAndroid", t = "bool"},						--是否机器人
	{k = "bAndroid", t = "bool"},						--机器标识	
}

--游戏结束
cmd.CMD_S_GameEnd =
{
	--下局信息
	{k = "cbTimeLeave", t = "byte"},					--剩余时间
	--扑克信息
	{k = "cbTableCardArray", t = "byte", l = {5, 5, 5, 5, 5}},	--桌面扑克	
	{k = "cbLeftCardCount", t = "byte"},				--扑克数目
	{k = "bcFirstCard", t = "byte"},

	--庄家信息
	{k = "lBankerScore", t = "score"},					--庄家成绩
	{k = "lBankerTotallScore", t = "score"},			--庄家总成绩
	{k = "nBankerTime", t = "int"},						--坐庄次数

	--玩家成绩
	{k = "lUserScore", t = "score"},					--玩家成绩
	{k = "lUserReturnScore", t = "score"},				--返回积分

	--全局信息
	{k = "lRevenue", t = "score"},						--游戏税收

	--占位玩家成绩
    {k = "lOccupySeatUserWinScore", t = "score", l = {cmd.MAX_OCCUPY_SEAT_COUNT}},
}

--占位
cmd.CMD_S_OccupySeat = 
{
    --申请占位玩家id
    {k = "wOccupySeatChairID", t = "word"},
    --占位索引
    {k = "cbOccupySeatIndex", t = "byte"},
    --占位椅子id
    {k = "tabWOccupySeatChairID", t = "word", l = {cmd.MAX_OCCUPY_SEAT_COUNT}},
}

--占位失败
cmd.CMD_S_OccupySeat_Fail = 
{
    --已申请占位玩家ID
    {k = "wAlreadyOccupySeatChairID", t = "word"},
    --已占位索引
    {k = "cbAlreadyOccupySeatIndex", t = "byte"},
    --占位椅子id
    {k = "tabWOccupySeatChairID", t = "word", l = {cmd.MAX_OCCUPY_SEAT_COUNT}},
}

--更新占位
cmd.CMD_S_UpdateOccupySeat = 
{
    --占位椅子id
    {k = "tabWOccupySeatChairID", t = "word", l = {cmd.MAX_OCCUPY_SEAT_COUNT}},
    --申请退出占位玩家
    {k = "wQuitOccupySeatChairID", t = "word"},
}

------客户端命令结构----
cmd.SUB_C_PLACE_JETTON			= 1						--用户下注
cmd.SUB_C_APPLY_BANKER			= 2						--申请庄家
cmd.SUB_C_CANCEL_BANKER			= 3						--取消申请
cmd.SUB_C_CONTINUE_CARD			= 4						--继续发牌

cmd.SUB_C_SUPERROB_BANKER		= 7						--超级抢庄
cmd.SUB_C_OCCUPYSEAT			= 8						--占位
cmd.SUB_C_QUIT_OCCUPYSEAT		= 9						--退出占位

--下注
cmd.CMD_C_PlaceJetton = 
{
	{k = "cbJettonArea", t = "byte"},					--筹码区域
	{k = "lJettonScore", t = "score"},					--加注数目
}

--占位
cmd.CMD_C_OccupySeat = 
{
    --占位玩家
    {k = "wOccupySeatChairID", t = "word"},
    --占位索引
    {k = "cbOccupySeatIndex", t = "byte"},
}

---GameDefine

--申请列表
function cmd.getEmptyApplyInfo(  )
    return
    {
        --用户信息
        m_userItem = {},
        --是否当前庄家
        m_bCurrent = false,
        --编号
        m_llIdx = 0,
        --是否超级抢庄
        m_bRob = false
    }
end

--获取空路单记录
function cmd.getEmptyGameRecord()
	return
	{
		bWinTianMen = false,		--天门胜利
		bWinDiMen = false,			--地门胜利
		bWinXuanMen = false,		--玄门胜利
		bWinHuangMen = false
	}
end

return cmd 