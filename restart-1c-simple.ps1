param([string]$programm_name="nul")
Try{
    $servername=$env:computername
    $zabbixhost="zabbix.example.com"
    $zabbix_key=$programm_name+".restart"
    switch ($programm_name)
    {
        "kassy" 
        {
            $window_name="1С:Предприятие - Астор: Обмен с кассами"
            $schedule_name="Запуск обмена с кассами"
        }
        "scales" 
        {
            $window_name="1С:Предприятие - Астор: Выгрузка на весы"
            $schedule_name="Запуск обмена с весами"
        }
        "exchange" 
        {
            $window_name="1С:Предприятие - Астор: Обмен данными"
            $schedule_name="Обмен"
        }
        default {
            throw "No param"
        }
    }

    ################### Прибиваем процессы, запускаем другие ###################
    schtasks /end /TN $schedule_name
    Sleep 10;
    Get-Process | Where-Object {$_.MainWindowTitle -eq $window_name} | Stop-Process -Force
    Sleep 10;
    schtasks /run /TN $schedule_name
    if ($LastExitCode -ne 0){
        throw "LastExitCode -ne 0"
    }

    #Send to Zabbix
    $get_str1="https://$zabbixhost/zabbix_sender/index.php?server=$servername&key=$zabbix_key$vm_name&value=100"
    $wc = New-Object system.Net.WebClient;
    $Result = $wc.downloadString("$get_str1")
} Catch 
{
        #Send to Zabbix Error
    $get_str2="https://$zabbixhost/zabbix_sender/index.php?server=$servername&key=$zabbix_key$vm_name&value=2"
    $wc = New-Object system.Net.WebClient;
    $Result = $wc.downloadString("$get_str2")
}
