#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define PCRE_STATIC
#include "pcre.h"

#define SAVEPVN(p,n)	((p) ? savepvn(p,n) : NULL)

START_EXTERN_C

EXTERN_C const regexp_engine pcre_engine;

END_EXTERN_C

regexp *
PCRE_pregcomp(pTHX_ char *exp, char *xend, PMOP *pm)
{
    register regexp *r;
    register pcre *re;
    unsigned long int length;
    const char *error;
    int erroffset;

    re = (pcre*)(pcre_compile(exp, 0, &error, &erroffset, NULL));
    Newxz(r,1,regexp);
    
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
    
    /* XXX TODO: we really should somehow map the flags and stuff
       from inside the pattern to out. For instance perl wants to
       know if the pattern is anchored, and things like that. 
     */
     
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

extern void *pcre_malloc_wrapper(size_t s) {
    return PerlMemShared_malloc(s);
}

extern void pcre_free_wrapper(void *p) {
    PerlMemShared_free(p);
}


MODULE = re::engine::PCRE	PACKAGE = re::engine::PCRE


void
get_pcre_engine()
    PPCODE:
	XPUSHs(sv_2mortal(newSViv(PTR2IV(&pcre_engine))));
	
BOOT:
{
    pcre_free = pcre_stack_free = pcre_free_wrapper;
    pcre_malloc = pcre_stack_malloc = pcre_malloc_wrapper;
}

