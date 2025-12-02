# AWS CloudFormation Deployment Script for Windows
# This script helps deploy the e-commerce microservices to AWS

param(
    [Parameter(Mandatory=$true)]
    [string]$KeyName,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubRepoUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$StackName = "ecommerce-app",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

Write-Host "[*] Starting AWS CloudFormation Deployment..." -ForegroundColor Cyan

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>&1
    Write-Host "[OK] AWS CLI found: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "[X] AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    Write-Host "    Download from: https://awscli.amazonaws.com/AWSCLIV2.msi" -ForegroundColor Yellow
    exit 1
}

# Fetch latest AMI ID
Write-Host "[*] Fetching latest Amazon Linux 2023 AMI ID..." -ForegroundColor Cyan
$amiId = ""

# Try SSM Parameter Store first
$ssmOutput = aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 --region $Region --query 'Parameter.Value' --output text 2>&1
if ($LASTEXITCODE -eq 0 -and $ssmOutput -and $ssmOutput -notmatch "AccessDenied|error|Error") {
    $amiId = $ssmOutput.Trim()
    Write-Host "[OK] Found AMI ID via SSM: $amiId" -ForegroundColor Green
} else {
    Write-Host "[!] SSM access denied or unavailable. Trying alternative method..." -ForegroundColor Yellow
    
    # Try EC2 describe-images as alternative (uses ec2:DescribeImages permission)
    $ec2Output = aws ec2 describe-images --region $Region --owners amazon --filters "Name=name,Values=al2023-ami-*-kernel-6.1-x86_64" "Name=state,Values=available" --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text 2>&1
    if ($LASTEXITCODE -eq 0 -and $ec2Output -and $ec2Output -notmatch "AccessDenied|error|Error") {
        $amiId = $ec2Output.Trim()
        Write-Host "[OK] Found AMI ID via EC2: $amiId" -ForegroundColor Green
    } else {
        Write-Host "[!] Could not automatically fetch AMI ID (insufficient permissions)." -ForegroundColor Yellow
        Write-Host "    You'll need to provide the AMI ID manually." -ForegroundColor Yellow
    }
}

# If AMI ID not found, prompt for it
if ([string]::IsNullOrWhiteSpace($amiId)) {
    Write-Host ""
    Write-Host "To find the latest Amazon Linux 2023 AMI ID:" -ForegroundColor Cyan
    Write-Host "  1. Go to EC2 Console > Launch Instance > Amazon Linux 2023" -ForegroundColor White
    Write-Host "  2. Or use AWS Console with a user that has SSM permissions" -ForegroundColor White
    Write-Host "  3. Or ask your AWS administrator for the AMI ID" -ForegroundColor White
    Write-Host ""
    $amiId = Read-Host "Enter Amazon Linux 2023 AMI ID (required)"
    if ([string]::IsNullOrWhiteSpace($amiId)) {
        Write-Host "[X] AMI ID is required. Deployment cancelled." -ForegroundColor Red
        exit 1
    }
}

# Generate App Key
Write-Host "[*] Generating application key..." -ForegroundColor Cyan
$appKey = openssl rand -base64 32
if (-not $appKey) {
    Write-Host "[X] Failed to generate app key. Make sure OpenSSL is installed." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] App key generated" -ForegroundColor Green

# Prompt for passwords
Write-Host "[*] Please enter database passwords:" -ForegroundColor Cyan
$mysqlRootPassword = Read-Host "MySQL Root Password (min 8 characters)" -AsSecureString
$mysqlAppPassword = Read-Host "MySQL App User Password (min 8 characters)" -AsSecureString

# Convert secure strings to plain text
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($mysqlRootPassword)
$mysqlRootPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($mysqlAppPassword)
$mysqlAppPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Prompt for SES credentials (optional)
Write-Host "[*] AWS SES Configuration (optional - can use placeholder):" -ForegroundColor Cyan
$sesUsername = Read-Host "SES SMTP Username (or 'placeholder')"
$sesPassword = Read-Host "SES SMTP Password (or 'placeholder')" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sesPassword)
$sesPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

