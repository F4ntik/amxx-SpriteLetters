"""Reference layout for inspecting real model geometry outside the game."""
def layout(width,height):
    items=[]
    def rect(x,y,w,h,zone):
        xx=x
        for wx in range(9,0,-1):
            if not w&(1<<wx):continue
            yy=y
            for hy in range(7,0,-1):
                if not h&(1<<hy):continue
                frame=(wx-1)*7+hy-1
                if zone==0:family='panel_bg_a' if frame<32 else 'panel_bg_b';body=frame%32
                elif zone<=2:family='panel_edges';body=(zone-1)*9+wx-1
                else:family='panel_edges';body=18+(zone-3)*7+hy-1
                items.append(dict(x=xx,y=yy,w=1<<wx,h=1<<hy,zone=zone,family=family,body=body))
                yy+=1<<hy
            xx+=1<<wx
    rect(4,4,width-8,height-8,0);rect(4,0,width-8,4,1);rect(4,height-4,width-8,4,2);rect(0,4,4,height-8,3);rect(width-4,4,4,height-8,4)
    for k in range(4):items.append(dict(x=width-4 if k%2 else 0,y=height-4 if k//2 else 0,w=4,h=4,zone=5,family='panel_corners',body=k))
    return items
