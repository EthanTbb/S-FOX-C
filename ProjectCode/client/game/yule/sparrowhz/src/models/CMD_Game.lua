local cmd =  {}

cmd.RES_PATH 				= "game/yule/sparrowhz/res/"
--游戏版本
cmd.VERSION 					= appdf.VersionValue(6,7,0,1)
--游戏标识
cmd.KIND_ID						= 389
--游戏人数
cmd.GAME_PLAYER					= 4
--视图位置(1~3)
cmd.MY_VIEWID					= 3
--最大牌数
cmd.MAX_COUNT 					= 14
--最大库存
cmd.MAX_REPERTORY 				= 112
--最大组合
cmd.MAX_WEAVE 					= 4

-- 语音动画
cmd.VOICE_ANIMATION_KEY = "voice_ani_key"

--********************       定时器标识         ***************--
cmd.IDI_START_GAME				= 201						--开始定时器
cmd.IDI_OUT_CARD				= 202						--出牌定时器
cmd.IDI_OPERATE_CARD			= 203						--操作定时器

--*******************        时间标识         *****************--
--快速出牌时间
cmd.TIME_OUT_CARD_FAST			= 10
--出牌时间
cmd.TIME_OUT_CARD				= 30
--准备时间
cmd.TIME_START_GAME 			= 30


--******************         游戏状态             ************--
--等待开始
cmd.GAME_SCENE_FREE				= 0
--叫庄状态
cmd.GAME_SCENE_PLAY				= 100

--组合子项
cmd.tagWeaveItem = 
{
	{k = "cbWeaveKind", t = "byte"},							--组合类型
	{k = "cbCenterCard", t = "byte"},							--中心扑克
	{k = "cbParam", t = "byte"},								--类型标志
	{k = "wProvideUser", t = "word"},							--供应用户
	{k = "cbCardData", t = "byte", l = {4}},					--麻将数据
}

--空闲状态
cmd.CMD_S_StatusFree = 
{
	--基础积分
	{k = "lCellScore", t = "int"},								--基础积分
	--时间信息
 	{k = "cbTimeOutCard", t = "byte"},							--出牌时间
 	{k = "cbTimeOperateCard", t = "byte"},						--操作时间
 	{k = "cbTimeStartGame", t = "byte"},						--开始时间
	--历史积分
	{k = "lTurnScore", t = "score", l = {cmd.GAME_PLAYER}},		--积分信息
	{k = "lCollectScore", t = "score", l = {cmd.GAME_PLAYER}},	--积分信息
	{k = "cbPlayerCount", t = "byte"},
	{k = "cbMaCount", t = "byte"},
}
--游戏状态
cmd.CMD_S_StatusPlay = 
{
	--时间信息
	{k = "cbTimeOutCard", t = "byte"},							--出牌时间
	{k = "cbTimeOperateCard", t = "byte"},						--叫分时间
	{k = "cbTimeStartGame", t = "byte"},						--开始时间
	--游戏变量
	{k = "lCellScore", t = "score"},							--单元积分
	{k = "wBankerUser", t = "word"},							--庄家用户
	{k = "wCurrentUser", t = "word"},							--当前用户
	{k = "cbMagicIndex", t = "byte"},							--财神索引

	{k = "cbPlayerCount", t = "byte"},
	{k = "cbMaCount", t = "byte"},

	{k = "cbActionCard", t = "byte"},							--动作扑克
	{k = "cbActionMask", t = "byte"},							--动作掩码
	{k = "cbLeftCardCount", t = "byte"},						--剩余数目
	{k = "bTrustee", t = "bool", l = {cmd.GAME_PLAYER}},		--是否托管
	{k = "bTing", t = "bool", l = {cmd.GAME_PLAYER}},			--是否听牌
	{k = "wOutCardUser", t = "word"},							--出牌用户
	{k = "cbOutCardData", t = "byte"},							--出牌扑克
	{k = "cbDiscardCount", t = "byte", l = {cmd.GAME_PLAYER}},	--丢弃数目
	{k = "cbDiscardCard", t = "byte", l = {60,60,60,60}},       --丢弃记录
	{k = "cbCardCount", t = "byte", l = {cmd.GAME_PLAYER}},		--扑克数目
	{k = "cbCardData", t = "byte", l = {cmd.MAX_COUNT}},		--扑克列表
	{k = "cbSendCardData", t = "byte"},							--发送扑克
	{k = "cbWeaveItemCount", t = "byte", l = {cmd.GAME_PLAYER}},--组合数目
	{k = "WeaveItemArray", t = "table", d = cmd.tagWeaveItem, l = {4, 4, 4, 4}},--组合扑克
	{k = "wHeapHead", t = "word"},								--堆立头部
	{k = "wHeapTail", t = "word"},								--堆立尾部
	{k = "cbHeapCardInfo", t = "byte", l = {2, 2, 2, 2}},		--牌堆信息

	--用于提示听牌
	{k = "cbHuCardCount", t = "byte", l = {cmd.MAX_COUNT}},
	{k = "cbHuCardData", t = "byte", l = {28,28,28,28,28,28,28,28,28,28,28,28,28,28}},
	{k = "cbOutCardCount", t = "byte"},
	{k = "cbOutCardDataEx", t = "byte", l = {cmd.MAX_COUNT}},
	--历史积分
	{k = "lTurnScore", t = "score", l = {cmd.GAME_PLAYER}},		--积分信息
	{k = "lCollectScore", t = "score", l = {cmd.GAME_PLAYER}}	--积分信息
}

