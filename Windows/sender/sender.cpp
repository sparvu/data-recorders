/*
 *  SDRsender
 *  SystemDataRecorder remote sender
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
#include "Winsock2.h"
#include "shared.h"
#include "pugixml-1.2\pugixml.hpp"
#include "sha2\sha256.h"
#include <Winhttp.h>
#include <algorithm>
using namespace std;
#define SERVICE_NAME  _T("sender")
#pragma comment(lib, "Ws2_32.lib")
#pragma comment(lib,"Winhttp.lib")
SERVICE_STATUS gServiceStatus = { 0 };
SERVICE_STATUS_HANDLE gStatusHandle = NULL;
HANDLE gServiceStopEvent = INVALID_HANDLE_VALUE;

//uncomment for console run
//#define	REC_TEST_CONSOLE 

#define	SEND_CHAR 

VOID WINAPI ServiceMain(DWORD argc, LPTSTR *argv);
DWORD WINAPI ServerCtrlHandlerEx(DWORD, DWORD, LPVOID, LPVOID);
DWORD WINAPI ServiceWorkerThread(LPVOID lpParam);
wofstream *defaultlog;
struct SDRProtocol {
	int port, proxyport;
	wstring protocol, proxy;

};

struct SDRHost {
	wstring name, username, password;
	vector<SDRProtocol> protocols;
};
struct SDRRecorder {
	wstring name;
	wifstream* stream;
	streamoff filesize;
};
struct SenderConfig {
	wstring subscription, privateKey, destination, protocol, hostname;
	vector<SDRRecorder> recorders;
	vector<SDRHost> hosts;
	bool tcpKeepalive;
};

SenderConfig scfg;

wstring RemoveWstringSymbol(wstring data, wchar_t symbol) {

	wstring tmp;
	for (int i = 0; i < data.size(); i++) {

		if (data[i] != symbol)
			tmp.push_back(data[i]);
	}
	return tmp;
}

wstring FetchNewStrings(wifstream *recorder, streamoff &lastPosition) {
	recorder->seekg(0, ios::end);
	streamoff filesize = recorder->tellg();

	if (filesize < lastPosition) {
		lastPosition = 0;
	}
	wstring buffer;
	for (streamoff n = lastPosition; n < filesize; n++) {

		recorder->seekg(lastPosition, ios::beg);
		wchar_t text[2048];
		recorder->getline(text, 2048);
		lastPosition = recorder->tellg();

		buffer.append(text);
		buffer.append(L"\n");
		if (filesize == lastPosition) {
			break;
		}
	}

	return buffer;
}

int InitSender(RecorderProperties *ws) {

	ws->pLoc = NULL;
	ws->pSvc = NULL;
	ws->treminateFlag = false;
	ws->parameters.interval = 5;
	ws->parameters.name = SERVICE_NAME;
	//recoder logs initialisation
	wstring preLog = AppPath() + L"\\SDRpreinitSender.log";
	OpenFileStream(ws->logStream, preLog);
	SetDefaultLog(ws->logStream);

	pugi::xml_document config;

	ZeroMemory(&scfg, sizeof(scfg));
	if (int initConfigResult = InitConfig(config) != status_ok) {
		return initConfigResult;
	}

	wstring apppath = AppPath();
	wstring currentLogPath =
			config.select_single_node(L"/sdr/recording/logs/current").node().attribute(
					L"path").as_string();
	if (currentLogPath.empty()) {
		WriteFileLogf(L"Failed to init configuration, code here:");
		return status_config_file_not_found;
	} else {
		ws->parameters.rawCurrentPath = apppath + currentLogPath;
	}

	wstring dailyLogPath =
			apppath
					+ config.select_single_node(L"/sdr/recording/logs/daily").node().attribute(
							L"path").as_string();
	if (dailyLogPath.empty()) {
		WriteFileLogf(L"Failed to init configuration, code here:");
		return status_config_file_not_found;
	} else {
		ws->parameters.logDailyPath = dailyLogPath;
	}

	pugi::xml_node transport = config.select_single_node(
			L"/sdr/recording/transport").node();

	scfg.subscription = config.select_single_node(
			L"/sdr/recording/subscription").node().text().as_string();

	scfg.privateKey =
			transport.child(L"private_key").attribute(L"path").as_string();
	scfg.destination =
			config.select_single_node(L"/sdr/recording/hostid").node().text().as_string();
	scfg.protocol = transport.child(L"protocol").text().as_string();
	scfg.tcpKeepalive = transport.child(L"tcp_keepalive").text().as_bool();

	if (transport.attribute(L"interval").empty()) {
		ws->parameters.interval = 60;
	} else {
		ws->parameters.interval = transport.attribute(L"interval").as_int();
	}

	char namebuf[255] = "";
	gethostname(namebuf, 255);

	string namestr(namebuf);

	scfg.hostname = wstring(namestr.begin(), namestr.end());

	wstring logFile = wstring(ws->parameters.name + L"rec.log");
	CloseFileStream(ws->logStream);
	DeleteFile(preLog.data());

	OpenFileStream(ws->logStream, ws->parameters.rawCurrentPath + logFile);
	SetDefaultLog(ws->logStream);

	for (pugi::xml_node trNode = config.select_single_node(
			L"/sdr/recording/transport/data/sdrd").node(); trNode; trNode =
			trNode.next_sibling(L"sdrd")) {
		wstring recorderName = trNode.attribute(L"name").as_string();
		SDRRecorder rec;
		rec.stream = new wifstream(
				ws->parameters.rawCurrentPath + recorderName + L"rec.sdrd");
		rec.name = recorderName;
		rec.stream->seekg(0, ios::end);
		rec.filesize = rec.stream->tellg();
		scfg.recorders.push_back(rec);

	}

	for (pugi::xml_node hostNode = config.select_single_node(
			L"/sdr/reporting/host").node(); hostNode;
			hostNode = hostNode.next_sibling()) {
		SDRHost hst;
		hst.name = hostNode.attribute(L"name").as_string();
		hst.username = hostNode.child(L"username").text().as_string();
		hst.password = hostNode.child(L"password").text().as_string();

		//https now

		/*if(!hostNode.child(L"http").empty()){
		 pugi::xml_node httpNode =  hostNode.child(L"http");
		 SDRProtocol ptc;
		 ptc.port =  httpNode.child(L"port").text().as_int();
		 ptc.proxy =  httpNode.child(L"proxy").text().as_string();
		 ptc.proxyport =  httpNode.child(L"proxyport").text().as_int();
		 hst.protocols.push_back(ptc);
		 }*/
		if (!hostNode.child(L"https").empty()) {
			pugi::xml_node httpsNode = hostNode.child(L"https");
			SDRProtocol ptc;
			ptc.port = httpsNode.child(L"port").text().as_int();
			ptc.proxy = httpsNode.child(L"proxy").text().as_string();
			ptc.proxyport = httpsNode.child(L"proxyport").text().as_int();
			hst.protocols.push_back(ptc);
		}
		/*	if(!hostNode.child(L"ssh2").empty()){
		 pugi::xml_node httpsNode =  hostNode.child(L"ssh2");
		 SDRProtocol ptc;
		 ptc.port =  httpsNode.child(L"port").text().as_int();
		 }
		 if(!hostNode.child(L"ftp").empty()){
		 pugi::xml_node httpsNode =  hostNode.child(L"ftp");
		 SDRProtocol ptc;
		 ptc.port =  httpsNode.child(L"port").text().as_int();
		 hst.protocols.push_back(ptc);
		 }*/
		scfg.hosts.push_back(hst);
	}
	return status_ok;
}

