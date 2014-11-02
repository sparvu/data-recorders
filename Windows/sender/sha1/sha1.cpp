#pragma once

#include "sha1.h"

// Rotate x bits to the left
#ifndef ROL32
#ifdef _MSC_VER
#define ROL32(_val32,_nBits) _rotl(_val32,_nBits)
#else
#define ROL32(_val32,_nBits) (((_val32)<<(_nBits))|((_val32)>>(32-(_nBits))))
#endif
#endif

#ifdef SHA1_LITTLE_ENDIAN
#define SHABLK0(i) (m_block->l[i] = \
	(ROL32(m_block->l[i],24) & 0xFF00FF00) | (ROL32(m_block->l[i],8) & 0x00FF00FF))
#else
#define SHABLK0(i) (m_block->l[i])
#endif

#define SHABLK(i) (m_block->l[i&15] = ROL32(m_block->l[(i+13)&15] ^ m_block->l[(i+8)&15] \
	^ m_block->l[(i+2)&15] ^ m_block->l[i&15],1))

// SHA-1 rounds
#define _R0(v,w,x,y,z,i) {z+=((w&(x^y))^y)+SHABLK0(i)+0x5A827999+ROL32(v,5);w=ROL32(w,30);}
#define _R1(v,w,x,y,z,i) {z+=((w&(x^y))^y)+SHABLK(i)+0x5A827999+ROL32(v,5);w=ROL32(w,30);}
#define _R2(v,w,x,y,z,i) {z+=(w^x^y)+SHABLK(i)+0x6ED9EBA1+ROL32(v,5);w=ROL32(w,30);}
#define _R3(v,w,x,y,z,i) {z+=(((w|x)&y)|(w&x))+SHABLK(i)+0x8F1BBCDC+ROL32(v,5);w=ROL32(w,30);}
#define _R4(v,w,x,y,z,i) {z+=(w^x^y)+SHABLK(i)+0xCA62C1D6+ROL32(v,5);w=ROL32(w,30);}

namespace umtl
{

	// Constructor and destructor
	sha1::sha1() : final_(false)
	{
		m_block = (SHA1_WORKSPACE_BLOCK*)m_workspace;
		Reset();
	}

	sha1::sha1( std::string const & str ) : final_(false)
	{
		m_block = (SHA1_WORKSPACE_BLOCK*)m_workspace;
		Reset();
		*this = str;
	}

	sha1::sha1( std::string const && str ) : final_(false)
	{
		m_block = (SHA1_WORKSPACE_BLOCK*)m_workspace;
		Reset();
		*this = str;
	}

	sha1::sha1( char const * str ) : final_(false)
	{
		m_block = (SHA1_WORKSPACE_BLOCK*)m_workspace;
		Reset();
		*this = str;
	}

	sha1::sha1( std::wstring const & str ) : final_(false)
	{
		m_block = (SHA1_WORKSPACE_BLOCK*)m_workspace;
		Reset();
		*this = str;
	}

	sha1::sha1( std::wstring const && str ) : final_(false)
	{
		m_block = (SHA1_WORKSPACE_BLOCK*)m_workspace;
		Reset();
		*this = str;
	}

	sha1::sha1( wchar_t const * str ) : final_(false)
	{
		m_block = (SHA1_WORKSPACE_BLOCK*)m_workspace;
		Reset();
		*this = str;
	}


	sha1::~sha1()
	{
		Reset();
	}

	sha1 & sha1::operator+=( std::string const & str )
	{
		Update( (UINT_8*)str.c_str(), str.length() );
		return *this;
	}

	sha1 & sha1::operator+=( std::string const && str )
	{
		Update( (UINT_8*)str.c_str(), str.length() );
		return *this;
	}

	sha1 & sha1::operator+=( const char * str )
	{
		Update( (UINT_8*)str, strlen( str ) );
		return *this;
	}

	sha1 & operator+( sha1 & inst, std::string const & str )
	{
		inst += str;
		return inst;
	}

	sha1 & operator+( sha1 & inst, std::string const && str )
	{
		inst += str;
		return inst;
	}

	sha1 & operator+( sha1 & inst, char const * str )
	{
		inst += str;
		return inst;
	}

