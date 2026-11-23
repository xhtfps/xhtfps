<#
  slim-history.ps1 - 重写历史腾体积（git filter-repo 封装）

  ⚠ 一次重写会改变所有提交 SHA，协作者旧克隆必须重新 clone。
    个人仓库、自己一个人用的仓库才建议跑。

  用法：
    # 1) 先看谁在吃体积（只读，不推送）
    pwsh -File .\tools\slim-history.ps1 -Repo zynq-navigator-board

    # 2) 确认要删的路径后真正执行
    pwsh -File .\tools\slim-history.ps1 -Repo zynq-navigator-board `
        -Remove "6_常用软件" -Remove "9_领航者ZYNQ底板V3.7版本（音频芯片为WM8960）" -Apply

  前置：pip install git-filter-repo（需 PATH 里能找到 git-filter-repo）
#>
param(
  [Parameter(Mandatory)][string]$Repo,
  [string]$Owner = "xhtfps",
  [string[]]$Remove = @(),
  [switch]$Apply
)

$ErrorActionPreference = "Stop"

if(-not (Get-Command git-filter-repo -ErrorAction SilentlyContinue)) {
  Write-Output "缺少 git-filter-repo，先执行： pip install git-filter-repo"
  exit 1
}

$work = Join-Path $env:TEMP ("slim_" + $Repo)
$url  = "https://github.com/$Owner/$Repo.git"

if($Apply -and $Remove.Count -eq 0) { throw "-Apply 必须配至少一个 -Remove 路径" }

if(-not $Apply) {
  Write-Output "== 只读分析：$Owner/$Repo 的前 20 大文件 =="
  $tmp = Join-Path $env:TEMP ("slimprobe_" + $Repo)
  if(Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
  git clone -q --bare $url $tmp
  Push-Location $tmp
  git rev-list --objects --all |
    git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
    ForEach-Object {
      $p = $_ -split ' ', 4
      if($p[0] -eq 'blob' -and $p[3]) { [pscustomobject]@{MB=[double]$p[2]/1MB; Path=$p[3]} }
    } | Sort-Object MB -Descending | Select-Object -First 20 |
    Format-Table @{n="MB";e={[math]::Round($_.MB,1)}}, Path -AutoSize | Out-String -Width 200
  Pop-Location
  Write-Output "确认后加 -Remove <路径> -Apply 执行重写。"
  exit 0
}

if(Test-Path $work) { Remove-Item $work -Recurse -Force }
git clone -q --bare $url $work
Push-Location $work
$args = @("--invert-paths")
foreach($p in $Remove) { $args += @("--path", $p) }
git filter-repo @args --force
Write-Output "== 重写完成，开始强力推送（会改写远端历史）=="
git push --mirror --force $url
Pop-Location

Write-Output "完成。本地旧克隆请重新 clone；服务器空间回收需要 GitHub 侧 GC，一般几分钟到几小时。"
