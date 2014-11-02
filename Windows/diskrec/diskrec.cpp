/*
 *  Diskrec
 *  SystemDataRecorder per-disk statistics
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

vector<double> GetCounterVector(PDH_HCOUNTER &hCounter);
VOID CALLBACK TimerRoutine(PVOID lpParam, BOOLEAN TimerOrWaitFired);

#define SERVICE_NAME  _T("disk")
#define _BIND_TO_CURRENT_CRT_VERSION
//uncomment for console run
//#define	REC_TEST_CONSOLE 

SERVICE_STATUS gServiceStatus = { 0 };
SERVICE_STATUS_HANDLE gStatusHandle = NULL;
HANDLE gServiceStopEvent = INVALID_HANDLE_VALUE;
HANDLE gDoneEvent;

struct DiskRecData {
	wstring name;
	double queue, totaltimepct, avgqueue, readtimepct, avgreadqueue,
			writetimepct, avgwritequeue, avgtotaltime, avgreadtime,
			avgwritetime, transfers, reads, writes, totalbytes, readbytes,
			writebytes, avgtotalbytes, avgreadbytes, avgwritebytes, idle,
			spitio;

};

struct PDHHandlers {
	HCOUNTER hQueue, hTotalTimePct, hAvgQueue, hReadTimePct, hAvgReadQueue,
			hWriteTimePct, hAvgWriteQueue, hAvgTotalTime, hAvgReadTime,
			hAvgWriteTime, hTransfers, hReads, hWrites, hTotalBytes, hReadBytes,
			hWriteBytes, hAvgTotalBytes, hAvgReadBytes, hAvgWriteBytes, hIdle,
			hSpitIO;
};

struct PDHCountersVectors {
	vector<wstring> names;
	vector<double> vQueue, vTotalTimePct, vAvgQueue, vReadTimePct,
			vAvgReadQueue, vWriteTimePct, vAvgWriteQueue, vAvgTotalTime,
			vAvgReadTime, vAvgWriteTime, vTransfers, vReads, vWrites,
			vTotalBytes, vReadBytes, vWriteBytes, vAvgTotalBytes, vAvgReadBytes,
			vAvgWriteBytes, vIdle, vSpitIO;
};

struct TimerParameters {
	RecorderProperties* ws;
	HQUERY hQuery;
	PDHHandlers counters;
	unsigned int* count;
};

inline double GetVDouble(vector<double> vec, int index) {
	if (index >= 0 && index < vec.size())
		return vec[index];
	return 0.0;
}

RecorderProperties *ws;
int ServiceTimerStarter(RecorderProperties* ws) {
	bool archiveDone = false;
	HQUERY hQuery = NULL;

	//clock
	clock_t this_time = clock();
	clock_t last_time = this_time;
	double timeCounterSec = 0;

	PDHHandlers c = { };

	PdhOpenQuery(NULL, 0, &hQuery);
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 198, true).data(), 0,
			&c.hQueue);		//	\\physicaldisk(*)\\current disk queue length :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 200, true).data(), 0,
			&c.hTotalTimePct);		//	\\physicaldisk(*)\\% disk time :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 1400, true).data(), 0,
			&c.hAvgQueue);		//	\\physicaldisk(*)\\avg. disk queue length :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 202, true).data(), 0,
			&c.hReadTimePct);	//      \\physicaldisk(*)\\% disk read time :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 1402, true).data(), 0,
			&c.hAvgReadQueue);//      \\physicaldisk(*)\\avg. disk read queue length :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 204, true).data(), 0,
			&c.hWriteTimePct);	//      \\physicaldisk(*)\\% disk write time :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 1404, true).data(), 0,
			&c.hAvgWriteQueue);	//      \\physicaldisk(*)\\avg. disk write queue length :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 206, true).data(), 0,
			&c.hAvgTotalTime);//      \\physicaldisk(*)\\avg. disk sec/transfer :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 208, true).data(), 0,
			&c.hAvgReadTime);		//	\\physicaldisk(*)\\avg. disk sec/read :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 210, true).data(), 0,
			&c.hAvgWriteTime);	//      \\physicaldisk(*)\\avg. disk sec/write :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 212, true).data(), 0,
			&c.hTransfers);			//	\\physicaldisk(*)\\disk transfers/sec :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 214, true).data(), 0,
			&c.hReads);				//	\\physicaldisk(*)\\disk reads/sec :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 216, true).data(), 0,
			&c.hWrites);			//	\\physicaldisk(*)\\disk writes/sec :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 218, true).data(), 0,
			&c.hTotalBytes);		//      \\physicaldisk(*)\\disk bytes/sec :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 220, true).data(), 0,
			&c.hReadBytes);		//      \\physicaldisk(*)\\disk read bytes/sec :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 222, true).data(), 0,
			&c.hWriteBytes);//      \\physicaldisk(*)\\disk write bytes/sec :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 224, true).data(), 0,
			&c.hAvgTotalBytes);	//      \\physicaldisk(*)\\avg. disk bytes/transfer :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 226, true).data(), 0,
			&c.hAvgReadBytes);	//	\\physicaldisk(*)\\avg. disk bytes/read :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 228, true).data(), 0,
			&c.hAvgWriteBytes);	//	\\physicaldisk(*)\\avg. disk bytes/write :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 1482, true).data(), 0,
			&c.hIdle);				//	\\physicaldisk(*)\\% idle time :
	PdhAddCounter(hQuery, GetEnglishPdhQuery(234, 1484, true).data(), 0,
			&c.hSpitIO);			//	\\physicaldisk(*)\\split io/sec :

	HANDLE hTimer = NULL;
	HANDLE hTimerQueue = CreateTimerQueue();
	gDoneEvent = CreateEvent(NULL, TRUE, FALSE, NULL);

	TimerParameters *params = new TimerParameters();
	params->hQuery = hQuery;
	params->ws = ws;
	params->counters = c;
	params->count = new unsigned int(0);

	PdhCollectQueryData(hQuery);
	Sleep(200);

	if (!CreateTimerQueueTimer(&hTimer, hTimerQueue,
			(WAITORTIMERCALLBACK) TimerRoutine, (LPVOID *) params, 10,
			ws->parameters.interval * 1000, 0)) {
		WriteFileLogf(L"Failed to create CreateTimerQueueTimer.");
		return 3;
	}

	//last row is _total
	while (!ws->treminateFlag) {
		this_time = clock();
		timeCounterSec += (double) (this_time - last_time);
		last_time = this_time;

		if (*params->count >= ws->parameters.countTotal
				&& ws->parameters.countTotal != -1) {
			SetEvent(gDoneEvent);
			ws->treminateFlag = true;
			PdhCloseQuery(hQuery);
			CloseFileStream(ws->rawStream);
			CloseFileStream(ws->logStream);
		}

		if (timeCounterSec < 0)
			timeCounterSec = 0;

		if ((int) timeCounterSec > CLOCKS_PER_SEC) {
			timeCounterSec = 0;
			int sec = SecSinceMidnight();
			if (((sec < 5 && sec >= 0) && !archiveDone)) {
				if (ArchiveFileRaw(ws) == status_ok) {
					archiveDone = true;
					WriteFileLogf(L"Archive creating success.");
				} else {
					WriteFileLogf(L"Failed to save archive.");
				}
			}
			if ((sec > 5) && archiveDone) {
				archiveDone = false;
			}
		}
		Sleep(500);
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
	PDH_STATUS status;
	//close recorder on exit
	if (ws->treminateFlag) {
		SetEvent(gDoneEvent);
		PdhCloseQuery(hQuery);
		CloseFileStream(ws->rawStream);
		CloseFileStream(ws->logStream);
	}
	//requests

	if (status = PdhCollectQueryData(hQuery)) {
		WriteFileLogf(L"Failed to get counters, code 0x%x.\n", status);
		return;
	}

	if (GetCounterVector(c.hQueue).size() == 0) {
		WriteFileLogf(L"Failed to get data, retry in 200ms!");
		Sleep(200);
		PdhCollectQueryData(hQuery);

	}

	int diskCount = GetCounterVector(c.hQueue).size() - 1;

	if (diskCount < 0) {
		WriteFileLogf(L"Failed to collect data.");
		return;
	}
	vector<DiskRecData> disks = vector<DiskRecData>(diskCount);

	try {
		v.names = GetCounterNames(c.hQueue);
		v.vQueue = GetCounterVector(c.hQueue);
		v.vTotalTimePct = GetCounterVector(c.hTotalTimePct);
		v.vAvgQueue = GetCounterVector(c.hAvgQueue);
		v.vReadTimePct = GetCounterVector(c.hReadTimePct);
		v.vAvgReadQueue = GetCounterVector(c.hAvgReadQueue);
		v.vWriteTimePct = GetCounterVector(c.hWriteTimePct);
		v.vAvgWriteQueue = GetCounterVector(c.hAvgWriteQueue);
		v.vAvgTotalTime = GetCounterVector(c.hAvgTotalTime);
		v.vAvgReadTime = GetCounterVector(c.hAvgReadTime);
		v.vAvgWriteTime = GetCounterVector(c.hAvgWriteTime);
		v.vTransfers = GetCounterVector(c.hTransfers);
		v.vReads = GetCounterVector(c.hReads);
		v.vWrites = GetCounterVector(c.hWrites);
		v.vTotalBytes = GetCounterVector(c.hTotalBytes);
		v.vReadBytes = GetCounterVector(c.hReadBytes);
		v.vWriteBytes = GetCounterVector(c.hWriteBytes);
		v.vAvgTotalBytes = GetCounterVector(c.hAvgTotalBytes);
		v.vAvgReadBytes = GetCounterVector(c.hAvgReadBytes);
		v.vAvgWriteBytes = GetCounterVector(c.hAvgWriteBytes);
		v.vIdle = GetCounterVector(c.hIdle);
		v.vSpitIO = GetCounterVector(c.hSpitIO);
	} catch (int status) {
		WriteFileLogf(L"Failed to catch couters, code 0x%x.\n", status);
		return;
	}

	for (int dindex = 0; dindex < v.names.size() - 1 && v.names.size() > 0;
			dindex++) {
		DiskRecData d;
		ZeroMemory(&d, sizeof(d));
		d.name = v.names[dindex];
		d.queue = GetVDouble(v.vQueue, dindex);
		d.totaltimepct = GetVDouble(v.vTotalTimePct, dindex);
		d.avgqueue = GetVDouble(v.vAvgQueue, dindex);
		d.readtimepct = GetVDouble(v.vReadTimePct, dindex);
		d.avgreadqueue = GetVDouble(v.vAvgReadQueue, dindex);
		d.writetimepct = GetVDouble(v.vWriteTimePct, dindex);
		d.avgwritequeue = GetVDouble(v.vAvgWriteQueue, dindex);
		d.avgtotaltime = GetVDouble(v.vAvgTotalTime, dindex);
		d.avgreadtime = GetVDouble(v.vAvgReadTime, dindex);
		d.avgwritetime = GetVDouble(v.vAvgWriteTime, dindex);
		d.transfers = GetVDouble(v.vTransfers, dindex);
		d.reads = GetVDouble(v.vReads, dindex);
		d.writes = GetVDouble(v.vWrites, dindex);
		d.totalbytes = GetVDouble(v.vTotalBytes, dindex);
		d.readbytes = GetVDouble(v.vReadBytes, dindex);
		d.writebytes = GetVDouble(v.vWriteBytes, dindex);
		d.avgtotalbytes = GetVDouble(v.vAvgTotalBytes, dindex);
		d.avgreadbytes = GetVDouble(v.vAvgReadBytes, dindex);
		d.avgwritebytes = GetVDouble(v.vAvgWriteBytes, dindex);
		d.idle = GetVDouble(v.vIdle, dindex);
		d.spitio = GetVDouble(v.vSpitIO, dindex);

		wchar_t szBuf[5024] = L"";
		_snwprintf(szBuf, 5024, L"%d:%.2f:%.2f:%.2f:%.2f:"
				L"%.2f:%.2f:%.2f:"
				L"%.2f:%.2f:%.2f:"
				L"%.2f:%.2f:%.2f:"
				L"%.2f:%.2f:%.2f:"
				L"%.2f:%.2f:%.2f:"
				L"%.2f:%.2f", dindex, d.queue, d.totaltimepct, d.readtimepct,
				d.writetimepct, d.avgqueue, d.avgreadqueue, d.avgwritequeue,
				d.avgtotaltime, d.avgreadtime, d.avgwritetime, d.transfers,
				d.reads, d.writes, d.totalbytes, d.readbytes, d.writebytes,
				d.avgtotalbytes, d.avgreadbytes, d.avgwritebytes, d.idle,
				d.spitio);

		if (int writeStatus = WriteFileRaw(ws->rawStream, szBuf) != status_ok) {
			WriteFileLogf(L"Failed to write to raw code, reopening.");
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

	ZeroMemory(&gServiceStatus, sizeof(gServiceStatus));
	gServiceStatus.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
	gServiceStatus.dwControlsAccepted = 0;
	gServiceStatus.dwCurrentState = SERVICE_START_PENDING;
	gServiceStatus.dwWin32ExitCode = 0;
	gServiceStatus.dwServiceSpecificExitCode = 0;
	gServiceStatus.dwCheckPoint = 0;

	if (SetServiceStatus(gStatusHandle, &gServiceStatus) == FALSE) {
		WriteFileLogf(
		_T("Diskrec: ServiceMain: SetServiceStatus returned error"));
	}

	gServiceStopEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
	if (gServiceStopEvent == NULL) {

		gServiceStatus.dwControlsAccepted = 0;
		gServiceStatus.dwCurrentState = SERVICE_STOPPED;
		gServiceStatus.dwWin32ExitCode = GetLastError();
		gServiceStatus.dwCheckPoint = 1;

		if (SetServiceStatus(gStatusHandle, &gServiceStatus) == FALSE) {
			WriteFileLogf(
			_T("Diskrec: ServiceMain: SetServiceStatus returned error"));
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
		_T("Diskrec: ServiceMain: SetServiceStatus returned error"));
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
		_T("Diskrec: ServiceMain: SetServiceStatus returned error"));
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
			_T("Diskrec: ServiceCtrlHandler: SetServiceStatus returned error"));
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