	sha1 & sha1::operator+=( std::wstring const & str )
	{
		Update( (UINT_8*)str.c_str(), str.length() * sizeof(wchar_t) );
		return *this;
	}

	sha1 & sha1::operator+=( std::wstring const && str )
	{
		Update( (UINT_8*)str.c_str(), str.length() * sizeof(wchar_t) );
		return *this;
	}

	sha1 & sha1::operator+=( const wchar_t * str )
	{
		Update( (UINT_8*)str, wcslen(str) * sizeof(wchar_t) );
		return *this;
	}

	sha1 & operator+( sha1 & inst, std::wstring const & str )
	{
		inst += str;
		return inst;
	}

	sha1 & operator+( sha1 & inst, std::wstring const && str )
	{
		inst += str;
		return inst;
	}

	sha1 & operator+( sha1 & inst, wchar_t const * str )
	{
		inst += str;
		return inst;
	}

	sha1 & sha1::operator[]( std::basic_string< TCHAR > const & filename )
	{
		Reset();
		HashFile(filename.c_str());
		return *this;
	}

	sha1 & sha1::operator[]( std::basic_string< TCHAR > const && filename )
	{
		Reset();
		HashFile(filename.c_str());
		return *this;
	}

	sha1 & sha1::operator[]( const TCHAR * filename )
	{
		Reset();
		HashFile(filename);
		return *this;
	}

	sha1 & sha1::operator=( std::string const & str )
	{
		Reset();
		*this += str;
		return *this;
	}

	sha1 & sha1::operator=( std::string const && str )
	{
		Reset();
		*this += str;
		return *this;
	}

	sha1 & sha1::operator=( const char * str )
	{
		Reset();
		*this += str;
		return *this;
	}

	sha1 & sha1::operator=( std::wstring const & str )
	{
		Reset();
		*this += str;
		return *this;
	}

	sha1 & sha1::operator=( std::wstring const && str )
	{
		Reset();
		*this += str;
		return *this;
	}

	sha1 & sha1::operator=( wchar_t const * str )
	{
		Reset();
		*this += str;
		return *this;
	}

	const TCHAR * sha1::c_str()
	{
		Final();
		ReportHashStl( hash_str_, sha1::REPORT_HEX_SHORT );
		return hash_str_.empty() ? 0 : hash_str_.c_str();
	}

	const char * sha1::c_buf()
	{
		return (char *)m_buffer;
	}

	std::wistream & operator >> ( std::wistream & istream, sha1 & inst )
	{
		std::wstring str;
		istream >> str;
		inst += str;
		return istream;
	}

	std::istream & operator >> ( std::istream & istream, sha1 & inst )
	{
		std::string str;
		istream >> str;
		inst += str;
		return istream;
	}

	std::basic_ostream< TCHAR, std::char_traits<TCHAR> > & 
		operator << ( std::basic_ostream< TCHAR, std::char_traits<TCHAR> > & stream, sha1 & inst )
	{
		return stream << inst.c_str();
	}

	void sha1::Reset()
	{
		// SHA1 initialization constants
		m_state[0] = 0x67452301;
		m_state[1] = 0xEFCDAB89;
		m_state[2] = 0x98BADCFE;
		m_state[3] = 0x10325476;
		m_state[4] = 0xC3D2E1F0;

		m_count[0] = 0;
		m_count[1] = 0;

		memset( m_buffer, 0, sizeof( m_buffer ) );

		hash_str_.clear();

		final_ = false;
	}

