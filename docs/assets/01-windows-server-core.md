# Fase 1: Configuración Inicial de Red e Identidad en Windows Server 2022 Core

## 1. Objetivo
Establecer la configuración base de red e identidad del servidor de infraestructura local (`DC01-SRV`). Este nodo actuará como Controlador de Dominio principal y servidor DNS en las siguientes fases del laboratorio. La instalación se realiza sobre **Windows Server 2022 Standard Core** para optimizar el consumo de recursos de memoria en VMware y reducir la superficie de ataque del sistema operativo.

---

## 2. Prerrequisitos
* Máquina Virtual en VMware con Windows Server 2022 Standard Core instalado.
* Adaptador de red virtual asignado al segmento privado del laboratorio (`192.168.10.0/24`).
* Credenciales con privilegios de Administrador local.

---

## 3. Automatización (Script de PowerShell)

El siguiente script (`scripts/01-windows-server/01-network-identity.ps1`) automatiza la detección de la interfaz física, asignación de IP estática, servidor DNS local y renombrado del equipo.

```powershell
<#
.SYNOPSIS
    Configuración inicial de red e identidad para Windows Server 2022 Core.
.DESCRIPTION
    Asigna dirección IP estática, máscara /24, puerta de enlace, servidor DNS local (loopback) 
    y renombra el equipo a DC01-SRV antes de reiniciar el sistema.
#>

$NewHostName    = "DC01-SRV"
$IPAddress      = "192.168.10.10"
$PrefixLength   = 24$DefaultGateway = "192.168.10.1"
$DNSServer      = "127.0.0.1"

Write-Host "=== Iniciando Configuración Base de Red e Identidad ===" -ForegroundColor Cyan

# Detección de adaptador activo
$NetAdapter = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1

if (-not $NetAdapter) {
    Write-Error "Error: No se encontró ningún adaptador de red activo."
    exit
}

# Asignación de IP Estática
Get-NetIPAddress -InterfaceAlias $NetAdapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
    Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

New-NetIPAddress -InterfaceAlias $NetAdapter.Name `
                 -IPAddress $IPAddress `
                 -PrefixLength $PrefixLength `
                 -DefaultGateway $DefaultGateway `
                 -AddressFamily IPv4 | Out-Null

# Asignación de Servidor DNS
Set-DnsClientServerAddress -InterfaceAlias $NetAdapter.Name -ServerAddresses$DNSServer

# Aplicación de Hostname y Reinicio
if ($env:COMPUTERNAME -ne$NewHostName) {
    Rename-Computer -NewName $NewHostName -Force
    Start-Sleep -Seconds 5
    Restart-Computer
}

## 7. Promoción a Controlador de Dominio (AD DS)

### Objetivo
Desplegar el rol de Active Directory Domain Services (AD DS) y promover `DC01-SRV` como el Controlador de Dominio principal del nuevo bosque `hl.internal`.

### Script de Automatización (`scripts/01-windows-server/02-deploy-ad-ds.ps1`)
El script instala la característica `AD-Domain-Services` junto con sus herramientas de gestión y ejecuta `Install-ADDSForest` mediante *splatting* para evitar errores de sintaxis en CLI.

```powershell
$DomainName   = "hl.internal"
$NetBiosName  = "HL"
$DSRMPassword = ConvertTo-SecureString "P@ssw0rd2026!" -AsPlainText -Force

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

$ForestParams = @{
    DomainName                    = $DomainName
    DomainNetbiosName             = $NetBiosName
    InstallDns                    = $true
    SafeModeAdministratorPassword = $DSRMPassword
    Force                         = $true
}

Install-ADDSForest @ForestParams