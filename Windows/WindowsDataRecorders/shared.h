/*
 *  Sdrlib
 *  Shared library for SystemDataRecorders
 *
 *  Copyright (c) 2014 DigitAir Servicii Informatice SRL
 *  Bucharest, Romania
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 2
 *  of the License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software Foundation,
 *  Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 *  (http://www.gnu.org/copyleft/gpl.html)
 */

#define _WIN32_DCOM
#include <iostream>
#include <comdef.h>
#include <list>
#include <map>
#include <vector>
#include <iterator>
#include <Wbemidl.h>
#include <string>
#include <sstream>
#include <ctime>
#include <locale>
#include <fstream>

#include <shlwapi.h>
#include <pdh.h>
#include <PdhMsg.h>
#include <iphlpapi.h>
#include "shlobj.h"
#include "xzip\XZip.h"
#include "pugixml-1.2\pugixml.hpp"
#include <atlconv.h>
#include <WinSvc.h>
#include <tchar.h>
#include <codecvt>
#define WCOLON  L":"
#define REQUESTCHECK status_ok && requestResult == status_ok?status_ok:status_query_failed
#pragma comment(lib, "pdh.lib")
#pragma comment(lib,"shlwapi.lib")
#pragma comment(lib, "iphlpapi.lib")
#pragma comment(lib, "wbemuuid.lib")

using namespace std;
//#pragma argsused

enum status {
	status_ok = 0,
	status_query_failed,
	status_connection_failed,
	status_config_file_not_found,
	status_io_error,
	status_path_not_found,
	status_out_of_memory,
	status_internal_error
};

struct RecorderParameters {
	wstring rawCurrentPath;
	wstring rawCurrentFile;
	wstring logDailyPath;
	wstring name;
	int countTotal;
	int interval;
	int archiveInterval;
};

struct RecorderProperties {
	wofstream rawStream;
	wofstream logStream;
	IWbemLocator *pLoc;
	IWbemServices *pSvc;
	HRESULT hres;
	bool treminateFlag;
	wstring sysLogPath;
	RecorderParameters parameters;

};

std::wstring __declspec(dllexport) FromVariant(VARIANT& vt);

std::wstring __declspec(dllexport) AppPath();

int __declspec(dllexport) Init(RecorderProperties *ws, wstring name);

int __declspec(dllexport) InitConfig(pugi::xml_document& config);

void __declspec(dllexport) WriteResultConsole(
		map<wstring, map<wstring, wstring>> &resultData);

int __declspec(dllexport) WriteFileRaw(wofstream &myfile, wstring resultData);

int __declspec(dllexport) WriteFileLog(wofstream &myfile, wstring data);

int __declspec(dllexport) WriteFileLogf(wstring fmt, ...);

int __declspec(dllexport) OpenFileStream(wofstream &myfile, wstring fileName,
		bool recreate = false);

int __declspec(dllexport) CloseFileStream(wofstream &myfile);

void __declspec(dllexport) SetDefaultLog(wofstream &myfile);

int __declspec(dllexport) ArchiveFileRaw(RecorderProperties *ws, bool sender =
		false);

int __declspec(dllexport) WMIRequest(IWbemServices* pSvc, IWbemLocator* pLoc,
		std::list<BSTR> requests,
		map<wstring, map<wstring, wstring>> &resultData, BSTR query);

int __declspec(dllexport) WMIConnect(IWbemServices **pSvc_g,
		IWbemLocator **pLoc_g);

int __declspec(dllexport) SecSinceMidnight();

double __declspec(dllexport) GetCounterTotal(PDH_HCOUNTER &hCounter);

vector<wstring> __declspec(dllexport) GetCounterNames(PDH_HCOUNTER &hCounter);

vector<double> __declspec(dllexport) GetCounterVector(PDH_HCOUNTER &hCounter);

wstring __declspec(dllexport) GetEnglishPdhQuery(int counter, int subCounter,
		bool wildcard = false , wstring custom = L"" );

