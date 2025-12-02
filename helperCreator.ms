-- ?????? ?????? ???? ??? ???? ???????? (HEX 0x0EFF02 ? RGB 14,255,2)
global CREATED_HELPERS = #()
global HELPER_COLOR = (color 14 255 2)

fn mkHelper name pos typ:"dummy" parent:undefined size:0.1 rotAngles:(eulerAngles -90 0 0) =
(
    local t = toLower typ
    local h

    if t == "point" then
    (
        h = Point name:name pos:pos size:size cross:true box:true axisTripod:false
        if isProperty h #centermarker do h.centermarker = false
        if isProperty h #display do h.display = false
        if isProperty h #showAxis do h.showAxis = false
        if isProperty h #directionAxis do h.directionAxis = false
        local q = rotAngles as quat
        h.rotation = q
    )
    else
    (
        h = Dummy name:name pos:pos
        h.boxsize = [size, size, size]
        local q = rotAngles as quat
        h.rotation = q
        if isProperty h #objectOffsetRot then
            h.objectOffsetRot = inverse q
    )

    h.wirecolor = HELPER_COLOR

    if parent != undefined then
    (
        local parentName = toLower parent
        local parentNode = undefined
        local allNodes = objects as array
        for n in allNodes where (toLower n.name) == parentName do
        (
            parentNode = n
            exit
        )

        if parentNode != undefined then
        (
            h.parent = parentNode
            in coordsys world h.pos = pos
        )
        else
        (
            format "????????: ???????? \"%\" ?? ?????? ??? \"%\".\n" parent name
        )
    )

    h
)

-- ?????? ????????????:
-- ???????:
-- #(name, pos, parent, size, rot)            -- ??? ?? ????????? "dummy"
-- #(name, pos, type, parent, size, rot)
-- parent ????? ???? ??????? ??? ???????? ?????: #"("A","B")"
fn parseSpec spec =
(
    local name = spec[1]
    local pos  = spec[2]

    local hasType = false
    if spec.count >= 3 and (classOf spec[3] == String) then
    (
        local t = toLower spec[3]
        if (t == "point" or t == "dummy") then hasType = true
    )

    local typ
    if hasType then typ = toLower spec[3] else typ = "dummy"

    local parent
    if hasType then
    (
        if spec.count >= 4 then parent = spec[4] else parent = undefined
    )
    else
    (
        if spec.count >= 3 then parent = spec[3] else parent = undefined
    )

    local size
    if hasType then
    (
        if spec.count >= 5 then size = spec[5] else size = 0.1
    )
    else
    (
        if spec.count >= 4 then size = spec[4] else size = 0.1
    )

    local rot
    if hasType then
    (
        if spec.count >= 6 then rot = spec[6] else rot = (eulerAngles -90 0 0)
    )
    else
    (
        if spec.count >= 5 then rot = spec[5] else rot = (eulerAngles -90 0 0)
    )

    #(name, pos, typ, parent, size, rot)
)

fn buildHelpers helperList =
(
    local created = #()
    for s in helperList do
    (
        local p = parseSpec s
        local name = p[1]
        local pos = p[2]
        local typ = p[3]
        local parent = p[4]
        local size = p[5]
        local rot = p[6]

        if (parent != undefined) and (classOf parent == Array) then
        (
            -- ??? ??????? ????? ? ??????? ????????? ??????? ????????? ????????
            for parentName in parent do
            (
                local h = mkHelper name pos typ:typ parent:parentName size:size rotAngles:rot
                append created h
				append CREATED_HELPERS h
            )
        )
        else
        (
            local h = mkHelper name pos typ:typ parent:parent size:size rotAngles:rot
            append created h
			append CREATED_HELPERS h -- ????????? ??????
        )
    )
    created
)

fn joinStrings arr sep =
(
    local s = ""
    for i = 1 to arr.count do
    (
        s += arr[i]
        if i < arr.count do s += sep
    )
    s
)