void AsyncCallback(HINTERNET hInternet, DWORD_PTR dwContext,
		DWORD dwInternetStatus, LPVOID lpvStatusInformation,
		DWORD dwStatusInformationLength) {

}

int TransferHTTPS(RecorderProperties* ws, wstring dest, wstring sdrid,
		wstring dbid, wstring delta, int hport, wstring hproxy = L"",
		int hproxyport = 0) {
	BOOL bResults = FALSE;
	HINTERNET hSession = NULL, hConnect = NULL, hRequest = NULL;

	// connect
	if (!hproxy.empty()) {
		wchar_t proxybuf[255] = L"";
		_snwprintf(proxybuf, 225, L"%s:%d", hproxy.data(), hport);
		hSession = WinHttpOpen(L"SDR windows sender",
				WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, proxybuf,
				NULL, 0);

		WriteFileLogf(L"Connected without proxy.");

	} else {
		hSession = WinHttpOpen(L"SDR windows sender",
				WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, WINHTTP_NO_PROXY_NAME,
				WINHTTP_NO_PROXY_BYPASS, 0);

		WriteFileLogf(L"Connected with proxy.");

	}

	if (!hSession) {
		wchar_t errorbuf[1024] = L"";
		_snwprintf(errorbuf, 1024, L"Error Open %d has occurred.",
				GetLastError());
		WriteFileLogf(errorbuf);

	}
	//sha256
	delta.shrink_to_fit();
	wstring tdelta = delta
			+ L":73:79:73:74:65:6d:64:61:74:61:72:65:63:6f:72:64:65:72";
	tdelta = RemoveWstringSymbol(tdelta, L':');
	wstring payload = umtl::sha256(tdelta).c_str();

	if (hSession)
		hConnect = WinHttpConnect(hSession, dest.c_str(), hport, 0);

	LPCWSTR types[2];
	types[0] = L"application/x-www-form-urlencoded";
	types[1] = 0;

	if (hConnect)
		hRequest = WinHttpOpenRequest(hConnect, L"POST", L"/api/ps",
		NULL, WINHTTP_NO_REFERER, types, WINHTTP_FLAG_SECURE);

	DWORD dwTmp = SECURITY_FLAG_IGNORE_CERT_CN_INVALID
			| SECURITY_FLAG_IGNORE_UNKNOWN_CA;

	WinHttpSetOption(hRequest, WINHTTP_OPTION_SECURITY_FLAGS, (LPVOID) & dwTmp,
			sizeof(dwTmp));

	//params
	wchar_t valuewBuf[2048 * 20] = L"";
	_snwprintf(valuewBuf, 2048 * 10, L"value=%s&h=%s&db=%s&hash=%s&data=%s",
			sdrid.data(), scfg.hostname.data(), dbid.data(), payload.data(),
			delta.data());

	if (!hConnect) {
		wchar_t errorbuf[1024] = L"";
		_snwprintf(errorbuf, 1024, L"Error Request %d has occurred.",
				GetLastError());
		WriteFileLogf(errorbuf);

	}

#ifdef SEND_CHAR
	//sending char
	char valueBuf[2048 * 10];
	char DefChar = ' ';

	WideCharToMultiByte(CP_ACP, 0, valuewBuf, -1, valueBuf, 2048 * 10, &DefChar,
			NULL);
	if (hRequest)
		bResults = WinHttpSendRequest(hRequest, 0, 0, (LPVOID) valueBuf,
				strlen(valueBuf), strlen(valueBuf), 0);
#endif
#ifndef SEND_CHAR

	//sending wchar_t
	if(hRequest)
	bResults = WinHttpSendRequest(
			hRequest,
			0,
			0,
			(LPVOID)valuewBuf,
			wcslen(valuewBuf),
			wcslen(valuewBuf),0);

#endif

	if (!bResults) {
		wchar_t errorbuf[1024] = L"";
		_snwprintf(errorbuf, 1024, L"Error Write %d has occurred.",
				GetLastError());
		WriteFileLogf(errorbuf);

	}

	// receive
	if (bResults)
		bResults = WinHttpReceiveResponse(hRequest, NULL);

	if (bResults) {
		wchar_t errorbuf[1024] = L"";
#ifdef SEND_CHAR
		_snwprintf(errorbuf, 1024, L"Sucessfuly send POST of %d size.",
				strlen(valueBuf));
#endif
#ifndef SEND_CHAR
		_snwprintf(errorbuf,1024,L"Sucessfuly send POST of %d size.",wcslen(valuewBuf));
#endif

		WriteFileLogf(errorbuf);

	} else {
		wchar_t errorbuf[1024] = L"";
		_snwprintf(errorbuf, 1024, L"Error Receive %d has occurred.",
				GetLastError());
		WriteFileLogf(errorbuf);

	}

	LPSTR pszOutBuffer;
	DWORD dwSize = 0;
	DWORD dwDownloaded = 0;
	if (bResults) {
		do {
			dwSize = 0;
			if (!WinHttpQueryDataAvailable(hRequest, &dwSize)) {
				wchar_t errorbuf[1024] = L"";
				_snwprintf(errorbuf, 1024,
						L"Error Receive data %d has occurred.", GetLastError());
				WriteFileLogf(errorbuf);

				break;
			}

			if (!dwSize)
				break;

			pszOutBuffer = new char[dwSize];

			ZeroMemory(pszOutBuffer, dwSize);

			if (!WinHttpReadData(hRequest, (LPVOID) pszOutBuffer, dwSize,
					&dwDownloaded)) {
				wchar_t errorbuf[1024] = L"";
				_snwprintf(errorbuf, 1024, L"Error Read data %d has occurred.",
						GetLastError());
				WriteFileLogf(errorbuf);

			} else {
				wchar_t errorbuf[1024] = L"";
				_snwprintf(errorbuf, 1024, L"Sucessfuly read response.");

				WriteFileLogf(errorbuf);

			}
			delete[] pszOutBuffer;

		} while (dwSize > 0);
	} else {
		wchar_t errorbuf[1024] = L"";
		_snwprintf(errorbuf, 1024, L"Error  %d has occurred.", GetLastError());
		WriteFileLogf(errorbuf);

	}

	// Close open handles.
	if (hRequest)
		WinHttpCloseHandle(hRequest);
	if (hConnect)
		WinHttpCloseHandle(hConnect);
	if (hSession)
		WinHttpCloseHandle(hSession);
	return 0;
}

