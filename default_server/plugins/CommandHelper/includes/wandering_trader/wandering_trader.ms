
export('wandering_trader_data', yml_decode(comp_read("wandering_trader.yml")))

proc _getData() {
  return(import('wanderingTrader'))
}

proc _setData(@newValue = array('traders': array(), /*tradeID: {'liveTime': time, }*/ 'config': null, 'viewers': array(), 'events': array(),'comming': array('time': time(), 'mode': 15), /*- 3000 * 1000*/ 'taskID': null)) {
  export('wanderingTrader', @newValue)
  return(@newValue)
}

proc _mainTask(@server) {
  @value = _getData()
  if(@value['taskID'], throw('ms.lang.Error', 'alreadyStartTask'))
  @value['taskID'] = set_interval(1000, closure() {
    @value = _getData()
    @config = @value['config']
    @comming = @value['comming']
    @time = 2400 - ((time() - @comming['time']) / 1000)
    @mode = @comming['mode']
    @modes = array(
      '15': '10',
      '10': '5',
      '5': '1',
      '1': 'start',
      'start': '15'
    )
    @min = (@mode.'min')
    if(@time <= 0 && @mode == 'start') {
      _system_broadcast('\ue4db', 'white', @config['startMessage'], @server)
      @comming['mode'] = 15
      @comming['time'] = time()
      _spawnTrader(array_rand(@config['trader']['spawnList'], 1, false)[0], @server)
    } else if(is_numeric(@mode) && @time <= @mode * 60 && @modes[@mode] != @mode) {
      _system_broadcast('\ue4db', 'white', @config['minMessage'][@min], @server)
      @comming['mode'] = @modes[@mode]
    }
    _setData(@value)
  })
  _setData(@value)
  return()
}

proc _traderForm(@stayTime = null) {
  if(!@stayTime, throw('ms.lang.Error', 'inputStayTime'))
  return(array(
    'stayTime': time() + @stayTime * 60 * 1000,
    'taskID': null,
    'uuid': null,
    'tradeItems': _assignTraderItems(), // page: list (3)
  ))
}

void proc _smokeParticle(@traderLoc) {
  @traderLoc['y'] += 1
  spawn_particle(@traderLoc, array(
    'particle': 'SMOKE_NORMAL',
    'xoffset': 3,
    'yoffset': 3,
    'zoffset': 3,
    'count': 100
  ))
}

