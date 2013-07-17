/* SCIPMEX - A simple MEX Interface to SCIP MILP/MIQP/MIQCQP/MINLP Solver
 * Copyright (C) Jonathan Currie 2012/2013 (I2C2)
 * 
 * Based in parts on matscip.c by SCIP authors.
 */

#include "mex.h"
#include <exception>
#include <ctype.h>
#include <stdio.h>

#include "scip/scip.h"
#include "scip/scipdefplugins.h"
#include "spxdefines.h"
#include "scipmex.h"
#include "config_ipopt_default.h"
#include "cppad/configure.hpp"
#include "mkl.h"
#include "dmumps_c.h"

#ifdef HAVE_ASL
 #include "asl_pfgh.h"
 #include "AMPL/reader_nl.h"
 struct SCIP_ProbData //probably should be declared in the above?
 {
    ASL*                  asl;
    SCIP_VAR**            vars;
    int                   nvars;
 };
#endif       

using namespace std;

//Argument Enumeration (in expected order of arguments)
enum {eH, eF, eA, eRL, eRU, eLB, eUB, eXTYPE, eSOS, eQC, eNLCON, eOPTS};
//PRHS Defines    
#define pH      prhs[eH]
#define pF      prhs[eF]
#define pA      prhs[eA]
#define pRL     prhs[eRL]
#define pRU     prhs[eRU]
#define pLB     prhs[eLB]
#define pUB     prhs[eUB]
#define pXTYPE  prhs[eXTYPE]
#define pSOS    prhs[eSOS]
#define pQC     prhs[eQC]
#define pNLCON  prhs[eNLCON]
#define pOPTS   prhs[eOPTS]

//Function Prototypes
void printSolverInfo();
void checkInputs(const mxArray *prhs[], int nrhs);
void getIntOption(const mxArray *opts, const char *option, int &var);
void getDblOption(const mxArray *opts, const char *option, double &var);

//Message Handler Callback
void msginfo(SCIP_MESSAGEHDLR *messagehdlr, FILE *file, const char *msg)
{
    mexPrintf(msg);
    mexEvalString("drawnow;"); //flush draw buffer
}
//Message Buffer
char msgbuf[BUFSIZE];

