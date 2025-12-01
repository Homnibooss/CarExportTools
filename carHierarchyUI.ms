-- ??????? rollout, ????????? ?????? ??????? ? ?????????? ??????????

global selectedNodes = #()
global lastSelectedNode = undefined
global currentColor = (dotNetClass "System.Drawing.Color").LightBlue
global tableBackColor = (dotNetClass "System.Drawing.Color").White

fn getNodeIndex nodes target =
(
    for i = 0 to (nodes.Count - 1) do
        if nodes.Item[i] == target then return i
    -1
)

fn isValidDummy d =
(
    if not isKindOf d Dummy then return false
    if matchPattern d.name pattern:"source*" then return false
    if matchPattern d.name pattern:"root_*" then return true
    local firstChar = substring d.name 1 1
    (firstChar == toUpper firstChar)
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

fn setupTreeView tv cbColors cbBackColors =
(
    tv.ShowLines = true
    tv.ShowRootLines = true
    tv.ShowPlusMinus = true
    tv.HideSelection = false
    tv.PathSeparator = "/"
    tv.Font = dotNetObject "System.Drawing.Font" "Consolas" 9
    tv.BackColor = tableBackColor

    cbColors.Items.Clear()
    cbBackColors.Items.Clear()

    cbColors.DropDownStyle     = (dotNetClass "System.Windows.Forms.ComboBoxStyle").DropDownList
    cbBackColors.DropDownStyle = (dotNetClass "System.Windows.Forms.ComboBoxStyle").DropDownList

    local colors = #("LightBlue","LightGreen","LightYellow","Orange","Pink","Purple","Gray","White","Black")
    for c in colors do
    (
        cbColors.Items.Add c
        cbBackColors.Items.Add c
    )
    cbColors.SelectedIndex = 0
    cbBackColors.SelectedIndex = 7 -- White

    -- ????????? ?????? ?? TreeView ? Tag
    cbColors.Tag     = dotNetMXSValue tv
    cbBackColors.Tag = dotNetMXSValue tv

    -- ??????????? ????? sender
    dotNet.addEventHandler cbColors "SelectedIndexChanged" (
        fn handler sender args =
        (
            local tvCtrl = sender.Tag.value
            changeHighlightColor tvCtrl sender
        )
    )

    dotNet.addEventHandler cbBackColors "SelectedIndexChanged" (
        fn handler sender args =
        (
            local tvCtrl = sender.Tag.value
            changeBackColor tvCtrl sender
        )
    )
)






fn addChildrenRecursive parentNode obj =
(
    local children = for c in obj.children where isValidDummy c collect c
    for child in children do
    (
        local childNode = parentNode.Nodes.Add child.name
        childNode.Tag = dotNetMXSValue child
        addChildrenRecursive childNode child
    )
)

fn rebuildTree tv =
(
    tv.BeginUpdate()
    tv.Nodes.Clear()
    selectedNodes = #()
    lastSelectedNode = undefined

    local roots = for obj in objects where (
        isValidDummy obj and matchPattern obj.name pattern:"root_*" and
        (obj.parent == undefined or not isKindOf obj.parent Dummy)
    ) collect obj

    for r in roots do
    (
        local rootNode = tv.Nodes.Add r.name
        rootNode.Tag = dotNetMXSValue r
        addChildrenRecursive rootNode r
    )

    tv.EndUpdate()
    tv.ExpandAll()
)

fn changeHighlightColor tv cbColors =
(
    local chosen = cbColors.SelectedItem
    if chosen != undefined do
    (
        currentColor = (dotNetClass "System.Drawing.Color").FromName chosen
        resetAllColors tv
        paintSelectedNodes selectedNodes
    )
)

fn changeBackColor tv cbBackColors =
(
    local chosen = cbBackColors.SelectedItem
    if chosen != undefined do
    (
        tableBackColor = (dotNetClass "System.Drawing.Color").FromName chosen
        tv.BackColor   = tableBackColor
        resetAllColors tv
        paintSelectedNodes selectedNodes
    )
)


fn handleNodeClick tv args =
(
    local node = args.Node
    if node == undefined then return()
    if node.Tag == undefined then return()

    local mxsObj = node.Tag.value
    if mxsObj == undefined then return()

    local objsToSelect = #()
    local nodesToPaint = #()

    if matchPattern mxsObj.name pattern:"root_*" then
    (
        collectChildrenSkipMeshes mxsObj objsToSelect
        for i = 0 to (node.Nodes.Count - 1) do append nodesToPaint node.Nodes.Item[i]
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
        if parent == undefined then parent = tv.Nodes

        local startIndex = getNodeIndex parent.Nodes lastSelectedNode
        local endIndex   = getNodeIndex parent.Nodes node

        if startIndex > -1 and endIndex > -1 do
        (
            local minI = amin #(startIndex,endIndex)
            local maxI = amax #(startIndex,endIndex)
            selectedNodes = #()
            objsToSelect = #()
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
        resetAllColors tv
        selectedNodes = nodesToPaint
        select objsToSelect
        lastSelectedNode = node
    )

    resetAllColors tv
    paintSelectedNodes selectedNodes
)
