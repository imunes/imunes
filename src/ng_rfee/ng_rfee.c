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

/*
 * TODO:
 *
 * use ticks instead of microuptime?
 * use taskqueue_enqueue instead of direct execution in callout handler?
 * bounds checking
 * node naming
 * mbuf leaks?
 * revisit mbuf copying functions (reduce mbuf manipulation overhead?)
 * dynamically allocate / grow cfg arrays (reduce runtime memory footprint?)
 * revisit microuptime() pressure?
 */

#include <sys/param.h>
#include <sys/ctype.h>
#include <sys/kdb.h>
#include <sys/kernel.h>
#include <sys/malloc.h>
#include <sys/mbuf.h>

#include <netgraph/ng_message.h>
#include <netgraph/netgraph.h>
#include <netgraph/ng_ksocket.h>
#include <netgraph/ng_parse.h>

#include "ng_rfee.h"
MALLOC_DEFINE(M_NETGRAPH_RFEE, "ng_rfee", "ng_rfee");
#ifndef MALLOC
#define MALLOC(space, cast, size, type, flags) \
 ((space) = (cast)malloc((u_long)(size), (type), (flags)))
#define FREE(addr, type) free((addr), (type))
#endif



#ifndef M_DONTWAIT
#define M_DONTWAIT M_NOWAIT
#endif

static uma_zone_t ngd_zone;	/* Stores descriptors of queued packets */

static int ng_rfee_linkcfg_parse(const struct ng_parse_type *type,
    const char *s, int *off, const u_char *const start,
    u_char *const buf, int *buflen);
static int ng_rfee_linkcfg_unparse(const struct ng_parse_type *type,
    const u_char *data, int *off, char *cbuf, int cbuflen);
static int ng_rfee_modevent(module_t mod, int type, void *unused);

static void link_unmap(hook_p hook);
static void link_map(hook_p hook);


/*
 * BER lookup table, modevent() must populate it.
 * The table has three dimensions:
 *  A: exponent (number of contiguous zeros after decimal point)
 *  B: mantissa (integer 1 to 9)
 *  C: packet size (in bytes, including additional framing overhead)
 */
#define	BER_E_MAX	12	/* max. exponent */
#define BER_PLEN_MAX	4095	/* max. packet length */
static uint64_t ber_p[BER_E_MAX+1][10][BER_PLEN_MAX+1];

/* TX jitter probability distribution is defined via this table. */
static struct jittertbl_entry {
	uint32_t	lo;	/* usec */
	uint32_t	hi;	/* usec */
} jt[] = {
	{ 20, 100 }, { 20, 150 }, { 20, 200 }, { 20, 300 },
	{ 20, 400 }, { 20, 500 }, { 20, 600 }, { 20, 700 },
	{ 20, 800 }, { 20, 850 }, { 20, 900 }, { 20, 950 },
	{ 20, 800 }, { 20, 850 }, { 20, 900 }, { 20, 950 },
	{ 20, 1000 }, { 20, 1050 }, { 50, 1100 }, { 20, 1150 },
	{ 20, 1000 }, { 20, 1050 }, { 50, 1100 }, { 20, 1150 },
	{ 20, 1000 }, { 20, 1050 }, { 50, 1100 }, { 20, 1150 },
	{ 50, 1500 }, { 50, 2500 }, { 100, 3500 }, { 100, 8000 },
	{ 0, 0 }	/* Terminating element is always { 0, 0 } */
};

static uint32_t	jt_size;	/* Element count in jt[] table */
static uint32_t	jt_avg;		/* In usec */


/* Bandwidth / delay queue infrastructure */
/* Packet header struct */
struct ngd_hdr {
	TAILQ_ENTRY(ngd_hdr)	ngd_le;		/* next pkt in queue */
	struct mbuf		*m;		/* packet */
	struct timeval		when;		/* this packet's due time */
};
TAILQ_HEAD(p_head, ngd_hdr);

/* Parse type for link configuration. */
static const struct ng_parse_type ng_rfee_linkcfg_type = {
	.parse =	&ng_rfee_linkcfg_parse,
	.unparse =	&ng_rfee_linkcfg_unparse,
};

