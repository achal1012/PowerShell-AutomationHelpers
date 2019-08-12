if (Get-Module -ListAvailable -Name Az.WebSites) {
    echo 'Az Module exists! No installation is required.'
} 
else {
    echo 'Installing Az modules..'
    Install-Module -Name Az -AllowClobber -Scope AllUsers
}

Connect-AzAccount

$actionStartStop = Read-Host -Prompt 'Input Action: (start/stop)'
$actionStartStop = $actionStartStop.ToLower()
if ($actionStartStop -ne 'start' -and $actionStartStop -ne 'stop') {
    echo "Not a valid action! Please retry."; exit
} 

$azCommand = $actionStartStop +"-AzWebApp"

$subscriptionId = Read-Host -Prompt 'Input subscriptionId:(Copy from Azure portal)'
$subscriptionId = $subscriptionId -replace '\s+', ''

try	{Set-AzContext -SubscriptionId $subscriptionId -ErrorAction Stop}
catch	{echo 'Check your account access on the subscription or check subscriptionId'; exit }

$resourceGroupName = Read-Host -Prompt 'Input resource group name'
$resourceGroupName = $resourceGroupName -replace '\s+', ''

function Read-MultiLineInputBoxDialog([string]$Message, [string]$WindowTitle, [string]$DefaultText)
{
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
 
    # Create the Label.
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Size(10,10) 
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.AutoSize = $true
    $label.Text = $Message
 
    # Create the TextBox used to capture the user's text.
    $textBox = New-Object System.Windows.Forms.TextBox 
    $textBox.Location = New-Object System.Drawing.Size(10,40) 
    $textBox.Size = New-Object System.Drawing.Size(575,200)
    $textBox.AcceptsReturn = $true
    $textBox.AcceptsTab = $false
    $textBox.Multiline = $true
    $textBox.ScrollBars = 'Both'
    $textBox.Text = $DefaultText
 
    # Create the OK button.
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Size(415,250)
    $okButton.Size = New-Object System.Drawing.Size(75,25)
    $okButton.Text = "OK"
    $okButton.Add_Click({ $form.Tag = $textBox.Text; $form.Close() })
 
    # Create the Cancel button.
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Size(510,250)
    $cancelButton.Size = New-Object System.Drawing.Size(75,25)
    $cancelButton.Text = "Cancel"
    $cancelButton.Add_Click({ $form.Tag = $null; $form.Close() })
 
    # Create the form.
    $form = New-Object System.Windows.Forms.Form 
    $form.Text = $WindowTitle
    $form.Size = New-Object System.Drawing.Size(610,320)
    $form.FormBorderStyle = 'FixedSingle'
    $form.StartPosition = "CenterScreen"
    $form.AutoSizeMode = 'GrowAndShrink'
    $form.Topmost = $True
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
    $form.ShowInTaskbar = $true
 
    # Add all of the controls to the form.
    $form.Controls.Add($label)
    $form.Controls.Add($textBox)
    $form.Controls.Add($okButton)
    $form.Controls.Add($cancelButton)
 
    # Initialize and show the form.
    $form.Add_Shown({$form.Activate()})
    $form.ShowDialog() > $null   # Trash the text of the button that was clicked.
 
    # Return the text that the user entered.
    return $form.Tag
}

$multiLineText = Read-MultiLineInputBoxDialog -Message "List Azure functions here delimited with semicolon" -WindowTitle "User input for AzureFunctions" -DefaultText "example funcName1;funcName2;funcName3"
if ($multiLineText -eq $null) 
	{ Write-Host "You clicked Cancel"; exit  }
else 
	{ Write-Host "You entered the following text: $multiLineText" }


$($multiLineText -replace '\s+', '').Split(";") | 
foreach {  $currState = Get-AzWebApp -Name $_ | select -ExpandProperty State; 
			If ($currState -eq 'Running' -and $actionStartStop -eq 'stop') {"Stopping the App $_"; & $azCommand -ResourceGroupName $resourceGroupName -Name $_;} 
			elseif($currState -eq 'Stopped' -and $actionStartStop -eq 'start') {"Starting the app $_"; & $azCommand -ResourceGroupName $resourceGroupName -Name $_;} 
			else {'Doing nothing for app $_'}  }
