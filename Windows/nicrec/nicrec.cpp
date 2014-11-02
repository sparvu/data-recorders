/*
 *  Nicrec
 *  SystemDataRecorder per-NIC statistics
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

#include <deque>
using namespace std;
#define SERVICE_NAME  _T("nic")

SERVICE_STATUS gServiceStatus = { 0 };
SERVICE_STATUS_HANDLE gStatusHandle = NULL;
HANDLE gServiceStopEvent = INVALID_HANDLE_VALUE;
HANDLE gDoneEvent;
//uncomment for console run
//#define	REC_TEST_CONSOLE 

VOID WINAPI ServiceMain(DWORD argc, LPTSTR *argv);
DWORD WINAPI ServerCtrlHandlerEx(DWORD, DWORD, LPVOID, LPVOID);
DWORD WINAPI ServiceWorkerThread(LPVOID lpParam);
VOID CALLBACK TimerRoutine(PVOID lpParam, BOOLEAN TimerOrWaitFired);

struct NicRecData {
	wstring inter;
	double timestamp, rxKB, rxpcks, rxerrs, rxdrop, rxfifo, rxframe, rxcompr,
			rxmulti, txKB, txpcks, txerrs, txdrop, txfifo, txcolls, txcarr,
			txcompr, txmulti, ttpcks, ttKB;

};
struct NicVectorData {
	vector<wstring> inter;
	vector<double> vRxKB, vRxpcks, vRxerrs, vRxdrop, vRxfifo, vRxframe,
			vRxcompr, vRxmulti, vTxKB, vTxpcks, vTxerrs, vTxdrop, vTxfifo,
			vTxcolls, vTxcarr, vTxcompr, vTxmulti, vTtpcks, vTtKB;

};
struct PDHHandlers {
	HCOUNTER hReceivedBytes, hReceivedPakets, hReceivedErrors, hReceivedDroped,
			hReceivedOverruns, hReceivedCarrierErrors,
			hReceivedCompressedErrors, hReceivedMultycast,

			hSentBytes, hSentPakets, hSentErrors, hSentDroped, hSentOverruns,
			hSentCarrierErrors, hSentCompressedErrors, hSentMultycast,
			hOffloadedConnections;
};
struct TimerParameters {
	RecorderProperties* ws;
	HQUERY hQuery;
	PDHHandlers counters;
	unsigned int* count;
	unsigned long* lastFrameErrors;
};

int ServiceTimerStarter(RecorderProperties* ws) {

	HQUERY hQuery = NULL;

	bool archiveDone = false;
	deque<float> loadavg1, loadavg5, loadavg15;

	//clock
	clock_t this_time = clock();
	clock_t last_time = this_time;
	double timeCounterSec = 0;

	PDHHandlers c = { };
	// Open a query object.
	PdhOpenQuery(NULL, 0, &hQuery);

	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 264, true).data(), 0,
			&c.hReceivedBytes); //\\Network Interface(*)\\bytes received/sec",
	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 266, true).data(), 0,
			&c.hReceivedPakets);//\\Network Interface(*)\\packets received/sec",
	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 530, true).data(), 0,
			&c.hReceivedErrors);//\\Network Interface(*)\\packets received errors",
	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 528, true).data(), 0,
			&c.hReceivedDroped);//\\Network Interface(*)\\packets received discarded",
	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 526, true).data(), 0,
			&c.hReceivedMultycast);	//\\Network Interface(*)\\packets received non-unicast/sec"
	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 506, true).data(), 0,
			&c.hSentBytes);	//\\Network Interface(*)\\bytes sent/sec",
	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 452, true).data(), 0,
			&c.hSentPakets);//\\Network Interface(*)\\packets sent/sec",
	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 542, true).data(), 0,
			&c.hSentErrors);//\\Network Interface(*)\\packets outbound errors",
	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 540, true).data(), 0,
			&c.hSentDroped);//\\Network Interface(*)\\packets outbound discarded",
	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 538, true).data(), 0,
			&c.hSentMultycast);	//\\Network Interface(*)\\packets sent non-unicast/sec",
	// PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 1596, true).data(), 0, &c.hOffloadedConnections);	//\\Network Interface(*)\\Offloaded Connections/sec",

	HANDLE hTimer = NULL;
	HANDLE hTimerQueue = CreateTimerQueue();
	gDoneEvent = CreateEvent(NULL, TRUE, FALSE, NULL);

	TimerParameters *params = new TimerParameters();
	params->hQuery = hQuery;
	params->ws = ws;
	params->counters = c;
	params->count = new unsigned int(0);
	params->lastFrameErrors = new unsigned long(0);
	PdhCollectQueryData(hQuery);
	Sleep(200);
	if (!CreateTimerQueueTimer(&hTimer, hTimerQueue,
			(WAITORTIMERCALLBACK) TimerRoutine, (LPVOID *) params, 10,
			ws->parameters.interval * 1000, 0)) {
		WriteFileLogf(L"Failed to create CreateTimerQueueTimer.");
	}

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

		if (timeCounterSec < 0)
			timeCounterSec = 0;

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

	PDHHandlers c = params->counters;
	RecorderProperties *ws = params->ws;
	HQUERY hQuery = params->hQuery;

	int status;
	if (status = PdhCollectQueryData(hQuery)) {
		WriteFileLogf(L"Failed to get counters, code ");
		return;
	}
	if (status == PDH_NO_DATA)
		wcout << L"No Data" << endl;

	int nicCount = GetCounterVector(c.hReceivedPakets).size();
	if (nicCount == 0) {

		WriteFileLogf(L"No network interfaces found.");
		return;
	}

	vector<NicRecData> nics = vector<NicRecData>();
	NicVectorData v = { };

	MIB_IPSTATS *pStats = new MIB_IPSTATS();
	unsigned long currentFrameErrors = 0;

	Sleep(10);
	GetIpStatistics(pStats);

	v.inter = GetCounterNames(c.hReceivedBytes);
	if (v.inter.empty()) {
		delete pStats;
		return;
	}
	currentFrameErrors = pStats->dwInAddrErrors + pStats->dwInDiscards;

	v.vRxKB = GetCounterVector(c.hReceivedBytes);
	v.vRxpcks = GetCounterVector(c.hReceivedPakets);
	v.vRxerrs = GetCounterVector(c.hReceivedErrors);
	v.vRxdrop = GetCounterVector(c.hReceivedDroped);
	v.vRxmulti = GetCounterVector(c.hReceivedMultycast);

	v.vTxKB = GetCounterVector(c.hSentBytes);
	v.vTxpcks = GetCounterVector(c.hSentPakets);
	v.vTxerrs = GetCounterVector(c.hSentErrors);
	v.vTxdrop = GetCounterVector(c.hSentDroped);
	v.vTxmulti = GetCounterVector(c.hSentMultycast);
	wcout << currentFrameErrors << L"  " << *params->lastFrameErrors << endl;
	//v.vRxfifo = GetCounterVector(c.hOffloadedConnections);
	for (int cindex = 0; cindex < v.inter.size() && v.inter.size() > 0;
			cindex++) {

		NicRecData d = { };
		d.inter = v.inter[cindex];
		d.rxKB = v.vRxKB[cindex];
		d.rxpcks = v.vRxpcks[cindex];
		d.rxerrs = v.vRxerrs[cindex];
		d.rxdrop = v.vRxdrop[cindex];
		d.rxmulti = v.vRxmulti[cindex];

		d.txKB = v.vTxKB[cindex];
		d.txpcks = v.vTxpcks[cindex];
		d.txerrs = v.vTxerrs[cindex];
		d.txdrop = v.vTxdrop[cindex];
		d.txmulti = v.vTxmulti[cindex];
		//d.rxfifo = v.vRxfifo[cindex];

		d.rxframe = currentFrameErrors - *params->lastFrameErrors;
		d.ttpcks = d.rxpcks + d.txpcks;
		d.ttKB = d.rxKB + d.txKB;

		wchar_t szBuf[2048] = L"";
		_snwprintf(szBuf, 2048, L"%s:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:"
				L"%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:"
				L"%.2f:%.2f", d.inter.c_str(), d.rxKB, d.rxpcks, d.rxerrs,
				d.rxdrop, d.rxfifo, d.rxframe, d.rxmulti, d.txKB, d.txpcks,
				d.txerrs, d.txdrop, d.txfifo, d.txcolls, d.txcarr, d.ttpcks,
				d.ttKB);

		if (int writeStatus = WriteFileRaw(ws->rawStream, szBuf) != status_ok) {
			WriteFileLogf(L"Failed to write to raw code, reopening.");
			OpenFileStream(ws->rawStream,
					ws->parameters.rawCurrentPath
							+ ws->parameters.rawCurrentFile);
		}

#ifdef	REC_TEST_CONSOLE 
		wcout<<szBuf<<endl;
#endif

	}
	delete pStats;

	InterlockedExchangeAdd(params->lastFrameErrors,
			currentFrameErrors - *params->lastFrameErrors);
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
#endif
	return 0;
}

VOID WINAPI ServiceMain(DWORD argc, LPTSTR *argv) {
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
						"Nicrec: ServiceMain: SetServiceStatus returned error"));
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
							"Nicrec: ServiceMain: SetServiceStatus returned error"));
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
						"Nicrec: ServiceMain: SetServiceStatus returned error"));
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
						"Nicrec: ServiceMain: SetServiceStatus returned error"));
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
			_T("Nicrec: ServiceCtrlHandler: SetServiceStatus returned error"));
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

