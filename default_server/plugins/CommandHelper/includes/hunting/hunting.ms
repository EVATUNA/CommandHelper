@tunaland_queue = array()

if(@server == 'main' && function_exists('tunalands_get_owner_uuid_with_chunk_query')) {

  proc _get_mass_from_chunk(@chunk) {
    @mass = array(
      'x': integer(@chunk['x'] / 16),
      'z': integer(@chunk['z'] / 16),
    )
    return(@mass)
  }

  proc _get_chunk_from_mass(@mass, @index) {
    @chunk = array(
      'x': @mass['x'] * 16 + integer(@index / 16),
      'z': @mass['z'] * 16 + @index % 16
    )
    return(@chunk)
  }

  proc _get_relative_chunk_index(@chunk) {
    //청크 구하는 기능 인덱스 구하는 기능 둘다 넣기?
    return((@chunk['x'] % 16) * 16) + (@chunk['z'] % 16)
  }

  proc _get_relative_chunk_xz(@index) { // 굳이..?
    @relative_chunk = array(
      'x': integer(@index / 16),
      'z': @index % 16
    )
    return(@relative_chunk)
  }

  proc _get_chunk_info(@x, @z) {
    @location = array(
      'x': @x * 16 + 8,
      'y': 64,
      'z': @z * 16 + 8,
      'world': 'spawn_minecraft_residence',
    )
    @chunk_info = array(
      get_biome(@location),
      integer(_get_highest_block_at(@location)['y'])
    )
    return(@chunk_info)
  }

  proc _get_highest_block_at(@location) {
    @bool = true
    @solid_blocks_to_ignore = array(
      "OAK_LOG",
      "SPRUCE_LOG",
      "BIRCH_LOG",
      "JUNGLE_LOG",
      "ACACIA_LOG",
      "DARK_OAK_LOG"
    )
    @minute_investigation = false

    @block = get_block(@location)
    @material_info = material_info(@block)
    if(@material_info['isSolid'] && @material_info['isOccluding'] && !array_contains(@solid_blocks_to_ignore, @block)) {
      @is_investing_solid_block = true
      @location['y'] += 8
    } else {
      @is_investing_solid_block = false
      @location['y'] -= 4
    }

    while(@bool) {
      @block = get_block(@location)
      @material_info = material_info(@block)

      if(!@minute_investigation) { // 큰 단위 조사
        if(@is_investing_solid_block) { // 첫 시작 조사가 블럭일시 위로 8칸씩 조사
          if(@material_info['isSolid'] && @material_info['isOccluding'] && !array_contains(@solid_blocks_to_ignore, @block)) {
            @location['y'] += 8
          } else {
            @location['y'] -= 1
            @minute_investigation = true
          }
        } else { // 첫 시작 조사가 공기일시 아래로 4칸씩 조사
          if(@material_info['isSolid'] && @material_info['isOccluding'] && !array_contains(@solid_blocks_to_ignore, @block)) {
            @location['y'] += 1
            @minute_investigation = true
          } else {
            @location['y'] -= 4
          }
        }
      } else { // 작은 단위 조사
        if(@is_investing_solid_block) { // 8칸씩 조사하다가 공기가 나왔을시 1칸씩 검사, 1칸씩 검사하다가 다시 블럭이 나오면 종료
          if(@material_info['isSolid'] && @material_info['isOccluding'] && !array_contains(@solid_blocks_to_ignore, @block)) {
            @bool = false
          } else {
            @location['y'] -= 1
          }
        } else { // 4칸씩 조사하다가 블럭이 나왔을시 1칸씩 검사, 1칸씩 검사하다가 다시 공기가 나오면 종료
          if(@material_info['isSolid'] && @material_info['isOccluding'] && !array_contains(@solid_blocks_to_ignore, @block)) {
            @location['y'] += 1
          } else {
            @location['y'] -= 1 // 가장 위의 블럭을 구하기 위해 +1
            @bool = false
          }
        }
      }
    }
    return(@location)
  }

  proc _get_random_surface_in_chunk(@x, @z) {
    @location = array(
      'x': @x * 16 + rand(16),
      'y': 64,
      'z': @z * 16 + rand(16),
      'world': 'spawn_minecraft_residence'
    )
    @highest_location = _get_highest_block_at(@location)
    @highest_location['y'] += 1
    
    @block = get_block(@highest_location)
    @ignore_blocks = array(
      "OAK_LOG",
      "SPRUCE_LOG",
      "BIRCH_LOG",
      "JUNGLE_LOG",
      "ACACIA_LOG",
      "DARK_OAK_LOG"
    )

    if(array_contains(@ignore_blocks, @block) || @highest_location['y'] < 63) {
      if(rand() > 0.005) {
        @return = _get_random_surface_in_chunk(@x, @z)
      } else {
        @return = null
      }
    } else {
      @return = @highest_location
    }
    return(@return)
  }

  # 튜나랜드 히스토리
  if(!file_exists('tunaland_history.json')) {
    async_write_file('tunaland_history.json', '[]', 'OVERWRITE')
  }

  proc _push_tunaland_queue(@x, @z, @tunaland_queue) {
    @owner = tunalands_get_owner_uuid_with_chunk_query('spawn_minecraft_residence', "@x:@z")
    if(is_null(@owner)) {
      @chunk = @x.'_'.@z
      @tunaland_queue[] = @chunk
      if(array_size(@tunaland_queue) == 1) {
        _update_tunaland_queue(@tunaland_queue)
      }
    }
  }

  proc _update_tunaland_queue(@tunaland_queue) {
    @path = 'tunaland_history.json'
    async_read(@path, closure(@content) {
      @chunks = json_decode(@content)
      @chunk = @tunaland_queue[0]
      if(!array_contains(@chunks, @chunk)) {
        @chunks[] = @chunk
      }
      async_write_file(@path, json_encode(@chunks), 'OVERWRITE', closure() {
        array_remove(@tunaland_queue, 0)
        if(array_size(@tunaland_queue) > 0) {
          _update_tunaland_queue(@tunaland_queue)
        }
      })
    })
  }
  
  proc _update_chunks_info(@radius) {
    queue_clear('update_chunk')

    broadcast('0%' simple_date('HH:mm:ss'))
    @biomes = array(
      "BEACH": array(),
      "SAVANNA": array(),
      "SUNFLOWER_PLAINS": array(),
      "FROZEN_OCEAN": array(),
      "BIRCH_FOREST": array(),
      "THE_VOID": array(),
      "WINDSWEPT_HILLS": array(),
      "DEEP_LUKEWARM_OCEAN": array(),
      "END_HIGHLANDS": array(),
      "DEEP_FROZEN_OCEAN": array(),
      "OLD_GROWTH_SPRUCE_TAIGA": array(),
      "END_MIDLANDS": array(),
      "FLOWER_FOREST": array(),
      "ERODED_BADLANDS": array(),
      "END_BARRENS": array(),
      "SNOWY_TAIGA": array(),
      "JUNGLE": array(),
      "OCEAN": array(),
      "ICE_SPIKES": array(),
      "SMALL_END_ISLANDS": array(),
      "FROZEN_RIVER": array(),
      "THE_END": array(),
      "DARK_FOREST": array(),
      "COLD_OCEAN": array(),
      "SNOWY_PLAINS": array(),
      "SNOWY_SLOPES": array(),
      "LUSH_CAVES": array(),
      "WINDSWEPT_SAVANNA": array(),
      "DRIPSTONE_CAVES": array(),
      "MEADOW": array(),
      "STONY_SHORE": array(),
      "WINDSWEPT_FOREST": array(),
      "PLAINS": array(),
      "OLD_GROWTH_BIRCH_FOREST": array(),
      "SAVANNA_PLATEAU": array(),
      "SPARSE_JUNGLE": array(),
      "STONY_PEAKS": array(),
      "RIVER": array(),
      "JAGGED_PEAKS": array(),
      "WARPED_FOREST": array(),
      "WOODED_BADLANDS": array(),
      "NETHER_WASTES": array(),
      "LUKEWARM_OCEAN": array(),
      "WINDSWEPT_GRAVELLY_HILLS": array(),
      "BAMBOO_JUNGLE": array(),
      "CUSTOM": array(),
      "DEEP_COLD_OCEAN": array(),
      "BADLANDS": array(),
      "OLD_GROWTH_PINE_TAIGA": array(),
      "MUSHROOM_FIELDS": array(),
      "DEEP_OCEAN": array(),
      "TAIGA": array(),
      "WOODED_HILLS": array(),
      "DESERT": array(),
      "SNOWY_BEACH": array(),
      "WARM_OCEAN": array(),
      "BASALT_DELTAS": array(),
      "FOREST": array(),
      "SWAMP": array(),
      "SOUL_SAND_VALLEY": array(),
      "FROZEN_PEAKS": array(),
      "GROVE": array(),
      "CRIMSON_FOREST": array()
    )
    for(@mass_x = -@radius, @mass_x < @radius, @mass_x ++) {
      for(@mass_z = -@radius, @mass_z < @radius, @mass_z ++) {
      
        # 파일 경로 생성 및 파일 생성
        @path = 'masses/'.@mass_x.'_'.@mass_z.'.json'

        # 매스 info
        @chunk_infos = array()

        # 내부 반복문
        for(@i = 0, @i < 256, @i++) {

          @closure = closure() {
            # 청크 구하기
            @chunk_array = _get_chunk_from_mass(array('x': @mass_x, 'z': @mass_z), @i)
            @chunk_x = @chunk_array['x']
            @chunk_z = @chunk_array['z']

            # 청크 데이터 불러오기
            @chunk_info = _get_chunk_info(@chunk_x, @chunk_z)
            //broadcast("§7@chunk_x:@chunk_z" @chunk_info)
            
            # 청크 데이터 넣기
            @chunk_infos[] = @chunk_info

            # 바이옴에 따라 바이옴 파일에 청크 넣기
            @biomes[@chunk_info[0]][] = @chunk_x.'_'.@chunk_z
          }
          queue_push(@closure, 'update_chunk')

        }

        # 내부 반복 끝날시
        @closure = closure() {
          # 파일 쓰기
          async_write_file(@path, json_encode(@chunk_infos), 'OVERWRITE')
          # 진행도 출력
          if(@mass_z == @radius - 1) {
            if(integer(@radius * 0.1 * 2) == integer((@mass_x + @radius))) { broadcast('10%' simple_date('HH:mm:ss')) }
            else if(integer(@radius * 0.2 * 2) == integer((@mass_x + @radius))) { broadcast('20%' simple_date('HH:mm:ss')) }
            else if(integer(@radius * 0.3 * 2) == integer((@mass_x + @radius))) { broadcast('30%' simple_date('HH:mm:ss')) }
            else if(integer(@radius * 0.4 * 2) == integer((@mass_x + @radius))) { broadcast('40%' simple_date('HH:mm:ss')) }
            else if(integer(@radius * 0.5 * 2) == integer((@mass_x + @radius))) { broadcast('50%' simple_date('HH:mm:ss')) }
            else if(integer(@radius * 0.6 * 2) == integer((@mass_x + @radius))) { broadcast('60%' simple_date('HH:mm:ss')) }
            else if(integer(@radius * 0.7 * 2) == integer((@mass_x + @radius))) { broadcast('70%' simple_date('HH:mm:ss')) }
            else if(integer(@radius * 0.8 * 2) == integer((@mass_x + @radius))) { broadcast('80%' simple_date('HH:mm:ss')) }
            else if(integer(@radius * 0.9 * 2) == integer((@mass_x + @radius))) { broadcast('90%' simple_date('HH:mm:ss')) }
          }
        }
        queue_push(@closure, 'update_chunk')

      }
    }

    // 모든 반복 다 끝났을시 바이옴 파일 처리
    @closure = closure() {
      broadcast('100%' simple_date('HH:mm:ss'))
      foreach(@biome: @chunks in @biomes) {
        @path = "biomes/@biome.json"
        async_write_file(@path, json_encode(@chunks), 'OVERWRITE')
        //broadcast(@biome @chunks)
      }
    }
    queue_push(@closure, 'update_chunk')
  }

  // 월드 초기화 해서 청크 로딩 해야할시 청크 마스터로 반지금 7500블럭 미리 로드 한 후에 청크 불러와야함 
  //_update_chunks_info(29)
  //queue_clear('update_chunk')
  
  # 바이옴별 청크 저장
  @biomes = array()
  @files = list_files('biomes')
  foreach(@file in @files) {
    @file_path = "biomes/@file"
    @file_name_and_extension = _get_file_name_and_extension(@file)
    @file_name = @file_name_and_extension[0]
    @file_extension = @file_name_and_extension[1]
    if(@file_extension == 'json') {
      async_read_file(@file_path, closure(@content) {
        @chunks = json_decode(@content)
        @biomes[@file_name] = @chunks
      })
    }
  }

  # 흔적 파일 불러오기
  @traces = array()
  @files = list_files('traces')
  foreach(@file in @files) {
    @file_path = "traces/@file"
    @file_name_and_extension = _get_file_name_and_extension(@file)
    @file_name = @file_name_and_extension[0]
    @file_extension = @file_name_and_extension[1]
    if(@file_extension == 'yml') {
      async_read_file(@file_path, closure(@content) {
        foreach(@trace_name: @trace_data in yml_decode(@content)) {
          @namespace = "@file_name:@trace_name"
          @traces[@namespace] = @trace_data
        }
      })
    }
  }

  # 다야 블럭 설치하여 땅 생성 시도시
  bind('block_place', null, array('block': 'DIAMOND_BLOCK'), @event, @tunaland_queue) { // _ro 붙이기
    if(@event['location']['world'] == 'spawn_minecraft_residence' && psneaking(@event['player'])) {
      @chunk = get_chunk_loc(@event['location'])
      _push_tunaland_queue(@chunk['x'], @chunk['z'], @tunaland_queue)
    }
  }

  # 점유 깃발 사용시
  bind('player_interact', null, array('button': 'right', 'itemname': 'GREEN_BANNER'), @event, @tunaland_queue) {
    if(@event['action'] == 'right_click_block' && @event['location']['world'] == 'spawn_minecraft_residence') {
      @chunk = get_chunk_loc(@event['location'])
      _push_tunaland_queue(@chunk['x'], @chunk['z'], @tunaland_queue)
    }
  }

  proc _get_near_chunk(@x, @z, @min_radius, @max_radius) {
    @x_rand = array_get_rand(array(1, -1)) * rand(@min_radius, @max_radius)
    @z_rand = array_get_rand(array(1, -1)) * rand(@min_radius, @max_radius)
    return(array('x': @x + @x_rand, 'z': @z + @z_rand))
  }

  proc _generate_trace(@player, @traces) {
    if(rand() < 0.1) {
      @read_masses = array()
      @chunk = get_chunk_loc(ploc(@player))
      @mass = _get_mass_from_chunk(@chunk)
      @path = 'masses/'.@mass['x'].'_'.@mass['z'].'.json'
      async_read(@path, closure(@content) {
        @mass_info = json_decode(@content)
        @read_masses[@path] = @mass_info
        async_read('tunaland_history.json', closure(@content) {
          @tunaland_history = json_decode(@content)
          if(array_contains(@tunaland_history, @chunk['x'].'_'.@chunk['z'])) { // 마을 안
            @chance = 0.5
            @min_radius = 5
            @max_radius = 10
          } else { //마을 밖
            @chance = 1
            @min_radius = 3
            @max_radius = 8
          }
          
          if(rand() < @chance) {
            @near_chunk = _get_near_chunk(@chunk['x'], @chunk['z'], @min_radius, @max_radius)
            @near_mass = _get_mass_from_chunk(@near_chunk)
            @near_path = 'masses/'.@near_mass['x'].'_'.@near_mass['z'].'.json'
            if(array_index_exists(@read_masses, @near_path)) { // mass 있음
              @index = _get_relative_chunk_index(@near_chunk)
              @chunk_info = @mass_info[@index]
              if(!array_contains(@tunaland_history, @near_chunk['x'].'_'.@near_chunk['z'])) {
                _start_moving(@near_chunk['x'], @chunk_info[1], @near_chunk['z'], @chunk_info[0], @traces, @read_masses)
              }
            } else if(file_exists(@near_path)) { // mass 없음
              async_read(@near_path, closure(@content) {
                @mass_info = json_decode(@content)
                @read_masses[@near_path] = @mass_info
                @index = _get_relative_chunk_index(@near_chunk)
                @chunk_info = @mass_info[@index]
                if(!array_contains(@tunaland_history, @near_chunk['x'].'_'.@near_chunk['z'])) {
                  _start_moving(@near_chunk['x'], @chunk_info[1], @near_chunk['z'], @chunk_info[0], @traces, @read_masses)
                }
              })
            }
          }
        })
      })
    }
  }

  proc _start_moving(@x, @y, @z, @biome, @traces, @read_masses) {
    @traces = array_deep_clone(@traces)
    foreach(@trace_name: @trace_data in @traces) {
      if(array_index_exists(@trace_data, 'conditions', 'chance_by_biomes', @biome)) {
        @start_chance = @trace_data['conditions']['chance_by_biomes'][@biome] ** (@trace_data['min_move'] * 0.1)
      } else {
        @start_chance = 0
      }
      if(rand() > @start_chance) {
        array_remove(@traces, @trace_name)
      }
    }
    if(array_size(@traces) > 0) {
      @trace_name = array_rand(@traces, 1, true)[0]
      @facing = rand(8)
      @moves = array(
        array(
          'x': @x,
          'y': @y,
          'z': @z,
          'biome': @biome,
          'facing': @facing
        )
      )
      _try_moving(@moves, 0, @traces, @trace_name, @read_masses)
    }
  }

  proc _try_moving(@moves, @failures, @traces, @trace_name, @read_masses) {
    @trace_data = @traces[@trace_name]
    @moving_count = array_size(@moves)
    if(@moving_count < @trace_data['max_move']) {
      if(@moving_count < @trace_data['min_move'] || rand() < 0.666) {

        @last_move = @moves[@moving_count - 1]

        if(@failures < 3) {
          switch(@failures) {
          case 0:
            switch(rand(20)) {
            case 0..15:
              @turn = 0
              break()
            case 16..17:
              @turn = -1
              break()
            case 18..19:
              @turn = 1
              break()
            }
            break()
          case 1:
            switch(rand(20)) {
            case 0..9:
              @turn = 0
              break()
            case 10..13:
              @turn = -1
              break()
            case 14..17:
              @turn = 1
              break()
            case 18:
              @turn = -2
              break()
            case 19:
              @turn = 2
              break()
            }
            break()
          case 2:
            switch(rand(20)) {
            case 0..5:
              @turn = 0
              break()
            case 6..9:
              @turn = -1
              break()
            case 10..13:
              @turn = 1
              break()
            case 14..16:
              @turn = -2
              break()
            case 17..19:
              @turn = 2
              break()
            }
            break()
          }

          @new_facing = @last_move['facing'] + @turn
          if(@new_facing < 0) {
            @new_facing += 8
          } else if(@new_facing > 7) {
            @new_facing -= 8
          }

          switch(@new_facing) {
          case 0:
            @new_x = @last_move['x']
            @new_z = @last_move['z'] + 1
            break()
          case 1:
            @new_x = @last_move['x'] - 1
            @new_z = @last_move['z'] + 1
            break()
          case 2:
            @new_x = @last_move['x'] - 1
            @new_z = @last_move['z']
            break()
          case 3:
            @new_x = @last_move['x'] - 1
            @new_z = @last_move['z'] - 1
            break()
          case 4:
            @new_x = @last_move['x']
            @new_z = @last_move['z'] - 1
            break()
          case 5:
            @new_x = @last_move['x'] + 1
            @new_z = @last_move['z'] - 1
            break()
          case 6:
            @new_x = @last_move['x'] + 1
            @new_z = @last_move['z']
            break()
          case 7:
            @new_x = @last_move['x'] + 1
            @new_z = @last_move['z'] + 1
            break()
          }

          @new_chunk = array('x': @new_x, 'z': @new_z)
          @new_mass = _get_mass_from_chunk(@new_chunk)
          @new_path = 'masses/'.@new_mass['x'].'_'.@new_mass['z'].'.json'
          
          async_read('tunaland_history.json', closure(@content) {
            @tunaland_history = json_decode(@content)

            if(array_index_exists(@read_masses, @new_path)) { // mass 있음
              @mass_info = @read_masses[@new_path]
              @index = _get_relative_chunk_index(@new_chunk)
              @chunk_info = @mass_info[@index]
              # 튜나랜드 땅인지 아닌지
              if(!array_contains(@tunaland_history, @new_chunk['x'].'_'.@new_chunk['z'])) {
                @is_succeeded = true
                @new_y = @chunk_info[1]
                @new_biome = @chunk_info[0]
                if(array_index_exists(@trace_data, 'conditions')) {
                  @conditions = @trace_data['conditions']

                  // 디버깅용 변수
                  @m = array_size(@moves) + 1
                  @f = @failures + 1
                  // 바이옴 검사
                  if(@is_succeeded && array_index_exists(@conditions, 'chance_by_biomes')) {
                    @chance_by_biomes = @conditions['chance_by_biomes']
                    if(array_index_exists(@chance_by_biomes, @new_biome)) {
                      @chance = @chance_by_biomes[@new_biome]
                    } else {
                      @chance = 0
                    }
                    if(rand() > @chance) {
                      @is_succeeded = false
                      //broadcast("§7@trace_name @m§7 번째 이동 실패 (트라이: @f) (바이옴)")
                    }
                  }

                  // 최소 y조사
                  if(@is_succeeded && array_index_exists(@conditions, 'min_y')) {
                    if(@conditions['min_y'] > @new_y) {
                      @is_succeeded = false
                      //broadcast("§7@trace_name @m§7 번째 이동 실패 (트라이: @f) (최소 y)")
                    }
                  }

                  // 최대 y조사
                  if(@is_succeeded && array_index_exists(@conditions, 'max_y')) {
                    if(@conditions['max_y'] < @new_y) {
                      @is_succeeded = false
                      //broadcast("§7@trace_name @m§7 번째 이동 실패 (트라이: @f) (최대 y)")
                    }
                  }

                  // y편차 확률 검사
                  if(@is_succeeded && array_index_exists(@conditions, 'height_difference_for_chance')) {
                    @old_y = @last_move['y']
                    if(abs(@old_y - @new_y) > rand() * @conditions['height_difference_for_chance']) {
                      @is_succeeded = false
                      //broadcast("§7@trace_name @m§7 번째 이동 실패 (트라이: @f) (y편차)")
                    }
                  }
                }

                if(@is_succeeded) {
                  @move = array(
                    'x': @new_x,
                    'y': @new_y,
                    'z': @new_z,
                    'biome': @new_biome,
                    'facing': @new_facing
                  )
                  @moves[] = @move
                  //broadcast(@trace_name array_size(@moves).' 번째 이동 성공 (방향:' @new_facing.')')
                  if(array_size(@moves) == @trace_data['min_move']) {
                    //broadcast('경로 생성 가능')
                  }
                  @failures = 0
                } else {
                  @failures += 1
                }
                _try_moving(@moves, @failures, @traces, @trace_name, @read_masses)
              } else if(rand() < 0.666) { // 이동 경로에 튜랜 땅 있을 시
                @first_move = @moves[0]
                //broadcast('경로 생성 재시도 (튜랜 땅이 경로에 걸림)')
                _start_moving(@first_move['x'], @first_move['y'], @first_move['z'], @first_move['biome'], @traces, @read_masses)
              } else {
                //broadcast('경로 생성 실패')
              }
            } else if(file_exists(@new_path)) { // mass 없음
              async_read(@new_path, closure(@content) {
                @mass_info = json_decode(@content)
                @read_masses[@new_path] = @mass_info
                @index = _get_relative_chunk_index(@new_chunk)
                @chunk_info = @mass_info[@index]
                # 튜나랜드 땅인지 아닌지
                if(!array_contains(@tunaland_history, @new_chunk['x'].'_'.@new_chunk['z'])) {
                  @is_succeeded = true
                  @new_y = @chunk_info[1]
                  @new_biome = @chunk_info[0]
                  if(array_index_exists(@trace_data, 'conditions')) {
                    @conditions = @trace_data['conditions']

                    // 디버깅용 변수
                    @m = array_size(@moves) + 1
                    @f = @failures + 1
                    // 바이옴 검사
                    if(@is_succeeded && array_index_exists(@conditions, 'chance_by_biomes')) {
                      @chance_by_biomes = @conditions['chance_by_biomes']
                      if(array_index_exists(@chance_by_biomes, @new_biome)) {
                        @chance = @chance_by_biomes[@new_biome]
                      } else {
                        @chance = 0
                      }
                      if(rand() > @chance) {
                        @is_succeeded = false
                        //broadcast("§7@trace_name @m§7 번째 이동 실패 (트라이: @f) (바이옴)")
                      }
                    }

                    // 최소 y조사
                    if(@is_succeeded && array_index_exists(@conditions, 'min_y')) {
                      if(@conditions['min_y'] > @new_y) {
                        @is_succeeded = false
                        //broadcast("§7@trace_name @m§7 번째 이동 실패 (트라이: @f) (최소 y)")
                      }
                    }

                    // 최대 y조사
                    if(@is_succeeded && array_index_exists(@conditions, 'max_y')) {
                      if(@conditions['max_y'] < @new_y) {
                        @is_succeeded = false
                        //broadcast("§7@trace_name @m§7 번째 이동 실패 (트라이: @f) (최대 y)")
                      }
                    }

                    // y편차 확률 검사
                    if(@is_succeeded && array_index_exists(@conditions, 'height_difference_for_chance')) {
                      @old_y = @last_move['y']
                      if(abs(@old_y - @new_y) > rand() * @conditions['height_difference_for_chance']) {
                        @is_succeeded = false
                        //broadcast("§7@trace_name @m§7 번째 이동 실패 (트라이: @f) (y편차)")
                      }
                    }
                  }

                  if(@is_succeeded) {
                    @move = array(
                      'x': @new_x,
                      'y': @new_y,
                      'z': @new_z,
                      'biome': @new_biome,
                      'facing': @new_facing
                    )
                    @moves[] = @move
                    //broadcast(@trace_name array_size(@moves).' 번째 이동 성공 (방향:' @new_facing.')')
                    if(array_size(@moves) == @trace_data['min_move']) {
                      //broadcast('경로 생성 가능')
                    }
                    @failures = 0
                  } else {
                    @failures += 1
                  }
                  _try_moving(@moves, @failures, @traces, @trace_name, @read_masses)
                } else if(rand() < 0.666) { // 이동 경로에 튜랜 땅 있을 시
                  @first_move = @moves[0]
                  //broadcast('경로 생성 재시도 (튜랜 땅이 경로에 걸림)')
                  _start_moving(@first_move['x'], @first_move['y'], @first_move['z'], @first_move['biome'], @traces, @read_masses)
                } else {
                  //broadcast('경로 생성 실패')
                }
              })
            } else if(rand() < 0.333) {
              @first_move = @moves[0]
              //broadcast('경로 생성 재시도 (청크 파일 없음)')
              _start_moving(@first_move['x'], @first_move['y'], @first_move['z'], @first_move['biome'], @traces, @read_masses)
            } else {
              //broadcast('경로 생성 실패 (청크 파일 없음)')
            }
          })

        } else if(rand() < 0.666) { // 3번 실패했을시
          @first_move = @moves[0]
          //broadcast('경로 생성 재시도 (3번 실패함)')
          _start_moving(@first_move['x'], @first_move['y'], @first_move['z'], @first_move['biome'], @traces, @read_masses)
        } else {
          //broadcast('경로 생성 실패 (3번 실패함)')
        }

      } else {
        if(!array_contains(array('RIVER', 'FROZEN_RIVER', 'BEACH', 'STONY_SHORE', 'SNOWY_BEACH', 'OCEAN', 'DEEP_OCEAN', 'DEEP_COLD_OCEAN', 'COLD_OCEAN', 'FROZEN_OCEAN', 'DEEP_FROZEN_OCEAN', 'LUKEWARM_OCEAN', 'DEEP_LUKEWARM_OCEAN', 'WARM_OCEAN'), @moves[-1]['biome'])) {
          //broadcast('흔적 생성')
          array_remove(@trace_data, 'conditions')
          array_remove(@trace_data, 'min_move')
          array_remove(@trace_data, 'max_move')
          @tag = array(
            'trace_name': @trace_name,
            'trace_data': @trace_data,
            'moves': @moves,
            'minute': 5
          )
          _place_trace(@tag, true)
        } else if(rand() < 0.666) { // 마지막 청크바이옴이 바다나 강일시
          @first_move = @moves[0]
          //broadcast('경로 생성 재시도 (마지막 청크 바다 or 강)')
          _start_moving(@first_move['x'], @first_move['y'], @first_move['z'], @first_move['biome'], @traces, @read_masses)
        } else {
          //broadcast('경로 생성 실패 (마지막 청크 바다 or 강)')
        }
      }
    } else {
      if(!array_contains(array('RIVER', 'FROZEN_RIVER', 'BEACH', 'STONY_SHORE', 'SNOWY_BEACH', 'OCEAN', 'DEEP_OCEAN', 'DEEP_COLD_OCEAN', 'COLD_OCEAN', 'FROZEN_OCEAN', 'DEEP_FROZEN_OCEAN', 'LUKEWARM_OCEAN', 'DEEP_LUKEWARM_OCEAN', 'WARM_OCEAN'), @moves[-1]['biome'])) {
        //broadcast('흔적 생성')
        array_remove(@trace_data, 'conditions')
        array_remove(@trace_data, 'min_move')
        array_remove(@trace_data, 'max_move')
        @tag = array(
          'trace_name': @trace_name,
          'trace_data': @trace_data,
          'moves': @moves,
          'minute': 5
        )
        _place_trace(@tag, true)
      } else if(rand() < 0.666) { // 마지막 청크바이옴이 바다나 강일시
        @first_move = @moves[0]
        //broadcast('경로 생성 재시도 (마지막 청크 바다 or 강)')
        _start_moving(@first_move['x'], @first_move['y'], @first_move['z'], @first_move['biome'], @traces, @read_masses)
      } else {
        //broadcast('경로 생성 실패 (마지막 청크 바다 or 강)')
      }
    }
  }

  
  proc _place_trace(@tag, @is_start) {
    @tag['minute'] = 5
    @moves = @tag['moves']
    if(array_index_exists(@tag['trace_data'], 'trace_term') && @tag['trace_data']['trace_term'] > 1) {
      @trace_term = @tag['trace_data']['trace_term']
    } else {
      @trace_term = 1
    }
    while(true) {
      if(array_size(@moves) == 1) { break() }
      if(!@is_start && @trace_term > 1) {
        @trace_term--
        array_remove(@moves, 0)
      } else if(array_contains(array(/*'RIVER', 'FROZEN_RIVER', 'BEACH', 'STONY_SHORE', 'SNOWY_BEACH',*/ 'OCEAN', 'DEEP_OCEAN', 'DEEP_COLD_OCEAN', 'COLD_OCEAN', 'FROZEN_OCEAN', 'DEEP_FROZEN_OCEAN', 'LUKEWARM_OCEAN', 'DEEP_LUKEWARM_OCEAN', 'WARM_OCEAN'), @moves[0]['biome'])) {
        array_remove(@moves, 0)
      } else {
        break()
      }
    }
    if(array_size(@moves) > 1) {
      @move = @moves[0]
      # 발자국일시
      @location = _get_random_surface_in_chunk(@move['x'], @move['z'])

      if(is_array(@location)) {
        @rotation = @move['facing']
        @framed_item = array(
          'name': @tag['trace_data']['traces']['item']['name'],
          'meta': array(
            'model': 0
          )
        )

        @is_snow = false
        if(array_index_exists(@tag['trace_data']['traces']['item'], 'normal_model')) {
          @framed_item['meta']['model'] = @tag['trace_data']['traces']['item']['normal_model']
        }
        if(get_block(@location) == 'SNOW' && array_index_exists(@tag['trace_data']['traces']['item'], 'snow_model')) {
          @framed_item['meta']['model'] = @tag['trace_data']['traces']['item']['snow_model']
          @is_snow = true
        }

        if(!@is_snow) {
          set_block(@location, 'AIR')
        }
        _summon_item_frame(@location, 'UP', @rotation, 'trace', @framed_item, @tag)
      } else {
        @location = _place_trace(@tag, false)
      }
      # 다른타입의 흔적일시
    } else {
      @move = @moves[0]
      @location = _get_random_surface_in_chunk(@move['x'], @move['z'])
      @location['x'] += 0.5
      @location['y'] += 1
      @location['z'] += 0.5
      if(is_array(@location)) {
        _summon_mythicmob(@tag['trace_data']['mob'], @tag['trace_data']['count'], @location)
      } else {
        // 흔적이 사라짐
        broadcast(@tag['trace_data']['mob'] '스폰 불가능')
      }
      // 몹 소환
    }
    //broadcast(@location)
    return(@location)
  }

  bind('player_interact_entity', null, array('clicked': 'ITEM_FRAME'), @event) {
    @player = @event['player']
    @uuid = puuid(@player)
    @id = @event['id']
    @tag = _get_tag(@id)
    if(is_array(@tag)) {
      @slot = pheld_slot(@player)
      @item = get_inventory_item(@uuid, @slot)
      if(is_array(@item) && @item['name'] == 'COMPASS' && array_index_exists(@item, 'meta', 'model') && !is_null(@item['meta']['model']) && @item['meta']['model'] > 0) {
        @location = _place_trace(@tag, false)
        entity_remove(@id)
        @item['meta']['lodestone'] = false
        @item['meta']['target'] = @location
        set_inventory_item(@uuid, @slot, @item)
      }
    }
  }

  bind('player_interact', null, array('block': 'SNOW', 'button': 'right', 'hand': 'main_hand'), @event) {
    @player = @event['player']
    @uuid = puuid(@player)

    @location = @event['location']
    @location['x'] += 0.5
    @location['z'] += 0.5

    @item_frames = entities_in_radius(@location, 1, 'ITEM_FRAME')
    foreach(@item_frame in @item_frames) {
      @tag = _get_tag(@item_frame)
      if(is_array(@tag)) {
        @slot = pheld_slot(@player)
        @item = get_inventory_item(@uuid, @slot)
        if(is_array(@item) && @item['name'] == 'COMPASS' && array_index_exists(@item, 'meta', 'model') && !is_null(@item['meta']['model']) && @item['meta']['model'] > 0) {
          @location = _place_trace(@tag, false)
          entity_remove(@item_frame)
          @item['meta']['lodestone'] = false
          @item['meta']['target'] = @location
          set_inventory_item(@uuid, @slot, @item)
        }
        break()
      }
    }
  }
}