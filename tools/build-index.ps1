#requires -Version 7.0
<#
.SYNOPSIS
    扫描账号下全部仓库，生成 catalog.json，并刷新 README 的仓库地图（§1）。

.DESCRIPTION
    数据源：优先 gh CLI（已登录），否则用 GITHUB_TOKEN 调 REST API。
    - catalog.json 是唯一数据源，README 表格由它渲染，不再手写。
    - README 中 <!-- CATALOG:START --> 与 <!-- CATALOG:END --> 之间的内容会被整体重写。
    - 人工口径（分类 / 芯片 / 板卡 / 状态）写在 tools/catalog-rules.json，优先于自动识别。

.PARAMETER RenderOnly
    不访问网络，只读本地 catalog.json 重新渲染 README。改了 README 文案或表格样式时用。

.PARAMETER Token
    无 gh CLI 时使用的 GitHub token（需 repo 权限才能读到私有仓库）。

.EXAMPLE
    pwsh -File .\tools\build-index.ps1
    pwsh -File .\tools\build-index.ps1 -RenderOnly

.NOTES
    需要 PowerShell 7+。报表字段全部来自 GitHub API 与仓库 README，不做猜测。
#>
[CmdletBinding()]
param(
    [string]$Owner       = 'xhtfps',
    [string]$CatalogPath = (Join-Path $PSScriptRoot '..\catalog.json'),
    [string]$ReadmePath  = (Join-Path $PSScriptRoot '..\README.md'),
    [string]$RulesPath   = (Join-Path $PSScriptRoot 'catalog-rules.json'),
    [switch]$RenderOnly,
    [string]$Token       = $env:GITHUB_TOKEN
)

$ErrorActionPreference = 'Stop'
$StartTag = '<!-- CATALOG:START -->'
$EndTag   = '<!-- CATALOG:END -->'

# ---------------------------------------------------------------- API 访问
$script:UseGh = $false
if (-not $RenderOnly) {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        gh auth status *> $null
        if ($LASTEXITCODE -eq 0) { $script:UseGh = $true }
    }
    if (-not $script:UseGh -and -not $Token) {
        throw '未检测到可用的 GitHub 凭据：请先执行 gh auth login，或设置 GITHUB_TOKEN（需 repo 权限以读取私有仓库）。'
    }
}

function Invoke-GitHubApi {
    param([Parameter(Mandatory)][string]$Path)

    if ($script:UseGh) {
        $raw = gh api -H 'Accept: application/vnd.github+json' $Path 2>$null
        if ($LASTEXITCODE -ne 0) { throw "gh api 调用失败：$Path" }
        return ($raw | ConvertFrom-Json)
    }

    $headers = @{
        'Accept'     = 'application/vnd.github+json'
        'User-Agent' = 'xhtfps-catalog-builder'
    }
    if ($Token) { $headers['Authorization'] = "Bearer $Token" }
    return Invoke-RestMethod -Uri "https://api.github.com$Path" -Headers $headers
}

function Get-ReadmeText {
    param([string]$Repo)
    try {
        $r = Invoke-GitHubApi "/repos/$Owner/$Repo/readme"
        if (-not $r.content) { return '' }
        $b64 = ($r.content -replace '\s', '')
        return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
    }
    catch {
        Write-Warning "读取 $Repo 的 README 失败：$($_.Exception.Message)"
        return ''
    }
}

# ---------------------------------------------------------------- README 解析
function Get-TableField {
    param([string]$Text, [string[]]$Keys)
    foreach ($line in ($Text -split "`n")) {
        if ($line -notmatch '^\|') { continue }
        $cells = $line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() }
        if ($cells.Count -lt 2) { continue }
        foreach ($k in $Keys) {
            if ($cells[0] -match $k) { return ($cells[1] -replace '[`*]', '').Trim() }
        }
    }
    return $null
}

function Get-Chip {
    param([string]$Text, [string[]]$Keys)
    $field = Get-TableField -Text $Text -Keys $Keys
    if ($field) { return $field }

    $pattern = 'STM32[FHLG][0-9]{2,3}[A-Z]{0,3}|GD32[Ff][0-9]{3}[A-Z]{0,2}|ESP32-S3|ESP32|ZYNQ-7020|ZYNQ|K230|IMX6ULL|i\.MX6ULL'
    $m = [regex]::Match($Text, $pattern, 'IgnoreCase')
    if ($m.Success) { return $m.Value.ToUpperInvariant() }
    return ''
}

