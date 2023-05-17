# https://efsol.ru/manuals/web-iis.html 
# +
# https://infostart.ru/1c/articles/275820/
#
# TODO make normal functions, clear code, 
########################################################################
# install IIS Roles and features
########################################################################

Install-WindowsFeature `
    -Name   Web-Server, `
    # Общие функции HTTP (Common HTTP Features)
            Web-Common-Http, ` 
            # Статическое содержимое (Static Content)
            Web-Static-Content, `
            # Документ по умолчанию (Default Document)
            Web-Default-Doc, `
            # Обзор каталогов (Directory Browsing)
            Web-Dir-Browsing, `
            # Ошибки HTTP (HTTP Errors)
    # Разработка приложений (Application Development)
            Web-App-Dev, `
            # ASP
            Web-ASP, `
            # ASP.NET 3.5
            Web-Asp-Net, `
            # Расширяемость .NET 3.5 (.NET Extensibility 3.5)
            Web-Net-Ext, `
            # Расширения ISAPI (ISAPI Extensions)
            Web-ISAPI-Ext, `
            # Фильтры ISAPI (ISAPI Filters)
            Web-ISAPI-Filter, `
    # Исправление и диагностика (Health and Diagnostics)
            Web-Health, `
            # Ведение журнала HTTP (HTTP Logging)
            Web-Http-Logging, `
            # Монитор запросов (Request Monitor)
            Web-Request-Monitor, `
    # Средства управления (Management Tools)
            #Web-Mgmt-Tools
            # Консоль управления IIS (IIS Management Console)
            Web-Mgmt-Console, `
            ## additional
            Web-Scripting-Tools, `
            Web-Mgmt-Service `
    -IncludeManagementTools

########################################################################
#  (RE)install 1c with web-server extention ??? assume 1c installed
########################################################################


########################################################################
# get 1c service data
########################################################################
# 1C:Enterprise 8.3 Server Agent (x86-64)
########################################################################

$srvc1c = Get-WmiObject win32_service `
          -Filter "name like '1C%'" |
          select Name, Status, Pathname, State, StartName
########################################################################
# full permission on c:\inetpub\wwwroot

# !!!!!!!!!!!

# ONLY IF 1C RUN FROM LOCAL USER, if domain need rewrite
########################################################################
$folder = "C:\inetpub\wwwroot" # need get folder path from iis
$acl = Get-Acl $folder

$srvc1c = Get-WmiObject win32_service `
          -Filter "name like '1C%'" |
          select Name, Status, Pathname, State, StartName
