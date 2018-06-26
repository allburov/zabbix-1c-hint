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
            $disconnect_param="@ОбменСКассами"
        }
        "scales" 
        {
            $window_name="1С:Предприятие - Астор: Выгрузка на весы"
            $schedule_name="Запуск обмена с весами"
            $disconnect_param="@ОбменСВесами"
        }
        "exchange" 
        {
            $window_name="1С:Предприятие - Астор: Обмен данными"
            $schedule_name="Обмен"
            $disconnect_param="@Обмен;@ОбменEDI"
        }
        "operativnyeostatki"
        {
            $window_name="1С:Предприятие - Астор: Оперативные остатки"
            $schedule_name="run-1C-Operativnye-ostatki"    
            $disconnect_param="@ОперативныеОстатки"
        }
        default {
            throw "No param"
        }
    }
    ################### Инициализируем параметры ###################
    ####Получаем строку подключения к базе
    $xml = SCHTASKS /Query /xml /TN Обмен
    
    if ($xml[-15] -like "*td*"){
        $arguments=$xml[98]
    } elseif ($xml[-7] -like "*td*"){
        $arguments=$xml[-7]
    } else {
        throw "No connection string"
    }
    $arguments=$arguments.replace('<Arguments>ENTERPRISE /S ',"")
    $arguments=$arguments.replace('/DisableStartupMessages /N "Обмен данными" /P "55555" /C "Auto_Exchange"</Arguments>',"")
    $arguments=$arguments.replace('/DisableStartupMessages /N "ОбменДанными" /P "55555" /C "Auto_Exchange"</Arguments>',"")
    $arguments=$arguments.replace('/DisableStartupMessages /N "Обмен" /P "55555" /C "Auto_Exchange"</Arguments>',"")
    $arguments=$arguments.replace('/DisableStartupMessages /N "Обмен данными" /P "55555" /C "Auto_Exchange___Full"</Arguments>',"")
    $arguments=$arguments.replace('"','')
    $arguments=$arguments.replace(' ','')
    $path_db=$arguments
    

    $1c_disconnect_path="C:\Program Files (x86)\1cv81\bin\1cv8.exe"
    $1c_disconnect_param="ENTERPRISE /S ""$path_db"" /DisableStartupMessages /N ""Обмен данными"" /P ""55555"" /C ""RUN%ОтключениеПользователей;@zabbix;$disconnect_param"""
    

    ################### Прибиваем процессы, запускаем другие ###################
    schtasks /end /TN $schedule_name
    Sleep 10;
    Get-Process | Where-Object {$_.MainWindowTitle -eq $window_name} | Stop-Process -Force
    Sleep 5;
        #Invoke-expression ". $1c_disconnect_path$1c_disconnect_param" #Выбивать сеанс пользователя из 1С-сервера через обработку 1С
    start-process $1c_disconnect_path $1c_disconnect_param -wait
    Sleep 5;
    schtasks /run /TN $schedule_name
    if ($LastExitCode -ne 0){
        throw "LastExitCode -ne 0"
    }

    ################### Send to Zabbix ###################
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



