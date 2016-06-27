#ifndef FFMPEG_VIDEO_DECODER_H
#define FFMPEG_VIDEO_DECODER_H






extern "C"
{
#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h" 
#include "libswscale/swscale.h"
};

class CFFMPEGH264Decoder
{
public:
	CFFMPEGH264Decoder(int nDataType);
	virtual ~CFFMPEGH264Decoder();
	
	static int Init();
	static int DeInit();
	static AVCodec *m_pcodec;
    static int YUV2RGB(unsigned char *yuv, unsigned char*rgb, int width, int height);
    
public:
	int Start();
	int GetResultWidth();
	int GetResultHeight();
	int GetResultType();
	unsigned char* GetResultData();
	int ReleaseResultData();
	int Decode(char* data, int length);
	int End();
	int GetType();
	int m_nWidth;
	int m_nHeight;
    int setLightnessOffset(char offset);
private:
	int m_nDataType;
	unsigned char* m_pBuffer;
	unsigned char* m_pBMP;
	int m_IsResultValid;
	AVPacket* m_packet;	
	AVCodecContext *m_context; // Codec Context
	AVFrame *m_picture; // Frame
    char m_offset;
	

};

#endif
