
proc _get_chunk_info(@x, @z) {
  @location = array(
    'x': @x * 16 + 8,
    'y': 64,
    'z': @z * 16 + 8,
    'world': 'spawn_minecraft_residence',
  )
  @chunk_info = array(
    get_biome(@location),
    0, //tunalands_get_owner_uuid_with_chunk_query(@location['world'], "@x:@z")
    integer(_get_highest_block_at(@location)['y'])
  )
  return(@chunk_info)
  //broadcast("§7@x:@z" @chunk_info)
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

proc _update_chunks_info(@offset_x, @offset_z, @radius, @force_update, @clear_queue)  {
  if(@clear_queue) {
    queue_clear('update_chunk')
  }
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
  for(@x = -@radius, @x < @radius, @x ++) {
    for(@z = -@radius, @z < @radius, @z ++) {
      @closure = closure() {
        // 진행도 디버그
        if(@z == @radius - 1) {
          if(integer(@radius * 0.1 * 2) == integer((@x + @radius))) { broadcast('10%' simple_date('HH:mm:ss')) }
          else if(integer(@radius * 0.2 * 2) == integer((@x + @radius))) { broadcast('20%' simple_date('HH:mm:ss')) }
          else if(integer(@radius * 0.3 * 2) == integer((@x + @radius))) { broadcast('30%' simple_date('HH:mm:ss')) }
          else if(integer(@radius * 0.4 * 2) == integer((@x + @radius))) { broadcast('40%' simple_date('HH:mm:ss')) }
          else if(integer(@radius * 0.5 * 2) == integer((@x + @radius))) { broadcast('50%' simple_date('HH:mm:ss')) }
          else if(integer(@radius * 0.6 * 2) == integer((@x + @radius))) { broadcast('60%' simple_date('HH:mm:ss')) }
          else if(integer(@radius * 0.7 * 2) == integer((@x + @radius))) { broadcast('70%' simple_date('HH:mm:ss')) }
          else if(integer(@radius * 0.8 * 2) == integer((@x + @radius))) { broadcast('80%' simple_date('HH:mm:ss')) }
          else if(integer(@radius * 0.9 * 2) == integer((@x + @radius))) { broadcast('90%' simple_date('HH:mm:ss')) }
        }

        @path = 'chunks/'.(@offset_x + @x).'_'.(@offset_z + @z).'.json'
        @is_update = true
        if(!@force_update && file_exists(@path)) { @is_update = false }
        if(@is_update) {
          @chunk_info = _get_chunk_info(@offset_x + @x, @offset_z + @z)
          @biomes[@chunk_info[0]][] = (@offset_x + @x).'_'.(@offset_z + @z)
          async_write_file(@path, json_encode(@chunk_info))
        }

      }
      queue_push(@closure, 'update_chunk')
    }
  }
  @closure = closure() {
    broadcast('100%' simple_date('HH:mm:ss'))
    foreach(@biome: @chunks in @biomes) {
      @path = "biomes/@biome.json"
      async_write_file(@path, json_encode(@chunks))
    }
  }
  queue_push(@closure, 'update_chunk')
}

proc _update_chunk_tunaland(@x, @z) {
  if(function_exists('tunalands_get_owner_uuid_with_chunk_query')) {
    @owner = tunalands_get_owner_uuid_with_chunk_query('spawn_minecraft_residence', "@x:@z")
    @path = 'chunks/'.@x.'_'.@z.'.json'
    if(is_null(@owner)) {
      async_read(@path, closure(@content) {
        @chunk_info = json_decode(@content)
        if(!@chunk_info[1]) {
          if(!is_null(tunalands_get_owner_uuid_with_chunk_query('spawn_minecraft_residence', "@x:@z"))) {
            @chunk_info[1] = 1
            async_write_file(@path, json_encode(@chunk_info), 'OVERWRITE')
          }
        }
      })
    }
  }
}

// 월드 초기화 해서 청크 로딩 해야할시 청크 마스터로 반지금 7500블럭 미리 로드 한 후에 청크 불러와야함 
// _update_chunks_info(0, 0, 450, true, true)

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

# 다야 블럭 설치하여 땅 생성 시도시
bind('block_place', null, array('block': 'DIAMOND_BLOCK'), @event) { // _ro 붙이기
  if(@event['location']['world'] == 'spawn_minecraft_residence' && psneaking(@event['player'])) {
    @chunk = get_chunk_loc(@event['location'])
    _update_chunk_tunaland(@chunk['x'], @chunk['z'])
  }
}

# 점유 깃발 사용시
bind('player_interact', null, array('button': 'right', 'itemname': 'GREEN_BANNER'), @event) {
  if(@event['action'] == 'right_click_block' && @event['location']['world'] == 'spawn_minecraft_residence') {
    @chunk = get_chunk_loc(@event['location'])
    _update_chunk_tunaland(@chunk['x'], @chunk['z'])
  }
}

proc _get_near_chunk(@x, @z, @min_radius, @max_radius) {
  @x_rand = array_get_rand(array(1, -1)) * rand(@min_radius, @max_radius)
  @z_rand = array_get_rand(array(1, -1)) * rand(@min_radius, @max_radius)
  return(array('x': @x + @x_rand, 'z': @z + @z_rand))
}

proc _generate_trace(@player) {
  if(rand() < 0.1) {
    @chunk = get_chunk_loc(ploc(@player))
    @path = 'chunks/'.@chunk['x'].'_'.@chunk['z'].'.json'
    async_read(@path, closure(@content) {
      @chunk_info = json_decode(@content)
      if(@chunk_info[1]) {
        @chance = 0.5
        @min_radius = 5
        @max_radius = 10
      } else {
        @chance = 1
        @min_radius = 3
        @max_radius = 8
      }
      if(rand() < @chance) {
        @near_chunk = _get_near_chunk(@chunk['x'], @chunk['z'], @min_radius, @max_radius)
        @path = 'chunks/'.@near_chunk['x'].'_'.@near_chunk['z'].'.json'
        if(file_exists(@path)) {
          async_read(@path, closure(@content) {
            @chunk_info = json_decode(@content)
            broadcast(@near_chunk['x'].'_'.@near_chunk['z'] @chunk_info)
          })
        }
      }
    })
  }
}
