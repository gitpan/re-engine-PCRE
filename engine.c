#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "pcre.h"

const regexp_engine pcre_engine;

pcre* compile(const char *pat, int opt);

regexp *
PCRE_pregcomp(pTHX_ char *exp, char *xend, PMOP *pm)
{
    register regexp *r;
    register pcre *re = compile(exp, 0);
    unsigned long int length;

    Newxz(r, 1, regexp);

    r->engine = &pcre_engine;
    r->refcnt = 1;

    /* This line is crucial! */
    r->precomp = savepvn(NULL, r->prelen);

    r->prelen = xend - exp;
    r->pprivate = re;

    pcre_fullinfo(
        re,
        NULL,
        PCRE_INFO_SIZE,
        &length
    );

    r->extflags = pm->op_pmflags & RXf_PMf_COMPILETIME;
    r->nparens  = (length - 1);
    Newxz(r->startp, length, I32);
    Newxz(r->endp, length, I32);

    return r;
}

I32
PCRE_regexec_flags(pTHX_ register regexp *r, char *stringarg, register char *strend,
                      char *strbeg, I32 minend, SV *sv, void *data, U32 flags)
{
    register pcre *re = r->pprivate;
    int rc;
    int *ovector;
    int i;

    ovector = malloc(sizeof(int) * r->nparens);

    rc = pcre_exec(
        re,         
        NULL,        
        strbeg,
        strend - strbeg,
        0,
        0,
        ovector,
        30
    );

    if (rc >= 0) {
        r->sublen = strend-strbeg;
        r->subbeg = savepvn(strbeg,r->sublen);
        for (i = 0; i < rc; i++) {
            r->startp[i] = ovector[i * 2];
            r->endp[i] = ovector[i * 2 + 1];
        }
        free(ovector);
        return 1;
    }
    else {
        free(ovector);
        int i;
        for (i = 0 ; i <= r->nparens ; i++) {
            r->startp[i] = -1;
            r->endp[i] = -1;
        }
        r->lastparen = r->lastcloseparen = 0;
        return 0;
    }

}

char *
PCRE_re_intuit_start(pTHX_ regexp *prog, SV *sv, char *strpos,
                     char *strend, U32 flags, re_scream_pos_data *data)
{
    return NULL;
}

SV *
PCRE_re_intuit_string(pTHX_ regexp *prog)
{
    return NULL;
}

void
PCRE_regfree_internal(pTHX_ struct regexp *r)
{
    Safefree(r->pprivate);
}

void *
PCRE_regdupe_internal(pTHX_ const regexp *r, CLONE_PARAMS *param)
{
    return r->pprivate;
}

const regexp_engine pcre_engine = {
        PCRE_pregcomp,
        PCRE_regexec_flags,
        PCRE_re_intuit_start,
        PCRE_re_intuit_string,
        PCRE_regfree_internal,
#if defined(USE_ITHREADS)        
        PCRE_regdupe_internal
#endif
};