proc _tradeItem(@player, @traderID = 0, @type, @page = 0, @slot, @tradeQty = 1, @server) {
  @keyArr = array( // key 계산 나중에 개선하기
    'BUY': array(
      14: 0, 15: 1, 16: 2,
      23: 3, 24: 4, 25: 5,
      32: 6, 33: 7, 34: 8
    ),
    'SELL': array(
      10: 0, 11: 1, 12: 2,
      19: 3, 20: 4, 21: 5,
      28: 6, 29: 7, 30: 8
    )
  )
  @key = @keyArr[@type][@slot]
  @value = _getData()
  @tradeItem = @value['traders'][@traderID]['tradeItems'][@type][@page][@key]
  switch(@type) {
  case 'SELL':
    # 구매 가능한 갯수, 개인이 구매 가능한 갯수 구하기
    @stock = @tradeItem['meta']['stock']
    @tradeHistory = @tradeItem['meta']['tradeHistory']
    if(@stock < 1 && @stock != -1) {
      return(-1)
    }
    @limit = @tradeItem['meta']['limit']
    if(array_index_exists(@tradeHistory, @player)) {
      if(@limit != -1 && @tradeHistory[@player] >= @limit || @stock == -1 && @tradeHistory[@player] >= @limit) {
        return(-2)
      }
    } else {
      @tradeHistory[@player] = 0
    }
    if(@limit != -1) {
      @minLimit = @limit - @tradeHistory[@player]
      if(@minLimit < @tradeQty) {
        @tradeQty -= @tradeQty - @minLimit
      }
    }
    if(@stock != -1 && @stock < @tradeQty) {
      @tradeQty -= @tradeQty - @stock
    }
    
    # 아이템 비교
    @detail = 'NONE'
    if(array_index_exists(@tradeItem, 'meta', 'detail')) {
      @detail = @tradeItem['meta']['detail']
    }
    
    # 아이템 뺏기
    @takingItem = array_deep_clone(@tradeItem)
    @takingItem['qty'] = @tradeQty
    @taken_qty = _takeItem(@player, @takingItem, @detail)

    # 재고 제거
    if(@stock != -1) {
      @tradeItem['meta']['stock'] -= @taken_qty
    }
    @tradeHistory[@player] += @taken_qty

    # 저장
    _setData(@value)

    # 돈 지급 및 로깅
    @price = @tradeItem['meta']['price'] * @taken_qty
    if(@price > 0) {
      acc_add(@player, @price)
      _logging('shop', time(), @server, 'wandering_trader', @player, puuid(@player), @tradeItem, 'sell', @taken_qty, @tradeItem['meta']['price'])
    }

    break()
  case 'BUY':
    @stock = @tradeItem['meta']['stock']
    @tradeHistory = @tradeItem['meta']['tradeHistory']
    if(@stock < 1 && @stock != -1) {
      return(-1)
    }
    @limit = @tradeItem['meta']['limit']
    if(array_index_exists(@tradeHistory, @player)) {
      if(@limit != -1 && @tradeHistory[@player] >= @limit || @stock == -1 && @tradeHistory[@player] >= @limit) {
        return(-2)
      }
    } else {
      @tradeHistory[@player] = 0
    }
    if(@limit != -1) {
      @minLimit = @limit - @tradeHistory[@player]
      if(@minLimit < @tradeQty) {
        @tradeQty -= @tradeQty - @minLimit
      }
    }
    if(@stock != -1 && @stock < @tradeQty) {
      @tradeQty -= @tradeQty - @stock
    }
    @price = @tradeItem['meta']['price'] * @tradeQty
    if(acc_balance(@player) < @price, tmsg(@player, '\ue4e1 캔이 부족합니다.'); return(-1))
    acc_subtract(@player, @price)
    @itemArr = array_deep_clone(@tradeItem)
    @itemArr['qty'] = @tradeQty
    if(@stock != -1) {
      @tradeItem['meta']['stock'] -= @tradeQty
    }
    @tradeHistory[@player] += @tradeQty
    _setData(@value)
    pgive_item(@player, @itemArr)
    _logging('shop', time(), @server, 'wandering_trader', @player, puuid(@player), @itemArr, 'buy', @tradeQty, @tradeItem['meta']['price'])
    //_playNamedSound(@player, 'entity.wandering_trader.yes')
  }
  return(0)
}

proc _randomStringToInt(@string) {
  @splitArr = split('~', @string)
  if(array_size(@splitArr) > 1) {
    @return = rand(integer(@splitArr[0]), integer(@splitArr[1]) + 1)
  } else {
    @return = integer(@splitArr[0])
  }
  return(@return)
}

proc _setItemMeta(@traderListArr) {
  @splitArr = null
  if(!@traderListArr || is_array(@traderListArr) && array_size(@traderListArr) < 1, return(array(array())))
  foreach(@key : @item in @traderListArr) {
    @item['meta']['stock'] = _randomStringToInt(@item['meta']['stock'])
    @item['meta']['maxStock'] = @item['meta']['stock']
    @item['meta']['tradeHistory'] = array()
  }
  return(@traderListArr)
}

