#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "pcre.h"
const regexp_engine pcre_engine;
pcre* compile(const char *pat, int opt);
void regfree(pcre *preg);
#define SAVEPVN(p,n)	((p) ? savepvn(p,n) : NULL)

/* XXX dmq: should be in perl.h via regexp.h but its not right now */
struct reg_substr_datum {
    I32 min_offset;
    I32 max_offset;
    SV *substr;		/* non-utf8 variant */
    SV *utf8_substr;	/* utf8 variant */
    I32 end_shift;
};
struct reg_substr_data {
    struct reg_substr_datum data[3];	/* Actual array */
};

regexp *
PCRE_pregcomp(pTHX_ char *exp, char *xend, PMOP *pm)
{
    register regexp *r;
    register pcre *re;
    unsigned long int length;
    

    re = compile(exp, 0);
    Newxz(r,1,regexp);
    
    /* XXX dmq: mandatory crap - pregfree needs to be changed */
    Newxz(r->substrs, 1, struct reg_substr_data);
    
    /* setup engine */
    r->engine = &pcre_engine;
    r->refcnt = 1;

    /* Preserve a copy of the original pattern */
    r->prelen = xend - exp;
    r->precomp = SAVEPVN(exp, r->prelen);

    /* Store our private object */
    r->pprivate = re;

    pcre_fullinfo(
        re,
        NULL,
        PCRE_INFO_SIZE,
        &length
    );
    
    /* store the compile flags */
    r->extflags = pm->op_pmflags & RXf_PMf_COMPILETIME;
    
    /* set up space for the capture buffers */
    r->nparens  = (length - 1);
    Newxz(r->startp, length, I32);
    Newxz(r->endp, length, I32);
    
    /* return the regexp */
    return r;
}

I32
PCRE_regexec_flags(pTHX_ register regexp *r, char *stringarg, register char *strend,
                      char *strbeg, I32 minend, SV *sv, void *data, U32 flags)
{
    register pcre *re = r->pprivate;
    I32 rc;
    int *ovector;
    I32 i;

    Newx(ovector,r->nparens,int);

    rc = (I32)pcre_exec(
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
        Safefree(ovector);
        return 1;
    }
    else {
        for (i = 0 ; i <= (I32)r->nparens ; i++) {
            r->startp[i] = -1;
            r->endp[i] = -1;
        }
        r->lastparen = r->lastcloseparen = 0;
        Safefree(ovector);
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
    PerlMemShared_free(r->pprivate);
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
