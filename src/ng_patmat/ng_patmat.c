/*
 * ng_patmat.c
 */


#include <sys/param.h>
#include <sys/ctype.h>
#include <sys/systm.h>
#include <sys/errno.h>
#include <sys/kernel.h>
#include <sys/malloc.h>
#include <sys/mbuf.h>

#include <netgraph/ng_message.h>
#include <netgraph/netgraph.h>
#include <netgraph/ng_parse.h>

#define NG_PM_NODE_TYPE		"patmat"
#define	NGM_PM_COOKIE		201111081

#define	NG_PM_MAXRULES		128
#define	NG_PM_MAXPATLEN		32

#ifndef M_DONTWAIT
#define M_DONTWAIT M_NOWAIT
#endif

MALLOC_DEFINE(M_NETGRAPH_PM, "ng_patmat", "ng_patmat");

#ifndef MALLOC
#define MALLOC(space, cast, size, type, flags) \
 ((space) = (cast)malloc((u_long)(size), (type), (flags)))
#define FREE(addr, type) free((addr), (type))
#endif


/* Netgraph methods */
static ng_constructor_t	ng_pm_constructor;
static ng_rcvmsg_t	ng_pm_rcvmsg;
static ng_shutdown_t	ng_pm_shutdown;
static ng_newhook_t	ng_pm_newhook;
static ng_rcvdata_t	ng_pm_rcvdata;
static ng_disconnect_t	ng_pm_disconnect;

/* Control message parser / unparser */
static int ng_pm_hookcfg_parse(const struct ng_parse_type *,
    const char *, int *, const u_char *const, u_char *const, int *);
static int ng_pm_hookcfg_unparse(const struct ng_parse_type *,
    const u_char *, int *, char *, int);

/* Netgraph commands. */
enum {
	NGM_PM_SETHOOKCFG = 1,
	NGM_PM_GETHOOKCFG,
};

enum {
	NGM_PM_ACTION_NONE = 0,
	NGM_PM_ACTION_MATCH_HOOK,
	NGM_PM_ACTION_NOMATCH_HOOK,
	NGM_PM_ACTION_MATCH_DUPTO,
	NGM_PM_ACTION_NOMATCH_DUPTO,
	NGM_PM_ACTION_MATCH_SKIPTO,
	NGM_PM_ACTION_NOMATCH_SKIPTO,
	NGM_PM_ACTION_MATCH_DROP,
	NGM_PM_ACTION_NOMATCH_DROP,
};

static struct actions {
	int	action_id;
	char	*action_name;
} actions[] = {
	{ NGM_PM_ACTION_MATCH_HOOK, 	"match_hook" },
	{ NGM_PM_ACTION_NOMATCH_HOOK, 	"nomatch_hook" },
	{ NGM_PM_ACTION_MATCH_DUPTO, 	"match_dupto" },
	{ NGM_PM_ACTION_NOMATCH_DUPTO, 	"nomatch_dupto" },
	{ NGM_PM_ACTION_MATCH_SKIPTO, 	"match_skipto" },
	{ NGM_PM_ACTION_NOMATCH_SKIPTO,	"nomatch_skipto" },
	{ NGM_PM_ACTION_MATCH_DROP, 	"match_drop" },
	{ NGM_PM_ACTION_NOMATCH_DROP,	"nomatch_drop" },
	{ NGM_PM_ACTION_NONE, 		NULL }
};

/*
 * Possible rule syntax:
 *
 * 10:match_hook:aa.bb.cc.dd/ff.00.ff.00@10.10:hook_name
 * 20:match_skipto:aa.bb.cc.dd/ff.00.ff.00@10:rule_number
 * 30:match_drop:aa.bb.cc.dd/ff.00.ff.00@10:
 * 40:match_hook::hook_name
 */
struct ng_pm_rule {
	uint32_t	prob;
	uint16_t	rule_number;
	uint16_t	action;
	uint16_t	p_off_lo;
	uint16_t	p_off_hi;
	uint16_t	p_len;
	uint16_t	spare;
	union {
		char	hname[NG_HOOKSIZ];
		hook_p	hp;
		int	skipto_index;
		int	skipto_rule_number;
	}		asdata;
	char		pattern[NG_PM_MAXPATLEN];
	char		mask[NG_PM_MAXPATLEN];
};
typedef struct ng_pm_rule ng_pm_rule_t;

