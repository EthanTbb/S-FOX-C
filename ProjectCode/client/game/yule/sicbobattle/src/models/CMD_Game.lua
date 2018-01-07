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
cmd.KIND_ID						= 118
	
--游戏人数
cmd.GAME_PLAYER					= 100
cmd.GAME_NAME					="百人骰宝"

--游戏记录长度
cmd.RECORD_LEN					= 3

--状态定义
cmd.GS_GAME_FREE				= 0
cmd.GS_GAME_START				= 100									--游戏开始
cmd.GS_PLAYER_BET				= cmd.GS_GAME_START+1					--下注状态
cmd.GS_GAME_END					= cmd.GS_GAME_START+2					--结束状态
cmd.GS_MOVECARD_END				= cmd.GS_GAME_START+3					--结束状态

--区域索引
cmd.ID_AREA_DRAGON				= 0									--龙
cmd.ID_AREA_TIGER				= 1									--虎
cmd.ID_AREA_LEOPARD				= 2									--豹

--玩家索引
cmd.DRAGON_INDEX				= 0									--龙
cmd.TIGER_INDEX					= 1									--虎
cmd.LEOPARD_INDEX				= 2									--豹
cmd.BANKER_INDEX				= 3									--庄

--其它
cmd.AREA_COUNT					= 52								--区域数目
cmd.CARD_COUNT					= 2									--抓牌数目
cmd.DIRECT_COUNT				= 4									--方位数目
cmd.ALL_CARD_COUNT				= 40								--牌堆数目
cmd.MAX_ODDS					= 1									--最大赔率
cmd.JETTON_COUNT				= 6									--筹码种类
cmd.DICE_COUNT					= 3									--骰子个数


--游戏倒计时
cmd.kGAMEFREE_COUNTDOWN			= 1
cmd.kGAMEPLAY_COUNTDOWN			= 2
cmd.kGAMEOVER_COUNTDOWN			= 3
-------------------------------------------------------------------------------------
------
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


--



--银行模块

--下注区域
cmd.g_cbAreaOdds =
{
	1,1,
	8,8,8,8,8,8,
	150,150,150,150,150,150,
	24,
	50,18,14,12,8,6,6,6,6,8,12,14,18,50,
	5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
	3,3,3,3,3,3,
	1,1
};

--筹码面值
cmd.g_lScoreType={500,1000,10000,100000,1000000,5000000};
--筹码光标
cmd.g_nJettonIDI={3000,3001,3002,3003,3004,3005};
--筹码位图
cmd.g_nJettonIDB={3100,3101,3102,3103,3104,3105};
--筹码IDC
cmd.g_nJettonIDC={3200,3201,3202,3203,3204,3205};

--赔率定义
cmd.RATE_TWO_PAIR				= 12								--对子赔率
cmd.SERVER_LEN					= 32								--房间长度

--机器人信息
cmd.tagRobotInfo = 
{
	{k = "nChip",t = "int",l={cmd.JETTON_COUNT}}, 					--筹码定义
	{k = "nAreaChance",t = "int",l={cmd.AREA_COUNT}},				--区域几率
	{k = "szCfgFileName",t = "tchar",l={260}},						--配置文件
	{k = "nMaxTime",t = "int"}										--最大赔率
};
--机器人配置
cmd.tagCustomAndroid = 
{
	--坐庄
	{k = "nEnableRobotBanker",t = "bool"}, 							--是否做庄
	{k = "lRobotBankerCountMin",t = "score"},						--坐庄次数
	{k = "lRobotBankerCountMax",t = "score"},						--坐庄次数
	{k = "lRobotListMinCount",t = "score"},							--列表人数
	{k = "lRobotListMaxCount",t = "score"}, 							--列表人数
	{k = "lRobotApplyBanker",t = "score"},							--最多申请个数
	{k = "lRobotWaitBanker",t = "score"},							--空盘重申

	--下注
	{k = "lRobotMinBetTime",t = "score"},							--下注筹码个数
	{k = "lRobotMaxBetTime",t = "score"},							--下注筹码个数
	{k = "lRobotMinJetton",t = "score"},							--下注筹码金额
	{k = "lRobotMaxJetton",t = "score"},							--下注筹码金额
	{k = "lRobotBetMinCount",t = "score"}, 							--下注机器人数
	{k = "lRobotBetMaxCount",t = "score"},							--下注机器人数
	{k = "lRobotAreaLimit",t = "score"},							--区域限制

	--存取款
	{k = "lRobotScoreMin",t = "score"},								--金币下限
	{k = "lRobotScoreMax",t = "score"},								--金币上限
	{k = "lRobotBankGetMin",t = "score"},							--取款最小值(非庄)
	{k = "lRobotBankGetMax",t = "score"},							--取款最大值(非庄)
	{k = "lRobotBankGetBankerMin",t = "score"}, 					--取款最小值(坐庄)
	{k = "lRobotBankGetBankerMax",t = "score"},						--取款最大值(坐庄)
	{k = "lRobotBankStoMul",t = "score"}							--存款百分比
}
--机器人配置
cmd.tagRobotConfig = 
{
	--上庄操作
	{k = "lBankerCondition",t = "score"}, 							--上庄条件
	--银行操作
	{k = "lBankDrawCondition",t = "score"},							--取款条件
	{k = "lBankDrawScore",t = "score"},								--取款数额
	{k = "lBankSaveCondition",t = "score"},							--存款条件
	{k = "lBankSaveScore",t = "score"}, 							--存款数额

	--庄家操作
	{k = "lBankerDrawCount",t = "score"},							--取款次数 (庄家)
	{k = "lBankerWinGiveUp",t = "score"},							--赢分下庄 (庄家)
	{k = "lBankerLoseGiveUp",t = "score"},							--输分下庄 (庄家)

	--下注操作
	{k = "lJettonLimit",t = "score",l={2}},							--筹码范围
	{k = "lBetTimeLimit",t = "score"},								--下注次数

	--配置人数
	{k = "nCfgRobotCount",t = "int"}								--配置人数
}

