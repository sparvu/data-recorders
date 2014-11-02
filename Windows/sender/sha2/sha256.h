/*
 *  FIPS-180-2 compliant SHA-256 implementation
 *
 *  Copyright (C) 2001-2003  Christophe Devine
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */


#ifndef _SHA256_H
#define _SHA256_H

#include <string>
#include <array>
#include "../sha1/SHA1.h"

namespace umtl
{
	typedef unsigned char uint8;
	typedef unsigned long int uint32;

	//-----------------------------------------------------------------------
	//

	struct sha256_context;

	void sha256_starts( sha256_context *ctx );
	void sha256_update( sha256_context *ctx, uint8 *input, uint32 length );
	void sha256_finish( sha256_context *ctx, std::tr1::array<uint8,32> & digest );

	struct sha256_context
	{
		uint32 total[2];
		uint32 state[8];
		uint8 buffer[64];
		std::tr1::array<uint8,32> digest;

		sha256_context() {
			clear();
		}

		void clear() {
			sha256_starts( this );
		}

		void update( uint8 * input, uint32 length )	{
			sha256_update( this, input, length );
		}

		void finish() {
			sha256_finish( this, digest );
			sha256_starts( this );
		}
	};


	//-----------------------------------------------------------------------
	//

	class sha256
	{
	public:
		sha256() : finish_(false) {}
		virtual ~sha256() {}

		#define sha256_update_char( inst )			inst.ctx.update( (uint8*)str, (uint32)strlen(str) ); inst.finish_ = false;
		#define sha256_update_string( inst )		inst.ctx.update( (uint8*)str.c_str(), (uint32)str.length() ); inst.finish_ = false;
		#define sha256_update_wchar( inst )			inst.ctx.update( (uint8*)str, (uint32)(wcslen(str)*sizeof(wchar_t)) ); inst.finish_ = false;
		#define sha256_update_wstring( inst )		inst.ctx.update( (uint8*)str.c_str(), (uint32)(str.length()*sizeof(wchar_t)) ); inst.finish_ = false;
													
		sha256( const char * str )												{ sha256_update_char	( (*this) ); }
		sha256( std::string & str )												{ sha256_update_string	( (*this) ); }
		sha256( std::string && str )											{ sha256_update_string	( (*this) ); }
		sha256( const wchar_t * str )											{ sha256_update_wchar	( (*this) ); }
		sha256( std::wstring & str )											{ sha256_update_wstring	( (*this) ); }
		sha256( std::wstring && str )											{ sha256_update_wstring	( (*this) ); }

		inline sha256 & operator +=( const char * str )							{ sha256_update_char	( (*this) ); return *this; }
		inline sha256 & operator +=( std::string const & str )					{ sha256_update_string	( (*this) ); return *this; }
		inline sha256 & operator +=( std::string const && str )					{ sha256_update_string	( (*this) ); return *this; }
		inline sha256 & operator +=( const wchar_t * str )						{ sha256_update_wchar	( (*this) ); return *this; }
		inline sha256 & operator +=( std::wstring const & str )					{ sha256_update_wstring	( (*this) ); return *this; }
		inline sha256 & operator +=( std::wstring const && str )				{ sha256_update_wstring	( (*this) ); return *this; }

		#undef sha256_update_char
		#undef sha256_update_string
		#undef sha256_update_wchar
		#undef sha256_update_wstring

		friend sha256 & operator+( sha256 & inst, std::string const & str )		{ return inst+= str; }
		friend sha256 & operator+( sha256 & inst, std::string const && str )	{ return inst+= str; }
		friend sha256 & operator+( sha256 & inst, std::wstring const & str )	{ return inst+= str; }
		friend sha256 & operator+( sha256 & inst, std::wstring const && str )	{ return inst+= str; }
		friend sha256 & operator+( sha256 & inst, char const * str )			{ return inst+= str; }
		friend sha256 & operator+( sha256 & inst, wchar_t const * str )			{ return inst+= str; }

		sha256 & operator=( std::string const & str )							{ ctx.clear(); return (*this) += str; }
		sha256 & operator=( std::string const && str )							{ ctx.clear(); return (*this) += str; }
		sha256 & operator=( std::wstring const & str )							{ ctx.clear(); return (*this) += str; }
		sha256 & operator=( std::wstring const && str )							{ ctx.clear(); return (*this) += str; }
		sha256 & operator=( const char * str )									{ ctx.clear(); return (*this) += str; }
		sha256 & operator=( wchar_t const * str )								{ ctx.clear(); return (*this) += str; }

		TCHAR const * c_str() {
			if( !finish_ )
			{
				ctx.finish();
				memset( hash_, 0, sizeof(hash_) );
				ReportHash( hash_, sizeof(hash_)/sizeof(TCHAR) );
				finish_ = true;
			}
			return hash_;
		}

		friend std::wistream & operator >> ( std::wistream & istream, sha256 & inst ) {
			std::wstring str;
			istream >> str;
			inst += str;
			return istream;
		}
		friend std::istream & operator >> ( std::istream & istream, sha256 & inst ) {
			std::string str;
			istream >> str;
			inst += str;
			return istream;
		}

		friend std::basic_ostream< TCHAR, std::char_traits<TCHAR> > & 
			operator << ( std::basic_ostream< TCHAR, std::char_traits<TCHAR> > & stream, sha256 & inst ) {
				return stream << inst.c_str();
		}


		void ReportHash(TCHAR* tszReport, size_t len) const
		{
			if(tszReport == NULL) return;

			TCHAR tszTemp[64];

			_sntprintf_s(tszTemp, 64, _T("%02x"), ctx.digest[0]);
			_tcscpy_s(tszReport, len, tszTemp);

			for(size_t i = 1; i < 32; ++i)
			{
				_sntprintf_s(tszTemp, 64, _T("%02x"), ctx.digest[i]);
				_tcscat_s(tszReport, len, tszTemp);
			}

			return;
		}

	private:
		sha256_context ctx;
		TCHAR hash_[65];
		bool finish_;
	};
}

#endif /* sha256.h */
