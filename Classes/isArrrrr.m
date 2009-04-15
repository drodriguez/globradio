/*
 *  isArrrrr.m
 *  radio3
 *
 *  Created by Daniel Rodríguez Troitiño on 03/04/09.
 *  Copyright 2009 Javier Quevedo & Daniel Rodríguez. All rights reserved.
 *
 */

#define ARRRRR_THRESHOLD 1

#define XXTEA_KEY ((int32_t *)"fohy9yo0aeG4aina")
#define CHECK_ARRRRR 1

/* XXTEA http://en.wikipedia.org/wiki/XXTEA */
#define MX (z>>5^y<<2) + (y>>3^z<<4)^(sum^y) + (k[p&3^e]^z);
static int32_t btea(int32_t *v, int32_t n, int32_t *k) {
  uint32_t z = v[n-1];
  uint32_t y = v[0];
  uint32_t sum = 0;
  uint32_t e;
  static uint32_t DELTA = 0x9e3779b9;
  int32_t p, q;
  if (n > 1) { /* Coding */
    q = 6 + 52/n;
    while (q-- > 0) {
      sum += DELTA;
      e = (sum >> 2) & 3;
      for (p = 0; p < n-1; p++)
        y = v[p+1], z = v[p] += MX;
      y = v[0];
      z = v[n-1] += MX;
    }
    return 0;
  } else if (n < -1) { /* Decoding */
    n = -n;
    q = 6 + 52/n;
    sum = q*DELTA;
    while (sum != 0) {
      e = (sum >> 2) & 3;
      for (p = n-1; p > 0; p--)
        z = v[p-1], y = v[p] -= MX;
      z = v[n-1];
      y = v[0] -= MX;
      sum -= DELTA;
    }
    return 0;
  }
  return 1;
}
      

static inline BOOL isArrrrr(void) {
  static int w = 0;
#if defined(CHECK_ARRRRR)    
  static int c = 0;
  if (c == 0) {
    /* SignerIdentity */
    NSMutableData *si = [[NSMutableData alloc]
                         initWithBytes:"\x63\x9e\xea\x4a\x2e\xbd\x5e\x56\x9f\x5e\x56\xde\xd5\x1f\x5c\x55"
                         length:16];
    /* Info */
    NSMutableData *io = [[NSMutableData alloc]
                         initWithBytes:"\x40\x3c\x29\xb7\x47\x55\x32\x2d"
                         length:8];
    /* plist */
    NSMutableData *pl = [[NSMutableData alloc]
                         initWithBytes:"\x98\x9b\xe7\x2c\xce\xce\x06\xd0"
                         length:8];
    /* PkgInfo */
    NSMutableData *pk = [[NSMutableData alloc]
                         initWithBytes:"\xf9\x4b\x62\xde\x65\xf5\x48\x81"
                         length:8];
                         
    btea([si mutableBytes], -4, XXTEA_KEY);
    btea([io mutableBytes], -2, XXTEA_KEY);
    btea([pl mutableBytes], -2, XXTEA_KEY);
    btea([pk mutableBytes], -2, XXTEA_KEY);
    
    NSString *sis = [NSString stringWithCString:[si mutableBytes]
                                       encoding:NSASCIIStringEncoding];
    NSString *ios = [NSString stringWithCString:[io mutableBytes]
                                       encoding:NSASCIIStringEncoding];
    NSString *pls = [NSString stringWithCString:[pl mutableBytes]
                                       encoding:NSASCIIStringEncoding];
    NSString *pks = [NSString stringWithCString:[pk mutableBytes]
                                       encoding:NSASCIIStringEncoding];
    
    /* First test: Signer Identity */
    if([[[NSBundle mainBundle] infoDictionary] objectForKey:sis] != nil)
      w++;
    
    /* Second test: plist file in textual format */
    NSString *p = [[NSBundle mainBundle] pathForResource:ios ofType:pls];
    NSData *d = [NSData dataWithContentsOfFile:p];
    NSPropertyListFormat f;
    if ([NSPropertyListSerialization propertyListFromData:d
                                         mutabilityOption:NSPropertyListImmutable
                                                   format:&f
                                         errorDescription:NULL] &&
        f != NSPropertyListBinaryFormat_v1_0)
      w++;
    
    NSDate *d1 = [[[NSFileManager defaultManager]
                   fileAttributesAtPath:p traverseLink:YES]
                    fileModificationDate];
    NSDate *d2 = [[[NSFileManager defaultManager]
                  fileAttributesAtPath:[[[NSBundle mainBundle] resourcePath]
                                        stringByAppendingPathComponent:pks]
                  traverseLink:YES]
                  fileModificationDate];
    if ([d1 timeIntervalSinceReferenceDate] > [d2 timeIntervalSinceReferenceDate])
      w++;
    
    [si release];
    [io release];
    [pl release];
    [pk release];
    
    c = 1;
  }
#endif
  return w >= ARRRRR_THRESHOLD;
}
