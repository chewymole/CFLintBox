/**
* My xUnit Test
*/
component extends="testbox.system.BaseSpec"{

    /*********************************** LIFE CYCLE Methods ***********************************/
    
        // executes before all test cases
        function beforeTests(){
            if(len(application?.lastLinted) EQ 0 ){
                //applicationStop();
            } 
            variables.objs = application.lintResults.cfcs;
        }
    
    
    /*********************************** TEST CASES BELOW ***********************************/
    
        // Remember that test cases MUST start or end with the keyword 'test'
        function hasLintResultTest(){
            for(var i in variables.objs){
                $assert.isTrue(fileExists(i.report),"lint result not found");
            }
        }

        //--REPLACE--START
        include "lintingServiceFuncs.cfm";
        //--REPLACE--END
    }
    