proc _formConvertGuiForm(@item, @itemId) {
  @item['itemId'] = @itemId // @itemId 선언
  if(array_index_exists(@item, 'meta')) {
    if(!array_index_exists(@item['meta'], 'lore')) {
      @item['meta']['lore'] = array() // 로어 선언
    }
    @item['qty'] = 1 // 갯수 설정
    if(array_index_exists(@item['meta'], 'price')) {
      @item['meta']['lore'][] = '§f§m                                '
      if(array_index_exists(@item['meta']['price'], 'buy')) {
        @item['meta']['lore'][] = ('§f구매 가격:§c'@item['meta']['price']['buy'].'캔') // 구매 금액 로어 추가
      }
      if(array_index_exists(@item['meta']['price'], 'sell')) {
        @item['meta']['lore'][] = ('§f판매 가격:§c'@item['meta']['price']['sell'].'캔') // 판매 금액 로어 추가
      }
      @item['meta']['lore'][] = '§f§m                                '
    }
  } else {
    @item['meta'] = array('lore': array())
  }
  return(@item)
}

proc _returnStoreDatas() { ## STORES 폴더 상점 불러오는 함수
  @targetPath = 'STORES/'
  @guiFrames = array()
  @products = array()
  @inProducts = array()
  foreach(@fileName in list_files(@targetPath)) {
    @storeName = split('.', @fileName)[0] // 파일 이름에 . 들어가면 안됨!
    @inProducts = yml_decode(read(@targetPath.@fileName))
    @guiFrames[@storeName] = array()
    foreach(@slot : @product in @inProducts['PRODUCTS']) {
      @guiFrames[@storeName][@slot] = _formConvertGuiForm(array_deep_clone(@product), length(@products))
      @products[] = @product
    }
  }
  return(array(
    'guiFrames': @guiFrames,
    'products': @products, // 주의! 다른 파일에서 똑같은 메타의 아이템을 가격 다르게 해서 다루면 안됨!
    'viewers': array()
  ))
}

@stores = _returnStoreDatas()

proc _compareItemArr(@itemA, @itemB, @detail) { //@itemA는 @product @itemB는 판매 하려 했던 아이템
  if(is_array(@itemA) && is_array(@itemB)) {
    if(array_index_exists(@itemA['meta'], 'price')) {array_remove(@itemA['meta'], 'price')}
    if(array_index_exists(@itemA['meta'], 'detail')) {array_remove(@itemA['meta'], 'detail')}
    if(array_index_exists(@itemA['meta'], 'opengui')) {array_remove(@itemA['meta'], 'opengui')}
    if(array_index_exists(@itemA, 'qty')) {array_remove(@itemA, 'qty')}
    if(array_index_exists(@itemB, 'qty')) {array_remove(@itemB, 'qty')}
    switch(@detail) {
    case 'ALL': //아이템 데이터가 완전히 똑같은지
      if(@itemA == @itemB) {
        @return = true
      } else {
        @return = false
      }
      break()
    case 'DISPLAY': //아이템 겉모습(아이템 모델, 디스플레이, 로어)이 같은지
      if(@itemA['name'] == @itemB['name']) {
        @return = true
        if(@return && array_index_exists(@itemA['meta'], 'display')) {
          if(!@itemB['meta'] || !@itemB['meta']['display'] || @itemA['meta']['display'] != @itemB['meta']['display']) {
            @return = false
          }
        } else if(@itemB['meta'] && @itemB['meta']['display']) {
          @return = false
        }
        if(@return && array_index_exists(@itemA['meta'], 'model')) {
          if(!@itemB['meta'] || !@itemB['meta']['model'] || @itemA['meta']['model'] != @itemB['meta']['model']) {
            @return = false
          }
        } else if(@itemB['meta'] && @itemB['meta']['model']) {
          @return = false
        }
        if(@return && array_index_exists(@itemA['meta'], 'lore')) {
          if(!@itemB['meta'] || !@itemB['meta']['lore'] || @itemA['meta']['lore'] != @itemB['meta']['lore']) {
            @return = false
          }
        } else if(@itemB['meta'] && @itemB['meta']['lore']) {
          @return = false
        }
      } else {
        @return = false
      }
      break()
    case 'NONE': //아이템 코드가 같은지 
      if(@itemA['name'] == @itemB['name']) {
        @return = true
      } else {
        @return = false
      }
      break()
    }
  } else {
    @return = false
  }
  return(@return)
}