--记录信息
cmd.tagGameRecord = 
{
	{k = "cbDiceValue",t = "byte",l={cmd.DICE_COUNT}}				--配置人数
}

--下注信息
cmd.tagUserBet = 
{
	{k = "szNickName",t = "tchar",l={32}},							--用户昵称
	{k = "dwUserGameID",t = "dword"},								--用户ID
	{k = "lUserStartScore",t = "score"},							--用户金币
	{k = "lUserWinLost",t = "score"}, 								--用户金币
	{k = "lUserBet",t = "score",l={cmd.AREA_COUNT}} 				--用户下注
}

--库存控制
cmd.RQ_REFRESH_STORAGE = 		1
cmd.RQ_SET_STORAGE = 			2

--服务器命令结构
cmd.SUB_S_GAME_FREE				= 99								--游戏空闲
cmd.SUB_S_GAME_START			= 100								--游戏开始
cmd.SUB_S_START_BET				= 101
cmd.SUB_S_PLACE_JETTON			= 102								--用户下注
cmd.SUB_S_GAME_END				= 103								--游戏结束
cmd.SUB_S_APPLY_BANKER			= 104								--申请庄家
cmd.SUB_S_CHANGE_BANKER			= 105								--切换庄家
cmd.SUB_S_CHANGE_USER_SCORE		= 106								--更新积分
cmd.SUB_S_SEND_RECORD			= 107								--游戏记录
cmd.SUB_S_PLACE_JETTON_FAIL		= 108								--下注失败
cmd.SUB_S_CANCEL_BANKER			= 109								--取消申请
cmd.SUB_S_ANDROA_AREA			= 110								--WinArea	
cmd.SUB_S_REVOCAT_BET			= 111								--撤销押注
cmd.SUB_S_ROBOT_BANKER			= 112								--上庄通知 (机器人)
cmd.SUB_S_ROBOT_CONFIG			= 113								--配置通知 (机器人)
cmd.SUB_S_AMDIN_COMMAND			= 120								--管理员命令
cmd.SUB_S_SEND_USER_BET_INFO    = 121								--发送下注
cmd.SUB_S_UPDATE_STORAGE        = 122								--更新库存
cmd.SUB_S_CONTROL_WIN			= 123								--控制单个玩家输赢

--控制区域信息
cmd.tagControlInfo = 
{
	{k = "cbControlArea",t = "byte",l={5}}  --控制区域
};

cmd.CMD_C_FreshStorage = 
{
	{k = "cbReqType",t = "byte"}, 									--请求类型
	{k = "lStorageDeduct",t = "score"},								--库存衰减
	{k = "lStorageCurrent",t = "score"},							--当前库存
	{k = "lStorageMax1",t = "score"},								--库存上限1
	{k = "lStorageMul1",t = "score"},								--系统输分概率1
	{k = "lStorageMax2",t = "score"},								--库存上限2
	{k = "lStorageMul2",t = "score"}								--系统输分概率2			
};

