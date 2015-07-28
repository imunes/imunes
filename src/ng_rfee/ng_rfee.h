/*-
 * Copyright (c) 2015 University of Zagreb
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
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#define	MAX_LINK_EPIDS	2048		/* XXX should dynamically grow */
#define	MAX_TOTAL_EPIDS	10000		/* XXX should dynamically grow */

#define	EPID_UNASSIGNED 0xffffffff

#define	DEFAULT_TX_QLIM	64
#define	DUP_MAX		500

/* Internal types and structures. */
typedef struct ber {
	uint8_t	m;			/* Mantissa */
	uint8_t e;			/* Exponent */
} ber_t;

typedef struct epid {
	uint32_t	epid;		/* Endpoint ID */
	uint16_t	delay;		/* delay, in 0.1 ms */
	ber_t		ber;		/* Bit error rate */
} epid_t;

struct linkcfg {
	epid_t		local_epid;	/* ID of local vnode */
	uint32_t	bw;		/* TX bandwidth in bps */
	uint32_t	qlim;		/* TX queue length limit, in packets */
	uint32_t	dup;		/* TX pkt duplication prob, in .1% */
	uint32_t	jitter;		/* TX average delay jitter, in us */
	uint32_t	wjitter;	/* internal use - ignored if set */
	uint32_t	epidcnt;	/* # of elements in epids[] */
	epid_t		epids[MAX_LINK_EPIDS];
					/* destination EPIDS, with tags */
};

struct linkcfgreq {
	char		name[NG_HOOKSIZ];
	struct linkcfg	cfg;
};

/* Netgraph node type name and magic cookie. */
#define	NG_RFEE_NODE_TYPE	"rfee"
#define	NGM_RFEE_COOKIE		2015060201

/* Netgraph commands. */
enum {
	NGM_RFEE_SETLINKCFG = 1,
	NGM_RFEE_GETLINKCFG,
};

