array proc _locForm(array @targetLoc = array(0, 0, 0, "world")) { # 좌표 배열 단순화
    array @convertForm = array(
        @targetLoc[0],
        @targetLoc[1],
        @targetLoc[2],
        @targetLoc[3]
    )
    return(@convertForm)
}

boolean proc _compareLoc(array @aLoc, array @bLoc) { 
    # 좌표가 같을 경우 TRUE, 일치 하지 않을 경우 FALSE
    int @aLocSize = array_size(@aLoc)
    
    int @samePoint = 0
    for(int @i = 0, @i < @aLocSize, @i++) {
        if(@aLoc[@i] == @bLoc[@i], @samePoint++)
        if(@samePoint >= @aLocSize, return(true))
    }
    return(false)
}
boolean proc _RHG_containLocInALL(array @targetLoc, array @RHGlocs) {
    foreach(array @saveLoc in @RHGlocs) {
        if(_compareLoc(@saveLoc, @targetLoc), return(true))
    }
    return(false)
}