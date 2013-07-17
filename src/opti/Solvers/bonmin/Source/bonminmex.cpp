/* BONMINMEX - A MEX Interface to BONMIN MINLP Solver
 * Copyright (C) Jonathan Currie 2011 (I2C2)
 */

/* Based heavily (if not all) on the IPOPT interface by Peter Carbonetto */

#include "mex.h"
#include "Coin_C_defines.h"
#include "config_bonmin_default.h"
#include "config_ipopt_default.h"
#include "config_cbc_default.h"
#include "config_cgl_default.h"
#include "config_clp_default.h"
#include "config_coinutils_default.h"
#include "config_osi_default.h"
#include "mkl.h"
#include "dmumps_c.h"  

#include "iterate.hpp"
#include "options.hpp"
#include "matlabinfo.hpp"
#include "matlabexception.hpp"
#include "matlabjournal.hpp"
#include "callbackfunctions.hpp"
#include "matlabprogram.hpp"

#include "BonOsiTMINLPInterface.hpp"
#include "BonIpoptSolver.hpp"
#include "BonCbc.hpp"
#include "BonBonminSetup.hpp"
#include "BonBabSetupBase.hpp"

#include "CoinMessageHandler.hpp"

#ifdef HAVE_CPLEX
   #include "cpxconst.h"
#endif        

#include <exception>
      
        
using namespace std;
using namespace Ipopt;
using namespace Bonmin;

//Message Handler
class DerivedHandler : public CoinMessageHandler {
public:
	virtual int print() ;
    virtual DerivedHandler * clone() const;
};
int DerivedHandler::print()
{
	mexPrintf(messageBuffer());
	mexPrintf("\n");
    mexEvalString("drawnow;"); //flush draw buffer
	return 0;
}
DerivedHandler * DerivedHandler::clone() const
{
  return new DerivedHandler(*this);
}

void printSolverInfo();

//Main Function
void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[])
{
    int printLevel = 0;
    DerivedHandler *mexprinter = NULL;
    
    try {
        //Header
        if(nrhs < 1) {
            if(nlhs < 1)
                printSolverInfo();
            else
                plhs[0] = mxCreateString(BONMIN_VERSION);
            return;
        }      

        // Check to see if we have the correct number of input and output arguments.
        if (nrhs != 3)
          throw MatlabException("Incorrect number of input arguments");
        if (nlhs != 2)
          throw MatlabException("Incorrect number of output arguments");
        
        // See if we are printing messages
        if(mxGetField(prhs[2],0,"display"))
            printLevel = (int)*mxGetPr(mxGetField(prhs[2],0,"display"));
        else
            printLevel = 0;
        
        // Get the first input which specifies the initial iterate.
        Iterate x0(mxDuplicateArray(prhs[0]));

        // Get the second input which specifies the callback functions.
        CallbackFunctions funcs(prhs[1]);
        
        //Append linear constraints if present
        if(mxGetField(prhs[2],0,"A") && !mxIsEmpty(mxGetField(prhs[2],0,"A"))) 
            funcs.appLinearConstraints(mxGetField(prhs[2],0,"A"));

        //Setup our Message Handler                
        if(printLevel) {
            mexprinter = new DerivedHandler();
            mexprinter->setLogLevel(printLevel); 
        }
                
        // Create a new Bonmin setup object and process the options.
        BonminSetup app(mexprinter);
        app.initializeOptionsAndJournalist();
        Options options(x0,app,prhs[2]);
        
        // Set up the BONMIN console
        if(printLevel) {
            //Create Journal to receive BONMIN messages
            SmartPtr<Journal> console = new MatlabJournal((EJournalLevel)printLevel);
            app.journalist()->AddJournal(console); 
        }
        
        // The first output argument is the value of the optimization variables obtained at the solution.
        plhs[0] = mxDuplicateArray(x0);
        Iterate x(plhs[0]);        

        // The second output argument stores other information, such as
        // the exit status, the value of the Lagrange multipliers upon
        // termination, the final state of the auxiliary data, and so on.
        MatlabInfo info(plhs[1]);

        // Check to see whether the user provided a callback function for
        // computing the Hessian. This is not needed in the special case
        // when a quasi-Newton approximation to the Hessian is being used.
        if (!options.bonminOptions().useQuasiNewton() && !funcs.hessianFuncIsAvailable())
          throw MatlabException("You must supply a callback function for computing the Hessian unless you decide to use a quasi-Newton approximation to the Hessian");

        // If the user tried to use her own scaling, report an error.
        if (options.bonminOptions().userScaling())
          throw MatlabException("The user-defined scaling option does not work in the MATLAB interface for BONMIN");
        
        //If the user supplied linear constraints, see if we can enable constant jac
        if(funcs.linearAIsAvailable()) {
            int nl = options.numNLconstraints();
            //If no nonlinear constraints, set all linear
            if(!nl) {
                //Set in relaxed solver (BONMIN is done automatically in options)
                app.options()->SetStringValue("jac_c_constant","yes");
                app.options()->SetStringValue("jac_d_constant","yes");
            }
            //Else check if any inequality or equality constraints are nonlinear
            else {
                bool nlEq=false, nlIneq=false;
                const double *cl = options.constraintlb(), *cu = options.constraintub();
                for(int i = 0; i < nl; i++)
                    if(cl[i] == cu[i])
                        nlEq = true;
                    else
                        nlIneq = true;
                //Enable relaxed solver options based on what we found above (BONMIN is done automatically in options)
                if(!nlEq) app.options()->SetStringValue("jac_c_constant","yes");
                if(!nlIneq) app.options()->SetStringValue("jac_d_constant","yes");
            }
        }
        
        /*** EDIT FOR LIBMWMA57 ***/
        //If using MA57 assume MathWorks version, disable MeTiS use (crashes on uncon problem)
        #ifdef haveMA57
            if (!options.bonminOptions().usingMA57()) {
                int value;
                app.options()->GetIntegerValue("ma57_pivot_order",value,"");
                if(value > 3) {
                    //mexWarnMsgTxt("overriding ma57 pivot order to option 2 (no MeTiS).");
                    app.options()->SetIntegerValue("ma57_pivot_order",2); }
            }
        #endif
        
        // Create a new instance of the constrained, mixed integer nonlinear program.
        MatlabProgram* matlabProgram = new MatlabProgram(x0,funcs,options,x,options.getAuxData(),info);
        SmartPtr<TMINLP> program = matlabProgram;

        // Intialize the Bonmin Setup object and process the options.
        try
        {
            app.initialize(GetRawPtr(program));
        }
        catch(...)
        {
            mexErrMsgTxt("Error initializing BONMIN problem!");
        }

        // Ask Bonmin to solve the problem.       
        Bab bb;        
        try
        {            
            bb(app); 
        }
        catch (std::exception& error) 
        {
            mexErrMsgTxt(error.what());
        }
        catch(...)
        {
            mexErrMsgTxt("Error running BONMIN solver, ensure your problem is not infeasible at the root node.");
        }
        
        // Collect statistics about Bonmin run
        info.setIterationCount(bb.iterationCount());  
        info.setNumNodes(bb.numNodes());
        info.setExitStatus(bb.mipStatus());
        //If feasible solution found, get best (relaxed)
        info.setBestObj(bb.continuousRelaxation());        

        // Free the dynamically allocated memory.
        mxDestroyArray(x0);
    } 
    catch (std::exception& error) 
    {
        mexErrMsgTxt(error.what());
    }
    catch(...)
    {
        mexErrMsgTxt("Error in BONMIN MEX Interface");
    }
}               

