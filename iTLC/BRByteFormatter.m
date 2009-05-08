/*
 * Copyright (c) 2005-2006 Michele Balistreri
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE. 
 */

#import "BRByteFormatter.h"

@implementation BRByteFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
	NSArray *sizeTable = [NSArray arrayWithObjects:@"B", @"KB", @"MB", @"GB", @"TB", nil];
		
	int i;
	float result = [anObject floatValue];
	
	if([anObject respondsToSelector:@selector(length)])
	{
		return anObject;
	}
	
	for(i = 0; i < 5 && result >= 1024; i++)
	{
		result = result/1024;
	}
	
	if((float)(result - (int)result) > 0.01)
	{
		return [NSString localizedStringWithFormat:@"%.2f %@", result, [sizeTable objectAtIndex:i]];
	}
	
	else
	{
		return [NSString localizedStringWithFormat:@"%.0f %@", result, [sizeTable objectAtIndex:i]];	
	}
}

@end