/* Per-hook configuration */
struct ng_pm_hookcfg {
	int		rules;
	int		maxcontig;
	ng_pm_rule_t	rule[NG_PM_MAXRULES];
};
typedef struct ng_pm_hookcfg ng_pm_hookcfg_t;
typedef struct ng_pm_hookcfg *ng_pm_hookcfg_p;

struct ng_pm_hookcfgreq {
	char		name[NG_HOOKSIZ];
	ng_pm_hookcfg_t	cfg;
};
typedef struct ng_pm_hookcfgreq ng_pm_hookcfgreq_t;

/* Parse type for hook configuration. */
static const struct ng_parse_type ng_pm_hookcfg_type = {
	.parse =	&ng_pm_hookcfg_parse,
	.unparse =	&ng_pm_hookcfg_unparse,
};

/* List of commands and how to convert arguments to/from ASCII. */
static const struct ng_cmdlist ng_pm_cmds[] = {
        { 
		.cookie =       NGM_PM_COOKIE,
		.cmd =          NGM_PM_SETHOOKCFG,
		.name =         "shc",
		.mesgType =     &ng_pm_hookcfg_type,
		.respType =     NULL
	},
        { 
		.cookie =       NGM_PM_COOKIE,
		.cmd =          NGM_PM_GETHOOKCFG,
		.name =         "ghc",
		.mesgType =     &ng_pm_hookcfg_type,
		.respType =     &ng_pm_hookcfg_type,
	},
	{ 0 }
};

/* Netgraph type descriptor */
static struct ng_type typestruct = {
	.version =	NG_ABI_VERSION,
	.name =		NG_PM_NODE_TYPE,
	.constructor =	ng_pm_constructor,
	.rcvmsg =	ng_pm_rcvmsg,
	.shutdown =	ng_pm_shutdown,
	.newhook =	ng_pm_newhook,
	.rcvdata =	ng_pm_rcvdata,
	.disconnect =	ng_pm_disconnect,
	.cmdlist =	ng_pm_cmds,
};
NETGRAPH_INIT(pm, &typestruct);


static void
ng_pm_clear_config(node_p node)
{
	hook_p hi;
	ng_pm_hookcfg_p hcp;

	LIST_FOREACH(hi, &node->nd_hooks, hk_hooks) {
		hcp = NG_HOOK_PRIVATE(hi);
		hcp->rules = 0;
	}
}

/*
 * Cfg parsing routines.
 */ 
