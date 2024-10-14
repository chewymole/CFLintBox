/**
 * Copyright Since 2005 Ortus Solutions, Corp
 * www.ortussolutions.com
 * *************************************************************************************
 */
component {

	this.name              = "CFLintBox";
	// any other application.cfc stuff goes below:
	this.sessionManagement = true;
	_loadConfig();

	// any mappings go here, we create one that points to the root called test.
	this.mappings[ "/tests" ] = getDirectoryFromPath( getCurrentTemplatePath() );
	this.mappings[ "/webroot" ] = expandPath( this.config.directoryToTest );
	// ADD MAPPINGS HERE TO YOUR FILE DIRECTORYS
	// example: this.mappings[ "/model" ] = getDirectoryFromPath( "/opt/web/cfmx/model/" );
	// example: this.mappings[ "/webroot" ] = getDirectoryFromPath( "/opt/web/cfmx/wwwroot/" );

	this.javaSettings = {
		LoadPaths = [expandPath( "./CFLint-1.5.0-all.jar" ) ], 
		loadColdFusionClassPath = true, 
		reloadOnChange = false
	};

	// if you want your tests to hit a db, add your dsn here.
	//this.datasource = "yourdsn";

	private void function _loadConfig() {
		var configFile = ExpandPath("./config.json");
		this.config = DeserializeJSON(FileRead(configFile, "utf-8"));		
	}

	public boolean function onApplicationStart() {		
		application.lintResults = {};
		application.testsWritten = false;
		application.config = this.config;
		

		if(NOT len(application.config?.directoryToTest)){
			writeOut("No directory specified 'directoryToTest' in config.json or missing config.json");
			abort;
		}

		if(NOT len(application.config?.runTestBox)){
			application.config.runTestBox = false;
		}

		try{
			// build the file system array
			application.fileSystem = _get_file_paths( application.config.directoryToTest );
			sleep(2000);
		} catch(any e){
			writeDump(e);
			abort;
		}
		

		try{
			// build the file sys array and run testBox writter
			_buildLintArray(true, NOT application.config.runTestBox );
			
			sleep(2000);
		} catch(any e){
			writeDump(e);
			abort;
		}
		
		
		application.started = now();
		return true;
	}


	// request start
	public boolean function onRequestStart( string targetPage ){
		if(LEN(url?.reload) ){
			applicationStop();
			writeOutput("Application stopped");
			abort;
		}
		// debug the results
		if(LEN(url?.dumpResults)){
			writeDump(application.filesystem);
			writeDump(application.lintResults);
			abort;
		}
		return true;
	}

	private array function _get_file_paths(required string directory) {
		var file_paths = [];		
		var dir = directoryList(arguments.directory, true, "query");
		for (var filez in dir) {
			var fdir = replace(filez.directory, "\", "/", "all");
			if( NOT fdir contains "WEB-INF" ) {

				if (filez.type == "file" AND listFindNoCase("cfc,cfm", listLast(filez.name,".") )) {
					arrayAppend(file_paths, fdir & "/" & filez.name);
				} else if (filez.type == "dir") {
					_get_file_paths(fdir & "/" & filez.name);				
				}
			}
		}
		return file_paths;
	}

	// Build out the application.lintResults cfcs and cfms and file elements
	private any function _buildLintArray(boolean runTestBox = false, boolean asHTML = false) {
		var ret = {
			cfcs = [],
			cfms = [],
			files = []
		};
		// Get a list of all the CF files in the specified directory
		//var files = application.fileSystem;
		var reportPath = getDirectoryFromPath( getCurrentTemplatePath() ) & "results/";
		// Loop through each CF file
		for (var f in application.fileSystem) {
			var p = replaceNoCase(f,application.config.directoryToTest,"");
			p = replaceNoCase(p,".","_","all");
			p = replaceNoCase(p,"/",".","all");
			var rfn = "file_" & p & ".json";
			ret.files.append({name=rfn,path=f,report=reportPath & rfn});
			if(listLast(f,".") eq "cfc") {
				var c = replaceNoCase(f,application.config.directoryToTest,"/webroot/","all");
				var md = getComponentMetadata(c);
				if(arguments.asHTML){
					exeCFLintResult(f,rfn,"-html -htmlfile");
				} else {
					exeCFLintResult(f,rfn);
					//getCFLintResult(f);
				}				
				ret.cfcs.append({Metadata=md,Path=f,report=reportPath & rfn});
				
			} else if(listLast(f,".") eq "cfm") {				
				if(arguments.asHTML){
					exeCFLintResult(f,rfn,"-html -htmlfile");
				} else {
					exeCFLintResult(f,rfn);
				}		
				ret.cfms.append({Metadata={},Path=f,report=reportPath & rfn});
			}		
		}

		application.lastLinted = now();
		application.lintResults = ret;

		if(arguments.runTestBox){
			application.testsWritten = writeTests(ret.files);		
		}

		return ret;
	  }
	  
	  // Get the CFC Lint result via Java, does not seem to work..
	  public any function getCFLintResult(string filePath) {		
		var japi = "";
		var res = "";
		var api = createObject("java", "com.cflint.api.CFLintAPI");
		var jresult = createObject("java", "com.cflint.api.CFLintResult");
		var fp = rereplacenocase(arguments.filePath, "/", "\", "all");
		//api.setVerbose(false);
		//api.setQuiet(false);
		//api.setDebug(false);
		jresult = api.scan(fp);
		res = deserializeJSON(jresult.getJson());

		writeDump( {f = fp,a=api.getResults().size(), r = res, j= jresult}  );
		abort;
		//jresult = result.init(japi);
		return japi.getJSON();
		//return jsonResult;
	  }

	  // Execute the CFC Lint through a batch file that then runs the java jar
	  public any function exeCFLintResult(required string filePath, required string reportPath, string type = '-json -jsonfile') {  
		var p = expandPath("./run_jar.sh");
		var w = expandPath("./run_jar.bat");
		var wh = expandPath("./run_jar_html.bat");
		var os = server.os.name;
		var args = " " & arguments.filePath;
		try{
			if(os contains "windows"){
				if(arguments.type eq "-html -htmlfile"){
					cfexecute(name=wh, arguments = args & " " & arguments.reportPath);
				} else {
					cfexecute(name=w, arguments = args & " " & arguments.reportPath);
				}
			} else{
				//writeDump(os);
				cfexecute(name="#p#", arguments = args & " " & arguments.reportPath & " " & arguments.type);
			}
		} catch(any e){
			writeDump(e);
			abort;
		}
	  }


	  // Write the CF Lint tests to a cfm that gets included in the specs/lintingServiceTest.cfc file
	  public boolean function writeTests(required array beans) {
		var tmp = fileRead(expandPath("./testFunc.txt"));
		var fp = expandPath("./specs/lintingServiceFuncs.cfm");
		var out = "<cfscript> " & chr(10);
		var bf = "";
		var tf = "";
		arguments.beans.each(function(el,i,ar){
			bf = replaceNoCase(tmp,'|FN|',el.name,'all');
			tf = replaceNoCase(el.name,'.json','','all');
			tf = replaceNoCase(tf,'.','_','all');
			bf = replaceNoCase(bf,'|FUNCNAME|', tf,'all');
			out &= bf;	
		});


		out &= chr(10) & " </cfscript>";
		fileWrite(fp, out);
		return true;

	  }

	  /*
	 tf = replaceNoCase(fil.name, ".json", "", "all");			
			bf = replacenocase(tmp, "|FN|", fil.name, "all");
			tf = replaceNoCase(tf, ".", "_", "all");
			bf = replaceNoCase(bf, "|FUNCNAME|", tf, "all");
			out &= bf;	 
	  */
}
