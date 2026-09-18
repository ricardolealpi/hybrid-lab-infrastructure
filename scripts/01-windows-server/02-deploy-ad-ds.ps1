<#
.SYNOPSIS
    Instalación de AD DS y Promoción del Bosque en Windows Server 2022 Core.
.DESCRIPTION
    Instala el rol de Active Directory Domain Services (AD DS) junto con sus herramientas 
    de administración y promueve el servidor a Controlador de Dominio del nuevo bosque 'hl.internal'.
.NOTES
    Ruta en repo: scripts/01-windows-server/02-deploy-ad-ds.ps1
#>

# 1. Definición de Variables de Dominio
$DomainName   = "hl.internal"
$NetBiosName  = "HL"
# Contraseña para el Modo de Restauración de Servicios de Directorio (DSRM)
$DSRMPassword = ConvertTo-SecureString "P@ssw0rd2026!" -AsPlainText -Force

Write-Host "=== 1/2. Instalando Rol AD-Domain-Services ===" -ForegroundColor Cyan
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Write-Host "=== 2/2. Promoviendo Servidor a Controlador de Dominio ($DomainName) ===" -ForegroundColor Cyan
Write-Host "El servidor se reiniciará automáticamente al finalizar..." -ForegroundColor Yellow

$ForestParams = @{
    DomainName                    = $DomainName
    DomainNetbiosName             = $NetBiosName
    InstallDns                    = $true
    SafeModeAdministratorPassword = $DSRMPassword
    Force                         = $true
}

Install-ADDSForest @ForestParams