static int
ng_pm_hookcfg_parse(const struct ng_parse_type *type, const char *s, int *off,
    const u_char *const start, u_char *const buf, int *buflen)
{
	ng_pm_hookcfgreq_t *hcreq = (ng_pm_hookcfgreq_t *) buf;
	ng_pm_hookcfg_t *hc = &hcreq->cfg;
	int i = *off;
	int last = strlen(s);
	int blen = sizeof(ng_pm_hookcfgreq_t);
	int rules = 0;
	int last_rule_number = 0;
	int p_len;
	int j;

	if (blen > *buflen)
		return(ENOMEM);

	bzero(buf, blen);

	*buflen = blen;
	/* First token should be a valid hook name */
	while (!isspace(s[i]) && i < last)
		i++;
	bcopy(&s[*off], &hcreq->name, i - *off);

	/* Skip whitespace */
	while (isspace(s[i]) && i < last)
		i++;
	*off = i;

	/* Remaining token(s) should be filtering rules */
	for (; i < last;) {
		/* Parse rule number */
		while (isdigit(s[i]) && i < last)
			i++;

		/* Bail out if no digits encountered */
		if (*off == i || s[i++] != ':')
			return(EINVAL);
                         
		hc->rule[rules].rule_number =
		    strtol(&s[*off], NULL, 10);

		/* Bail out if rule numbers are not monotonically increasing */
		if (hc->rule[rules].rule_number <= last_rule_number)
			return(EINVAL);
		last_rule_number = hc->rule[rules].rule_number;

		/* Parse action keyword */
		*off = i;
		while ((isalpha(s[i]) || s[i] == '_') && i < last)
			i++;
		if (s[i] != ':')
			return(EINVAL);

		for (j = 0; actions[j].action_name != NULL; j++) {
			if (strncmp(&s[*off], actions[j].action_name,
			    max(i - *off, strlen(actions[j].action_name)))
			    == 0)
				break;
		}
		if (i++ >= last)
			return(EINVAL);
		*off = i;
		hc->rule[rules].action = actions[j].action_id;

		/* Parse pattern, mask and offset(s) */
		if (s[i] == ':') {
			/* Pattern and offsets are already bzero()ed here */
		} else {
			/* Pattern */
			p_len = 0;
			do {
				if (i + 3 > last || !isxdigit(s[i]) ||
				    !isxdigit(s[i + 1]))
					return(EINVAL);
				sscanf(&s[i], "%02x*[./]", &j);
				hc->rule[rules].pattern[p_len++] = j;
				i += 3;
			} while (s[i - 1] == '.');
			hc->rule[rules].p_len = p_len;
			if (s[i - 1] != '/')
				return(EINVAL);
			/* Mask */
			p_len = 0;
			do {
				if (i + 3 > last || !isxdigit(s[i]) ||
				    !isxdigit(s[i + 1]))
					return(EINVAL);
				sscanf(&s[i], "%02x*[.@]", &j);
				hc->rule[rules].mask[p_len++] = j;
				i += 3;
			} while (s[i - 1] == '.');
			if (s[i - 1] != '@' || !isdigit(s[i]) ||
			    hc->rule[rules].p_len != p_len)
				return(EINVAL);
			/* Offset(s) */
			*off = i;
			while (isdigit(s[i]) && i < last)
				i++;
			if (*off == i || i >= last)
				return(EINVAL);
			hc->rule[rules].p_off_lo = strtol(&s[*off], NULL, 10);
			if (s[i] != '.')
				hc->rule[rules].p_off_hi =
				    hc->rule[rules].p_off_lo;
			else {
				while (s[i] == '.' && i < last)
					i++;
				if (i >= last)
					return(EINVAL);
				*off = i;
				while (isdigit(s[i]) && i < last)
					i++;
				if (*off == i || i >= last)
					return(EINVAL);
				hc->rule[rules].p_off_hi =
				    strtol(&s[*off], NULL, 10);
			}
			if (s[i] != ':')
				return(EINVAL);
		}
		i++;
		if (i > last)
			return(EINVAL);
		*off = i;

		/* Update maxcontig */
		j = hc->rule[rules].p_off_hi + hc->rule[rules].p_len;
		if (j > hc->maxcontig)
			hc->maxcontig = j;

		/* Action-specific target (hook or rule) */
		switch (hc->rule[rules].action) {
		case NGM_PM_ACTION_MATCH_HOOK:
		case NGM_PM_ACTION_NOMATCH_HOOK:
		case NGM_PM_ACTION_MATCH_DUPTO:
		case NGM_PM_ACTION_NOMATCH_DUPTO:
			while (!isspace(s[i]) && i < last)
				i++;
			if (*off == i || (i - *off) > NG_HOOKSIZ)
				return(EINVAL);
			bcopy(&s[*off], &hc->rule[rules].asdata.hname,
			    i - *off);
			hc->rule[rules].asdata.hname[i - *off] = 0;
			break;
		case NGM_PM_ACTION_MATCH_SKIPTO:
		case NGM_PM_ACTION_NOMATCH_SKIPTO:
			while (isdigit(s[i]) && i < last)
				i++;
			if (*off == i)
				return(EINVAL);
			hc->rule[rules].asdata.skipto_rule_number =
			    strtol(&s[*off], NULL, 10);
			break;
		case NGM_PM_ACTION_MATCH_DROP:
		case NGM_PM_ACTION_NOMATCH_DROP:
			/* Nothing to parse here */
			break;
		default:
			/* Bail out if action keyword is unknown */
			return(EINVAL);
		}

		/* Skip whitespace (if any) */
		while (isspace(s[i]) && i < last)
			i++;
		*off = i;
		rules++;
	};
	hc->rules = rules;

	return (0);
}