helperList = #(
	#("root_chassis", [0,0,0], undefined, 0.1, (eulerAngles -90 0 0)),
    #("Chassis_stock", [0,0,0], undefined, 0.1, (eulerAngles -90 0 0)),
	#("Chassis_missile", [0,0,0], undefined, 0.1, (eulerAngles -90 0 0)),
    #("muffler_root", [0.414,1.771,0.042], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		
    #("root_bonnet", [0,-0.746,0.682], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("Bonnet_stock", [0,-0.746,0.682], "root_bonnet", 0.1, (eulerAngles -90 0 0)),
			
    #("root_bumper_front", [0,-2.144,0.155], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("BumperFront_stock", [0,-2.144,0.155], "root_bumper_front", 0.1, (eulerAngles -90 0 0)),
			
    #("root_bumper_rear", [0,2.177,0.266], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("BumperRear_stock", [0,2.177,0.266], "root_bumper_rear" , 0.1, (eulerAngles -90 0 0)),
			
			
    #("root_exhaustpipe", [0,0,0], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("ExhaustPipe_stock", [0,0,0], "root_exhaustpipe", 0.1, (eulerAngles -90 0 0)),
			#("marker_exhaust1", [0,-0.927,0.176], "ExhaustPipe_stock", 0.1, (eulerAngles 0 0 0)),
			#("marker_exhaust2", [0.404,1.710,0.053], "ExhaustPipe_stock", 0.1, (eulerAngles 0 0 0)),
		#("ExhaustPipe_stockV", [0,0,0], "root_exhaustpipe", 0.1, (eulerAngles -90 0 0)),
			#("marker_exhaust1l", [0.342,-0.927,0.176], "Point", "ExhaustPipe_stockV", 0.1, (eulerAngles 0 0 0)),
			#("marker_exhaust1r", [-0.342,-0.927,0.176], "Point", "ExhaustPipe_stockV", 0.1, (eulerAngles 0 0 0)),
			#("marker_exhaust2", [0.404,1.710,0.053], "Point", "ExhaustPipe_stockV", 0.1, (eulerAngles 0 0 0)),
		#("ExhaustPipe_custom", [0,0,0], "root_exhaustpipe", 0.1, (eulerAngles -90 0 0)),
			#("marker_exhaust0", [0,1.643,0.060], "Point", "ExhaustPipe_custom", 0.1, (eulerAngles 0 0 0)),
			#("marker_exhaust1", [0,-0.927,0.176], "Point", "ExhaustPipe_custom", 0.1, (eulerAngles 0 0 0)),
		#("ExhaustPipe_customV", [0,0,0], "root_exhaustpipe", 0.1, (eulerAngles -90 0 0)),
			#("marker_exhaust0", [0.138,1.388,0.053], "Point", "ExhaustPipe_customV", 0.1, (eulerAngles 0 0 0)),
			#("marker_exhaust1l", [0.263,-0.928,0.176], "Point", "ExhaustPipe_customV", 0.1, (eulerAngles 0 0 0)),
			#("marker_exhaust1r", [-0.263,-0.928,0.176], "Point", "ExhaustPipe_customV", 0.1, (eulerAngles 0 0 0)),
			
    #("root_fender_left", [0.819,-1.283,0.564], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("FenderLeft_stock", [0.819,-1.283,0.564], "root_fender_left", 0.1, (eulerAngles -90 0 0)),
			
    #("root_fender_right", [-0.819,-1.283,0.564], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("FenderRight_stock", [-0.819,-1.283,0.564], "root_fender_right", 0.1, (eulerAngles -90 0 0)),
			
    #("root_fender_rear", [0,1.190,0.755], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("FenderRear_stock", [0,1.190,0.755], "root_fender_rear", 0.1, (eulerAngles -90 0 0)),
			
    #("root_headlights_left", [0.574,-2.010,0.439], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("HeadlightsLeft_stock", [0.574,-2.010,0.439], "root_headlights_left", 0.1, (eulerAngles -90 0 0)),
			
    #("root_headlights_right", [-0.574,-2.010,0.439], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("HeadlightsRight_stock", [-0.574,-2.010,0.439], "root_headlights_right", 0.1, (eulerAngles -90 0 0)),
			
    #("root_interior", [0,0,0], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
			
    #("root_skirt_left", [0.851,0,0.062], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("SkirtLeft_stock", [0.851,0,0.062], "root_skirt_left", 0.1, (eulerAngles -90 0 0)),
			
    #("root_skirt_right", [-0.851,0,0.062], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("SkirtRight_stock", [-0.851,0,0.062], "root_skirt_right", 0.1, (eulerAngles -90 0 0)),
			
    #("root_taillights_left", [0.686,2.089,0.613], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("TaillightsLeft_stock", [0.686,2.089,0.613], "root_taillights_left", 0.1, (eulerAngles -90 0 0)),
			
    #("root_taillights_right", [-0.686,2.089,0.613], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("TaillightsRight_stock", [-0.686,2.089,0.613], "root_taillights_right", 0.1, (eulerAngles -90 0 0)),
			
    #("root_trunk", [0,1.473,0.746], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("Trunk_stock", [0,1.473,0.746], "root_trunk", 0.1, (eulerAngles -90 0 0)),
			#("root_spoiler", [0,2.072,0.793], "Trunk_stock", 0.1, (eulerAngles -90 0 0)),
				#("Spoiler_stock", [0,2.072,0.793], "root_spoiler", 0.1, (eulerAngles -90 0 0)),
			
    #("root_window_front", [0,-0.438,0.911], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("WindowFront_stock", [0,-0.438,0.911], "root_window_front", 0.1, (eulerAngles -90 0 0)),
			
    #("root_window_rear", [0,1.254,0.992], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		#("WindowRear_stock", [0,1.254,0.992], "root_window_rear", 0.1, (eulerAngles -90 0 0)),
			
    #("source_axis_front", [0,-1.275,0.09], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
    #("source_axis_rear", [0,1.237,0.041], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
    #("source_bracing_front_left", [0.389,-1.292,0.165], "Point", #("Chassis_stock","Chassis_missile"), 0.2, (eulerAngles -90 0 0)),
    #("source_bracing_front_right", [-0.389,-1.292,0.165], "Point", #("Chassis_stock","Chassis_missile"), 0.2, (eulerAngles -90 0 0)),
    #("source_cooler", [0,-1.970,0.241], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
    #("source_diff", [0,1.248,0.150], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
    #("source_engine", [0,-1.24,0.237], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
    #("source_exhaust2", [0.414,1.771,0.042], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles 0 0 0)),
    #("source_fl_stubadj", [0.275,-1.637,0.070], "Point", #("Chassis_stock","Chassis_missile"), 0.2, (eulerAngles -90 0 0)),
    #("source_fr_stubadj", [-0.275,-1.637,0.070], "Point", #("Chassis_stock","Chassis_missile"), 0.2, (eulerAngles -90 0 0)),
	#("source_frame_rear_left", [0.526,0.673,0.075], "Point", #("Chassis_stock","Chassis_missile"), 0.2, (eulerAngles -90 -30 0)),
	#("source_frame_rear_right", [-0.526,0.673,0.075], "Point", #("Chassis_stock","Chassis_missile"), 0.2, (eulerAngles -90 30 0)),
	#("source_front_left", [0.276,-1.276,0.117], "Point", "Chassis_stock", 0.2, (eulerAngles -90 0 0)),
	#("source_front_right", [-0.276,-1.276,0.117], "Point", "Chassis_stock", 0.2, (eulerAngles -90 0 0)),
	#("source_hose1_front_left", [0.453,-1.242,0.330], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
	#("source_hose1_front_right", [-0.453,-1.242,0.330], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
		
	#("source_radiator", [0,-1.833,0.505], "Chassis_stock", 0.1, (eulerAngles -90 0 0)),
	#("source_radiator", [0,1.960,0.661], "Chassis_missile", 0.1, (eulerAngles -90 0 0)),
		
	#("source_radiatorpipe1Chassis", [-0.118,-0.880,0.423], "Point", "Chassis_stock", 0.1, (eulerAngles 0 0 0)),
	#("source_radiatorpipe2Chassis", [0,1.434,0.319], "Point", "Chassis_stock", 0.1, (eulerAngles 0 0 0)),
	#("source_skndhose1_rear_left", [0.485,1.409,0.323], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
	#("source_skndhose1_rear_right", [-0.485,1.409,0.323], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
	#("source_topshock_front_left", [0.567,-1.192,0.566], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
	#("source_topshock_front_right", [-0.567,-1.192,0.566], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
	#("source_topshock_rear_left", [0.591,1.256,0.557], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
	#("source_topshock_rear_right", [-0.591,1.256,0.557], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
	#("source_transmission", [0,-0.685,0.199], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles 0 0 0))
		
		
)

