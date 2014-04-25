//
//  VYMessage.m
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/16/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

#import "VYMessage.h"

#import "VYMessageChunk.h"

NSString * const kVYMessageOptionsIndentifierKey = @"VYMessageOptionsIndentifierKey";

@interface VYMessage ()
{
    NSUInteger _chunkCount;
}

@property (nonatomic) NSInteger chunkIndex;

@end

@implementation VYMessage

#pragma mark -
#pragma mark Object Lifecycle

+ (instancetype)messageWithData:(NSData *)data
{
    return [[self alloc] initWithData:data];
}

+ (instancetype)messageWithChunk:(VYMessageChunk *)chunk
{
    return [[self alloc]initWithChunk:chunk];
}

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    
    if (self != nil)
    {
        _chunkIndex = -1;
        
        [self updateWithData:data];
    }
    
    return self;
}

- (instancetype)initWithChunk:(VYMessageChunk *)chunk
{
    return [self initWithData:chunk.body];
}

#pragma mark -
#pragma mark Methods

- (NSUInteger)chunkCount
{
    return _chunkCount;
}

- (VYMessageChunk *)firstChunk
{
    return [self retreiveChunkAtIndex:0];
}

- (VYMessageChunk *)currentChunk
{
    return [self retreiveChunkAtIndex:self.chunkIndex];
}

- (VYMessageChunk *)nextChunk
{
    return [self retreiveChunkAtIndex:self.chunkIndex + 1];
}

- (VYMessageChunk *)chunkAtIndex:(NSUInteger)index
{
    NSParameterAssert(index < [self chunkCount]);
    
    VYMessageChunk *chunk = nil;
    
    if (index < [self chunkCount])
    {
        chunk = [self retreiveChunkAtIndex:index];
    }
    else
    {
        @throw [NSException exceptionWithName:@"IndexOutOfBounds" reason:@"Index out of bounds" userInfo:nil];
    }
    
    return chunk;
}

#pragma mark -
#pragma mark Private Methods

- (void)updateWithData:(NSData *)data
{
    _data = [data copy];
    _chunkCount = ([_data length] % kVYMessageChunkBodyLength == 0)
    ? [_data length] / kVYMessageChunkBodyLength
    : [_data length] / kVYMessageChunkBodyLength + 1;
}

- (VYMessageChunk *)retreiveChunkAtIndex:(NSUInteger)index
{
    VYMessageChunk *chunk = nil;
    
    if (index < [self chunkCount])
    {
        self.chunkIndex = index;
        
        NSUInteger location = self.chunkIndex * kVYMessageChunkBodyLength;
        NSInteger length = [self.data length] - location;
        
        if (length > kVYMessageChunkBodyLength)
        {
            length = kVYMessageChunkBodyLength;
        }
        
        chunk = [VYMessageChunk new];
        chunk.first = (self.chunkIndex == 0);
        chunk.last = (self.chunkIndex == [self chunkCount] - 1);
        chunk.body = [NSData dataWithBytes:[self.data bytes] + location length:length];
    }
    
    return chunk;
}

@end

@implementation VYMutableMessage

- (void)addChunk:(VYMessageChunk *)chunk
{
    if (chunk != nil)
    {
        NSMutableData *data = [self.data mutableCopy];
        [data appendData:chunk.body];
        
        [self updateWithData:data];
    }
}

@end
