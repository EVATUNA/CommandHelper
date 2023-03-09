# 로그 파일 생성
proc _create_log_files(@server) {
  # 메인 폴더
  @main_log_dir_path = '../../../../logs/commandhelper'
  if(!file_exists(@main_log_dir_path)) { create_dir(@main_log_dir_path) }
  # 날짜
  @date = simple_date('yyyy-MM-dd')
  # 상점
  @shop_log_dir_path = "@main_log_dir_path/shop"
  if(!file_exists(@shop_log_dir_path)) { create_dir(@shop_log_dir_path) }
  @shop_log_path = "@shop_log_dir_path/@date.log"
  if(!file_exists(@shop_log_path)) { create_file(@shop_log_path) }
  # 농사
  @harvest_log_dir_path = "@main_log_dir_path/harvest"
  if(!file_exists(@harvest_log_dir_path)) { create_dir(@harvest_log_dir_path) }
  @harvest_log_path = "@harvest_log_dir_path/@date.log"
  if(!file_exists(@harvest_log_path)) { create_file(@harvest_log_path) }
  # 채광
  @mine_log_dir_path = "@main_log_dir_path/mine"
  if(!file_exists(@mine_log_dir_path)) { create_dir(@mine_log_dir_path) }
  @mine_log_path = "@mine_log_dir_path/@date.log"
  if(!file_exists(@mine_log_path)) { create_file(@mine_log_path) }
  # 낚시
  @mine_log_dir_path = "@main_log_dir_path/fish"
  if(!file_exists(@mine_log_dir_path)) { create_dir(@mine_log_dir_path) }
  @mine_log_path = "@mine_log_dir_path/@date.log"
  if(!file_exists(@mine_log_path)) { create_file(@mine_log_path) }
  # 인첸트
  @mine_log_dir_path = "@main_log_dir_path/enchant"
  if(!file_exists(@mine_log_dir_path)) { create_dir(@mine_log_dir_path) }
  @mine_log_path = "@mine_log_dir_path/@date.log"
  if(!file_exists(@mine_log_path)) { create_file(@mine_log_path) }
  # 수리
  @mine_log_dir_path = "@main_log_dir_path/repair"
  if(!file_exists(@mine_log_dir_path)) { create_dir(@mine_log_dir_path) }
  @mine_log_path = "@mine_log_dir_path/@date.log"
  if(!file_exists(@mine_log_path)) { create_file(@mine_log_path) }
  # 채팅
  @chat_log_dir_path = "@main_log_dir_path/chat"
  if(!file_exists(@chat_log_dir_path)) { create_dir(@chat_log_dir_path) }
  @chat_log_path = "@chat_log_dir_path/@date.log"
  if(!file_exists(@chat_log_path)) { create_file(@chat_log_path) }
  # 루팅
  @loot_log_dir_path = "@main_log_dir_path/loot"
  if(!file_exists(@loot_log_dir_path)) { create_dir(@loot_log_dir_path) }
  @loot_log_path = "@loot_log_dir_path/@date.log"
  if(!file_exists(@loot_log_path)) { create_file(@loot_log_path) }
}
# 커헬 로드 후 파일세팅
_create_log_files(@server)
# 날짜 갱신 후 파일세팅
set_cron('0 0 * * *', closure() {
  _create_log_files(@server)
})

