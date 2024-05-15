param location string = 'japaneast'

@maxLength(5)
param prefix string = 'simu'
param ImageVersion string = '333.0.0'

var CommonName = 'prefix${substring(uniqueString(resourceGroup().id), 0, 4)}'
var GoldenResourceGroup = 'simulate-rg'

// イメージのギャラリーID
var ComputeGalleryId = '${(resourceGroup().id)}/providers/Microsoft.Compute/galleries/simulate_acg/images/define01/versions/${ImageVersion}'

// イメージの確認
resource image 'Microsoft.Compute/galleries/images/versions@2023-07-03' existing = {
  name: ImageVersion
  scope: resourceGroup(GoldenResourceGroup)
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: '${CommonName}Vnet'
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
  name: '${CommonName}Nic1'
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

resource vm1 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: '${CommonName}Vm1'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        id: ComputeGalleryId
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
  name: '${CommonName}Pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: '${CommonName}bastion'
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

output vnetName string = vnet.id
output vm1Name string = vm1.name
output image string= image.name
