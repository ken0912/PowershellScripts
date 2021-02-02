[CmdletBinding()]Param(
    [Parameter(Mandatory=$false)]
    [string]$scur,
    [Parameter(Mandatory=$false)]
    [string]$tcur
)
$ScriptRoot = "G:\PowershellScripts\ExchangeRate"
Set-Location $ScriptRoot

function GetExchangeRate([string]$scur,[string]$tcur)
{
    Invoke-WebRequest "https://huobiduihuan.51240.com/?f=$scur&t=$tcur&j=1" -OutFile $env:TEMP\exchangerate.html 
    
    #parsing currency rate
    if((Get-Content $env:TEMP\exchangerate.html -raw -encoding UTF8) -match "(?ms)<title>.*</title>"){
        #$content = $Matches[0] -match "([0-9]+)([0-9]*[0-9]*\.[0-9][0-9]*)"   
        #$Matches 
        #$rate = $Matches[0]

        ##########################
        $arrcontent = $Matches[0] -split "可以兑换 "
        if($arrcontent[1] -match "([0-9]*)([0-9]*[0-9]*\.*[0-9][0-9]*)"){
            $rate = $Matches[0]
        }
    
    }
    #get update time of currency rate
    if((Get-Content $env:TEMP\exchangerate.html -raw -encoding UTF8) -match "(?ms)汇率更新时间：(.*?)）</div>"){
        $chararry = $Matches[0] -split "汇率更新时间：" -split "）"
        $update = $chararry[1]
    }
    del $env:TEMP\exchangerate.html -Force -ea 0
    return $rate,$update
}

$result = GetExchangeRate $scur $tcur
$result_reverse = GetExchangeRate $tcur $scur

if ($result[0] -eq $null){
    return
}

$ts = Get-Date -UFormat "%Y%m%d"
$file_name = "log_{0}" -f $ts

$date = Get-Date -UFormat "%Y-%m-%d %H:%M:%S"
"{0}    {1} -> {2}    1 : {3}    {4}" -f $date,$scur,$tcur,$result[0],$result[1] | Out-File -Append .\log\$file_name.txt

Import-Module ".\Functions.ps1" -Force
$sql_Exists = "
IF EXISTS(SELECT 1
    FROM GlobalSurveyData..tbl_CurrencyConversion
    WHERE ConvertDate = CONVERT(varchar(10),DATEADD(DAY,-DAY(getdate())+1,GETDATE()),120)
	    AND CurrencyCode = '{0}')
BEGIN
	SELECT 1
END 
ELSE
BEGIN
	SELECT 0
END" -f $tcur

$table_Exists = run_query $sql_Exists
$cur_Exists = $table_Exists[0]

if ($cur_Exists -eq 0){
    $sql_Insert = "
    INSERT INTO GlobalSurveyData..tbl_CurrencyConversion(
	    LastUpdateDate,
	    CurrencyCode,
	    ConvertDate,
	    ConvertFromValue,
	    ConvertToValue)
    SELECT GETDATE(),
        '{0}',
        CONVERT(varchar(10),DATEADD(DAY,-DAY(getdate())+1,GETDATE()),120),
        {1},
        {2} " -f $tcur,$result_reverse[0],$result[0]

    $table_Currency = run_update $sql_Insert
}


