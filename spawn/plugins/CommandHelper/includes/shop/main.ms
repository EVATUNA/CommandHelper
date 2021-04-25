mixed proc _getStore() { return(import('store')) }
void proc _setStore(array @newStore = array(
  'gui': array(), ## gui 구조를 미리 짜서 올려놓음
  'products': array() ## 물품들의 상세 정보
)) { export('store', @newStore) }
array proc _getStoreGuiFrame(string @store) {
  return(_getStore()['gui'][@store])
}
string proc _path() {
  return('stores/')
}

array proc _itemConversionGuiForm(array @item, int @itemid) {
  #####################################
  ## gui에 표시될 아이템 기본 배열
  #####################################
  array @conversionItem = array(
    'meta': array(
      'lore': array()
    ),
    'name': @item['name'],
    'qty': 1,
    'itemid': @itemid
  )

  #####################################
  ## 아이템 display, lore 설정
  #####################################
  try {
    @conversionItem['meta']['display'] = @item['meta']['data']['display']['title']
  } catch(IndexOverflowException @e) {
    try {
      @conversionItem['meta']['display'] = @item['meta']['display']
    } catch(IndexOverflowException @e) {
      @conversionItem['meta']['display'] = @item['name']
    }
  }
  try {
    @conversionItem['meta']['lore'] = @item['meta']['data']['display']['lore']
  } catch(IndexOverflowException @e) {
    try {
      @conversionItem['meta']['lore'] = @item['meta']['lore']
    } catch(IndexOverflowException @e) { }
  }
  #####################################
  ### 가격, 판매 금액 추가
  #####################################
  double @purchase = 0.0
  double @sell = 0.0
  try {
    @purchase += @item['meta']['data']['price']['purchase']
  } catch(IndexOverflowException @e) { }
  try {
    @sell += @item['meta']['data']['price']['sell']
  } catch(IndexOverflowException @e) { }
  boolean @line = false
  if(@purchase > 0) {
    if(!@line, @line = true; @conversionItem['meta']['lore'][] = '§f§m                             ')
    @conversionItem['meta']['lore'][] = ('§f구매 가격:§c'@purchase.'캔')
  }
  if(@sell > 0) {
    if(!@line, @line = true; @conversionItem['meta']['lore'][] = '§f§m                             ')
    @conversionItem['meta']['lore'][] = ('§f판매 가격:§c'@sell.'캔')
  }
  if(@line, @conversionItem['meta']['lore'][] = '§f§m                             ')

  return(@conversionItem)
}

array proc _loadStores() {
  array @guiframe = array()
  array @producsts = array()
  string @path = _path()
  string @storename; array @storeProducsts;
  foreach(@filename in list_files(@path)) {
    @storename = split('.', @filename)[0]
    @storeProducsts = yml_decode(read(@path.@filename))
    @guiframe[@storename] = array()
    foreach(@slot : @producst in @storeProducsts['clicked']) {
      @guiframe[@storename][@slot] = _itemConversionGuiForm(@producst, length(@producsts)) ## length로 itemid 지정
      ## products에 id를 넣음
      @producsts[] = @producst
    }
  }
  return(array('gui': @guiframe, 'products': @producsts))
}
// gui에서 클릭한 아이템의 itemid를 구하고, products에 itemid를 넣어 구매가격 알아낸 후 구매, 판매 진행

_setStore(_loadStores())

###
array proc _basicFrame(string @store) {
  array @frame = array()
  for(int @slot = 0, @slot < 54, @slot++, @frame[@slot] = null)
  ## gui design
  foreach(@slot : @item in _getStoreGuiFrame(@store)) {
    @frame[@slot] = @item
  }
  return(@frame)
}

mixed proc _getData() { return(import('storegui')) }
void proc _setData(array @newData = array(
  'viewers': array(),
)) { export('storegui', @newData) }

string proc _guiid(string @viewer) { return('storegui.'.@viewer) }
void proc _showGui(string @viewer, string @store = 'main') {
  string @guiid = _guiid(@viewer)
  array @frame = _basicFrame(@store)
  if(!_existsGui(@guiid), create_virtual_inventory(@guiid, 54, ''))
  set_inventory(@guiid, @frame)
  popen_inventory(@viewer, @guiid)
}

register_command('evatunastore', array(
  'aliases': array('store'),
  'executor': closure(@cmd, @sender, @inputArgs) {
    _showGui(@sender)
  },
  'tabcompleter': closure(@cmd, @sender, @inputArgs) {
    return(array())
  }
))