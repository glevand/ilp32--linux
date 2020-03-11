// SPDX-License-Identifier: GPL-2.0
/*
 * ARM64 userspace implementations of gettimeofday() and similar.
 *
 * Copyright (C) 2018 ARM Limited
 *
 */
#include <linux/time.h>
#include <linux/types.h>

//#include <asm/vdso/compat_gettimeofday.h>

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

#if 0
static __always_inline
long clock_gettime_fallback(clockid_t _clkid, struct __kernel_timespec *_ts)
{
	register struct __kernel_timespec *ts asm("x1") = _ts;
	register clockid_t clkid asm("x0") = _clkid;
	register long ret asm ("x0");
	register long nr asm("x8") = __NR_clock_gettime;

	asm volatile(
	"       svc #0\n"
	: "=r" (ret)
	: "r" (clkid), "r" (ts), "r" (nr)
	: "memory");

	return ret;
}
#endif

static __always_inline
long clock_gettime32_fallback(clockid_t _clkid, struct old_timespec32 *_ts)
{
	register struct old_timespec32 *ts asm("r1") = _ts;
	register clockid_t clkid asm("r0") = _clkid;
	register long ret asm ("r0");
	register long nr asm("r7") = __NR_compat_clock_gettime;

	asm volatile(
	"	svc #0\n"
	: "=r" (ret)
	: "r" (clkid), "r" (ts), "r" (nr)
	: "memory");

	return ret;
}

static __maybe_unused int
__cvdso_clock_gettime32(clockid_t clock, struct old_timespec32 *res)
{
	struct __kernel_timespec ts;
	int ret;

	ret = __cvdso_clock_gettime_common(clock, &ts);

	if (unlikely(ret))
		return clock_gettime32_fallback(clock, res);

	/* For ret == 0 */
	res->tv_sec = ts.tv_sec;
	res->tv_nsec = ts.tv_nsec;

	return ret;
}

int __kernel_clock_gettime(clockid_t clock,
			   struct old_timespec32 *ts)
{
	return __cvdso_clock_gettime32(clock, ts);
}

int __kernel_gettimeofday(struct __kernel_old_timeval *tv,
			  struct timezone *tz)
{
	return __cvdso_gettimeofday(tv, tz);
}

#if 0
static __always_inline
int clock_getres_fallback(clockid_t _clkid, struct __kernel_timespec *_ts)
{
	register struct __kernel_timespec *ts asm("x1") = _ts;
	register clockid_t clkid asm("x0") = _clkid;
	register long ret asm ("x0");
	register long nr asm("x8") = __NR_clock_getres;

	asm volatile(
	"       svc #0\n"
	: "=r" (ret)
	: "r" (clkid), "r" (ts), "r" (nr)
	: "memory");

	return ret;
}
#endif

static __always_inline
int clock_getres32_fallback(clockid_t _clkid, struct old_timespec32 *_ts)
{
	register struct old_timespec32 *ts asm("r1") = _ts;
	register clockid_t clkid asm("r0") = _clkid;
	register long ret asm ("r0");
	register long nr asm("r7") = __NR_compat_clock_getres;

	/* The checks below are required for ABI consistency with arm */
	if ((_clkid >= MAX_CLOCKS) && (_ts == NULL))
		return -EINVAL;

	asm volatile(
	"       svc #0\n"
	: "=r" (ret)
	: "r" (clkid), "r" (ts), "r" (nr)
	: "memory");

	return ret;
}

static __maybe_unused int
__cvdso_clock_getres_time32(clockid_t clock, struct old_timespec32 *res)
{
	struct __kernel_timespec ts;
	int ret;

	ret = __cvdso_clock_getres_common(clock, &ts);

	if (unlikely(ret))
		return clock_getres32_fallback(clock, res);

	if (likely(res)) {
		res->tv_sec = ts.tv_sec;
		res->tv_nsec = ts.tv_nsec;
	}
	return ret;
}

int __kernel_clock_getres(clockid_t clock_id,
			  struct old_timespec32 *res)
{
	return __cvdso_clock_getres_time32(clock_id, res);
}
