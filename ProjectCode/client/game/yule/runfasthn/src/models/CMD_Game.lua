local cmd =  {}

--游戏版本
cmd.VERSION 					= appdf.VersionValue(6,7,0,1)
--游戏标识
cmd.KIND_ID						= 601
--游戏人数
cmd.GAME_PLAYER					= 3
--视图位置(1~3)
cmd.MY_VIEWID					= 2

--正常牌数
cmd.NORMAL_CARD_COUNT			= 16
--牌间距
cmd.CARD_SPACING 				= 30
--牌宽
cmd.CARD_WIDTH 					= 143
--牌高
cmd.CARD_HEIGHT 				= 194

--********************        扑克类型        *************--
--错误类型
cmd.CT_ERROR					= 0
--单牌类型
cmd.CT_SINGLE					= 1
--单连类型
cmd.CT_SINGLE_LINE				= 2
--对连类型
cmd.CT_DOUBLE_LINE				= 3
--三连类型
cmd.CT_THREE_LINE				= 4
--三带一单
cmd.CT_THREE_LINE_TAKE_SINGLE	= 5
--三带一对
cmd.CT_THREE_LINE_TAKE_DOUBLE	= 6
--炸弹类型
cmd.CT_BOMB						= 7


--********************       定时器标识         ***************--
--出牌定时器
cmd.IDI_OUT_CARD				= 200
--开始定时器
cmd.IDI_START_GAME				= 202

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

--*********************      服务器命令结构       ************--
--游戏开始
cmd.SUB_S_GAME_START			= 101
--加注结果
cmd.SUB_S_OUT_CARD				= 102
--用户强退
cmd.SUB_S_PASS_CARD				= 103
--发牌消息
cmd.SUB_S_GAME_END				= 104
--游戏结束
cmd.SUB_S_AUTOMATISM			= 109

--空闲状态
cmd.CMD_S_StatusFree = 
{
	--基础积分
	{k = "lBaseScore", t = "score"},
	--历史积分
	{k = "lTurnScore", t = "score", l = {cmd.GAME_PLAYER}},
	{k = "lCollectScore", t = "score", l = {cmd.GAME_PLAYER}},
	--托管状态
 	{k = "bAutoStatus", t = "bool", l = {cmd.GAME_PLAYER}},
}
--游戏状态
cmd.CMD_S_StatusPlay = 
{
	--基础积分
	{k = "lBaseScore", t = "score"},
	--庄家用户
	{k = "wBankerUser", t = "word"},
	--出牌的人
	{k = "wLastOutUser", t = "word"},
	--当前玩家
	{k = "wCurrentUser", t = "word"},
	--手上扑克
	{k = "bCardData", t = "byte", l = {16}},
	-- --扑克数目
	{k = "bCardCount", t = "byte", l = {cmd.GAME_PLAYER}},
	-- --炸弹数目
	{k = "bBombCount", t = "byte", l = {cmd.GAME_PLAYER}},
	-- --基础出牌
	{k = "bTurnCardCount", t = "byte"},
	-- --出牌列表
	{k = "bTurnCardData", t = "byte", l = {16}},
	-- --总局得分
	{k = "lAllTurnScore", t = "score", l = {cmd.GAME_PLAYER}},
	--上局得分
	{k = "lLastTurnScore", t = "score", l = {cmd.GAME_PLAYER}},
	--托管状态
	{k = "bAutoStatus", t = "bool", l = {cmd.GAME_PLAYER}},
	--房间类型
	{k = "wRoomType", t = "word"},
	--历史积分
	{k = "lTurnScore", t = "score", l = {cmd.GAME_PLAYER}},
	{k = "lCollectScore", t = "score", l = {cmd.GAME_PLAYER}}
}
--发送扑克
cmd.CMD_S_GameStart = 
{
	--庄家用户
	{k = "wBankerUser", t = "word"},
	--当前玩家
	{k = "wCurrentUser", t = "word"},
	--扑克列表
	{k = "cbCardData", t = "byte", l = {16}}
}
--用户出牌
cmd.CMD_S_OutCard = 
{
	--扑克数目
	{k = "bCardCount", t = "byte"},
	--当前玩家
	{k = "wCurrentUser", t = "word"},
	--出牌玩家
	{k = "wOutCardUser", t = "word"},
	 --扑克列表
	{k = "bCardData", t = "byte", l = {16}}
}
--放弃出牌
cmd.CMD_S_PassCard = 
{
	--一轮开始
	{k = "bNewTurn", t = "byte"},
	--放弃玩家
	{k = "wPassUser", t = "word"},
	--当前玩家
	{k = "wCurrentUser", t = "word"}
}
--游戏结束
cmd.CMD_S_GameEnd = 
{
	--游戏税收
	{k = "lGameTax", t = "score"},
	--游戏积分
	{k = "lGameScore", t = "score", l = {cmd.GAME_PLAYER}},
	--扑克数目
	{k = "bCardCount", t = "byte", l = {cmd.GAME_PLAYER}},
	--扑克列表
	{k = "bCardData", t = "byte", l = {48}}
}

--玩家托管事件
cmd.CMD_S_UserAutomatism = 
{
	--椅子号
	{k = "wChairID", t = "word"},
	--托管
	{k = "bTrusee", t = "bool"}
}
--**********************    客户端命令结构        ************--

cmd.SUB_C_OUT_CART				= 2			--用户出牌
cmd.SUB_C_PASS_CARD				= 3			--放弃出牌
cmd.SUB_C_AUTOMATISM			= 4			--托管消息

--用户托管
cmd.CMD_C_Automatism = 
{
	{k = "bAutomatism", t = "bool"}
}
--出牌数据包
cmd.CMD_C_OutCard = 
{
	--出牌数目
	{k = "bCardCount", t = "byte"},
	--扑克列表
	{k = "bCardData", t = "byte", l = {16}}
}

return cmd