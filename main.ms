## main data
export('server', 'spawn')
@players_data = array()

## Include
foreach(@file in list_files('includes')) {
  include('includes/'.@file.'/main.ms')
}

## POGU UseTable
pogu_use_table('state')
#pogu_use_table('ch-skill')
#pogu_use_table('ch-setting')


############################################
### INTERFACE SYSTEM (인터페이스 시스템) ###
############################################
# 인터페이스 시스템에선 일부 시스템들도 함께 관리합니다.
# ex) 스킬 카운트/쿨다운, 낚시



#상태 데이터?

######################
### INTERFACE TEXT ###
######################
@files_data = array()
async_read('font_space.json', closure(@json) {
  @files_data['fonts'] = json_decode(@json)
})

######################
### INTERFACE DATA ###
######################
@players_data = array()
###################
### PLAYER DATA ###
###################


#################
### PROCEDURE ###
#################


#################
### MAIN CODE ###
#################




#포리치 부분은 실질적으로 사용될 일은 거의 없음 커헬 리로드 하지 않는 이상... <재접 귀찮은 테섭 용도!!!>
@players = all_players()
foreach(@player in @players) {
  #_load_player_data(@player)
}




if(is_null(import('interface.task'))) {
  /*@interface_task = set_interval(1000, closure() {
    ### DEBUG
    #broadcast(@players_data)
    ###
    foreach(@player: @player_data in @players_data) {
      @uuid = puuid(@player)
      if(!ponline(@player)) {
        _save_player_data(@player, @player_data)
        array_remove(@players_data, @uuid)
        if(has_bind('mastery.dash.sneak_down.'.@player)) { unbind('mastery.dash.sneak_down.'.@player) }
        if(has_bind('mastery.dash.stand_up.'.@player)) { unbind('mastery.dash.stand_up.'.@player) }
        if(has_bind('mastery.dash.jump.'.@player)) { unbind('mastery.dash.jump.'.@player) }
        if(has_bind('mastery.dash.fly.'.@player)) { unbind('mastery.dash.fly.'.@player) }
      } else {
        @dash_count = @players_data[@uuid]['active_skill']['dash']['count']
        if(@dash_count > 0 && array_contains(array('SURVIVAL', 'ADVENTURE'), pmode(@player))) { # 대쉬 스킬 시작 (항시 바인드가 아닌 조건 만족시 바인드기 때문에 스킬부분에 들가진 못함)
          if(!has_bind('mastery.dash.sneak_down.'.@player)) {
            bind('player_toggle_sneak', array('id': 'mastery.dash.sneak_down.'.@player), array('sneaking': true, 'player': @player), @event, @player, @players_data) {
              @ploc = ploc(@player)
              @ploc['y'] += 0.45
              @fence_locations = array(
                'x+z+': array('x': @ploc['x'] + 0.3, 'y': @ploc['y'], 'z': @ploc['z'] + 0.3, 'world': @ploc['world']),
                'x+z-': array('x': @ploc['x'] + 0.3, 'y': @ploc['y'], 'z': @ploc['z'] - 0.3, 'world': @ploc['world']),
                'x-z+': array('x': @ploc['x'] - 0.3, 'y': @ploc['y'], 'z': @ploc['z'] + 0.3, 'world': @ploc['world']),
                'x-z+': array('x': @ploc['x'] - 0.3, 'y': @ploc['y'], 'z': @ploc['z'] - 0.3, 'world': @ploc['world'])
              )
              @is_player_on_the_fence = false
              foreach(@fence_location in @fence_locations) {
                if(string_contains(get_block(@fence_location), 'FENCE') || string_contains(get_block(@fence_location), 'WALL')) {
                  @is_player_on_the_fence = true
                  break()
                }
              }
              @ploc['y'] += 0.5
              @block_locations = array(
                'x+z+': array('x': @ploc['x'] + 0.3, 'y': @ploc['y'], 'z': @ploc['z'] + 0.3, 'world': @ploc['world']),
                'x+z-': array('x': @ploc['x'] + 0.3, 'y': @ploc['y'], 'z': @ploc['z'] - 0.3, 'world': @ploc['world']),
                'x-z+': array('x': @ploc['x'] - 0.3, 'y': @ploc['y'], 'z': @ploc['z'] + 0.3, 'world': @ploc['world']),
                'x-z+': array('x': @ploc['x'] - 0.3, 'y': @ploc['y'], 'z': @ploc['z'] - 0.3, 'world': @ploc['world'])
              )
              @is_player_on_the_solid_block = false
              foreach(@block_location in @block_locations) {
                if(get_block_info(@block_location, 'solid')) {
                  @is_player_on_the_solid_block = true
                  break()
                }
              }
              if(@is_player_on_the_fence || @is_player_on_the_solid_block) {
                @stand_up_task = set_timeout(750, closure() {
                  if(has_bind('mastery.dash.stand_up.'.@player)) { unbind('mastery.dash.stand_up.'.@player)}
                  set_pflight(@player, false)
                  if(phas_flight(@player)) { set_pflying(@player, false) }
                })
                if(!has_bind('mastery.dash.stand_up.'.@player)) {
                  bind('player_toggle_sneak', array('id': 'mastery.dash.stand_up.'.@player), array('sneaking': false, 'player': @player), @event, @player, @stand_up_task, @players_data) {
                    @ploc = ploc(@player)
                    @ploc['y'] += 0.45
                    @fence_locations = array(
                      'x+z+': array('x': @ploc['x'] + 0.3, 'y': @ploc['y'], 'z': @ploc['z'] + 0.3, 'world': @ploc['world']),
                      'x+z-': array('x': @ploc['x'] + 0.3, 'y': @ploc['y'], 'z': @ploc['z'] - 0.3, 'world': @ploc['world']),
                      'x-z+': array('x': @ploc['x'] - 0.3, 'y': @ploc['y'], 'z': @ploc['z'] + 0.3, 'world': @ploc['world']),
                      'x-z+': array('x': @ploc['x'] - 0.3, 'y': @ploc['y'], 'z': @ploc['z'] - 0.3, 'world': @ploc['world'])
                    )
                    @is_player_on_the_fence = false
                    foreach(@fence_location in @fence_locations) {
                      if(string_contains(get_block(@fence_location), 'FENCE') || string_contains(get_block(@fence_location), 'WALL')) {
                        @is_player_on_the_fence = true
                        break()
                      }
                    }
                    @ploc['y'] += 0.5
                    @block_locations = array(
                      'x+z+': array('x': @ploc['x'] + 0.3, 'y': @ploc['y'], 'z': @ploc['z'] + 0.3, 'world': @ploc['world']),
                      'x+z-': array('x': @ploc['x'] + 0.3, 'y': @ploc['y'], 'z': @ploc['z'] - 0.3, 'world': @ploc['world']),
                      'x-z+': array('x': @ploc['x'] - 0.3, 'y': @ploc['y'], 'z': @ploc['z'] + 0.3, 'world': @ploc['world']),
                      'x-z+': array('x': @ploc['x'] - 0.3, 'y': @ploc['y'], 'z': @ploc['z'] - 0.3, 'world': @ploc['world'])
                    )
                    @is_player_on_the_solid_block = false
                    foreach(@block_location in @block_locations) {
                      if(get_block_info(@block_location, 'solid')) {
                        @is_player_on_the_solid_block = true
                        break()
                      }
                    }
                    if(@is_player_on_the_fence || @is_player_on_the_solid_block) {
                      @jump_task = set_timeout(750, closure() {
                        if(has_bind('mastery.dash.jump.'.@player)) { unbind('mastery.dash.jump.'.@player)}
                        set_pflight(@player, false)
                        if(phas_flight(@player)) { set_pflying(@player, false) }
                      })
                      set_pflight(@player, true)
                      if(!has_bind('mastery.dash.jump.'.@player)) {
                        bind('player_jump', array('id': 'mastery.dash.jump.'.@player), array('player': @player), @event, @player, @jump_task, @players_data) {
                          @ploc = ploc(@player)
                          @jump_xz = array('x': @ploc['x'], 'z': @ploc['z'])
                          @fly_task = set_timeout(750, closure() {
                            if(has_bind('mastery.dash.fly.'.@player)) { unbind('mastery.dash.fly.'.@player)}
                            set_pflight(@player, false)
                            if(phas_flight(@player)) { set_pflying(@player, false) }
                          })
                          if(!has_bind('mastery.dash.fly.'.@player)) {
                            bind('player_toggle_flight', array('id': 'mastery.dash.fly.'.@player), array('flying': true), @event, @player, @jump_xz, @fly_task, @players_data) {
                              cancel()
                              set_pflight(@player, false)
                              if(phas_flight(@player)) { set_pflying(@player, false) }
                              @ploc = ploc(@player)
                              @fly_xz = array('x': @ploc['x'], 'z': @ploc['z'])
                              @yaw = get_yaw(@jump_xz, @fly_xz)
                              @dash_count = @players_data[@uuid]['active_skill']['dash']['count']
                              if(@yaw != 'NaN' && @dash_count > 0) {
                                @vector = get_vector(array('yaw': @yaw, 'pitch': 0), 1.25)
                                set_pvelocity(@player, @vector)
                                play_named_sound(@ploc, array('sound': 'entity.bat.takeoff', 'category': 'NEUTRAL', 'volume': 0.3, 'pitch': 1))
                                @dash_count = @players_data[@uuid]['active_skill']['dash']['count']
                                @players_data[@uuid]['active_skill']['dash']['count'] -= 1
                              }
                              if(has_bind('mastery.dash.fly.'.@player)) { unbind('mastery.dash.fly.'.@player) }
                              clear_task(@fly_task)
                              ## flight 바인드 끝 jump, flight 모두 언바인드
                            }
                          }
                          if(has_bind('mastery.dash.stand_up.'.@player)) { unbind('mastery.dash.stand_up.'.@player) }
                          clear_task(@jump_task)
                          ## jump 바인드 끝, stand_up은 이전 조건이므로 언바인드
                        }
                      }
                    } else {
                      if(has_bind('mastery.dash.stand_up.'.@player)) { unbind('mastery.dash.stand_up.'.@player) }
                      if(has_bind('mastery.dash.jump.'.@player)) { unbind('mastery.dash.jump.'.@player) }
                      if(has_bind('mastery.dash.fly.'.@player)) { unbind('mastery.dash.fly.'.@player) }
                      set_pflight(@player, false)
                      if(phas_flight(@player)) { set_pflying(@player, false) }
                    }
                    clear_task(@stand_up_task)
                    ## stand_up 바인드 끝, sneak_down은 interval에 의해 바인드 언바인드가 정해지므로 언바인드 실행 안함
                  }
                }
              } else {
                if(has_bind('mastery.dash.stand_up.'.@player)) { unbind('mastery.dash.stand_up.'.@player) }
                if(has_bind('mastery.dash.jump.'.@player)) { unbind('mastery.dash.jump.'.@player) }
                if(has_bind('mastery.dash.fly.'.@player)) { unbind('mastery.dash.fly.'.@player) }
                set_pflight(@player, false)
                if(phas_flight(@player)) { set_pflying(@player, false) }
              }


            }
          }
        } else {
          if(has_bind('mastery.dash.sneak_down.'.@player)) { unbind('mastery.dash.sneak_down.'.@player) }
          if(has_bind('mastery.dash.stand_up.'.@player)) { unbind('mastery.dash.stand_up.'.@player) }
          if(has_bind('mastery.dash.jump.'.@player)) { unbind('mastery.dash.jump.'.@player) }
          if(has_bind('mastery.dash.fly.'.@player)) { unbind('mastery.dash.fly.'.@player) }
          if(array_contains(array('SURVIVAL', 'ADVENTURE'), pmode(@player))) {
            set_pflight(@player, false)
            if(phas_flight(@player)) { set_pflying(@player, false) }
          }
        } # 대쉬 스킬 끝
        @dash_cooldown = @players_data[@uuid]['active_skill']['dash']['cooldown']
        if(@dash_count < 3) { #대쉬 쿨타임 시작
          if(@dash_cooldown > 1) {
            @players_data[@uuid]['active_skill']['dash']['cooldown'] -= 1
          } else {
            @players_data[@uuid]['active_skill']['dash']['count'] += 1
            @players_data[@uuid]['active_skill']['dash']['cooldown'] = 5 # 1: 40, 2: 30, 3: 20 (숙련 레벨에 따른 쿨다운)
          }
        } # 대쉬 쿨타임 끝

        #actionbar
        if(@dash_count == 3) {
          @cooldown = 'done'
        } else {
          @cooldown = @dash_cooldown
        }

       

        
        switch(@players_data[@uuid]['setting']['en_ko']) {
        case true:
          switch(@players_data[@uuid]['setting']['channel']) {
          case 'general':
            @channel = '\ue3fd'
          case 'guild':
            @channel = '\ue3ff'
          case 'local':
            @channel = '\ue401'
          case 'admin':
            @channel = '\ue403'
          default:
            @channel = '\ue3fd'
          }
        case false:
        switch(@players_data[@uuid]['setting']['channel']) {
          case 'general':
            @channel = '\ue3fe'
          case 'guild':
            @channel = '\ue400'
          case 'local':
            @channel = '\ue402'
          case 'admin':
            @channel = '\ue404'
          default:
            @channel = '\ue3fe'
          }
        }
        @fonts = @files_data['fonts']
        action_msg(@player, @fonts['space.5'].@channel.@fonts['space.-65'].@fonts['space.'.@players_data[@uuid]['setting']['resolution']])
        #action_msg(@player, '대쉬 횟수:'@dash_count'(대기 시간:'@cooldown.')')
        #bossbar        
      }
    }
  })*/
  #export('interface.task', @interface_task)
}

