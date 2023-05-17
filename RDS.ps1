Add-WindowsFeature `
	-IncludeManagementTools `
	-Restart `
	–Name `
		RDS-Connection-Broker, `
		#RDS-Web-Access, `
		RDS-RD-Server

New-RDSessionDeployment `
	-SessionHost @("FQDN") `
	-ConnectionBroker "FQDN"

	
New-RDSessionCollection `
	-CollectionName "RDS"
	-SessionHost @("FQDN")
	-ConnectionBrokerHost @("FQDN")
	
