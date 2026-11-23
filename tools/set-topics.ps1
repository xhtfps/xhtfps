#requires -Version 7.0
<#
.SYNOPSIS
    按 TOPICS.md 词表给全部仓库写 GitHub topics（可 -DryRun 只看不写）。
.DESCRIPTION
    输入是 catalog.json（先跑 tools/build-index.ps1）。标签按“结构→芯片→工具链→领域→外设”顺序拼，
    词表外的一律丢弃；已有标签里属于词表的会被保留并合并。
.EXAMPLE
    pwsh ./tools/set-topics.ps1 -DryRun
    pwsh ./tools/set-topics.ps1 -Token $env:GITHUB_TOKEN
#>
[CmdletBinding()]
param(
    [string]$Owner = 'xhtfps',
    [string]$CatalogPath = (Join-Path $PSScriptRoot '..\catalog.json'),
    [int]$MaxTopics = 8,
    [switch]$DryRun,
    [string]$Token = $env:GITHUB_TOKEN
)

$ErrorActionPreference = 'Stop'
$cat = Get-Content -LiteralPath $CatalogPath -Raw -Encoding utf8 | ConvertFrom-Json

# ---------------------------------------------------------------- 词表
$structTags = @('index','project-collection','project','course','competition','reference','driver-library','knowledge-base')
$chipTags   = @('stm32f4','stm32h7','gd32','esp32','esp32s3','zynq','k230','imx6ull')
$toolTags   = @('keil','cubemx','freertos','lvgl','espidf','canmv','pytorch','opencv')
$domainTags = @('dds','adc','imu','motor-control','power-electronics','signal-processing','computer-vision','deep-learning','yolo','speech','robot','dataset','math-modeling')
$periphTags = @('ad9959','ads1256','mpu6050','adf4351','adf4001','adf4360','pga2310','pga4311','ad8370','si5351','cdce937','ds18b20','tmp275','dac8562','ssd1963','ltdc')
$generic    = @('embedded','electronics','mcu')
$vocab = @($structTags + $chipTags + $toolTags + $domainTags + $periphTags + $generic)

function Get-StructTag {
    param($r)
    switch ($r.category) {
        '索引'       { return 'index' }
        '板卡工程集' { return 'project-collection' }
        '具体项目'   { return 'project' }
        '竞赛与课程' {
            if ($r.name -match 'competition|cup|shuweibei|diansai|电赛') { return 'competition' }
            return 'course'
        }
        '资料库'     { return 'reference' }
        '支撑库'     {
            if ($r.name -eq 'bsp-libs') { return 'driver-library' }
            return 'knowledge-base'
        }
        default      { return '' }
    }
}

function Get-ChipTags {
    param([string]$chip)
    $out = New-Object System.Collections.Generic.List[string]
    if ($chip -match 'STM32F4')   { $out.Add('stm32f4') }
    if ($chip -match 'STM32H7')   { $out.Add('stm32h7') }
    if ($chip -match 'GD32')      { $out.Add('gd32') }
    if ($chip -match 'ESP32-S3')  { $out.Add('esp32s3') } elseif ($chip -match 'ESP32') { $out.Add('esp32') }
    if ($chip -match 'ZYNQ')      { $out.Add('zynq') }
    if ($chip -match 'K230')      { $out.Add('k230') }
    if ($chip -match 'MX6ULL')    { $out.Add('imx6ull') }
    return $out
}

function Get-ToolTags {
    param([string]$stack)
    $out = New-Object System.Collections.Generic.List[string]
    if ($stack -match 'Keil')            { $out.Add('keil') }
    if ($stack -match 'CubeMX')          { $out.Add('cubemx') }
    if ($stack -match 'FreeRTOS')        { $out.Add('freertos') }
    if ($stack -match 'LVGL')            { $out.Add('lvgl') }
    if ($stack -match 'ESP-IDF')         { $out.Add('espidf') }
    if ($stack -match 'CanMV')           { $out.Add('canmv') }
    if ($stack -match 'PyTorch|torch')   { $out.Add('pytorch') }
    if ($stack -match 'OpenCV')          { $out.Add('opencv') }
    return $out
}