//Main Function
void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[])
{
    //Input Args
    double *H, *f, *A, *rl, *ru, *lb, *ub, *sosind, *soswt, *Q, *l, *qrl, *qru;
    char *xtype, *sostype = NULL;
    char fpath[BUFSIZE];
    
    //Return Args
    double *x, *fval, *exitflag, *iter, *nodes, *gap;
    const char *fnames[3] = {"LPiter","BBnodes","BBgap"};
    
    //Common Options
    int maxiter = 1500;
    int maxnodes = 10000;
    double maxtime = 1000;
    double primtol = 1e-6;
    int printLevel = 0;
    bool aslMode = false;
    int optsEntry = 0;
    mxArray* OPTS;
    
    //Internal Vars
    size_t ncon = 0, ndec = 0;
    size_t i, j, k;
    int alb = 0, aub = 0, no = 0, tm = 0, ts = 1;    
        
    //Sparse Indicing
    mwIndex *H_ir, *H_jc, *A_ir, *A_jc, *Q_ir, *Q_jc;
    mwIndex startRow, stopRow;
    
    //Print Header or return version string if requested
    if(nrhs < 1) {
        if(nlhs < 1) 
            printSolverInfo();
        else {
            sprintf(msgbuf,"%d.%d.%d",SCIPmajorVersion(),SCIPminorVersion(),SCIPtechVersion());
            plhs[0] = mxCreateString(msgbuf);
        }
        return;
    }        
    
    //Check Inputs
    checkInputs(prhs,nrhs); 
    
    #ifdef HAVE_ASL
    //Assume AMPL mode if first arg is a string
    if(mxIsChar(pH))
        aslMode = true;
    #endif
    
    //Initialization based on aslMode or not        
    if(aslMode) {
        //Get .nl file name
        mxGetString(prhs[0], fpath, BUFSIZE);
        //Options in asl places
        optsEntry = 1;
        OPTS = (mxArray*)prhs[1];        
    }
    else { //Normal, MATLAB mode
        //Get pointers to input vars
        H = mxGetPr(pH); H_ir = mxGetIr(pH); H_jc = mxGetJc(pH);
        f = mxGetPr(pF);
        A = mxGetPr(pA); A_ir = mxGetIr(pA); A_jc = mxGetJc(pA);
        rl = mxGetPr(pRL); ru = mxGetPr(pRU);
        lb = mxGetPr(pLB); ub = mxGetPr(pUB);
        if(nrhs > eXTYPE)
            xtype = mxArrayToString(pXTYPE);
        //Options in normal places
        optsEntry = eOPTS;
        OPTS = (mxArray*)pOPTS;
        //Get sizes from input args
        ndec = mxGetNumberOfElements(pF);
        ncon = mxGetM(pA); 
    }
                        
    //Get Common Options if specified
    if(nrhs > optsEntry) {
        getIntOption(OPTS,"maxiter",maxiter);
        getIntOption(OPTS,"maxnodes",maxnodes);
        getDblOption(OPTS,"maxtime",maxtime);
        getDblOption(OPTS,"tolrfun",primtol);
        getIntOption(OPTS,"display",printLevel);
        //Check for nonlinear testing mode
        getIntOption(OPTS,"testmode",tm);
    }       

    //Create Outputs
    plhs[0] = mxCreateDoubleMatrix(ndec,1, mxREAL);
    plhs[1] = mxCreateDoubleMatrix(1,1, mxREAL);
    plhs[2] = mxCreateDoubleMatrix(1,1, mxREAL);
    plhs[3] = mxCreateDoubleMatrix(1,1, mxREAL);  
    plhs[4] = mxCreateDoubleMatrix(1,1, mxREAL);  
    x = mxGetPr(plhs[0]); 
    fval = mxGetPr(plhs[1]); 
    exitflag = mxGetPr(plhs[2]);        
    //Statistic Structure Output
    plhs[3] = mxCreateStructMatrix(1,1,3,fnames);
    mxSetField(plhs[3],0,fnames[0],mxCreateDoubleMatrix(1,1, mxREAL));
    mxSetField(plhs[3],0,fnames[1],mxCreateDoubleMatrix(1,1, mxREAL));
    mxSetField(plhs[3],0,fnames[2],mxCreateDoubleMatrix(1,1, mxREAL));
    iter  = mxGetPr(mxGetField(plhs[3],0,fnames[0]));
    nodes = mxGetPr(mxGetField(plhs[3],0,fnames[1]));
    gap   = mxGetPr(mxGetField(plhs[3],0,fnames[2]));

    //SCIP Objects
    SCIP* scip;
    SCIP_VAR** vars = NULL;
    SCIP_CONS** cons = NULL;
    SCIP_VAR* qobj;

    //Create SCIP Object
    SCIP_ERR( SCIPcreate(&scip) , "Error creating SCIP object");
    SCIP_ERR( SCIPincludeDefaultPlugins(scip), "Error including SCIP default plugins");
    //Add Ctrl-C Event Handler
    SCIP_ERR( SCIPincludeCtrlCEventHdlr(scip), "Error adding Ctrl-C Event Handler");
    
    //Enter problem if in MATLAB mode
    if(!aslMode) { 
        //Create Empty Problem
        SCIP_ERR( SCIPcreateProbBasic(scip,"OPTI Problem"), "Error creating basic SCIP problem");    

        //Create continuous xtype array if empty or not supplied
        if(nrhs <= eXTYPE || mxIsEmpty(pXTYPE)) {
            xtype = (char*)mxCalloc(ndec,sizeof(char));
            for(i=0;i<ndec;i++)
                xtype[i] = 'c';
        }

        //Create infinite bounds if empty
        if(mxIsEmpty(pLB)) {
            lb = (double*)mxCalloc(ndec,sizeof(double)); alb=1;
            for(i=0;i<ndec;i++)
                lb[i] = -1e50;
        }
        if(mxIsEmpty(pUB)) {
            ub = (double*)mxCalloc(ndec,sizeof(double)); aub=1;
            for(i=0;i<ndec;i++)
                ub[i] = 1e50;
        }

        //Create SCIP Variables (also loads linear objective + bounds)
        SCIP_ERR( SCIPallocMemoryArray(scip,&vars,(int)ndec), "Error allocating variable memory");
        double llb, lub;
        for(i=0;i<ndec;i++)
        {
            SCIP_VARTYPE vartype;
            //Assign variable type
            switch(tolower(xtype[i]))
            {
                case 'i':
                    vartype = SCIP_VARTYPE_INTEGER; llb = lb[i]; lub = ub[i]; break;
                case 'b':
                    vartype = SCIP_VARTYPE_BINARY; 
                    llb = lb[i] <= -1e50 ? 0 : lb[i]; //if we don't do this, SCIP fails during presolve
                    lub = ub[i] >= 1e50 ? 1 : ub[i];
                    break;
                case 'c':
                    vartype = SCIP_VARTYPE_CONTINUOUS; llb = lb[i]; lub = ub[i]; break;
                default:
                    sprintf(msgbuf,"Unknown variable type for variable %d",i);
                    mexErrMsgTxt(msgbuf);
            }
            //Create variable
            SCIP_ERR( SCIPcreateVarBasic(scip,&vars[i],NULL,llb,lub,f[i],vartype), "Error creating basic SCIP variable");
            //Add to problem
            SCIP_ERR( SCIPaddVar(scip,vars[i]), "Error adding SCIP variable to problem");
        }

        //Add Quadratic Objective (as Quadratic Constraint 0.5x'Hx - qobj = 0, and min(x) f'x + qobj, if exists)
        if(!mxIsEmpty(pH))
        {
            //Create an unbounded variable to add to objective, representing the quadratic part
            SCIP_ERR( SCIPcreateVarBasic(scip, &qobj, "quadobj", -SCIPinfinity(scip), SCIPinfinity(scip), 1.0, SCIP_VARTYPE_CONTINUOUS), "Error adding quadratic objective variable");
            SCIP_ERR( SCIPaddVar(scip, qobj), "Error adding quadratic objective variable");

            //Create an empty quadratic constraint = 0.0
            SCIP_CONS* qobjc;
            SCIP_ERR( SCIPcreateConsBasicQuadratic(scip, &qobjc, "quadobj_con", 0, NULL, NULL, 0, NULL, NULL, NULL, 0.0, 0.0), "Error creating quadratic objective constraint");

            //Add linear term, connecting quadratic "constraint" to objective
            SCIP_ERR( SCIPaddLinearVarQuadratic(scip, qobjc, qobj, -1.0), "Error adding quadratic objective linear term");

            //Begin processing Hessian (note we expect the full H, not lower/upper triangular - to allow for non-convex and other not-nice problems)
            for(i = 0; i < ndec; i++) 
            {
                //Determine number of nz in this column
                startRow = H_jc[i];
                stopRow = H_jc[i+1];
                no = (int)(stopRow - startRow);
                //If we have nz in this column
                if(no > 0) {
                    //Add each coefficient
                    for(j = startRow; j < stopRow; j++) {
                        //Check for squared term, or bilinear
                        if(i == H_ir[j]) { //diagonal
                            SCIP_ERR( SCIPaddSquareCoefQuadratic(scip, qobjc, vars[i], 0.5*H[j]), "Error adding quadratic squared term");}
                        else {
                            SCIP_ERR( SCIPaddBilinTermQuadratic(scip, qobjc, vars[H_ir[j]], vars[i], 0.5*H[j]), "Error adding quadratic bilinear term");}
                    }
                }
            }       
            //Add the quadratic constraint, then release it
            SCIP_ERR( SCIPaddCons(scip,qobjc), "Error adding quadratic objective constraint");
            SCIP_ERR( SCIPreleaseCons(scip,&qobjc), "Error releaseing quadratic objective constraint");
        }

        //Add Linear Constraints (if they exist)
        if(ncon) 
        {     
            //Allocate memory for all constraints (we create them all now, as we have to add coefficients in column order)
            SCIP_ERR( SCIPallocMemoryArray(scip, &cons, (int)ncon), "Error allocating constraint memory");
            //Create each constraint and add row bounds, but leave coefficients empty
            for(i=0;i<ncon;i++)
            {
                SCIPsnprintf(msgbuf, BUFSIZE, "lincon%d", i); //appears constraints require a name
                SCIP_ERR( SCIPcreateConsBasicLinear(scip,&cons[i],msgbuf,0,NULL,NULL,rl[i],ru[i]), "Error creating basic SCIP linear constraint");
            }
            //Now for each column (variable), add coefficients
            for(i = 0; i < ndec; i++) 
            {
                //Determine number of nz in this column
                startRow = A_jc[i];
                stopRow = A_jc[i+1];
                no = (int)(stopRow - startRow);
                //If we have nz in this column
                if(no > 0) 
                {
                    //Add each coefficient
                    for(j = startRow; j < stopRow; j++)
                        SCIP_ERR( SCIPaddCoefLinear(scip, cons[A_ir[j]], vars[i], A[j]), "Error adding constraint linear coefficient");
                }
            }
            //Now for each constraint, add it to the problem, then release it
            for(i=0;i<ncon;i++)
            {
                SCIP_ERR( SCIPaddCons(scip,cons[i]), "Error adding linear constraint");                   
                SCIP_ERR( SCIPreleaseCons(scip,&cons[i]), "Error releasing linear constraint");
            }
        }

        //Add SOS Constraints (if they exist)
        if(nrhs > eSOS && !mxIsEmpty(pSOS))
        {
            //Determine the number of SOS to add
            size_t no_sets = (int)mxGetNumberOfElements(mxGetField(pSOS,0,"type"));
            if(no_sets > 0) {
                //Collect Types
                sostype = mxArrayToString(mxGetField(pSOS,0,"type"));
                //For each SOS, create respective constraint, add it, then release it
                SCIP_CONS *consos = NULL;
                size_t novars;
                for(i = 0; i < no_sets; i++)
                {
                    //Create constraint name
                    SCIPsnprintf(msgbuf, BUFSIZE, "soscon%d", i);
                    //Collect novars + ind + wt
                    if(mxIsCell(mxGetField(pSOS,0,"index"))) {
                        novars = (int)mxGetNumberOfElements(mxGetCell(mxGetField(pSOS,0,"index"),i));
                        sosind = mxGetPr(mxGetCell(mxGetField(pSOS,0,"index"),i));
                    }
                    else {
                        novars = (int)mxGetNumberOfElements(mxGetField(pSOS,0,"index"));
                        sosind = mxGetPr(mxGetField(pSOS,0,"index"));
                    }
                    if(mxIsCell(mxGetField(pSOS,0,"weight"))) //should check here soswt is the same length
                        soswt = mxGetPr(mxGetCell(mxGetField(pSOS,0,"weight"),i));
                    else
                        soswt = mxGetPr(mxGetField(pSOS,0,"weight"));
                    //Switch based on SOS type
                    switch(sostype[i])
                    {
                        case '1':     
                            //Create an empty SOS1 constraint                            
                            SCIP_ERR( SCIPcreateConsBasicSOS1(scip,&consos,msgbuf,0,NULL,NULL), "Error creating basic SCIP SOS1 constraint");
                            //For each variable, add to SOS constraint
                            for(j = 0; j < novars; j++)
                                SCIP_ERR( SCIPaddVarSOS1(scip,consos,vars[(int)sosind[j]-1],soswt[j]), "Error adding SOS1 constraint"); //remember -1 for Matlab indicies
                            break;

                        case '2':
                            //Create an empty SOS2 constraint                            
                            SCIP_ERR( SCIPcreateConsBasicSOS2(scip,&consos,msgbuf,0,NULL,NULL), "Error creating basic SCIP SOS2 constraint");
                            //For each variable, add to SOS constraint
                            for(j = 0; j < novars; j++)
                                SCIP_ERR( SCIPaddVarSOS2(scip,consos,vars[(int)sosind[j]-1],soswt[j]), "Error adding SOS2 constraint"); //remember -1 for Matlab indicies
                            break;

                        default:
                            sprintf(msgbuf,"Uknown SOS Type for SOS %d",i);
                            mexErrMsgTxt(msgbuf);                        
                    }
                    //Add the constraint to the problem, then release it
                    SCIP_ERR( SCIPaddCons(scip,consos), "Error adding SOS constraint");                    
                    SCIP_ERR( SCIPreleaseCons(scip,&consos), "Error releasing SOS constraint");
                }
            }
        }   

        //Add Quadratic Constraints (if they exist)
        if(nrhs > eQC && !mxIsEmpty(pQC))
        {
            //Determine the number of SOS to add
            size_t no_qc = (int)mxGetNumberOfElements(mxGetField(pQC,0,"qrl"));
            if(no_qc > 0) {
                //Collect l and r
                l = mxGetPr(mxGetField(pQC,0,"l"));
                qrl = mxGetPr(mxGetField(pQC,0,"qrl"));
                qru = mxGetPr(mxGetField(pQC,0,"qru"));
                //For each QC, create respective constraint, add it, then release it
                SCIP_CONS *conqc = NULL;
                for(i = 0; i < no_qc; i++)
                {
                    //Create constraint name
                    SCIPsnprintf(msgbuf, BUFSIZE, "qccon%d", i);
                    //Collect Q
                    if(mxIsCell(mxGetField(pQC,0,"Q"))) {
                        Q = mxGetPr(mxGetCell(mxGetField(pQC,0,"Q"),i));
                        Q_ir = mxGetIr(mxGetCell(mxGetField(pQC,0,"Q"),i));
                        Q_jc = mxGetJc(mxGetCell(mxGetField(pQC,0,"Q"),i));
                    }
                    else {
                        Q = mxGetPr(mxGetField(pQC,0,"Q"));
                        Q_ir = mxGetIr(mxGetField(pQC,0,"Q"));
                        Q_jc = mxGetJc(mxGetField(pQC,0,"Q"));
                    }
                    //Collect bounds
                    double lqrl, lqru;
                    lqrl = mxIsInf(qrl[i]) ? -1e50 : qrl[i];
                    lqru = mxIsInf(qru[i]) ?  1e50 : qru[i];
                        
                    //Create an empty quadratic constraint <= r
                    SCIP_ERR( SCIPcreateConsBasicQuadratic(scip, &conqc, msgbuf, 0, NULL, NULL, 0, NULL, NULL, NULL, lqrl, lqru), "Error creating quadratic constraint");

                    //Add linear terms
                    for(j = 0; j < ndec; j++)
                    {
                        if(!SCIPisFeasZero(scip, l[j+i*no_qc])) {
                            SCIP_ERR( SCIPaddLinearVarQuadratic(scip, conqc, vars[j], l[j+i*no_qc]), "Error adding quadratic objective linear term");}
                    }
                    //Begin processing Q (note we expect the full Q, not lower/upper triangular - to allow for non-convex problems)
                    for(k = 0; k < ndec; k++) 
                    {
                        //Determine number of nz in this column
                        startRow = Q_jc[k];
                        stopRow = Q_jc[k+1];
                        no = (int)(stopRow - startRow);
                        //If we have nz in this column
                        if(no > 0) {
                            //Add each coefficient
                            for(j = startRow; j < stopRow; j++) {                                
                                //Check for squared term, or bilinear
                                if(k == Q_ir[j]) { //diagonal
                                    SCIP_ERR( SCIPaddSquareCoefQuadratic(scip, conqc, vars[k], Q[j]), "Error adding quadratic constraint squared term");}
                                else {
                                    SCIP_ERR( SCIPaddBilinTermQuadratic(scip, conqc, vars[Q_ir[j]], vars[k], Q[j]), "Error adding quadratic constraint bilinear term");}
                            }
                        }
                    } 
                    //Add the constraint to the problem, then release it
                    SCIP_ERR( SCIPaddCons(scip,conqc), "Error adding quadratic constraint");                    
                    SCIP_ERR( SCIPreleaseCons(scip,&conqc), "Error releasing quadratic constraint");
                }
            }
        }

        //Add Nonlinear constraints and / or objective (if they exist)
        if(nrhs > eNLCON && !mxIsEmpty(pNLCON))
        {
            double *instr;
            int ninstr = 0;
            double *conval, cval, *objval, oval;
            double *x0 = NULL, err;

            //Check if we have constraint validation points to check against
            if(mxGetField(pNLCON,0,"nlcon_val")) {
                conval = mxGetPr(mxGetField(pNLCON,0,"nlcon_val"));
                //Check if we have initial guess to use
                if(mxGetField(pNLCON,0,"x0"))
                    x0 = mxGetPr(mxGetField(pNLCON,0,"x0"));            
            }            
            //Check if we have objective validation point to check against
            if(mxGetField(pNLCON,0,"obj_val")) {
                objval = mxGetPr(mxGetField(pNLCON,0,"obj_val"));
                //Check if we have initial guess to use
                if(mxGetField(pNLCON,0,"x0"))
                    x0 = mxGetPr(mxGetField(pNLCON,0,"x0")); //same as above but may be uncon
            }

            //Add nonlinear constraints
            if(mxGetField(pNLCON,0,"instr"))
            {
                //Get constraint bounds
                double *cl = mxGetPr(mxGetField(pNLCON,0,"cl"));
                double *cu = mxGetPr(mxGetField(pNLCON,0,"cu"));
                //See if we have multiple constraints
                if(mxIsCell(mxGetField(pNLCON,0,"instr"))) 
                {
                    //For each cell, receive instruction list, add constraint, and verify
                    for(size_t i = 0; i < mxGetNumberOfElements(mxGetField(pNLCON,0,"instr")); i++)
                    {
                        //Retrieve instructions
                        instr = mxGetPr(mxGetCell(mxGetField(pNLCON,0,"instr"),i));
                        ninstr = mxGetNumberOfElements(mxGetCell(mxGetField(pNLCON,0,"instr"),i));
                        //Add the constraint
                        cval = addNonlinearCon(scip, vars, instr, ninstr, cl[i], cu[i], x0, i, false);
                        //Validate if possible
                        if(x0 != NULL)
                        {
                            err = abs(cval - conval[i]);
                            if(err > 1e-6) {
                                sprintf(msgbuf,"Failed validation test on nonlinear constraint #%d, difference: %1.6g",i,err);
                                mexWarnMsgTxt(msgbuf);
                                ts = 0;
                            }
                            #ifdef DEBUG
                            else
                                mexPrintf("-- Passed validation test on nonlinear constraint #%d --\n",i);  
                            #endif
                        }
                    }
                }
                else //only one constraint
                {
                    //Retrieve instructions
                    instr = mxGetPr(mxGetField(pNLCON,0,"instr"));
                    ninstr = mxGetNumberOfElements(mxGetField(pNLCON,0,"instr"));
                    //Add the constraint
                    cval = addNonlinearCon(scip, vars, instr, ninstr, *cl, *cu, x0, 0, false);
                    //Validate if possible
                    if(x0 != NULL)
                    {
                        err = abs(cval - *conval);
                        if(err > 1e-6) {
                            sprintf(msgbuf,"Failed validation test on nonlinear constraint #0, difference: %1.6g",err);
                            mexWarnMsgTxt(msgbuf);
                            ts = 0;
                        }
                        #ifdef DEBUG
                        else
                            mexPrintf("-- Passed validation test on nonlinear constraint #0 --\n");  
                        #endif
                    }
                }
            }
            //Add nonlinear objective
            if(mxGetField(pNLCON,0,"obj_instr"))
            {
                //Retrieve instructions
                instr = mxGetPr(mxGetField(pNLCON,0,"obj_instr"));
                ninstr = mxGetNumberOfElements(mxGetField(pNLCON,0,"obj_instr"));
                //Add the objective as nonlinear constraint: obj(x) - nlobj = 0, and min(x) f'x + nlobj
                oval = addNonlinearCon(scip, vars, instr, ninstr, 0, 0, x0, 0, true);
                //Validate if possible
                if(x0 != NULL)
                {
                    err = abs(oval - *objval);
                    if(err > 1e-6) {
                        sprintf(msgbuf,"Failed validation test on nonlinear objective #0, difference: %1.6g",err);
                        mexWarnMsgTxt(msgbuf);
                        ts = 0;
                    }
                    #ifdef DEBUG
                    else
                        mexPrintf("-- Passed validation test on nonlinear objective --\n\n\n");  
                    #endif
                }
            }        
        }
    }
    #ifdef HAVE_ASL
    //Read problem if in ASL mode
    else {
        //Include Stefan's .nl reader
        SCIP_ERR( SCIPincludeReaderNl(scip), "Error including NL reader");
        //Read the problem in
        SCIP_ERR( SCIPreadProb(scip,fpath,"nl"), "Error reading AMPL .nl file, ensure it is compatible with SCIP functionality" );        
        //Check problem was read successfully
        if(SCIPgetStage(scip) >= SCIP_STAGE_PROBLEM) {
            if(printLevel)
                mexPrintf("Read AMPL file: %s\n",fpath);
            //Create Problem Vars
            //vars = SCIPgetOrigVars(scip); //don't use these methods as will also include objective + nl constraint vars
            //ndec = SCIPgetNOrigVars(scip);
            SCIP_PROBDATA* probdata = SCIPgetProbData(scip);
            ndec = probdata->nvars;
            vars = probdata->vars;
            //Create new plhs for x
            mxDestroyArray(plhs[0]); //existing one is 0x0
            plhs[0] = mxCreateDoubleMatrix(ndec,1, mxREAL); 
            x = mxGetPr(plhs[0]); 
        }
        else {
            SCIP_ERR( SCIPfree(&scip), "Error releasing SCIP problem");
            mexErrMsgTxt("Error reading AMPL .nl file. Please ensure the file exists and is compatible with SCIP.");
        }        
    }
    #endif
    
    //Set Common OPTI Options  
    SCIP_ERR( SCIPsetRealParam(scip,"limits/time",maxtime), "Error setting maxtime");
    SCIP_ERR( SCIPsetLongintParam(scip,"lp/iterlim",maxiter), "Error setting iterlim");
    SCIP_ERR( SCIPsetLongintParam(scip,"limits/nodes",maxnodes), "Error setting nodes");
    SCIP_ERR( SCIPsetRealParam(scip,"numerics/lpfeastol",primtol), "Error setting lpfeastol");
    
    //If user has requested print out
    if(printLevel)
    {
        //Create Message Handler
        SCIP_MESSAGEHDLR *mexprinter;
        SCIPmessagehdlrCreate(&mexprinter,TRUE,NULL,FALSE,&msginfo,&msginfo,&msginfo,NULL,NULL);
        SCIP_ERR( SCIPsetMessagehdlr(scip,mexprinter), "Error adding message handler");
        //Set Verbosity Level
        SCIP_ERR( SCIPsetIntParam(scip,"display/verblevel",printLevel), "Error setting verblevel");
    }

    //Solve Problem if not in testing mode
    if(tm==0)
    {
        SCIP_ERR( SCIPsolve(scip), "Error solving SCIP problem!");

        //Assign Return Arguments
        if(SCIPgetNSols(scip) > 0 ) 
        {
            SCIP_SOL* scipbestsol = SCIPgetBestSol(scip);
            //Assign x
            for(i = 0;i<ndec;i++)
               x[i] = SCIPgetSolVal(scip,scipbestsol,vars[i]);            
            //Assign fval
            *fval = SCIPgetSolOrigObj(scip, scipbestsol);
            //Get Solve Statistics
            *iter = (double)SCIPgetNLPIterations(scip);
            *nodes = (double)SCIPgetNTotalNodes(scip);
            *gap = SCIPgetGap(scip);
            #ifdef HAVE_ASL
            if(aslMode) //write ampl solution by default
                SCIPwriteAmplSolReaderNl(scip,NULL);
            #endif
        }
        //Get Solution Status
        *exitflag = (double)SCIPgetStatus(scip);
    }
    //Else return test status
    else
        *x = ts;

    //Clean up memory from MATLAB mode
    if(!aslMode) {
        //Clean up memory
        mxFree(xtype);
        if(alb) mxFree(lb); alb = 0;
        if(aub) mxFree(ub); aub = 0;
        if(sostype) mxFree(sostype); sostype = NULL;

        //Release Variables
        for(i=0;i<ndec;i++)
            SCIP_ERR( SCIPreleaseVar(scip,&vars[i]), "Error releasing SCIP variable");
        if(!mxIsEmpty(pH))
            SCIP_ERR( SCIPreleaseVar(scip,&qobj), "Error releasing SCIP quadratic objective variable");

        //Now free SCIP arrays & problem
        SCIPfreeMemoryArray(scip, &vars);
        if(ncon) SCIPfreeMemoryArray(scip, &cons);
    }
    //Clean up general SCIP memory
    SCIP_ERR( SCIPfree(&scip), "Error releasing SCIP problem");
}               