/* List of commands and how to convert arguments to/from ASCII. */
static const struct ng_cmdlist ng_rfee_cmds[] = {
	{
		.cookie =	NGM_RFEE_COOKIE,
		.cmd =		NGM_RFEE_SETLINKCFG,
		.name =		"setlinkcfg",
		.mesgType =	&ng_rfee_linkcfg_type,
		.respType =	NULL
	},
	{
		.cookie =	NGM_RFEE_COOKIE,
		.cmd =		NGM_RFEE_GETLINKCFG,
		.name =		"getlinkcfg",
		.mesgType =	&ng_rfee_linkcfg_type,
		.respType =	&ng_rfee_linkcfg_type
	},
	{ 0 }
};

/* Hook private data. */
struct hookinfo {
	hook_p		hook;
	int		bwq_frames;		/* # of frames in bw queue */
	int		dlq_frames;		/* # of frames in delay queue */
	struct p_head	bwq_head;		/* Bandwidth queue head */
	struct p_head	dlq_head;		/* Delay queue head */
	struct timeval	bwq_utime;		/* Deadline for next pkt */
	LIST_ENTRY(hookinfo) bwq_le;		/* All active bandwidth qs */
	LIST_ENTRY(hookinfo) dlq_le;		/* All active delay qs */
	union		cfg {
		struct linkcfg	link;
	} cfg;
};
typedef struct hookinfo *hook_priv_p;

/* Node private data. */
struct ng_rfee_node_private {
	LIST_HEAD(, hookinfo) bwq_active_head;
	LIST_HEAD(, hookinfo) dlq_active_head;
	struct callout	queue_timer;
	hook_priv_p	epid2hp[MAX_TOTAL_EPIDS];
};
typedef struct ng_rfee_node_private *node_priv_p;

/* Netgraph node methods. */
static ng_constructor_t	ng_rfee_constructor;
static ng_shutdown_t	ng_rfee_shutdown;
static ng_newhook_t	ng_rfee_newhook;
static ng_connect_t	ng_rfee_connect;
static ng_disconnect_t	ng_rfee_disconnect;
static ng_rcvmsg_t	ng_rfee_rcvmsg;
static ng_rcvdata_t	ng_rfee_rcvdata;

/* Link specific rcvdata handlers. */
static int		ng_rfee_link_send(hook_priv_p, struct mbuf *,
			    struct timeval *);
static void		ng_rfee_bwq_dequeue(hook_priv_p, struct timeval *);
static int		ng_rfee_dlq_enqueue(hook_priv_p, struct mbuf *,
			    struct timeval *now, int);
static void		ng_rfee_dlq_dequeue(hook_priv_p, struct timeval *);

/* Callout handler - processes queued mbufs */
static void		ng_rfee_dequeue(node_p, hook_p, void *, int);

/* Node type descriptor. */
static struct ng_type ng_rfee_typestruct = {
	.version =	NG_ABI_VERSION,
	.name =		NG_RFEE_NODE_TYPE,
	.mod_event =	ng_rfee_modevent,
	.constructor =	ng_rfee_constructor,
	.shutdown = 	ng_rfee_shutdown,
	.newhook =	ng_rfee_newhook,
	.connect =	ng_rfee_connect,
	.disconnect =	ng_rfee_disconnect,
	.rcvmsg =	ng_rfee_rcvmsg,
	.rcvdata =	ng_rfee_rcvdata,
	.cmdlist =	ng_rfee_cmds,
};
NETGRAPH_INIT(rfee, &ng_rfee_typestruct);


static int
ng_rfee_constructor(node_p node)
{
	node_priv_p np;

	MALLOC(np, node_priv_p, sizeof(*np), M_NETGRAPH_RFEE,
	    M_NOWAIT | M_ZERO);
	if (np == NULL)
		return (ENOMEM);
	NG_NODE_SET_PRIVATE(node, np);

	/* Allow only a single thread to operate on this node at a time */
	NG_NODE_FORCE_WRITER(node);

	/* Start the timer, triggering on each clock tick */
	ng_callout_init(&np->queue_timer);
	ng_callout(&np->queue_timer, node, NULL, 1, ng_rfee_dequeue, NULL, 0);

	return (0);
}

/*
 * Destroy a node.
 */
static int
ng_rfee_shutdown(node_p node)
{
	node_priv_p np = NG_NODE_PRIVATE(node);

	ng_uncallout(&np->queue_timer, node);
	if (np != NULL)
		FREE(np, M_NETGRAPH_RFEE);
	NG_NODE_SET_PRIVATE(node, NULL);
	NG_NODE_UNREF(node);
	return (0);
}

