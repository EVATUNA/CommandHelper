console('EvaData loaded')

proc _load_data(@uuid, @players_data) {
  pogu_get('setting_data:'.@uuid, closure(@connected, @value) { @players_data[@uuid]['setting'] = json_decode(@value) })
  pogu_get('chating_data:'.@uuid, closure(@connected, @value) { @players_data[@uuid]['chating'] = json_decode(@value) })
}
proc _save_data(@uuid, @players_data, @clear) {
  pogu_set('setting_data:'.@uuid, json_encode(@players_data[@uuid]['setting']), closure(@connected, @value) {})
  pogu_set('chating_data:'.@uuid, json_encode(@players_data[@uuid]['chating']), closure(@connected, @value) {})
  if(@clear) {
    array_remove(@players_data, @uuid)
  }
}
proc _new_data(@uuid, @players_data) {
  @players_data[@uuid]['chating'] = array(
    'channel': 'general',
    'en_ko': false,
    'selected_badge': ''
  )
  @players_data[@uuid]['setting'] = array(
    'interface': array(
      'resolution': 427,
      'hand': 'right'
    ),
    'chating': array(
      'type': 'general', // general / messenger
      'alignment': 'none', // none / center / left / right
      'listening': array(
        'general': true,
        'local': true,
        'guild': true,
        'admin': true
      ),
      'observer_mode': false
    ),
    "sound": array(
      'chating': false,
      'mention': true
    ),
    'is_premium': false
  )
  _save_data(@uuid, @players_data, false)
}

proc _verify_request(@player, @uuid, @players_state, @players_data) {
  @player_state = array(
    'player': @player,
    'verifing': false,
    'verify_countdown': -1,
    'shifting': false,
    'guild': null,
    'guild_role': null,
    'is_op': pisop(@player)
  )
  if(array_index_exists(@players_state, @uuid)) {
    @data = array(
      'player': @player,
      'uuid': @uuid,
      'type': 'join_by_shifting' #타 서버에서 이 데이터를 받을 시 서버 이동중 상태'만!' 이동 완료 상태로 바꾸면 됨
    )
    _bungeecord_foward(@player, 'PlayerStateChangeEvent', @data)
    _verify_accept(@uuid, @players_state, @players_data)
    @players_state[@uuid] = @player_state
  } else {
    @data = array(
      'player': @player,
      'uuid': @uuid,
      'type': 'join_by_logging_in', #타 서버에서 이 데이터를 받을 시 길드 설정 및 오피 설정을 해준 값을 state로 저장함
    )
    _bungeecord_foward(@player, 'PlayerStateChangeEvent', @data)
    @players_state[@uuid] = @player_state
    @players_state[@uuid]['verifing'] = true
    @players_state[@uuid]['verify_countdown'] = 60
  }
}

proc _verify_accept(@uuid, @players_state, @players_data) {
  @players_state[@uuid]['verifing'] = false
  @players_state[@uuid]['verify_countdown'] = -1
  pogu_has('setting_data:'.@uuid, closure(@connected, @has) {
    if(@has) {
      _load_data(@uuid, @players_data)
    } else {
      _new_data(@uuid, @players_data)
    }
  })
}

bind('player_join', null, null, @event, @players_state, @players_data, @players_item) {
  @player = @event['player']
  @uuid = puuid(@player)
  _verify_request(@player, @uuid, @players_state, @players_data)
  @players_item[@uuid] = array(
    'is_inv_open': false,
    'hand': null,
    'armor': null,
    'enchantments': array(
      'hand': null,
      'armor': null
    )
  )
  @items = array(
    'hand': get_inventory_item(@uuid, pheld_slot(@player)),
    'armor': get_inventory_item(@uuid, 37)
  )
  _update_item(@player, @uuid, @items, @players_item)
}

