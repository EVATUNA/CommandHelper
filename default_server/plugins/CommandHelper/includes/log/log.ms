# 로그 파일 위치 선언
@log_paths = array()

# 로그 파일 생성
proc _create_log_files(@log_paths, @server) {

  # 메인 폴더
  @main_log_dir_path = '../../../../logs/commandhelper'
  if(!file_exists(@main_log_dir_path)) { create_dir(@main_log_dir_path) }

  # 날짜
  @date = simple_date('yyyy-MM-dd')

  # 메인 서버에서만 로깅
  if(@server == 'main') {

    # 상점
    @shop_log_dir_path = "@main_log_dir_path/shop"
    if(!file_exists(@shop_log_dir_path)) { create_dir(@shop_log_dir_path) }
    @log_paths['shop'] = "@shop_log_dir_path/@date.log"
    if(!file_exists(@log_paths['shop'])) { create_file(@log_paths['shop']) write_file(@log_paths['shop'], '[]', 'OVERWRITE') }

    # 농사
    @harvest_log_dir_path = "@main_log_dir_path/harvest"
    if(!file_exists(@harvest_log_dir_path)) { create_dir(@harvest_log_dir_path) }
    @log_paths['harvest'] = "@harvest_log_dir_path/@date.log"
    if(!file_exists(@log_paths['harvest'])) { create_file(@log_paths['harvest']) write_file(@log_paths['harvest'], '[]', 'OVERWRITE') }
  }

  # 오버, 네더 서버에서만 로깅
  if(@server == 'over' || @server == 'nether') {

    # 채광
    @mine_log_dir_path = "@main_log_dir_path/mine"
    if(!file_exists(@mine_log_dir_path)) { create_dir(@mine_log_dir_path) }
    @log_paths['mine'] = "@mine_log_dir_path/@date.log"
    if(!file_exists(@log_paths['mine'])) { create_file(@log_paths['mine']) write_file(@log_paths['mine'], '[]', 'mine') }

  }

  # 채팅 (게스트 제외 모든 서버에서 로깅)
  @chat_log_dir_path = "@main_log_dir_path/chat"
  if(!file_exists(@chat_log_dir_path)) { create_dir(@chat_log_dir_path) }
  @log_paths['chat'] = "@chat_log_dir_path/@date.log"
  if(!file_exists(@log_paths['chat'])) { create_file(@log_paths['chat']) write_file(@log_paths['chat'], '[]', 'chat') }

}

# 커헬 로드 후 파일세팅
_create_log_files(@log_paths, @server)

# 날짜 갱신 후 파일세팅
@cron_task = set_cron('0 0 * * *', closure() {
  _create_log_files(@log_paths, @server)
})
/*

if(@server == 'main') {
  proc _shop_logging(@shop_log_path, @player, @uuid, @type, @item, @qty, @price) {
    #시간
    @time = simple_date('HH:mm:ss')
    # 아이템 이름
    if(array_index_exists(@item, 'meta', 'display') && @item['meta']['display'] != '') {
      @item_name = strip_colors(@item['meta']['display'])
    } else {
      @item_name = @item['name']
    }
    # 메시지 부분
    @log = "[@time] @player(@uuid) @type @item_name x@qty (price: @price)\n"
    # 로깅
    write_file(@shop_log_path, @log, 'APPEND')
  }
  proc _harvest_logging(@harvest_log_path, @player, @uuid, @item, @location) {
    #시간
    @time = simple_date('HH:mm:ss')
    # 아이템 이름
    if(array_index_exists(@item, 'meta', 'display') && @item['meta']['display'] != '') {
      @item_name = strip_colors(@item['meta']['display'])
    } else {
      @item_name = @item['name']
    }
    # 좌표
    @x = integer(@location['x']) 
    @y = integer(@location['y'])
    @z = integer(@location['z'])
    # 매시지 부분
    @log = "[@time] @player(@uuid) harvest @item_name in x: @x y: @y z: @z"
    # 로깅
    write_file(@harvest_log_path, @log, 'APPEND')
  }
}

if(@server == 'over' || @server == 'nether') {
  proc _mine_logging(@mine_log_path, @player, @uuid, @item, @location) {
    # 시간
    @time = simple_date('HH:mm:ss')
    # 아이템 이름
    if(array_index_exists(@item, 'meta', 'display') && @item['meta']['display'] != '') {
      @item_name = strip_colors(@item['meta']['display'])
    } else {
      @item_name = @item['name']
    }
    # 좌표
    @x = integer(@location['x'])
    @y = integer(@location['y'])
    @z = integer(@location['z'])
    # 매시지 부분
    @log = "[@time] @player(@uuid) mine @item_name in x: @x y: @y z: @z\n"
    # 로깅
    write_file(@mine_log_path, @log, 'APPEND')
  }
}

proc _chat_logging(@chat_log_path, @content) {
  # 콘솔 로깅
  mom_log('INFO', @content)
  # 시간
  @time = simple_date('HH:mm:ss')
  # 메시지 부분
  @log = "[@time] @content\n"
  # 파일 로깅
  write_file(@chat_log_path, @log, 'APPEND')
}
*/