--*********************      服务器命令结构       ************--
cmd.SUB_S_GAME_START			= 100								--游戏开始
cmd.SUB_S_OUT_CARD				= 101								--用户出牌
cmd.SUB_S_SEND_CARD				= 102								--发送扑克
cmd.SUB_S_OPERATE_NOTIFY		= 103								--操作提示
cmd.SUB_S_OPERATE_RESULT		= 104								--操作命令
cmd.SUB_S_LISTEN_CARD			= 105								--用户听牌
cmd.SUB_S_TRUSTEE				= 106								--用户托管
cmd.SUB_S_REPLACE_CARD			= 107								--用户补牌
cmd.SUB_S_GAME_CONCLUDE			= 108								--游戏结束
cmd.SUB_S_SET_BASESCORE			= 109								--设置基数
cmd.SUB_S_HU_CARD				= 110								--听牌胡牌数据
cmd.SUB_S_RECORD				= 111								--房卡结算记录

--发送扑克
cmd.CMD_S_GameStart = 
{
	{k = "wBankerUser", t = "word"},							--庄家用户
	{k = "wReplaceUser", t = "word"},							--补花用户
	{k = "wSiceCount", t = "word"},								--筛子点数
	{k = "wHeapHead", t = "word"},								--牌堆头部
	{k = "wHeapTail", t = "word"},								--牌堆尾部
	{k = "cbMagicIndex", t = "byte"},							--财神索引
	{k = "cbHeapCardInfo", t = "byte", l = {2,2,2,2}},          --堆立信息
	{k = "cbUserAction", t = "byte"},							--用户动作
	{k = "cbCardData", t = "byte", l = {cmd.MAX_COUNT}},		--麻将列表
}
-- --机器人扑克
-- cmd.CMD_S_AndroidCard = 
-- {
-- 	{k = "cbHandCard", t = "byte", l = {14, 14, 14, 14}},		--手上扑克
-- 	{k = "wCurrentUser", t = "word"}							--当前玩家
-- }
-- --用户叫分
-- cmd.CMD_S_CallScore = 
-- {
-- 	{k = "wCurrentUser", t = "word"},							--当前玩家
-- 	{k = "wCallScoreUser", t = "word"},							--叫分玩家
-- 	{k = "cbCurrentScore", t = "byte"},							--当前叫分
-- 	{k = "cbUserCallScore", t = "byte"}							--上次叫分
-- }
-- --庄家信息
-- cmd.CMD_S_BankerInfo = 
-- {
-- 	{k = "wCurrentUser", t = "word"},							--庄家
-- 	{k = "wCurrentUser", t = "word"},							--当前玩家
-- 	{k = "cbBankerScore", t = "byte"},							--庄家叫分
-- 	{k = "cbBankerCard", t = "byte", l = {3}}					--庄家扑克
-- }
--用户出牌
cmd.CMD_S_OutCard = 
{
	{k = "wOutCardUser", t = "word"},							--出牌用户
	{k = "cbOutCardData", t = "byte"},							--出牌扑克
	{k = "bSysOut", t = "bool"},								--托管系统出牌
}
--发送扑克
cmd.CMD_S_SendCard = 
{
	{k = "cbCardData", t = "byte"},								--扑克数据
	{k = "cbActionMask", t = "byte"},							--动作掩码
	{k = "wCurrentUser", t = "word"},							--当前用户
	{k = "wSendCardUser", t = "word"},							--发牌用户
	{k = "wReplaceUser", t = "word"},							--补牌用户
	{k = "bTail", t = "bool"},									--末尾发牌
}
--操作提示
cmd.CMD_S_OperateNotify = 
{
	{k = "cbActionMask", t = "byte"},							--动作掩码
	{k = "cbActionCard", t = "byte"}							--动作扑克
}
--操作命令
cmd.CMD_S_OperateResult = 
{
	{k = "wOperateUser", t = "word"},							--操作用户
	{k = "cbActionMask", t = "byte"},							--动作掩码
	{k = "wProvideUser", t = "word"},							--供应用户
	{k = "cbOperateCode", t = "byte"},							--操作代码
	{k = "cbOperateCard", t = "byte", l = {3}},					--操作扑克
}
--提示听牌
cmd.CMD_S_Hu_Data = 
{
	{k = "cbOutCardCount", t = "byte"},
	{k = "cbOutCardData", t = "byte", l = {14}},
	{k = "cbHuCardCount", t = "byte", l = {14}},
	{k = "cbHuCardData", t = "byte", l = {28, 28, 28, 28, 28, 28, 28,
											28, 28, 28, 28, 28, 28, 28}},
	{k = "cbHuCardRemainingCount", t = "byte", l = {28, 28, 28, 28, 28, 28, 28,
											28, 28, 28, 28, 28, 28, 28}},
}
--听牌操作命令
cmd.CMD_S_ListenCard = 
{
	{k = "wListenUser", t = "word"},							--听牌用户
	{k = "bListen", t = "bool"},								--是否听牌

	{k = "cbHuCardCount", t = "byte"},
	{k = "cbHuCardData", t = "byte", l = {34}},
}
--游戏结束
cmd.CMD_S_GameConclude = 
{
	{k = "lCellScore", t = "int"},								--单元积分
	{k = "lGameScore", t = "score", l = {cmd.GAME_PLAYER}},		--游戏积分
	{k = "lRevenue", t = "score", l = {cmd.GAME_PLAYER}},		--税收积分
	{k = "lGangScore", t = "score", l = {cmd.GAME_PLAYER}},		--本局杠输赢分
	{k = "wProvideUser", t = "word"},							--供应用户
	{k = "cbProvideCard", t = "byte"},							--供应扑克
	{k = "cbSendCardData", t = "byte"},							--最后发牌
	{k = "cbChiHuKind", t = "dword", l = {cmd.GAME_PLAYER}},	--胡牌类型
	{k = "dwChiHuRight", t = "dword", l = {1, 1, 1, 1}},		--胡牌类型
	{k = "wLeftUser", t = "word"},								--玩家逃跑
	{k = "wLianZhuang", t = "word"},							--连庄
	{k = "cbCardCount", t = "byte", l = {cmd.GAME_PLAYER}},		--扑克数目
	{k = "cbHandCardData", t = "byte", l = {14, 14, 14, 14}},	--扑克列表
	--{k = "cbMaCount", t = "byte"},							--码数
	{k = "cbMaCount", t = "byte", l = {cmd.GAME_PLAYER}},		--码数
	{k = "cbMaData", t = "byte", l = {7}},						--码数据
}
--用户托管
cmd.CMD_S_Trustee = 
{
	{k = "bTrustee", t = "bool"},								--是否托管
	{k = "wChairID", t = "word"}								--托管用户
}
--补牌命令
cmd.CMD_S_ReplaceCard = 
{
	{k = "wReplaceUser", t = "word"},							--补牌用户
	{k = "cbReplaceCard", t = "byte"}							--补牌扑克
}
--游戏记录
cmd.CMD_S_Record = 
{
	{k = "nCount", t = "int"},									--
	{k = "cbHuCount", t = "byte", l = {cmd.GAME_PLAYER}},		--
	{k = "cbMaCount", t = "byte", l = {cmd.GAME_PLAYER}},		--
	{k = "cbAnGang", t = "byte", l = {cmd.GAME_PLAYER}},		--
	{k = "cbMingGang", t = "byte", l = {cmd.GAME_PLAYER}},		--
	{k = "lAllScore", t = "score", l = {cmd.GAME_PLAYER}},		--
	{k = "lDetailScore", t = "score", l = {32, 32, 32, 32}},	--
}


