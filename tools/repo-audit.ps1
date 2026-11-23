<#
  repo-audit.ps1 - 按 REPO-STANDARD.md 体检本账号全部仓库

  用法：
    pwsh -File .\tools\repo-audit.ps1                  # 只在控制台输出
    pwsh -File .\tools\repo-audit.ps1 -WriteReport       # 同时写 repo-audit-report.md
    pwsh -File .\tools\repo-audit.ps1 -Owner someone     # 体检别家账号

  依赖：gh CLI 已登录（gh auth status 显示有 repo 权限）。
  只读操作，不会改动任何仓库。
#>
param(
  [string]$Owner = "xhtfps",
  [switch]$WriteReport
)

$ErrorActionPreference = "Continue"
$RequiredFiles = @("README.md", "LICENSE", ".gitignore", ".gitattributes")
$RequiredSections = @("## 1.", "## 2.", "## 3.", "## 4.", "## 5.", "## 6.")

function Test-RepoFile {
  param($Repo, $Path)
  $out = gh api "repos/$Owner/$Repo/contents/$Path" --silent 2>$null
  return ($LASTEXITCODE -eq 0)
}

function Get-RepoText {
  param($Repo, $Path)
  $out = gh api "repos/$Owner/$Repo/contents/$Path" -H "Accept: application/vnd.github.raw" 2>$null | Out-String
  if($LASTEXITCODE -ne 0){ return "" }
  return $out
}

$repos = gh repo list $Owner --limit 200 --json name,isArchived,visibility,diskUsage,topics,description | ConvertFrom-Json
$rows = @()

foreach($r in ($repos | Where-Object { -not $_.isArchived })) {
  $missing = @()
  foreach($f in $RequiredFiles) { if(-not (Test-RepoFile $r.name $f)) { $missing += $f } }

  $readme = Get-RepoText $r.name "README.md"
  $missSec = @()
  foreach($s in $RequiredSections) { if($readme -notmatch [regex]::Escape($s)) { $missSec += ($s -replace '## ','') } }

  $needSummary = ($r.diskUsage -gt 51200)   # 50 MB 以上应有排除摘要
  $hasSummary = Test-RepoFile $r.name "EXCLUDED_FILES.md"
  $hasFatCsv = Test-RepoFile $r.name "EXCLUDED_MANIFEST.csv"

  $issues = @()
  if($missing.Count -gt 0)   { $issues += "缺文件: " + ($missing -join ",") }
  if($missSec.Count -gt 0)   { $issues += "README 缺段: " + ($missSec -join ",") }
  if($r.topics.Count -lt 3)  { $issues += "topics<3" }
  if(-not $r.description)    { $issues += "无描述" }
  if($needSummary -and -not $hasSummary) { $issues += "大仓库缺 EXCLUDED_FILES.md" }
  if($hasFatCsv)             { $issues += "仍有逐文件 CSV" }

  $rows += [pscustomobject]@{
    仓库     = $r.name
    可见性   = $r.visibility
    体积MB   = $r.diskUsage / 1024
    Topics   = $r.topics.Count
    结论     = if($issues.Count -eq 0){ "OK" } else { "需修" }
    问题     = $issues -join "；"
  }
}

$rows | Sort-Object @{Expression={$_.结论 -ne "OK"}; Descending=$true}, 体积MB -Descending |
  Format-Table 仓库, 可见性, @{n="体积MB";e={[math]::Round($_.体积MB,1)}}, Topics, 结论, 问题 -AutoSize | Out-String -Width 200

$bad = ($rows | Where-Object { $_.结论 -ne "OK" }).Count
Write-Output ("合计 {0} 个活跃仓库，合规 {1}，需修 {2}" -f $rows.Count, ($rows.Count - $bad), $bad)

if($WriteReport) {
  $head = "# 仓库体检报告`n`n生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm')　账号：$Owner`n`n| 仓库 | 可见性 | 体积 MB | Topics | 结论 | 问题 |`n| --- | --- | --- | --- | --- | --- |"
  $body = $rows | Sort-Object 体积MB -Descending | ForEach-Object {
    "| {0} | {1} | {2} | {3} | {4} | {5} |" -f $_.仓库, $_.可见性, [math]::Round($_.体积MB,1), $_.Topics, $_.结论, $_.问题
  }
  Set-Content -Path "repo-audit-report.md" -Value (($head, $body -join "`n")) -Encoding utf8
  Write-Output "已写入 repo-audit-report.md"
}