proc _assignTraderItems() {
  @config = _getData()['config']
  @itemList = @config['tradeItemList']
  @itemLimit = @config['trader']['selectItemCount']
  @buySelectCount = _randomStringToInt(@itemLimit['BUY'])
  @sellSelectCount = _randomStringToInt(@itemLimit['SELL'])
  @sellList = array_deep_clone(@itemList['SELL'])
  @buyList = array_deep_clone(@itemList['BUY'])

  @buyList = _setItemMeta(@buyList)
  @sellList = _setItemMeta(@sellList)
  if(@buySelectCount > 0) {
    @buyItemList = _paging(array_rand(@buyList, @buySelectCount, false), 9)
  } else {
    @buyItemList = array(array())
  }
  if(@sellSelectCount > 0) {
    @sellItemList = _paging(array_rand(@sellList, @sellSelectCount, false), 9)
  } else {
    @sellItemList = array(array())
  }
  
  @selectItems = array('BUY': @buyItemList, 'SELL': @sellItemList)
  return(@selectItems)
}

proc _spawnTrader(@locArray = null, @server) {
  if(!@locArray || !is_array(@locArray), throw('ms.lang.Error', 'inputLocArr'))
  @value = _getData()
  @traderList = @value['traders']
  @traderID = array_size(@traderList)
  @config = @value['config']
  @traderForm = _traderForm(@config['stayTime'])

  // SpawnTrader
  @traderUUID = spawn_entity('WANDERING_TRADER', 1, @locArray)[0]
  set_entity_ai(@traderUUID, false)
  @traderForm['uuid'] = @traderUUID
  @traderForm['taskID'] = set_interval(300, closure() {
    @value = _getData()
    @traderInfo = @value['traders'][@traderID]
    @traderUUID = @traderInfo['uuid']
    if(!entity_exists(@traderUUID), _closeTrader(@traderID, @server))
    if(@traderInfo['stayTime'] <= time()) {
      _closeTrader(@traderID, @server)
    } else {
      // UpdateBellTime
      @viewers = @value['viewers']
      foreach(@viewer : @arr in @viewers) {
        @uiName = _uiName(@viewer)
        @bell = _timeBell(@value['traders'][@arr['openTraderID']]['stayTime'])
        set_inventory_item(@uiName, 4, @bell)
      }
      // TrackingSee
      @traderLoc = entity_loc(@traderUUID)
      @radiusPlayers = players_in_radius(@traderLoc, 5)
      if(array_size(@radiusPlayers)  > 0) {
        @targetPlayer = @radiusPlayers[0]
        @targetLoc = ploc(@targetPlayer)
        @targetLoc['y'] += 1

        @seeYaw = get_yaw(@traderLoc, @targetLoc)
        @seePitch = get_pitch(@traderLoc, @targetLoc)
        set_entity_rotation(@traderUUID, @seeYaw, @seePitch)
      }
    }
  })
  @traderList[@traderID] = @traderForm
  _setData(@value)
  _mainEventBind(@server)

  _smokeParticle(entity_loc(@traderUUID))
}

proc _closeTrader(@traderID = 0, @server) {
  @value = _getData()
  @traderList = @value['traders']
  if(!array_index_exists(@traderList, @traderID), throw('ms.lang.Error', 'notExistsTraderID'))
  @traderInfo = @traderList[@traderID]

  // ClearTask
  @taskID = @traderInfo['taskID']
  clear_task(@taskID)
  @taskID = null

  foreach(@viewer : @arr in @value['viewers']) {
    if(@arr['openTraderID'] == @traderID, close_pinv(@viewer))
  }
  @traderUUID = @traderInfo['uuid']
  _smokeParticle(entity_loc(@traderUUID))
  // RemoveTrader
  if(array_size(@traderList) <= 1, _mainEventunBind();)
  if(entity_exists(@traderUUID), entity_remove(@traderUUID))
  array_remove(@traderList, @traderID)
  _setData(@value)

  _system_broadcast('\ue4db', 'white', @value['config']['endMessage'], @server)
}