proc _takeItem(@player, @take_item, @detail) {
  @inventory = pinv(@player)
  @take_qty = @take_item['qty'] #가져갈 갯수
  array_remove(@take_item, 'qty')
  @taken_qty = 0 #가져간 갯수
  foreach(@slot : @item in @inventory) {
    if(@item) {
      @clone_item = array_deep_clone(@item) #인벤토리 포리치 돌린 아이템
      @qty = @clone_item['qty']
      array_remove(@clone_item, 'qty')
      if(_compareItemArr(@take_item, @clone_item, @detail)) {
        if(@take_qty == -1) {
          @taken_qty += @inventory[@slot]['qty']
          @inventory[@slot]['qty'] = 0
          set_inventory_item(puuid(@player), @slot, @inventory[@slot])
        } else if(@qty > @take_qty) {
          @taken_qty += @take_qty 
          @inventory[@slot]['qty'] -= @take_qty
          @take_qty -= @qty
          set_inventory_item(puuid(@player), @slot, @inventory[@slot])
          if(@take_qty < 0) {
            break()
          }
        } else {
          @taken_qty += @inventory[@slot]['qty']
          @inventory[@slot]['qty'] = 0
          set_inventory_item(puuid(@player), @slot, @inventory[@slot])
          break()
        }
      }
    }
  }
  //set_pinv(@player, @pInv)
  return(@taken_qty)
}

void proc _buyItem(@player, @itemMeta) { # 구매
  @money = acc_balance(@player)
  @purchase_price = @itemMeta['meta']['price']['buy'] * @itemMeta['qty']
  if(@money >= @purchase_price) {
    acc_subtract(@player, @purchase_price)
    @minItemCount = pgive_item(@player, @itemMeta)
    if(@minItemCount > 0) {
      @itemMeta['qty'] = @minItemCount
      drop_item(ploc(@player), @itemMeta)
      msg('§c인벤토리에 공간이 없어 아이템이 바닥에 떨어집니다!')
    }
  } else {
    #돈 부족
  }
}

void proc _sellItem(@player, @itemMeta, @detail, @shop_log_path) { # 판매
  @price = @itemMeta['meta']['price']['sell']
  @taken_qty = _takeItem(@player, @itemMeta, @detail)
  @selling_price = @price * @taken_qty
  if(@selling_price > 0) {
    acc_add(player(), @selling_price)
    if(is_proc('_shop_logging')) {
      @uuid = puuid(@player)
      _shop_logging(@shop_log_path, @player, @uuid, 'sell', @itemMeta, @taken_qty, @selling_price)
    }
  }
}

proc _itemMetaAddLore(@itemMeta, @message) {
  if(!array_index_exists(@itemMeta, 'meta'), @itemMeta['meta'] = array('lore': array()))
  if(!array_index_exists(@itemMeta['meta'], 'lore'), @itemMeta['meta']['lore'] = array())
  @itemMeta['meta']['lore'][] = @message
  return(@itemMeta)
}

proc _setupFrame(@storeName, @player, @stores) { ## gui 열 때 구성시켜주는 함수
  @viewers = @stores['viewers']
  @products = @stores['products']
  @guiFrames = @stores['guiFrames']

  @tradeInfo = @viewers[@player]['tradeInfo']
  @frame = array()
  for(@slot = 0, @slot < 54, @slot++, @frame[@slot] = null)
  
  @count = @tradeInfo['count']
  @convertCount = ('§c'.@count.'개§f')
  @enchanted = false
  
  if(@count <= -1) {
    @count = 1
    if(@tradeInfo['type'] == 'SELL') {
      @convertCount = '§c모두§f'
      @enchanted = true
    } else {
      @tradeInfo['count'] = 1
      @convertCount = '§c1개§f'
    }
  }
  if(@tradeInfo['type'] == 'BUY') {
    @koreanType = '§c§l§o구입§f'
  } else {
    @koreanType = '§c§l§o판매§f'
  }
  @addLores = array(
    '§f왼 클릭시 다음 아이템을'@convertCount @koreanType.'합니다.',
    '§b쉬프트 왼 클릭시 구매 갯수를 변경합니다.',
    '§b쉬프트 우 클릭시 구매/판매 모드로 변경합니다.'
  )

  foreach(@slot : @itemMeta in array_deep_clone(@guiFrames[@storeName])) {
    @itemId = @itemMeta['itemId']
    @hereItemMeta = @products[@itemId]
    if(array_index_exists(@hereItemMeta, 'meta')) {
      if(array_index_exists(@hereItemMeta['meta'], 'opengui')) {
        #_itemMetaAddLore(@itemMeta, '§f왼 클릭시 해당 창으로 이동합니다.')
      } else if(array_index_exists(@hereItemMeta['meta'], 'price')) {
        if(@tradeInfo['type'] == 'BUY') {
          if(array_index_exists(@hereItemMeta['meta']['price'], 'buy')) {
            _itemMetaAddLore(@itemMeta, @addLores[0])
          } else {
            _itemMetaAddLore(@itemMeta, '§f해당 아이템은 §c§l§o구입§f할 수 없습니다.')
          }
        } else {
          if(array_index_exists(@hereItemMeta['meta']['price'], 'sell')) {
            _itemMetaAddLore(@itemMeta, @addLores[0])
          } else {
            _itemMetaAddLore(@itemMeta, '§f해당 아이템은 §c§l§o판매§f할 수 없습니다.')
          }
        }
        _itemMetaAddLore(@itemMeta, @addLores[1])
        _itemMetaAddLore(@itemMeta, @addLores[2])
        #@itemMeta['qty'] = 1 #@count 로 할경우 상점gui상에서 선택한 갯수로 보임
      }
    }
    @frame[@slot] = @itemMeta
  }
  return(@frame)
}

