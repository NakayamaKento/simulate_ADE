param location string = 'japaneast'
param username string = 'AzureAdmin'
param prefix string = 'golden'

@secure()
param password string

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: '${prefix}Vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.16.0.0/16'
        '172.17.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'mySubnet'
        properties: {
          addressPrefix: '172.16.0.0/16'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '172.17.0.0/24'
        }
      }
    ]
  }
}

resource nic1 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${prefix}Nic1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'myIpConfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAddress: '172.16.29.2'
        }
      }
    ]
  }
}

resource vm1 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: '${prefix}Vm1'
  location: location
  properties: {
    osProfile:{
      adminUsername: username
      adminPassword: password
      computerName: 'vm1'
    }
    hardwareProfile: {
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic1.id
        }
      ]
    }
  }
}

// Bastion
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: '${prefix}PublicIp'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: '${prefix}bastion'
    }
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-11-01' = {
  name: '${prefix}Bastion'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'myIpConfig'
        properties: {
          subnet: {
            id: vnet.properties.subnets[1].id
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

output vnetName string = vnet.name
output vm1Name string = vm1.name