proc _backgroundInvForm() {
  @uiInvs = array()
  for(@slot = 0, @slot < 54, @slot++) { @uiInvs[@slot] = null }
  @pane = array('meta': array('display': ''), 'name': 'GRAY_STAINED_GLASS_PANE')
  for(@y = 0, @y < 54, @y += 9) {
    @yz = @y / 9
    if(@yz == 0 || @yz == 5) {
      for(@x = 0, @x < 9, @x++) { @uiInvs[@y + @x] = @pane } 
    }
    for(@x = 0, @x < 3, @x++) { @uiInvs[@y + @x * 4] = @pane } 
  }
  return(@uiInvs)
}

proc _timeBell(@stayTime) {
  @remainSecond = ceil((@stayTime - time()) / 1000)
  @remainMin = integer(@remainSecond / 60)
  return(array(
    'name': 'BELL', 'qty': @remainMin + 1,
    'meta': array(
      'display': '§f남은 시간',
      'lore': '§c'.@remainSecond.'§7초 후 상인이 떠납니다.'
    )
  ))
}

proc _uiName(@player = null) {
  if(!@player, throw('ms.lang.Error', 'inputPlayerName'))
  return('traderVirtualUI.'.@player)
}

proc _uiForm(@viewer = null, @traderID = 0, @seePageArr = array('SELL': 0, 'BUY': 0)) {
  @uiInvs = _backgroundInvForm()
  @value = _getData()
  @traderInfo = @value['traders'][@traderID]
  @tradeList = @traderInfo['tradeItems']
  // DesignInv
  @bell = _timeBell(@traderInfo['stayTime'])
  @sellPane = array('name': 'RED_STAINED_GLASS_PANE', 'meta': array('display': '§c판매 거래 목록'))
  @buyPane = array('name': 'LIME_STAINED_GLASS_PANE', 'meta': array('display': '§a구매 거래 목록'))
  @uiInvs[2] = @sellPane; @uiInvs[47] = @sellPane;
  @uiInvs[6] = @buyPane; @uiInvs[51] = @buyPane;
  @uiInvs[4] = @bell;
  @undoPageItem = array(
    'name': 'PRISMARINE_SHARD', 'meta': array('flags': array('HIDE_ENCHANTS'), 'display': '§f이전 페이지', 'lore': '§7클릭 시 이전 페이지로 이동합니다.')
  )
  @nextPageItem = array(
    'name': 'FEATHER', 'meta': array('flags': array('HIDE_ENCHANTS'), 'display': '§f다음 페이지', 'lore': '§7클릭 시 다음 페이지로 이동합니다.')
  )
  @banner = array(
    'name': 'MOJANG_BANNER_PATTERN', 'meta': array('display': 'n 페이지')
  )
  // SellDesign
  @banner['meta']['display'] = ('§d'.(@seePageArr['SELL'] + 1)'페이지')
  if(@seePageArr['SELL'] < 1) {
    @undoPageItem['meta']['display'] = '§4이전 페이지가 없습니다.'
    @undoPageItem['meta']['enchants'] = array()
  } else {
    @undoPageItem['meta']['display'] = '§f이전 페이지'
    @undoPageItem['qty'] = @seePageArr['SELL']
    @undoPageItem['meta']['enchants'] = array(array('elevel': 1, 'etype': 'DIG_SPEED'))
  }
  if(!array_index_exists(@tradeList['SELL'], @seePageArr['SELL'] + 1)) {
    @nextPageItem['meta']['display'] = '§4다음 페이지가 없습니다.'
    @nextPageItem['meta']['enchants'] = array()
  } else {
    @nextPageItem['meta']['enchants'] = array(array('elevel': 1, 'etype': 'DIG_SPEED'))
    @nextPageItem['meta']['display'] = '§f다음 페이지'
  }
  @nextPageItem['qty'] = @seePageArr['SELL'] + 2
  @uiInvs[39] = array_deep_clone(@nextPageItem)
  @uiInvs[37] = array_deep_clone(@undoPageItem)
  @uiInvs[38] = array_deep_clone(@banner)
  // BuyDesign
  if(@seePageArr['BUY'] < 1) {
    @undoPageItem['meta']['display'] = '§4이전 페이지가 없습니다.'
    @undoPageItem['meta']['enchants'] = array()
  } else {
    @undoPageItem['meta']['display'] = '§f이전 페이지'
    @undoPageItem['qty'] = @seePageArr['BUY'] 
    @undoPageItem['meta']['enchants'] = array(array('elevel': 1, 'etype': 'DIG_SPEED'))
  }
  @banner['meta']['display'] = ('§d'.(@seePageArr['BUY'] + 1)'페이지')
  if(!array_index_exists(@tradeList['BUY'], @seePageArr['BUY'] + 1)) {
    @nextPageItem['meta']['display'] = '§4다음 페이지가 없습니다.'
    @nextPageItem['meta']['enchants'] = array()
  } else {
    @nextPageItem['meta']['enchants'] = array(array('elevel': 1, 'etype': 'DIG_SPEED'))
    @nextPageItem['meta']['display'] = '§f다음 페이지'
  }
  @nextPageItem['qty'] = @seePageArr['BUY'] + 2
  @uiInvs[43] = array_deep_clone(@nextPageItem)
  @uiInvs[41] = array_deep_clone(@undoPageItem)
  @uiInvs[42] = array_deep_clone(@banner)

  @sellList = @tradeList['SELL']
  @buyList = @tradeList['BUY']
  
  @seePageList = array('SELL': array_deep_clone(@sellList[@seePageArr['SELL']]), 'BUY': array_deep_clone(@buyList[@seePageArr['BUY']]))
  foreach(@type : @list in @seePageList) {
    for(@y = 1, @y < 4, @y++) {
      @minX = 1; @maxX = 4;
      if(@type == 'BUY', @minX = 5; @maxX = 8;)
      for(@x = @minX, @x < @maxX, @x++) {
        @slot = @y * 9 + @x
        if(!array_index_exists(@list, 0), break(2))
        @itemArr = array_deep_clone(@list[0])
        if(!array_index_exists(@itemArr, 'name'), break(2))
        @display = @itemArr['name']

        @limitQty = 0
        @tradeHistory = @itemArr['meta']['tradeHistory']
        if(array_index_exists(@tradeHistory, @viewer), @limitQty = @tradeHistory[@viewer])

          @max_stock = @itemArr['meta']['maxStock']
          if(@max_stock < 0) { @max_stock = 1 }
          @stock = @itemArr['meta']['stock']
          if(@stock == 0) {
            @stock_color = '§c'
          } else if(@stock < @max_stock ** 0.5) {
            @stock_color = '§6'
          } else if(@stock < @max_stock ** 0.75) {
            @stock_color = '§e'
          } else {
            @stock_color = '§a'
          }

          @max_limit = @itemArr['meta']['limit']
          if(@max_limit < 0) { @max_limit = 1 }
          @limit = @max_limit - @limitQty
          if(@limit == 0) {
            @limit_color = '§c'
          } else if(@limit < @max_limit ** 0.5) {
            @limit_color = '§6'
          } else if(@limit < @max_limit ** 0.75) {
            @limit_color = '§e'
          } else {
            @limit_color = '§a'
          }

        if(@type == 'SELL') {

          @itemArr['meta']['lore'] = array(
            '§7가격:§f'@itemArr['meta']['price'].'캔',
            "§7판매 제한:@stock_color @stock/@max_stock",
            "§7개인 판매 제한:@limit_color @limit/@max_limit",
            '§b쉬프트 좌 클릭 시 16개씩 판매합니다.'
          )
          if(@stock == -1, @itemArr['qty'] = 1; @itemArr['meta']['lore'][1] = '§7판매 제한:§a 없음')
          if(@limit == -1, @itemArr['meta']['lore'][2] = '§7개인 판매 제한:§a 없음')

          if(@stock != -1 && @stock < 1 || @limit != -1 && @limit < 1) {
            @itemArr['meta']['lore'][] = '§4더 이상 판매할 수 없습니다.'
          }

        } else if(@type == 'BUY') {

          @itemArr['meta']['lore'] = array(
            '§7가격:§f'@itemArr['meta']['price'].'캔',
            "§7구매 제한:@stock_color @stock/@max_stock",
            "§7개인 구매 제한:@limit_color @limit/@max_limit",
            '§b쉬프트 좌 클릭 시 16개씩 구매합니다.'
          )
          if(@stock == -1, @itemArr['qty'] = 1; @itemArr['meta']['lore'][1] = '§7구매 제한:§a 없음')
          if(@limit == -1, @itemArr['meta']['lore'][2] = '§7개인 구매 제한:§a 없음')

          if(@stock != -1 && @stock < 1 || @limit != -1 && @limit < 1) {
            @itemArr['meta']['lore'][] = '§4더 이상 구매할 수 없습니다.'
          }

        }
        @itemArr['qty'] = 1 //@itemArr['meta']['stock'] // 일부 아이템 최대 갯수 핵방지때문에 무조건 1개로 표시

        @uiInvs[@slot] = @itemArr
        array_remove(@list, 0)
      }
    }
  }
  return(@uiInvs)
}