# 로깅 proc
proc _logging(@type, @time, @server) {
  # dir path
  @main_log_dir_path = "../../../../logs/commandhelper/@type"
  # path
  @date = simple_date('yyyy-MM-dd', time())
  @path = "@main_log_dir_path/@date.log"
  # loging
  @log = ''
  @arguments_size = array_size(@arguments)
  if(@arguments_size > 1) {
    switch(@type) {
    case 'chat':    // @type, @time, @server, @channel, @sender_name, @sender_uuid, @target_name, @target_uuid, @message
      if(@arguments_size == 9) {
        @channel = @arguments[3]
        @sender_name = @arguments[4]
        @sender_uuid = @arguments[5]
        @target_name = @arguments[6]
        @target_uuid = @arguments[7]
        @message = strip_colors(@arguments[8])
        // time_stamp
        @time_stamp = simple_date('yyyy-MM-dd HH:mm:ss', time())
        // log
        if(@target_name == '') { // 일반 채팅
          @log = "[ev-commandhelper] [@time_stamp] [@type] [@server] [@channel] @sender_name (@sender_uuid): @message\n"
        } else { // 귓속말
          @log = "[ev-commandhelper] [@time_stamp] [@type] [@server] [@channel] @sender_name (@sender_uuid) to @target_name (@target_uuid): @message\n"
        }
      }
      break()
    case 'mine':
    case 'harvest': // @type, @time, @server, @location, @player, @uuid, @item
      if(@arguments_size == 7) {
        @location = @arguments[3]
        @player = @arguments[4]
        @uuid = @arguments[5]
        @item = @arguments[6]
        // time_stamp
        @time_stamp = simple_date('yyyy-MM-dd HH:mm:ss', time())
        // location_stamp
        @location_x = integer(@location['x'])
        @location_y = integer(@location['y'])
        @location_z = integer(@location['z'])
        @location_world = @location['world']
        @location_stamp = "@location_world, @location_x, @location_y, @location_z"
        // item_name
        if(array_index_exists(@item, 'meta', 'display') && @item['meta']['display'] != '') {
          @item_name = strip_colors(@item['meta']['display'])
        } else {
          @item_name = @item['name']
        }
        // log
        @log = "[ev-commandhelper] [@time_stamp] [@type] [@server] [@location_stamp] @player (@uuid) @item_name\n"
        switch(@type) {
        case 'mine':
          prometheus_mining(@server, @location_world, @item_name)
          break()
        case 'harvest':
          prometheus_harvest(@server, @location_world, @item_name)
          break()
        }
      }
      break()
    case 'shop':    // @type, @time, @server, @shop_name, @player, @uuid, @item, @sub_type, @qty, @each_price
      if(@arguments_size == 10) {
        @shop_name = @arguments[3]
        @player = @arguments[4]
        @uuid = @arguments[5]
        @item = @arguments[6]
        @sub_type = @arguments[7]
        @qty = @arguments[8]
        @each_price = @arguments[9]
        // time_stamp
        @time_stamp = simple_date('yyyy-MM-dd HH:mm:ss', time())
        // item_name
        if(array_index_exists(@item, 'meta', 'display') && @item['meta']['display'] != '') {
          @item_name = strip_colors(@item['meta']['display'])
        } else {
          @item_name = @item['name']
        }
        // log
        @log = "[ev-commandhelper] [@time_stamp] [@type] [@server] [@shop_name] @player (@uuid) @sub_type x@qty @each_price @item_name\n"
        prometheus_shop(@server, @shop_name, @sub_type, @qty, @each_price, @item_name)
      }
      break()
    case 'fish':    // @type, @time, @server, @location, @player, @uuid, @item, @size
      if(@arguments_size == 8) {
        @location = @arguments[3]
        @player = @arguments[4]
        @uuid = @arguments[5]
        @item = @arguments[6]
        @size = @arguments[7]
        // time_stamp
        @time_stamp = simple_date('yyyy-MM-dd HH:mm:ss', time())
        // location_stamp
        @location_x = integer(@location['x'])
        @location_y = integer(@location['y'])
        @location_z = integer(@location['z'])
        @location_world = @location['world']
        @location_stamp = "@location_world, @location_x, @location_y, @location_z"
        // item_name
        if(array_index_exists(@item, 'meta', 'display') && @item['meta']['display'] != '') {
          @item_name = strip_colors(@item['meta']['display'])
        } else {
          @item_name = @item['name']
        }
        // log
        @log = "[ev-commandhelper] [@time_stamp] [@type] [@server] [@location_stamp] @player (@uuid) @item_name @size\n"
        prometheus_fishing(@server, @location['world'], @item_name, @size)
      }
      break()
    case 'enchant': // @type, @time, @server, @location, @player, @uuid, @enchant_item, @ingredient_item, @enchant, @cost
      if(@arguments_size == 10) {
        @location = @arguments[3]
        @player = @arguments[4]
        @uuid = @arguments[5]
        @enchant_item = @arguments[6]
        @ingredient_item = @arguments[7]
        @enchant_name = @arguments[8]
        @cost = @arguments[9]
        // time_stamp
        @time_stamp = simple_date('yyyy-MM-dd HH:mm:ss', time())
        // location_stamp
        @location_x = integer(@location['x'])
        @location_y = integer(@location['y'])
        @location_z = integer(@location['z'])
        @location_world = @location['world']
        @location_stamp = "@location_world, @location_x, @location_y, @location_z"
        // item_name
        if(array_index_exists(@enchant_item, 'meta', 'display') && @enchant_item['meta']['display'] != '') {
          @enchant_item_name = strip_colors(@enchant_item['meta']['display'])
        } else {
          @enchant_item_name = @enchant_item['name']
        }
        if(array_index_exists(@ingredient_item, 'meta', 'display') && @ingredient_item['meta']['display'] != '') {
          @ingredient_item_name = strip_colors(@ingredient_item['meta']['display'])
        } else {
          @ingredient_item_name = @ingredient_item['name']
        }
        // log
        @log = "[ev-commandhelper] [@time_stamp] [@type] [@server] [@location_stamp] @player (@uuid) enchant @enchant_name at @enchant_item_name with @ingredient_item_name and @cost\n"
        prometheus_enchant(@server, @location['world'], @enchant_item_name, @ingredient_item_name, @enchant_name, @cost)
      }
      break()
    case 'repair':  // @type, @time, @server, @location, @player, @uuid, @repair_item, @qty, @rank, @success
      if(@arguments_size == 10) {
        @location = @arguments[3]
        @player = @arguments[4]
        @uuid = @arguments[5]
        @repair_item = @arguments[6]
        @qty = @arguments[7]
        @rank = @arguments[8]
        @success = @arguments[9]
        // time_stamp
        @time_stamp = simple_date('yyyy-MM-dd HH:mm:ss', time())
        // location_stamp
        @location_x = integer(@location['x'])
        @location_y = integer(@location['y'])
        @location_z = integer(@location['z'])
        @location_world = @location['world']
        @location_stamp = "@location_world, @location_x, @location_y, @location_z"
        // item_name
        if(array_index_exists(@repair_item, 'meta', 'display') && @repair_item['meta']['display'] != '') {
          @repair_item_name = strip_colors(@repair_item['meta']['display'])
        } else {
          @repair_item_name = @repair_item['name']
        }
        // log
        @log = "[ev-commandhelper] [@time_stamp] [@type] [@server] [@location_stamp] @player (@uuid) repair @repair_item_name with @rank rank x@qty\n"
        prometheus_repair(@server, @location['world'], @repair_item_name, @qty, @rank, @success)
      }
      break()
    case 'loot':    // @type, @time, @server, @location, @mob, @player_rewards, @dropped_items
      if(@arguments_size == 7) {
        @location = @arguments[3]
        @mob = @arguments[4]
        @player_rewards = @arguments[5]
        @dropped_items = @arguments[6]
        // time_stamp
        @time_stamp = simple_date('yyyy-MM-dd HH:mm:ss', time())
        // location_stamp
        @location_x = integer(@location['x'])
        @location_y = integer(@location['y'])
        @location_z = integer(@location['z'])
        @location_world = @location['world']
        @location_stamp = "@location_world, @location_x, @location_y, @location_z"
        // mob_name
        @mob_name = strip_colors(get_mob_name(@mob))
        if(@mob_name == '') { @mob_name = entity_type(@mob) }
        // location_log
        @log = "[ev-commandhelper] [@time_stamp] [@type] [@server] [@mob_name] [@mob] was killed at [@location_stamp]\n"
        // player_reward_log
        foreach(@player: @rewards in @player_rewards) {
          if(ponline(@player)) {
            @uuid = @rewards['uuid']
            @can = @rewards['money']
            @tunapoint = @rewards['tunapoint']
            @arcanepoint = @rewards['arcanepoint']
            @log .= "[ev-commandhelper] [@time_stamp] [@type] [@server] [@mob_name] [@mob] was killed by @player (@uuid) dropped [@can can] [@tunapoint tunapoint] [@arcanepoint arcanepoint]\n"
          }
        }
        // item_name
        foreach(@item in @dropped_items) {
          if(array_index_exists(@item, 'meta', 'display') && @item['meta']['display'] != '') {
            @item_name = strip_colors(@item['meta']['display'])
          } else {
            @item_name = @item['name']
          }
          // qty
          if(array_index_exists(@item, 'qty')) {
            @qty = @item['qty']
          } else {
            @qty = 1
          }
          // item_log
          @log .= "[ev-commandhelper] [@time_stamp] [@type] [@server] [@mob_name] [@mob] dropped @item_name x@qty\n"
        }
      }
      break()
    }
  }
  # file append
  if(file_exists(@path)) {
    write_file(@path, @log, 'APPEND')
  } else {
    //broadcast('로깅 실패')
  }
}