	// Update the hash value
	void sha1::Update(const UINT_8* pbData, UINT_32 uLen)
	{
		if( final_ )
			Reset();

		UINT_32 j = ((m_count[0] >> 3) & 0x3F);

		if((m_count[0] += (uLen << 3)) < (uLen << 3))
			++m_count[1]; // Overflow

		m_count[1] += (uLen >> 29);

		UINT_32 i;
		if((j + uLen) > 63)
		{
			i = 64 - j;
			memcpy_s(&m_buffer[j], i, pbData, i);
			Transform(m_state, m_buffer);

			for( ; (i + 63) < uLen; i += 64)
				Transform(m_state, &pbData[i]);

			j = 0;
		}
		else i = 0;

		if((uLen - i) != 0)
			memcpy_s(&m_buffer[j], 64 - j, &pbData[i], uLen - i);
	}

#ifdef SHA1_UTILITY_FUNCTIONS
	// Hash in file contents
	bool sha1::HashFile(const TCHAR* tszFileName)
	{
		if(tszFileName == NULL) return false;

		std::ifstream stream;

		stream.open( tszFileName, std::ios::in | std::ios::binary );

		stream.seekg( 0, std::ios::end );
		size_t lFileSize = (size_t)stream.tellg();
		stream.seekg( 0, std::ios::beg );

		static const size_t lMaxBuf = 8000;

		UINT_8 vData[lMaxBuf];

		size_t lRemaining = lFileSize;

		while( lRemaining > 0 )
		{
			const size_t uMaxRead = static_cast<size_t>((lRemaining > lMaxBuf) ? lMaxBuf : lRemaining);

			stream.read( (char*)vData, uMaxRead );

			Update(vData, static_cast<UINT_32>(uMaxRead));

			lRemaining -= static_cast<INT_64>(uMaxRead);
		}

		stream.close();

		return (lRemaining == 0);
	}
#endif

	// Finalize hash, call before using ReportHash(Stl)
	void sha1::Final()
	{
		if( final_ )
			return;

		UINT_32 i;

		UINT_8 finalcount[8];
		for(i = 0; i < 8; ++i)
			finalcount[i] = (UINT_8)((m_count[((i >= 4) ? 0 : 1)]
		>> ((3 - (i & 3)) * 8) ) & 255); // Endian independent

		Update((UINT_8*)"\200", 1);

		while ((m_count[0] & 504) != 448)
			Update((UINT_8*)"\0", 1);

		Update(finalcount, 8); // Cause a SHA1Transform()

		for(i = 0; i < 20; ++i)
			m_digest[i] = (UINT_8)((m_state[i >> 2] >> ((3 - (i & 3)) * 8)) & 0xFF);

		// Wipe variables for security reasons
#ifdef SHA1_WIPE_VARIABLES
		memset(m_buffer, 0, 64);
		memset(m_state, 0, 20);
		memset(m_count, 0, 8);
		memset(finalcount, 0, 8);
		Transform(m_state, m_buffer);
#endif

		final_ = true;
	}

#ifdef SHA1_UTILITY_FUNCTIONS
	bool sha1::ReportHash(TCHAR* tszReport, size_t len, REPORT_TYPE rtReportType) const
	{
		if(tszReport == NULL) return false;

		TCHAR tszTemp[16];

		if((rtReportType == REPORT_HEX) || (rtReportType == REPORT_HEX_SHORT))
		{
			_sntprintf_s(tszTemp, 15, _T("%02x"), m_digest[0]);
			_tcscpy_s(tszReport, len, tszTemp);

			const TCHAR* lpFmt = ((rtReportType == REPORT_HEX) ? _T(" %02x") : _T("%02x"));
			for(size_t i = 1; i < 20; ++i)
			{
				_sntprintf_s(tszTemp, 15, lpFmt, m_digest[i]);
				_tcscat_s(tszReport, len, tszTemp);
			}
		}
		else if(rtReportType == REPORT_DIGIT)
		{
			_sntprintf_s(tszTemp, 15, _T("%u"), m_digest[0]);
			_tcscpy_s(tszReport, len, tszTemp);

			for(size_t i = 1; i < 20; ++i)
			{
				_sntprintf_s(tszTemp, 15, _T(" %u"), m_digest[i]);
				_tcscat_s(tszReport, len, tszTemp);
			}
		}
		else return false;

		return true;
	}
#endif

#ifdef SHA1_STL_FUNCTIONS
	bool sha1::ReportHashStl(std::basic_string<TCHAR>& strOut, REPORT_TYPE rtReportType) const
	{
		TCHAR tszOut[84] = {0};
		const bool bResult = ReportHash(tszOut, sizeof(tszOut) / sizeof(TCHAR), rtReportType);
		if(bResult) strOut = tszOut;
		return bResult;
	}
#endif

	bool sha1::GetHash(UINT_8* pbDest) const
	{
		if(pbDest == NULL) return false;
		memcpy(pbDest, m_digest, 20);
		return true;
	}

