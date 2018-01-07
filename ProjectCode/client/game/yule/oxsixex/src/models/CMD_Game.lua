local cmd =  {}

--游戏版本
cmd.VERSION 					= appdf.VersionValue(6,7,0,1)
--游戏标识
cmd.KIND_ID						= 36
--游戏人数
cmd.GAME_PLAYER					= 6
--游戏名字
cmd.GAME_NAME				    = "通比牛牛"	
--最大数目				
cmd.MAX_COUNT					= 5		
--下注区域							
cmd.MAX_JETTON_AREA				= 6									
--最大赔率
cmd.MAX_TIMES				    = 5									

--视图位置
cmd.MY_VIEW_CHAIRID				= 3
cmd.VIEW_TOP_MIDDLE             = 0
cmd.VIEW_TOP_LEFFT              = 1
cmd.VIEW_MIDDLE_LEFFT           = 2
cmd.VIEW_MIDDLE_RIGHT           = 4
cmd.VIEW_TOP_RIGHT              = 5
--结束原因
cmd.GER_NO_PLAYER				= 16								--没有玩家
-------------游戏状态
--等待开始
cmd.GS_TK_FREE				= 0
--游戏进行
cmd.GS_TK_PLAYING			= 100

--操作记录
cmd.MAX_OPERATION_RECORD		= 20						--操作记录条数
cmd.RECORD_LENGTH				= 128					    --每条记录字长

cmd.SERVER_LEN				    = 32 
--游戏开始
cmd.SUB_S_GAME_START			= 100
--用户强退
cmd.SUB_S_PLAYER_EXIT			= 101
--发牌消息
cmd.SUB_S_SEND_CARD			    = 102
--游戏结束
cmd.SUB_S_GAME_END				= 103
--用户摊牌
cmd.SUB_S_OPEN_CARD				= 104
--刷新控制服务端
cmd.SUB_S_ADMIN_STORAGE_INFO    = 112
--查询用户结果
cmd.SUB_S_REQUEST_QUERY_RESULT  = 113
--用户控制
cmd.SUB_S_USER_CONTROL          = 114
--用户控制完成
cmd.SUB_S_USER_CONTROL_COMPLETE = 115
--操作记录
cmd.SUB_S_OPERATION_RECORD      = 116

--------------------------发送请求--------------------------------
cmd.SUB_C_OPEN_CARD			    = 1									--用户摊牌
-------------------------------------------------------------------
cmd.GameStatues = {
    FREE_STATUES = 0,
    READY_STATUES = 1,
    START_STATUES = 2,
    OPENCARD_STATUES = 3,
    END_STATUES = 4, 
}

--时间标识
cmd.TIME_USER_START_GAME		= 28									--开始定时器
cmd.TIME_USER_OPEN_CARD			= 30									--摊牌定时器
cmd.IDI_START_GAME = "IDI_START_GAME"
cmd.IDI_TIME_OPEN_CARD = "IDI_TIME_OPEN_CARD"
cmd.IDI_DELAY_TIME = "IDI_DELAY_TIME"

return cmd