//Check all inputs for size and type errors
void checkInputs(const mxArray *prhs[], int nrhs)
{
    size_t ndec, ncon;    
    
    #ifdef HAVE_ASL
    //Check For Path as first argument
    if(mxIsChar(prhs[0]))
    {
        char fpath[BUFSIZE];
        //Check file exists
        mxGetString(prhs[0], fpath, BUFSIZE);
        FILE* fp = fopen(fpath,"r");
        if(fp == NULL)
            mexErrMsgTxt("Cannot open the supplied AMPL .nl file for reading. Check the file exists on the supplied path.");
        else
            fclose(fp);
        //Assume now in AMPL mode
        if(nrhs > 1 && !mxIsEmpty(prhs[1]) && !mxIsStruct(prhs[1]))
            mexErrMsgTxt("The options argument must be a structure!");
        return;
    }
    #endif
            
    //Correct number of inputs
    if(nrhs <= eUB)
        mexErrMsgTxt("You must supply at least 7 arguments to scip (H, f, A, rl, ru, lb, ub)"); 
    
    //Check we have an objective
    if(mxIsEmpty(pF))
        mexErrMsgTxt("You must supply a linear objective function via f (all zeros if not required)!");
    
    //Check options is a structure
    if(nrhs > eOPTS && !mxIsEmpty(pOPTS) && !mxIsStruct(pOPTS))
        mexErrMsgTxt("The options argument must be a structure!");
    
    //Get Sizes    
    ndec = mxGetNumberOfElements(pF);
    ncon = mxGetM(pA);
    
    //Check Quadratic Objective
    if(!mxIsEmpty(pH)) {
        if(mxGetM(pH) != ndec || mxGetN(pH) != ndec)
            mexErrMsgTxt("H has incompatible dimensions");
        if(!mxIsSparse(pH))
            mexErrMsgTxt("H must be a sparse matrix");
    }
    
    //Check Constraint Pairs
    if(ncon && mxIsEmpty(pRL))
        mexErrMsgTxt("rl is empty!");
    if(ncon && mxIsEmpty(pRU))
        mexErrMsgTxt("ru is empty!");
    
    //Check Sparsity (only supported in A and H)
    if(!mxIsEmpty(pA)) {
        if(mxIsSparse(pF) || mxIsSparse(pRL) || mxIsSparse(pLB))
            mexErrMsgTxt("Only A is a sparse matrix");
        if(!mxIsSparse(pA))
            mexErrMsgTxt("A must be a sparse matrix");
    }
    
    //Check xtype data type
    if(nrhs > eXTYPE && !mxIsEmpty(pXTYPE) && mxGetClassID(pXTYPE) != mxCHAR_CLASS)
        mexErrMsgTxt("xtype must be a char array");
    
    //Check SOS structure
    if(nrhs > eSOS && !mxIsEmpty(pSOS)) {
        if(!mxIsStruct(pSOS))
            mexErrMsgTxt("The SOS argument must be a structure!");       
        if(mxGetFieldNumber(pSOS,"type") < 0)
            mexErrMsgTxt("The sos structure should contain the field 'type'");
        if(mxGetFieldNumber(pSOS,"index") < 0)
            mexErrMsgTxt("The sos structure should contain the field 'index'");
        if(mxGetFieldNumber(pSOS,"weight") < 0)
            mexErrMsgTxt("The sos structure should contain the field 'weight'");
        
        int no_sets = (int)mxGetNumberOfElements(mxGetField(pSOS,0,"type")); 
        if(no_sets > 1) {
            if(!mxIsCell(mxGetField(pSOS,0,"index")) || mxIsEmpty(mxGetField(pSOS,0,"index")))
                mexErrMsgTxt("sos.index must be a cell array, and not empty!");
            if(!mxIsCell(mxGetField(pSOS,0,"weight")) || mxIsEmpty(mxGetField(pSOS,0,"weight")))
                mexErrMsgTxt("sos.weight must be a cell array, and not empty!");
            if(mxGetNumberOfElements(mxGetField(pSOS,0,"index")) != no_sets)
                mexErrMsgTxt("sos.index cell array is not the same length as sos.type!");
            if(mxGetNumberOfElements(mxGetField(pSOS,0,"weight")) != no_sets)
                mexErrMsgTxt("sos.weight cell array is not the same length as sos.type!");        
        }
    }
    
    //Check QC structure
    if(nrhs > eQC && !mxIsEmpty(pQC)) {
        if(!mxIsStruct(pQC))
            mexErrMsgTxt("The QC argument must be a structure!");       
        if(mxGetFieldNumber(pQC,"Q") < 0)
            mexErrMsgTxt("The QC structure should contain the field 'Q'");
        if(mxGetFieldNumber(pQC,"l") < 0)
            mexErrMsgTxt("The QC structure should contain the field 'l'");
        if(mxGetFieldNumber(pQC,"qrl") < 0)
            mexErrMsgTxt("The QC structure should contain the field 'qrl'");
        if(mxGetFieldNumber(pQC,"qru") < 0)
            mexErrMsgTxt("The QC structure should contain the field 'qru'");
       
        if(mxGetNumberOfElements(mxGetField(pQC,0,"qrl")) != mxGetNumberOfElements(mxGetField(pQC,0,"qru")))
            mexErrMsgTxt("qrl and qru should have the the same number of elements");
       
        int no_qc = (int)mxGetNumberOfElements(mxGetField(pQC,0,"qrl")); 
        if(no_qc > 1) {
            if(!mxIsCell(mxGetField(pQC,0,"Q")) || mxIsEmpty(mxGetField(pQC,0,"Q")))
                mexErrMsgTxt("Q must be a cell array, and not empty!");
            if(mxGetNumberOfElements(mxGetField(pQC,0,"Q")) != no_qc)
                mexErrMsgTxt("You must have a Q specified for each row in qrl, qru, and column in l");
            //Check each Q
            mxArray *Q;
            for(int i = 0; i < no_qc; i++)
            {
                Q = mxGetCell(mxGetField(pQC,0,"Q"),i);
                if(!mxIsSparse(Q))
                    mexErrMsgTxt("Q must be sparse!");
                if(mxGetM(Q) != ndec || mxGetN(Q) != ndec)
                    mexErrMsgTxt("Q must be an n x n square matrix");
            }
        }   
        //just one QC
        else {
            if(mxIsEmpty(mxGetField(pQC,0,"Q")))
                mexErrMsgTxt("Q must not be empty!");
            if(!mxIsSparse(mxGetField(pQC,0,"Q")))
                mexErrMsgTxt("Q must be sparse!");
            if(mxGetM(mxGetField(pQC,0,"Q")) != ndec || mxGetN(mxGetField(pQC,0,"Q")) != ndec)
                mexErrMsgTxt("Q must be an n x n square matrix");
        }
        //Common checks
        if(mxIsEmpty(mxGetField(pQC,0,"l")))
            mexErrMsgTxt("l must not be empty!");
        if(mxIsSparse(mxGetField(pQC,0,"l")))
            mexErrMsgTxt("l matrix must be dense!");
        if(mxGetN(mxGetField(pQC,0,"l")) != no_qc)
            mexErrMsgTxt("l matrix/vector does not have the same number of columns as there are elements in qrl/qru");
        if(mxGetM(mxGetField(pQC,0,"l")) != ndec)
            mexErrMsgTxt("l matrix/vector does not have the same number of rows as ndec"); 
    }
    
    //Check NL structure
    if(nrhs > eNLCON && !mxIsEmpty(pNLCON)) {
        if(!mxIsStruct(pNLCON))
            mexErrMsgTxt("The NL argument must be a structure!");       
        if(mxGetFieldNumber(pNLCON,"instr") < 0 && mxGetFieldNumber(pNLCON,"obj_instr") < 0)
            mexErrMsgTxt("The NL structure should contain the field 'instr' or 'obj_instr'");
        if(mxGetField(pNLCON,0,"instr"))
        {
            if(mxGetFieldNumber(pNLCON,"cl") < 0)
                mexErrMsgTxt("The NL structure should contain the field 'cl' when specifying nonlinear constraints");
            if(mxGetFieldNumber(pNLCON,"cu") < 0)
                mexErrMsgTxt("The NL structure should contain the field 'cu' when specifying nonlinear constraints");
            if(mxGetNumberOfElements(mxGetField(pNLCON,0,"cl")) != mxGetNumberOfElements(mxGetField(pNLCON,0,"cu")))
                mexErrMsgTxt("The number of elements in cl and cu is not the same");
            //Check number of constraints the same as cl/cu
            if(mxIsCell(mxGetField(pNLCON,0,"instr"))) {
                if(mxGetNumberOfElements(mxGetField(pNLCON,0,"instr")) != mxGetNumberOfElements(mxGetField(pNLCON,0,"cl")))
                    mexErrMsgTxt("The number of constraints specified by cell array nl.instr does not match the length of vectors cl & cu");
            }
            else {                
                if(mxGetNumberOfElements(mxGetField(pNLCON,0,"cl")) != 1)
                    mexErrMsgTxt("When nl.instr is not a cell (single constraint), cl and cu are expected to be scalars");
            }
        }        
    }
    
    //Check Sizes
    if(ncon) {
        if(mxGetN(pA) != ndec)
            mexErrMsgTxt("A has incompatible dimensions");
        if(mxGetNumberOfElements(pRL) != ncon)
            mexErrMsgTxt("rl has incompatible dimensions");
        if(mxGetNumberOfElements(pRU) != ncon)
            mexErrMsgTxt("ru has incompatible dimensions");
    }
    if(!mxIsEmpty(pLB) && (mxGetNumberOfElements(pLB) != ndec))
        mexErrMsgTxt("lb has incompatible dimensions");
    if(!mxIsEmpty(pUB) && (mxGetNumberOfElements(pUB) != ndec))
        mexErrMsgTxt("ub has incompatible dimensions");    
    if(nrhs > eXTYPE && !mxIsEmpty(pXTYPE) && (mxGetNumberOfElements(pXTYPE) != ndec))
        mexErrMsgTxt("xtype has incompatible dimensions");    
}

