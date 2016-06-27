#include "FFMPEGH264Decoder.h"

#include "assert.h"

AVCodec *CFFMPEGH264Decoder::m_pcodec = NULL;

CFFMPEGH264Decoder::CFFMPEGH264Decoder(int nDataType)
{
	m_nDataType = nDataType;
	m_pBMP = NULL;
	m_packet = NULL;
	m_picture = NULL;
	m_context = NULL;
	m_pBuffer = NULL;
}
CFFMPEGH264Decoder::~CFFMPEGH264Decoder()
{



}
int CFFMPEGH264Decoder::Init()
{
	//初始化解码库
    
    
	avcodec_register_all();
	av_register_all();
	m_pcodec = avcodec_find_decoder(CODEC_ID_H264);
    
	if (m_pcodec != NULL) 
	{
		return 1; 
	} 
	
	return 0;
}
int CFFMPEGH264Decoder::DeInit()
{
	m_pcodec = NULL;
	return 0;
}
int CFFMPEGH264Decoder::Start()
{
	m_IsResultValid = 0;
	m_nWidth = 0;
	m_nHeight = 0;

	m_packet = new AVPacket; 
	av_init_packet(m_packet);
	
	//allocate codec context
	m_context = avcodec_alloc_context3(m_pcodec);
	if(m_context == NULL)
	{
		assert(false);
		return 1;
	}
	//open codec
	if (avcodec_open2(m_context, m_pcodec, NULL) < 0) 
	{
		assert(false);
		return 1; 
	} 

	//allocate frame buffer
	//m_picture = avcodec_alloc_frame();
    m_picture = av_frame_alloc();
	if(m_picture == NULL)
	{
		assert(false);
		return 1;
	}

	
	return 0;
}
int CFFMPEGH264Decoder::End()
{
	if(m_picture != NULL)
	{
		av_free(m_picture);
		m_picture = NULL;
	}

	if(m_context != NULL)
	{
		avcodec_flush_buffers(m_context);
		avcodec_close(m_context); 
		av_free(m_context);
		m_context = NULL;
	} 
	
	if(m_pBuffer != NULL)
	{
		delete[] m_pBuffer;
		m_pBuffer = NULL;
	}

	if(m_pBMP != NULL)
	{
		delete[] m_pBMP;
		m_pBMP = NULL;
	}

	if(m_packet != NULL)
	{
		av_free_packet(m_packet); 
		delete[] m_packet;
		m_packet = NULL;
	}

	return 0;
}
int CFFMPEGH264Decoder::GetResultWidth()
{

	return m_nWidth;
}

int CFFMPEGH264Decoder::GetResultHeight()
{

	return m_nHeight;
}

unsigned char* CFFMPEGH264Decoder::GetResultData()
{
	if(!m_IsResultValid)
	{
		return 0;
	}

	if(m_nDataType == 1)
	{        
		return m_pBMP;
	}

	return m_pBuffer;
}

int CFFMPEGH264Decoder::ReleaseResultData()
{
	m_IsResultValid = 0;
	return 0;
}

int CFFMPEGH264Decoder::Decode(char* data, int length)
{
	assert(m_IsResultValid == 0);
	if(m_context == NULL || m_picture == NULL)
	{
		return 1;
	}
	m_packet->data = (unsigned char*)data;
	m_packet->size = length;
	int nGotPicture = 0;
	int nBytesConsumed = avcodec_decode_video2(m_context, m_picture, &nGotPicture, (const AVPacket*)m_packet);
	if(nBytesConsumed <= 0 || m_picture->data[0] == 0)
	{
		
		return 0;
	}

	int size = m_context->width * m_context->height;
	
	if(m_pBuffer == NULL)
	{
		m_pBuffer = new unsigned char[size * 3 / 2];
		if(m_nDataType == 1)
		{
			int nNewLen = size * 4;
			m_pBMP = new unsigned char[nNewLen];
		}
	}
	else
	{
		int sizeOld = m_nWidth * m_nHeight;
		if(size != sizeOld)
		{
			
			delete[] m_pBuffer;
			if(m_pBMP != NULL)
			{
				delete[] m_pBMP;
				m_pBMP = NULL;
			}
			if(m_nDataType == 1)
			{
				int nNewLen = m_nWidth * m_nHeight * 4;
				m_pBMP = new unsigned char[nNewLen];
			}
			m_pBuffer = new unsigned char[size * 3 / 2];
		}

	}
	unsigned char* pY = (unsigned char *)m_pBuffer;
	unsigned char* pU = (unsigned char *)(m_pBuffer + size);
	unsigned char* pV = (unsigned char *)(m_pBuffer + size * 5 / 4);

	int i = 0;
	int p = 0; 

	//拷贝Y分量
	for(p = 0, i = 0; i < m_context->height; i++)
	{
		memcpy(pY + p ,
			m_picture->data[0] + i * m_picture->linesize[0], 
			m_context->width);
			p += m_context->width;
	}

	//拷贝U分量
	for(p = 0, i = 0; i < m_context->height / 2; i++)
	{
		memcpy(pU + p,
			m_picture->data[1] + i * m_picture->linesize[1], 
			m_context->width / 2);
			p += m_context->width / 2;
	}

	//拷贝V分量
	for(p = 0, i = 0; i < m_context->height / 2; i++)
	{
		memcpy(pV  + p,
			m_picture->data[2] + i * m_picture->linesize[2], 
			m_context->width / 2);
			p += m_context->width / 2;
	}

	//保存图像长宽
	m_nWidth = m_context->width;
	m_nHeight = m_context->height;
    for (int i = 0; i < m_nHeight; i++) {
        for (int j = 0; j < m_nWidth; j++) {
            int value = pY[i * m_nWidth + j] + m_offset;
            if (value < 0 ) {
                pY[i * m_nWidth + j] = 0;
            }else if(value > 255){
                pY[i * m_nWidth + j] = 255;
            }else{
                pY[i * m_nWidth + j] = (char)value;
            }
        }
    }

	if(m_nDataType == 1)
	{
		assert(m_pBMP != NULL);
		//m_YUV.ConvertYUVtoRGB(pY, pU, pV, m_pBMP, m_nWidth, m_nHeight);
        for (int i = 0; i < m_nHeight; i++) {
            for (int j = 0; j < m_nWidth; j++) {
                int value = pY[i * m_nWidth + j] + m_offset;
                if (value < 0 ) {
                    pY[i * m_nWidth + j] = 0;
                }else if(value > 255){
                    pY[i * m_nWidth + j] = 255;
                }else{
                    pY[i * m_nWidth + j] = (char)value;
                }
            }
        }
        
       // yv12_to_rgb24_c(m_pBMP, m_nWidth , pY, pV, pU, m_nWidth, m_nWidth / 2, m_nWidth, m_nHeight);
        
        
        
	}
	m_IsResultValid = 1;

	return 0;
}




int CFFMPEGH264Decoder ::setLightnessOffset(char offset){
    m_offset = offset;
    return 0;

}

int CFFMPEGH264Decoder::GetType()
{

	return 0;//ffmpeg默认为0
}

int CFFMPEGH264Decoder::GetResultType()
{

	return m_nDataType;
}

