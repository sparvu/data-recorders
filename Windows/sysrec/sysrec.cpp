/*
 *  Sysrec
 *  SystemDataRecorder overall system statistics
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
using namespace std;
SERVICE_STATUS gServiceStatus = { 0 };
SERVICE_STATUS_HANDLE gStatusHandle = NULL;
HANDLE gServiceStopEvent = INVALID_HANDLE_VALUE;
HANDLE gDoneEvent;
#define SERVICE_NAME  _T("sys")

//uncomment for console run
//#define	REC_TEST_CONSOLE 

VOID WINAPI ServiceMain(DWORD argc, LPTSTR *argv);
DWORD WINAPI ServerCtrlHandlerEx(DWORD, DWORD, LPVOID, LPVOID);
DWORD WINAPI ServiceWorkerThread(LPVOID lpParam);
VOID CALLBACK TimerRoutine(PVOID lpParam, BOOLEAN TimerOrWaitFired);

struct SysRecData {
	double cpupct, sumpct, headpct, userpct, syspct, idlepct, irqpct,

	memusedpct, realfreepct, swapusedpct,

	readReq, writeReq, totReq, readByt, writeByt, totByt,

	rxByt, txByt, ntByt, rxerr, txerr, rxdrp, txdrp;

	;

	//PDHHandlers WMI usulay contains uint64
	ULONGLONG runqsz, plistsz, memused, memfree, memtotal, buffers, cached,
			realfree, swapused, swapfree, swaptotal, swapcached;

};

struct PDHHandlers {
	HCOUNTER

	hCounterMZero, hCounterModified, hCounterStandbyReserve,
			hCounterStandbyNormal, hCounterStandbyPriority,

			hProcTime, hProcUserTime, hProcTimeWildCard, hProcPrevTime,
			hProcIdleTime, hProcQueue, hProcCount, hProcIteruptTime,

			//memory

			hMemoryZero, hMemoryModified, hMemoryAvaliable, hMemoryTotal,
			hMemoryUsed, hMemoryStandbyReserve, hMemoryStandbyNormal,
			hMemoryStandbyPriority, hMemoryCachedXP,

			//disk
			hDiskReadReq, hDiskWriteReq, hDiskReadByt, hDiskWriteByt,

			//network
			hNetworkRxByt, hNetworkTxByt, hNetworkNtByt, hNetworkRxerr,
			hNetworkTxerr, hNetworkRxdrp, hNetworkTxdrp,

			hReceivedBytes, hReceivedPakets, hReceivedErrors, hReceivedDroped,

			hSentBytes, hSentPakets, hSentErrors, hSentDroped,

			//system
			hReadReq, hWriteReq, hTotReq, hReadByt, hWriteByt,

			swapused, swapfree, swaptotal, swapcached;

};

struct WMIRequests {
	list<BSTR> rProcessor, rSystem, rMemory, rOs, rNetwork;
};

struct TimerParameters {
	RecorderProperties* ws;
	HQUERY hQuery;
	WMIRequests requests;
	PDHHandlers counters;
	unsigned int* count;
};
RecorderProperties *ws;
int ServiceTimerStarter(RecorderProperties* ws) {
	//connectiong to WMI
	WMIConnect(&ws->pSvc, &ws->pLoc);

	HQUERY hQuery = NULL;
	HLOG hLog = NULL;

	DWORD dwLogType = PDH_LOG_TYPE_CSV;
	DWORD counterType = PERF_COUNTER_100NS_QUEUELEN_TYPE;
	PDHHandlers c = { };
	bool archiveDone = false;

	//clock
	clock_t this_time = clock();
	clock_t last_time = this_time;
	double timeCounter = ws->parameters.interval * CLOCKS_PER_SEC + 10,
			timeCounterSec = 0;

	WMIRequests r;

	//lists of requested parameters
	r.rProcessor = list<BSTR>();
	r.rProcessor.push_front(L"PercentIdleTime");
	r.rProcessor.push_front(L"PercentInterruptTime");
	r.rProcessor.push_front(L"PercentPrivilegedTime");
	r.rProcessor.push_front(L"TimeStamp_Sys100NS");
	r.rProcessor.push_front(L"PercentProcessorTime");
	r.rProcessor.push_front(L"PercentUserTime");
	r.rProcessor.push_front(L"PercentInterruptTime");

	r.rSystem = list<BSTR>();
	r.rSystem.push_front(L"ProcessorQueueLength");
	r.rSystem.push_front(L"SystemCallsPerSec");
	r.rSystem.push_front(L"Processes");
	r.rSystem.push_front(L"FileControlOperationsPerSec");
	r.rSystem.push_front(L"FileDataOperationsPerSec");
	r.rSystem.push_front(L"FileReadBytesPerSec");
	r.rSystem.push_front(L"FileReadOperationsPerSec");
	r.rSystem.push_front(L"FileWriteBytesPerSec");
	r.rSystem.push_front(L"FileWriteOperationsPerSec");
	r.rSystem.push_front(L"FloatingEmulationsPerSec");

	r.rMemory = list<BSTR>();
	r.rMemory.push_front(L"AvailableKBytes");
	r.rMemory.push_front(L"AvailableKBytes");
	r.rMemory.push_front(L"CacheBytes");

	r.rOs = list<BSTR>();
	r.rOs.push_front(L"FreePhysicalMemory");
	r.rOs.push_front(L"FreeVirtualMemory");
	r.rOs.push_front(L"TotalVisibleMemorySize");
	r.rOs.push_front(L"SizeStoredInPagingFiles");
	r.rOs.push_front(L"FreeSpaceInPagingFiles");

	r.rNetwork = list<BSTR>();
	r.rNetwork.push_front(L"BytesReceivedPerSec");
	r.rNetwork.push_front(L"BytesSentPerSec");
	r.rNetwork.push_front(L"BytesTotalPerSec");
	r.rNetwork.push_front(L"PacketsReceivedErrors");
	r.rNetwork.push_front(L"PacketsOutboundErrors");
	r.rNetwork.push_front(L"PacketsOutboundDiscarded");
	r.rNetwork.push_front(L"PacketsReceivedDiscarded");

	// Open a query object.
	PdhOpenQuery(NULL, 0, &hQuery);

	PdhAddCounter(hQuery, GetEnglishPdhQuery(4, 1676).data(), 0,
			&c.hCounterMZero);			//\\Memory\Free & Zero Page List Bytes
	PdhAddCounter(hQuery, GetEnglishPdhQuery(4, 1678).data(), 0,
			&c.hCounterModified);			//\\Memory\Modified Page List Bytes
	PdhAddCounter(hQuery, GetEnglishPdhQuery(4, 1680).data(), 0,
			&c.hCounterStandbyReserve);	   //\Memory\Standby Cache Reserve Bytes
	PdhAddCounter(hQuery, GetEnglishPdhQuery(4, 1682).data(), 0,
			&c.hCounterStandbyNormal);//\Memory\Standby Cache Normal Priority Bytes
	PdhAddCounter(hQuery, GetEnglishPdhQuery(4, 1684).data(), 0,
			&c.hCounterStandbyPriority);      //\Memory\Standby Cache Core Bytes

	//disk
	PdhAddCounter(hQuery, GetEnglishPdhQuery(2, 16).data(), 0, &c.hDiskReadByt);//
	PdhAddCounter(hQuery, GetEnglishPdhQuery(2,18).data(), 0, &c.hDiskWriteByt);//
	PdhAddCounter(hQuery, GetEnglishPdhQuery(2,10).data(), 0, &c.hDiskReadReq);//
	PdhAddCounter(hQuery, GetEnglishPdhQuery(2,12).data(), 0, &c.hDiskWriteReq);//

	//network
	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 264, true).data(), 0,
			&c.hReceivedBytes); //\\Network Interface(*)\\bytes received/sec",
	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 530, true).data(), 0,
			&c.hReceivedErrors);//\\Network Interface(*)\\packets received errors",
	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 528, true).data(), 0,
			&c.hReceivedDroped);//\\Network Interface(*)\\packets received discarded",

	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 506, true).data(), 0,
			&c.hSentBytes);	//\\Network Interface(*)\\bytes sent/sec",
	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 542, true).data(), 0,
			&c.hSentErrors);//\\Network Interface(*)\\packets outbound errors",
	PdhAddCounter(hQuery, GetEnglishPdhQuery(510, 540, true).data(), 0,
			&c.hSentDroped);//\\Network Interface(*)\\packets outbound discarded",

	//proc
	PdhAddCounter(hQuery, GetEnglishPdhQuery(238, 6, false, L"(_total)").data(),
			0, &c.hProcTime);		//  "\\processor(_total)\\% processor time"
	PdhAddCounter(hQuery,
			GetEnglishPdhQuery(238, 142, false, L"(_total)").data(), 0,
			&c.hProcUserTime);//	"\\processor(_total)\\% user time",
	PdhAddCounter(hQuery, GetEnglishPdhQuery(238, 6, false, L"(_total)").data(),
			0, &c.hProcTimeWildCard);//	"\\processor(_total)\\% processor time",
	PdhAddCounter(hQuery,
			GetEnglishPdhQuery(238, 144, false, L"(_total)").data(), 0,
			&c.hProcPrevTime);		//	"\\processor(_total)\\% privileged time
	PdhAddCounter(hQuery,
			GetEnglishPdhQuery(238, 1746, false, L"(_total)").data(), 0,
			&c.hProcIdleTime);		//	"\\processor(_total)\\% idle time",
	PdhAddCounter(hQuery,
			GetEnglishPdhQuery(238, 44, false, L"(_total)").data(), 0,
			&c.hProcQueue);			//	"\\system\\processor queue length"
	PdhAddCounter(hQuery,
			GetEnglishPdhQuery(238, 698, false, L"(_total)").data(), 0,
			&c.hProcIteruptTime);	//	"\\processor(_total)\\% interrupt time"

	WriteFileLogf(L"Requesting parameters.");

	HANDLE hTimer = NULL;
	HANDLE hTimerQueue = CreateTimerQueue();
	gDoneEvent = CreateEvent(NULL, TRUE, FALSE, NULL);

	TimerParameters *params = new TimerParameters();
	params->hQuery = hQuery;
	params->ws = ws;
	params->counters = c;
	params->requests = r;
	params->count = new unsigned int(0);

	if (!CreateTimerQueueTimer(&hTimer, hTimerQueue,
			(WAITORTIMERCALLBACK) TimerRoutine, (LPVOID *) params, 10,
			ws->parameters.interval * 1000, 0)) {
		WriteFileLogf(L"Failed to create CreateTimerQueueTimer.");
		return status_ok;
	}
	//Main loop
	PdhCollectQueryData(hQuery);
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

			return status_ok;
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
	PDHHandlers c = params->counters;
	WMIRequests r = params->requests;
	RecorderProperties *ws = params->ws;
	HQUERY hQuery = params->hQuery;
	PDH_STATUS status;
	PDH_FMT_COUNTERVALUE pdhValue;
	//requests
	int requestResult;

	map<wstring, map<wstring, wstring>> resultDataProc = map<wstring,
			map<wstring, wstring>>(), resultDataProcSec = map<wstring,
			map<wstring, wstring>>(), resultDataSystem = map<wstring,
			map<wstring, wstring>>(), resultDataMemory = map<wstring,
			map<wstring, wstring>>(), resultDataOS = map<wstring,
			map<wstring, wstring>>(), resultDataNetwork = map<wstring,
			map<wstring, wstring>>();

	int cpuCount = 0;
	SysRecData d = { };
	//-----------------------cpu----------------------------
	requestResult = WMIRequest(ws->pSvc, ws->pLoc, r.rProcessor, resultDataProc,
			L"SELECT * FROM Win32_PerfFormattedData_PerfOS_Processor");
	Sleep(10);
	requestResult =
			WMIRequest(ws->pSvc, ws->pLoc, r.rSystem, resultDataSystem,
					L"SELECT * FROM Win32_PerfFormattedData_PerfOS_System")
					== REQUESTCHECK;
	Sleep(10);
	requestResult =
			WMIRequest(ws->pSvc, ws->pLoc, r.rMemory, resultDataMemory,
					L"SELECT * FROM Win32_PerfFormattedData_PerfOS_Memory")
					== REQUESTCHECK;
	Sleep(10);
	requestResult =
			WMIRequest(ws->pSvc, ws->pLoc, r.rOs, resultDataOS,
					L"SELECT * FROM Win32_OperatingSystem") == REQUESTCHECK;
	Sleep(10);
	//requestResult = WMIRequest(ws->pSvc, ws->pLoc ,r.rNetwork ,
	//resultDataNetwork,
	//L"SELECT * FROM Win32_PerfFormattedData_Tcpip_NetworkInterface")
	//== REQUESTCHECK;

	//handing lost connection and reconnecting
	if (requestResult != status_ok) {
		if (ws->pSvc != NULL)
			ws->pSvc->Release();
		if (ws->pLoc != NULL)
			ws->pLoc->Release();

		ws->pSvc = NULL;
		ws->pLoc = NULL;

		CoUninitialize();
		WriteFileLogf(L"Reconnecting\n");
		WMIConnect(&ws->pSvc, &ws->pLoc);
		return;
	}

	//cpu
	for (map<wstring, map<wstring, wstring>>::const_iterator iterator =
			resultDataProc.begin(), end = resultDataProc.end(); iterator != end;
			++iterator) {
		pair<wstring, map<wstring, wstring>> row = *iterator;
		if (row.first != L"_Total") {
			cpuCount++;
			d.cpupct += stoi(row.second[L"PercentProcessorTime"]);
			d.sumpct += stoi(row.second[L"PercentProcessorTime"]);
		}
	}

	if (status = PdhCollectQueryData(hQuery)) {
		WriteFileLogf(L"Failed to get counters, code 0x%x.\n", status);
		return;
	}
	Sleep(200);

	wchar_t stBuf[2048] = L"";

	status = PdhGetFormattedCounterValue(c.hProcTime, PDH_FMT_DOUBLE,
			(LPDWORD) NULL, &pdhValue);
	d.cpupct = pdhValue.doubleValue;
	d.sumpct = pdhValue.doubleValue;

	status = PdhGetFormattedCounterValue(c.hProcPrevTime, PDH_FMT_DOUBLE,
			(LPDWORD) NULL, &pdhValue);
	d.syspct = pdhValue.doubleValue;

	status = PdhGetFormattedCounterValue(c.hProcUserTime, PDH_FMT_DOUBLE,
			(LPDWORD) NULL, &pdhValue);
	d.userpct = pdhValue.doubleValue;

	status = PdhGetFormattedCounterValue(c.hProcIteruptTime, PDH_FMT_DOUBLE,
			(LPDWORD) NULL, &pdhValue);
	d.irqpct = pdhValue.doubleValue;

	status = PdhGetFormattedCounterValue(c.hProcIdleTime, PDH_FMT_DOUBLE,
			(LPDWORD) NULL, &pdhValue);

	d.idlepct = pdhValue.doubleValue;

	////////////////////////////

	d.sumpct *= (double) cpuCount;
	d.headpct = (double) (cpuCount * 100.0) - d.sumpct;



	d.runqsz = stoull(
			resultDataSystem.begin()->second[L"ProcessorQueueLength"]);
	d.plistsz = stoull(resultDataSystem.begin()->second[L"Processes"]);
	//cpu

	//disk

	PdhGetFormattedCounterValue(c.hDiskReadByt, PDH_FMT_DOUBLE, (LPDWORD) NULL,
			&pdhValue);
	d.readByt = pdhValue.doubleValue / 1024;

	PdhGetFormattedCounterValue(c.hDiskWriteByt, PDH_FMT_DOUBLE, (LPDWORD) NULL,
			&pdhValue);
	d.writeByt = pdhValue.doubleValue / 1024;

	PdhGetFormattedCounterValue(c.hDiskReadReq, PDH_FMT_DOUBLE, (LPDWORD) NULL,
			&pdhValue);
	d.readReq = pdhValue.doubleValue;

	PdhGetFormattedCounterValue(c.hDiskWriteReq, PDH_FMT_DOUBLE, (LPDWORD) NULL,
			&pdhValue);
	d.writeReq = pdhValue.doubleValue;

	d.totReq = d.readReq + d.writeReq;
	d.totByt = d.writeByt + d.readByt;
	//disk

	//memory
	d.memtotal = stoull(
			resultDataOS.begin()->second[L"TotalVisibleMemorySize"]);

	status = PdhGetFormattedCounterValue(c.hCounterMZero, PDH_FMT_LARGE,
			(LPDWORD) NULL, &pdhValue);

	if (status)	// xp and 2003
	{
		d.memfree = stoull(
				resultDataMemory.begin()->second[L"AvailableKBytes"]);
		d.realfree = d.memfree;
		d.memused = d.memtotal - d.realfree;
		d.memusedpct = (double) d.memused / (double) d.memtotal * 100.0;

		d.realfreepct = (double) d.realfree / (double) d.memtotal * 100.0;
		d.buffers = 0;
		d.cached = stoull(resultDataMemory.begin()->second[L"CacheBytes"])
				/ 1024;
	} else {

		d.memfree = pdhValue.largeValue / 1024;

		d.realfree = stoull(
				resultDataMemory.begin()->second[L"AvailableKBytes"]);
		d.realfreepct = (double) d.realfree / (double) d.memtotal * 100.0;

		d.memused = d.memtotal - d.realfree;
		d.memusedpct = (double) d.memused / (double) d.memtotal * 100.0;

		PdhGetFormattedCounterValue(c.hCounterModified, PDH_FMT_LARGE,
				(LPDWORD) NULL, &pdhValue);
		d.buffers = pdhValue.largeValue / 1024;

		//all stanby and buffer refers to cache
		PdhGetFormattedCounterValue(c.hCounterStandbyReserve, PDH_FMT_LARGE,
				(LPDWORD) NULL, &pdhValue);
		d.cached += pdhValue.largeValue / 1024;

		PdhGetFormattedCounterValue(c.hCounterStandbyNormal, PDH_FMT_LARGE,
				(LPDWORD) NULL, &pdhValue);
		d.cached += pdhValue.largeValue / 1024;

		PdhGetFormattedCounterValue(c.hCounterStandbyPriority, PDH_FMT_LARGE,
				(LPDWORD) NULL, &pdhValue);
		d.cached += pdhValue.largeValue / 1024;
		d.cached += d.buffers;

	}

	d.swaptotal = stoull(
			resultDataOS.begin()->second[L"SizeStoredInPagingFiles"]);
	d.swapfree = stoull(
			resultDataOS.begin()->second[L"FreeSpaceInPagingFiles"]);
	d.swapused = d.swaptotal - d.swapfree;
	if (d.swaptotal != 0)
		d.swapusedpct = (double) d.swapused / (double) d.swaptotal * 100.0;

	//memory

	//network

	d.rxByt += GetCounterTotal(c.hReceivedBytes) / 1024.0;
	d.txByt += GetCounterTotal(c.hSentBytes) / 1024.0;
	d.ntByt += d.rxByt + d.txByt;
	d.rxerr += GetCounterTotal(c.hReceivedErrors);
	d.txerr += GetCounterTotal(c.hSentErrors);
	d.rxdrp += GetCounterTotal(c.hReceivedDroped);
	d.txdrp += GetCounterTotal(c.hSentDroped);

	//network

	//rawstring
	wchar_t szBuf[2048] = L"";
	_snwprintf_s(szBuf, 2048, _TRUNCATE,
			L"%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:"		//cpu
					L"%.2f:%llu:%llu:"//cpu
					L"%.2f:%llu:%llu:%llu:%llu:%llu:%llu:%.2f:"//memory
					L"%.2f:%llu:%llu:%llu:%llu:"//swap
					L"%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:"//disk
					L"%.2f:%.2f:%.2f:%.2f:%.2f:%.2f:%.2f",//network
			d.cpupct, d.sumpct, d.headpct, d.userpct, d.syspct, d.idlepct,
			d.irqpct,
			d.runqsz, d.plistsz, d.memusedpct, d.memused, d.memfree, d.memtotal,
			d.buffers, d.cached, d.realfree, d.realfreepct, d.swapusedpct,
			d.swapused, d.swapfree, d.swaptotal, d.swapcached, d.readReq,
			d.writeReq, d.totReq, d.readByt, d.writeByt, d.totByt, d.rxByt,
			d.txByt, d.ntByt, d.rxerr, d.txerr, d.rxdrp, d.txdrp);

	if (int writeStatus = WriteFileRaw(ws->rawStream, szBuf) != status_ok) {
		WriteFileLogf(L"Failed to write to raw, reopening.");
		OpenFileStream(ws->rawStream,
				ws->parameters.rawCurrentPath + ws->parameters.rawCurrentFile);

	}
#ifdef REC_TEST_CONSOLE
	wcout<<szBuf<<endl;
#endif

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
		"Sysrec: ServiceMain: SetServiceStatus returned error"));
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
		"sysrec: ServiceMain: SetServiceStatus returned error"));
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
		"Sysec: ServiceMain: SetServiceStatus returned error"));
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
		"rec: ServiceMain: SetServiceStatus returned error"));
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
	"rec: ServiceCtrlHandler: SetServiceStatus returned error"));
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