$PeripheralMap = [ordered]@{
    'AD9959'     = 'AD9959'
    'ADS1256'    = 'ADS1256'
    'MPU6050'    = 'MPU6050'
    'ADF4351'    = 'ADF4351'
    'ADF4001'    = 'ADF4001'
    'ADF4360'    = 'ADF4360'
    'PGA2310'    = 'PGA2310'
    'PGA4311'    = 'PGA4311'
    'AD8370'     = 'AD8370'
    'SI5351'     = 'SI5351A'
    'CDCE937'    = 'CDCE937'
    'DS18B20'    = 'DS18B20'
    'TMP275'     = 'TMP275'
    'DAC8562'    = 'DAC8562'
    'SSD1963'    = 'SSD1963'
    'LTDC'       = 'LTDC'
    'LVGL'       = 'LVGL'
    'FreeRTOS'   = 'FreeRTOS'
    'Modbus'     = 'Modbus'
    'YOLO'       = 'YOLO'
    'Whisper'    = 'Whisper'
    'GPT-SoVITS' = 'GPT-SoVITS'
    'USB'        = 'USB'
    'CAN'        = 'CAN'
}

function Get-Peripherals {
    param([string]$Text)
    $hits = New-Object System.Collections.Generic.List[string]
    foreach ($k in $PeripheralMap.Keys) {
        if ($Text -imatch [regex]::Escape($k)) { $hits.Add($PeripheralMap[$k]) }
    }
    return @($hits)
}

function Get-HeadSizeKb {
    param([string]$Repo, [string]$Branch)
    try {
        $tree = Invoke-GitHubApi "/repos/$Owner/$Repo/git/trees/$Branch`?recursive=1"
        if ($tree.truncated) { return 0 }
        $sum = ($tree.tree | Where-Object { $_.type -eq 'blob' } | Measure-Object -Property size -Sum).Sum
        if (-not $sum) { return 0 }
        return [int]($sum / 1024)
    }
    catch {
        return 0
    }
}

function Get-ReadmeSectionCount {
    param([string]$Text)
    $count = 0
    foreach ($n in 1..5) {
        if ($Text -match "(?m)^##\s*$n") { $count++ }
    }
    return $count
}

# ---------------------------------------------------------------- 分类推断
$CategoryOrder = @('板卡工程集', '具体项目', '竞赛与课程', '资料库', '支撑库', '索引')

function Get-CategoryByRule {
    param([string]$Name)
    switch -Regex ($Name) {
        '^xhtfps$'                                    { return '索引' }
        '-board-materials$|-reference-materials$'     { return '资料库' }
        'hardware-course-materials'                   { return '资料库' }
        '(projects|freertos-labs|cubemx-labs|k230-ai)' { return '板卡工程集' }
        '(course|basics|competition|math-modeling|shuweibei|cup-)' { return '竞赛与课程' }
        '(bsp-libs|notes)'                            { return '支撑库' }
        default                                       { return '具体项目' }
    }
}

# ---------------------------------------------------------------- 主流程
$rules = @{}
if (Test-Path -LiteralPath $RulesPath) {
    $raw = Get-Content -LiteralPath $RulesPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($p in $raw.PSObject.Properties) { $rules[$p.Name] = $p.Value }
}

if ($RenderOnly) {
    if (-not (Test-Path -LiteralPath $CatalogPath)) { throw "找不到 catalog.json：$CatalogPath" }
    $catalog = Get-Content -LiteralPath $CatalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
}
else {
    Write-Host "拉取 $Owner 的仓库列表 ..."
    $repos = @(Invoke-GitHubApi "/user/repos?per_page=100&affiliation=owner&sort=pushed")
    if ($repos.Count -ge 100) { Write-Warning '仓库数达到 100，分页未实现，请补充分页逻辑。' }

    $items = New-Object System.Collections.Generic.List[object]
    $i = 0
    foreach ($repo in ($repos | Where-Object { $_.owner.login -eq $Owner } | Sort-Object -Property name)) {
        $i++
        Write-Progress -Activity '解析仓库' -Status $repo.name -PercentComplete ([math]::Round($i / $repos.Count * 100))
        $text = Get-ReadmeText -Repo $repo.name
        $rule = $rules[$repo.name]

        $chip    = if ($rule -and $rule.chip)  { $rule.chip }  else { Get-Chip       -Text $text -Keys @('MCU', '主控', '芯片', '器件') }
        $board   = if ($rule -and $rule.board) { $rule.board } else { Get-TableField -Text $text -Keys @('开发板', '板卡', '平台') }
        $stack   = if ($rule -and $rule.stack) { $rule.stack } else { @($repo.language, ($repo.topics -join ', ')) | Where-Object { $_ } | Select-Object -First 1 }
        $status  = if ($rule -and $rule.status) { $rule.status } else { '维护中' }
        $category = if ($rule -and $rule.category) { $rule.category } else { Get-CategoryByRule -Name $repo.name }

        $items.Add([pscustomobject][ordered]@{
            name          = $repo.name
            category      = $category
            chip          = [string]$chip
            board         = [string]$board
            stack         = [string]$stack
            status        = [string]$status
            visibility    = if ($repo.private) { '私有' } else { '公开' }
            size_kb       = [int]$repo.diskUsage
            head_size_kb  = Get-HeadSizeKb -Repo $repo.name -Branch $repo.default_branch
            language      = [string]$repo.language
            license       = if ($repo.license) { $repo.license.spdx_id } else { '' }
            topics        = @($repo.topics)
            description   = [string]$repo.description
            default_branch = [string]$repo.default_branch
            pushed_at     = ([datetime]$repo.pushed_at).ToString('yyyy-MM-dd')
            html_url      = [string]$repo.html_url
            readme_sections = Get-ReadmeSectionCount -Text $text
            peripherals   = @(Get-Peripherals -Text $text)
        })
    }
    Write-Progress -Activity '解析仓库' -Completed

    $catalog = [pscustomobject][ordered]@{
        schema       = 1
        owner        = $Owner
        generated_at = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss+08:00')
        repo_count   = $items.Count
        repos        = @($items | Sort-Object -Property name)
    }
}

