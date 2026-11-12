extends RefCounted
static func zoom_for(spec:Dictionary,aiming:bool)->float:
 if not aiming:return 1.0
 var zoom:float=spec.get('aim_zoom',1.0)
 return clampf(zoom,0.25,1.0) if is_finite(zoom) else 1.0
static func camera_offset(mouse:Vector2,viewport_size:Vector2,zoom:float,aiming:bool)->Vector2:
 # Solve C=(P+M)/2 with M=C+(mouse-screen_center)/zoom.
 return (mouse-viewport_size*.5)/zoom if aiming else Vector2.ZERO