# 1C local user
$username=$srvc1c.StartName.Split('\')[1]
$user = New-Object System.Security.Principal.NTAccount($username) 
$sid = $user.Translate([System.Security.Principal.SecurityIdentifier]) 
$ace = [System.Security.AccessControl.FileSystemAccessRule]::new($sid,'FullControl','ContainerInherit, ObjectInherit','None','Allow')
$acl.AddAccessRule($ace)
Set-Acl -Path $folder -AclObject $acl





$srvc1c = Get-WmiObject win32_service `
          -Filter "name like '1C%'" |
          select Name, Status, Pathname, State, StartName

########################################################################
# full permission for IISUSRS on 1c install folder
# https://social.technet.microsoft.com/Forums/en-US/870fab41-439b-4f3a-ace4-cbfe4e41f789/powershell-setacl-use-without-changing-owner?forum=winserverpowershell
########################################################################
$installpath = $srvc1c.PathName.Split('"')[1]
$folder = (Get-Item (Split-path $installpath)).Parent.Parent
$1cfolder=$folder.FullName
$gacl = Get-Acl $1cfolder
$group = New-Object System.Security.Principal.NTAccount("iis_iusrs")
try
{
    $gsid = $group.translate([system.security.principal.securityidentifier])
}
catch
{
echo "Not a valid user"
}
if ($gsid -ne $null)
{
   $AccessRule = [System.Security.AccessControl.FileSystemAccessRule]::new($gsid,'FullControl','ContainerInherit, ObjectInherit','None','Allow')
   $gacl.AddAccessRule($AccessRule)
   Set-Acl -AclObject $gacl -Path $1cfolder
}


########################################################################
# publish 1c app
########################################################################

# publish
$PhysicalPath = "C:\inetpub\wwwroot\upp"


if (Test-Path $PhysicalPath) {
   
    Write-Host "Folder Exists"
    # Perform Delete file from folder operation
}
else
{
  
    #PowerShell Create directory if not exists
    New-Item $PhysicalPath -ItemType Directory
    Write-Host "Folder Created successfully"

}



# create web application
New-WebApplication -Name "1C" -Site "Default Web Site" -PhysicalPath $PhysicalPath -ApplicationPool "DefaultAppPool"
# add mime type for 1c
#https://serverfault.com/questions/554140/editing-setting-mime-types-with-powershell

########################################################################
# Добавляем настройки для обработки файлов 1С. 
# На вкладке Сопоставление обработчиков добавляем скрипты
# (не скрипты со звездочкой) для каждого расширения -"*.1cws" и "*.1crs".
########################################################################
Add-WebConfigurationProperty -PSPath (Get-WebApplication -Name "1C").PSpath -Filter "system.webServer/staticContent" -Name "." -Value @{ fileExtension='.1crs'; mimeType='text/xml' }
Add-WebConfigurationProperty -PSPath (Get-WebApplication -Name "1C").PSpath -Filter "system.webServer/staticContent" -Name "." -Value @{ fileExtension='.1cws'; mimeType='text/xml' }

#ADD SCRIPT MAP ?????????????
### 1c handler mappings /edit feature permissions add execute


########################################################################
#  
########################################################################

<# https://infostart.ru/1c/articles/275820/

Алексей Штейнварг
(alexstey)
Рейтинг: 417

сделано в повершелле
1) Установка IIS выполняется стандартными средствами. Набор достаточных компонент приведен на скриншоте.
2) Создаем папку на web сервере. В моем случае 1С.
4) Зададим права для обработчика web-сервисов 1С. Права на запуск (Выполнение) модулей добавляются для группы IIS_IUSRS на папку
C:\Program Files (x86)\1cv8\8.3.4.465\bin.
5) Если база файловая, нужно добавить права на изменение (Изменение) на папку и подпапки базы для той же группы.
6) В консоли IIS. Кликаем правой кнопкой мыши на строку с созданной нами папкой.  Преобразовываем её в приложение.


 
сделано частично, не знаю, пп 9, и задание ограничений из пп8
7) Добавляем MIME типы 1С. Делать это можно для сервера или для сайта, или для папки. Наследование присутствует.
8) Добавляем настройки для обработки файлов 1С. На вкладке Сопоставление обработчиков добавляем скрипты (не скрипты со звездочкой) для каждого расширения -"*.1cws" и "*.1crs".
Имена любые. Главное - для каждого расширение отдельное правило! Ограничения запроса -> Доступ -> Сценарий или Выполнение.
9) Для обработчиков нужно задать дополнительные параметры (Edit Feature Permission). Установить флаги запуска скриптов и приложений.
10) Можно проверить наличие обработчика web-сервисов 1С на вкладке ISAPI and CGI Restrictions для сервера.

 


11) Обращаемся по адресу http://localhost/1C/.
12) Об анонимной аутентификации на IIS и доступе к базе. Настроить доступ с использованием автоматически создаваемого пользователя IUSR у меня получилось. Важно проверить, что Анонимная проверка подлинности включена как в корне сервера, ТАК И НА САЙТЕ. Иначе не работает!!!!

3) Публикуем сервис из 1С. Администрирование -> 1С -> Конфигуратор  -> Администрирование  -> Публикация на Web-сервере. 

Все работает :)!


#>