foreach(@player in all_players()) {
  @uuid = puuid(@player)
  _verify_request(@player, @uuid, @players_state, @players_data)
  @players_item[@uuid] = array(
    'is_inv_open': false,
    'hand': null,
    'armor': null,
    'enchantments': array(
      'hand': null,
      'armor': null
    )
  )
  @items = array(
    'hand': get_inventory_item(@uuid, pheld_slot(@player)),
    'armor': get_inventory_item(@uuid, 37)
  )
  _update_item(@player, @uuid, @items, @players_item)
}

bind('player_quit', null, null, @event, @players_state, @players_data, @players_item) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(!@players_state[@uuid]['shifting']) {
    if(array_index_exists(@players_state, @uuid)) {
      array_remove(@players_state, @uuid)
    }
    @data = array(
      'player': @player,
      'uuid': @uuid,
      'type': 'quit'
    )
    _bungeecord_foward(@player, 'PlayerStateChangeEvent', @data)  #@player를 서버마다 배치해둔 임시 플레이어로 설정해야 함 타 서버에서 로그아웃 한 경우 포워드 읽은걸로 이 배열 지워줘야 함
  } 
  if(array_index_exists(@players_data, @uuid)) {
    _save_data(@uuid, @players_data, true)
  }
  if(array_index_exists(@players_item, @uuid)) {
    array_remove(@players_item, @uuid)
  }
}

bind('player_command', null, null, @event, @players_state, @players_data, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(@players_state[@uuid]['verifing']) {
    cancel()
    if(@event['command'] == '/resourcepackverify') {
      @player = player(@uuid)
      tellraw(@player, array(string_multiply('\n', 100).'인증이 완료되었습니다.'))
      @data = array(
        'player': @player,
        'uuid': @uuid,
        'type': 'verify_resourcepack'
      )
      _bungeecord_foward(@player, 'PlayerStateChangeEvent', @data)
      _verify_accept(@uuid, @players_state, @players_data)
    }
  }
}

proc _send_request_msg(@player, @players_state) {
  @uuid = puuid(@player)
  @message = array(
    'translate': '%1$s%3$s',
    'with': array(
      array(
        array(
          'text': string_multiply('\n', 100)
        ),
        array(
          'text': '설정된 에바참치 리소스팩을 찾을 수 없습니다!\n\n',
          'color': 'red'
        ),
        array(
          'translate': '인증을 완료하기 전까지 일부 시스템 사용이 제한되며\n%s초 후, 서버와 연결이 자동으로 종료됩니다.\n\n',
          'with': array(
            array(
              'text': @players_state[@uuid]['verify_countdown'],
              'color': 'yellow'
            )
          ),
          'color': 'white'
        ),
        array(
          'text': '리소스팩을 설정한 후, 채팅메시지를 클릭해주세요.\n'
        ),
        array(
          'text': '리소스팩을 다운로드하려면 이 채팅메시지를 클릭해주세요.',
          'underlined': true,
          'color': 'gray',
          'clickEvent': array(
            'action': 'open_url',
            'value': 'https://evatuna.fish/'
          )
        ),
      ),
      array(
        'translate': '%1$s%4$s',
        'with': array(
          array(
            array(
              'text': string_multiply('\n', 100)
            ),
            array(
              'text': '에바참치 리소스팩의 업데이트가 필요합니다!\n\n',
              'color': 'red'
            ),
            array(
              'translate': '인증을 완료하기 전까지 일부 시스템 사용이 제한되며\n%s초 후, 서버와 연결이 자동으로 종료됩니다.\n\n',
              'with': array(
                array(
                  'text': @players_state[@uuid]['verify_countdown'],
                  'color': 'yellow'
                )
              ),
              'color': 'white'
            ),
            array(
              'text': '최신 버전으로 리소스팩을 설정한 후, 채팅메시지를 클릭해주세요.\n'
            ),
            array(
              'text': '최신 버전의 리소스팩을 다운로드하려면 이 채팅메시지를 클릭해주세요.',
              'underlined': true,
              'color': 'gray',
              'clickEvent': array(
                'action': 'open_url',
                'value': 'https://evatuna.fish/'
              )
            )
          ),
          array(
            array(
              'text': string_multiply('\n', 100)
            ),
            array(
              'text': '최신 버전의 에바참치 리소스팩이 확인되었습니다\n\n',
              'color': 'green'
            ),
            array(
              'translate': '인증을 완료하기 전까지 일부 시스템 사용이 제한되며\n%s초 후, 서버와 연결이 자동으로 종료됩니다.\n\n',
              'with': array(
                array(
                  'text': @players_state[@uuid]['verify_countdown'],
                  'color': 'yellow'
                )
              ),
              'color': 'white'
            ),
            array(
              'text': '이 채팅메시지를 클릭할 시, 인증이 완료됩니다.',
              'underlined': true,
              'color': 'gray',
              'clickEvent': array(
                'action': 'run_command',
                'value': '/resourcepackverify'
              )
            )
          )
        )
      )
    ),
  )
  tellraw(@player, @message)
}