/*
 * Give our OK for a new hook to be added.  XXX do we need this at all?
 */
static  int
ng_rfee_newhook(node_p node, hook_p hook, const char *name)
{

	return (0);
}

static int
ng_rfee_connect(hook_p hook)
{
	hook_priv_p hp;

	if (strncmp(NG_HOOK_NAME(hook), "link", 4) != 0)
		return (EINVAL);

	MALLOC(hp, hook_priv_p, sizeof(*hp), M_NETGRAPH_RFEE, M_NOWAIT | M_ZERO);
	if (hp == NULL)
		return (ENOMEM);

	struct linkcfg *lcp = &hp->cfg.link;
	lcp->local_epid.epid = EPID_UNASSIGNED;
	TAILQ_INIT(&hp->bwq_head);
	TAILQ_INIT(&hp->dlq_head);

	hp->hook = hook;
	NG_HOOK_SET_PRIVATE(hook, hp);
	return (0);
}

static int
ng_rfee_disconnect(hook_p hook)
{
	hook_priv_p hp = NG_HOOK_PRIVATE(hook);
	struct ngd_hdr *ngd_h, *ngd_h_next;

	/*
	 * hp can be null if an attempt was made to create a hook that was
	 * not a link.
	 */
	if (hp == NULL)
		return (0);

	/* Flush the bandwidth emulation queue */
	TAILQ_FOREACH_SAFE(ngd_h, &hp->bwq_head, ngd_le, ngd_h_next) {
		TAILQ_REMOVE(&hp->bwq_head, ngd_h, ngd_le);
		m_freem(ngd_h->m);
		uma_zfree(ngd_zone, ngd_h);
	}
	/* Flush the delay emulation queue */
	TAILQ_FOREACH_SAFE(ngd_h, &hp->dlq_head, ngd_le, ngd_h_next) {
		TAILQ_REMOVE(&hp->dlq_head, ngd_h, ngd_le);
		m_freem(ngd_h->m);
		uma_zfree(ngd_zone, ngd_h);
	}
	link_unmap(hook);

	FREE(hp, M_NETGRAPH_RFEE);
	NG_HOOK_SET_PRIVATE(hook, NULL);
	return (0);
}

static int
ng_rfee_rcvmsg(node_p node, item_p item, hook_p lasthook)
{
	struct linkcfgreq *lcreq = NULL;
	hook_p hook;
	hook_priv_p hp;
	struct ng_mesg *msg;
	struct ng_mesg *resp = NULL;
	int len, error = 0;

	NGI_GET_MSG(item, msg);
	if (msg->header.typecookie != NGM_RFEE_COOKIE)
		error = EINVAL;
	else {
		switch (msg->header.cmd) {
		case NGM_RFEE_SETLINKCFG:
		case NGM_RFEE_GETLINKCFG:
			lcreq = (struct linkcfgreq *) msg->data;
			hook = ng_findhook(node, lcreq->name);
			if (hook == NULL)
				error = ENOENT;
			break;
		default:
			error = EINVAL;
			break;
		}
	}

	/* Have we found a valid hook? */
	if (error == 0) {
		hp = NG_HOOK_PRIVATE(hook);
		switch (msg->header.cmd) {
		case NGM_RFEE_SETLINKCFG:
			len = msg->header.arglen -
			    offsetof(struct linkcfgreq, cfg);
			if (len < 0 || len > sizeof(lcreq->cfg)) {
				error = EINVAL;
				break;
			}
			link_unmap(hook);
			bcopy(&lcreq->cfg, &hp->cfg.link, len);
			link_map(hook);
			break;
		case NGM_RFEE_GETLINKCFG:
			/* Send back in a response */
			NG_MKRESPONSE(resp, msg, sizeof(*lcreq), M_NOWAIT);
			if (resp == NULL)
				error = ENOMEM;
			else {
				lcreq = (struct linkcfgreq *) resp->data;
				bcopy(&hp->cfg.link, &lcreq->cfg,
				    sizeof(lcreq->cfg));
			}
			break;
		}
	}

	NG_RESPOND_MSG(error, node, item, resp);
	NG_FREE_MSG(msg);
	return (error);
}

/*
 * General data reception handler.
 */
