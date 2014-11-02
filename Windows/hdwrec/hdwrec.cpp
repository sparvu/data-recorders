/*
 *  Hdwrec
 *  SystemDataRecorder hdw,sfw inventory
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
#include <fcntl.h>
#include <io.h>

using namespace std;
SERVICE_STATUS gServiceStatus = { 0 };
SERVICE_STATUS_HANDLE gStatusHandle = NULL;
HANDLE gServiceStopEvent = INVALID_HANDLE_VALUE;
HANDLE gDoneEvent;
#define SERVICE_NAME  _T("hdw")

//uncomment for console run
//#define	REC_TEST_CONSOLE

VOID WINAPI ServiceMain(DWORD argc, LPTSTR *argv);
DWORD WINAPI ServerCtrlHandlerEx(DWORD, DWORD, LPVOID, LPVOID);
DWORD WINAPI ServiceWorkerThread(LPVOID lpParam);
VOID CALLBACK TimerRoutine(PVOID lpParam, BOOLEAN TimerOrWaitFired);

struct SysRecData {
	wstring hostname, platform, os, codename, distributor, kernel;

	//PDHHandlers WMI usulay contains uint64
	ULONGLONG runqsz, pcpu, vcpu, memtotal, swaptotal, disks, nics, jvms,
			uptime;
};

static ULONGLONG __stdcall MyGetTickCount64() {
	static __declspec(thread)  ULONGLONG high = 0;
	static __declspec(thread)  ULONG lastLow = 0;
	const ULONG low = GetTickCount();
	if (lastLow > low) {
		high += 0x100000000I64;
	}
	lastLow = low;
	return high | (ULONGLONG) low;
}

long GetMajorVersion() {
	OSVERSIONINFO vi;
	vi.dwOSVersionInfoSize = sizeof vi;
	GetVersionEx(&vi);
	return vi.dwMajorVersion;
}
struct WMIRequests {
	list<BSTR> requestsDisk, requestsProcess, requestsNetwork, requestsComputer,
			requestsOs, requestsOsVar;
};

struct TimerParameters {
	RecorderProperties* ws;
	WMIRequests requests;
	unsigned int* count;
};

RecorderProperties *ws;
int ServiceTimerStarter(RecorderProperties* ws) {
	WMIConnect(&ws->pSvc, &ws->pLoc);

	bool archiveDone = false;

	//clock
	clock_t this_time = clock();
	clock_t last_time = this_time;
	double timeCounterSec = 0;

	WMIRequests requests;
	//lists of requested parameters
	requests.requestsDisk = list<BSTR>();
	requests.requestsDisk.push_front(L"Name");

	requests.requestsProcess = list<BSTR>();
	requests.requestsProcess.push_front(L"Name");

	requests.requestsNetwork = list<BSTR>();
	requests.requestsNetwork.push_front(L"Name");

	requests.requestsComputer = list<BSTR>();

	if (GetMajorVersion() >= 6)
		requests.requestsComputer.push_front(L"NumberOfLogicalProcessors"); //unvavliable before vista

	requests.requestsComputer.push_front(L"NumberOfProcessors");
	requests.requestsComputer.push_front(L"SystemType");

	requests.requestsOs = list<BSTR>();
	requests.requestsOs.push_front(L"TotalVisibleMemorySize");
	requests.requestsOs.push_front(L"SizeStoredInPagingFiles");
	requests.requestsOs.push_front(L"CSName");
	requests.requestsOs.push_front(L"LastBootUpTime");
	requests.requestsOs.push_front(L"OSArchitecture");
	requests.requestsOs.push_front(L"OSType");
	requests.requestsOs.push_front(L"Caption");

	requests.requestsOsVar = list<BSTR>();
	requests.requestsOs.push_front(L"LastBootUpTime");

	WriteFileLogf(L"Requesting parameters.");

	_setmode(_fileno(stdout), _O_U8TEXT);
	//Main loop

	HANDLE hTimer = NULL;
	HANDLE hTimerQueue = CreateTimerQueue();
	gDoneEvent = CreateEvent(NULL, TRUE, FALSE, NULL);

	TimerParameters *params = new TimerParameters();
	params->ws = ws;
	params->requests = requests;
	params->count = new unsigned int(0);

	if (!CreateTimerQueueTimer(&hTimer, hTimerQueue,
			(WAITORTIMERCALLBACK) TimerRoutine, (LPVOID *) params, 10,
			ws->parameters.interval * 1000, 0)) {
		WriteFileLogf(L"Failed to create CreateTimerQueueTimer.");
		return 3;
	}

	while (!ws->treminateFlag) {
		this_time = clock();
		timeCounterSec += (double) (this_time - last_time);
		last_time = this_time;

		if (*params->count >= ws->parameters.countTotal
				&& ws->parameters.countTotal != -1) {
			SetEvent(gDoneEvent);
			ws->treminateFlag = true;
			if (ws->pSvc != NULL)
				ws->pSvc->Release();
			if (ws->pLoc != NULL)
				ws->pLoc->Release();

			ws->pSvc = NULL;
			ws->pLoc = NULL;

			CloseFileStream(ws->rawStream);
			CloseFileStream(ws->logStream);

		}

		if (timeCounterSec < 0) {
			timeCounterSec = 0;
		}
		if ((int) timeCounterSec > CLOCKS_PER_SEC) {
			timeCounterSec = 0;

			int sec = SecSinceMidnight();
			if ((sec < 5 && sec >= 0 && !archiveDone)) {
				if (ArchiveFileRaw(ws) == status_ok) {
					archiveDone = true;
					WriteFileLogf(L"Archive creating success.");
				} else {
					WriteFileLogf(L"Failed to save archive.");
				}

			}
			if (sec > 5 && archiveDone) {
				archiveDone = false;
			}
		}
		Sleep(200);
	}
	return status_ok;
}

VOID CALLBACK TimerRoutine(PVOID lpParam, BOOLEAN TimerOrWaitFired) {
	// lpParam points to the argument; in this case it is an int
	TimerParameters *params = static_cast<TimerParameters*>(lpParam);

	WMIRequests r = params->requests;
	RecorderProperties *ws = params->ws;

	map<wstring, map<wstring, wstring>> resultDataDisk = map<wstring,
			map<wstring, wstring>>(), resultDataOS = map<wstring,
			map<wstring, wstring>>(), resultDataNetwork = map<wstring,
			map<wstring, wstring>>(), resultDataProcess = map<wstring,
			map<wstring, wstring>>(), resultDataComputer = map<wstring,
			map<wstring, wstring>>();

	map<wstring, map<wstring, VARIANT>> resultDataOSVariant = map<wstring,
			map<wstring, VARIANT>>();

	//requests
	int requestResult;
	int cpuCount = 0;
	SysRecData d = { };
	//-----------------------cpu----------------------------
	requestResult =
			WMIRequest(ws->pSvc, ws->pLoc, r.requestsNetwork, resultDataNetwork,
					L"SELECT Name FROM Win32_PerfFormattedData_Tcpip_NetworkInterface  where name != '_Total'");
	Sleep(10);
	requestResult =
			WMIRequest(ws->pSvc, ws->pLoc, r.requestsDisk, resultDataDisk,
					L"SELECT Name FROM Win32_PerfFormattedData_PerfDisk_PhysicalDisk  where name != '_Total'")
					== REQUESTCHECK;
	Sleep(10);
	requestResult =
			WMIRequest(ws->pSvc, ws->pLoc, r.requestsOs, resultDataOS,
					L"SELECT * FROM Win32_OperatingSystem") == REQUESTCHECK;
	Sleep(10);
	requestResult =
			WMIRequest(ws->pSvc, ws->pLoc, r.requestsComputer,
					resultDataComputer, L"SELECT * FROM Win32_ComputerSystem")
					== REQUESTCHECK;

	requestResult =
			WMIRequest(ws->pSvc, ws->pLoc, r.requestsProcess, resultDataProcess,
					L"SELECT Name FROM Win32_PerfFormattedData_PerfProc_Process where Name like 'java%'")
					== REQUESTCHECK;
	if (requestResult != status_ok) {
		WriteFileLogf(L"Reconnecting\n");
		if (ws->pSvc != NULL)
			ws->pSvc->Release();
		if (ws->pLoc != NULL)
			ws->pLoc->Release();

		ws->pSvc = NULL;
		ws->pLoc = NULL;

		CoUninitialize();

		WMIConnect(&ws->pSvc, &ws->pLoc);
		return;
	}

	d.hostname = wstring(resultDataOS.begin()->second[L"CSName"]);
	d.os = wstring(resultDataOS.begin()->second[L"Caption"]);
	d.platform = wstring(resultDataComputer.begin()->second[L"SystemType"]);
	d.pcpu = stoull(resultDataComputer.begin()->second[L"NumberOfProcessors"]);
	if (GetMajorVersion() >= 6) {
		d.vcpu =
				stoull(
						resultDataComputer.begin()->second[L"NumberOfLogicalProcessors"]);
	} else {
		d.vcpu = d.pcpu;
	}

	d.memtotal = stoull(
			resultDataOS.begin()->second[L"TotalVisibleMemorySize"]);

	d.jvms = resultDataProcess.size();
	d.disks = resultDataDisk.size();
	d.nics = resultDataNetwork.size();

	time_t now_local = 0;
	now_local = (time_t) (MyGetTickCount64() / 1000);

	tm lt;
	gmtime_s(&lt, &now_local);
	wchar_t timeBuf[50] = L"";
	_snwprintf(timeBuf, 50, L"%dd %dh %dm %ds", lt.tm_yday, lt.tm_hour,
			lt.tm_min, lt.tm_sec);

	//rawscring
	wchar_t szBuf[2048] = L"";
	_snwprintf(szBuf, 2048, L"%s:%s:%s:%llu:%llu:"
			L"%llu:%llu:%llu:%llu:%llu:%s", d.hostname.data(),
			d.platform.data(), d.os.data(), d.pcpu, d.vcpu, d.memtotal,
			d.swaptotal, d.disks, d.nics, d.jvms, timeBuf);

	CloseFileStream(ws->rawStream);
	OpenFileStream(ws->rawStream,
			ws->parameters.rawCurrentPath + ws->parameters.rawCurrentFile);

	if (int writeStatus = WriteFileRaw(ws->rawStream, szBuf) != status_ok) {
		WriteFileLogf(L"Failed to write to raw code, reopening.");
		OpenFileStream(ws->rawStream,
				ws->parameters.rawCurrentPath + ws->parameters.rawCurrentFile);
	}

	wcout << szBuf << endl;

	InterlockedIncrement(params->count);
}

int main(int argc, char* argv[]) {
	//here fo run as service
#ifndef REC_TEST_CONSOLE
	SERVICE_TABLE_ENTRY ServiceTable[] = { { SERVICE_NAME,
			(LPSERVICE_MAIN_FUNCTION) ServiceMain }, { NULL, NULL } };
	if (StartServiceCtrlDispatcher(ServiceTable) == FALSE) {
		return GetLastError();
	}
#endif

#ifdef REC_TEST_CONSOLE
	//here fo run in console
	RecorderProperties *ws = new RecorderProperties();
	Init(ws,SERVICE_NAME);
	ServiceTimerStarter(ws);
#endif
	return 0;
}

VOID WINAPI ServiceMain(DWORD argc, LPTSTR *argv) {
	DWORD Status = E_FAIL;
	RecorderProperties *ws = new RecorderProperties();

	Init(ws, SERVICE_NAME);

	gStatusHandle = RegisterServiceCtrlHandlerEx(SERVICE_NAME,
			ServerCtrlHandlerEx, (LPVOID *) ws);

	if (gStatusHandle == NULL) {
		return;
	}

	// Tell the service controller we are starting
	ZeroMemory(&gServiceStatus, sizeof(gServiceStatus));
	gServiceStatus.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
	gServiceStatus.dwControlsAccepted = 0;
	gServiceStatus.dwCurrentState = SERVICE_START_PENDING;
	gServiceStatus.dwWin32ExitCode = 0;
	gServiceStatus.dwServiceSpecificExitCode = 0;
	gServiceStatus.dwCheckPoint = 0;

	if (SetServiceStatus(gStatusHandle, &gServiceStatus) == FALSE) {
		WriteFileLogf(
				_T(
						"Hdwrec: ServiceMain: SetServiceStatus returned error"));
	}

	gServiceStopEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
	if (gServiceStopEvent == NULL) {

		gServiceStatus.dwControlsAccepted = 0;
		gServiceStatus.dwCurrentState = SERVICE_STOPPED;
		gServiceStatus.dwWin32ExitCode = GetLastError();
		gServiceStatus.dwCheckPoint = 1;

		if (SetServiceStatus(gStatusHandle, &gServiceStatus) == FALSE) {
			WriteFileLogf(
					_T(
							"Hdwrec: ServiceMain: SetServiceStatus returned error"));
		}
		return;
	}

	// Tell the service controller we are started
	gServiceStatus.dwControlsAccepted = SERVICE_ACCEPT_STOP;
	gServiceStatus.dwCurrentState = SERVICE_RUNNING;
	gServiceStatus.dwWin32ExitCode = 0;
	gServiceStatus.dwCheckPoint = 0;

	if (SetServiceStatus(gStatusHandle, &gServiceStatus) == FALSE) {
		WriteFileLogf(
				_T(
						"Hdwrec: ServiceMain: SetServiceStatus returned error"));
	}

	HANDLE hThread = CreateThread(NULL, 0, ServiceWorkerThread, (LPVOID *) ws,
			0, NULL);

	WaitForSingleObject(hThread, INFINITE);

	CloseHandle(gServiceStopEvent);

	gServiceStatus.dwControlsAccepted = 0;
	gServiceStatus.dwCurrentState = SERVICE_STOPPED;
	gServiceStatus.dwWin32ExitCode = 0;
	gServiceStatus.dwCheckPoint = 3;

	if (SetServiceStatus(gStatusHandle, &gServiceStatus) == FALSE) {
		WriteFileLogf(
				_T(
						"Hdwrec: ServiceMain: SetServiceStatus returned error"));
	}

	return;
}

DWORD WINAPI ServerCtrlHandlerEx(DWORD dwControl, DWORD dwEventType,
		LPVOID lpEventData, LPVOID lpContext) {
	RecorderProperties *ws = static_cast<RecorderProperties*>(lpContext);
	switch (dwControl) {
	case SERVICE_CONTROL_STOP:

		if (gServiceStatus.dwCurrentState != SERVICE_RUNNING)
			break;

		//stop recorder
		ws->treminateFlag = true;

		gServiceStatus.dwControlsAccepted = 0;
		gServiceStatus.dwCurrentState = SERVICE_STOP_PENDING;
		gServiceStatus.dwWin32ExitCode = 0;
		gServiceStatus.dwCheckPoint = 4;

		if (SetServiceStatus(gStatusHandle, &gServiceStatus) == FALSE) {
			WriteFileLogf(
					_T(
							"Hdwrec: ServiceCtrlHandler: SetServiceStatus returned error"));
		}

		// This will signal the worker thread to start shutting down
		SetEvent(gServiceStopEvent);

		break;

	default:
		break;
	}
	return 0;
}

DWORD WINAPI ServiceWorkerThread(LPVOID lpParam) {
	while (WaitForSingleObject(gServiceStopEvent, 0) != WAIT_OBJECT_0) {
		RecorderProperties *ws = static_cast<RecorderProperties*>(lpParam);
		ServiceTimerStarter(ws);
	}
	return ERROR_SUCCESS;
}
