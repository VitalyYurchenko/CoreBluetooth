//
//  VYDataTransferService.m
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/24/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

#import "VYDataTransferService.h"

#import "VYConstants.h"

#import "VYCharacteristic.h"

@interface VYDataTransferService ()

@property (nonatomic, readonly) CBUUID *dataRequestCharacteristicUUID;
@property (nonatomic, readonly) CBUUID *dataResponseCharacteristicUUID;

@property (nonatomic, getter = isRequestInProgress) BOOL requestInProgress;

@end

@implementation VYDataTransferService

#pragma mark -
#pragma mark Object Lifecicle

- (instancetype)initWithCBService:(CBService *)cbService
{
    self = [super initWithCBService:cbService];
    
    if (self != nil)
    {
        _dataRequestCharacteristicUUID = [CBUUID UUIDWithString:kVYPeripheralDataRequestCharacteristicUUID];
        _dataResponseCharacteristicUUID = [CBUUID UUIDWithString:kVYPeripheralDataResponseCharacteristicUUID];
        
        [self configure];
    }
    
    return self;
}

- (void)dealloc
{
    [self unconfigure];
}

#pragma mark -
#pragma mark Overridden Methods

- (void)configure
{
    [super configure];
    
    [self discoverCharacteristics:@[self.dataRequestCharacteristicUUID, self.dataResponseCharacteristicUUID] completion:^(NSError *error)
    {
        if (error == nil)
        {
            // Configure data request characteristic.
            VYCharacteristic *requestCharacteristic = self.characteristics[self.dataRequestCharacteristicUUID];
            
            NSParameterAssert(requestCharacteristic != nil);
            NSParameterAssert(requestCharacteristic.CBCharacteristic.properties & CBCharacteristicPropertyWrite);
            
            // Configure data response characteristic.
            VYCharacteristic *responseCharacteristic = self.characteristics[self.dataResponseCharacteristicUUID];
            
            NSParameterAssert(responseCharacteristic != nil);
            NSParameterAssert(responseCharacteristic.CBCharacteristic.properties & CBCharacteristicPropertyRead);
        }
    }];
}

- (void)unconfigure
{
    [super unconfigure];
    
    [self.characteristics removeAllObjects];
}

#pragma mark -
#pragma mark Methods

- (void)sendRequestData:(NSData *)requestData completion:(VYDataTransferServiceResponseBlock)block
{
    NSAssert(![self isRequestInProgress], @"Another send request task is in progress.");
    
    if (![self isRequestInProgress])
    {
        self.requestInProgress = YES;
        
        VYCharacteristic *requestCharacteristic = self.characteristics[self.dataRequestCharacteristicUUID];
        [requestCharacteristic writeValue:requestData completion:^(NSData *writeValue, NSError *writeError)
        {
            if (block != nil)
            {
                if (writeError != nil)
                {
                    block(nil, writeError);
                    self.requestInProgress = NO;
                }
                else
                {
                    VYCharacteristic *responseCharacteristic = self.characteristics[self.dataResponseCharacteristicUUID];
                    [responseCharacteristic readValueWithCompletion:^(NSData *readValue, NSError *readError)
                    {
                        block(readValue, readError);
                        self.requestInProgress = NO;
                    }];
                }
            }
            else
            {
                self.requestInProgress = NO;
            }
        }];
    }
}

@end
