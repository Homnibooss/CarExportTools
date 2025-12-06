/* ===========================
   Car Hierarchy Viewer (module)
   =========================== */

global selectedNodes = #()
global lastSelectedNode = undefined
global currentColor = (dotNetClass "System.Drawing.Color").LightBlue
global tableBackColor = (dotNetClass "System.Drawing.Color").White
global g_tvHierarchy -- ?????? ?? TreeView ?? ????????? rollout

-- ????? TreeNode ?? ???????
global FN_searchNodeByObject

fn FN_searchNodeByObject nodes targetObj =
(
    for i = 0 to nodes.Count - 1 do
    (
        local nd = nodes.Item[i]
        if nd.Tag != undefined and nd.Tag.value == targetObj then return nd
        local child = FN_searchNodeByObject nd.Nodes targetObj
        if child != undefined then return child
    )
    undefined
)

fn findNodeByObject tvCtrl obj = FN_searchNodeByObject tvCtrl.Nodes obj

-- ?????????
fn resetColorsTreeNodeCollection nodes =
(
    for j = 0 to (nodes.Count - 1) do
    (
        local c = nodes.Item[j]
        c.BackColor = tableBackColor
        c.ForeColor = (dotNetClass "System.Drawing.Color").Black
        resetColorsTreeNodeCollection c.Nodes
    )
)

fn resetAllColors tvCtrl =
(
    if tvCtrl == undefined then return()
    for i = 0 to (tvCtrl.Nodes.Count - 1) do
    (
        local n = tvCtrl.Nodes.Item[i]
        n.BackColor = tableBackColor
        n.ForeColor = (dotNetClass "System.Drawing.Color").Black
        resetColorsTreeNodeCollection n.Nodes
    )
)

fn paintSelectedNodes nodesArray =
(
    for k in nodesArray where k != undefined do
    (
        k.BackColor = currentColor
        k.ForeColor = (dotNetClass "System.Drawing.Color").Black
    )
)

fn isValidDummy d =
(
    if not isKindOf d Dummy then return false
    if matchPattern d.name pattern:"source*" then return false
    if matchPattern d.name pattern:"root_*" then return true
    if (matchPattern d.name pattern:"interior_stock" or matchPattern d.name pattern:"interior_missile") then return true
    if matchPattern d.name pattern:"DoorInt*" then return true
    local firstChar = substring d.name 1 1
    firstChar == toUpper firstChar
)

fn collectChildrenSkipMeshes obj arr =
(
    local children = for c in obj.children where isValidDummy c collect c
    for child in children do
    (
        append arr child
        collectChildrenSkipMeshes child arr
    )
)

fn getNodeIndex nodes target =
(
    for i = 0 to nodes.Count - 1 do if nodes.Item[i] == target then return i
    -1
)

fn setupTreeView tv =
(
    if tv == undefined then return()
    tv.ShowLines = true
    tv.ShowRootLines = true
    tv.ShowPlusMinus = true
    tv.HideSelection = true
    tv.PathSeparator = "/"
    tv.Font = dotNetObject "System.Drawing.Font" "Consolas" 9
    tv.BackColor = tableBackColor
    tv.LabelEdit = true
)

fn isSpecialDummy d = isValidDummy d and (matchPattern d.name pattern:"interior_stock" or matchPattern d.name pattern:"interior_missile")

fn addChildrenRecursive parentNode obj =
(
    local children = for c in obj.children where isValidDummy c collect c
    for child in children do
    (
        if isSpecialDummy child then continue
        local childNode = parentNode.Nodes.Add child.name
        childNode.Tag = dotNetMXSValue child
        addChildrenRecursive childNode child
    )
)

