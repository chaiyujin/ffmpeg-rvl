#include "librvldepth.h"

int DepthImageInfoSize = sizeof(DepthImageInfo);

int ff_librvldepth_compress_rvl(const short *input, char *output, int numPixels) {	
	int *buffer, *pBuffer, word, nibblesWritten, value;
    int zeros, nonzeros, nibble;
    int i;
    const short *p;
    const short *end;
	short previous;
    short current;
    int delta;
    int positive;
	word = 0;
	buffer = pBuffer = (int *)output;
	nibblesWritten = 0;
	end = input + numPixels;
    previous = 0;
	while (input != end) {
		zeros = 0, nonzeros = 0;
		for (; (input != end) && !*input; input++, zeros++);
		// EncodeVLE(zeros);  // number of zeros
		value = zeros;
		do {
			nibble = value & 0x7;  // lower 3 bits
			if (value >>= 3) nibble |= 0x8;  // more to come
			word <<= 4;
			word |= nibble;
			if (++nibblesWritten == 8) {
				// output word
				*pBuffer++ = word;
				nibblesWritten = 0;
				word = 0;
			}
		} while (value);
		for (p = input; (p != end) && *p++; nonzeros++);
		// EncodeVLE(nonzeros);
		value = nonzeros;
		do {
			nibble = value & 0x7;  // lower 3 bits
			if (value >>= 3) nibble |= 0x8;  // more to come
			word <<= 4;
			word |= nibble;
			if (++nibblesWritten == 8) {
				// output word
				*pBuffer++ = word;
				nibblesWritten = 0;
				word = 0;
			}
		} while (value);
		for (i = 0; i < nonzeros; i++) {
			current = *input++;
			delta = current - previous;
			positive = (delta << 1) ^ (delta >> 31);
			// EncodeVLE(positive);  // nonzero value
			value = positive;
			do {
				nibble = value & 0x7;  // lower 3 bits
				if (value >>= 3) nibble |= 0x8;  // more to come
				word <<= 4;
				word |= nibble;
				if (++nibblesWritten == 8) {
					// output word
					*pBuffer++ = word;
					nibblesWritten = 0;
					word = 0;
				}
			} while (value);
			previous = current;
		}
	}
	if (nibblesWritten)  // last few values
		*pBuffer++ = word << 4 * (8 - nibblesWritten);
	return (int)((char *)pBuffer - (char *)buffer);  // num bytes
}

void ff_librvldepth_decompress_rvl(const char *input, short *output, int numPixels) {
	const int *buffer, *pBuffer;
	int word, nibblesWritten, value, bits;
	unsigned int nibble;
	short current, previous;
	int numPixelsToDecode;
    int positive, zeros, nonzeros, delta;
    numPixelsToDecode = numPixels;
	buffer = pBuffer = (const int *)input;
	nibblesWritten = 0;
    previous = 0;
	while (numPixelsToDecode) {
		// int zeros = DecodeVLE();  // number of zeros
		value = 0;
		bits = 29;
		do {
			if (!nibblesWritten) {
				word = *pBuffer++;
				nibblesWritten = 8;
			}
			nibble = word & 0xf0000000;
			value |= (nibble << 1) >> bits;
			word <<= 4;
			nibblesWritten--;
			bits -= 3;
		} while (nibble & 0x80000000);
		zeros = value;
		numPixelsToDecode -= zeros;
		for (; zeros; zeros--)
			*output++ = 0;
		// int nonzeros = DecodeVLE();  // number of nonzeros
		value = 0;
		bits = 29;
		do {
			if (!nibblesWritten) {
				word = *pBuffer++;
				nibblesWritten = 8;
			}
			nibble = word & 0xf0000000;
			value |= (nibble << 1) >> bits;
			word <<= 4;
			nibblesWritten--;
			bits -= 3;
		} while (nibble & 0x80000000);
		nonzeros = value;
		numPixelsToDecode -= nonzeros;
		for (; nonzeros; nonzeros--) {
			// int positive = DecodeVLE();  // nonzero value
			value = 0;
			bits = 29;
			do {
				if (!nibblesWritten) {
					word = *pBuffer++;
					nibblesWritten = 8;
				}
				nibble = word & 0xf0000000;
				value |= (nibble << 1) >> bits;
				word <<= 4;
				nibblesWritten--;
				bits -= 3;
			} while (nibble & 0x80000000);
			positive = value;
			delta = (positive >> 1) ^ -(positive & 1);
			current = previous + delta;
			*output++ = current;
			previous = current;
		}
	}
}