param([string]$Only)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$pageRoot = Join-Path $projectRoot 'Food_Delivery_Dashboard.Report\definition\pages\04d80d09a565e42044b7'
$visualRoot = Join-Path $pageRoot 'visuals'
$resolvedVisualRoot = (Resolve-Path -LiteralPath $visualRoot).Path
if (-not $resolvedVisualRoot.StartsWith($projectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to modify visuals outside the project: $resolvedVisualRoot"
}
$outputDocs = [ordered]@{}

function Literal([string]$value) {
    return @{ expr = @{ Literal = @{ Value = $value } } }
}

function Solid([string]$color) {
    return @{ solid = @{ color = Literal("'$color'") } }
}

function ColumnField([string]$property) {
    return @{ Column = @{ Expression = @{ SourceRef = @{ Entity = 'final_data' } }; Property = $property } }
}

function MeasureField([string]$property) {
    return @{ Measure = @{ Expression = @{ SourceRef = @{ Entity = 'final_data' } }; Property = $property } }
}

function Projection($field, [string]$queryRef, [string]$nativeQueryRef, [bool]$active = $false) {
    $projection = [ordered]@{ field = $field; queryRef = $queryRef; nativeQueryRef = $nativeQueryRef }
    if ($active) { $projection.active = $true }
    return $projection
}

function MeasureProjection([string]$name) {
    return Projection (MeasureField $name) "final_data.$name" $name
}

function ColumnProjection([string]$name, [bool]$active = $true) {
    return Projection (ColumnField $name) "final_data.$name" $name $active
}

function ContainerObjects([string]$title, [string]$background = '#171C2B', [bool]$showTitle = $true, [bool]$showHeader = $true) {
    return [ordered]@{
        title = @(@{ properties = [ordered]@{
            show = Literal($(if ($showTitle) { 'true' } else { 'false' }))
            text = Literal("'$title'")
            titleWrap = Literal('true')
            fontColor = Solid '#F5F7FC'
            fontFamily = Literal("'Segoe UI Semibold'")
            fontSize = Literal('13D')
            bold = Literal('true')
            alignment = Literal("'left'")
        } })
        background = @(@{ properties = [ordered]@{
            show = Literal('true')
            color = Solid $background
            transparency = Literal('0D')
        } })
        border = @(@{ properties = [ordered]@{
            show = Literal('true')
            color = Solid '#293147'
            radius = Literal('10D')
            width = Literal('1D')
        } })
        visualHeader = @(@{ properties = [ordered]@{
            show = Literal($(if ($showHeader) { 'true' } else { 'false' }))
            foreground = Solid '#9CA8BD'
            background = Solid $background
            border = Solid $background
        } })
    }
}

function New-VisualFile([string]$name, [double]$x, [double]$y, [double]$width, [double]$height, [int]$z, [int]$tabOrder, $visual) {
    $doc = [ordered]@{
        '$schema' = 'https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.10.0/schema.json'
        name = $name
        position = [ordered]@{ x = $x; y = $y; z = $z; height = $height; width = $width; tabOrder = $tabOrder }
        visual = $visual
    }
    $json = $doc | ConvertTo-Json -Depth 100 -Compress
    $script:outputDocs["Food_Delivery_Dashboard.Report/definition/pages/04d80d09a565e42044b7/visuals/$name/visual.json"] = $json
}

function CardVisual([string]$measure, [string]$accent, [bool]$categoryLabel = $true, [bool]$showValue = $true, [string]$background = '#171C2B') {
    $objects = [ordered]@{
        labels = @(@{ properties = [ordered]@{
            show = Literal($(if ($showValue) { 'true' } else { 'false' }))
            fontSize = Literal('26D')
            bold = Literal('true')
            color = Solid '#F5F7FC'
            labelDisplayUnits = Literal('0D')
        } })
        categoryLabels = @(@{ properties = [ordered]@{
            show = Literal($(if ($categoryLabel) { 'true' } else { 'false' }))
            fontSize = Literal('11D')
            bold = Literal('false')
            color = Solid '#9CA8BD'
            fontFamily = Literal("'Segoe UI'")
        } })
    }
    $container = ContainerObjects '' $background $false $false
    $container.border[0].properties.color = Solid $accent
    return [ordered]@{
        visualType = 'card'
        query = @{ queryState = @{ Values = @{ projections = @((MeasureProjection $measure)) } } }
        objects = $objects
        visualContainerObjects = $container
        drillFilterOtherVisuals = $true
    }
}

function ChartVisual([string]$type, [string]$title, $queryState, [string]$accent, $sortField = $null) {
    $query = [ordered]@{ queryState = $queryState }
    if ($null -ne $sortField) {
        $query.sortDefinition = @{ sort = @(@{ field = $sortField; direction = 'Descending' }); isDefaultSort = $true }
    }
    return [ordered]@{
        visualType = $type
        query = $query
        objects = [ordered]@{
            dataPoint = @(@{ properties = @{ defaultColor = Solid $accent } })
            dataLabels = @(@{ properties = @{ show = Literal('true'); color = Solid '#DCE7FF'; fontSize = Literal('10D') } })
            categoryAxis = @(@{ properties = @{ showAxisTitle = Literal('false'); labelColor = Solid '#9CA8BD'; gridlineShow = Literal('false') } })
            valueAxis = @(@{ properties = @{ showAxisTitle = Literal('false'); labelColor = Solid '#9CA8BD'; gridlineColor = Solid '#293147' } })
            legend = @(@{ properties = @{ show = Literal('true'); labelColor = Solid '#DCE7FF'; position = Literal("'RightCenter'") } })
        }
        visualContainerObjects = ContainerObjects $title
        drillFilterOtherVisuals = $true
    }
}

function SlicerVisual([string]$column, [string]$title, [string]$mode) {
    return [ordered]@{
        visualType = 'slicer'
        query = @{ queryState = @{ Values = @{ projections = @((ColumnProjection $column)) } } }
        objects = [ordered]@{
            data = @(@{ properties = @{ mode = Literal("'$mode'") } })
            general = @(@{ properties = @{} })
            items = @(@{ properties = @{ fontColor = Solid '#F5F7FC'; background = Solid '#121725'; textSize = Literal('11D') } })
            selection = @(@{ properties = @{ selectAllCheckboxEnabled = Literal('true'); singleSelect = Literal('false') } })
        }
        visualContainerObjects = ContainerObjects $title '#121725' $true $true
        drillFilterOtherVisuals = $true
    }
}

# Replace the old six visual definitions in place and add six new definitions.
# Sidebar panel and active navigation pill.
New-VisualFile '26d2f747d78c2d784fdd' 1024 0 256 720 0 0 (CardVisual 'Overview Label' '#121725' $false $false '#121725')
$nav = CardVisual 'Overview Label' '#4F8CFF' $false $true '#263B64'
$nav.objects.labels[0].properties.fontSize = Literal('13D')
$nav.objects.labels[0].properties.color = Solid '#DCE7FF'
New-VisualFile '7fb65e2f61ec36739f8f' 1040 24 224 48 9000 1 $nav

# KPI row.
New-VisualFile 'a4be41e6a928ee9d4c76' 24 24 234 104 1000 2 (CardVisual 'Total Orders' '#4F8CFF')
New-VisualFile '2972b1de38f5a3134a27' 274 24 234 104 1100 3 (CardVisual 'Revenue' '#31D0AA')
New-VisualFile 'c766499154e71b129974' 524 24 234 104 1200 4 (CardVisual 'Average Order Value' '#A970FF')
New-VisualFile '44b73ddaba663c93d45a' 774 24 234 104 1300 5 (CardVisual 'Delivered %' '#31D0AA')

# Revenue by City: horizontal bars with business tooltips.
$revenueCityState = [ordered]@{
    Category = @{ projections = @((ColumnProjection 'city')) }
    Y = @{ projections = @((MeasureProjection 'Revenue')) }
    Tooltips = @{ projections = @((MeasureProjection 'Total Orders'), (MeasureProjection 'Average Order Value'), (MeasureProjection 'Delivered %')) }
}
New-VisualFile '20000000000000000001' 24 148 484 250 2000 6 (ChartVisual 'barChart' 'Revenue by City' $revenueCityState '#4F8CFF' (MeasureField 'Revenue'))

# Status distribution donut.
$statusState = [ordered]@{
    Category = @{ projections = @((ColumnProjection 'status')) }
    Y = @{ projections = @((MeasureProjection 'Total Orders')) }
    Tooltips = @{ projections = @((MeasureProjection 'Revenue'), (MeasureProjection 'Average Order Value'), (MeasureProjection 'Delivered %')) }
}
$statusVisual = ChartVisual 'donutChart' 'Order Status' $statusState '#31D0AA'
$statusVisual.objects.dataLabels[0].properties.show = Literal('true')
$statusVisual.objects.dataLabels[0].properties.labelStyle = Literal("'Category, percent of total'")
$statusVisual.objects.legend[0].properties.position = Literal("'RightCenter'")
New-VisualFile '20000000000000000002' 524 148 484 250 2100 7 $statusVisual

# Order trend over time.
$trendState = [ordered]@{
    Category = @{ projections = @((ColumnProjection 'order_time')) }
    Y = @{ projections = @((MeasureProjection 'Total Orders')) }
    Tooltips = @{ projections = @((MeasureProjection 'Revenue'), (MeasureProjection 'Average Order Value'), (MeasureProjection 'Delivered %')) }
}
$trendVisual = ChartVisual 'lineChart' 'Order Trend over Time' $trendState '#4F8CFF' (ColumnField 'order_time')
$trendVisual.objects.dataLabels[0].properties.show = Literal('false')
$trendVisual.objects.categoryAxis[0].properties.axisType = Literal("'Scalar'")
$trendVisual.objects.shapes = @(@{ properties = @{ strokeWidth = Literal('3D'); showMarker = Literal('true'); markerSize = Literal('5D') } })
New-VisualFile '30000000000000000001' 24 414 604 282 3000 8 $trendVisual

# Average order value by city.
$aovCityState = [ordered]@{
    Category = @{ projections = @((ColumnProjection 'city')) }
    Y = @{ projections = @((MeasureProjection 'Average Order Value')) }
    Tooltips = @{ projections = @((MeasureProjection 'Revenue'), (MeasureProjection 'Total Orders'), (MeasureProjection 'Delivered %')) }
}
New-VisualFile '30000000000000000002' 644 414 364 282 3100 9 (ChartVisual 'columnChart' 'Average Order Value by City' $aovCityState '#A970FF' (MeasureField 'Average Order Value'))

# Right sidebar slicers. Their visual headers retain the built-in clear-selection icon.
New-VisualFile '40000000000000000001' 1040 96 224 228 9100 10 (SlicerVisual 'city' 'City' 'Dropdown')
New-VisualFile '40000000000000000002' 1040 340 224 260 9200 11 (SlicerVisual 'status' 'Order Status' 'Basic')

# Update the page title and background while keeping the report single-page.
$pagePath = Join-Path $pageRoot 'page.json'
$page = Get-Content -LiteralPath $pagePath -Raw | ConvertFrom-Json
$page.displayName = 'Food Delivery Overview'
$page | Add-Member -Force -NotePropertyName objects -NotePropertyValue ([ordered]@{
    background = @(@{ properties = @{ color = Solid '#0B0F19'; transparency = Literal('0D') } })
    outspace = @(@{ properties = @{ color = Solid '#0B0F19' } })
})
$script:outputDocs['Food_Delivery_Dashboard.Report/definition/pages/04d80d09a565e42044b7/page.json'] = ($page | ConvertTo-Json -Depth 100 -Compress)

foreach ($entry in $outputDocs.GetEnumerator()) {
    if ($Only -and $entry.Key -ne $Only) { continue }
    Write-Output ("FILE|" + $entry.Key)
    Write-Output $entry.Value
    Write-Output 'ENDFILE'
}
