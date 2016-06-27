#include <objc/NSObject.h>

@interface VideoPacket : NSObject

@property char* buffer;
@property int size;

@end

@interface VideoFileParser : NSObject

-(BOOL)open:(NSString*)fileName;
-(VideoPacket *)nextPacket;
-(void)close;

@end
