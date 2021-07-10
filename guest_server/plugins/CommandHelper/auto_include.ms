proc _color(@color) {
  if(reg_count('^#[a-fA-F0-9]{6}$', @color)) {
    return('§x§'.@color[1].'§'.@color[2].'§'.@color[3].'§'.@color[4].'§'.@color[5].'§'.@color[6])
  } else {
    return(color(@color))
  }
}