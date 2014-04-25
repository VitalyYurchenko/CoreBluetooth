//
//  VYPeripheral.m
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/16/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

#import "VYPeripheral.h"

#import "VYConstants.h"

#import "VYDataTransferService.h"
#import "VYCharacteristic.h"

@interface VYPeripheral ()

@property (nonatomic, readonly) CBUUID *dataTransferServiceUUID;

@end

@implementation VYPeripheral

#pragma mark -
#pragma mark Object Lifecycle

+ (instancetype)peripheralWithCBPeripheral:(CBPeripheral *)cbPeripheral
{
    return [[self alloc] initWithCBPeripheral:cbPeripheral];
}

- (instancetype)init
{
    return [self initWithCBPeripheral:nil];
}

- (instancetype)initWithCBPeripheral:(CBPeripheral *)cbPeripheral
{
    self = [super init];
    
    if (self != nil)
    {
        NSParameterAssert(cbPeripheral != nil);
        
        if (cbPeripheral != nil)
        {
            _CBPeripheral = cbPeripheral;
            _CBPeripheral.delegate = self;
            
            _services = [NSMutableDictionary dictionary];
            
            _dataTransferServiceUUID = [CBUUID UUIDWithString:kVYPeripheralDataTransferServiceUUID];
            
            [_CBPeripheral addObserver:self forKeyPath:@"services" options:kNilOptions context:(__bridge void *)([self class])];
        }
        else
        {
            self = nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [_CBPeripheral removeObserver:self forKeyPath:@"services" context:(__bridge void *)([self class])];
}

#pragma mark -
#pragma mark Methods

- (void)sendRequestData:(NSData *)requestData completion:(void (^)(NSData *, NSError *))handler
{
    if ([self isConnected])
    {
        VYDataTransferService *service = self.services[self.dataTransferServiceUUID];
        [service sendRequestData:requestData completion:handler];
    }
    else if (handler != nil)
    {
        handler(nil, nil);
    }
}

- (BOOL)isConnected
{
    return self.CBPeripheral.state == CBPeripheralStateConnected;
}

#pragma mark -
#pragma mark Handling CBCentralManager Callbacks

- (void)didConnect
{
    NSParameterAssert(self.CBPeripheral.state == CBPeripheralStateConnected);
    
    [self.CBPeripheral discoverServices:@[self.dataTransferServiceUUID]];
}

- (void)didFailToConnectWithError:(NSError *)error
{
    NSParameterAssert(self.CBPeripheral.state == CBPeripheralStateDisconnected);
}

- (void)didDisconnectWithError:(NSError *)error
{
    NSParameterAssert(self.CBPeripheral.state == CBPeripheralStateDisconnected);
}

#pragma mark -
#pragma mark <CBPeripheralDelegate>

- (void)peripheralDidUpdateName:(CBPeripheral *)cbPeripheral
{
    NSLog(@"Info: CBPeripheral did update name: %@", cbPeripheral);
}

- (void)peripheral:(CBPeripheral *)cbPripheral didModifyServices:(NSArray *)invalidatedCBServices
{
    NSLog(@"Info: CBPeripheral did modify services: %@", invalidatedCBServices);
    
    NSArray *serviceUUIDs = [invalidatedCBServices valueForKey:@"UUID"];
    [self.services removeObjectsForKeys:serviceUUIDs];
}

- (void)peripheral:(CBPeripheral *)cbPeripheral didDiscoverServices:(NSError *)error
{
    if (error != nil)
    {
        NSLog(@"Error: CBPeripheral did discover service with error: %@", error);
    }
    else
    {
        NSLog(@"Info: CBPeripheral did discover services");
        
        for (CBService *cbService in cbPeripheral.services)
        {
            if ([cbService.UUID isEqual:self.dataTransferServiceUUID])
            {
                VYDataTransferService *service = self.services[cbService.UUID];
                
                if (service == nil)
                {
                    service = [VYDataTransferService serviceWithCBService:cbService];
                    
                    self.services[service.CBService.UUID] = service;
                }
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)cbPeripheral didDiscoverCharacteristicsForService:(CBService *)cbService error:(NSError *)error
{
    NSLog(@"Info: CBPeripheral did discover characteristics for service: %@; Error: %@", cbService, error);
    
    VYService *service = self.services[cbService.UUID];
    [service didDiscoverCharacteristicsWithError:error];
}

- (void)peripheral:(CBPeripheral *)cbPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)cbCharacteristic error:(NSError *)error
{
    NSLog(@"Error: CBPeripheral did update value for characteristic: %@; Error: %@", cbCharacteristic, error);
    
    VYService *service = self.services[cbCharacteristic.service.UUID];
    VYCharacteristic *characteristic = service.characteristics[cbCharacteristic.UUID];
    [characteristic didUpdateValueWithError:error];
}

- (void)peripheral:(CBPeripheral *)cbPeripheral didWriteValueForCharacteristic:(CBCharacteristic *)cbCharacteristic error:(NSError *)error
{
    NSLog(@"Info: CBPeripheral did write value for characteristic: %@; Error: %@", cbCharacteristic, error);
    
    VYService *service = self.services[cbCharacteristic.service.UUID];
    VYCharacteristic *characteristic = service.characteristics[cbCharacteristic.UUID];
    [characteristic didWriteValueWithError:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)cbCharacteristic error:(NSError *)error
{
    NSLog(@"Info: CBPeripheral did update notification state for characteristic: %@; Error: %@", cbCharacteristic, error);
    
    VYService *service = self.services[cbCharacteristic.service.UUID];
    VYCharacteristic *characteristic = service.characteristics[cbCharacteristic.UUID];
    [characteristic didUpdateNotificationStateWithError:error];
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == (__bridge void *)([self class]))
    {
        if (object == self.CBPeripheral)
        {
            if ([keyPath isEqualToString:@"services"])
            {
                if ([object valueForKeyPath:keyPath] == nil)
                {
                    [self.services removeAllObjects];
                }
            }
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