static int
ng_rfee_rcvdata(hook_p hook, item_p item)
{
	node_priv_p np = NG_NODE_PRIVATE(NG_HOOK_NODE(hook));
	hook_priv_p hp = NG_HOOK_PRIVATE(hook);
	struct mbuf *m;
	struct linkcfg *lcp = &hp->cfg.link;
	struct timeval now, *when;
	struct ngd_hdr *ngd_h = NULL;
	uint32_t delay, dd, rnd, jti;

	/* Drop the frame if TX queue is full. */
	if (hp->bwq_frames >= lcp->qlim) {
		NG_FREE_ITEM(item);
		return (ENOBUFS);
	}

	m = NGI_M(item);
	KASSERT(m != NULL, ("NGI_GET_M failed"));

	/* Detach the mbuf from its ng item */
	NGI_M(item) = NULL;

	microuptime(&now);
	/* Bypass queueing alltogether if possible. */
	if (lcp->bw == 0 && lcp->jitter == 0 && lcp->dup == 0 && hp->bwq_frames == 0)
		ng_rfee_link_send(hp, m, &now);
	else {
		/* Queue it. */
		ngd_h = uma_zalloc(ngd_zone, M_NOWAIT);
		KASSERT((ngd_h != NULL), ("ngd_h zalloc failed"));
		ngd_h->m = m;
		if (hp->bwq_frames == 0) {
			when = &hp->bwq_utime;
			if (lcp->bw || lcp->jitter) {
				/* Compute due time for this packet. */
				if (lcp->bw)
					delay = ((uint64_t) m->m_pkthdr.len) *
					    8000000 / lcp->bw;
				else
					delay = 0;
				if (lcp->jitter) {
					rnd = random();
					jti = (rnd >> 24) % jt_size;
					dd = jt[jti].lo +
					    rnd % (jt[jti].hi - jt[jti].lo);
					dd = dd * lcp->wjitter;
					delay += dd;
				}
				when->tv_usec = now.tv_usec + delay;
				when->tv_sec = now.tv_sec +
				    when->tv_usec / 1000000;
				when->tv_usec = when->tv_usec % 1000000;
			}
			LIST_INSERT_HEAD(&np->bwq_active_head, hp, bwq_le);
		}
		TAILQ_INSERT_TAIL(&hp->bwq_head, ngd_h, ngd_le);
		if (hp->bwq_frames++)
			ng_rfee_bwq_dequeue(hp, &now);
	}

	NG_FREE_ITEM(item);
	return (0);
}

/*
 * Dequeue from bandwidth queue and forward all frames that are due by now.
 */
static void
ng_rfee_bwq_dequeue(hook_priv_p hp, struct timeval *now)
{
	struct timeval *when;
	struct linkcfg *lcp;
	struct ngd_hdr *ngd_h, *ngd_h_next;
	struct mbuf *m;
	uint32_t delay, dd, rnd, jti;
	int dup;

	lcp = &hp->cfg.link;
	when = &hp->bwq_utime;
	TAILQ_FOREACH_SAFE(ngd_h, &hp->bwq_head, ngd_le, ngd_h_next) {
		/* Bail out if queue head is not yet due for tx. */
		if (now->tv_sec < when->tv_sec)
			break;
		else if (now->tv_sec == when->tv_sec &&
		    now->tv_usec < when->tv_usec)
			break;

		/* Leave a duplicate of this packet in the queue? */
		dup = (lcp->dup && random() % 1000 <= lcp->dup);

		/* Compute due time for next pkt in queue. */
		if ((lcp->bw || lcp->jitter) && ngd_h_next != NULL) {
			if (dup)
				m = ngd_h->m;
			else
				m = ngd_h_next->m;
			if (lcp->bw)
				delay = ((uint64_t) m->m_pkthdr.len) *
				    8000000 / lcp->bw;
			else
				delay = 0;
			if (lcp->jitter) {
				rnd = random();
				jti = (rnd >> 24) % jt_size;
				dd = jt[jti].lo +
				    rnd % (jt[jti].hi - jt[jti].lo);
				dd = dd * lcp->wjitter;
				delay += dd;
			}
			when->tv_usec += delay;
			when->tv_sec += when->tv_usec / 1000000;
			when->tv_usec = when->tv_usec % 1000000;
		}

		/* Dequeue pkt, send it, and free the descriptor. */
		if (dup) {
			/* Send a duplicate, not the original. */
			m = m_dup(ngd_h->m, M_NOWAIT);
			if (m != NULL)
				ng_rfee_link_send(hp, m, now);
		} else {
			ng_rfee_link_send(hp, ngd_h->m, now);
			TAILQ_REMOVE(&hp->bwq_head, ngd_h, ngd_le);
			hp->bwq_frames--;
			uma_zfree(ngd_zone, ngd_h);
		}
	}
	if (hp->bwq_frames == 0)
		LIST_REMOVE(hp, bwq_le);
}