if ([string]::IsNullOrWhiteSpace($sesUsername)) {
    $sesUsername = "placeholder"
}
if ([string]::IsNullOrWhiteSpace($sesPasswordPlain)) {
    $sesPasswordPlain = "placeholder"
}

# Deploy with CloudFormation
Write-Host "[*] Deploying stack '$StackName' to region '$Region'..." -ForegroundColor Cyan
Write-Host "    This will take 5-10 minutes..." -ForegroundColor Yellow

$deployCommand = @(
    "cloudformation", "create-stack",
    "--stack-name", $StackName,
    "--template-body", "file://infrastructure/cloudformation.yml",
    "--parameters",
    "ParameterKey=KeyName,ParameterValue=$KeyName",
    "ParameterKey=LatestAmiId,ParameterValue=$amiId",
    "ParameterKey=GitHubRepoUrl,ParameterValue=$GitHubRepoUrl",
    "ParameterKey=AppKey,ParameterValue=$appKey",
    "ParameterKey=MySQLRootPassword,ParameterValue=$mysqlRootPasswordPlain",
    "ParameterKey=MySQLAppPassword,ParameterValue=$mysqlAppPasswordPlain",
    "ParameterKey=SESUsername,ParameterValue=$sesUsername",
    "ParameterKey=SESPassword,ParameterValue=$sesPasswordPlain",
    "--capabilities", "CAPABILITY_NAMED_IAM",
    "--region", $Region
)

try {
    aws @deployCommand
    Write-Host "[OK] Stack creation initiated!" -ForegroundColor Green
    Write-Host "[*] Waiting for stack to be created (this may take 5-10 minutes)..." -ForegroundColor Yellow
    
    # Wait for stack creation
    aws cloudformation wait stack-create-complete --stack-name $StackName --region $Region
    
    Write-Host "[OK] Stack created successfully!" -ForegroundColor Green
    
    # Get outputs
    Write-Host "`n[*] Retrieving deployment information..." -ForegroundColor Cyan
    $outputs = aws cloudformation describe-stacks --stack-name $StackName --region $Region --query "Stacks[0].Outputs" --output json | ConvertFrom-Json
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
    
    foreach ($output in $outputs) {
        if ($output.OutputKey -eq "WebsiteURL") {
            Write-Host "Live URL (IP): " -NoNewline -ForegroundColor Yellow
            Write-Host $output.OutputValue -ForegroundColor White
        }
        if ($output.OutputKey -eq "WebsiteURLDNS") {
            Write-Host "Live URL (DNS): " -NoNewline -ForegroundColor Yellow
            Write-Host $output.OutputValue -ForegroundColor White
        }
        if ($output.OutputKey -eq "PublicIP") {
            Write-Host "Public IP: " -NoNewline -ForegroundColor Yellow
            Write-Host $output.OutputValue -ForegroundColor White
        }
        if ($output.OutputKey -eq "PublicDNS") {
            Write-Host "Public DNS: " -NoNewline -ForegroundColor Yellow
            Write-Host $output.OutputValue -ForegroundColor White
        }
    }
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "Your application is now live!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
    
} catch {
    Write-Host "[X] Deployment failed!" -ForegroundColor Red
    Write-Host "    Error: $_" -ForegroundColor Red
    Write-Host "`n[*] To check stack status:" -ForegroundColor Yellow
    Write-Host "    aws cloudformation describe-stacks --stack-name $StackName --region $Region" -ForegroundColor White
    Write-Host "`n[*] To view stack events:" -ForegroundColor Yellow
    Write-Host "    aws cloudformation describe-stack-events --stack-name $StackName --region $Region" -ForegroundColor White
    exit 1
}

