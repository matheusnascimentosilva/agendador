# Caminho do script de lembrete
$scriptPath = "G:\MEUS PROJETOS\Agendador\LembreteFaturas.ps1"

# Criar pasta se não existir
if (-not (Test-Path "C:\Lembretes")) {
    New-Item -ItemType Directory -Path "C:\Lembretes" | Out-Null
}

# Criar o script de lembrete (se ainda não existir)
if (-not (Test-Path $scriptPath)) {
    @'
param (
    [string]$mensagem = "🚨 Lembrete de pagamento!",
    [string]$titulo = "Fatura"
)

Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show($mensagem, $titulo)
'@ | Out-File -FilePath $scriptPath -Encoding UTF8
}

Write-Host "✅ Script de lembrete criado em $scriptPath"

# Lista de faturas
$faturas = @(
    @{ Nome = "Servidor Double"; Dia = 17; Hora = "09:00"; Mensagem = "🚨 Pagar Servidor Double!" },
    @{ Nome = "Servidor Email"; Dia = 1; Hora = "09:00"; Mensagem = "🚨 Pagar Servidor Email!" },
    @{ Nome = "Servidor Liberty"; Dia = 7; Hora = "09:00"; Mensagem = "🚨 Pagar Servidor Liberty!" },
    @{ Nome = "Servidor Euro"; Dia = 12; Hora = "09:00"; Mensagem = "🚨 Pagar Servidor Euro!" }
)

# Criar as tarefas recorrentes
foreach ($fatura in $faturas) {
    $taskName = "Lembrete " + $fatura.Nome
    $descricao = "Lembrete mensal para pagar " + $fatura.Nome

    $horaSplit = $fatura.Hora.Split(":")
    $acao = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$scriptPath`" -mensagem `"$($fatura.Mensagem)`" -titulo 'Lembrete'"

    # Gatilho: primeira execução no próximo mês
    $dataInicial = Get-Date -Day $fatura.Dia -Hour $horaSplit[0] -Minute $horaSplit[1] -Second 0

    # Se a data inicial já passou neste mês, pula para o próximo
    if ($dataInicial -lt (Get-Date)) {
        $dataInicial = $dataInicial.AddMonths(1)
    }

    $gatilho = New-ScheduledTaskTrigger -Once -At $dataInicial

    # Configuração para repetir todo mês
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    try {
        Register-ScheduledTask -Action $acao -Trigger $gatilho -TaskName $taskName -Description $descricao -Settings $settings -Force | Out-Null
        Write-Host "✅ Tarefa criada: $taskName (dia $($fatura.Dia) às $($fatura.Hora))"
    }
    catch {
        Write-Host "⚠️ Erro ao criar tarefa: $taskName"
    }
}

Write-Host "`n🎉 Todas as tarefas foram configuradas com sucesso!"
