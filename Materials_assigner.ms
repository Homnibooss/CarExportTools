/* ===========================
   Assign Materials Functions
   =========================== */

global activeLibrary = undefined
global libraryPath   = undefined
global iniFile       = (getDir #plugcfg + "\\AssignMatTool.ini")

fn normalizeName s =
(
    if s == undefined then "" else (toLower (trimRight (trimLeft s)))
)

fn updateLibraryInfo lblCtrl =
(
    if activeLibrary != undefined then
        lblCtrl.text = "Library materials: " + activeLibrary.count as string
    else
        lblCtrl.text = "Library materials: (not loaded)"
)

fn loadLibraryFromPath path lblCtrl =
(
    if path != undefined and doesFileExist path then
    (
        activeLibrary = loadTempMaterialLibrary path
        updateLibraryInfo lblCtrl
    )
)

fn findMaterialByName key =
(
    local k = normalizeName key
    local foundMat = undefined
    if activeLibrary != undefined then
    (
        for m in activeLibrary do
        (
            if normalizeName m.name == k then
            (
                foundMat = m
                exit
            )
        )
    )
    foundMat
)

fn assignMaterialsToChildrenByName rootObj =
(
    local count = 0
    for child in rootObj.children do
    (
        if isKindOf child GeometryClass then
        (
            local mat = findMaterialByName child.name
            if mat != undefined then
            (
                try(child.material = mat)catch()
                count += 1
            )
        )
        else if isKindOf child Dummy then
        (
           
            count += assignMaterialsToChildrenByName child
        )
        else
        (
            count += assignMaterialsToChildrenByName child
        )
    )
    count
)

fn reportResult assignedCount skipped titleText =
(
    local msg = "Materials assigned: " + assignedCount as string + "\n\n"
    if skipped.count > 0 then
    (
        msg += "The following meshes were skipped (no matching material found):\n\n"
        for s in skipped do msg += (s + "\n")
    )
    messageBox msg title:titleText
)

fn assignSelectedMaterials =
(
    if selection.count == 0 then
    (
        messageBox "No objects selected!"
        return()
    )

    if activeLibrary == undefined then
    (
        messageBox "No library loaded!"
        return()
    )

    local skipped = #()
    local assignedCount = 0

    for obj in selection do
    (
        if isKindOf obj GeometryClass then
        (
            local mat = findMaterialByName obj.name
            if mat != undefined then
            (
                try(obj.material = mat)catch()
                assignedCount += 1
            )
            else append skipped obj.name
        )
        else if isKindOf obj Dummy then
        (
            assignedCount += assignMaterialsToChildrenByName obj
        )
        else
        (
            assignedCount += assignMaterialsToChildrenByName obj
        )
    )

    reportResult assignedCount skipped "Assign Selected"
)

fn assignAllVisibleMaterials =
(
    if activeLibrary == undefined then
    (
        messageBox "No library loaded!"
        return()
    )

    local skipped = #()
    local assignedCount = 0

    for obj in geometry where not obj.isHidden do
    (
        local mat = findMaterialByName obj.name
        if mat != undefined then
        (
            try(obj.material = mat)catch()
            assignedCount += 1
        )
        else append skipped obj.name
    )

    reportResult assignedCount skipped "Assign All Visible Meshes"
)

fn assignAllMaterials =
(
    if activeLibrary == undefined then
    (
        messageBox "No library loaded!"
        return()
    )

    local skipped = #()
    local assignedCount = 0

    for obj in geometry do
    (
        local mat = findMaterialByName obj.name
        if mat != undefined then
        (
            try(obj.material = mat)catch()
            assignedCount += 1
        )
        else append skipped obj.name
    )

    reportResult assignedCount skipped "Assign All Meshes"
)

fn initMaterialLibrary lblCtrl =
(
    libraryPath = getINISetting iniFile "Settings" "LibraryPath"
    if libraryPath != undefined do loadLibraryFromPath libraryPath lblCtrl
)
