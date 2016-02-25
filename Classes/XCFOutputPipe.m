//
//  XCFOutputPipe.m
//  BBUncrustifyPlugin
//
//  Created by Guy Kogus on 25/02/16.
//
//

#import "XCFOutputPipe.h"
#import "BBLogging.h"

@interface XCFOutputPipe ()

@property (nonatomic, strong) NSFileHandle *writeFileHandle;
@property (nonatomic, strong) NSFileHandle *readFileHandle;
@property (nonatomic, strong) NSURL *fileUrl;

@end

@implementation XCFOutputPipe

+ (NSPipe *)pipe
{
	return [[XCFOutputPipe alloc] init];
}

- (void)dealloc
{
	if (self.fileUrl)
	{
		[[NSFileManager defaultManager] removeItemAtURL:self.fileUrl error:NULL];
	}
}

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"clang-format.tmp"];
		NSError *error = nil;
		NSURL *directoryURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
		if (![fileManager createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error])
		{
			DDLogError(@"Failed to create temporary directory: %@", error);
		}
		else
		{
			_fileUrl = [directoryURL URLByAppendingPathComponent:fileName];
			if (![fileManager fileExistsAtPath:[_fileUrl path]] &&
				![fileManager createFileAtPath:[_fileUrl path] contents:nil attributes:nil])
			{
				DDLogError(@"Failed to create temporary file at %@", _fileUrl);
				_fileUrl = nil;
			}
			else
			{
				_writeFileHandle = [NSFileHandle fileHandleForWritingToURL:_fileUrl error:NULL];
				_readFileHandle = [NSFileHandle fileHandleForReadingFromURL:_fileUrl error:NULL];
			}
		}
	}
	return (_writeFileHandle && _readFileHandle) ? self : nil;
}

- (NSFileHandle *)fileHandleForWriting
{
	return self.writeFileHandle;
}

- (NSFileHandle *)fileHandleForReading
{
	return self.readFileHandle;
}

@end