rollout helperCreator "Helper Creator" width:260 height:380
(
    groupBox grp_doorCount "Door Count" pos:[20,20] width:220 height:70
    checkbox chk_door1 "2 Doors" pos:[30,40] width:200 height:20 checked:true
    checkbox chk_door2 "4 Doors" pos:[30,60] width:200 height:20 checked:false

    groupBox grp_roof "Roof" pos:[20,100] width:220 height:50
    checkbox chk_roof "Roof" pos:[30,120] width:200 height:20 checked:false
	
	groupBox grp_grill "Grill" pos:[20,160] width:220 height:50
    checkbox chk_grill "Grill" pos:[30,180] width:200 height:20 checked:false

    groupBox grp_taillights "Taillights" pos:[20,220] width:220 height:50
    checkbox chk_taillightscenter "Taillights Center" pos:[30,240] width:200 height:20 checked:false
	
	button btn_create "Create Objects" pos:[20,280] width:220 height:40
	
	button btn_delete "Delete All" pos:[20,330] width:220 height:40

    -- ????????? ???????????? ?????????
    on chk_door1 changed state do
    (
        if state then chk_door2.checked = false
    )
    on chk_door2 changed state do
    (
        if state then chk_door1.checked = false
    )

    on btn_create pressed do
    (
        local listToBuild = helperList

        if chk_door1.checked do
        (
            local doorHelpers = #(
                #("root_door_left", [0.828,-0.663,0.369], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
                #("DoorLeft_stock", [0.828,-0.663,0.369], "root_door_left", 0.1, (eulerAngles -90 0 0)),
                #("root_door_int_left", [0.633,-0.482,0.409], "DoorLeft_stock", 0.1, (eulerAngles -90 0 0)),
                #("root_mirror_left", [0.775,-0.451,0.722], "DoorLeft_stock", 0.1, (eulerAngles -90 0 0)),
                #("MirrorLeft_stock", [0.775,-0.451,0.722], "root_mirror_left", 0.1, (eulerAngles -90 0 0)),

                #("root_door_right", [-0.828,-0.663,0.369], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
                #("DoorRight_stock", [-0.828,-0.663,0.369], "root_door_right", 0.1, (eulerAngles -90 0 0)),
                #("root_door_int_right", [-0.633,-0.482,0.409], "DoorRight_stock", 0.1, (eulerAngles -90 0 0)),
                #("root_mirror_right", [-0.775,-0.451,0.722], "DoorRight_stock", 0.1, (eulerAngles -90 0 0)),
                #("MirrorRight_stock", [-0.775,-0.451,0.722], "root_mirror_right", 0.1, (eulerAngles -90 0 0))
            )
            listToBuild = listToBuild + doorHelpers
        )

        if chk_door2.checked do
        (
            local door2Helpers = #(
                #("root_door_left_front", [0.828,-0.663,0.369], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
                #("DoorLeft_front_stock", [0.828,-0.663,0.369], "root_door_left_front", 0.1, (eulerAngles -90 0 0)),
                #("root_door_int_left", [0.633,-0.482,0.409], "DoorLeft_front_stock", 0.1, (eulerAngles -90 0 0)),
                #("root_mirror_left", [0.775,-0.451,0.722], "DoorLeft_front_stock", 0.1, (eulerAngles -90 0 0)),
                #("MirrorLeft_stock", [0.775,-0.451,0.722], "root_mirror_left", 0.1, (eulerAngles -90 0 0)),

                #("root_door_right_front", [-0.828,-0.663,0.369], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
                #("DoorRight_front_stock", [-0.828,-0.663,0.369], "root_door_right_front", 0.1, (eulerAngles -90 0 0)),
                #("root_door_int_right", [-0.633,-0.482,0.409], "DoorRight_front_stock", 0.1, (eulerAngles -90 0 0)),
                #("root_mirror_right", [-0.775,-0.451,0.722], "DoorRight_front_stock", 0.1, (eulerAngles -90 0 0)),
                #("MirrorRight_stock", [-0.775,-0.451,0.722], "root_mirror_right", 0.1, (eulerAngles -90 0 0)),

                #("root_door_left_rear", [0.828,0.272,0.369], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
                #("Door_left_stock", [0.828,0.272,0.369], "root_door_left_rear", 0.1, (eulerAngles -90 0 0)),

                #("root_door_right_rear", [-0.828,0.272,0.369], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
                #("Door_right_stock", [-0.828,0.272,0.369], "root_door_right_rear", 0.1, (eulerAngles -90 0 0))
            )
            listToBuild = listToBuild + door2Helpers
        )

        if chk_roof.checked do
        (
            local roofHelpers = #(
                #("root_roof", [0,0.814,1.145], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
                #("Roof_stock", [0,0.814,1.145], "root_roof", 0.1, (eulerAngles -90 0 0))
            )
            listToBuild = listToBuild + roofHelpers
        )
		
		if chk_grill.checked do
        (
            local grillHelpers = #(
                #("root_grill", [0,-2.041,0.526], #("Chassis_stock","Chassis_missile"), 0.1, (eulerAngles -90 0 0)),
                #("Grill_stock", [0,-2.041,0.526], "root_grill", 0.1, (eulerAngles -90 0 0))
            )
            listToBuild = listToBuild + grillHelpers
        )

        if chk_taillightscenter.checked do
        (
            local taillightscenterHelpers = #(
                #("root_taillights_center", [0,2.165,0.575], "Trunk_stock", 0.1, (eulerAngles -90 0 0)),
                #("TaillightsCenter_stock", [0,2.165,0.575], "root_taillights_center", 0.1, (eulerAngles -90 0 0))
            )
            listToBuild = listToBuild + taillightscenterHelpers
        )

        local created = buildHelpers listToBuild
        local names = for c in created collect c.name
        format "??????? ????????: %\n" (joinStrings names ", ")
		
		
    
)

on btn_delete pressed do
(
    local deleted = #()
    for h in CREATED_HELPERS where isValidNode h do
    (
        local nm = h.name   -- ????????? ??? ?? ????????
        delete h
        append deleted nm   -- ???????????? ??????????? ???
    )
    CREATED_HELPERS = #() -- ??????? ??????
    format "??????? ????????: %\n" (joinStrings deleted ", ")
)



)




