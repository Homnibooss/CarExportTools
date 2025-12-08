include "$scripts/helperCreator.ms"
include "$scripts/carHierarchyUI.ms"
include "$scripts/Materials_assigner.ms"


global g_exportFolder = ""
global g_mainExportDialogState = #expanded

fn toggleMainExportDialog =
(
    if g_mainExportDialogState == #expanded then
    (
        -- ????????: ????????? ?????? ????
        local dlg = (windows.getChildHWND 0 "Main Scene/Export Tools")[1]
        if dlg != undefined do
        (
            setDialogSize mainExportRollout [300,50] -- ?????????? ??????
            g_mainExportDialogState = #collapsed
        )
    )
    else
    (
        -- ??????????: ?????????? ???????? ??????
        local dlg = (windows.getChildHWND 0 "Main Scene/Export Tools")[1]
        if dlg != undefined do
        (
            setDialogSize mainExportRollout [760,840] -- ???? ???????? ??????
            g_mainExportDialogState = #expanded
        )
    )
)

fn recurseHierarchy node acc =
(
    for c in node.children do
    (
        append acc c
        recurseHierarchy c acc
    )
)

fn getHierarchyNodes rootNode =
(
    local nodesArray = #(rootNode)
    recurseHierarchy rootNode nodesArray
    return nodesArray
)

fn getAttachedNodes dummyNode =
(
    local attached = for obj in objects where (obj.parent == dummyNode) collect obj
    append attached dummyNode
    return attached
)

fn clearExtraUVMaps obj =
(
    if not isValidNode obj then return #()
    if (classof obj == Dummy) then return #()
    if (superClassOf obj != GeometryClass) then return #()

    local addedMods = #()
    local uvwClearAlpha = UVW_Mapping_Clear(); uvwClearAlpha.mapID = -2
    local uvwClearIllum = UVW_Mapping_Clear(); uvwClearIllum.mapID = -1
    local uvwClearColor = UVW_Mapping_Clear(); uvwClearColor.mapID = 0
    local uvwClearUV2   = UVW_Mapping_Clear(); uvwClearUV2.mapID = 2
    local uvwClearUV3   = UVW_Mapping_Clear(); uvwClearUV3.mapID = 3
    local uvwClearUV4   = UVW_Mapping_Clear(); uvwClearUV4.mapID = 4
    local nrmModifier   = Edit_Normals()
    local t2mModifier   = Turn_to_Mesh(); t2mModifier.useInvisibleEdges = off

    try (
        addModifier obj nrmModifier;        append addedMods nrmModifier
        addModifier obj uvwClearIllum before:1; append addedMods uvwClearIllum
        addModifier obj uvwClearUV2   before:1; append addedMods uvwClearUV2
        addModifier obj uvwClearUV3   before:1; append addedMods uvwClearUV3
        addModifier obj uvwClearUV4   before:1; append addedMods uvwClearUV4
        if obj.name != "misc" then (
            addModifier obj uvwClearAlpha before:1; append addedMods uvwClearAlpha
            addModifier obj uvwClearColor before:1; append addedMods uvwClearColor
        )
        addModifier obj t2mModifier;        append addedMods t2mModifier
    ) catch()

    return addedMods
)

fn removeModifiers obj modsArray =
(
    if not isValidNode obj then return false
    for m in modsArray do (try (deleteModifier obj m) catch())
)

fn exportDummyHierarchyToFBX dummyNode exportDir includeChildren:true =
(
    if dummyNode == undefined or not isValidNode dummyNode do return false
    if exportDir == undefined or exportDir == "" do return false

    local exportNodes = if includeChildren then getHierarchyNodes dummyNode else getAttachedNodes dummyNode
    if exportNodes.count == 0 then return false

    select exportNodes
    local safeName = filterString dummyNode.name ":\\/*?\"<>|" splitEmptyTokens:false
    local fileName = exportDir + "\\" + (safeName[1]) + ".fbx"
    exportFile fileName #noPrompt selectedOnly:true using:FBXEXP
    return true
)

fn collectChildren node acc =
(
    for c in node.children do
    (
        append acc c
        collectChildren c acc
    )
)

fn getAllRoots = for o in objects where matchpattern o.name pattern:"root_*" ignorecase:true collect o

fn findRootByBase baseName rootsArray =
(
    for r in rootsArray where (toLower r.name) == ("root_" + baseName) do return r
    undefined
)


fn getDummies__DST onlySelected =
(
    if onlySelected then
        for o in selection where isKindOf o Dummy collect o
    else
        for o in objects   where isKindOf o Dummy collect o
)