/*
 * Forward a frame received on link hook or dequeued from bandwidth queue.
 */
static int
ng_rfee_link_send(hook_priv_p hp, struct mbuf *m, struct timeval *now)
{
	node_priv_p np = NG_NODE_PRIVATE(NG_HOOK_NODE(hp->hook));
	hook_priv_p dsthp;
	struct linkcfg *lcp = &hp->cfg.link;
	struct mbuf *m2;
	int error = 0;
	int i;
	static uint64_t oldrand, rand;

	if (!(m->m_flags & M_PKTHDR)) {
		printf("ouch, M_PKTHDR not set!?\n");
		m_freem(m);
		return (ENOBUFS);
	}

	/* Deliver the packet to link hooks, if any. */
	for (i = 0; i < lcp->epidcnt; i++) {
		dsthp = np->epid2hp[lcp->epids[i].epid];
		if (dsthp == NULL)
			continue;

		/* Drop in accordance with the BER tag. */
		if (lcp->epids[i].ber.m != 0) {
			oldrand = rand;
			rand = random();
			if ((oldrand ^ (rand << 17)) >=
			    ber_p[lcp->epids[i].ber.e][lcp->epids[i].ber.m][
			    m->m_pkthdr.len])
				continue;
		}

		/* XXX would m_copypacket() be safe here? */
		if ((m2 = m_dup(m, M_DONTWAIT)) == NULL) {
			error = ENOBUFS;
			break;
		}

		ng_rfee_dlq_enqueue(dsthp, m2, now, lcp->epids[i].delay);
	}

	/* We must free the original mbuf since it was never consumed. */
	m_freem(m);

	return (error);
}

/*
 * Enqueue a packet in delay queue, or send it immediately if delay == 0.
 */
static int
ng_rfee_dlq_enqueue(hook_priv_p hp, struct mbuf *m, struct timeval *now,
    int delay)
{
	node_priv_p np = NG_NODE_PRIVATE(NG_HOOK_NODE(hp->hook));
	int error = 0;
	struct ngd_hdr *ngd_h;

	if (delay == 0) {
		NG_SEND_DATA_ONLY(error, hp->hook, m);
		return (error);
	}
	delay = delay * 100 - 50; /* internal to usec conversion */

	ngd_h = uma_zalloc(ngd_zone, M_NOWAIT);
	KASSERT((ngd_h != NULL), ("ngd_h zalloc failed"));
	ngd_h->m = m;

	/* Compute due time for this packet. */
	ngd_h->when.tv_usec = now->tv_usec + delay;
	ngd_h->when.tv_sec = now->tv_sec + ngd_h->when.tv_usec / 1000000;
	ngd_h->when.tv_usec = ngd_h->when.tv_usec % 1000000;

	TAILQ_INSERT_TAIL(&hp->dlq_head, ngd_h, ngd_le);
	if (hp->dlq_frames == 0)
		LIST_INSERT_HEAD(&np->dlq_active_head, hp, dlq_le);
	if (hp->dlq_frames++)
		ng_rfee_dlq_dequeue(hp, now);

	return (0);
}

/*
 * Dequeue from delay queue and forward all frames that are due by now.
 */
static void
ng_rfee_dlq_dequeue(hook_priv_p hp, struct timeval *now)
{
	struct linkcfg *lcp;
	struct ngd_hdr *ngd_h, *ngd_h_next;
	int error;

	lcp = &hp->cfg.link;
	TAILQ_FOREACH_SAFE(ngd_h, &hp->dlq_head, ngd_le, ngd_h_next) {
		/* Bail out if queue head is not yet due for tx. */
		if (now->tv_sec < ngd_h->when.tv_sec)
			break;
		else if (now->tv_sec == ngd_h->when.tv_sec &&
		    now->tv_usec < ngd_h->when.tv_usec)
			break;

		/* Dequeue pkt, send it, and free the descriptor. */
		NG_SEND_DATA_ONLY(error, hp->hook, ngd_h->m);
		TAILQ_REMOVE(&hp->dlq_head, ngd_h, ngd_le);
		hp->dlq_frames--;
		uma_zfree(ngd_zone, ngd_h);
	}
	if (hp->dlq_frames == 0)
		LIST_REMOVE(hp, dlq_le);
}