fn rebuildTree tv =
(
    if tv == undefined then return()
    tv.BeginUpdate()
    tv.Nodes.Clear()
    selectedNodes = #()
    lastSelectedNode = undefined

    local roots = for obj in objects where (isValidDummy obj and matchPattern obj.name pattern:"root_*" and (obj.parent == undefined or not isKindOf obj.parent Dummy)) collect obj
    for r in roots do
    (
        local rootNode = tv.Nodes.Add r.name
        rootNode.Tag = dotNetMXSValue r
        addChildrenRecursive rootNode r
    )

    local specials = for obj in objects where (isValidDummy obj and (matchPattern obj.name pattern:"interior_stock" or matchPattern obj.name pattern:"interior_missile")) collect obj
    for s in specials do
    (
        local sNode = tv.Nodes.Add s.name
        sNode.Tag = dotNetMXSValue s
        addChildrenRecursive sNode s
    )

    local doorInts = for obj in objects where (isValidDummy obj and matchPattern obj.name pattern:"DoorInt*") collect obj
    for d in doorInts do
    (
        local dNode = tv.Nodes.Add d.name
        dNode.Tag = dotNetMXSValue d
        addChildrenRecursive dNode d
    )

    tv.EndUpdate()
    tv.ExpandAll()
)

fn expandAllTree tv = if tv != undefined do tv.ExpandAll()
fn collapseAllTree tv = if tv != undefined do tv.CollapseAll()

-- ????????? ?????
fn handleNodeClick sender args =
(
    if sender == undefined then return()
    local node = args.Node
    if node == undefined then return()
    local mxsObj = if node.Tag != undefined then node.Tag.value else undefined
    if mxsObj == undefined then return()

    local objsToSelect = #()
    local nodesToPaint = #()

    if matchPattern mxsObj.name pattern:"root_*" then
    (
        collectChildrenSkipMeshes mxsObj objsToSelect
        for i = 0 to node.Nodes.Count - 1 do append nodesToPaint node.Nodes.Item[i]
    )
    else
    (
        append objsToSelect mxsObj
        append nodesToPaint node
    )

    local ctrlDown = keyboard.controlPressed
    local shiftDown = keyboard.shiftPressed

    if shiftDown and lastSelectedNode != undefined then
    (
        local parent = node.Parent
        if parent == undefined then parent = sender.Nodes
        local startIndex = getNodeIndex parent.Nodes lastSelectedNode
        local endIndex = getNodeIndex parent.Nodes node
        if startIndex > -1 and endIndex > -1 do
        (
            local minI = amin #(startIndex,endIndex)
            local maxI = amax #(startIndex,endIndex)
            selectedNodes = #(); objsToSelect = #()
            for i = minI to maxI do
            (
                local n = parent.Nodes.Item[i]
                append selectedNodes n
                if n.Tag != undefined do append objsToSelect n.Tag.value
            )
            select objsToSelect
        )
    )
    else if ctrlDown then
    (
        for n in nodesToPaint do if (findItem selectedNodes n) == 0 do append selectedNodes n
        select (selection as array + objsToSelect)
        lastSelectedNode = node
    )
    else
    (
        resetAllColors sender
        selectedNodes = nodesToPaint
        select objsToSelect
        lastSelectedNode = node
    )

    resetAllColors sender
    paintSelectedNodes selectedNodes
)

-- Callback ??? ????????????? ??????
callbacks.removeScripts id:#carHierarchySelection

_cbScript =
"(
    if g_tvHierarchy != undefined and isKindOf g_tvHierarchy dotNetControl do
    (
        if selection.count > 0 then
        (
            resetAllColors g_tvHierarchy
            selectedNodes = #()
            for obj in selection do
            (
                if isValidDummy obj then
                (
                    local nd = findNodeByObject g_tvHierarchy obj
                    if nd != undefined do append selectedNodes nd
                )
            )
            paintSelectedNodes selectedNodes
            if selectedNodes.count > 0 then selectedNodes[1].EnsureVisible()
        )
    )
)"

callbacks.addScript #selectionSetChanged _cbScript id:#carHierarchySelection
