//
//  VYCentralController.m
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/14/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

#import "VYCentralController.h"

#import "VYConstants.h"

@interface VYCentralController ()

@property (nonatomic) CBPeripheral *peripheral;

@end

@implementation VYCentralController

#pragma mark -
#pragma mark Object Lifecycle

- (id)init
{
    self = [super init];
    
    if (self != nil)
    {
        dispatch_queue_t queue = NULL;
        NSDictionary *options = @{CBCentralManagerOptionShowPowerAlertKey: @YES,
                                  CBCentralManagerOptionRestoreIdentifierKey: @""};
        
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:queue options:options];
    }
    
    return self;
}

#pragma mark -
#pragma mark <CBCentralManagerDelegate>

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"Info: CBCentralManager did update state: %ld", (long)central.state);
    
    switch (central.state)
    {
        case CBCentralManagerStateUnknown:
        {
            break;
        }
        case CBCentralManagerStateResetting:
        {
            break;
        }
        case CBCentralManagerStateUnsupported:
        {
            break;
        }
        case CBCentralManagerStateUnauthorized:
        {
            break;
        }
        case CBCentralManagerStatePoweredOff:
        {
            break;
        }
        case CBCentralManagerStatePoweredOn:
        {
            NSArray *serviceUUIDs = @[[CBUUID UUIDWithString:kVYPeripheralMainServiceUUID]];
            NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey: @NO,
                                      CBCentralManagerScanOptionSolicitedServiceUUIDsKey: @[]};
            
            [central scanForPeripheralsWithServices:serviceUUIDs options:options];
            
            break;
        }
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
    NSLog(@"Info: CBCentralManager will restore state: %@", dict);
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Info: CBCentralManager did retrive peripherals: %@", peripherals);
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
    NSLog(@"Info: CBCentralManager did retrive connected peripherals: %@", peripherals);
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSLog(@"Info: CBCentralManager did discover peripheral: %@", peripheral);
    
    NSDictionary *options = @{CBConnectPeripheralOptionNotifyOnConnectionKey: @YES,
                              CBConnectPeripheralOptionNotifyOnDisconnectionKey: @YES,
                              CBConnectPeripheralOptionNotifyOnNotificationKey: @YES};
    
    [central stopScan];
    [central connectPeripheral:peripheral options:options];
    
    self.peripheral = peripheral;
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Info: CBCentralManager did connect peripheral: %@", peripheral);
    
    peripheral.delegate = self;
    
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Error: CBCentralManager did fail connect peripheral: %@; Error: %@", peripheral, error);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Info: CBCentralManager did disconnect peripheral: %@; Error: %@", peripheral, error);
    
    NSArray *serviceUUIDs = @[[CBUUID UUIDWithString:kVYPeripheralMainServiceUUID]];
    NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey: @NO,
                              CBCentralManagerScanOptionSolicitedServiceUUIDsKey: @[]};
    
    [central scanForPeripheralsWithServices:serviceUUIDs options:options];
}

#pragma mark -
#pragma mark <CBPeripheralDelegate>

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
    NSLog(@"Info: CBPeripheral did update name: %@", peripheral.name);
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices
{
    NSLog(@"Info: CBPeripheral did modify services: %@", invalidatedServices);
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services)
    {
        NSLog(@"Info: CBPeripheral did discover service: %@", service);
        
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kVYPeripheralMainServiceUUID]])
        {
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kVYPeripheralMainServiceCharacteristicUUID]] forService:service];
            [peripheral discoverIncludedServices:nil forService:service];
        }
    }
    
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:[CBUUID UUIDWithString:kVYPeripheralMainServiceUUID]])
    {
        for (CBService *includedService in service.includedServices)
        {
            NSLog(@"Info: CBPeripheral did discover included service: %@ for service: %@", includedService, service);
        }
    }
    
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:[CBUUID UUIDWithString:kVYPeripheralMainServiceUUID]])
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            NSLog(@"Info: CBPeripheral did discover characteristic: %@ for service: %@", characteristic, service);
            
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kVYPeripheralMainServiceCharacteristicUUID]])
            {
                if (characteristic.properties & CBCharacteristicPropertyRead)
                {
                    [peripheral readValueForCharacteristic:characteristic];
                }
                
                if (characteristic.properties & CBCharacteristicPropertyNotify)
                {
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
        }
    }
    
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kVYPeripheralMainServiceCharacteristicUUID]])
    {
        NSLog(@"Info: CBPeripheral did update value: %@ for: characteristic: %@", characteristic.value, characteristic);
        
        NSString *stringValue = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"Info: Value: %@", stringValue);
        
        if (characteristic.properties & CBCharacteristicPropertyWrite)
        {
            NSData *value = [@"Hello, World!!!" dataUsingEncoding:NSUTF8StringEncoding];
            [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }
    }
    
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    for (CBDescriptor *descriptor in characteristic.descriptors)
    {
        NSLog(@"Info: CBPeripheral did discover descriptor: %@ for characteristic: %@", descriptor, characteristic);
        
        [peripheral readValueForDescriptor:descriptor];
    }
    
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    NSLog(@"Info: CBPeripheral did update value: %@ for: descriptor: %@", descriptor.value, descriptor);
    
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
    }
}

@end
