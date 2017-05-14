
$PythonPath="C:\Python36\"
$certbot_path = "Lib\site-packages\certbot\"
$mainpy="main.py"
$crypto_util="crypto_util.py"
$cert_manager="cert_manager.py"
$account="account.py"
$util="util.py"
$storage="storage.py"
#log=log.py


function downloPythonInstallerPIPCert{

# Downloads prereqs - currently not error checking
#seeperate this from the install as the download is quite big (32MB)


$python_installer_url="https://www.python.org/ftp/python/3.6.0/python-3.6.0-amd64.exe"
$digicert_pip_intermediate_ca="https://www.digicert.com/CACerts/DigiCertHighAssuranceEVRootCA.crt"

Invoke-WebRequest -Uri $python_installer_url -OutFile $env:temp\python.exe
Invoke-WebRequest -Uri $digicert_pip_intermediate_ca -OutFile $env:temp\digicert_pip.crt
}

function installPythonPIPCert{

# ceritifcate is installed in the Trusted Root Store of the Local Machine
# info on python install paramaters: https://docs.python.org/3/using/windows.html

Import-Certificate -FilePath $env:temp\digicert_pip.crt -CertStoreLocation "Cert:\LocalMachine\Root"
Write-Host "Digicert Certificate for PyPi Installed Installed"

$cmd = "/passive InstallAllUsers=1 DefaultCustomTargetDir=""C:\Python36"" CompileAll=1 PrependPath=1"
Start-Process $env:temp\python.exe -ArgumentList $cmd -Wait
Write-Host "Python 3.6 Installed"

}

function installPIPVENV{

#https://pip.pypa.io/en/stable/installing/ pip docs
#virtual env docs: https://pypi.python.org/pypi/virtualenv/
#virtual environemnt manager https://virtualenvwrapper.readthedocs.io/en/latest/ 
# download pip install script. Run it in case python install does not install it

Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile $env:temp\get-pip.py 
Start-Process python.exe -ArgumentList $env:temp\get-pip.py  -Wait

$cmd = "install virtualenv"
Start-Process pip -ArgumentList $cmd  -Wait
Write-Host "Virtualenv Installed"

$cmd = "install virtualenvwrapper"
Start-Process pip -ArgumentList $cmd  -Wait
Write-Host "virtualenvwrapper Installed"
Write-Host ""
Write-Host "Installed Packages:"
pip freeze

}

function createVirtualCertbotEnvs($virtualenv,$version){

Start-Process virtualenv -ArgumentList $virtualenv  -Wait
Write-Host "Created Virtual Environment: "
}

function installCertbotInVENVS($virtualenv,$version){

Write-Host($virtualenv)
$certbot_cmd = "install certbot=="+$version
Write-Host($certbot_cmd)

$cmd = $virtualenv+"\Scripts\activate.ps1"
Write-Host($cmd)
Invoke-Expression $cmd
Start-Process pip -ArgumentList $certbot_cmd  -Wait
Write-Host "Insatlled Certbot $version In Virtual Environment: $virtualenv" 

}

function fixCertbotFiles($virtualenv){

#replace main.py - e.message with e and os.geteuid with '0'

$path = $virtualenv + $certbot_path + $mainpy
(Get-Content $path).replace('os.geteuid()', "'0'") | Set-Content $path
(Get-Content $path).replace('e.message', 'e') | Set-Content $path

#replace 3 other classes  os.geteuid with '0'

$path = $virtualenv + $certbot_path + $crypto_util
(Get-Content $path).replace('os.geteuid()', "'0'") | Set-Content $path
$path = $virtualenv + $certbot_path + $cert_manager
(Get-Content $path).replace('os.geteuid()', "'0'") | Set-Content $path
$path = $virtualenv + $certbot_path + $account
(Get-Content $path).replace('os.geteuid()', "'0'") | Set-Content $path
#log.py doesn't seem to exist anymore (14/05/2017). Left in cse it needs to be run
#$path = $virtualenv + $certbot_path + $log
#(Get-Content $path).replace('os.geteuid()', "'0'") | Set-Content $path


#new fixes (14/05/2017) Expand function wasn't working. New codebase has a tuple error
#https://github.com/certbot/certbot/issues/4510
#

$path = $virtualenv + $certbot_path + $util
(Get-Content $path).replace('configargparse.ACTION_TYPES_THAT_DONT_NEED_A_VALUE.add(ShowWarning)', "#configargparse.ACTION_TYPES_THAT_DONT_NEED_A_VALUE.add(ShowWarning)") | Set-Content $path

$path = $virtualenv + $certbot_path + $storage
(Get-Content $path).replace('os.rename', "os.replace") | Set-Content $path

Write-Host "Modified Certbot to Work with Windows in: $virtualenv" 

}

downloPythonInstallerPIPCert
installPythonPIPCert
installPIPVENV

createVirtualCertbotEnvs("$env:SystemDrive\Certbot-Production\")
createVirtualCertbotEnvs("$env:SystemDrive\Certbot-Staging\")
createVirtualCertbotEnvs("$env:SystemDrive\Certbot-Test\")

installCertbotInVENVS "$env:SystemDrive\Certbot-Production\" "0.13.0"
installCertbotInVENVS "$env:SystemDrive\Certbot-Staging\" "0.13.0"
installCertbotInVENVS "$env:SystemDrive\Certbot-Test\" "0.13.0"

fixCertbotFiles("$env:SystemDrive\Certbot-Production\")
fixCertbotFiles("$env:SystemDrive\Certbot-Staging\")
fixCertbotFiles("$env:SystemDrive\Certbot-Test\")