static int
ng_pm_hookcfg_unparse(const struct ng_parse_type *type, const u_char *data,
    int *off, char *cbuf, int cbuflen)
{
	const ng_pm_hookcfgreq_t *hcreq =
	    (const ng_pm_hookcfgreq_t *) (data + *off);
	const ng_pm_hookcfg_t *hc = &hcreq->cfg;
	int i, j;

        cbuf += sprintf(cbuf, "%s", hcreq->name);

	for (i = 0; i < hc->rules; i++) {
		/* Rule number */
		cbuf += sprintf(cbuf, " %d:", hc->rule[i].rule_number);

		/* Action */
		for (j = 0; actions[j].action_name != NULL; j++) {
			if (actions[j].action_id ==
			    hc->rule[i].action) {
				cbuf += sprintf(cbuf, "%s:",
				    actions[j].action_name);
				break;
			}
		}

		/* Pattern, mask, offset(s) */
		for (j = 0; j < hc->rule[i].p_len; j++) {
			cbuf += sprintf(cbuf, "%02x",
			    hc->rule[i].pattern[j] & 0xff);
			if (j < hc->rule[i].p_len - 1)
				*cbuf++ = '.';
		}
		if (hc->rule[i].p_len)
			*cbuf++ = '/';
		for (j = 0; j < hc->rule[i].p_len; j++) {
			cbuf += sprintf(cbuf, "%02x",
			    hc->rule[i].mask[j] & 0xff);
			if (j < hc->rule[i].p_len - 1)
				*cbuf++ = '.';
		}
		if (hc->rule[i].p_len) {
			cbuf += sprintf(cbuf, "@%d", hc->rule[i].p_off_lo);
			if (hc->rule[i].p_off_lo != hc->rule[i].p_off_hi)
				cbuf += sprintf(cbuf, "..%d",
				    hc->rule[i].p_off_hi);
		}
		*cbuf++ = ':';

		/* Action-specific target (hook or rule) */
		switch (hc->rule[i].action) {
		case NGM_PM_ACTION_MATCH_HOOK:
		case NGM_PM_ACTION_NOMATCH_HOOK:
		case NGM_PM_ACTION_MATCH_DUPTO:
		case NGM_PM_ACTION_NOMATCH_DUPTO:
			cbuf += sprintf(cbuf, "%s",
			    hc->rule[i].asdata.hname);
			break;
		case NGM_PM_ACTION_MATCH_SKIPTO:
		case NGM_PM_ACTION_NOMATCH_SKIPTO:
			j = hc->rule[i].asdata.skipto_index;
			cbuf += sprintf(cbuf, "%d", hc->rule[j].rule_number);
			break;
		case NGM_PM_ACTION_MATCH_DROP:
		case NGM_PM_ACTION_NOMATCH_DROP:
			/* Nothing to unparse here */
			break;
		default:
			/* Bail out if action keyword is unknown */
			return(EINVAL);
		}

	}

	*off += sizeof(*hcreq);

	return (0);
}

static int
ng_pm_constructor(node_p node)
{

	NG_NODE_SET_PRIVATE(node, NULL);
	return (0);
}

static int
ng_pm_newhook(node_p node, hook_p hook, const char *name)
{
	ng_pm_hookcfg_p hcp;

	MALLOC(hcp, ng_pm_hookcfg_p, sizeof(*hcp), M_NETGRAPH_PM,
            M_NOWAIT | M_ZERO);
	if (hcp == NULL)
		return (ENOMEM);

	NG_HOOK_SET_PRIVATE(hook, hcp);
	ng_pm_clear_config(node);
	return (0);
}