--**********************    客户端命令结构        ************--
cmd.SUB_C_OUT_CARD				= 1									--出牌命令
cmd.SUB_C_OPERATE_CARD			= 2									--操作扑克
cmd.SUB_C_LISTEN_CARD			= 3									--用户听牌
cmd.SUB_C_TRUSTEE				= 4									--用户托管
cmd.SUB_C_REPLACE_CARD			= 5									--用户补牌
cmd.SUB_C_SEND_CARD             = 6									--发送扑克

--出牌命令
cmd.CMD_C_OutCard = 
{
	{k = "cbCardData", t = "byte"}								--扑克数据
}
--操作命令
cmd.CMD_C_OperateCard = 
{
	{k = "cbOperateCode", t = "byte"},							--操作代码
	{k = "cbOperateCard", t = "byte", l = {3}}					--操作扑克
}
--用户听牌
cmd.CMD_C_ListenCard = 
{
	{k = "bListenCard", t = "bool"}								--是否听牌
}
--用户托管
cmd.CMD_C_Trustee = 
{
	{k = "bTrustee", t = "bool"}								--是否托管
}
--补牌命令
cmd.CMD_C_ReplaceCard = 
{
	{k = "cbCardData", t = "byte"}								--扑克数据
}
--发送扑克
cmd.CMD_C_SendCard = 
{
	{k = "cbControlGameCount", t = "byte"},						--控制次数
	{k = "cbCardCount", t = "byte"},							--扑克数目
	{k = "wBankerUser", t = "word"},							--控制庄家
	{k = "cbCardData", t = "byte", l = {cmd.MAX_REPERTORY}}		--扑克数据
}

return cmd