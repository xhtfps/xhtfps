#requires -Version 7.0
<#
.SYNOPSIS
    基于 catalog.json 做一次静态体检，结果写 HEALTH.md。
.DESCRIPTION
    只看机器可判断的硬指标：体积、更新活跃度、topics 缺失、README 缺失、visibility 结构。
    不做风格评判。产物 HEALTH.md 由 CI 定时重写，人工不用改。
.EXAMPLE
    pwsh ./tools/health-check.ps1
#>
[CmdletBinding()]
param(
    [string]$CatalogPath = (Join-Path $PSScriptRoot '..\catalog.json'),
    [string]$OutPath     = (Join-Path $PSScriptRoot '..\HEALTH.md'),
    [int]$SizeLimitMb    = 200,
    [int]$StaleDays      = 180
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $CatalogPath)) { throw "找不到 $CatalogPath，先跑 tools/build-index.ps1" }
$cat = Get-Content -LiteralPath $CatalogPath -Raw -Encoding utf8 | ConvertFrom-Json
$repos = $cat.repos
$today = Get-Date

function Format-Mb([double]$kb) {
    if ($kb -ge 1024) { return ('{0:N0} MB' -f ($kb / 1024)) }
    return ('{0:N0} KB' -f $kb)
}

$totalMb = ($repos | Measure-Object -Property head_size_kb -Sum).Sum / 1024
$pub = ($repos | Where-Object visibility -eq '公开').Count
$priv = ($repos | Where-Object visibility -eq '私有').Count

$heavy = $repos | Where-Object { $_.head_size_kb / 1024 -ge $SizeLimitMb } | Sort-Object -Property head_size_kb -Descending
$stale = $repos | ForEach-Object {
    $d = [datetime]$_.pushed_at
    [pscustomobject]@{ name = $_.name; days = [int]($today - $d).TotalDays; date = $_.pushed_at }
} | Where-Object { $_.days -ge $StaleDays } | Sort-Object -Property days -Descending
$noTopics = $repos | Where-Object { -not $_.topics -or $_.topics.Count -eq 0 }
$noReadme = $repos | Where-Object { $_.readme_sections -le 1 }

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# 仓库体检（HEALTH）')
[void]$sb.AppendLine()
[void]$sb.AppendLine("> 由 ``tools/health-check.ps1`` 定时生成（$($today.ToString('yyyy-MM-dd HH:mm'))），基于 ``catalog.json``，只看硬指标。")
[void]$sb.AppendLine()
[void]$sb.AppendLine('## 1. 概览')
[void]$sb.AppendLine()
[void]$sb.AppendLine('| 指标 | 值 |')
[void]$sb.AppendLine('| --- | --- |')
[void]$sb.AppendLine("| 仓库数 | $($repos.Count)（公开 $pub / 私有 $priv） |")
[void]$sb.AppendLine("| HEAD 体积合计 | $(Format-Mb ([double]$totalMb * 1024)) |")
[void]$sb.AppendLine("| 超 ${SizeLimitMb} MB 的仓 | $($heavy.Count) 个 |")
[void]$sb.AppendLine("| 超过 $StaleDays 天未更新 | $($stale.Count) 个 |")
[void]$sb.AppendLine("| 没有 topics | $($noTopics.Count) 个 |")
[void]$sb.AppendLine("| README 只有标题 | $($noReadme.Count) 个 |")
[void]$sb.AppendLine()

[void]$sb.AppendLine("## 2. 体积红线（≥ ${SizeLimitMb} MB，按 HEAD 检出体积）")
[void]$sb.AppendLine()
if ($heavy.Count -eq 0) {
    [void]$sb.AppendLine('全部达标。')
} else {
    [void]$sb.AppendLine('| 仓库 | HEAD 体积 | diskUsage | 建议 |')
    [void]$sb.AppendLine('| --- | --- | --- | --- |')
    foreach ($r in $heavy) {
        $adv = if ($r.head_size_kb / 1024 -ge 400) { '优先瘦身：手册/视频/安装包移出后重写历史' }
               elseif ($r.head_size_kb / 1024 -ge 250) { '权重走 Release，资料移出' }
               else { '按 SLIM-PLAN.md 排期' }
        [void]$sb.AppendLine("| [``$($r.name)``](https://github.com/xhtfps/$($r.name)) | $(Format-Mb $r.head_size_kb) | $(Format-Mb $r.size_kb) | $adv |")
    }
}
[void]$sb.AppendLine()

[void]$sb.AppendLine("## 3. 长期未更新（≥ $StaleDays 天）")
[void]$sb.AppendLine()
if ($stale.Count -eq 0) {
    [void]$sb.AppendLine('无。')
} else {
    [void]$sb.AppendLine('| 仓库 | 最近推送 | 间隔 |')
    [void]$sb.AppendLine('| --- | --- | --- |')
    foreach ($s in $stale) { [void]$sb.AppendLine("| [``$($s.name)``](https://github.com/xhtfps/$($s.name)) | $($s.date) | $($s.days) 天 |") }
}
[void]$sb.AppendLine()

[void]$sb.AppendLine('## 4. 元数据缺失')
[void]$sb.AppendLine()
if ($noTopics.Count -eq 0) { [void]$sb.AppendLine('- topics：全部仓库都有') } else {
    [void]$sb.AppendLine("- topics 缺失：$((($noTopics | ForEach-Object { $_.name }) -join '、'))")
}
if ($noReadme.Count -eq 0) { [void]$sb.AppendLine('- README：全部有正文') } else {
    [void]$sb.AppendLine("- README 过薄：$((($noReadme | ForEach-Object { $_.name }) -join '、'))")
}
[void]$sb.AppendLine()
[void]$sb.AppendLine('## 5. 处置入口')
[void]$sb.AppendLine()
[void]$sb.AppendLine('- 体积与历史：`SLIM-PLAN.md` + `tools/slim-history.ps1`')
[void]$sb.AppendLine('- topics 词表：`TOPICS.md` + `tools/set-topics.ps1`')
[void]$sb.AppendLine('- 索引与表格：`tools/build-index.ps1`（CI 每天重跑）')

[IO.File]::WriteAllText($OutPath, $sb.ToString(), (New-Object Text.UTF8Encoding($false)))
"写完 $OutPath：$($repos.Count) 仓，超限 $($heavy.Count) 个，陈旧 $($stale.Count) 个"
