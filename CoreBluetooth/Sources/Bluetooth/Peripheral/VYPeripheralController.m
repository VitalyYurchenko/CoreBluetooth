//
//  VYPeripheralController.m
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/14/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

#import "VYPeripheralController.h"

#import "VYConstants.h"

@interface VYPeripheralController ()

@property (nonatomic) CBMutableService *mainService;
@property (nonatomic) CBMutableCharacteristic *mainServiceCharacteristic;

@end

@implementation VYPeripheralController

#pragma mark -
#pragma mark Object Lifecycle

- (id)init
{
    self = [super init];
    
    if (self != nil)
    {
        // Initialize a peripheral manager.
        dispatch_queue_t queue = NULL;
        NSDictionary *options = @{CBPeripheralManagerOptionShowPowerAlertKey: @YES,
                                  CBPeripheralManagerOptionRestoreIdentifierKey: @""};
        
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:queue options:options];
        
        // Initialize a characteristic.
        CBUUID *characteristicUUID = [CBUUID UUIDWithString:kVYPeripheralMainServiceCharacteristicUUID];
        CBCharacteristicProperties properties = CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite | CBCharacteristicPropertyNotify;
        NSData *value = nil;
        CBAttributePermissions permissions = CBAttributePermissionsReadable | CBAttributePermissionsWriteable;
        
        _mainServiceCharacteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID
                                                                        properties:properties
                                                                             value:value
                                                                       permissions:permissions];
        
        // Initialize a service.
        CBUUID *serviceUUID = [CBUUID UUIDWithString:kVYPeripheralMainServiceUUID];
        
        _mainService = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
        _mainService.characteristics = @[_mainServiceCharacteristic];
    }

    return self;
}

#pragma mark -
#pragma mark <CBPeripheralManagerDelegate>

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"Info: CBPeripheralManager did update state: %ld", (long)peripheral.state);
    
    switch (peripheral.state)
    {
        case CBPeripheralManagerStateUnknown:
        {
            break;
        }
        case CBPeripheralManagerStateResetting:
        {
            break;
        }
        case CBPeripheralManagerStateUnsupported:
        {
            break;
        }
        case CBPeripheralManagerStateUnauthorized:
        {
            break;
        }
        case CBPeripheralManagerStatePoweredOff:
        {
            break;
        }
        case CBPeripheralManagerStatePoweredOn:
        {
            [peripheral addService:self.mainService];
            
            break;
        }
        default:
            break;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict
{
    
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
    }
    else
    {
        if ([service isEqual:self.mainService])
        {
            NSDictionary *advertisementData = @{CBAdvertisementDataLocalNameKey: @"CoreBluetoothPeripheral",
                                                CBAdvertisementDataServiceUUIDsKey: @[service.UUID]};
            
            [peripheral startAdvertising:advertisementData];
        }
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    if ([characteristic.UUID isEqual:self.mainServiceCharacteristic.UUID])
    {
        NSData *value = self.mainServiceCharacteristic.value != nil ? self.mainServiceCharacteristic.value : [NSData data];
        [peripheral updateValue:value forCharacteristic:self.mainServiceCharacteristic onSubscribedCentrals:nil];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"Info: CBPeripheralManager did recieve read request: %@", request);
    
    CBATTError result = CBATTErrorSuccess;
    
    if ([request.characteristic.UUID isEqual:self.mainServiceCharacteristic.UUID])
    {
        if (request.offset >= [self.mainServiceCharacteristic.value length])
        {
            result = CBATTErrorInvalidOffset;
        }
        else
        {
            NSRange range = NSMakeRange(request.offset, [self.mainServiceCharacteristic.value length] - request.offset);
            request.value = [self.mainServiceCharacteristic.value subdataWithRange:range];
        }
    }
    
    [peripheral respondToRequest:request withResult:result];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    NSLog(@"Info: CBPeripheralManager did recieve write requests: %@", requests);
    
    for (CBATTRequest *request in requests)
    {
        if ([request.characteristic.UUID isEqual:self.mainServiceCharacteristic.UUID])
        {
            if (request.offset == 0)
            {
                self.mainServiceCharacteristic.value = request.value;
                
                [peripheral respondToRequest:[requests firstObject] withResult:CBATTErrorSuccess];
                [peripheral updateValue:self.mainServiceCharacteristic.value forCharacteristic:self.mainServiceCharacteristic onSubscribedCentrals:nil];
            }
            else if (request.offset == [self.mainServiceCharacteristic.value length])
            {
                NSMutableData *mutableValue = [self.mainServiceCharacteristic.value mutableCopy];
                [mutableValue appendData:request.value];
                self.mainServiceCharacteristic.value = [mutableValue copy];
                
                [peripheral respondToRequest:[requests firstObject] withResult:CBATTErrorSuccess];
                [peripheral updateValue:self.mainServiceCharacteristic.value forCharacteristic:self.mainServiceCharacteristic onSubscribedCentrals:nil];
            }
            else
            {
                [peripheral respondToRequest:[requests firstObject] withResult:CBATTErrorInvalidOffset];
                break;
            }
        }
        else
        {
            break;
        }
    }
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    if ([self.mainServiceCharacteristic isNotifying])
    {
        [peripheral updateValue:self.mainServiceCharacteristic.value forCharacteristic:self.mainServiceCharacteristic onSubscribedCentrals:nil];
    }
}

@end
