//
//  VYCentralManager.m
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/14/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

#import "VYCentralManager.h"

#import "VYConstants.h"

#import "VYPeripheral.h"

@implementation VYCentralManager

#pragma mark -
#pragma mark Singleton

+ (instancetype)sharedManager
{
    static VYCentralManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(void)
    {
        if (sharedManager == nil)
        {
            sharedManager = [[super allocWithZone:NULL] init];
        }
    });
    
    return sharedManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedManager];
}

#pragma mark -
#pragma mark Object Lifecycle

- (id)init
{
    self = [super init];
    
    if (self != nil)
    {
        dispatch_queue_t queue = dispatch_queue_create("VYCentralManagerQueue", DISPATCH_QUEUE_SERIAL);
        NSDictionary *options = @{CBCentralManagerOptionShowPowerAlertKey: @YES,
                                  CBCentralManagerOptionRestoreIdentifierKey: @""};
        
        _CBCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:queue options:options];
        
        _peripherals = [NSMutableDictionary dictionary];
    }
    
    return self;
}

#pragma mark -
#pragma mark Methods

- (void)scanForPeripherals
{
    if (self.CBCentralManager.state == CBCentralManagerStatePoweredOn)
    {
        dispatch_sync(dispatch_get_main_queue(), ^(void) { [self willChangeValueForKey:@"peripherals"]; });
        [self.peripherals removeAllObjects];
        dispatch_sync(dispatch_get_main_queue(), ^(void) { [self didChangeValueForKey:@"peripherals"]; });
        
        NSArray *serviceUUIDs = @[[CBUUID UUIDWithString:kVYPeripheralDataTransferServiceUUID]];
        NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey: @YES,
                                  CBCentralManagerScanOptionSolicitedServiceUUIDsKey: @[]};
        
        [self.CBCentralManager scanForPeripheralsWithServices:serviceUUIDs options:options];
    }
}

- (void)stopScanForPeripherals
{
    if (self.CBCentralManager.state == CBCentralManagerStatePoweredOn)
    {
        [self.CBCentralManager stopScan];
    }
}

- (void)connectPeripheral:(VYPeripheral *)peripheral
{
    CBPeripheral *cbPeripheral = peripheral.CBPeripheral;
    
    if ((cbPeripheral != nil) &&
        (cbPeripheral.state == CBPeripheralStateDisconnected))
    {
        NSDictionary *options = @{CBConnectPeripheralOptionNotifyOnConnectionKey: @YES,
                                  CBConnectPeripheralOptionNotifyOnDisconnectionKey: @YES,
                                  CBConnectPeripheralOptionNotifyOnNotificationKey: @YES};
        [self.CBCentralManager connectPeripheral:cbPeripheral options:options];
    }
}

- (void)disconnectPeripheral:(VYPeripheral *)peripheral
{
    CBPeripheral *cbPeripheral = peripheral.CBPeripheral;
    
    if ((cbPeripheral != nil) &&
        (cbPeripheral.state == CBPeripheralStateConnecting ||
         cbPeripheral.state == CBPeripheralStateConnected))
    {
        [self.CBCentralManager cancelPeripheralConnection:cbPeripheral];
    }
}

#pragma mark -
#pragma mark <CBCentralManagerDelegate>

- (void)centralManagerDidUpdateState:(CBCentralManager *)cbCentral
{
    NSLog(@"Info: CBCentralManager did update state: %ld", (long)cbCentral.state);
    
    switch (cbCentral.state)
    {
        case CBCentralManagerStateUnknown:
        case CBCentralManagerStateResetting:
        case CBCentralManagerStateUnsupported:
        case CBCentralManagerStateUnauthorized:
        {
            dispatch_sync(dispatch_get_main_queue(), ^(void) { [self willChangeValueForKey:@"peripherals"]; });
            [self.peripherals removeAllObjects];
            dispatch_sync(dispatch_get_main_queue(), ^(void) { [self didChangeValueForKey:@"peripherals"]; });
            
            break;
        }
        case CBCentralManagerStatePoweredOff:
        {
            break;
        }
        case CBCentralManagerStatePoweredOn:
        {
            [self scanForPeripherals];
            
            break;
        }
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)cbCentral willRestoreState:(NSDictionary *)dict
{
    NSLog(@"Info: CBCentralManager will restore state: %@", dict);
}

- (void)centralManager:(CBCentralManager *)cbCentral
 didDiscoverPeripheral:(CBPeripheral *)cbPeripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSLog(@"Info: CBCentralManager did discover peripheral: %@", cbPeripheral);
    
    VYPeripheral *peripheral = self.peripherals[cbPeripheral.identifier];
    
    if (peripheral == nil)
    {
        peripheral = [VYPeripheral peripheralWithCBPeripheral:cbPeripheral];
        
        dispatch_sync(dispatch_get_main_queue(), ^(void) { [self willChangeValueForKey:@"peripherals"]; });
        self.peripherals[peripheral.CBPeripheral.identifier] = peripheral;
        dispatch_sync(dispatch_get_main_queue(), ^(void) { [self didChangeValueForKey:@"peripherals"]; });
        
        // Vitaly.Yurchenko: TMP.
        [self connectPeripheral:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)cbCentral didConnectPeripheral:(CBPeripheral *)cbPeripheral
{
    NSLog(@"Info: CBCentralManager did connect peripheral: %@", cbPeripheral);
    
    VYPeripheral *peripheral = self.peripherals[cbPeripheral.identifier];
    [peripheral didConnect];
}

- (void)centralManager:(CBCentralManager *)cbCentral didFailToConnectPeripheral:(CBPeripheral *)cbPeripheral error:(NSError *)error
{
    NSLog(@"Error: CBCentralManager did fail connect peripheral: %@; Error: %@", cbPeripheral, error);
    
    VYPeripheral *peripheral = self.peripherals[cbPeripheral.identifier];
    [peripheral didFailToConnectWithError:error];
}

- (void)centralManager:(CBCentralManager *)cbCentral didDisconnectPeripheral:(CBPeripheral *)cbPeripheral error:(NSError *)error
{
    NSLog(@"Info: CBCentralManager did disconnect peripheral: %@; Error: %@", cbPeripheral, error);
    
    VYPeripheral *peripheral = self.peripherals[cbPeripheral.identifier];
    [peripheral didDisconnectWithError:error];
}

@end