//Print Solver Information
void printSolverInfo()
{    
    mexPrintf("\n-----------------------------------------------------------\n");
    mexPrintf(" BONMIN: Basic Open Source Nonlinear Mixed Integer Optimizer [v%s]\n",BONMIN_VERSION);
    mexPrintf("  - Released under the Eclipse Public License: http://opensource.org/licenses/eclipse-1.0\n");
    mexPrintf("  - Source available from: https://projects.coin-or.org/Bonmin\n\n");
    
    mexPrintf(" This binary is statically linked to the following software:\n");
    mexPrintf("  - Ipopt  [v%s] (Eclipse Public License)\n",IPOPT_VERSION);
    mexPrintf("  - CBC    [v%s] (Eclipse Public License)\n",CBC_VERSION);
    mexPrintf("  - CGL    [v%s] (Eclipse Public License)\n",CGL_VERSION);
    mexPrintf("  - CLP    [v%s] (Eclipse Public License)\n",CLP_VERSION);
    mexPrintf("  - MUMPS  [v%s]\n",MUMPS_VERSION);
    mexPrintf("  - METIS  [v4.0.3] (Copyright University of Minnesota)\n");
    mexPrintf("  - CoinUtils [v%s] (Eclipse Public License)\n",COINUTILS_VERSION);
    mexPrintf("  - OSI    [v%s] (Eclipse Public License)\n",OSI_VERSION);
    mexPrintf("  - Intel Math Kernel Library [v%d.%d R%d]\n",__INTEL_MKL__,__INTEL_MKL_MINOR__,__INTEL_MKL_UPDATE__);
    
    mexPrintf("\n And is dynamically linked to the following software:\n");
    mexPrintf("  - MA57   [v3.0] (Included as part of the MATLAB distribution)\n");
    #ifdef HAVE_CPLEX
        mexPrintf("  - CPLEX  [v%d.%d.%d]\n",CPX_VERSION_VERSION,CPX_VERSION_RELEASE,CPX_VERSION_MODIFICATION);
    #endif
    
    mexPrintf("\n MEX Interface P.Carbonetto [Modified by J.Currie 2013]\n");
    mexPrintf("-----------------------------------------------------------\n");
}
