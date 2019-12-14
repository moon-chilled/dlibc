module dlibc.external.allocator;

// Shamelessly stolen from freebsd; libexec/rtld-elf/rtld_malloc.c
// TODO: maybe replace with https://github.com/mjansson/rpmalloc or similar?
// that one seems to be fancy/fast, with a (slightly) more permissive license.
// Main concern is that integrating this into druntime would mean that the whole
// thing could no longer be boost-licensed.
// (Or maybe write my own malloc)

// Copyright notice follows:
/*
 * Copyright (c) 1983 Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
/*
 * malloc.c (Caltech) 2/21/82
 * Chris Kingsley, kingsley@cit-20.
 *
 * This is a very fast storage allocator.  It allocates blocks of a small
 * number of different sizes, and keeps free lists of each size.  Blocks that
 * don't exactly fit are passed up to the next larger size.  In this
 * implementation, the available sizes are 2^n-4 (or 2^n-10) bytes long.
 * This is designed for use in a virtual memory environment.
 */


import plat_version;
import sys_mman;
import string;
import strings;
import unistd;

extern (C):
__gshared:

// A reasonable default, and likely to be correct
// but for an actual implementation, see __init_libc in musl (src/env/__libc_start_main.c)
auto getpagesize() { return 0x1000; }



//TODO: take advantage of the fact that 'size' is a power of 2
private long roundup2(long x, long size) {
	if (x % size != 0) {
		return x + size-(x%size);
	} else {
		return x;
	} 
}
private long rounddown2(long x, long size) {
	if (x % size != 0) {
		return x - (x%size);
	} else {
		return x;
	}
}

/*
 * Pre-allocate mmap'ed pages
 */
enum NPOOLPAGES = 128*1024/getpagesize();
private char* pagepool_start, pagepool_end;

/*
 * The overhead on a block is at least 4 bytes.  When free, this space
 * contains a pointer to the next free block, and the bottom two bits must
 * be zero.  When in use, the first byte is set to MAGIC, and the second
 * byte is the size index.  The remaining bytes are for alignment.
 * If range checking is enabled then a second word holds the size of the
 * requested block, less 1, rounded up to a multiple of sizeof(RMAGIC).
 * The order of elements is critical: ov.magic must overlay the low order
 * bits of ov_next, and ov.magic can not be a valid ov_next bit pattern.
 */
union Overhead {
	Overhead *ov_next;	/* when free */
	private struct _ovu {
		ubyte magic;	/* magic number */
		ubyte index;	/* bucket # */
	}
       	_ovu ov;
}

enum MAGIC = 0xef; /* magic # on accounting info */

/*
 * nextf[i] is the pointer to the next free block of size 2^(i+3).  The
 * smallest allocatable block is 8 bytes.  The Overhead information
 * precedes the data area returned to the user.
 */
enum NBUCKETS = 30;
private Overhead*[NBUCKETS] nextf;

private int pagesz;			/* page size */
private int pagebucket;			/* page size bucket */

/*
 * The array of supported page sizes is provided by the user, i.e., the
 * program that calls this storage allocator.  That program must initialize
 * the array before making its first call to allocate storage.  The array
 * must contain at least one page size.  The page sizes must be stored in
 * increasing order.
 */

void *malloc(size_t nbytes) {
	Overhead *op;
	int bucket;
	ssize_t n;
	size_t amt;

	/*
	 * First time malloc is called, setup page size and
	 * align break pointer so all data will be page aligned.
	 */
	if (pagesz == 0) {
		pagesz = n = getpagesize();
		if (morepages(NPOOLPAGES) == 0)
			return null;
		op = cast(Overhead *)(pagepool_start);
  		n = n - (*op).sizeof - (cast(long)op & (n - 1));
		if (n < 0)
			n += pagesz;
  		if (n) {
			pagepool_start += n;
		}
		bucket = 0;
		amt = 8;
		while (cast(uint)pagesz > amt) {
			amt <<= 1;
			bucket++;
		}
		pagebucket = bucket;
	}
	/*
	 * Convert amount of memory requested into closest block size
	 * stored in hash buckets which satisfies request.
	 * Account for space used per block for accounting.
	 */
	if (nbytes <= cast(ulong)(n = pagesz - (*op).sizeof)) {
		amt = 8;	/* size of first bucket */
		bucket = 0;
		n = -(*op).sizeof;
	} else {
		amt = pagesz;
		bucket = pagebucket;
	}
	while (nbytes > amt + n) {
		amt <<= 1;
		if (amt == 0)
			return null;
		bucket++;
	}
	/*
	 * If nothing in hash bucket right now,
	 * request more memory from the system.
	 */
  	if ((op = nextf[bucket]) == null) {
  		morecore(bucket);
  		if ((op = nextf[bucket]) == null)
  			return (null);
	}
	/* remove from linked list */
  	nextf[bucket] = op.ov_next;
	op.ov.magic = MAGIC;
	op.ov.index = cast(ubyte)bucket;
  	return cast(char *)(op + 1);
}