@interval_task = set_interval(1000, closure() {
  #broadcast(@players_state)
  foreach(@player in all_players()) {
    @uuid = puuid(@player)
    if(array_index_exists(@players_data, @uuid)) {
      _send_action_msg(@player, @players_data[@uuid], @text)
    } else {
      if(@players_state[@uuid]['verifing']) {
        if(@players_state[@uuid]['verify_countdown'] > 0) {
          _send_request_msg(@player, @players_state)
          @players_state[@uuid]['verify_countdown'] -= 1
        } else {
          if(@players_state[@uuid]['verify_countdown'] != -1) {
          @players_state[@uuid]['verify_countdown'] -= 1 #인증 서버기준 데이터 설정
          #인증 서버 이동으로 대채 예정
          pkick(@player, '리소스팩 설정 후, 다시 접속하여 인증해 주세요!')
          }
        }
      }
    }
  }
})

@cron_task = set_cron('*/1 * * * *', closure() {
  foreach(@player in all_players()) {
    @uuid = @player
    if(import('state.'@uuid) == 'none') {
      if(array_index_exists(@players_data, @uuid)) {
        _save_data(@uuid, @players_data, false)
      }
    }
  }
})

bind('plugin_message_received', null, array('channel': 'BungeeCord'), @event, @players_state) {
  foreach(@key: @byte in @event['bytes']) {
    if(@key != 0) {
      if(@byte == 0) {
        @subchannel_size = @key - 2
        break()
      }
    }
  }
  @data = array(
    'subchannel': string(ba_get_bytes(@event['bytes'], @subchannel_size, 2)),
    'value': json_decode(string(ba_get_bytes(@event['bytes'], array_size(@event['bytes']) - @subchannel_size - 6, @subchannel_size + 6)))
  )
  broadcast(@data)
  switch(@data['subchannel']) {
  case 'PlayerStateChangeEvent':
    @player = @data['value']['player']
    @uuid = @data['value']['uuid']
    switch(@data['value']['type']) {
    case 'join_by_logging_in':
      @players_state[@uuid] = array(
        'player': @player,
        'verifing': true,
        'verify_countdown': -1,
        'shifting': false,
        'guild': null,
        'guild_role': null,
        'is_op': pisop(@player)
      )
      break()
    case 'verify_resourcepack':
      @players_state[@uuid] = array(
        'player': @player,
        'verifing': false,
        'verify_countdown': -1,
        'shifting': false,
        'guild': null,
        'guild_role': null,
        'is_op': pisop(@player)
      )
      break()
    case 'shift':
      @players_state[@uuid] = array(
        'player': @player,
        'verifing': false,
        'verify_countdown': -1,
        'shifting': true,
        'guild': null,
        'guild_role': null,
        'is_op': pisop(@player)
      )
      break()
    case 'join_by_shifting':
      @players_state[@uuid] = array(
        'player': @player,
        'verifing': false,
        'verify_countdown': -1,
        'shifting': false,
        'guild': null,
        'guild_role': null,
        'is_op': pisop(@player)
      )
      break()
    case 'quit':
      array_remove(@players_state, @uuid)
      break()
    }
    break()
  case 'PlayerChatEvent':
    break()
  }
}