/*
bind('player_join', array('id': 'mastery.fishing.setup'), null, @event) {
  @player = @event['player']
  @fishing_data = array(
  )
  #bind('player_fish', array('id': 'mastery.fishing.reel_out.'.@player), array('player': @player, 'state': 'FISHING'), @event, @player, @fishing_data)
  bind('player_fish', array('id': 'mastery.fishing.bite.'.@player), array('player': @player, 'state': 'BITE'), @event, @player, @fishing_data) {
    cancel()
    set_interval(100, closure() {
      if(!ponline(@player)) {
        clear_task()
        if(has_bind('mastery.fishing.reel_out.'.@player)) { unbind('mastery.fishing.reel_out.'.@player) }
        if(has_bind('mastery.fishing.caught_fish.'.@player)) { unbind('mastery.fishing.reel_in.'.@player) }
        if(has_bind('mastery.fishing.bite.'.@player)) { unbind('mastery.fishing.bite.'.@player) }
      } else {
        @hook = @event['hook']
        if(!entity_exists(@hook)) {
          clear_task()
          if(has_bind('mastery.fishing.caught_fish.'.@player)) { unbind('mastery.fishing.caught_fish.'.@player) }
          if(has_bind('mastery.fishing.bite.'.@player)) { unbind('mastery.fishing.bite.'.@player) }
          #entity_remove(@fishing_players[@player]['armor_stand']) ### 추가 상황에서도 아머스탠드 제거 해줘야 함 (낚시중 서버 꺼져서 아머스탠드가 살아 있을수도 있음)
          #array_remove(@fishing_players, @player) #데이터 초기화
          stop_named_sound(@player, 'entity.fishing_bobber.splash', 'NEUTRAL')
          stop_named_sound(@player, 'entity.entity.player.swim', 'NEUTRAL')
          stop_named_sound(@player, 'entity.entity.player.splash', 'NEUTRAL')
          stop_named_sound(@player, 'entity.item.crossbow.quick_charge_3', 'NEUTRAL')
        } else {
          @hook_location = entity_loc(@hook)
          @hook_location['y'] += 0.125
          @player_location = ploc(@player)
          if(psneaking(@player)) { @y_adjustment = 2.255 } else { @y_adjustment = 2.625 }
          @player_location['y'] += @y_adjustment
          @magnitude = distance(@hook_location, @player_location)
          @vector = ('x': (@hook_location['x'] - @player_location['x']) / @magnitude, 'y': (@hook_location['y'] - @player_location['y']) / @magnitude, 'z': (@hook_location['z'] - @player_location['z']) / @magnitude)
          @rotating_yaw = get_yaw(@player_location, @hook_location)
          @rotating_pitch = get_pitch(@player_location, @hook_location)
          #
          if(@rotating_yaw < 180) {
            if(@player_location['yaw'] > @rotating_yaw && @player_location['yaw'] < @rotating_yaw + 180) {
              @leaning = 'right'
            } else {
              @leaning = 'left'
            }
          } else {
            @opposite_yaw = @rotating_yaw - 180
            if(@player_location['yaw'] < @rotating_yaw && @player_location['yaw'] > @rotating_yaw - 180) {
              @leaning = 'left'
            } else {
              @leaning = 'right'
            }
          }

          if(@leaning == 'left') {
            @new_yaw = @player_location['yaw'] + 0.1
          } else {
            @new_yaw = @player_location['yaw'] - 0.1
          }
          #
          #action_msg(@player, '내_yaw' round(@player_location['yaw'], 2) '위치기준 yaw' round(@rotating_yaw, 2) '좌우 회전 중심'round(@opposite_yaw, 2) @a)
          #relative_teleport(puuid(@player), array('x': ploc()[x], 'y': ploc()[y] + 1, 'z': ploc()[z], 'world':  ploc()['world'], 'yaw': @new_yaw, 'pitch': get_pitch(@player_location, @hook_location)))
        }
        
      }
    })
  }
}
*/
/*
@fishings = array()
bind('player_fish', null, array('state': 'BITE'), @event, @fishings) {
  @player = @event['player']
  @hook = @event['hook']
  @player_location = ploc(@player)
  @hook_location = entity_loc(@hook)
  @direction = array_rand(array(array('left', -90), array('right', 90)), 1, false)[0]
  @moving_yaw = get_yaw(@player_location, @hook_location) + @direction[1]
  @moving_vector = get_vector(array('yaw': @moving_yaw, 'pitch': 0), 0.2)
  play_named_sound(@hook_location, array('sound': 'entity.player.splash', 'category': 'NEUTRAL', 'volume': 0.3, 'pitch': 1 + rand() / 2))
  play_named_sound(@hook_location, array('sound': 'entity.fishing_bobber.splash', 'category': 'NEUTRAL', 'volume': 0.3, 'pitch': 0.85 + rand() / 2))
  play_named_sound(@player_location, array('sound': 'entity.player.splash', 'category': 'NEUTRAL', 'volume': 0.05, 'pitch': 1 + rand() / 2), @player)
  play_named_sound(@player_location, array('sound': 'entity.fishing_bobber.splash', 'category': 'NEUTRAL', 'volume': 0.05, 'pitch': 0.85 + rand() / 2), @player)
  set_entity_velocity(@hook, @moving_vector)
  if(!array_index_exists(@fishings, @player)) {
    @hook_location['yaw'] = 0.0
    @fishings[@player] = array(
      'armor_stand': spawn_entity('ARMOR_STAND', 1, @hook_location, closure(@uuid) { set_entity_spec(@uuid, array('visible': false, 'small': true, 'marker': true, 'poses': array('poseHead': @moving_vector))) set_entity_rider(@hook, @uuid) set_mob_equipment(@uuid, array('HELMET': array('name': 'LEATHER_HORSE_ARMOR', 'meta': array('model': 1)))) })[0],
      'direction': @direction[0]
    )
    
    bind('player_interact', array('id': 'mastery.fishing.click.'.@player), array('player': @player, 'hand': 'main_hand', 'itemname': 'FISHING_ROD', 'button': 'right'), @event, @fishings, @player, @hook) {
      cancel()
      @player_location = ploc(@player)
      @hook_location = entity_loc(@hook)
      @relative_yaw = get_yaw(@player_location, @hook_location)
      if(@relative_yaw < 180) {
        if(@player_location['yaw'] > @relative_yaw && @player_location['yaw'] < @relative_yaw + 180) {
          @leaning = 'right'
        } else {
          @leaning = 'left'
        }
      } else {
        if(@player_location['yaw'] < @relative_yaw && @player_location['yaw'] > @relative_yaw - 180) {
          @leaning = 'left'
        } else {
          @leaning = 'right'
        }
      }
      if(@fishings[@player]['direction'] == 'left') {
        if(@leaning == 'left') {
          @moving_yaw = @relative_yaw - 90
          @draw = false
        } else {
          @moving_yaw = @relative_yaw + 90
          @draw = true
        }
      } else {
        if(@leaning == 'left') {
          @moving_yaw = @relative_yaw - 90
          @draw = true
        } else {
          @moving_yaw = @relative_yaw + 90
          @draw = false
        }
      }
      if(@draw) {
        @magnitude = 0.2 + 0.4 * rand()
        play_named_sound(@player_location, array('sound': 'item.crossbow.quick_charge_3', 'category': 'PLAYERS', 'volume': 0.8, 'pitch': 0.5 + rand() / 2))
        play_named_sound(@player_location, array('sound': 'item.crossbow.quick_charge_3', 'category': 'PLAYERS', 'volume': 0.8, 'pitch': 0.5 + rand() / 2), @player)
      } else {
        @magnitude = 0.5 + rand()
        play_named_sound(@player_location, array('sound': 'entity.fishing_bobber.retrieve', 'category': 'PLAYERS', 'volume': 1, 'pitch': 0.3 + rand() / 2))
        play_named_sound(@player_location, array('sound': 'entity.fishing_bobber.retrieve', 'category': 'PLAYERS', 'volume': 1, 'pitch': 0.3 + rand() / 2), @player)
      }
      @moving_vector = get_vector(array('yaw': @moving_yaw, 'pitch': 0), @magnitude)
      set_entity_velocity(@hook, @moving_vector)
    }
    @direction = array_rand(array(array('left', -90), array('right', 90)), 1, false)[0]
    @int = array(0)
    set_interval(100, closure() {
      if(!entity_exists(@hook)) {
        if(has_bind('mastery.fishing.click.'.@player)) { unbind('mastery.fishing.click.'.@player) }
        if(entity_exists(@fishings[@player]['armor_stand'])) { entity_remove(@fishings[@player]['armor_stand']) } ### 추가 상황에서도 아머스탠드 제거 해줘야 함 (낚시중 서버 꺼져서 아머스탠드가 살아 있을수도 있음)
        array_remove(@fishings, @player)
        stop_named_sound(@player, 'entity.fishing_bobber.splash', 'NEUTRAL')
        stop_named_sound(@player, 'entity.entity.player.swim', 'NEUTRAL')
        stop_named_sound(@player, 'entity.entity.player.splash', 'NEUTRAL')
        stop_named_sound(@player, 'entity.item.crossbow.quick_charge_3', 'NEUTRAL')
        if(has_bind('mastery.fishing.click.'.@player)) { unbind('mastery.fishing.click.'.@player) }
        clear_task()
      } else {
        @player_location = ploc()
        @hook_location = entity_loc(@hook)
        
        set_timeout(integer(rand() * 100), closure() {
          if(rand() > 0.95) {
            @direction = array_rand(array(array('left', -90), array('right', 90)), 1, false)[0]
            @fishings[@player]['direction'] = @direction[0]
            @moving_yaw = get_yaw(@player_location, @hook_location) + @direction[1]
            @moving_vector = get_vector(array('yaw': @moving_yaw, 'pitch': 0), 0.2)
            @moving_vector['y'] = - 0.1 - 0.2 * rand()
            set_entity_velocity(@hook, @moving_vector)
            ###
            play_named_sound(@hook_location, array('sound': 'entity.player.splash', 'category': 'NEUTRAL', 'volume': 0.3, 'pitch': 1 + rand() / 2))
            play_named_sound(@hook_location, array('sound': 'entity.fishing_bobber.splash', 'category': 'NEUTRAL', 'volume': 0.3, 'pitch': 0.85 + rand() / 2))
            play_named_sound(@player_location, array('sound': 'entity.player.splash', 'category': 'NEUTRAL', 'volume': 0.05, 'pitch': 1 + rand() / 2), @player)
            play_named_sound(@player_location, array('sound': 'entity.fishing_bobber.splash', 'category': 'NEUTRAL', 'volume': 0.05, 'pitch': 0.85 + rand() / 2), @player)
            
          } else {
            @direction = @fishings[@player]['direction']
            if(@direction == 'left') { @moving_yaw = get_yaw(@player_location, @hook_location) - 90 } else { @moving_yaw = get_yaw(@player_location, @hook_location) + 90 }
            @moving_vector = get_vector(array('yaw': @moving_yaw, 'pitch': 0), 0.04 * rand())
            if(rand() > 0.9) { @moving_vector['y'] = -0.2 * rand()}
            set_entity_velocity(@hook, @moving_vector)
            @int[0] += 0.05
            set_entity_spec(@fishings[@player]['armor_stand'], array('poses': array('poseHead': array('x': 0, 'y': @moving_yaw / 60, 'z': 0))))
            #action_msg(@int[0] '|' entity_spec(@fishings[@player]['armor_stand'])['poses']['poseHead']['x'] entity_spec(@fishings[@player]['armor_stand'])['poses']['poseHead']['y'] entity_spec(@fishings[@player]['armor_stand'])['poses']['poseHead']['z'])
          }
        })
        if(rand() > 0.7) {
          spawn_particle(@hook_location, 'WATER_BUBBLE')
          play_named_sound(@hook_location, array('sound': 'entity.player.swim', 'category': 'NEUTRAL', 'volume': 0.2, 'pitch': 1 + rand() / 2))
          play_named_sound(@player_location, array('sound': 'entity.player.swim', 'category': 'NEUTRAL', 'volume': 0.08, 'pitch': 1 + rand() / 2), @player)
        }
        @hook_location['y'] += 0.2
        spawn_particle(@hook_location, 'WATER_SPLASH')
        spawn_particle(@hook_location, 'WATER_SPLASH')
        spawn_particle(@hook_location, 'WATER_SPLASH')
        spawn_particle(@hook_location, 'WATER_SPLASH')
        spawn_particle(@hook_location, 'WATER_SPLASH')
        #@fishing_players[@player]['player_location']['yaw'] - ploc(@player)['yaw']
        #@fishing_players[@player]['player_location']['pitch'] - ploc(@player)['pitch']
        #action_msg(@player, @fishing_players[@player]['player_location']['yaw'] - ploc(@player)['yaw'] @fishing_players[@player]['player_location']['pitch'] - ploc(@player)['pitch'])
        #relative_teleport(@player, array(yaw: 1, pitch: 0))
        #set_entity_rotation(puuid(@player), 0, 1)
        #set_entity_velocity(@hook, array('x': 0.05, 'y': 0, 'z': 0))
      }
    })
  } else {
    @fishings[@player]['direction'] = @direction[0]
  }
}

bind('block_break', null, null, @event) {
  @player = @event['player']
  if(array_contains(array('WHEAT', 'CARROTS', 'POTATOS', 'BEETROOTS'), @event['block']) && array_contains(array('SURVIVAL', 'ADVENTURE'), pmode(@player))) {
    @slot = pheld_slot(@player)
    @item = get_inventory_item(puuid(@player), @slot)
    if(!is_null(@item) && array_contains(array('WOODEN_HOE', 'STONE_HOE', 'GOLDEN_HOE', 'IRON_HOE', 'DIAMOND_HOE', 'NETHERITE_HOE'), @item['name'])) {
      if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'damage')) {
        @damage = 0
      } else {
        @damage = @item['meta']['damage']
      }
      if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'enchants') || !array_index_exists(@item['meta']['enchants'], 'unbreaking')) {
        @unbreaking_level = 0
      } else {
        @unbreaking_level = @item['meta']['enchants']['unbreaking']['elevel']
      }
      @breaking_chance = 1 / (@unbreaking_level + 1)
      if(rand() < @breaking_chance) {
        if(is_null(@item['meta'])) {
          @item['meta'] = array('damage': @damage + 1)
        } else {
          @item['meta']['damage'] = @damage + 1
        }
        if(material_info(@item['name'], 'maxDurability') <= @item['meta']['damage']) {
          play_entity_effect(puuid(@player), 'BREAK_EQUIPMENT_MAIN_HAND')
          set_inventory_item(puuid(@player), @slot, null)
        } else {
          set_inventory_item(puuid(@player), @slot, @item)
        }
      }
      @skill_mode = import('farming_skill')
      @location = @event['location']
      switch(@skill_mode) {
      case 'golden_finger':
        if(array_contains(array('WHEAT', 'CARROTS', 'POTATOS'), @event['block'])) {
          @max_age = 7
        } else {
          @max_age = 3
        }
        if(get_blockdata(@location)['age'] == @max_age) {
          @drops = @event['drops']
          array_remove(@drops, 0)
          modify_event('drops', @drops)
          set_timeout(0, closure() { set_block(@location, @event['block']) })
        } else {
          cancel()
        }
        break()
      case 'wide_hand':
        for(@x = -1, @x < 2, @x++) {
          for(@z = -1, @z < 2, @z++) {
            if(@x != 0 || @z != 0) {
              @breaking_location = array('x': @location['x'] + @x, 'y': @location['y'], 'z': @location['z'] + @z, 'world': @location['world'])
              if(array_contains(array('WHEAT', 'CARROTS', 'POTATOS'), @event['block'])) {
                @max_age = 7
              } else {
                @max_age = 3
              }
              if(get_block(@breaking_location) == @event['block'] && get_blockdata(@breaking_location)['age'] == @max_age) {
                @item = get_inventory_item(puuid(@player), @slot)
                if(!is_null(@item) && array_contains(array('WOODEN_HOE', 'STONE_HOE', 'GOLDEN_HOE', 'IRON_HOE', 'DIAMOND_HOE', 'NETHERITE_HOE'), @item['name'])) {
                  if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'damage')) {
                    @damage = 0
                  } else {
                    @damage = @item['meta']['damage']
                  }
                  if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'enchants') || !array_index_exists(@item['meta']['enchants'], 'unbreaking')) {
                    @unbreaking_level = 0
                  } else {
                    @unbreaking_level = @item['meta']['enchants']['unbreaking']['elevel']
                  }
                  @breaking_chance = 1 / (@unbreaking_level + 1)
                  if(rand() < @breaking_chance) {
                    if(is_null(@item['meta'])) {
                      @item['meta'] = array('damage': @damage + 1)
                    } else {
                      @item['meta']['damage'] = @damage + 1
                    }
                    if(material_info(@item['name'], 'maxDurability') <= @item['meta']['damage']) {
                      play_entity_effect(puuid(@player), 'BREAK_EQUIPMENT_MAIN_HAND')
                      set_inventory_item(puuid(@player), @slot, null)
                    } else {
                      set_inventory_item(puuid(@player), @slot, @item)
                    }
                  }
                  sudo(player(), '/loot spawn' @breaking_location['x'] + 0.5 @breaking_location['y'] @breaking_location['z'] + 0.5 'mine' integer(@breaking_location['x']) integer(@breaking_location['y']) integer(@breaking_location['z']) 'mainhand')
                  set_block(@breaking_location, 'AIR')
                }
              }
            }
          }
        }
        break()
      default:
        break()
      }
    }
    
  }
}

bind('player_interact', null, null, @event) {
  #broadcast(@event['action'])
  @player = @event['player']
  if(!is_null(@event['item']) && array_contains(array('WOODEN_HOE', 'STONE_HOE', 'GOLDEN_HOE', 'IRON_HOE', 'DIAMOND_HOE', 'NETHERITE_HOE'), @event['item']['name']) && @event['action'] == 'right_click_block' && array_contains(array('SURVIVAL', 'ADVENTURE'), pmode(@player))) {
    @event['location']['y'] += 1
    if(array_contains(array('GRASS_BLOCK', 'DIRT'), @event['block']) && array_contains(array('AIR', 'CAVE_AIR', 'VOID_AIR'), get_block(@event['location']))) {
      if(@event['hand'] == 'main_hand') {
        @slot = pheld_slot(@player)
      } else {
        @slot = 40
      }
      @item = get_inventory_item(puuid(@player), @slot)
      @locatoin = @event['location']
      if(rand() > 0.6666) {
        if(pcooldown(@player, @item['name']) == 0) {
          sudo(player(), '/particle minecraft:composter' @event['location']['x'] + 0.5 @event['location']['y'] + 0.1 @event['location']['z'] + 0.5 0.3 0 0.3 0 5)
          set_pcooldown(@player, 'WOODEN_HOE', 30)
          set_pcooldown(@player, 'STONE_HOE', 15)
          set_pcooldown(@player, 'IRON_HOE', 10)
          set_pcooldown(@player, 'DIAMOND_HOE', 7)
          set_pcooldown(@player, 'NETHERITE_HOE', 4)
          set_pcooldown(@player, 'GOLDEN_HOE', 2)
        }
      } else {
        if(pcooldown(@player, @item['name']) == 0) {
          cancel()
          if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'damage')) {
            @damage = 0
          } else {
            @damage = @item['meta']['damage']
          }
          if(is_null(@item['meta']) || !array_index_exists(@item['meta'], 'enchants') || !array_index_exists(@item['meta']['enchants'], 'unbreaking')) {
            @unbreaking_level = 0
          } else {
            @unbreaking_level = @item['meta']['enchants']['unbreaking']['elevel']
          }
          @breaking_chance = 1 / (@unbreaking_level + 1)
          if(rand() < @breaking_chance) {
            if(is_null(@item['meta'])) {
              @item['meta'] = array('damage': @damage + 1)
            } else {
              @item['meta']['damage'] = @damage + 1
            }
            
            if(material_info(@item['name'], 'maxDurability') == @item['meta']['damage']) {
              play_entity_effect(puuid(@player), 'BREAK_EQUIPMENT_MAIN_HAND')
              set_inventory_item(puuid(@player), @slot, null)
            } else {
              set_inventory_item(puuid(@player), @slot, @item)
            }
          }
          sudo(player(), '/particle minecraft:smoke' @event['location']['x'] + 0.5 @event['location']['y'] + 0.1 @event['location']['z'] + 0.5 0.3 0 0.3 0 10)
          set_pcooldown(@player, 'WOODEN_HOE', 30)
          set_pcooldown(@player, 'STONE_HOE', 15)
          set_pcooldown(@player, 'IRON_HOE', 10)
          set_pcooldown(@player, 'DIAMOND_HOE', 7)
          set_pcooldown(@player, 'NETHERITE_HOE', 4)
          set_pcooldown(@player, 'GOLDEN_HOE', 2)
        }
      }
    }
  }
}
*/
  #@hook_location['y'] -= 0.8
  #@fishing_array = array(
  #  'dummy_item': drop_item(@hook_location, array('name': 'STONE'), false),
  #  'dummy_armorstand': spawn_entity('ARMOR_STAND', 1, @hook_location, closure(@uuid) { set_entity_spec(@uuid, array('visible': false, 'small': true)) })[0]
  #)
  #set_timeout(1, closure() {
  #  set_entity_rider(@fishing_array['dummy_item'], @fishing_array['dummy_armorstand'])
  #  set_entity_rider(@fishing_array['dummy_armorstand'], @hook)
  #})
  #@dummy_item = drop_item(@hook_location, array('name': 'STONE'), false)
  #spawn_entity('ARMOR_STAND', 1, @hook_location, closure(@dummy_armorstand) {
    #set_entity_spec(@dummy_armorstand, array('visible': false, 'small': true))
    #set_entity_rider(@dummy_item, @dummy_armorstand)
    #set_entity_rider(@dummy_armorstand, @hook)
  #})
  #@hook_vector = entity_velocity(@hook)
  #@fishing_array = array('is_ready': false, 'uuids': array('hook': @hook, 'dummy_item': null, 'dummy_armorstand': null))
  #set_interval(200, closure() {
    #if(!entity_exists(@hook)) {
      #clear_task()
    #} else {
      #if(@fishing_array['is_ready']) {
        #@hook_vector = entity_velocity(@hook)
        #@hook_location = entity_loc(@hook)
        #@under_block = get_block(@hook_location)
        #@hook_location['y'] += 0.25
        #@upper_block = get_block(@hook_location)

        #if(!@fishing_array['is_ready'] && @under_block == 'WATER' && @upper_block != 'WATER' && @hook_vector['magnitude'] < 0.1 && @hook_vector['x'] < 0.1 && @hook_vector['x'] < 0.1) {
        #  @fishing_array['is_ready'] = true
        #  #set_entity_loc(@hook, entity_loc(@hook))
        #  @dummy_item = drop_item(@hook_location, array('name': 'STONE'), false)

          
        #}
        #action_msg(@player, '던져지는 중' @fishing_array)
      #} else {
        #action_msg(@player, '안착' @fishing_array)
        #set_entity_velocity(@hook, array('x': 0, 'y': rand() / 5 * -1, 'z': 0))
      #}
    #}
  #})
  #@target_location = location_shift(@hook_location, @hook_vector)
  #broadcast(@target_location)
  #broadcast(round(@hook_location['x'], 3) round(@hook_location['y'], 3) round(@hook_location['z'], 3))
  #broadcast(round(@target_location['x'], 3) round(@target_location['y'], 3) round(@target_location['z'], 3))
  #shoot_projectile(player(), 'ARMOR_STAND', @target_location)
  #broadcast(a)
  #@uuid = drop_item(@hook_location, array('name': 'STONE'), false)
  #spawn_entity('PIG', 1, @hook_location, closure(@uuid) {
    #broadcast(@uuid)
    #set_timeout(100, closure() {
    #  broadcast(entity_spec(@uuid))
    #})
    #set_entity_spec(@uuid, array('pickupdelay': '-100'))
    #broadcast(entity_spec(@uuid))
    #set_entity_silent(@uuid, true)
    #set_can_pickup_items(@uuid, false)
    #set_entity_ai(@uuid, false)
    #set_mob_age(@uuid, -1, ture)
    #set_entity_velocity(@uuid, @hook_vector)
  #})

#include_dir('includes', true)