void *calloc(size_t num, size_t size) {
	void *ret;

	if (size != 0 && (num * size) / size != num) {
		/* size_t overflow. */
		return (null);
	}

	if ((ret = malloc(num * size)) != null)
		memset(ret, 0, num * size);

	return (ret);
}

/*
 * Allocate more memory to the indicated bucket.
 */
private void morecore(int bucket) {
	Overhead *op;
	int sz;		/* size of desired block */
  	int amt;			/* amount to allocate */
  	int nblks;			/* how many blocks we get */

	/*
	 * sbrk_size <= 0 only for big, FLUFFY, requests (about
	 * 2^30 bytes on a VAX, I think) or for a negative arg.
	 */
	if (cast(uint)bucket >= 8 * int.sizeof - 4)
		return;
	sz = 1 << (bucket + 3);
	if (sz < pagesz) {
		amt = pagesz;
  		nblks = amt / sz;
	} else {
		amt = sz + pagesz;
		nblks = 1;
	}
	if (amt > pagepool_end - pagepool_start)
		if (morepages(amt/pagesz + NPOOLPAGES) == 0)
			return;
	op = cast(Overhead *)pagepool_start;
	pagepool_start += amt;

	/*
	 * Add new memory allocated to that on
	 * free list for this hash bucket.
	 */
  	nextf[bucket] = op;
  	while (--nblks > 0) {
		op.ov_next = cast(Overhead *)(cast(char*)op + sz);
		op = cast(Overhead *)(cast(char*)op + sz);
  	}
}

void free(void *cp) {
	int size;
	Overhead *op;

  	if (cp == null)
  		return;
	op = cast(Overhead *)(cast(char*)cp - Overhead.sizeof);
	if (op.ov.magic != MAGIC)
		return;				/* sanity */
  	size = op.ov.index;
	op.ov_next = nextf[size];	/* also clobbers ov.magic */
  	nextf[size] = op;
}

void *realloc(void *cp, size_t nbytes) {
	uint onb;
	int i;
	Overhead *op;
  	void *res;

  	if (cp == null)
		return (malloc(nbytes));
	op = cast(Overhead *)(cast(char*)cp - Overhead.sizeof);
	if (op.ov.magic != MAGIC)
		return (null);	/* Double-free or bad argument */
	i = op.ov.index;
	onb = 1 << (i + 3);
	if (onb < cast(uint)pagesz)
		onb -= (*op).sizeof;
	else
		onb += pagesz - (*op).sizeof;
	/* avoid the copy if same size block */
	if (i != 0) {
		i = 1 << (i + 2);
		if (i < pagesz)
			i -= (*op).sizeof;
		else
			i += pagesz - (*op).sizeof;
	}
	if (nbytes <= onb && nbytes > cast(size_t)i)
		return (cp);
  	if ((res = malloc(nbytes)) == null)
		return (null);
	bcopy(cp, res, (nbytes < onb) ? nbytes : onb);
	free(cp);
  	return (res);
}

private int morepages(int n) {
	char *addr;
	int offset;

	if (pagepool_end - pagepool_start > pagesz) {
		addr = cast(char*)roundup2(cast(long)pagepool_start, pagesz);
		if (munmap(addr, pagepool_end - addr) != 0) {
version (dbg_messages) {
			rtld_fdprintf(STDERR_FILENO,
			    "morepages: cannot munmap %p: %s\n",
			    addr, rtld_strerror(errno));
}
		}
	}

	offset = cast(int)(cast(long)pagepool_start - rounddown2(cast(long)pagepool_start, pagesz));

	pagepool_start = cast(char*)mmap(null, n * pagesz, PROT_READ | PROT_WRITE,
	    MAP_ANON | MAP_PRIVATE, -1, 0);
	if (pagepool_start == MAP_FAILED) {
version (dbg_messages) {
		rtld_fdprintf(STDERR_FILENO,
		    "morepages: cannot mmap anonymous memory: %s\n",
		    rtld_strerror(errno));
}
		return (0);
	}
	pagepool_end = pagepool_start + n * pagesz;
	pagepool_start += offset;

	return (n);
}