static void
ng_rfee_dequeue(node_p node, hook_p hook, void *arg1, int arg2)
{
        node_priv_p np = NG_NODE_PRIVATE(node);
	hook_priv_p hp, hp_next;
	struct timeval now;

	microuptime(&now);
	LIST_FOREACH_SAFE(hp, &np->bwq_active_head, bwq_le, hp_next)
		ng_rfee_bwq_dequeue(hp, &now);
	LIST_FOREACH_SAFE(hp, &np->dlq_active_head, dlq_le, hp_next)
		ng_rfee_dlq_dequeue(hp, &now);

	ng_callout(&np->queue_timer, node, NULL, 1, ng_rfee_dequeue, NULL, 0);
}


/*
 * Cfg parsing routines.
 */
static int
ng_rfee_linkcfg_parse(const struct ng_parse_type *type, const char *s, int *off,
    const u_char *const start, u_char *const buf, int *buflen)
{
	struct linkcfgreq *lcreq = (struct linkcfgreq *) buf;
	int i = *off;
	int last = strlen(s);
	int blen = offsetof(struct linkcfgreq, cfg) + offsetof(struct linkcfg, epids);
	int ber_e, ber_m;

	bzero(buf, blen);

	/* First token -> hook name */
	while (!isspace(s[i]) && i < last)
		i++;
	bcopy(&s[*off], &lcreq->name, i - *off);
	lcreq->cfg.qlim = DEFAULT_TX_QLIM;

	while (isspace(s[i]) && i < last)
		i++;
	*off = i;

	/* second token -> local EPID */
	while (isdigit(s[i]) && i < last)
		i++;

	lcreq->cfg.local_epid.epid = strtol(&s[*off], NULL, 10);
	/* Extended attributes may follow after a ":" sign */
	while (s[i] == ':') {
		i++;
		if (s[i] == 'b' || s[i] == 'B') {
			/* 'b' for TX bandwidth */
			while (!isdigit(s[i]) && i < last)
				i++;
			*off = i;
			while (isdigit(s[i]) && i < last)
				i++;
			lcreq->cfg.bw = strtol(&s[*off], NULL, 10);
		} else if (s[i] == 'q' || s[i] == 'Q') {
			/* 'q' for TX queue length limit */
			while (!isdigit(s[i]) && i < last)
				i++;
			*off = i;
			while (isdigit(s[i]) && i < last)
				i++;
			lcreq->cfg.qlim = strtol(&s[*off], NULL, 10);
		} else if (s[i] == 'j' || s[i] == 'J') {
			/* 'j' for TX delay jitter */
			while (!isdigit(s[i]) && i < last)
				i++;
			*off = i;
			while (isdigit(s[i]) && i < last)
				i++;
			lcreq->cfg.jitter = strtol(&s[*off], NULL, 10) * 1000;
			lcreq->cfg.wjitter = lcreq->cfg.jitter / jt_avg;
			if (s[i] != '.')
				continue;
			i++;
			if (!isdigit(s[i]))
				return (EINVAL);
			lcreq->cfg.jitter += (s[i] - '0') * 100;
			lcreq->cfg.wjitter = lcreq->cfg.jitter / jt_avg;
			i++;
		} else if (s[i] == 'd' || s[i] == 'D') {
			/* 'd' for TX packet duplication probability */
			while (!isdigit(s[i]) && i < last)
				i++;
			*off = i;
			while (isdigit(s[i]) && i < last)
				i++;
			lcreq->cfg.dup = strtol(&s[*off], NULL, 10) * 10;
			if (lcreq->cfg.dup > DUP_MAX)
				lcreq->cfg.dup = DUP_MAX;
			if (s[i] != '.')
				continue;
			i++;
			if (!isdigit(s[i]))
				return (EINVAL);
			lcreq->cfg.dup += (s[i] - '0');
			if (lcreq->cfg.dup > DUP_MAX)
				lcreq->cfg.dup = DUP_MAX;
			i++;
		} else
			return (EINVAL);
	}
	while (isspace(s[i]) && i < last)
		i++;
	*off = i;

	/* remaining token(s) -> target EPID list */
	do {
		while (isdigit(s[i]) && i < last)
			i++;

		/* Bail out if no digits encountered */
		if (*off == i)
			break;

		lcreq->cfg.epids[lcreq->cfg.epidcnt].epid =
		    strtol(&s[*off], NULL, 10);

		/* Extended attributes may follow after a ":" sign */
		while (s[i] == ':') {
			i++;
			if (s[i] == 'b' || s[i] == 'B') {
				/* 'b' for BER */
				while (!isdigit(s[i]) && i < last)
					i++;
				*off = i;
				if (s[i] != '0' && i < last) {
					ber_m = s[i] - '0';
					i++;
					if ((s[i] != 'e' && s[i] != 'E') ||
					    i >= last)
						return (EINVAL);
					i++;
					if (s[i] != '-' || i >= last)
						return (EINVAL);
					i++;
					if (s[i] == '0')
						i++;
					if (!isdigit(s[i]) || s[i] == '0' ||
					    i >= last)
						return (EINVAL);
					ber_e = strtol(&s[i], NULL, 10) - 1;
					while (isdigit(s[i]) && i < last)
						i++;
					*off = i;
					if (ber_e >= BER_E_MAX)
						return (EINVAL);
					lcreq->cfg.epids[
					    lcreq->cfg.epidcnt].ber.m = ber_m;
					lcreq->cfg.epids[
					    lcreq->cfg.epidcnt].ber.e = ber_e;
					continue;
				}
				while (s[i] == '0' && i < last)
					i++;
				if (s[i] != '.' || i >= last)
					return (EINVAL);
				i++;
				while (s[i] == '0' && i < last) {
					lcreq->cfg.epids[
					    lcreq->cfg.epidcnt].ber.e++;
					i++;
				}
				if (!isdigit(s[i]) && i >= last)
					return (EINVAL);
				if (isdigit(s[i]))
					lcreq->cfg.epids[
					    lcreq->cfg.epidcnt].ber.m =
					    s[i] - '0';
				if (lcreq->cfg.epids[
				    lcreq->cfg.epidcnt].ber.e >= BER_E_MAX)
					return (EINVAL);
				while (isdigit(s[i]) && i < last)
					i++;
			} else if (s[i] == 'd' || s[i] == 'D') {
				/* 'd' for delay */
				while (!isdigit(s[i]) && i < last)
					i++;
				*off = i;
				while (isdigit(s[i]) && i < last)
					i++;
				lcreq->cfg.epids[lcreq->cfg.epidcnt].delay =
				    strtol(&s[*off], NULL, 10) * 10;
				if (s[i] != '.')
					continue;
				i++;
				if (!isdigit(s[i]))
					continue;
				lcreq->cfg.epids[lcreq->cfg.epidcnt].delay +=
				    (s[i] - '0');
				i++;
			} else
				return (EINVAL);
		}

		if (lcreq->cfg.epids[lcreq->cfg.epidcnt].epid
		    < EPID_UNASSIGNED &&
		    lcreq->cfg.epids[lcreq->cfg.epidcnt].epid !=
		    lcreq->cfg.local_epid.epid) {
			blen += sizeof(epid_t); /* XXX */
			if (blen > *buflen)
				return(ENOMEM);
			lcreq->cfg.epidcnt++;
		}
		while (!isdigit(s[i]) && i < last)
			i++;
		*off = i;
	} while (!isspace(s[i]) && i < last);

	*buflen = blen;
	return (0);
}

