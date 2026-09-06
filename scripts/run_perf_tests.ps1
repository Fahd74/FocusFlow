# ═══════════════════════════════════════════════════════════════════════════
#  FocusFlow – Performance Test Runner
#  تشغيل اختبارات الأداء الكاملة لـ Windows و Android
#
#  الاستخدام:
#    .\scripts\run_perf_tests.ps1                    # Windows فقط
#    .\scripts\run_perf_tests.ps1 -Android           # Windows + Android
#    .\scripts\run_perf_tests.ps1 -Android -DbOnly   # قاعدة البيانات فقط
#    .\scripts\run_perf_tests.ps1 -DeviceId "XYZ"    # جهاز أندرويد محدد
# ═══════════════════════════════════════════════════════════════════════════

param(
    [switch]$Android,
    [switch]$DbOnly,
    [switch]$WindowsOnly,
    [string]$DeviceId = "10JF9N00KT0001Q"  # Default: V2529 device
)

# ─── Colors & Helpers ────────────────────────────────────────────────────────
function Write-Header($text) {
    Write-Host ""
    Write-Host ("═" * 60) -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host ("═" * 60) -ForegroundColor Cyan
}

function Write-Step($text) {
    Write-Host "  ▶ $text" -ForegroundColor Yellow
}

function Write-Success($text) {
    Write-Host "  ✓ $text" -ForegroundColor Green
}

function Write-Fail($text) {
    Write-Host "  ✗ $text" -ForegroundColor Red
}

function Write-Info($text) {
    Write-Host "  ℹ $text" -ForegroundColor Gray
}

# ─── Setup ───────────────────────────────────────────────────────────────────
$timestamp   = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportsDir  = "perf_reports"
$winReport   = "$reportsDir\windows_$timestamp.txt"
$mobReport   = "$reportsDir\android_$timestamp.txt"
$dbReport    = "$reportsDir\database_$timestamp.txt"
$summaryFile = "$reportsDir\summary_$timestamp.md"

New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null

Write-Header "FocusFlow Performance Test Runner"
Write-Info "الوقت: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Info "تقارير الأداء ستُحفظ في: $reportsDir\"

# ─── Check Flutter ────────────────────────────────────────────────────────────
Write-Header "1. فحص البيئة"
Write-Step "التحقق من Flutter..."
$flutterVersion = flutter --version 2>&1 | Select-String "Flutter" | Select-Object -First 1
Write-Success "Flutter: $flutterVersion"

Write-Step "الأجهزة المتصلة..."
flutter devices

# ─── Run Windows Tests ────────────────────────────────────────────────────────
if (-not $Android -or $WindowsOnly) {

    if (-not $DbOnly) {
        Write-Header "2. اختبارات الأداء – Windows (PERF-01 → PERF-10)"
        Write-Step "جاري تشغيل performance_test.dart على Windows..."
        $startTime = Get-Date

        flutter test integration_test/performance_test.dart `
            -d windows `
            --reporter expanded `
            2>&1 | Tee-Object -FilePath $winReport

        $exitCode = $LASTEXITCODE
        $elapsed  = ((Get-Date) - $startTime).TotalSeconds

        if ($exitCode -eq 0) {
            Write-Success "اختبارات Windows اكتملت في $([math]::Round($elapsed, 1)) ثانية ✓"
        } else {
            Write-Fail "بعض اختبارات Windows فشلت (exit code: $exitCode)"
        }
        Write-Info "التقرير: $winReport"
    }

    Write-Header "3. اختبارات قاعدة البيانات – Windows (DB-01 → DB-09)"
    Write-Step "جاري تشغيل db_performance_test.dart..."
    $startTime = Get-Date

    flutter test integration_test/db_performance_test.dart `
        -d windows `
        --reporter expanded `
        2>&1 | Tee-Object -FilePath $dbReport

    $exitCode = $LASTEXITCODE
    $elapsed  = ((Get-Date) - $startTime).TotalSeconds

    if ($exitCode -eq 0) {
        Write-Success "اختبارات DB اكتملت في $([math]::Round($elapsed, 1)) ثانية ✓"
    } else {
        Write-Fail "بعض اختبارات DB فشلت (exit code: $exitCode)"
    }
    Write-Info "التقرير: $dbReport"
}

# ─── Run Android Tests ────────────────────────────────────────────────────────
if ($Android -and -not $WindowsOnly) {

    Write-Header "4. اختبارات الأداء – Android (MOB-01 → MOB-10)"
    Write-Step "جاري تشغيل performance_mobile_test.dart على $DeviceId..."

    # Check device is connected
    $deviceList = flutter devices 2>&1
    if ($deviceList -notmatch $DeviceId) {
        Write-Fail "الجهاز $DeviceId غير متصل! تأكد من تفعيل USB Debugging."
        Write-Info "الأجهزة المتاحة:"
        flutter devices
    } else {
        $startTime = Get-Date

        flutter test integration_test/performance_mobile_test.dart `
            -d $DeviceId `
            --reporter expanded `
            2>&1 | Tee-Object -FilePath $mobReport

        $exitCode = $LASTEXITCODE
        $elapsed  = ((Get-Date) - $startTime).TotalSeconds

        if ($exitCode -eq 0) {
            Write-Success "اختبارات Android اكتملت في $([math]::Round($elapsed, 1)) ثانية ✓"
        } else {
            Write-Fail "بعض اختبارات Android فشلت (exit code: $exitCode)"
        }
        Write-Info "التقرير: $mobReport"
    }
}

# ─── Generate Summary Report ─────────────────────────────────────────────────
Write-Header "5. تقرير ملخص النتائج"

$summaryContent = @"
# تقرير أداء FocusFlow
**التاريخ**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**الجهاز**: $($env:COMPUTERNAME)

## نتائج Windows
$(if (Test-Path $winReport) { "``````"; Get-Content $winReport | Select-String "\[PERF\]" | ForEach-Object { $_.Line }; "``````" } else { "_لم يتم تشغيل الاختبار_" })

## نتائج قاعدة البيانات
$(if (Test-Path $dbReport) { "``````"; Get-Content $dbReport | Select-String "\[DB-PERF\]" | ForEach-Object { $_.Line }; "``````" } else { "_لم يتم تشغيل الاختبار_" })

## نتائج Android
$(if (Test-Path $mobReport) { "``````"; Get-Content $mobReport | Select-String "\[MOB-PERF\]" | ForEach-Object { $_.Line }; "``````" } else { "_لم يتم تشغيل الاختبار_" })
"@

$summaryContent | Out-File -FilePath $summaryFile -Encoding UTF8
Write-Success "تقرير الملخص محفوظ في: $summaryFile"

Write-Header "اكتمل التشغيل 🎉"
Write-Info "لعرض نتائج [PERF] من Windows:  Select-String '\[PERF\]' $winReport"
Write-Info "لعرض نتائج [DB-PERF]:          Select-String '\[DB-PERF\]' $dbReport"
if ($Android) {
    Write-Info "لعرض نتائج [MOB-PERF]:         Select-String '\[MOB-PERF\]' $mobReport"
}
