<#
  repo-audit.ps1 - 按 REPO-STANDARD.md 体检本账号全部仓库

  用法：
    pwsh -File .\tools\repo-audit.ps1                  # 只在控制台输出
    pwsh -File .\tools\repo-audit.ps1 -WriteReport       # 同时写 repo-audit-report.md

  依赖：gh CLI 已登录（gh auth status 显示有 repo 权限）。
  只读操作；每个仓库只调 2 次 API（目录列表 + README），并自带重试。
#>
param(
  [string]$Owner = "xhtfps",
  [switch]$WriteReport
)

$ErrorActionPreference = "Continue"
$RequiredFiles = @("README.md", "LICENSE", ".gitignore", ".gitattributes")
$RequiredSections = @("## 1.", "## 2.", "## 3.", "## 4.", "## 5.")

function Invoke-Gh {
  param([string[]]$Args, [int]$Retry = 3)
  for($i = 1; $i -le $Retry; $i++) {
    $out = & gh @Args 2>$null | Out-String
    if($LASTEXITCODE -eq 0 -and $out.Trim().Length -gt 0) { return $out }
    Start-Sleep -Milliseconds 400
  }
  return $null
}

$json = Invoke-Gh @("repo","list",$Owner,"--limit","200","--json","name,isArchived,visibility,diskUsage,repositoryTopics,description")
if(-not $json) { throw "gh repo list 失败，先检查 gh auth status" }
$repos = $json | ConvertFrom-Json
$rows = @()

foreach($r in ($repos | Where-Object { -not $_.isArchived })) {
  $rootJson = Invoke-Gh @("api", "repos/$Owner/$($r.name)/contents")
  $names = @()
  $apiFail = $false
  if($rootJson) { $names = @(($rootJson | ConvertFrom-Json) | ForEach-Object { $_.name }) } else { $apiFail = $true }

  $readme = Invoke-Gh @("api", "repos/$Owner/$($r.name)/contents/README.md", "-H", "Accept: application/vnd.github.raw")
  $missSec = @()
  $readFail = $false
  if(-not $readme) { $readFail = $true }
  else {
    foreach($s in $RequiredSections) {
      if($readme -notmatch [regex]::Escape($s)) { $missSec += ($s -replace '## ').TrimEnd('.') }
    }
  }

  $mb = [math]::Round($r.diskUsage / 1024, 1)
  $topicCount = @($r.repositoryTopics).Count
  $issues = @()

  if($apiFail) { $issues += "目录 API 失败（未判定缺文件）" }
  else {
    $missing = @($RequiredFiles | Where-Object { $names -notcontains $_ })
    if($missing.Count -gt 0) { $issues += "缺文件: " + ($missing -join ",") }
    if($r.diskUsage -gt 51200 -and $names -notcontains "EXCLUDED_FILES.md") { $issues += ">50MB 缺 EXCLUDED_FILES.md" }
    if($names -contains "EXCLUDED_MANIFEST.csv") { $issues += "仍有逐文件 CSV" }
  }

  if($readFail) { $issues += "README 读取失败（网络/限流）" }
  elseif($missSec.Count -gt 0) { $issues += "README 缺段: " + ($missSec -join ",") }
  if($topicCount -lt 3) { $issues += "topics=$topicCount<3" }
  if(-not $r.description) { $issues += "无描述" }
  if($mb -gt 50) { $issues += "体积 $mb MB 超红线" }

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
$sorted | Format-Table 仓库, 可见性, 体积MB, Topics, 结论, 问题 -AutoSize | Out-String -Width 240 | Write-Output

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