void proc _openTraderUI(@viewer = null, @traderID = 0, @seePageArr = array('SELL': 0, 'BUY': 0), @server) {
  @uiName = _uiName(@viewer)
  @value = _getData()
  @tradeItems = @value['traders'][@traderID]['tradeItems']
  if(!array_index_exists(@tradeItems['SELL'], @seePageArr['SELL']) || !array_index_exists(@tradeItems['BUY'], @seePageArr['BUY'])) {
    return()
  }
  @uiInvs = _uiForm(@viewer, @traderID, @seePageArr)
  if(!array_contains(get_virtual_inventories(), @uiName), create_virtual_inventory(@uiName, 54, ''))
  set_inventory(@uiName, @uiInvs)
  // BindEvent
  @viewers = @value['viewers']
  if(!array_index_exists(@viewers, @viewer)) {
    popen_inventory(@viewer, @uiName)
  }
  @viewers[@viewer] = array('openTraderID': @traderID, 'seePage': @seePageArr)
  _setData(@value)
  _uiEventBind(@server)
}

proc _mainEventBind(@server) {
  if(has_bind('traderDamage'), return())
  bind('entity_damage', array('id': 'traderDamage'), array('type': 'WANDERING_TRADER'), @e) {
    @traderList = _getData()['traders']
    foreach(@traderID : @traderInfo in @traderList) {
      if(@traderInfo['uuid'] == @e['id'], cancel(); break();)
    }
  }
  bind('player_interact_entity', array('id': 'traderInteract'), array('hand': 'main_hand'), @e, @server) {
    if(@e['clicked'] == 'WANDERING_TRADER') {
      cancel()
      @traderList = _getData()['traders']
      foreach(@traderID : @traderInfo in @traderList) {
        if(@traderInfo['uuid'] == @e['id']) {
          _openTraderUI(@e['player'], @traderID, array('SELL': 0, 'BUY': 0), @server)
          break()
        }
      }
    }
  }
  bind('shutdown', array('id': 'traderShutdownEvent'), null, @e, , @server) {
    @traderList = _getData()['traders']
    foreach(@traderID : @traderInfo in @traderList) {
      _closeTrader(@traderID, @server)
    }
  }
}

