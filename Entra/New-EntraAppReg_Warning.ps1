for (($i = 1); $i -lt 100000; $i++) {
    az ad app create --display-name AppTest$i
    Write-Output "AppTest$i"
    Start-Sleep -Seconds 1
}