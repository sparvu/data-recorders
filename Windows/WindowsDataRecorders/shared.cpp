/*
 *  sdrlib
 *  shared library for recorders
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
#include "shared.h"
//#define	REC_TEST_CONSOLE 
wofstream *defaultlog;
std::wstring FromVariant(VARIANT& vt) {
	_bstr_t bs(vt);
	return std::wstring(static_cast<const wchar_t*>(bs));
}

std::wstring AppPath() {
	WCHAR szPath[MAX_PATH];

	GetModuleFileName(NULL, szPath, FILENAME_MAX);
	wstring appPath(szPath);
	appPath = appPath.substr(0, appPath.find_last_of(L"\\"));
	appPath = appPath.substr(0, appPath.find_last_of(L"\\"));
	return appPath;
}

int Init(RecorderProperties *ws, wstring name) {

	ws->pLoc = NULL;
	ws->pSvc = NULL;
	ws->treminateFlag = false;

	//recoder logs initialisation

	ws->parameters.name = name;
	wstring preLog = AppPath() + L"\\SDRpreinit_" + name + L"rec.log";
	OpenFileStream(ws->logStream, preLog);
	SetDefaultLog(ws->logStream);
	pugi::xml_document config;

	if (int initConfigResult = InitConfig(config) != status_ok) {
		return initConfigResult;
	}

	wstring recorderXpath = L"/sdr/recording/recorders/sdrd[@name='"
			+ ws->parameters.name + L"']";
	pugi::xml_node recorderConfigNode = config.select_single_node(
			recorderXpath.data()).node();

	if ((ws->parameters.interval =
			recorderConfigNode.attribute(L"interval").as_int()) == 0
			&& ws->parameters.interval <= 1) {
		ws->parameters.interval = 60;
	}

	if ((ws->parameters.countTotal =
			recorderConfigNode.attribute(L"count").as_int()) == 0
			&& ws->parameters.countTotal < -1) {
		ws->parameters.countTotal = -1;
	}

	//for archive testing
	if ((ws->parameters.archiveInterval = recorderConfigNode.attribute(
			L"archiveat").as_int()) == 0)
		ws->parameters.archiveInterval = -1;

	wstring apppath = AppPath();
	ws->parameters.rawCurrentPath =
			apppath
					+ config.select_single_node(L"/sdr/recording/logs/current").node().attribute(
							L"path").as_string();
	if (ws->parameters.rawCurrentPath.empty()) {
		WriteFileLogf(L"Failed to init configuration, code here:");
		return status_config_file_not_found;
	}

	ws->parameters.logDailyPath =
			apppath
					+ config.select_single_node(L"/sdr/recording/logs/daily").node().attribute(
							L"path").as_string();
	if (ws->parameters.logDailyPath.empty()) {
		WriteFileLogf(L"Failed to init configuration, code here:");
		return status_config_file_not_found;

	}

	ws->sysLogPath = ws->parameters.rawCurrentPath + ws->parameters.name
			+ L"rec.log";
	//ws->parameters.rawCurrentFile = ws->parameters.rawCurrentPath;
	ws->parameters.rawCurrentFile += ws->parameters.name + L"rec.sdrd";

	OpenFileStream(ws->rawStream,
			ws->parameters.rawCurrentPath + ws->parameters.rawCurrentFile);
	CloseFileStream(ws->logStream);

	DeleteFile(preLog.data());

	OpenFileStream(ws->logStream, ws->sysLogPath);
	SetDefaultLog(ws->logStream);
	WriteFileLogf(L"Starting recorder " + ws->parameters.name + L"rec.");
	return status_ok;
}

int InitConfig(pugi::xml_document& config) {
	//check folders, create in dont exist
	wstring appDataPath = AppPath();

	wstring logPath;
	wstring rawCurrentPath;
	wstring logDailyPath;
	//config
	wstring configFile = appDataPath + L"\\etc\\sdr.xml";
	//because service runs at windows/System32 folder
	//we forced to use absolute path

	pugi::xml_parse_result result = config.load_file(configFile.data());
	if (result.status != pugi::status_ok) {
		return status_config_file_not_found;
	}
	//first install build directory tree

	logPath = L"\\log";
	rawCurrentPath = logPath + L"\\current\\";
	logDailyPath = logPath + L"\\daily\\";

	config.select_single_node(L"/sdr/recording/logs/base").node().attribute(
			L"path").set_value(logPath.data());
	config.select_single_node(L"/sdr/recording/logs/current").node().attribute(
			L"path").set_value(rawCurrentPath.data());
	config.select_single_node(L"/sdr/recording/logs/daily").node().attribute(
			L"path").set_value(logDailyPath.data());

	config.save_file(configFile.data());

	logPath = appDataPath + logPath;
	rawCurrentPath = appDataPath + rawCurrentPath;
	logDailyPath = appDataPath + logDailyPath;

	//create config folderst
	CreateDirectory(logPath.data(), 0);
	if (GetLastError() == ERROR_PATH_NOT_FOUND)
		return status_path_not_found;
	CreateDirectory(rawCurrentPath.data(), 0);
	if (GetLastError() == ERROR_PATH_NOT_FOUND)
		return status_path_not_found;
	CreateDirectory(logDailyPath.data(), 0);
	if (GetLastError() == ERROR_PATH_NOT_FOUND)
		return status_path_not_found;

	return status_ok;
}

void WriteResultConsole(map<wstring, map<wstring, wstring>> &resultData) {

	for (map<wstring, map<wstring, wstring>>::const_iterator iterator =
			resultData.begin(), end = resultData.end(); iterator != end;
			++iterator) {
		pair<wstring, map<wstring, wstring>> dataSet = *iterator;
		wcout << "set: " << dataSet.first << endl;
		for (map<wstring, wstring>::const_iterator setIterator =
				dataSet.second.begin(), end = dataSet.second.end();
				setIterator != end; ++setIterator) {
			pair<wstring, wstring> dataPair = *setIterator;
			wcout << "\t" << dataPair.first << " : " << dataPair.second << endl;
		}
	}
}

int WriteFileRaw(wofstream &myfile, wstring resultData) {
	if (myfile.is_open()) {
		myfile << std::time(NULL) << L":" << resultData << endl;
		myfile.flush();
	} else
		return status_query_failed;
	return status_ok;
}

int OpenFileStream(wofstream &myfile, wstring fileName, bool recreate) {

	if (recreate)
		myfile.open(fileName, ios::out);
	else
		myfile.open(fileName, ios::out | ios::app);
	if (myfile.is_open()) {
		std::locale loc(std::locale::classic(), new std::codecvt_utf8<wchar_t>);
		myfile.imbue(loc);
		return status_ok;
	} else
		return status_io_error;
}

int CloseFileStream(wofstream &myfile) {
	if (myfile.is_open()) {
		myfile.flush();
		myfile.close();
	}
	return status_ok;
}

void SetDefaultLog(wofstream &myfile) {
	defaultlog = &myfile;

}

int WriteFileLog(wofstream &myfile, wstring data) {
	if (myfile.is_open()) {
		struct tm lt;

		time_t now_local = time(NULL);
		localtime_s(&lt, &now_local);

		wchar_t szBuf[2148] = L"";
		_snwprintf_s(szBuf, 2148, 2148, L"[%d-%02d-%02d %02d:%02d:%02d]: %s",
				lt.tm_year + 1900, lt.tm_mon + 1, lt.tm_mday, lt.tm_hour,
				lt.tm_min, lt.tm_sec, data.data());
		myfile << szBuf << endl;
#ifdef REC_TEST_CONSOLE
		wcout<< szBuf << endl;
#endif

		myfile.flush();
	} else
		return status_query_failed;
	return status_ok;
}

int ArchiveFileRaw(RecorderProperties *ws, bool sender) {

	if (CloseFileStream(ws->rawStream) != status_ok) {
		return status_io_error;
	}
	if (CloseFileStream(ws->logStream) != status_ok) {
		return status_io_error;
	}

	time_t now_local = time(NULL);

	struct tm lt;

	now_local -= 3600; //prev day
	localtime_s(&lt, &now_local);

	wchar_t szBuf[MAX_PATH];
	_snwprintf(szBuf, MAX_PATH, L"%d-%02d-%02d\\", lt.tm_year + 1900,
			lt.tm_mon + 1, lt.tm_mday);
	wstring todayFolder = ws->parameters.logDailyPath + szBuf;

	CreateDirectory(todayFolder.data(), 0);
	HZIP todayZip;
	ZRESULT zipResult;
	//ziping raw
	if (!sender) {
		wstring archiveRawFilePath = todayFolder + ws->parameters.rawCurrentFile
				+ L".zip";
		todayZip = CreateZip((void*) archiveRawFilePath.data(), 0,
		ZIP_FILENAME);
		zipResult = ZipAdd(todayZip, ws->parameters.rawCurrentFile.data(),
				(void*) (ws->parameters.rawCurrentPath
						+ ws->parameters.rawCurrentFile).data(), 0,
				ZIP_FILENAME);
		CloseZip(todayZip);
		if (zipResult != ZR_OK) {
			WriteFileLogf(L"Raw zip creation failed");
		}
	}

	//ziping log
	wstring archiveLogFilePath = todayFolder + ws->parameters.name + L"log.zip";
	todayZip = CreateZip((void*) archiveLogFilePath.data(), 0, ZIP_FILENAME);
	wstring logFile = wstring(ws->parameters.name + L"rec.log");
	zipResult = ZipAdd(todayZip, logFile.data(),
			(void*) (ws->parameters.rawCurrentPath + logFile).data(), 0,
			ZIP_FILENAME);
	CloseZip(todayZip);
	if (zipResult != ZR_OK) {
		WriteFileLogf(L"Log zip creation failed");
	}

	if (!sender
			&& OpenFileStream(ws->rawStream,
					ws->parameters.rawCurrentPath
							+ ws->parameters.rawCurrentFile, true)
					!= status_ok) {
		return status_io_error;
	}

	if (OpenFileStream(ws->logStream, ws->sysLogPath, true) != status_ok) {
		return status_io_error;
	}

	return status_ok;
}

int WMIRequest(IWbemServices* pSvc, IWbemLocator* pLoc,
		std::list<BSTR> requests,
		map<wstring, map<wstring, wstring>> &resultData, BSTR query) {
	if (pSvc == NULL || pLoc == NULL) {
		return status_query_failed;
	}

	HRESULT hres;

	IEnumWbemClassObject* pEnumerator = NULL;
	hres = pSvc->ExecQuery(L"WQL", query,
			WBEM_FLAG_FORWARD_ONLY | WBEM_FLAG_RETURN_IMMEDIATELY, NULL,
			&pEnumerator);

	if (FAILED(hres)) {
		return status_query_failed;
	}

	// Get the data from the WQL sentence
	IWbemClassObject *pclsObj = NULL;
	ULONG uReturn = 0;
	resultData.clear();
	int index = 0;
	while (pEnumerator) {
		HRESULT hr = pEnumerator->Next(WBEM_INFINITE, 1, &pclsObj, &uReturn);

		if (0 == uReturn || FAILED(hr))
			break;

		VARIANT vtProp;

		//get name
		hr = pclsObj->Get(L"Name", 0, &vtProp, 0, 0); // Uint32
		wstring mapKey = L"";
		if (!FAILED(hr)) {
			if ((vtProp.vt == VT_NULL) || (vtProp.vt == VT_EMPTY)) {
				wchar_t szBuf[20];
				wsprintf(szBuf, L"%Id", index++);
				mapKey.append(szBuf);
			} else
				mapKey = FromVariant(vtProp);
		}

		VariantClear(&vtProp);
		resultData.insert(
				std::pair<wstring, map<wstring, wstring>>(mapKey,
						map<wstring, wstring>()));

		for (std::list<BSTR>::const_iterator iterator = requests.begin(), end =
				requests.end(); iterator != end; ++iterator) {
			BSTR req = *iterator;
			hr = pclsObj->Get(req, 0, &vtProp, 0, 0); // Uint32
			wstring value = L"";
			if (!FAILED(hr)) {
				if ((vtProp.vt == VT_NULL) || (vtProp.vt == VT_EMPTY)) {
					value = L"NULL";
				} else {

					value = FromVariant(vtProp);
				}
				resultData[mapKey].insert(
						std::pair<wstring, wstring>(req, value));
			}
			VariantClear(&vtProp);

		}
		pclsObj->Release();
		pclsObj = NULL;
	}

	pEnumerator->Release();
	if (pclsObj != NULL)
		pclsObj->Release();

	return status_ok;
}

int WMIConnect(IWbemServices **pSvc_g, IWbemLocator **pLoc_g) {
	IWbemLocator *pLoc = NULL;
	IWbemServices *pSvc = NULL;
	BSTR strNetworkResource;
	HRESULT hres;
	strNetworkResource = L"ROOT\\CIMV2";

	// Initialize COM. ------------------------------------------

	hres = CoInitializeEx(0, COINIT_MULTITHREADED);
	if (FAILED(hres)) {
		return status_connection_failed;
	}

	// Set general COM security levels --------------------------

	hres = CoInitializeSecurity(
	NULL, -1,                          // COM authentication
			NULL,                        // Authentication services
			NULL,                        // Reserved
			RPC_C_AUTHN_LEVEL_DEFAULT,   // Default authentication
			RPC_C_IMP_LEVEL_IMPERSONATE, // Default Impersonation
			NULL,                        // Authentication info
			EOAC_NONE,                   // Additional capabilities
			NULL                         // Reserved
			);

	if (FAILED(hres)) {
		cout << "Failed to initialize security. Error code = 0x" << hex << hres
				<< endl;
		cout << _com_error(hres).ErrorMessage() << endl;
		return status_connection_failed;                  // Program has failed.
	}

	// Obtain the initial locator to WMI -------------------------

	hres = CoCreateInstance(CLSID_WbemLocator, 0, CLSCTX_INPROC_SERVER,
			IID_IWbemLocator, (LPVOID *) &pLoc);

	if (FAILED(hres)) {
		cout << "Failed to create IWbemLocator object." << " Err code = 0x"
				<< hex << hres << endl;
		cout << _com_error(hres).ErrorMessage() << endl;
		return status_connection_failed;                 // Program has failed.
	}

	// Connect to WMI through the IWbemLocator::ConnectServer method

	hres = pLoc->ConnectServer(_bstr_t(strNetworkResource),
	NULL,
	NULL, 0,
	NULL, 0, 0, &pSvc);

	if (FAILED(hres)) {
		return status_connection_failed;
	}

	// Set security levels on the proxy -------------------------
	hres = CoSetProxyBlanket(pSvc, RPC_C_AUTHN_WINNT, RPC_C_AUTHZ_NONE,
	NULL, RPC_C_AUTHN_LEVEL_CALL, RPC_C_IMP_LEVEL_IMPERSONATE,
	NULL, EOAC_NONE);

	if (FAILED(hres)) {
		return status_connection_failed;               // Program has failed.
	}
	*pLoc_g = pLoc;
	*pSvc_g = pSvc;
	return status_ok;
}

int SecSinceMidnight() {
	time_t now_local = time(NULL);
	struct tm lt;
	localtime_s(&lt, &now_local);
	int sec_local = lt.tm_hour * 3600 + lt.tm_min * 60 + lt.tm_sec;
	return sec_local;
}

double GetCounterTotal(PDH_HCOUNTER &hCounter) {
	double value = 0;
	PDH_STATUS status = ERROR_SUCCESS;
	DWORD dwBufferSize = 0;         // Size of the pItems buffer
	DWORD dwItemCount = 0;          // Number of items in the pItems buffer
	PDH_FMT_COUNTERVALUE_ITEM *pItems = NULL;
	status = PdhGetFormattedCounterArray(hCounter, PDH_FMT_DOUBLE,
			&dwBufferSize, &dwItemCount, pItems);
	if (PDH_MORE_DATA == status) {
		pItems = (PDH_FMT_COUNTERVALUE_ITEM *) malloc(dwBufferSize);
		if (pItems) {
			status = PdhGetFormattedCounterArray(hCounter, PDH_FMT_DOUBLE,
					&dwBufferSize, &dwItemCount, pItems);
			if (ERROR_SUCCESS == status) {

				for (DWORD i = 0; i < dwItemCount; i++) {
					value += pItems[i].FmtValue.doubleValue;
				}
			}

			free(pItems);
			pItems = NULL;
			dwBufferSize = dwItemCount = 0;
		} else {

			WriteFileLogf(L"PdhGetFormattedCounterArray2 failed with 0x%x.\n",
					status);
			throw status;
		}
	}

	else {
		WriteFileLogf(
				L"PdhGetFormattedCounterArray failed with 0x%x. counter: %x \n",
				status, &hCounter);
		throw status;
	}
	return value;
}
vector<wstring> GetCounterNames(PDH_HCOUNTER &hCounter) {
	vector<wstring> names = vector<wstring>();

	PDH_STATUS status = ERROR_SUCCESS;
	DWORD dwBufferSize = 0;
	DWORD dwItemCount = 0;
	PDH_FMT_COUNTERVALUE_ITEM *pItems = NULL;
	status = PdhGetFormattedCounterArray(hCounter, PDH_FMT_DOUBLE,
			&dwBufferSize, &dwItemCount, pItems);
	if (PDH_MORE_DATA == status) {
		pItems = (PDH_FMT_COUNTERVALUE_ITEM *) malloc(dwBufferSize);
		if (pItems) {
			status = PdhGetFormattedCounterArray(hCounter, PDH_FMT_DOUBLE,
					&dwBufferSize, &dwItemCount, pItems);
			if (ERROR_SUCCESS == status) {

				for (DWORD i = 0; i < dwItemCount; i++) {
					names.push_back(pItems[i].szName);
				}
			}
			free(pItems);
			pItems = NULL;
			dwBufferSize = dwItemCount = 0;
		} else {
			WriteFileLogf(L"PdhGetFormattedCounterArray2 failed with 0x%x.\n",
					status);
		}
	}

	else {
		WriteFileLogf(
				L"PdhGetFormattedCounterArray failed with 0x%x. counter: %x \n",
				status, &hCounter);
	}
	return names;
}

vector<double> GetCounterVector(PDH_HCOUNTER &hCounter) {
	vector<double> proc;
	PDH_STATUS status = ERROR_SUCCESS;
	DWORD dwBufferSize = 0;
	DWORD dwItemCount = 0;
	PDH_FMT_COUNTERVALUE_ITEM *pItems = NULL;
	status = PdhGetFormattedCounterArray(hCounter, PDH_FMT_DOUBLE,
			&dwBufferSize, &dwItemCount, pItems);
	if (PDH_MORE_DATA == status) {
		pItems = (PDH_FMT_COUNTERVALUE_ITEM *) malloc(dwBufferSize);
		if (pItems) {
			status = PdhGetFormattedCounterArray(hCounter, PDH_FMT_DOUBLE,
					&dwBufferSize, &dwItemCount, pItems);
			if (ERROR_SUCCESS == status) {

				for (DWORD i = 0; i < dwItemCount; i++) {
					proc.push_back(pItems[i].FmtValue.doubleValue);
				}
			} else {
				WriteFileLogf(
						L"PdhGetFormattedCounterArray2 failed with 0x%x \n",
						status);
			}

			free(pItems);
			pItems = NULL;
			dwBufferSize = dwItemCount = 0;
		} else {
			WriteFileLogf(L"PdhGetFormattedCounterArray2 failed with 0x%x.\n",
					status);
		}
	}

	else {
		WriteFileLogf(
				L"PdhGetFormattedCounterArray failed with 0x%x. counter: %x \n",
				status, &hCounter);
	}
	return proc;
}
wstring GetEnglishPdhQuery(int counter, int subCounter, bool wildcard,
		wstring custom) {
	wstring result = L"\\";
	PDH_STATUS status = ERROR_SUCCESS;
	TCHAR szCompName[MAX_PATH] = { };
	DWORD dw = 0;
	GetComputerName(szCompName, &dw);

	status = PdhLookupPerfNameByIndexW(NULL, counter, NULL, &dw);
	TCHAR *szBuf = new TCHAR[dw];
	status = PdhLookupPerfNameByIndexW(NULL, counter, szBuf, &dw);

	if (status != ERROR_SUCCESS && status != PDH_INSUFFICIENT_BUFFER) {
		WriteFileLogf(L"PdhLookupPerfNameByIndex failed with 0x%x.\n", status);
	}

	result.append(szBuf);

	if (wildcard == true)
		result.append(L"(*)");

	if (!custom.empty()) {
		result.append(custom);
	}

	result.append(L"\\");

	delete[] szBuf;

	dw = 0;
	status = PdhLookupPerfNameByIndexW(NULL, subCounter, NULL, &dw);
	szBuf = new TCHAR[dw];
	status = PdhLookupPerfNameByIndexW(NULL, subCounter, szBuf, &dw);

	if (status != ERROR_SUCCESS && status != PDH_INSUFFICIENT_BUFFER) {
		WriteFileLogf(L"PdhLookupPerfNameByIndex2 failed with 0x%x.\n", status);
	}
	result.append(szBuf);

	wcout << result.data() << endl;
	delete[] szBuf;

	return result;
}

int WriteFileLogf(wstring fmt, ...) {
	wchar_t szBuf[2048] = L"";
	va_list args;
	va_start(args, fmt);
	_snwprintf_s(szBuf, 2048, 2048, fmt.data(), args);
	WriteFileLog(*defaultlog, wstring(szBuf));
	va_end(args);
	return 0;
}
