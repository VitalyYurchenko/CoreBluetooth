//
//  VYMessageChunk.m
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/22/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

#import "VYMessageChunk.h"

typedef NS_OPTIONS(uint8_t, VYMessageChunkHeaderValue)
{
    VYMessageChunkHeaderValueFirst      = 1 << 0,
    VYMessageChunkHeaderValueLast       = 1 << 1,
    VYMessageChunkHeaderValueReserved1  = 1 << 2,
    VYMessageChunkHeaderValueReserved2  = 1 << 3,
    VYMessageChunkHeaderValueReserved3  = 1 << 4,
    VYMessageChunkHeaderValueReserved4  = 1 << 5,
    VYMessageChunkHeaderValueReserved5  = 1 << 6,
    VYMessageChunkHeaderValueReserved6  = 1 << 7
};

const NSUInteger kVYMessageChunkMTULength = 132;
const NSUInteger kVYMessageChunkHeaderLength = 1;
const NSUInteger kVYMessageChunkBodyLength = kVYMessageChunkMTULength - kVYMessageChunkHeaderLength;

@interface VYMessageChunk ()

@property (nonatomic, readonly) NSData *header;

@end

@implementation VYMessageChunk

#pragma mark -
#pragma mark Object Lifecycle

+ (instancetype)messageChunkWithData:(NSData *)data
{
    return [[self alloc] initWithData:data];
}

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    
    if (self != nil)
    {
        if ([data length] >= kVYMessageChunkHeaderLength)
        {
            // Parse header.
            NSData *header = [data subdataWithRange:NSMakeRange(0, kVYMessageChunkHeaderLength)];
            uint8_t byte = ((uint8_t *)[header bytes])[0];
            
            _first = byte & VYMessageChunkHeaderValueFirst;
            _last = byte & VYMessageChunkHeaderValueLast;
            
            if ([data length] > kVYMessageChunkHeaderLength)
            {
                // Copy body.
                NSInteger length = [data length] - kVYMessageChunkHeaderLength;
                
                NSParameterAssert(length <= kVYMessageChunkBodyLength);
                
                if (length <= kVYMessageChunkBodyLength)
                {
                    _body = [data subdataWithRange:NSMakeRange(kVYMessageChunkHeaderLength, length)];
                }
            }
        }
    }
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (NSData *)data
{
    NSMutableData *data = [NSMutableData data];
    [data appendData:self.header];
    [data appendData:self.body];
    
    return [NSData dataWithData:data];
}

- (void)setBody:(NSData *)body
{
    NSParameterAssert([body length] <= kVYMessageChunkBodyLength);
    
    if ([body length] <= kVYMessageChunkBodyLength)
    {
        _body = body;
    }
}

#pragma mark -
#pragma mark Private Accessors

- (NSData *)header
{
    uint8_t byte = 0;
    
    if ([self isFirst])
    {
        byte |= VYMessageChunkHeaderValueFirst;
    }
    
    if ([self isLast])
    {
        byte |= VYMessageChunkHeaderValueLast;
    }
    
    return [NSData dataWithBytes:&byte length:kVYMessageChunkHeaderLength];
}

@end