fn isDummySafe__DST dummy =
(
    local deps = refs.dependentNodes dummy
    for d in deps where d != dummy do return false
    true
)


/* ===========================
   Rollout: Export Tool & Hierarchy Tool (includes Dummy Size Tool)
   =========================== */
rollout mainExportRollout "Main Scene/Export Tools"
(
	button btnToggle "Minimize / Restore" pos:[3,3] width:120 height:25
	
    -- Export Tool
    groupBox grpExport "Export Tool" pos:[10,35] width:220 height:90
    button btnExportSelected "Export Selected" width:200 height:30 pos:[20,55]
    button btnExportAll      "Export All"      width:200 height:30 pos:[20,90]

    --Hierarchy Tool
    groupBox grpHierarchy     "Hierarchy Tool" pos:[10,130] width:300 height:60
    button btnBuildHierarchy  "Build Hierarchy"   width:140 height:30 pos:[20,150]
    button btnUngroupHierarchy "Ungroup Hierarchy" width:140 height:30 pos:[160,150]

    local sides = #("left","right","front","rear","center") --Add new side to build hierarchy

    -- Folder selection 
    label    lblFolderPath   "Folder Path:" pos:[10,200] width:300 height:16
    edittext edtFolderPath   ""             pos:[10,220] width:300 height:24
    button   btnSelectFolder "Select Folder..." pos:[10,250] width:300 height:25
	 button   btnSceneFolder  "Use Scene Folder" pos:[10,280] width:300 height:25

    --Dummy Size Tool
	groupBox grpLightHelpers "Light Helpers" pos:[10,430] width:220 height:190
	checkbox chk_placeByClick "Place by Click" pos:[20,450] width:200
	button btn_headlight "Create Headlight" pos:[20,470] width:200 height:22
	button btn_brake "Create Brake" pos:[20,500] width:200 height:22
	button btn_turnLeft  "Create Turn Left"  pos:[20,530] width:95 height:22
	button btn_turnRight "Create Turn Right" pos:[125,530] width:95 height:22

	button btn_reverse "Create Reverse" pos:[20,560] width:200 height:22
	button btn_taillight "Create Taillight" pos:[20,590] width:200 height:22
    groupBox grpDummy "Dummy Size Tool" pos:[10,310] width:300 height:110
    label    lbl_info "Rebuild Dummies" pos:[20,330] width:280 height:16
    spinner  spn_size "New Dummy Size:" type:#float range:[0.001,100000,0.1] fieldwidth:80 pos:[20,340] width:260
    checkbox chk_selected "Only Selected" checked:false pos:[20,355] width:260
    button   btn_apply "Apply" pos:[20,380] width:260 height:25
	
	    -- Scene Hierarchy Viewer
    groupBox grpHierarchyView "Scene Hierarchy" pos:[340,10] width:400 height:815
    button btnUpdateHierarchy "Update" pos:[350,30] width:100 height:25
    button btnExpandHierarchy "Expand All" pos:[460,30] width:100 height:25
    button btnCollapseHierarchy "Collapse All" pos:[570,30] width:100 height:25
    dotNetControl tvHierarchy "System.Windows.Forms.TreeView" pos:[350,70] width:380 height:745
	
	
	    -- Material Assignment Tool
    groupBox grpAssignMat "Material Assigner" pos:[10,630] width:290 height:195
    label    lblMatInfo "Library materials: (not loaded)" pos:[20,650] width:260
    button   btnLoadLibrary      "Load Material Library"     pos:[20,670] width:260 height:25
    button   btnAssignSelected   "Assign Selected"           pos:[20,700] width:260 height:25
    button   btnAssignAllVisible "Assign All Visible Meshes" pos:[20,730] width:260 height:25
    button   btnAssignAll        "Assign All Meshes"         pos:[20,760] width:260 height:25
	button btnRemoveSelected "Remove Selected Materials" 	 pos:[20,790] width:260 height:25

     on btnLoadLibrary pressed do
    (
        local file = getOpenFileName caption:"Select Material Library" types:"Material Library (*.mat)|*.mat"
        if file != undefined do
        (
            libraryPath = file
            setINISetting iniFile "Settings" "LibraryPath" libraryPath   -- ????????? ????
            loadLibraryFromPath libraryPath lblMatInfo
        )
    )

    on btnAssignSelected pressed    do assignSelectedMaterials()
    on btnAssignAllVisible pressed  do assignAllVisibleMaterials()
    on btnAssignAll pressed         do assignAllMaterials()
	on btnRemoveSelected pressed do removeSelectedMaterials()

    on btnToggle pressed do toggleMainExportDialog()

	
	
	fn hexToColor hexStr =
(
local r = execute ("0x" + substring hexStr 1 2)
local g = execute ("0x" + substring hexStr 3 2)
local b = execute ("0x" + substring hexStr 5 2)
color r g b
)

fn makeHelper name colorHex pos rotAngles =
(
    local h = point name:name size:0.05 centermarker:on axisTripod:off cross:on box:on
    h.wirecolor = hexToColor colorHex

    -- ???????? ????????? ?????????
    local m = matrix3 1
    m.row4 = pos
    preRotate m (eulerAngles rotAngles.x rotAngles.y rotAngles.z)
    h.transform = m

    -- ???? ???????? ????????, ?????? ?? ?????????
    if selection.count == 1 and isKindOf selection[1] Dummy do
    (
        h.parent = selection[1]
    )

    h
)

fn placeHelper name colorHex rotAngles =
(
    if chk_placeByClick.checked then
    (
        local p = pickPoint snap:#3D
        if (p != undefined and p != #rightClick) then
        (
            makeHelper name colorHex p rotAngles
        )
    )
    else
    (
        makeHelper name colorHex [0,0,0] rotAngles
    )
)




-- Headlight: ??? Z ?????? (90,0,0)
on btn_headlight pressed do placeHelper "headlight" "E1C657" [90,0,0]

-- Brake: ??? Z ????? (90,0,180)
on btn_brake pressed do placeHelper "brake" "B01A1A" [90,0,180]

-- Reverse: ??? Z ????? (90,0,180)
on btn_reverse pressed do placeHelper "reverse" "A3A3A3" [90,0,180]

-- Taillight: ??? Z ????? (90,0,180)
on btn_taillight pressed do placeHelper "taillight" "B11C95" [90,0,180]

-- Turn Left: ??? Z ????? (90,0,270)
on btn_turnLeft pressed do placeHelper "turn_left" "B1581B" [90,0,90]

-- Turn Right: ??? Z ?????? (90,0,90)
on btn_turnRight pressed do placeHelper "turn_right" "B1581B" [90,0,270]

	

    /* Rollout open */
    on mainExportRollout open do
    (
        if g_exportFolder != "" then edtFolderPath.text = g_exportFolder
			g_tvHierarchy = tvHierarchy
			setupTreeView tvHierarchy
        rebuildTree tvHierarchy
		 initMaterialLibrary lblMatInfo
    )
	
	on mainExportRollout close do 
		(
    g_tvHierarchy = undefined
)
	
	on btnUpdateHierarchy pressed do rebuildTree tvHierarchy
    on btnExpandHierarchy pressed do expandAllTree tvHierarchy
    on btnCollapseHierarchy pressed do collapseAllTree tvHierarchy
		
	
	on tvHierarchy NodeMouseClick sender args do (
        handleNodeClick sender args 
    )

    /* Folder selection */
    on btnSelectFolder pressed do
    (
        local selectedDir = getSavePath caption:"Select export folder"
        if selectedDir != undefined then
        (
            g_exportFolder = selectedDir
            edtFolderPath.text = g_exportFolder
        )
    )
	
	on btnSceneFolder pressed do
    (
        if maxFilePath != undefined and maxFilePath != "" then
        (
            local compPath = maxFilePath + "Components"
            
            -- ???? ????? ?? ??????????, ???????
            if not doesFileExist compPath do
            (
                makeDir compPath
            )
            
            g_exportFolder = compPath
            edtFolderPath.text = g_exportFolder
        )
        else
        (
            messageBox "Please, save scene."
        )
    )
	
    on edtFolderPath changed txt do g_exportFolder = txt

    /* Export Selected */
    fn exportSelectedDummies =
    (
        if g_exportFolder == "" then
        (
            messageBox "Please select an export folder." title:"Folder not selected"
            return false
        )

        local selectedObjects = selection as array
        if selectedObjects.count == 0 then
        (
            messageBox "Select at least one Dummy object." title:"Nothing selected"
            return false
        )

        for obj in selectedObjects do
        (
            if isValidNode obj and (classof obj == Dummy) then
            (
                local attached    = for c in objects where (c.parent == obj) collect c
                local modTracker  = #()
                for a in attached do append modTracker #(a, clearExtraUVMaps a)

                local originalParent = undefined
                if obj.parent != undefined then
                (
                    originalParent = obj.parent
                    obj.parent     = undefined
                )

                exportDummyHierarchyToFBX obj g_exportFolder includeChildren:false

                if originalParent != undefined and isValidNode originalParent then obj.parent = originalParent
                for t in modTracker do removeModifiers t[1] t[2]
            )
        )
    )

    /* Export All */
    fn exportAllDummies =
    (
        if g_exportFolder == "" then
        (
            messageBox "Please select an export folder." title:"Folder not selected"
            return false
        )

        local allDummies = for obj in objects where (classof obj == Dummy) collect obj
        if allDummies.count == 0 then
        (
            messageBox "No Dummy objects found in the scene." title:"Nothing to export"
            return false
        )

        for dummy in allDummies do
        (
            if matchPattern (toLower dummy.name) pattern:"root*" then continue

            local attached = for obj in objects where (obj.parent == dummy) collect obj
            if attached.count == 0 then continue

            local modTracker = #()
            for a in attached do append modTracker #(a, clearExtraUVMaps a)

            local originalParent = undefined
            if dummy.parent != undefined then
            (
                originalParent = dummy.parent
                dummy.parent   = undefined
            )

            exportDummyHierarchyToFBX dummy g_exportFolder includeChildren:false

            if originalParent != undefined and isValidNode originalParent then dummy.parent = originalParent
            for t in modTracker do removeModifiers t[1] t[2]
        )
    )

    on btnExportSelected pressed do exportSelectedDummies()
    on btnExportAll      pressed do exportAllDummies()

    /* Build Hierarchy */
    on btnBuildHierarchy pressed do
    (
        local roots = getAllRoots()
        if roots.count == 0 then return()

        local ignoreArray   = #()
        local chassisMissile = undefined
        for obj in objects where obj.name == "Chassis_missile" do chassisMissile = obj

        if chassisMissile != undefined then
        (
            append ignoreArray chassisMissile
            collectChildren chassisMissile ignoreArray
        )

        for obj in objects do
        (
            if findItem ignoreArray obj != 0 then continue

            local objName = toLower obj.name
            if matchpattern objName pattern:"root_*"   ignorecase:true then continue
            if matchpattern objName pattern:"source*"  ignorecase:true then continue

            local matchedRoot = undefined

            for r in roots while matchedRoot == undefined do
            (
                local baseName = substituteString (toLower r.name) "root_" ""
                if findString objName baseName != undefined then matchedRoot = r
            )

            if matchedRoot == undefined then
            (
                for s in sides while matchedRoot == undefined do
                (
                    local pos = findString objName s
                    if pos != undefined then
                    (
                        local basePart = substring objName 1 (pos-1)
                        basePart = trimRight basePart "_"
                        basePart = trimRight basePart " "
                        if basePart != "" then
                        (
                            local combinedName = basePart + "_" + s
                            matchedRoot = findRootByBase combinedName roots
                        )
                    )
                )
            )

            if matchedRoot != undefined then
            (
                local safeToParent = true
                local p = matchedRoot.parent
                while p != undefined do
                (
                    if p == obj then (safeToParent = false; exit)
                    p = p.parent
                )
                if safeToParent and obj.parent != matchedRoot then obj.parent = matchedRoot
            )
        )

        if chassisMissile != undefined then
        (
            local rootChassis = undefined
            for r in roots where toLower r.name == "root_chassis" do rootChassis = r
            if rootChassis != undefined then chassisMissile.parent = rootChassis
        )
    )

    /* Ungroup Hierarchy */
    on btnUngroupHierarchy pressed do
    (
        local roots = getAllRoots()
        if roots.count == 0 then return()

        for r in roots do
        (
            local children = for o in objects where o.parent == r collect o
            for c in children do
            (
                if matchpattern (toLower c.name) pattern:"source*" ignorecase:true then continue
                if not matchpattern c.name pattern:"root_*" ignorecase:true then
                (
                    c.parent = undefined
                )
            )
        )
    )

    /* Dummy Size Tool: Apply */
    on btn_apply pressed do
    (
        local newSize     = spn_size.value
        local dummies     = getDummies__DST chk_selected.checked
        local rebuiltCount = 0

        if dummies.count == 0 then
        (
            messageBox "No Dummy objects found."
            return()
        )

        undo "Rebuild Dummies" on
        (
            for d in dummies do
            (
                if not isDummySafe__DST d then
                (
                    format "Skipping dummy used in modifier: %\n" d.name
                    continue
                )

                try
                (
                    local oldName     = d.name
                    local tempName    = uniqueName "temp_dummy"
                    d.name            = tempName

                    local oldTransform = d.transform
                    local oldParent    = d.parent
                    local oldChildren  = d.children

                    local newD = Dummy()
                    newD.boxsize = [newSize, newSize, newSize]

                    newD.transform = oldTransform
                    newD.name      = oldName

                    if oldParent != undefined do newD.parent = oldParent
                    for ch in oldChildren do ch.parent = newD

                    delete d
                    rebuiltCount += 1
                )
                catch
                (
                    format "Error rebuilding dummy: %\n" d
                )
            )
        )

        messageBox ("Done. Rebuilt Dummy: " + rebuiltCount as string)
    )
)


/* ===========================
   Rollout: Utilities
   =========================== */
rollout utilitiesRollout "CarParts Tool"
(
    button btnOpenExport         "Main Tools"    width:150 height:30 pos:[10,10]
    button btnOpenVertexChecker  "VertexColor Checker"        width:150 height:30 pos:[10,50]
    button btnOpenNgonsFinder    "N-gons Cheker"                 width:150 height:30 pos:[10,90]
	button btnOpenHelperCreator "Helper Creator" width:150 height:30 pos:[10,130]

    on btnOpenHelperCreator pressed do
    (
       try(destroyDialog helperCreator) catch()
    createDialog helperCreator width:260 height:380 style:#(#style_toolwindow, #style_sysmenu)
    )


    on btnOpenExport pressed do
    (
        try(destroyDialog mainExportRollout) catch()
        createDialog mainExportRollout width:760 height:840 style:#(#style_toolwindow, #style_sysmenu)
    )

    on btnOpenVertexChecker pressed do
    (
        try(destroyDialog VertexColorCheckerRollout) catch()

        -- VertexColorChecker Script
        rollout VertexColorCheckerRollout "Vertex Color / Alpha / Illum Checker" width:420 height:400
        (
            dotNetControl lv_objects "System.Windows.Forms.ListView" pos:[10,10] width:400 height:220
            button btn_find         "Find All"   width:140 align:#center
			button btn_findVisible  "Find Isolated"    width:140 align:#center
            button btn_select       "Select All From List"     width:140 align:#center
            button btn_fix_selected "Fix Selected"      width:140 align:#center
            button btn_fix_all      "Fix All"           width:140 align:#center
            label  lbl_status       "Ready."            align:#left offset:[0,5]

            local badObjs   = #()
            local badReasons = #()

            on VertexColorCheckerRollout open do
            (
                lv_objects.View          = (dotNetClass "System.Windows.Forms.View").Details
                lv_objects.FullRowSelect = true
                lv_objects.GridLines     = true
                lv_objects.MultiSelect   = false
                lv_objects.Columns.Add "Object Name" 240
                lv_objects.Columns.Add "Issues"      100

                try (
                    local rW = VertexColorCheckerRollout.width
                    local rH = VertexColorCheckerRollout.height
                    lv_objects.width  = rW - 20
                    lv_objects.height = rH - 200
                    btn_find.pos         = [((rW/2) - btn_find.width/2),         rH - 165]
					btn_findVisible.pos  = [((rW/2) - btn_findVisible.width/2),  rH - 140]
                    btn_select.pos       = [((rW/2) - btn_select.width/2),       rH - 115]
                    btn_fix_selected.pos = [((rW/2) - btn_fix_selected.width/2), rH - 90]
                    btn_fix_all.pos      = [((rW/2) - btn_fix_all.width/2),      rH - 65]
                    lbl_status.pos       = [10, rH - 25]
                ) catch()
            )

            fn addToListView obj reason =
            (
                local item = dotNetObject "System.Windows.Forms.ListViewItem" obj.name
                item.SubItems.Add reason
                lv_objects.Items.Add item
            )
			
			

            fn hasBadVertexColor obj =
            (
                if isKindOf obj GeometryClass then
                (
                    local meshObj = snapshotAsMesh obj
                    if meshop.getMapSupport meshObj 0 then
                    (
                        local numVCVerts = meshop.getNumMapVerts meshObj 0
                        if numVCVerts > 0 then
                        (
                            for i = 1 to numVCVerts do
                            (
                                local c = meshop.getMapVert meshObj 0 i
                                if (c.x != 1.0 or c.y != 1.0 or c.z != 1.0) then
                                (
                                    delete meshObj
                                    return true
                                )
                            )
                        )
                    )
                    delete meshObj
                )
                return false
            )

            fn hasBadVertexAlpha obj =
            (
                if isKindOf obj GeometryClass then
                (
                    local meshObj  = snapshotAsMesh obj
                    local channelID = -2
                    if meshop.getMapSupport meshObj channelID then
                    (
                        local numVerts = meshop.getNumMapVerts meshObj channelID
                        if numVerts > 0 then
                        (
                            for i = 1 to numVerts do
                            (
                                local v = meshop.getMapVert meshObj channelID i
                                if v.x != 100.0 then
                                (
                                    delete meshObj
                                    return true
                                )
                            )
                        )
                    )
                    delete meshObj
                )
                return false
            )

            fn hasBadIllumination obj =
            (
                if isKindOf obj GeometryClass then
                (
                    local meshObj = snapshotAsMesh obj
                    local illumChannel = -1
                    if meshop.getMapSupport meshObj illumChannel then
                    (
                        local numVerts = meshop.getNumMapVerts meshObj illumChannel
                        if numVerts > 0 then
                        (
                            for i = 1 to numVerts do
                            (
                                local c = meshop.getMapVert meshObj illumChannel i
                                if (c.x != 1.0 or c.y != 1.0 or c.z != 1.0) then
                                (
                                    delete meshObj
                                    return true
                                )
                            )
                        )
                    )
                    delete meshObj
                )
                return false
            )
			
			fn findVisibleBadMeshes =
    (
        lv_objects.Items.Clear()
        badObjs    = #()
        badReasons = #()
        lbl_status.text = "Checking visible meshes..."
        redrawViews()

        for o in geometry where (not o.isHidden and not o.isFrozen) do
        (
            local badColor = hasBadVertexColor o
            local badAlpha = hasBadVertexAlpha o
            local badIllum = hasBadIllumination o
            if (badColor or badAlpha or badIllum) do
            (
                append badObjs o
                local reason = ""
                if badColor and badAlpha and badIllum then reason = "C+A+I"
                else if badColor and badAlpha then reason = "C+A"
                else if badColor and badIllum then reason = "C+I"
                else if badAlpha and badIllum then reason = "A+I"
                else if badColor then reason = "Color"
                else if badAlpha then reason = "Alpha"
                else if badIllum then reason = "Illum"
                append badReasons reason
                addToListView o reason
            )
        )

        if badObjs.count > 0 then lbl_status.text = ("Found: " + badObjs.count as string + " bad mesh(es).")
        else lbl_status.text = "All visible meshes are OK."
    )

            fn fixVertexColorAlphaIllum obj =
            (
                if not isKindOf obj Editable_Poly do convertToPoly obj
                local chAlpha = -2
                local chIllum = -1

                if isKindOf obj Editable_Poly then
                (
                    if not (polyOp.getMapSupport obj 0)       do polyOp.setMapSupport obj 0 true
                    if polyOp.getNumMapVerts obj 0 == 0       do polyOp.setNumMapVerts obj 0 obj.numverts
                    for i = 1 to polyOp.getNumMapVerts obj 0  do polyOp.setMapVert obj 0 i [1,1,1]

                    if not (polyOp.getMapSupport obj chAlpha) do polyOp.setMapSupport obj chAlpha true
                    if polyOp.getNumMapVerts obj chAlpha == 0 do polyOp.setNumMapVerts obj chAlpha obj.numverts
                    for i = 1 to polyOp.getNumMapVerts obj chAlpha do polyOp.setMapVert obj chAlpha i [100,0,0]

                    if not (polyOp.getMapSupport obj chIllum) do polyOp.setMapSupport obj chIllum true
                    if polyOp.getNumMapVerts obj chIllum == 0 do polyOp.setNumMapVerts obj chIllum obj.numverts
                    for i = 1 to polyOp.getNumMapVerts obj chIllum do polyOp.setMapVert obj chIllum i [1,1,1]
                )
                else if isKindOf obj Editable_Mesh then
                (
                    if not (meshop.getMapSupport obj 0)       do meshop.setMapSupport obj 0 true
                    if meshop.getNumMapVerts obj 0 == 0       do meshop.setNumMapVerts obj 0 obj.numverts
                    for i = 1 to meshop.getNumMapVerts obj 0  do meshop.setMapVert obj 0 i [1,1,1]

                    if not (meshop.getMapSupport obj chAlpha) do meshop.setMapSupport obj chAlpha true
                    if meshop.getNumMapVerts obj chAlpha == 0 do meshop.setNumMapVerts obj chAlpha obj.numverts
                    for i = 1 to meshop.getNumMapVerts obj chAlpha do meshop.setMapVert obj chAlpha i [100,0,0]

                    if not (meshop.getMapSupport obj chIllum) do meshop.setMapSupport obj chIllum true
                    if meshop.getNumMapVerts obj chIllum == 0 do meshop.setNumMapVerts obj chIllum obj.numverts
                    for i = 1 to meshop.getNumMapVerts obj chIllum do meshop.setMapVert obj chIllum i [1,1,1]
                )
                update obj
            )

            on btn_find pressed do
            (
                lv_objects.Items.Clear()
                badObjs    = #()
                badReasons = #()
                lbl_status.text = "Checking scene..."
                redrawViews()

                for o in geometry do
                (
                    local badColor = hasBadVertexColor o
                    local badAlpha = hasBadVertexAlpha o
                    local badIllum = hasBadIllumination o
                    if (badColor or badAlpha or badIllum) do
                    (
                        append badObjs o
                        local reason = ""
                        if badColor and badAlpha and badIllum then reason = "C+A+I"
                        else if badColor and badAlpha then reason = "C+A"
                        else if badColor and badIllum then reason = "C+I"
                        else if badAlpha and badIllum then reason = "A+I"
                        else if badColor then reason = "Color"
                        else if badAlpha then reason = "Alpha"
                        else if badIllum then reason = "Illum"
                        append badReasons reason
                        addToListView o reason
                    )
                )

                if badObjs.count > 0 then lbl_status.text = ("Found " + badObjs.count as string + " bad mesh(es).")
                else lbl_status.text = "All meshes are OK."
            )
			
			 on btn_findVisible pressed do findVisibleBadMeshes()

            on btn_select pressed do
            (
                if badObjs.count > 0 then
                (
                    select badObjs
                    lbl_status.text = "Objects selected."
                )
                else lbl_status.text = "List is empty."
            )

            on btn_fix_all pressed do
            (
                if badObjs.count > 0 then
                (
                    for o in badObjs where isValidNode o do fixVertexColorAlphaIllum o
                    lbl_status.text = "All listed meshes fixed."
                    badObjs = #(); badReasons = #()
                    lv_objects.Items.Clear()
                )
                else lbl_status.text = "Nothing to fix."
            )

            on btn_fix_selected pressed do
            (
                local fixed = 0
                if selection.count > 0 then
                (
                    for o in selection do
                    (
                        local idx = findItem badObjs o
                        if idx > 0 do
                        (
                            fixVertexColorAlphaIllum o
                            fixed += 1
                            deleteItem badObjs idx
                            deleteItem badReasons idx
                        )
                    )
                    lv_objects.Items.Clear()
                    for i = 1 to badObjs.count do addToListView badObjs[i] badReasons[i]
                    lbl_status.text = ("Fixed " + fixed as string + " selected mesh(es).")
                )
                else lbl_status.text = "No selected objects."
            )

            on lv_objects doubleClick sender args do
            (
                if lv_objects.SelectedItems.Count > 0 then
                (
                    local selName = lv_objects.SelectedItems.Item[0].Text
                    local obj = getNodeByName selName
                    if isValidNode obj then
                    (
                        select obj
                        lbl_status.text = "Selected: " + obj.name
                    )
                )
            )

            on VertexColorCheckerRollout resized size do
            (
               local rW = VertexColorCheckerRollout.width
                    local rH = VertexColorCheckerRollout.height
                    lv_objects.width  = rW - 20
                    lv_objects.height = rH - 200
                    btn_find.pos         = [((rW/2) - btn_find.width/2),         rH - 165]
					btn_findVisible.pos  = [((rW/2) - btn_findVisible.width/2),  rH - 140]
                    btn_select.pos       = [((rW/2) - btn_select.width/2),       rH - 115]
                    btn_fix_selected.pos = [((rW/2) - btn_fix_selected.width/2), rH - 90]
                    btn_fix_all.pos      = [((rW/2) - btn_fix_all.width/2),      rH - 65]
                    lbl_status.pos       = [10, rH - 25]
            )
        )
        createDialog VertexColorCheckerRollout pos:[200,200] style:#(#style_titlebar, #style_sysmenu, #style_resizing)
    )

    on btnOpenNgonsFinder pressed do
    (
        try(destroyDialog findNgonsRollout) catch()

        -- Find Ngons Script
        rollout findNgonsRollout "Find Ngons" width:360 height:440
        (
            button btn_find      "Find All"   width:150 height:30
			button btn_findVisible "Find Isolated" width:150 height:30
            button btn_selectAll "Select Listed"  width:150 height:30
            dotNetControl lv_results "System.Windows.Forms.ListView" pos:[10,10] width:340 height:340
            label lbl_count "Found: 0" pos:[10,400] width:340 height:20 align:#center

            local objMap  = #()
            local ngonsMap = #()

            fn findNgons obj =
(
    if classof obj != Editable_Poly then return #()
    local faceCount = polyop.getNumFaces obj
    local ngons = #()
    for f = 1 to faceCount do
    (
        local verts = polyop.getFaceVerts obj f
        if verts != undefined and verts.count > 4 do append ngons f
    )
    return ngons
)


           on findNgonsRollout open do
(
    lv_results.View          = (dotNetClass "System.Windows.Forms.View").Details
    lv_results.FullRowSelect = true
    lv_results.GridLines     = true
    lv_results.MultiSelect   = false
    lv_results.Columns.Clear()
    lv_results.Columns.Add "Object Name" 230
    lv_results.Columns.Add "Ngons Count" 90

    try (
        local rW = findNgonsRollout.width
        local rH = findNgonsRollout.height
        lv_results.width  = rW - 20
        lv_results.height = rH - 200

        btn_find.pos        = [(rW/2 - btn_find.width/2),        rH - 175]
        btn_findVisible.pos = [(rW/2 - btn_findVisible.width/2), rH - 135]
        btn_selectAll.pos   = [(rW/2 - btn_selectAll.width/2),   rH - 95]
        lbl_count.pos       = [10, rH - 25]
    ) catch()
)
			
			 fn findVisibleNgons =
(
    lv_results.Items.Clear()
    objMap   = #()
    ngonsMap = #()

    local totalFound = 0

    for o in geometry where (not o.isHidden and not o.isFrozen) do
    (
        local ngs = #()
        if classof o == Editable_Poly then
        (
            local faceCount = polyop.getNumFaces o
            for f = 1 to faceCount do
            (
                local verts = polyop.getFaceVerts o f
                if verts != undefined and verts.count > 4 do append ngs f
            )
        )

        if ngs.count > 0 then
        (
            local item = dotNetObject "System.Windows.Forms.ListViewItem" o.name
            item.SubItems.Add (ngs.count as string)
            lv_results.Items.Add item

            append objMap o
            append ngonsMap ngs
            totalFound += 1
        )
    )

    lbl_count.text = "Found: " + totalFound as string
)


            on btn_find pressed do
(
    lv_results.Items.Clear()
    objMap   = #()
    ngonsMap = #()

    local totalFound = 0

    for o in geometry do
    (
        if classof o == Editable_Poly then
        (
            local ngons = #()
            local faceCount = polyop.getNumFaces o
            for f = 1 to faceCount do
            (
                local verts = polyop.getFaceVerts o f
                if verts != undefined and verts.count > 4 do append ngons f
            )

            if ngons.count > 0 then
            (
                local item = dotNetObject "System.Windows.Forms.ListViewItem" o.name
                item.SubItems.Add (ngons.count as string)
                lv_results.Items.Add item

                append objMap o
                append ngonsMap ngons
                totalFound += 1
            )
        )
    )

    lbl_count.text = "Found: " + totalFound as string
)


            on lv_results doubleClick sender args do
            (
                local selItems = lv_results.SelectedItems
                if selItems.Count > 0 then
                (
                    local idx = selItems.Item[0].Index + 1
                    if idx <= objMap.count then
                    (
                        local obj   = objMap[idx]
                        local ngons = ngonsMap[idx]
                        if obj != undefined and ngons.count > 0 do
                        (
                            select obj
                            max zoomext sel all
                            subObjectLevel = 4
                            max modify mode
                            local selFaces = #{}
                            for f in ngons do selFaces[f] = true
                            polyop.setFaceSelection obj selFaces
                        )
                    )
                )
            )
			on btn_findVisible pressed do findVisibleNgons()

            on btn_selectAll pressed do
            (
                if objMap.count > 0 then
                (
                    select objMap
                    max zoomext sel all
                )
            )

            on findNgonsRollout resized size do
            (
               lv_results.width  = size.x - 20
    lv_results.height = size.y - 200

    btn_find.pos        = [(size.x/2 - btn_find.width/2),        size.y - 175]
    btn_findVisible.pos = [(size.x/2 - btn_findVisible.width/2), size.y - 135]
    btn_selectAll.pos   = [(size.x/2 - btn_selectAll.width/2),   size.y - 95]
    lbl_count.pos       = [10, size.y - 25] 
            )
        )
        createDialog findNgonsRollout style:#(#style_titlebar, #style_sysmenu, #style_resizing)
    )
)

try(deleteRollout utilitiesRollout) catch()
addRollout utilitiesRollout to:utilities