--更新库存
cmd.CMD_S_UpdateStorage = 
{
	{k = "cbReqType",t = "byte"}, 									--请求类型
	{k = "lStorageStart",t = "score"},								--起始库存
	{k = "lStorageDeduct",t = "score"},								--库存衰减
	{k = "lStorageCurrent",t = "score"},							--当前库存
	{k = "lStorageMax1",t = "score"},								--库存上限1
	{k = "lStorageMul1",t = "score"},								--系统输分概率1
	{k = "lStorageMax2",t = "score"},								--库存上限2			
	{k = "lStorageMul2",t = "score"}								--系统输分概率2			
};

cmd.CMD_C_ControlWinLose = 
{
	{k = "cbWinLose",t = "byte"}, 									--0为无效值，1为赢，2为输
	{k = "lQueryGameID",t = "score"}								--玩家ID
};

--请求回复
cmd.CMD_S_CommandResult = 
{
	{k = "cbAckType",t = "byte"}, 									--回复类型 1:ACK_SET_WIN_AREA 设置赢的区域，2:ACK_RESET_CONTROL 结果控制 3:ACK_PRINT_SYN 打印
	{k = "cbResult",t = "byte"},									--结果 2:CR_ACCEPT 接受 3:CR_REFUSAL 拒接 4:CR_INVALID 失效
	{k = "cbSicbo1",t = "byte"},									--
	{k = "cbSicbo2",t = "byte"},									--
	{k = "cbSicbo3",t = "byte"},									--
	{k = "cbTotalCount",t = "byte"},								--
	{k = "cbLastType",t = "byte"}									--		

};

cmd.CMD_S_RevocatBet = 
{
	{k = "lUserBet",t = "score",l={cmd.AREA_COUNT}}							
};

cmd.CMD_S_AndroidArea = 
{
	{k = "bWinArea",t = "byte",l={cmd.AREA_COUNT}}
};

cmd.CMD_S_RevocatBet = 
{
	{k = "lUserBet",t = "score",l={cmd.AREA_COUNT}}
};
---------------------------------------------------------------------------------------
--发送下注
cmd.CMD_S_SendUserBetInfo = 
{
	{k = "cbAreaCount",t = "byte"},												--下注区域
	{k = "lUserStartScore",t = "score",l={cmd.GAME_PLAYER}},					--起始分数
	{k = "lUserJettonScore",t = "score",l={cmd.GAME_PLAYER}},					--个人总注
};

--失败结构
cmd.CMD_S_PlaceJettonFail = 
{
	{k = "wPlaceUser",t = "word"},												--下注玩家
	{k = "lJettonArea",t = "byte"},												--下注区域
	{k = "lPlaceScore",t = "score"}												--当前下注

};

--更新积分
cmd.CMD_S_ChangeUserScore = 
{
	{k = "wChairID",t = "word"},												--椅子号码
	{k = "wCurrentBankerChairID",t = "word"},									--当前庄家
	{k = "cbBankerTime",t = "byte"},											--庄家局数
	{k = "lScore",t = "score"},													--玩家积分
	{k = "lCurrentBankerScore",t = "score"}										--庄家分数

};

--申请庄家
cmd.CMD_S_ApplyBanker = 
{
	{k = "wApplyUser",t = "word"}												--申请玩家
};

--取消申请
cmd.CMD_S_CancelBanker = 
{
	{k = "wCancelUser",t = "word"}												--取消玩家
};

--切换庄家
cmd.CMD_S_ChangeBanker = 
{
	{k = "wBankerUser",t = "word"},												--当庄玩家
	{k = "lBankerScore",t = "score"}											--庄家金币
};

--游戏状态（空闲）
cmd.CMD_S_StatusFree = 
{
	--全局信息
	{k = "cbTimeLeave",t = "byte"},												--剩余时间
	--庄家信息
	{k = "wBankerUser",t = "word"},												--当前庄家
	{k = "cbBankerTime",t = "word"},											--庄家局数
	{k = "bEnableSysBanker",t = "bool"},										--系统做庄
	--玩家信息
	{k = "lUserMaxScore",t = "score"},											--玩家金币
	{k = "lBankerWinScore",t = "score"},										--庄家成绩
	{k = "lBankerScore",t = "score"},											--庄家分数
	--控制信息
	{k = "lApplyBankerCondition",t = "score"},									--申请条件
	{k = "lAreaLimitScore",t = "score"},										--区域限制
	--房间信息
	{k = "szGameRoomName",t = "string",s = cmd.SERVER_LEN},						--房间名称
	{k = "CustomAndroid",t = "table",d=cmd.tagCustomAndroid}					--机器人配置
};