int ServiceTimerStarter(RecorderProperties* ws) {
	//clock
	clock_t this_time = clock();
	clock_t last_time = this_time;
	double timeCounter = ws->parameters.interval * CLOCKS_PER_SEC + 10,
			timeCounterSec = 0;
	//Main loop

	for (int count = 0;;) {
		this_time = clock();
		timeCounter += (double) (this_time - last_time);
		timeCounterSec += (double) (this_time - last_time);
		last_time = this_time;

		if (ws->treminateFlag) {
			for (int index = 0; index < scfg.recorders.size(); index++) {
				if (scfg.recorders[index].stream->is_open()) {
					scfg.recorders[index].stream->close();
				}
			}
			return status_ok;
		}

		//requests
		if (timeCounter < 0) //time changes  backward
				{
			timeCounter = 0;
			WriteFileLogf(L"Time considerably chages\n");
		}

		if (timeCounter > (double) (ws->parameters.interval * CLOCKS_PER_SEC)) {

			timeCounter = 0;
			for (int index = 0; index < scfg.recorders.size(); index++) {

				if (!scfg.recorders[index].stream->is_open()) {
					scfg.recorders[index].stream->open(
							ws->parameters.rawCurrentPath
									+ scfg.recorders[index].name + L"rec.sdrd");
				}
				if (scfg.recorders[index].stream->is_open()) {

					wstring data = FetchNewStrings(scfg.recorders[index].stream,
							scfg.recorders[index].filesize);
					if (!data.empty()) {
						WriteFileLogf(
								wstring(L"Sending: ")
										+ scfg.recorders[index].name);
						TransferHTTPS(ws, scfg.destination, scfg.subscription,
								scfg.recorders[index].name, data,
								scfg.hosts[0].protocols[0].port,
								scfg.hosts[0].protocols[0].proxy,
								scfg.hosts[0].protocols[0].proxyport);
					}
					scfg.recorders[index].stream->close();
				} else {
					wchar_t errorbuf[1024] = L"";
					_snwprintf(errorbuf, 1024,
							L"Reopening stream for %s, no sdrd file found.",
							scfg.recorders[index].name.c_str());
					WriteFileLogf(errorbuf);

				}
			}

			count++;
		}
		if (timeCounterSec < 0)

			timeCounterSec = 0;
		if ((int) timeCounterSec > CLOCKS_PER_SEC) {
			timeCounterSec = 0;

			/*    int sec = SecSinceMidnight();
			 if((sec < 5 && sec >= 0 && !archiveDone) )
			 {
			 /*   if(ArchiveFileRaw(ws,true) == status_ok ){
			 archiveDone = true;
			 WriteFileLogf(L"Archive creating success.");
			 }
			 else
			 {
			 WriteFileLogf(L"Failed to save archive");
			 }

			 }
			 if( sec > 5 && archiveDone  ){
			 archiveDone = false;
			 }*/
		}
		Sleep(100);
	}

	return status_ok;
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
	InitSender(ws);
	ServiceTimerStarter(ws);
#endif
	return 0;
}

VOID WINAPI ServiceMain(DWORD argc, LPTSTR *argv) {

	RecorderProperties *ws = new RecorderProperties();
	InitSender(ws);

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
				_T("SDRSender: ServiceMain: SetServiceStatus returned error"));
	}

	gServiceStopEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
	if (gServiceStopEvent == NULL) {

		gServiceStatus.dwControlsAccepted = 0;
		gServiceStatus.dwCurrentState = SERVICE_STOPPED;
		gServiceStatus.dwWin32ExitCode = GetLastError();
		gServiceStatus.dwCheckPoint = 1;

		if (SetServiceStatus(gStatusHandle, &gServiceStatus) == FALSE) {
			WriteFileLogf(
					_T("SDRSender: ServiceMain: SetServiceStatus returned error"));
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
				_T("SDRSender: ServiceMain: SetServiceStatus returned error"));
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
				_T("SDRSender: ServiceMain: SetServiceStatus returned error"));
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
			_T("SDRSender: ServiceCtrlHandler: SetServiceStatus returned error"));
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