proc _logging(@type, @time, @server) {
  # dir path
  @main_log_dir_path = "../../../../logs/commandhelper/@type"
  # loging
  @arguments_size = array_size(@arguments)
  if(@arguments_size > 1) {
    switch(@type) {
    case 'chat':
      // @type, @time, @server, @channel, @sender_name, @sender_uuid, @target_name, @target_uuid, @message
      if(@arguments_size == 9) {
        @channel = @arguments[3]
        @sender_name = @arguments[4]
        @sender_uuid = @arguments[5]
        @target_name = @arguments[6]
        @target_uuid = @arguments[7]
        @message = @arguments[8]
        // time_stamp
        @time_stamp = simple_date('yyyy-MM-dd HH:mm:ss', time())
        broadcast(@time_stamp)
        // log
        if(@target_name != "") { // 일반 채팅
          @log = "[ev-commandhelper] [@time_stamp] [@type] [@server] [@channel] @sender_name (@sender_uuid) : @message"
        } else { // 귓속말
          @log = "[ev-commandhelper] [@time_stamp] [@type] [@server] [@channel] @sender_name (@sender_uuid) → @target_name (@target_uuid) : @message"
        }
        broadcast(@log)
      }
      break()
    case 'mine':
    case 'harvest':
      // @type, @time, @server, @location, @player, @uuid, @item
      if(@arguments_size == 7) {
        @location = @arguments[3]
        @player = @arguments[4]
        @uuid = @arguments[5]
        // time_stamp
        @time_stamp = simple_date('yyyy-MM-dd HH:mm:ss', time())
        // location_stamp
        @location_x = @location['x']
        @location_y = @location['y']
        @location_z = @location['z']
        @location_world = @location['world']
        @location_stamp = "@world/@x.@y.@z"
        // item_name
        if(array_index_exists(@item, 'meta', 'display') && @item['meta']['display'] != '') {
          @item_name = strip_colors(@item['meta']['display'])
        } else {
          @item_name = @item['name']
        }
        // log
        @log = "[ev-commandhelper] [@time_stamp] [@type] [@server] [@location_stamp] @player @item_name"
      }
      break()
    case 'shop':
      // @type, @time, @server, @location, @player, @uuid, @item, @sub_type, @price
      if(@arguments_size == 7) {
        @location = @arguments[3]
        @player = @arguments[4]
        @uuid = @arguments[5]
        // time_stamp
        @time_stamp = simple_date('yyyy-MM-dd HH:mm:ss', time())
        // location_stamp
        @location_x = @location['x']
        @location_y = @location['y']
        @location_z = @location['z']
        @location_world = @location['world']
        @location_stamp = "@world/@x.@y.@z"
        // item_name
        if(array_index_exists(@item, 'meta', 'display') && @item['meta']['display'] != '') {
          @item_name = strip_colors(@item['meta']['display'])
        } else {
          @item_name = @item['name']
        }
        // log
        @log = "[ev-commandhelper] [@time_stamp] [@type] [@server] [@location_stamp] @player @item_name"
      }
      break()
    }
  }
}
