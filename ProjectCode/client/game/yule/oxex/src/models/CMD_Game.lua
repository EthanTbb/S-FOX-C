local cmd =  {}

--游戏版本
cmd.VERSION 					= appdf.VersionValue(6,7,0,1)
--游戏标识
cmd.KIND_ID						= 102
	
--游戏人数
cmd.GAME_PLAYER					= 2

--视图位置
cmd.MY_VIEWID					= 1

--******************         游戏状态             ************--
--等待开始
cmd.GS_TK_FREE					= 0
--叫庄状态
cmd.GS_TK_CALL					= 100
--下注状态
cmd.GS_TK_SCORE					= 101
--游戏进行
cmd.GS_TK_PLAYING				= 102

--*********************      服务器命令结构       ************--
--游戏开始
cmd.SUB_S_GAME_START			= 100
--加注结果
cmd.SUB_S_ADD_SCORE				= 101
--用户强退
cmd.SUB_S_PLAYER_EXIT			= 102
--发牌消息
cmd.SUB_S_SEND_CARD				= 103
--游戏结束
cmd.SUB_S_GAME_END				= 104
--用户摊牌
cmd.SUB_S_OPEN_CARD				= 105
--用户叫庄
cmd.SUB_S_CALL_BANKER			= 106

--**********************    客户端命令结构        ************--
--用户叫庄
cmd.SUB_C_CALL_BANKER			= 1
--用户加注
cmd.SUB_C_ADD_SCORE				= 2
--用户摊牌
cmd.SUB_C_OPEN_CARD				= 3
--更新库存
cmd.SUB_C_STORAGE				= 6
--设置上限
cmd.SUB_C_STORAGEMAXMUL			= 7
--请求查询用户
cmd.SUB_C_REQUEST_QUERY_USER	= 8
--用户控制
cmd.SUB_C_USER_CONTROL			= 9

--********************       定时器标识         ***************--
--无效定时器
cmd.IDI_NULLITY					= 200
--开始定时器
cmd.IDI_START_GAME				= 201
--叫庄定时器
cmd.IDI_CALL_BANKER				= 202
--加注定时器
cmd.IDI_TIME_USER_ADD_SCORE		= 1
--摊牌定时器
cmd.IDI_TIME_OPEN_CARD			= 2

--*******************        时间标识         *****************--
--叫庄定时器
cmd.TIME_USER_CALL_BANKER		= 30
--开始定时器
cmd.TIME_USER_START_GAME		= 30
--加注定时器
cmd.TIME_USER_ADD_SCORE			= 30
--摊牌定时器
cmd.TIME_USER_OPEN_CARD			= 30

return cmd