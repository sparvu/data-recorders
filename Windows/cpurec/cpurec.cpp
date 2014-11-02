/*
 *  Cpurec
 *  SystemDataRecorder per-cpu statistics
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
#include <vector>

VOID WINAPI ServiceMain(DWORD argc, LPTSTR *argv);
DWORD WINAPI ServerCtrlHandlerEx(DWORD, DWORD, LPVOID, LPVOID);
DWORD WINAPI ServiceWorkerThread(LPVOID lpParam);
using namespace std;

VOID CALLBACK TimerRoutine(PVOID lpParam, BOOLEAN TimerOrWaitFired);

vector<double> GetCounterVector(PDH_HCOUNTER &hCounter);
#define SERVICE_NAME  _T("cpu")
#define _BIND_TO_CURRENT_CRT_VERSION
//uncomment for console run
//#define	REC_TEST_CONSOLE 

SERVICE_STATUS gServiceStatus = { 0 };
SERVICE_STATUS_HANDLE gStatusHandle = NULL;
HANDLE gServiceStopEvent = INVALID_HANDLE_VALUE;
HANDLE gDoneEvent;

struct CpuRecData {
	int cpuid;
	double timestamp, userpct, syspct, idlepct, totalpct, irqpct;

};

struct PDHHandlers {
	HCOUNTER

	hProcTime, hProcUserTime, hProcTimeWildCard, hProcPrevTime, hProcIdleTime,
			hProcQueue, hProcIteruptTime;

};

struct PDHCountersVectors {
	vector<wstring> name;
	vector<double> vUserpct, vSyspct, vIdlepct, vTotalpct, vIrqpct;
};

struct TimerParameters {
	RecorderProperties* ws;
	HQUERY hQuery;
	PDHHandlers counters;
	unsigned int* count;
	bool is2003x64;
};

bool Is2003Version() {
	OSVERSIONINFO vi;
	vi.dwOSVersionInfoSize = sizeof vi;
	GetVersionEx(&vi);
	return vi.dwMajorVersion == 5 && vi.dwMinorVersion == 2; // 5.2
}

RecorderProperties *ws;
int ServiceTimerStarter(RecorderProperties* ws) {
	//connectiong to WMI

	bool archiveDone = false;

	HQUERY hQuery = NULL;

	PDH_STATUS pdhStatus;

	//clock
	clock_t this_time = clock();
	clock_t last_time = this_time;
	double timeCounter = ws->parameters.interval * CLOCKS_PER_SEC + 10,
			timeCounterSec = 0;

	int requestResult;
	PDHHandlers c = { };

	PdhOpenQuery(NULL, 0, &hQuery);

	PdhAddCounter(hQuery, GetEnglishPdhQuery(238, 6, true).data(), 0,
			&c.hProcTime);				//  "\\processor(*)\\% processor time"
	PdhAddCounter(hQuery, GetEnglishPdhQuery(238, 142, true).data(), 0,
			&c.hProcUserTime);//	"\\processor(*)\\% user time",
	PdhAddCounter(hQuery, GetEnglishPdhQuery(238, 144, true).data(), 0,
			&c.hProcPrevTime);			//	"\\processor(*)\\% privileged time
	PdhAddCounter(hQuery, GetEnglishPdhQuery(238, 1482, true).data(), 0,
			&c.hProcIdleTime);				//	"\\processor(*)\\% idle time",
	PdhAddCounter(hQuery, GetEnglishPdhQuery(238, 698, true).data(), 0,
			&c.hProcIteruptTime);		//	"\\processor(*)\\% interrupt time"
	HANDLE hTimer = NULL;
	HANDLE hTimerQueue = CreateTimerQueue();
	gDoneEvent = CreateEvent(NULL, TRUE, FALSE, NULL);

	TimerParameters *params = new TimerParameters();
	params->hQuery = hQuery;
	params->ws = ws;
	params->counters = c;
	params->count = new unsigned int(0);
	params->is2003x64 = false;

	PdhCollectQueryData(hQuery);
	Sleep(1000);

	PdhCollectQueryData(hQuery);

	if (!CreateTimerQueueTimer(&hTimer, hTimerQueue,
			(WAITORTIMERCALLBACK) TimerRoutine, (LPVOID *) params, 10,
			ws->parameters.interval * 1000, 0)) {
		WriteFileLogf(L"Failed to create CreateTimerQueueTimer.");

	}

#if _WIN32
	if (Is2003Version()) {
		params->is2003x64 = true;
	}
#endif

	while (!ws->treminateFlag) {
		this_time = clock();
		timeCounterSec += (double) (this_time - last_time);
		last_time = this_time;

		//close recorder on exit
		if (*params->count >= ws->parameters.countTotal
				&& ws->parameters.countTotal != -1) {
			SetEvent(gDoneEvent);
			ws->treminateFlag = true;
			PdhCloseQuery(hQuery);
			CloseFileStream(ws->rawStream);
			CloseFileStream(ws->logStream);
			return status_ok;
		}
		//requests

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
		Sleep(100);
	}
	return status_ok;
}

VOID CALLBACK TimerRoutine(PVOID lpParam, BOOLEAN TimerOrWaitFired) {
	// lpParam points to the argument; in this case it is an int
	TimerParameters *params = static_cast<TimerParameters*>(lpParam);

	PDHCountersVectors v = { };
	PDHHandlers c = params->counters;
	RecorderProperties *ws = params->ws;
	HQUERY hQuery = params->hQuery;
	PDH_FMT_COUNTERVALUE pdhValue;

	if (PdhCollectQueryData(hQuery)) {
		WriteFileLogf(L"Failed to get counters.");
		return;
	}
	Sleep(100);
	if (GetCounterVector(c.hProcTime).size() == 0) {
		WriteFileLogf(L"Failed to get data, retry in 200ms!");
		Sleep(200);
		PdhCollectQueryData(hQuery);
	}

	//last row is _total
	int cpuCount = GetCounterVector(c.hProcTime).size() - 1;

	if (cpuCount == -1) {
		WriteFileLogf(L"Failed to collect data.");
		return;
	}

	vector<CpuRecData> cpus = vector<CpuRecData>(cpuCount);
	v.name = GetCounterNames(c.hProcTime);
	v.vTotalpct = GetCounterVector(c.hProcTime);
	v.vUserpct = GetCounterVector(c.hProcUserTime);
	v.vSyspct = GetCounterVector(c.hProcPrevTime);
	v.vIdlepct = GetCounterVector(c.hProcIdleTime);

	v.vIrqpct = GetCounterVector(c.hProcIteruptTime);

	for (int cindex = 0; cindex < v.vTotalpct.size() && v.vTotalpct.size() > 0;
			cindex++) {
		if (v.name[cindex][0] == '_') {
			continue;
		}

		CpuRecData d = { 0 };
		d.cpuid = cindex;
		d.userpct = v.vUserpct[cindex];
		d.syspct = v.vSyspct[cindex];
		d.totalpct = v.vTotalpct[cindex];
		d.irqpct = v.vIrqpct[cindex];
		if (params->is2003x64)			//broken counters on x32 on win2003x64
		{
			d.idlepct = 100.0 - d.totalpct;

		} else {
			d.idlepct = v.vIdlepct[cindex];
		}

		wchar_t szBuf[128] = L"";
		_snwprintf_s(szBuf, 128, 128, L"%d:%.2f:%.2f:%.2f:%.2f:%.2f", d.cpuid,
				d.userpct, d.syspct, d.idlepct, d.irqpct, d.totalpct);

		if (int writeStatus = WriteFileRaw(ws->rawStream, szBuf) != status_ok) {
			WriteFileLogf(L"Failed to write to raw code:");
			OpenFileStream(ws->rawStream,
					ws->parameters.rawCurrentPath
							+ ws->parameters.rawCurrentFile);
		}
		wcout << szBuf << endl;
	}

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
	Init(ws, SERVICE_NAME);
	ServiceTimerStarter(ws);
	delete ws;

#endif
	return 0;
}

VOID WINAPI ServiceMain(DWORD argc, LPTSTR *argv) {

	RecorderProperties *ws = new RecorderProperties();

	ws->pLoc = NULL;
	ws->pSvc = NULL;
	ws->treminateFlag = false;

	//recoder logs initialisation

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
		_T("Cpurec: ServiceMain: SetServiceStatus returned error"));
	}

	gServiceStopEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
	if (gServiceStopEvent == NULL) {

		gServiceStatus.dwControlsAccepted = 0;
		gServiceStatus.dwCurrentState = SERVICE_STOPPED;
		gServiceStatus.dwWin32ExitCode = GetLastError();
		gServiceStatus.dwCheckPoint = 1;

		if (SetServiceStatus(gStatusHandle, &gServiceStatus) == FALSE) {
			WriteFileLogf(
			_T("Cpurec: ServiceMain: SetServiceStatus returned error"));
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
		_T("Cpurec: ServiceMain: SetServiceStatus returned error"));
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
		_T("Cpurec: ServiceMain: SetServiceStatus returned error"));
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
			_T("Cpurec: ServiceCtrlHandler: SetServiceStatus returned error"));
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