proc _mainEventunBind() { // TEST
  unbind('traderDamage')
  unbind('traderInteract')
  unbind('traderShutdownEvent')
}

proc _uiEventunBind() {
  @value = _getData()
  foreach(@eventID in @value['events']) {
    unbind(@eventID)
    array_remove_values(@value['events'], @eventID)
  }
  _setData(@value)
}

proc _uiEventBind(@server) {
  @value = _getData()
  @eventID = 'traderInventoryClick'
  if(!array_contains(@value['events'], @eventID)) {
    if(!has_bind(@eventID)) {
      @value['events'][] = bind('inventory_close', array('id': 'traderInventoryClose'), array('virtual': true), @e) {
        @value = _getData()
        @viewers = @value['viewers']
        @player = @e['player']
        if(array_index_exists(@viewers, @player)) {
          array_remove(@viewers, @player)
          _setData(@value)
          //_writeLog('trader', @player.'이 거래를 끝냄.')
          if(array_size(@viewers) < 1, _uiEventunBind())
        }
      }
      @value['events'][] = bind('inventory_click', array('id': @eventID), array('virtual': true), @e, @server) {
        @value = _getData()
        @viewers = @value['viewers']
        @player = @e['player']
        if(array_index_exists(@viewers, @player)) {
          cancel()
          if(@e['action'] == 'PICKUP_ALL' || @e['clicktype'] == 'SHIFT_LEFT') {

            @viewerInfo = @viewers[@player]
            @seePageArr = array_deep_clone(@viewerInfo['seePage'])
            @traderID = @viewerInfo['openTraderID']
            @slot = @e['rawslot']
            @slotItem = @e['slotitem']
            @tradeQty = 1
            if(@e['clicktype'] == 'SHIFT_LEFT', @tradeQty = 16)

            if(!@slotItem, exit())
            switch(@slot) {
              case 37:
              @seePageArr['SELL'] -= 1
              case 41:
              @seePageArr['BUY'] -= 1
              case 39:
              @seePageArr['SELL'] += 1
              case 43:
              @seePageArr['BUY'] += 1

              case 14..16: // BUY
              case 23..25:
              case 32..34:
              _tradeItem(@player, @traderID, 'BUY', @seePageArr['BUY'], @slot, @tradeQty, @server)
              case 10..12:  // SELL
              case 19..21:
              case 28..30:
              _tradeItem(@player, @traderID, 'SELL', @seePageArr['SELL'], @slot, @tradeQty, @server)
            }
            _openTraderUI(@player, @traderID, @seePageArr, @server)
            foreach(@viewer : @arr in @viewers) {
              _openTraderUI(@viewer, @arr['openTraderID'], @arr['seePage'], @server)
            }

          }
        }
      }
      _setData(@value)
    }
  }  
}

