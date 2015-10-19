//
//  main.m
//  cartool
//
//  Created by Steven Troughton-Smith on 14/07/2013.
//  Copyright (c) 2013 High Caffeine Content. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CUINamedLookup : NSObject
- (NSString *)renditionName;
@end

@interface CUINamedImage : CUINamedLookup
-(CGImageRef)image;
@end

@interface CUIThemeFacet : NSObject
+(CUIThemeFacet *)themeWithContentsOfURL:(NSURL *)u error:(NSError **)e;
@end

@interface CUICatalog : NSObject
- (NSArray <NSString *>*)allImageNames;
- (NSArray <CUINamedImage *>*)imagesWithName:(NSString *)n;
@end

void CGImageWriteToFile(CGImageRef image, NSString *path)
{
	if (!image)
		return;

    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
	CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, ([path hasSuffix:@".png"] ? kUTTypePNG : kUTTypeJPEG), 1, NULL);
    CGImageDestinationAddImage(destination, image, nil);
	
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
    }
	
    CFRelease(destination);
}


void exportCarFileAtPath(NSString * carPath, NSString *outputDirectoryPath)
{
	NSError *error = nil;
	
	outputDirectoryPath = [outputDirectoryPath stringByExpandingTildeInPath];

	CUIThemeFacet *facet = [CUIThemeFacet themeWithContentsOfURL:[NSURL fileURLWithPath:carPath] error:&error];
	
	CUICatalog *catalog = [[CUICatalog alloc] init];
	
	/* Override CUICatalog to point to a file rather than a bundle */
	[catalog setValue:facet forKey:@"_storageRef"];
	
	for (NSString *key in [catalog allImageNames]) {
		printf("%s\n", [key UTF8String]);

		NSArray *images = [catalog imagesWithName:key];
		
		for (CUINamedImage *image in images) {
			CGImageWriteToFile ([image image], [outputDirectoryPath stringByAppendingPathComponent:image.renditionName]);
		}
	}
}

int main(int argc, const char * argv[])
{
	@autoreleasepool {
	    
		if (argc != 3)
		{
			printf("Usage: cartool Assets.car outputDirectory\n");
			return -1;
		}
	    
		exportCarFileAtPath([NSString stringWithUTF8String:argv[1]], [NSString stringWithUTF8String:argv[2]]);
		
	}
    return 0;
}