function Get-DomainTags {
    param($r)
    $out = New-Object System.Collections.Generic.List[string]
    $per = @($r.peripherals)
    if ($per -contains 'AD9959' -or $r.name -match 'dds|rlc|lissajous') { $out.Add('dds') }
    if ($per -contains 'ADS1256') { $out.Add('adc') }
    if ($per -contains 'MPU6050') { $out.Add('imu') }
    if ($r.name -match 'fad-vision|yolo|vision') { $out.Add('computer-vision') }
    if ($r.name -match 'dl-pytorch|fad-vision')  { $out.Add('deep-learning') }
    if ($r.name -match 'speech|gpt-sovits|whisper') { $out.Add('speech') }
    if ($r.name -match 'robot|dance') { $out.Add('robot') }
    if ($r.name -match 'math-modeling|shuweibei') { $out.Add('math-modeling') }
    if ($r.name -match 'electronics-competition|电赛') { $out.Add('signal-processing') }
    if ($r.name -match 'novelty|nir-') { $out.Add('signal-processing') }
    return ($out | Select-Object -Unique)
}

function Get-PeriphTags {
    param($r)
    $known = @{}
    $periphTags | ForEach-Object { $known[$_.ToUpper()] = $true }
    return @($r.peripherals | Where-Object { $known.ContainsKey($_.ToUpper()) } | ForEach-Object { $_.ToLower() } | Select-Object -First 3)
}

# ---------------------------------------------------------------- 计算
$plan = @()
foreach ($r in ($cat.repos | Sort-Object name)) {
    $tags = New-Object System.Collections.Generic.List[string]
    $tags.Add((Get-StructTag $r))
    Get-ChipTags $r.chip | ForEach-Object { $tags.Add($_) }
    Get-ToolTags $r.stack | ForEach-Object { $tags.Add($_) }
    # 领域与外设标签只给“真的在用”的工程仓；索引/资料库/知识库不继承这些词
    $allowDomain = $r.category -in @('板卡工程集','具体项目','竞赛与课程')
    $allowPeriph = $allowDomain -or $r.name -eq 'bsp-libs'
    if ($allowDomain) { Get-DomainTags $r | ForEach-Object { $tags.Add($_) } }
    if ($allowPeriph) { Get-PeriphTags $r | ForEach-Object { $tags.Add($_) } }

    $existing = @($r.topics | Where-Object { $vocab -contains $_ })
    foreach ($e in $existing) { if (-not $tags.Contains($e)) { $tags.Add($e) } }

    $final = @($tags | Where-Object { $_ -and $vocab -contains $_ } | Select-Object -Unique)
    # esp32s3 比 esp32 更具体，两级别同时出现时去掉泛的那个
    if ($final -contains 'esp32s3' -and $final -contains 'esp32') { $final = $final | Where-Object { $_ -ne 'esp32' } }
    if ($final.Count -eq 0) { $final = @('embedded') }
    if ($final.Count -gt $MaxTopics) { $final = $final[0..($MaxTopics - 1)] }
    if ($r.category -eq '索引') { $final = @('index') }
    $plan += [pscustomobject]@{ repo = $r.name; topics = $final }
}

foreach ($p in $plan) {
    $dropped = @($p.topics | Where-Object { $false })  # 占位，保持结构清晰
    "{0,-32} {1}" -f $p.repo, ($p.topics -join ', ')
}

if ($DryRun) { "`n[DryRun] 共 $($plan.Count) 个仓库，未写入。" ; exit 0 }

# ---------------------------------------------------------------- 写入
if (-not $Token) { throw '需要 Token：-Token 或 $env:GITHUB_TOKEN（需 repo 权限以改 topics）' }
$headers = @{
    'Accept'               = 'application/vnd.github+json'
    'Authorization'        = "Bearer $Token"
    'User-Agent'           = 'xhtfps-topics'
    'X-GitHub-Api-Version' = '2022-11-28'
}
foreach ($p in $plan) {
    $body = @{ names = @($p.topics) } | ConvertTo-Json -Compress
    $ok = $false
    for ($i = 1; $i -le 4 -and -not $ok; $i++) {
        try {
            Invoke-RestMethod -Method PUT -Uri "https://api.github.com/repos/$Owner/$($p.repo)/topics" `
                -Headers $headers -Body $body -ContentType 'application/json; charset=utf-8' | Out-Null
            "OK   $($p.repo)"
            $ok = $true
        } catch {
            if ($i -eq 4) { "FAIL $($p.repo)：$($_.Exception.Message)" } else { Start-Sleep -Seconds (2 * $i) }
        }
    }
}
