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
  gh api "repos/$Owner/$Repo/contents/$Path" --silent 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function Get-RepoText {
  param($Repo, $Path)
  $out = gh api "repos/$Owner/$Repo/contents/$Path" -H "Accept: application/vnd.github.raw" 2>$null | Out-String
  if($LASTEXITCODE -ne 0){ return "" }
  return $out
}

$json = gh repo list $Owner --limit 200 --json name,isArchived,visibility,diskUsage,repositoryTopics,description 2>$null | Out-String
if(-not $json) { throw "gh repo list 失败，先检查 gh auth status" }
$repos = $json | ConvertFrom-Json
$rows = @()

foreach($r in ($repos | Where-Object { -not $_.isArchived })) {
  $missing = @()
  foreach($f in $RequiredFiles) { if(-not (Test-RepoFile $r.name $f)) { $missing += $f } }

  $readme = Get-RepoText $r.name "README.md"
  $missSec = @()
  foreach($s in $RequiredSections) {
    if($readme -notmatch [regex]::Escape($s)) { $missSec += ($s -replace '## ','') }
  }

  $mb = [math]::Round($r.diskUsage / 1024, 1)
  $topicCount = @($r.repositoryTopics).Count
  $needSummary = ($r.diskUsage -gt 51200)   # 50 MB 以上应有排除摘要
  $hasSummary = Test-RepoFile $r.name "EXCLUDED_FILES.md"
  $hasFatCsv  = Test-RepoFile $r.name "EXCLUDED_MANIFEST.csv"

  $issues = @()
  if($missing.Count -gt 0)  { $issues += "缺文件: " + ($missing -join ",") }
  if($missSec.Count -gt 0)  { $issues += "README 缺段: " + ($missSec -join ",") }
  if($topicCount -lt 3)     { $issues += "topics=$topicCount<3" }
  if(-not $r.description)   { $issues += "无描述" }
  if($needSummary -and -not $hasSummary) { $issues += "大仓库缺 EXCLUDED_FILES.md" }
  if($hasFatCsv)            { $issues += "仍有逐文件 CSV" }

  $rows += [pscustomobject]@{
    仓库   = $r.name
    可见性 = $r.visibility
    体积MB = $mb
    Topics = $topicCount
    结论   = if($issues.Count -eq 0){ "OK" } else { "需修" }
    问题   = $issues -join "；"
  }
}

$sorted = $rows | Sort-Object @{Expression={$_.结论 -ne "OK"}; Descending=$true}, @{Expression={$_.体积MB}; Descending=$true}
$sorted | Format-Table 仓库, 可见性, 体积MB, Topics, 结论, 问题 -AutoSize | Out-String -Width 220 | Write-Output

$bad = @($rows | Where-Object { $_.结论 -ne "OK" }).Count
Write-Output ("合计 {0} 个活跃仓库，合规 {1}，需修 {2}" -f $rows.Count, ($rows.Count - $bad), $bad)

if($WriteReport) {
  $head = @"
# 仓库体检报告

生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm')　账号：$Owner

| 仓库 | 可见性 | 体积 MB | Topics | 结论 | 问题 |
| --- | --- | --- | --- | --- | --- |
"@
  $body = ($sorted | ForEach-Object {
    "| {0} | {1} | {2} | {3} | {4} | {5} |" -f $_.仓库, $_.可见性, $_.体积MB, $_.Topics, $_.结论, $_.问题
  }) -join "`n"
  Set-Content -Path "repo-audit-report.md" -Value ($head + $body) -Encoding utf8
  Write-Output "已写入 repo-audit-report.md"
}