--游戏状态(玩)
cmd.CMD_S_StatusPlay = 
{
	--全局下注
	{k = "lAllJettonScore",t = "score",l={cmd.AREA_COUNT}},						--全体总注
	--玩家下注
	{k = "lUserJettonScore",t = "score",l={cmd.AREA_COUNT}},					--个人总注
	--玩家积分
	{k = "lUserMaxScore",t = "score"},											--最大下注
	--控制信息
	{k = "lApplyBankerCondition",t = "score"},									--申请条件
	{k = "lAreaLimitScore",t = "score"},										--区域限制
	--扑克信息
	{k = "cbDiceValue",t = "byte",l={cmd.DICE_COUNT}},							--桌面扑克
	--庄家消息
	{k = "wBankerUser",t = "word"},												--当前庄家
	{k = "cbBankerTime",t = "word"},											--庄家局数
	{k = "lBankerWinScore",t = "score"},										--庄家赢分
	{k = "lBankerScore",t = "score"},											--庄家分数
	{k = "bEnableSysBanker",t = "bool"},										--系统做庄
	--结束信息
	{k = "lEndBankerScore",t = "score"},										--庄家成绩
	{k = "lEndUserScore",t = "score"},											--玩家成绩
	{k = "lEndUserReturnScore",t = "score"},									--返回积分
	{k = "lEndRevenue",t = "int"},												--游戏税收
	--全局信息
	{k = "cbTimeLeave",t = "byte"},												--剩余时间
	{k = "cbGameStatus",t = "byte"},											--游戏状态
	--房间信息
	{k = "szGameRoomName",t = "string",s = cmd.SERVER_LEN},						--房间名称
	{k = "CustomAndroid",t = "table",d=cmd.tagCustomAndroid}					--机器人配置
};

--游戏空闲
cmd.CMD_S_GameFree = 
{
	{k = "cbTimeLeave",t = "byte"},												--剩余时间
	{k = "nListUserCount",t = "int"}											--列表人数
};

--游戏开始
cmd.CMD_S_GameStart = 
{
	{k = "wBankerUser",t = "word"},												--庄家位置
	{k = "cbTimeLeave",t = "byte"},												--剩余时间
	{k = "lBankerScore",t = "score"},											--庄家金币
	{k = "lUserMaxScore",t = "score"},											--庄家金币
	{k = "nChipRobotCount",t = "int"},											--人数上限 (下注机器人)
	{k = "nAndriodApplyCount",t = "int"},										--机器人列表人数
	{k = "bWinFlag",t = "byte",l={cmd.AREA_COUNT}}								--输赢信息 (机器人)
};

--开始下注
cmd.CMD_S_StartBet = 
{
	{k = "cbTimeLeave",t = "byte"}												--剩余时间
};

--用户下注
cmd.CMD_S_PlaceJetton = 
{
	{k = "wChairID",t = "word"},												--用户位置
	{k = "cbJettonArea",t = "byte"},											--筹码区域
	{k = "lJettonScore",t = "score"},											--加注数目
	{k = "bIsAndroid",t = "bool"}												--是否机器人
}; 

--游戏结束
cmd.CMD_S_GameEnd = 
{
	--下局信息
	{k = "cbTimeLeave",t = "byte"},												--剩余时间
	--扑克信息
	{k = "cbDiceValue",t = "byte",l={cmd.DICE_COUNT}},							--骰子点数
	{k = "cbLeftCardCount",t = "byte"},											--扑克数目
	{k = "bcFirstCard",t = "byte"},												
	--庄家信息
	{k = "nBankerTime",t = "int"},												--做庄次数
	{k = "lBankerScore",t = "score"},											--庄家成绩
	{k = "lBankerTotallScore",t = "score"},										--庄家分数
	--玩家成绩
	{k = "lUserScore",t = "score"},												--玩家成绩
	{k = "lUserReturnScore",t = "score"},					--返回积分
	--全局信息
	{k = "lRevenue",t = "int"}								--游戏税收
};

--客户端命令结构

cmd.SUB_C_PLACE_JETTON		=	1							--用户下注
cmd.SUB_C_APPLY_BANKER		=	2							--申请庄家
cmd.SUB_C_CANCEL_BANKER		=	3							--取消申请
cmd.SUB_C_CONTINUE_CARD		=	4							--继续发牌
cmd.SUB_C_AMDIN_COMMAND		=	5							--管理员命令
cmd.SUB_C_STORAGE			=	6							--更新库存
cmd.SUB_C_CONTROL_WIN		=	7							--控制单个玩家输赢
-- cmd.define IDM_ADMIN_STORAGE			WM_USER+1001
-- cmd.define IDM_CONTROL_WIN				WM_USER+1002

--用户下注
cmd.CMD_C_PlaceBet = 
{
	--筹码区域
	{k = "cbBetArea", t = "byte"},
	--加注数目
	{k = "lBetScore", t = "score"}
}
return cmd 