static int
ng_rfee_linkcfg_unparse(const struct ng_parse_type *type, const u_char *data,
     int *off, char *cbuf, int cbuflen)
{
	const struct linkcfgreq *lcreq = (const struct linkcfgreq *) (data + *off);
	int i;

	if (lcreq->cfg.local_epid.epid == EPID_UNASSIGNED)
		return (0);

	cbuf += sprintf(cbuf, "%d", lcreq->cfg.local_epid.epid);
	if (lcreq->cfg.bw != 0)
		cbuf += sprintf(cbuf, ":bw%d", lcreq->cfg.bw);
	if (lcreq->cfg.qlim != DEFAULT_TX_QLIM)
		cbuf += sprintf(cbuf, ":qlen%d", lcreq->cfg.qlim);
	if (lcreq->cfg.jitter != 0) {
		cbuf += sprintf(cbuf, ":jit%d", lcreq->cfg.jitter / 1000);
		if (lcreq->cfg.jitter % 1000 != 0)
			cbuf += sprintf(cbuf, ".%d", (lcreq->cfg.jitter % 1000) / 100);
	}
	if (lcreq->cfg.dup != 0) {
		cbuf += sprintf(cbuf, ":dup%d", lcreq->cfg.dup / 10);
		if (lcreq->cfg.dup % 10 != 0)
			cbuf += sprintf(cbuf, ".%d", lcreq->cfg.dup % 10);
	}
	for (i = 0; i < lcreq->cfg.epidcnt; i++) {
		if (i == 0)
			cbuf += sprintf(cbuf, " ");
		cbuf += sprintf(cbuf, "%d", lcreq->cfg.epids[i].epid);
		if (lcreq->cfg.epids[i].ber.m != 0) {
			cbuf += sprintf(cbuf, ":ber%dE-%d",
			    lcreq->cfg.epids[i].ber.m, lcreq->cfg.epids[i].ber.e + 1);
		}
		if (lcreq->cfg.epids[i].delay != 0) {
			cbuf += sprintf(cbuf, ":dly%d",
			    lcreq->cfg.epids[i].delay / 10);
			if (lcreq->cfg.epids[i].delay % 10 != 0)
				cbuf += sprintf(cbuf, ".%d",
				    lcreq->cfg.epids[i].delay % 10);
		}
		if (i != lcreq->cfg.epidcnt - 1)
			cbuf += sprintf(cbuf, " ");
	}
	*off += sizeof(struct linkcfgreq);

	return (0);
}


