local cmd =  {}

cmd.RES 						= "game/yule/zhajinhua/res/"
--游戏版本
cmd.VERSION 					= appdf.VersionValue(6,7,0,1)
--游戏标识
cmd.KIND_ID						= 6
	
--游戏人数
cmd.GAME_PLAYER					= 5

--视图位置
cmd.MY_VIEWID					= 3

--空闲状态
cmd.GAME_STATUS_FREE			= 0
--游戏状态
cmd.GAME_STATUS_PLAY			= 100

--***************服务端命令结构**************--
--游戏开始
cmd.SUB_S_GAME_START			= 100
--加注结果
cmd.SUB_S_ADD_SCORE				= 101
--放弃跟注
cmd.SUB_S_GIVE_UP				= 102
--发牌消息
cmd.SUB_S_SEND_CARD				= 103
--游戏结束
cmd.SUB_S_GAME_END				= 104
--比牌跟注
cmd.SUB_S_COMPARE_CARD			= 105
--看牌跟注
cmd.SUB_S_LOOK_CARD				= 106
--用户强退
cmd.SUB_S_PLAYER_EXIT			= 107
--开牌消息
cmd.SUB_S_OPEN_CARD				= 108
--等待比牌
cmd.SUB_S_WAIT_COMPARE			= 109
--智能消息
cmd.SUB_S_ANDROID_CARD			= 110
--看牌消息
cmd.SUB_S_CHEAT_CARD			= 111
--更新密钥
cmd.SUB_S_UPDATEAESKEY			= 120

--***************客户端命令结构**************--
--用户加注
cmd.SUB_C_ADD_SCORE				= 1
--放弃消息
cmd.SUB_C_GIVE_UP				= 2
--比牌消息
cmd.SUB_C_COMPARE_CARD			= 3
--看牌消息
cmd.SUB_C_LOOK_CARD				= 4
--开牌消息
cmd.SUB_C_OPEN_CARD				= 5
--等待比牌
cmd.SUB_C_WAIT_COMPARE			= 6
--完成动画
cmd.SUB_C_FINISH_FLASH			= 7
--完成动画
cmd.SUB_C_ADD_SCORE_TIME		= 8
--****************定时器标识******************--
--开始定时器
cmd.IDI_START_GAME   			= 200
--加注定时器
cmd.IDI_USER_ADD_SCORE			= 201
--选比牌用户定时器
cmd.IDI_USER_COMPARE_CARD		= 202
--过滤定时器
cmd.IDI_DISABLE					= 203
--*****************时间标识*****************--
--开始定时器
cmd.TIME_START_GAME				= 20
--加注定时器
cmd.TIME_USER_ADD_SCORE			= 25
--比牌定时器
cmd.TIME_USER_COMPARE_CARD		= 25


return cmd