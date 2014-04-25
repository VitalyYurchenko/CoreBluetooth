//
//  VYPeripheralController.m
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/14/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

#import "VYPeripheralController.h"

#import "VYConstants.h"

#import "VYMessage.h"
#import "VYMessageChunk.h"

@interface VYPeripheralController ()

@property (nonatomic) CBMutableService *dataTransferService;
@property (nonatomic) CBMutableCharacteristic *dataRequestCharacteristic;
@property (nonatomic) CBMutableCharacteristic *dataResponseCharacteristic;

@property (nonatomic) VYMutableMessage *requestMessage;
@property (nonatomic) VYMutableMessage *responseMessage;

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
        case CBPeripheralManagerStateResetting:
        case CBPeripheralManagerStateUnsupported:
        case CBPeripheralManagerStateUnauthorized:
        {
            [self deinitializeServices];
            
            break;
        }
        case CBPeripheralManagerStatePoweredOff:
        {
            break;
        }
        case CBPeripheralManagerStatePoweredOn:
        {
            if (![self isServicesInitialized] && [self initializeServices])
            {
                [peripheral addService:self.dataTransferService];
            }
            
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
        if ([service isEqual:self.dataTransferService])
        {
            NSDictionary *advertisementData = @{CBAdvertisementDataLocalNameKey: @"CoreBluetoothPeripheral",
                                                CBAdvertisementDataServiceUUIDsKey: @[service.UUID]};
            
            [peripheral startAdvertising:advertisementData];
        }
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"Info: CBPeripheralManager did recieve read request: %@", request);
    
    CBATTError result = CBATTErrorSuccess;
    
    // Handle data response characteristic read request.
    if ([request.characteristic.UUID isEqual:self.dataResponseCharacteristic.UUID])
    {
        if (request.offset == 0)
        {
            request.value = [self.responseMessage firstChunk].data;
        }
        else
        {
            result = CBATTErrorInvalidOffset;
        }
    }
    
    [peripheral respondToRequest:request withResult:result];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    NSLog(@"Info: CBPeripheralManager did recieve write requests: %@", requests);
    
    CBATTRequest *firstRequest = [requests firstObject];
    CBATTError result = CBATTErrorSuccess;
    
    // Handle data request characteristic write request.
    if ([firstRequest.characteristic.UUID isEqual:self.dataRequestCharacteristic.UUID])
    {
        NSMutableData *data = nil;
        
        for (CBATTRequest *request in requests)
        {
            if (request.offset == 0)
            {
                data = [NSMutableData dataWithData:request.value];
            }
            else if (request.offset == [data length])
            {
                [data appendData:request.value];
            }
            else
            {
                data = nil;
                result = CBATTErrorInvalidOffset;
                
                break;
            }
        }
        
        if (data != nil)
        {
            VYMessageChunk *chunk = [VYMessageChunk messageChunkWithData:data];
            
            if ([chunk isFirst])
            {
                self.requestMessage = [VYMutableMessage messageWithChunk:chunk];
                self.responseMessage = nil;
            }
            else
            {
                [self.requestMessage addChunk:chunk];
            }
            
            if ([chunk isLast])
            {
                self.responseMessage = [self.requestMessage.data isEqualToData:[kVYSampleText dataUsingEncoding:NSUTF8StringEncoding]]
                ? [VYMutableMessage messageWithData:[@"Status Code: 200" dataUsingEncoding:NSUTF8StringEncoding]]
                : [VYMutableMessage messageWithData:[@"Status Code: 400" dataUsingEncoding:NSUTF8StringEncoding]];
                self.requestMessage = nil;
            }
        }
        else
        {
            self.requestMessage = nil;
            self.responseMessage = nil;
        }
    }
    
    [peripheral respondToRequest:firstRequest withResult:result];
}

#pragma mark -
#pragma mark Working With Services

- (BOOL)initializeServices
{
    // Initialize a characteristics.
    self.dataRequestCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kVYPeripheralDataRequestCharacteristicUUID]
                                                                        properties:CBCharacteristicPropertyWrite
                                                                             value:nil
                                                                       permissions:CBAttributePermissionsWriteable];
    self.dataResponseCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kVYPeripheralDataResponseCharacteristicUUID]
                                                                     properties:CBCharacteristicPropertyRead
                                                                          value:nil
                                                                    permissions:CBAttributePermissionsReadable];
    
    // Initialize a service.
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kVYPeripheralDataTransferServiceUUID];
    
    self.dataTransferService = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
    self.dataTransferService.characteristics = @[self.dataResponseCharacteristic, self.dataRequestCharacteristic];
    
    return self.dataTransferService != nil;
}

- (void)deinitializeServices
{
    self.dataResponseCharacteristic = nil;
    self.dataRequestCharacteristic = nil;
    self.dataTransferService = nil;
}

- (BOOL)isServicesInitialized
{
    return self.dataTransferService != nil;
}

@end