static int
ng_pm_rcvmsg(node_p node, item_p item, hook_p lasthook)
{
	ng_pm_hookcfgreq_t *hcreq = NULL;
	struct ng_mesg *msg;
	struct ng_mesg *resp = NULL;
	hook_p hook = NULL;
	ng_pm_hookcfg_p hcp;
	int i, j, len, error = 0;
 
	NGI_GET_MSG(item, msg);
	if (msg->header.typecookie != NGM_PM_COOKIE)
		error = EINVAL;
	else {
		switch (msg->header.cmd) {
		case NGM_PM_SETHOOKCFG:
		case NGM_PM_GETHOOKCFG:
			hcreq = (ng_pm_hookcfgreq_t *) msg->data;
			hook = ng_findhook(node, hcreq->name);
			if (hook == NULL)
				error = ENOENT;
			break;
		default:
			error = EINVAL;
			break;
		}
	}
	if (error)
		goto done;

	/* We have a valid target hook here... */
	hcp = NG_HOOK_PRIVATE(hook);
	switch (msg->header.cmd) {
	case NGM_PM_SETHOOKCFG:
		len = msg->header.arglen -
		    offsetof(ng_pm_hookcfgreq_t, cfg);
		/* XXX exact match for len? */
		if (len < 0 || len > sizeof(hcreq->cfg)) {
			error = EINVAL;
			break;
		}
		/* Map hook names to pointers and rule numbers to indices */
		for (i = 0; i < hcreq->cfg.rules; i++) {
			switch (hcreq->cfg.rule[i].action) {
			case NGM_PM_ACTION_MATCH_HOOK:
			case NGM_PM_ACTION_NOMATCH_HOOK:
			case NGM_PM_ACTION_MATCH_DUPTO:
			case NGM_PM_ACTION_NOMATCH_DUPTO:
				hook = ng_findhook(node,
				    hcreq->cfg.rule[i].asdata.hname);
				if (hook == NULL) {
					error = ENOENT;
					goto done;
				}
				hcreq->cfg.rule[i].asdata.hp = hook;
				break;
			case NGM_PM_ACTION_MATCH_SKIPTO:
			case NGM_PM_ACTION_NOMATCH_SKIPTO:
				error = ENOENT;
				for (j = i + 1; j < hcreq->cfg.rules; j++) {
					if (hcreq->cfg.rule[i].asdata.
					    skipto_rule_number ==
					    hcreq->cfg.rule[j].rule_number) {
						error = 0;
						break;
					}
				}
				if (error)
					goto done;
				hcreq->cfg.rule[i].asdata.skipto_index = j;
				break;
			default:
				break;
			}
		}
		bcopy(&hcreq->cfg, hcp, sizeof(hcreq->cfg));
		break;
	case NGM_PM_GETHOOKCFG:
		NG_MKRESPONSE(resp, msg, sizeof(*hcp), M_NOWAIT);
		if (resp == NULL)
			error = ENOMEM;
		else {
			hcreq = (ng_pm_hookcfgreq_t *) resp->data;
			sprintf(hcreq->name, "%s", NG_HOOK_NAME(hook));
			bcopy(hcp, &hcreq->cfg, sizeof(hcreq->cfg));
			/* Translate hook pointers to hook names */
			for (i = 0; i < hcreq->cfg.rules; i++) {
				switch (hcreq->cfg.rule[i].action) {
				case NGM_PM_ACTION_MATCH_HOOK:
				case NGM_PM_ACTION_NOMATCH_HOOK:
				case NGM_PM_ACTION_MATCH_DUPTO:
				case NGM_PM_ACTION_NOMATCH_DUPTO:
					hook = hcreq->cfg.rule[i].asdata.hp;
					sprintf(hcreq->cfg.rule[i].asdata.hname,
					    "%s", NG_HOOK_NAME(hook));
				default:
					break;
				}
			}
		}
		break;
	default:
		error = EINVAL;
		break;
	}

done:
	NG_RESPOND_MSG(error, node, item, resp);
	NG_FREE_MSG(msg);
	return (error);
}