register_command('trader', array(
  'permission': 'trader',
  'executor': closure(@command, @player, @args) {
    if(array_size(@args) > 0) {
      @value = _getData()
      @traderList = @value['traders']
      switch(@args[0]) {
      case 'list':
        foreach(@traderID : @traderInfo in @traderList) {
          @traderLoc = entity_loc(@traderInfo['uuid'])
          @displayLoc = array_implode(array(integer(@traderLoc['x']), integer(@traderLoc['y']), integer(@traderLoc['z']), @traderLoc['world']), ',')
          msg('§b'@traderID.'번 상인:§7'@displayLoc)
        }
        break()
      case 'spawn':
        @playerLoc = ploc(@player)
        @playerLoc['y'] += 1
        _spawnTrader(@playerLoc, @server)
        break()
      case 'remove':
        if(array_index_exists(@args, 1) && array_index_exists(@traderList, @args[1])) {
          @traderID = integer(@args[1])
          _closeTrader(@traderID, @server)
          msg( @traderID.'번 상인이 삭제되었습니다.')
        } else {
          msg('존재하지 않는 상인 번호입니다.')
        }
        break()
      case 'debug':
        msg(_getData())
        break()
      case 'come':
        @comming = @value['comming']
        @comming['mode'] = 'start'
        @comming['time'] = 0
        _setData(@value)
        break()
      }
      exit()
    }
  }
))

@value = _getData()
if(!@value, @value = _setData(), _mainEventBind())
if(!@value['config'], @value['config'] = import('wandering_trader_data'); _setData(@value))

if(@server == 'main') {
  set_timeout(5000, closure() {
    _mainTask(@server)
  })
}