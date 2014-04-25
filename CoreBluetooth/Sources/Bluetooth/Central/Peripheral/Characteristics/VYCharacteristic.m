//
//  VYCharacteristic.m
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/25/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

#import "VYCharacteristic.h"

#import "VYMessage.h"
#import "VYMessageChunk.h"

@interface VYCharacteristic ()

@property (nonatomic, copy) VYCharacteristicUpdateValueBlock autoUpdateValueBlock;

@property (nonatomic, copy) VYCharacteristicUpdateValueBlock updateValueBlock;
@property (nonatomic, copy) VYCharacteristicWriteValueBlock writeValueBlock;
@property (nonatomic, copy) VYCharacteristicUpdateNotificationStateBlock updateNotificationStateBlock;

@property (nonatomic, getter = isUpdateValueInProgress) BOOL updateValueInProgress;
@property (nonatomic, getter = isWriteValueInProgress) BOOL writeValueInProgress;
@property (nonatomic, getter = isUpdateNotificationInProgress) BOOL updateNotificationStateInProgress;

@property (nonatomic) VYMessage *writeMessage;
@property (nonatomic) VYMutableMessage *readMessage;

@end

@implementation VYCharacteristic

#pragma mark -
#pragma mark Object Lifecycle

+ (instancetype)characteristicWithCBCharacteristic:(CBCharacteristic *)cbCharacteristic
{
    return [[self alloc] initWithCBCharacteristic:cbCharacteristic];
}

- (instancetype)init
{
    return [self initWithCBCharacteristic:nil];
}

- (instancetype)initWithCBCharacteristic:(CBCharacteristic *)cbCharacteristic
{
    self = [super init];
    
    if (self != nil)
    {
        NSParameterAssert(cbCharacteristic != nil);
        
        if (cbCharacteristic != nil)
        {
            _CBCharacteristic = cbCharacteristic;
        }
        else
        {
            self = nil;
        }
    }
    
    return self;
}

#pragma mark -
#pragma mark Methods

- (void)setUpdateValueBlock:(VYCharacteristicUpdateValueBlock)block
{
    self.autoUpdateValueBlock = block;
}

- (void)readValueWithCompletion:(VYCharacteristicUpdateValueBlock)block
{
    NSAssert(![self isUpdateValueInProgress], @"Another read value for characteristic task is in progress.");
    
    if (![self isUpdateValueInProgress])
    {
        self.updateValueInProgress = YES;
        self.updateValueBlock = block;
        
        [self.CBCharacteristic.service.peripheral readValueForCharacteristic:self.CBCharacteristic];
    }
}

- (void)writeValue:(NSData *)value completion:(VYCharacteristicWriteValueBlock)block
{
    NSAssert(![self isWriteValueInProgress], @"Another write value for characteristic task is in progress.");
    
    if (![self isWriteValueInProgress])
    {
        self.writeValueInProgress = YES;
        self.writeValueBlock = block;
        
        self.writeMessage = [VYMessage messageWithData:value];
        [self writeValue:[self.writeMessage nextChunk].data];
    }
}

- (void)setNotifyValue:(BOOL)enabled completion:(VYCharacteristicUpdateNotificationStateBlock)block
{
    NSAssert(![self isUpdateNotificationInProgress], @"Another set notify value for characteristic task is in progress.");
    
    if (![self isUpdateNotificationInProgress])
    {
        self.updateNotificationStateInProgress = YES;
        self.updateNotificationStateBlock = block;
        [self.CBCharacteristic.service.peripheral setNotifyValue:enabled forCharacteristic:self.CBCharacteristic];
    }
}

#pragma mark -
#pragma mark Handling CBPeripheral Callbacks

- (void)didUpdateValueWithError:(NSError *)error
{
    if (error != nil)
    {
        if (self.autoUpdateValueBlock != nil)
        {
            self.autoUpdateValueBlock(nil, error);
        }
        
        if ([self isUpdateValueInProgress])
        {
            if (self.updateValueBlock != nil)
            {
                self.updateValueBlock(nil, error);
                self.updateValueBlock = nil;
            }
            
            self.readMessage = nil;
            self.updateValueInProgress = NO;
        }
    }
    else
    {
        VYMessageChunk *chunk = [VYMessageChunk messageChunkWithData:self.CBCharacteristic.value];
        
        if ([chunk isFirst])
        {
            self.readMessage = [VYMutableMessage messageWithChunk:chunk];
        }
        else
        {
            [self.readMessage addChunk:chunk];
        }
        
        if ([chunk isLast])
        {
            if (self.autoUpdateValueBlock != nil)
            {
                self.autoUpdateValueBlock(self.readMessage.data, error);
            }
            
            if ([self isUpdateValueInProgress])
            {
                if (self.updateValueBlock != nil)
                {
                    self.updateValueBlock(self.readMessage.data, error);
                    self.updateValueBlock = nil;
                }
                
                self.readMessage = nil;
                self.updateValueInProgress = NO;
            }
        }
    }
}

- (void)didWriteValueWithError:(NSError *)error
{
    if (error != nil)
    {
        if ([self isWriteValueInProgress])
        {
            if (self.writeValueBlock != nil)
            {
                self.writeValueBlock(nil, error);
                self.writeValueBlock = nil;
            }
            
            self.writeMessage = nil;
            self.writeValueInProgress = NO;
        }
    }
    else
    {
        if ([self isWriteValueInProgress])
        {
            if ([[self.writeMessage currentChunk] isLast])
            {
                if (self.writeValueBlock != nil)
                {
                    self.writeValueBlock(self.writeMessage.data, error);
                    self.writeValueBlock = nil;
                }
                
                self.writeMessage = nil;
                self.writeValueInProgress = NO;
            }
            else
            {
                [self writeValue:[self.writeMessage nextChunk].data];
            }
        }
    }
}

- (void)didUpdateNotificationStateWithError:(NSError *)error
{
    if ([self isUpdateNotificationInProgress])
    {
        if (self.updateNotificationStateBlock != nil)
        {
            self.updateNotificationStateBlock([self.CBCharacteristic isNotifying], error);
            self.updateNotificationStateBlock = nil;
        }
        
        self.updateNotificationStateInProgress = NO;
    }
}

#pragma mark -
#pragma mark Helpers

- (void)writeValue:(NSData *)value
{
    [self.CBCharacteristic.service.peripheral writeValue:value forCharacteristic:self.CBCharacteristic type:CBCharacteristicWriteWithResponse];
}

@end
