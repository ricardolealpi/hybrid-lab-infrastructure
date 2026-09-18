<#
.SYNOPSIS
    Configuración inicial de red e identidad para Windows Server 2022 Core.
.DESCRIPTION
    Asigna una dirección IP estática, máscara /24, puerta de enlace, servidor DNS local (loopback) 
    y renombra el equipo a DC01-SRV antes de reiniciar el sistema.
.NOTES
    Ruta en repo: scripts/01-windows-server/01-network-identity.ps1
#>

# 1. Definición de Variables de Configuración
$NewHostName    = "DC01-SRV"
$IPAddress      = "192.168.10.10"
$PrefixLength   = 24$DefaultGateway = "192.168.10.1"
$DNSServer      = "127.0.0.1" # Apunta a sí mismo para la futura instalación de AD DS / DNS

Write-Host "=== Iniciando Configuración Base de Red e Identidad ===" -ForegroundColor Cyan

# 2. Detección de la Interfaz de Red Activa
$NetAdapter = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1

if (-not $NetAdapter) {
    Write-Error "Error: No se encontró ningún adaptador de red activo. Verifica la interfaz en VMware."
    exit
}

Write-Host "Adaptador detectado: $($NetAdapter.Name) ($($NetAdapter.InterfaceDescription))" -ForegroundColor Yellow

# 3. Limpieza de IPs Previas y Asignación de IP Estática
Write-Host "Configurando IP Estática $IPAddress/$PrefixLength y Gateway$DefaultGateway..." -ForegroundColor Green

# Elimina direccionamiento IPv4 previo en la interfaz para evitar duplicados
Get-NetIPAddress -InterfaceAlias $NetAdapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
    Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

# Aplicación de nueva IP y Gateway
New-NetIPAddress -InterfaceAlias $NetAdapter.Name `
                 -IPAddress $IPAddress `
                 -PrefixLength $PrefixLength `
                 -DefaultGateway $DefaultGateway `
                 -AddressFamily IPv4 | Out-Null

# 4. Configuración del Servidor DNS
Write-Host "Asignando Servidor DNS Primario ($DNSServer)..." -ForegroundColor Green
Set-DnsClientServerAddress -InterfaceAlias $NetAdapter.Name -ServerAddresses$DNSServer

# 5. Cambio de Nombre de Host y Reinicio
$CurrentHostname =$env:COMPUTERNAME

if ($CurrentHostname -ne$NewHostName) {
    Write-Host "Cambiando Nombre de Equipo: '$CurrentHostname' -> '$NewHostName'..." -ForegroundColor Green
    Rename-Computer -NewName $NewHostName -Force
    
    Write-Host "Reinicio requerido. El servidor se reiniciará en 5 segundos..." -ForegroundColor Red
    Start-Sleep -Seconds 5
    Restart-Computer
} else {
    Write-Host "El equipo ya tiene el nombre '$NewHostName'. No se requiere reinicio." -ForegroundColor Cyan
}