	// Private SHA-1 transformation
	void sha1::Transform(UINT_32* pState, const UINT_8* pBuffer)
	{
		UINT_32 a = pState[0], b = pState[1], c = pState[2], d = pState[3], e = pState[4];

		memcpy_s(m_block, sizeof(m_workspace), pBuffer, 64);

		// 4 rounds of 20 operations each. Loop unrolled.
		_R0(a,b,c,d,e, 0); _R0(e,a,b,c,d, 1); _R0(d,e,a,b,c, 2); _R0(c,d,e,a,b, 3);
		_R0(b,c,d,e,a, 4); _R0(a,b,c,d,e, 5); _R0(e,a,b,c,d, 6); _R0(d,e,a,b,c, 7);
		_R0(c,d,e,a,b, 8); _R0(b,c,d,e,a, 9); _R0(a,b,c,d,e,10); _R0(e,a,b,c,d,11);
		_R0(d,e,a,b,c,12); _R0(c,d,e,a,b,13); _R0(b,c,d,e,a,14); _R0(a,b,c,d,e,15);
		_R1(e,a,b,c,d,16); _R1(d,e,a,b,c,17); _R1(c,d,e,a,b,18); _R1(b,c,d,e,a,19);
		_R2(a,b,c,d,e,20); _R2(e,a,b,c,d,21); _R2(d,e,a,b,c,22); _R2(c,d,e,a,b,23);
		_R2(b,c,d,e,a,24); _R2(a,b,c,d,e,25); _R2(e,a,b,c,d,26); _R2(d,e,a,b,c,27);
		_R2(c,d,e,a,b,28); _R2(b,c,d,e,a,29); _R2(a,b,c,d,e,30); _R2(e,a,b,c,d,31);
		_R2(d,e,a,b,c,32); _R2(c,d,e,a,b,33); _R2(b,c,d,e,a,34); _R2(a,b,c,d,e,35);
		_R2(e,a,b,c,d,36); _R2(d,e,a,b,c,37); _R2(c,d,e,a,b,38); _R2(b,c,d,e,a,39);
		_R3(a,b,c,d,e,40); _R3(e,a,b,c,d,41); _R3(d,e,a,b,c,42); _R3(c,d,e,a,b,43);
		_R3(b,c,d,e,a,44); _R3(a,b,c,d,e,45); _R3(e,a,b,c,d,46); _R3(d,e,a,b,c,47);
		_R3(c,d,e,a,b,48); _R3(b,c,d,e,a,49); _R3(a,b,c,d,e,50); _R3(e,a,b,c,d,51);
		_R3(d,e,a,b,c,52); _R3(c,d,e,a,b,53); _R3(b,c,d,e,a,54); _R3(a,b,c,d,e,55);
		_R3(e,a,b,c,d,56); _R3(d,e,a,b,c,57); _R3(c,d,e,a,b,58); _R3(b,c,d,e,a,59);
		_R4(a,b,c,d,e,60); _R4(e,a,b,c,d,61); _R4(d,e,a,b,c,62); _R4(c,d,e,a,b,63);
		_R4(b,c,d,e,a,64); _R4(a,b,c,d,e,65); _R4(e,a,b,c,d,66); _R4(d,e,a,b,c,67);
		_R4(c,d,e,a,b,68); _R4(b,c,d,e,a,69); _R4(a,b,c,d,e,70); _R4(e,a,b,c,d,71);
		_R4(d,e,a,b,c,72); _R4(c,d,e,a,b,73); _R4(b,c,d,e,a,74); _R4(a,b,c,d,e,75);
		_R4(e,a,b,c,d,76); _R4(d,e,a,b,c,77); _R4(c,d,e,a,b,78); _R4(b,c,d,e,a,79);

		// Add the working vars back into state
		pState[0] += a;
		pState[1] += b;
		pState[2] += c;
		pState[3] += d;
		pState[4] += e;

		// Wipe variables
#ifdef SHA1_WIPE_VARIABLES
		a = b = c = d = e = 0;
#endif
	}

}

#undef _R0
#undef _R1
#undef _R2
#undef _R3
#undef _R4