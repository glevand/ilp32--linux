// SPDX-License-Identifier: GPL-2.0
/*
 * ARM64 userspace implementations of gettimeofday() and similar.
 *
 * Copyright (C) 2018 ARM Limited
 *
 */
#include <linux/time.h>
#include <linux/types.h>

#if 0
static void sizeof_types(void)
{
	struct __kernel_timespec ts;
	struct old_timespec32 ots32;
	struct __kernel_old_timeval otv;
	struct __kernel_old_timeval otv32;

	char (*__1)[sizeof(ts.tv_sec)] = 1;     // 8 bytes.
	char (*__2)[sizeof(ts.tv_nsec)] = 1;    // 8 bytes.

	char (*__3)[sizeof(ots32.tv_sec)] = 1;  // 4 bytes.
	char (*__4)[sizeof(ots32.tv_nsec)] = 1; // 4 bytes.

	char (*__5)[sizeof(otv.tv_sec)] = 1;    // 4 bytes.
	char (*__6)[sizeof(otv.tv_usec)] = 1;   // 4 bytes.

	char (*__7)[sizeof(otv32.tv_sec)] = 1;  // 4 bytes.
	char (*__8)[sizeof(otv32.tv_usec)] = 1; // 4 bytes.
}
#endif

int __kernel_clock_gettime(clockid_t clock,
			   struct __kernel_timespec *ts)
{
	return __cvdso_clock_gettime(clock, ts);
}

int __kernel_gettimeofday(struct __kernel_old_timeval *tv,
			  struct timezone *tz)
{
	return __cvdso_gettimeofday(tv, tz);
}

int __kernel_clock_getres(clockid_t clock_id,
			  struct __kernel_timespec *res)
{
	return __cvdso_clock_getres(clock_id, res);
}
