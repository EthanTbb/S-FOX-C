--
-- Author: Tang
-- Date: 2016-12-08 15:42:04
--
local cmd = {}

cmd.KIND_ID 			= 401
cmd.GAME_PLAER 			= 2
cmd.NO_CHESS			= 0  --没有棋子
cmd.BLACK_CHESS			= 1  --黑色棋子
cmd.WHITE_CHESS			= 2  --白色棋子

cmd.GU_WAIT_PEACE       = 1  --求和
cmd.GU_WAIT_PEGRET      = 2  --等待悔棋
cmd.FR_COUNT_LIMIT 		= 1	 --次数限制
cmd.FR_PLAYER_OPPOSE    = 2	 --玩家反对

cmd.AESKEY_TOTAL		= 16  --密钥总个数（前4位取用户USERID的四位,后12位可变）
cmd.AESKEY_VARIABLECOUNT = 12  --可变密匙个数

cmd.AESENCRYPTION_LENGTH = 16 --公共加密原文长度

--状态定义
cmd.GS_GAME_FREE			= 0
cmd.GS_GAME_STATUS	    	= 100   
cmd.GS_GAME_END        	    = 101

--服务器命令结构
cmd.SUB_S_GAME_START			=100									--游戏开始
cmd.SUB_S_PLACE_CHESS			=101									--放置棋子
cmd.SUB_S_REGRET_REQ			=102									--悔棋请求
cmd.SUB_S_REGRET_FAILE			=103									--悔棋失败
cmd.SUB_S_REGRET_RESULT			=104									--悔棋结果
cmd.SUB_S_PEACE_REQ				=105									--和棋请求
cmd.SUB_S_PEACE_ANSWER			=106									--和棋应答
cmd.SUB_S_BLACK_TRADE			=107									--交换对家
cmd.SUB_S_GAME_END				=108									--游戏结束
cmd.SUB_S_CHESS_MANUAL			=109									--棋谱信息
cmd.SUB_S_COACH					=110									--指导费
cmd.SUB_S_UPDATEAESKEY			=111									--更新密钥

--游戏状态
cmd.CMD_S_StatusFree= 
{
	{k="wBlackUser",t="word"}, 				--黑棋玩家
	{k="wBankerUser",t="word"},				--庄家玩家
	{k="bPermitCoach",t="bool"},			--是否允许指导费
	{k="lCoachRestarin",t="int"},			--指导费约束
}

--游戏状态
cmd.CMD_S_StatusPlay=
{
	{k="wGameClock",t="word"},												--局时时间
	{k="wBlackUser",t="word"},												--黑棋玩家
	{k="wBankerUser",t="word"}, 											--庄家玩家
	{k="wCurrentUser",t="word"},											--当前玩家
	{k="cbRestrict",t="byte"},												--是否禁手
	{k="cbTradeUser",t="byte"},												--是否对换
	{k="cbDoubleChess",t="byte"},											--是否双打
	{k="wLeftClock",t="word",l={2}},										--剩余时间
	{k="cbBegStatus",t="word",l={2}},										--请求状态
	{k="bPermitCoach",t="bool"},											--是否允许指导费
	{k="lCoachRestarin",t="int"}											--指导费约束
}

cmd.CMD_S_Coach=
{
	{k="wBankerUser",t="word"},												--庄家玩家
	{k="lCoachRestrain",t="int"}											--指导费约束
}
--游戏开始
cmd.CMD_S_GameStart=
{
	{k="wGameClock",t="word"},													--局时时间
	{k="wBlackUser",t="word"},													--黑棋玩家
	{k="cbRestrict",t="byte"},													--是否禁手
	{k="cbTradeUser",t="byte"},													--是否对换
	{k="cbDoubleChess",t="byte"},												--是否双打
	{k="bPermitCoach",t="bool"},												--是否允许指导费
	{k="lCoachRestarin",t="int"},												--指导费约束

	{k="wBankerUser",t="word"}													--庄家玩家
}

--放置棋子
cmd.CMD_S_PlaceChess = 
{
	{k="cbXPos",t="byte"},													--棋子位置
	{k="cbYPos",t="byte"},													--棋子位置
	{k="wPlaceUser",t="word"},				 								--放棋玩家
	{k="wCurrentUser",t="word"},				 							--当前玩家
	{k="wLeftClock",t="word",l={2}}											--剩余时间
}

--悔棋失败
cmd.CMD_S_RegretFaile = 
{
	{k="cbFaileReason",t="byte"}											--失败原因
}

--悔棋结果
cmd.CMD_S_RegretResult = 
{
	{k="wRegretUser",t="word"},												--悔棋玩家
	{k="wCurrentUser",t="word"},											--当前玩家
	{k="wRegretCount",t="word"},											--悔棋数目
	{k="wLeftClock",t="word",l={2}}											--局时时间
}

--游戏结束
cmd.CMD_S_GameEnd = 
{
	{k="wWinUser",t="word"},												--胜利玩家
	{k="lUserScore",t="score",l={2}}										--用户积分
}

--更新密钥
cmd.CMD_S_UpdateAESKey = 
{
	{k="chUserUpdateAESKey",t="byte",s=cmd.AESKEY_TOTAL}					--密钥
}


cmd.tagChessManual = 
{

	{k="cbXPos",t="byte"},													--棋子位置
	{k="cbYPos",t="byte"},													--棋子位置
	{k="cbColor",t="byte"}

}

--客户端命令结构
cmd.SUB_C_PLACE_CHESS			=1									--放置棋子
cmd.SUB_C_REGRET_REQ			=2									--悔棋请求
cmd.SUB_C_REGRET_ANSWER			=3									--悔棋应答
cmd.SUB_C_PEACE_REQ				=4									--和棋请求
cmd.SUB_C_PEACE_ANSWER			=5									--和棋应答
cmd.SUB_C_GIVEUP_REQ			=6									--认输请求
cmd.SUB_C_TRADE_REQ				=7									--交换请求
cmd.SUB_C_PAY_CHARGE			=8									--付指导费


cmd.RegretReq = 1   --悔棋
cmd.PeaceReq  = 2   --求和

cmd.FR_COUNT_LIMIT   = 1   --限制次数
cmd.FR_PLAYER_OPPOSE = 2   --玩家反对

return cmd