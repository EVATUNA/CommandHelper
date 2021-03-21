console('EvaEnchant loaded')

## Essence Data Load
@essences = array()
foreach(@file in list_files('essence_tables')) {
  @essence = replace(@file, '.json', '')
  async_read('essence_tables/'.@file, closure(@data) {
    @essences[@essence] = json_decode(@data)
  })
}

proc _get_enchanted_item(@enchanting_item, @entries, @luck) {
  @total_weight = 0
  foreach(@key: @entry in @entries) {
    @weight = @entry['weight']
    if(array_index_exists(@entry, 'quality')) {
      @quality = @entry['quality']
    } else {
      @quality = 0
    }
    @weight = @weight + @quality * @luck # new_weight = quality x luck + weight
    if(@weight < 0) {
      @weight = 0
    }
    @entries[@key]['weight'] = @weight
    @total_weight += @weight
  }
  @result_weight = @total_weight * round(rand(), 5)
  @min_weight = 0
  @final_entry = null
  foreach(@entry in @entries) {
    @weight = @entry['weight']
    @max_weight = @min_weight + @weight
    if(@max_weight > @result_weight) {
      @final_entry = @entry
      break()
    } else {
      @min_weight = @max_weight
    }
  }
  @enchanted_item = @enchanting_item
  if(!is_null(@enchanting_item) && !is_null(@enchanting_item['meta']) && array_index_exists(@enchanting_item['meta'], 'modifiers')) {
    @lore_size = array_size(@enchanting_item['meta']['modifiers'])
  } else {
    @lore_size = 0
  } 
  if(!is_null(@final_entry)) {
    @enchanted_item['meta']['lore'][@lore_size] = ''
    @enchanted_item['meta']['lore'][@lore_size + 1] = '§f'.@final_entry['icon'].' '.hexcolor(@final_entry['color']).@final_entry['name']
    @descriptions = @final_entry['descriptions']
    foreach(@key: @description in @descriptions) {
      @enchanted_item['meta']['lore'][@lore_size + 2 + @key] = '§7'.@description
    }
  }
  return(@enchanted_item)
}