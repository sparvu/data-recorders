/*
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
#include <windows.h>
#include <stdio.h>
#include <string>
#include <iostream>
#include <cstdlib>
std::wstring EtcAppPath() {
	WCHAR szPath[MAX_PATH];
	GetModuleFileName(NULL, szPath, FILENAME_MAX);
	std::wstring appPath(szPath);
	appPath = appPath.substr(0, appPath.find_last_of(L"\\"));
	appPath = appPath.substr(0, appPath.find_last_of(L"\\")).append(L"\\etc\\");
	return appPath;
}

int main(int argc, char *argv[]) {

//	std::wcout<<argc<<std::endl;
//	std::wcout<<EtcAppPath()<<std::endl;
	if (argc == 2 && strcmp(argv[1], "Install") == 0) {
		std::wcout << L"Instalation" << std::endl;
		ShellExecute(0, L"open", L"cmd.exe", L"/C startSDRAll.bat",
				EtcAppPath().data(), SW_HIDE);
	}

	if (argc == 2 && strcmp(argv[1], "Uninstall") == 0) {
		std::wcout << L"Removal" << std::endl;
		ShellExecute(0, L"open", L"cmd.exe", L"/C deleteAllNA.bat",
				EtcAppPath().data(), SW_HIDE);
	}
	Sleep(10000);
	return 0;
}