//Option Getting Methods
void getIntOption(const mxArray *opts, const char *option, int &var)
{
    if(mxGetField(opts,0,option))
      var = (int)*mxGetPr(mxGetField(opts,0,option));
}
void getDblOption(const mxArray *opts, const char *option, double &var)
{
    if(mxGetField(opts,0,option))
      var = *mxGetPr(mxGetField(opts,0,option));
}

//Print Solver Information
void printSolverInfo()
{    
    mexPrintf("\n-----------------------------------------------------------\n");
    mexPrintf(" SCIP: Solving Constraint Integer Programs [v%d.%d.%d]\n",SCIPmajorVersion(),SCIPminorVersion(),SCIPtechVersion());
    mexPrintf("  - Released under the ZIB Academic License: http://scip.zib.de/academic.txt\n");
    mexPrintf("  - Source available from: http://scip.zib.de/\n\n");
    
    mexPrintf(" This binary is statically linked to the following software:\n");
    mexPrintf("  - SoPlex [v%d] (ZIB Academic License)\n",SOPLEX_VERSION);
    mexPrintf("  - Ipopt  [v%s] (Eclipse Public License)\n",IPOPT_VERSION);
    strcpy(msgbuf,&CPPAD_PACKAGE_STRING[6]);
    mexPrintf("  - CppAD  [v%s] (Eclipse Public License)\n",msgbuf);  
    mexPrintf("  - MUMPS  [v%s]\n",MUMPS_VERSION);
    mexPrintf("  - METIS  [v4.0.3] (Copyright University of Minnesota)\n");
    #ifdef HAVE_ASL
        mexPrintf("  - ASL    [v%d] (Netlib)\n",ASLdate_ASL);
    #endif
    mexPrintf("  - Intel Math Kernel Library [v%d.%d R%d]\n",__INTEL_MKL__,__INTEL_MKL_MINOR__,__INTEL_MKL_UPDATE__);
    
    mexPrintf("\n And is dynamically linked to the following software:\n");
    mexPrintf("  - MA57   [v3.0] (Included as part of the MATLAB distribution)\n");
    
    mexPrintf("\n MEX Interface J.Currie 2013 (www.i2c2.aut.ac.nz)\n");
    mexPrintf("-----------------------------------------------------------\n");
}