proc _setupEvent(@player, @stores, @shop_log_path) { ## GUI 이벤트 함수(클릭 이벤트 여깄슴)
  @guiFrames = @stores['guiFrames']
  @viewers = @stores['viewers']
  @products = @stores['products']
  @returnList = array()
  @returnList[] = bind('inventory_click', null, array('virtual': true, 'player': @player), @e, @player, @guiFrames, @viewers, @stores, @products, @shop_log_path) {
    cancel()
    @hitSlot = @e['rawslot']
    if(@hitSlot < 54, cancel()) # STORE CLICK CANCEL

    @viewerInfo = @viewers[@player]
    @storeName = @viewerInfo['storeName']
    @guiFrame = @guiFrames[@storeName]
    if(array_index_exists(@guiFrame, @hitSlot)) {
      @itemId = @guiFrame[@hitSlot]['itemId']
      @tradeInfo = @viewerInfo['tradeInfo']
      @hitItemMeta = @products[@itemId]
      if(@e['action'] == 'MOVE_TO_OTHER_INVENTORY') {
        if(array_index_exists(@hitItemMeta, 'meta') && array_index_exists(@hitItemMeta['meta'], 'price')) {
          ## COUNT CHANGE
          if(@e['leftclick']) {
            @counts = array(1, 16, 32, 64, -1)
            @index = array_index(@counts, @tradeInfo['count']) + 1
            if(@tradeInfo['type'] == 'BUY' && @index > 3) {
              @index = 0
            } else {
              if(!array_index_exists(@counts, @index)) {
                @index = 0
              }
            }
            @tradeInfo['count'] = @counts[@index]
          }
          ## TYPE CHANGE
          if(@e['rightclick']) {
            switch(@tradeInfo['type']) {
              case 'BUY':
              @newType = 'SELL'
              case 'SELL':
              @newType = 'BUY'
            }
            @tradeInfo['type'] = @newType
          }
        }
      } else if(@e['action'] == 'PICKUP_ALL' && array_index_exists(@hitItemMeta, 'meta')) {
        if(array_index_exists(@hitItemMeta['meta'], 'opengui')) {
          @storeName = @hitItemMeta['meta']['opengui']
        } else if(array_index_exists(@hitItemMeta['meta'], 'price')) {
          if(array_index_exists(@hitItemMeta['meta']['price'], 'buy') && @tradeInfo['type'] == 'BUY') {
            @hitItemMeta['qty'] = @tradeInfo['count']
            _buyItem(@player, @hitItemMeta)
          } else if(array_index_exists(@hitItemMeta['meta']['price'], 'sell') && @tradeInfo['type'] == 'SELL') { ## SELL ITEM
            @targetItem = array_deep_clone(@hitItemMeta)
            @targetItem['qty'] = @tradeInfo['count']
            @detail = 'NONE'
            if(array_index_exists(@hitItemMeta['meta'], 'detail')) {
              @detail = @hitItemMeta['meta']['detail']
            }
            _sellItem(@player, @targetItem, @detail, @shop_log_path)
          }
        }
      }
      _showGui(@player, @storeName, @stores, @shop_log_path)
    }
  }
  @returnList[] = bind('inventory_drag', null, array('virtual': true), @e, @player) {
    if(@e['player'] != @player, exit())
    if(@e['rawslots'][0] < 54, cancel())
  }
  @returnList[] = bind('inventory_close', null, array('virtual': true), @e, @player, @viewers) {
    if(@e['player'] != @player, exit())
    foreach(@eventId in @viewers[@player]['events']) {
      unbind(@eventId)
    }
    array_remove(@viewers, @player)
  }
  return(@returnList)
}

proc _existGui(@guiId) {
  if(array_contains(get_virtual_inventories(), @guiId), return(true))
  return(false)
}

proc _guiId(@player) { return('STOREGUI.'.@player) }

void proc _showGui(@player, @storeName, @stores, @shop_log_path) { ## GUI 여는 함수
  @guiId = _guiId(@player)

  @viewers = @stores['viewers']
  if(!_existGui(@guiId), create_virtual_inventory(@guiId, 54, ''))
  if(!array_index_exists(@viewers, @player)) {
    popen_inventory(@player, @guiId)
    @viewers[@player] = array( ## SET VALUE
      'events': _setupEvent(@player, @stores, @shop_log_path),
      'storeName': @storeName,
      'tradeInfo': array(
        'count': 1,
        'type': 'BUY'
      )
    )
  } else {
    @viewers[@player]['storeName'] = @storeName
  }
  @guiFrame = _setupFrame(@storeName, @player, @stores)
  set_inventory(@guiId, @guiFrame)
}

register_command('quickeasyshop', array(
  'aliases': array('store', 'evatunastore'),
  'executor': closure(@prefix, @sender, @inArguments) {
    _showGui(@sender, @inArguments[0], @stores, @shop_log_path)
  },
  'tabcompleter': closure(@prefix, @sender, @inArguments) {
    return(array())
  }
))