static void
link_unmap(hook_p hook)
{
	node_priv_p np = NG_NODE_PRIVATE(NG_HOOK_NODE(hook));
	hook_priv_p hp = NG_HOOK_PRIVATE(hook);
	struct linkcfg *lcp = &hp->cfg.link;

	if (lcp->local_epid.epid < EPID_UNASSIGNED)
		np->epid2hp[lcp->local_epid.epid] = NULL;
}

static void
link_map(hook_p hook)
{
	node_p node = NG_HOOK_NODE(hook);
	node_priv_p np = NG_NODE_PRIVATE(node);
	hook_priv_p hp = NG_HOOK_PRIVATE(hook);
	struct linkcfg *lcp = &hp->cfg.link;

	if (lcp->local_epid.epid == EPID_UNASSIGNED)
		return;	/* XXX should return an error */

	np->epid2hp[lcp->local_epid.epid] = hp;
}

static void
set_ber_p(int e, int m)
{
	static const uint64_t one = 0x1000000000000; /* = 2^48 */
	uint64_t p0, p;
	uint32_t plen, i;

	/*
	 * For a given BER and each frame size N (in bytes) calculate
	 * the probability P_OK that the frame is clean:
	 *
	 * P_OK(BER,N) = (1 - BER) ^ (N * 8)
	 *
	 * We use a 64-bit fixed-point format with decimal point
	 * positioned between bits 47 and 48.
	 */
	p = one * m / 10;
	for (i = 0; i < e; i++)
		p /= 10;
	p0 = one - p;
	p = one;
	for (plen = 0; plen < BER_PLEN_MAX; plen++) {
		ber_p[e][m][plen] = p;
		for (i = 0; i < 8; i++)
			p = (p*(p0&0xffff)>>48) + \
			    (p*((p0>>16)&0xffff)>>32) + \
			    (p*(p0>>32)>>16);
	}
}

static int
ng_rfee_modevent(module_t mod, int type, void *unused)
{
	int error = 0;
	int m, e;
                
	switch (type) {
	case MOD_LOAD:
		ngd_zone = uma_zcreate("ng_rfee", sizeof(struct ngd_hdr),
		    NULL, NULL, NULL, NULL, UMA_ALIGN_PTR, 0);
		if (ngd_zone == NULL)
			panic("ng_rfee: couldn't allocate descriptor zone");

		/* Compute jitter table size and average */
		for (jt_size = 0, jt_avg = 0; jt[jt_size].lo != jt[jt_size].hi;
		    jt_size++)
			jt_avg += (jt[jt_size].lo + jt[jt_size].hi);
		jt_avg = jt_avg / (jt_size * 2);

		/* Populate the BER lookup table */
		for (e = 0; e < BER_E_MAX; e++)
			for (m = 1; m < 10; m++)
				set_ber_p(e, m);
		break;

	case MOD_UNLOAD:
		uma_zdestroy(ngd_zone);
		break;

	default:
		error = EOPNOTSUPP;
		break;
	}

	return (error);
}