static int
ng_pm_rcvdata(hook_p hook, item_p item)
{
	ng_pm_hookcfg_p hcp = NG_HOOK_PRIVATE(hook);
	int rule, i, off0, vlan_tag, vlan_mask, end;
	int match = 0;
	int error = 0;
	int maxlen;
	struct mbuf *m = NGI_M(item);
	struct mbuf *m2;
	char *c;

	if (hcp->rules == 0)
		goto drop;

	if (!(m->m_flags & M_PKTHDR)) {
		printf("ouch, M_PKTHDR not set!?\n");
		goto drop;
	}

	maxlen = hcp->maxcontig;
	if (m->m_len < maxlen)
		maxlen = m->m_len;

//printf("%s() %d: rcv'd pkt on hook %s len %d maxcontig %d maxlen %d\n", __FUNCTION__, __LINE__, NG_HOOK_NAME(hook), m->m_len, hcp->maxcontig, maxlen);

	m = m_pullup(m, maxlen);
	NGI_M(item) = m;
	if (m == NULL) {
		printf("m_pullup() failed for %d\n", maxlen);
		goto drop;
	}

	for (rule = 0; rule < hcp->rules; rule++) {
		/* Pattern matching */
		for (off0 = hcp->rule[rule].p_off_lo;
		    off0 <= hcp->rule[rule].p_off_hi; off0++) {
			end = hcp->rule[rule].p_len;
			if (end + off0 > maxlen) {
				match = 0;
				break;
			}
			match = 1;
			c = mtod(m, char *);
			for (i = 0, c += off0; i < end; i++, c++) {
//printf("%s() %d: rule = %d off = %d i = %d *c = %02x pat[off] = %02x mask[i] = %02x\n", __FUNCTION__, __LINE__, rule, off0 + i, i, *c & 0xff, hcp->rule[rule].pattern[i] & 0xff, hcp->rule[rule].mask[i] & 0xff);
				/* Special handling for VLAN tagged mbufs */
				if (off0 + i == 12 &&
				    (m->m_flags & M_VLANTAG)) {
					if ((hcp->rule[rule].pattern[i] ^ 0x81)
					    & hcp->rule[rule].mask[i] & 0xff) {
						match = 0;
						break;
					}
					i++;
					if (hcp->rule[rule].pattern[i] & 0xff
					    & hcp->rule[rule].mask[i]) {
						match = 0;
						break;
					}
					i++;
					vlan_tag =
					    hcp->rule[rule].pattern[i] << 8;
					vlan_mask =
					    hcp->rule[rule].mask[i] << 8;
					i++;
					c--;
					vlan_tag |= hcp->rule[rule].pattern[i];
					vlan_mask |= hcp->rule[rule].mask[i];
//printf("VLANtagged: vlan_tag = %d vlan_mask = %08X\n", vlan_tag & 0x0fff, vlan_mask);
					if ((vlan_tag ^ m->m_pkthdr.ether_vtag)
					    & vlan_mask & 0x0fff) {
						match = 0;
						break;
					}
					continue;
				}
				if ((*c ^ hcp->rule[rule].pattern[i]) &
				    hcp->rule[rule].mask[i]) {
					match = 0;
					break;
				}
			}
			if (match)
				break;
		}

//printf("%s() %d: rule %d match %d\n", __FUNCTION__, __LINE__, rule, match);

		/* Decide what to do */
		switch (hcp->rule[rule].action) {
		case NGM_PM_ACTION_MATCH_HOOK:
			if (match) {
				NG_FWD_ITEM_HOOK(error, item,
				    hcp->rule[rule].asdata.hp);
				return (0);
			}
			break;
		case NGM_PM_ACTION_NOMATCH_HOOK:
			if (!match) {
				NG_FWD_ITEM_HOOK(error, item,
				    hcp->rule[rule].asdata.hp);
				return (0);
			}
			break;
		case NGM_PM_ACTION_MATCH_DUPTO:
			if (match) {
				if ((m2 = m_dup(m, M_DONTWAIT)) == NULL) {
					printf("ouch, m_dup() failed!\n");
					break;
				}
#if 0
				if (m->m_flags & M_VLANTAG) {
					m2->m_flags |= M_VLANTAG;
					m2->m_pkthdr.ether_vtag =
					    m->m_pkthdr.ether_vtag;
				}
#endif
				NG_SEND_DATA_ONLY(error,
				    hcp->rule[rule].asdata.hp, m2);
			}
			break;
		case NGM_PM_ACTION_NOMATCH_DUPTO:
			if (!match) {
				if ((m2 = m_dup(m, M_DONTWAIT)) == NULL) {
					printf("ouch, m_dup() failed!\n");
					break;
				}
				NG_SEND_DATA_ONLY(error,
				    hcp->rule[rule].asdata.hp, m2);
			}
			break;
		case NGM_PM_ACTION_MATCH_SKIPTO:
			if (match)
				rule = hcp->rule[rule].asdata.skipto_index;
			break;
		case NGM_PM_ACTION_NOMATCH_SKIPTO:
			if (!match)
				rule = hcp->rule[rule].asdata.skipto_index;
			break;
		case NGM_PM_ACTION_MATCH_DROP:
			if (match)
				goto drop;
			break;
		case NGM_PM_ACTION_NOMATCH_DROP:
			if (!match)
				goto drop;
			break;
		default:
			break;
		}
	}

drop:
//printf("%s() %d: drop\n", __FUNCTION__, __LINE__);
	NG_FREE_ITEM(item);
	return (0);
}

static int
ng_pm_shutdown(node_p node)
{

	NG_NODE_UNREF(node);
	return (0);
}

static int
ng_pm_disconnect(hook_p hook)
{
	ng_pm_hookcfg_p hcp = NG_HOOK_PRIVATE(hook);

	ng_pm_clear_config(NG_HOOK_NODE(hook));
	FREE(hcp, M_NETGRAPH_PM);
	NG_HOOK_SET_PRIVATE(hook, NULL);
	return (0);
}
