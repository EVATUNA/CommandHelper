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
    if(!file_exists(@log_paths['shop'])) { create_file(@log_paths['shop']) }

    # 농사
    @harvesting_log_dir_path = "@main_log_dir_path/harvesting"
    if(!file_exists(@harvesting_log_dir_path)) { create_dir(@harvesting_log_dir_path) }
    @log_paths['harvesting'] = "@harvesting_log_dir_path/@date.log"
    if(!file_exists(@log_paths['harvesting'])) { create_file(@log_paths['harvesting']) }
  }

  # 오버, 네더 서버에서만 로깅
  if(@server == 'over' || @server == 'nether') {

    # 채광
    @mining_log_dir_path = "@main_log_dir_path/mining"
    if(!file_exists(@mining_log_dir_path)) { create_dir(@mining_log_dir_path) }
    @log_paths['mining'] = "@mining_log_dir_path/@date.log"
    if(!file_exists(@log_paths['mining'])) { create_file(@log_paths['mining']) }

  }

  # 채팅 (게스트 제외 모든 서버에서 로깅)
  @chating_log_dir_path = "@main_log_dir_path/chating"
  if(!file_exists(@chating_log_dir_path)) { create_dir(@chating_log_dir_path) }
  @log_paths['chating'] = "@chating_log_dir_path/@date.log"
  if(!file_exists(@log_paths['chating'])) { create_file(@log_paths['chating']) }

}

# 커헬 로드 후 파일세팅
_create_log_files(@log_paths, @server)

# 날짜 갱신 후 파일세팅
@cron_task = set_cron('0 0 * * *', closure() {
  _create_log_files(@log_paths, @server)
})

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
  proc _harvesting_logging(@harvesting_log_path, @player, @uuid, @item, @location) {
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
    @log = "[@time] @player(@uuid) harvest @item_name in x: @x y: @y z: @z\n"
    # 로깅
    write_file(@harvesting_log_path, @log, 'APPEND')
  }
}

if(@server == 'over' || @server == 'nether') {
  proc _mining_logging(@mining_log_path, @player, @uuid, @item, @location) {
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
    write_file(@mining_log_path, @log, 'APPEND')
  }
}

proc _chating_logging(@chating_log_path, @content) {
  # 콘솔 로깅
  mom_log('INFO', @content)
  # 시간
  @time = simple_date('HH:mm:ss')
  # 메시지 부분
  @log = "[@time] @content\n"
  # 파일 로깅
  write_file(@chating_log_path, @log, 'APPEND')
}