# ---------------------------------------------------------------- 渲染 README
function Format-Size {
    param([int]$Kb)
    if ($Kb -le 0)       { return '—' }
    if ($Kb -ge 1048576) { return ('{0:N2} GB' -f ($Kb / 1048576)) }
    if ($Kb -ge 1024)    { return ('{0:N0} MB' -f ($Kb / 1024)) }
    return "$Kb KB"
}

function Format-Cell {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return '—' }
    return ($Value -replace '\|', '\|').Trim()
}

$all = @($catalog.repos)
$content = @($all | Where-Object { $_.category -ne '索引' })
$publicCount = @($content | Where-Object { $_.visibility -eq '公开' }).Count
$privateCount = @($content | Where-Object { $_.visibility -eq '私有' }).Count

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("## 1. 仓库地图（$($content.Count) 个内容仓库 + 本索引）")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('> 本节由 `tools/build-index.ps1` 生成，请勿手改；新增或改动仓库后重跑脚本。公开 ' + $publicCount + ' 个 / 私有 ' + $privateCount + ' 个。')
[void]$sb.AppendLine('')

$sectionNo = 0
foreach ($cat in $CategoryOrder) {
    $group = @($content | Where-Object { $_.category -eq $cat } | Sort-Object -Property name)
    if ($group.Count -eq 0) { continue }
    $sectionNo++
    [void]$sb.AppendLine("### 1.$sectionNo $cat（$($group.Count)）")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| 仓库 | 定位 | 可见性 | 芯片 / 板卡 | 技术栈 | 体积 | 状态 |')
    [void]$sb.AppendLine('| --- | --- | --- | --- | --- | --- | --- |')

    foreach ($r in $group) {
        $chipBoard = (@($r.chip, $r.board) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ' / '
        $size = if ($r.head_size_kb) { Format-Size -Kb $r.head_size_kb } else { Format-Size -Kb $r.size_kb }
        $line = '| [{0}]({1}) | {2} | {3} | {4} | {5} | {6} | {7} |' -f `
            $r.name, $r.html_url, (Format-Cell $r.description), $r.visibility, (Format-Cell $chipBoard), (Format-Cell $r.stack), $size, (Format-Cell $r.status)
        [void]$sb.AppendLine($line)
    }
    [void]$sb.AppendLine('')
}

[void]$sb.AppendLine('> 体积 = HEAD 检出文件的真实体积（`git/trees?recursive=1` 求和）；`diskUsage`（含历史）仅作回退。分类、芯片、状态的权威口径在 `tools/catalog-rules.json`。')

$block = $sb.ToString()

$readme = Get-Content -LiteralPath $ReadmePath -Raw -Encoding UTF8
$i = $readme.IndexOf($StartTag)
$j = $readme.IndexOf($EndTag)
if ($i -lt 0 -or $j -lt 0 -or $j -lt $i) {
    throw "README 缺少 CATALOG 标记（$StartTag / $EndTag），请先在 §1 位置插入标记。"
}
$tailStart = $j + $EndTag.Length
$newReadme = $readme.Substring(0, $i) + $StartTag + "`n" + $block + "`n" + $EndTag + $readme.Substring($tailStart)

$utf8 = [System.Text.UTF8Encoding]::new($false)

if (-not $RenderOnly) {
    $catalog | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $CatalogPath -Encoding utf8
    Write-Host "写入 catalog.json：$CatalogPath（$($content.Count) 个内容仓库）"
}

[System.IO.File]::WriteAllText($ReadmePath, $newReadme, $utf8)
Write-Host "刷新 README：$ReadmePath"
