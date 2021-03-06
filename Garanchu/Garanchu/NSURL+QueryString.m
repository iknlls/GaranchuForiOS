//
//  NSURL+QueryString.m
//  Garanchu
//
//  Copyright (c) 2013 makoto_kw. All rights reserved.
//

#import "NSURL+QueryString.h"

@implementation NSURL (QueryString)

+ (NSString *)urlEncode:(NSString *)text
{
    return (__bridge_transfer NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                (__bridge CFStringRef)text,
                                                                NULL,
                                                                (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                kCFStringEncodingUTF8);
//    return [text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)urlDecode:(NSString *)text
{
	return [text stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)buildParameters:(NSDictionary *)params
{
    NSMutableString *s = [NSMutableString string];    
    NSString *key;
    for ( key in params.allKeys ) {
        id value = [params objectForKey:key];
        if ([value isKindOfClass:[NSNull class]]) {
            [s appendFormat:@"%@=&", key];
        } else {
            NSString *uriEncodedValue = [NSURL urlEncode:[value description]];
            [s appendFormat:@"%@=%@&", key, uriEncodedValue];
        }
    }    
    if ( [s length] > 0 ) {
        [s deleteCharactersInRange:NSMakeRange([s length]-1, 1)];
    }
    return s;
}

+ (NSDictionary *)queryToDictionary:(NSString *)query
{    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	for (NSString *pair in pairs) {
		NSArray *components = [pair componentsSeparatedByString:@"="];
		[params setObject:[NSURL urlDecode:[components objectAtIndex:1]]
				   forKey:[NSURL urlDecode:[components objectAtIndex:0]]];
	}
	return params;
}

- (NSURL *)URLByAppendingQueryString:(NSString *)query overwrite:(BOOL)overwrite
{
    return [self URLByAppendingParameters:[NSURL queryToDictionary:query] overwrite:overwrite];
}

- (NSURL *)URLByAppendingParameters:(NSDictionary *)params overwrite:(BOOL)overwrite
{
    NSMutableDictionary *mergedParams = [self.queryAsDictionary mutableCopy];
    NSEnumerator* e = [params keyEnumerator];

    id key = nil;
    while ( (key = [e nextObject]) != nil) {
        if (overwrite || [mergedParams objectForKey:key] == nil) {
            [mergedParams setObject:[params objectForKey:key] forKey:key];
        }
    }
        
    NSString *urlString = nil;
    NSString *queryString = [NSURL buildParameters:mergedParams];
    if (self.query) {
        NSRange queryPrefixRange = [self.absoluteString rangeOfString:@"?"];
        urlString = [NSString stringWithFormat:@"%@?%@", 
                     [self.absoluteString substringWithRange:NSMakeRange(0, queryPrefixRange.location)],
                     queryString];
    } else {
        urlString = [NSString stringWithFormat:@"%@?%@", self.absoluteString, queryString];
    }
    return [NSURL URLWithString:urlString];
}

- (NSDictionary *)queryAsDictionary
{
    return [NSURL queryToDictionary:self.query];
}
            
@end
