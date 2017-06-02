#include "trend.h"
//+-----------------------------------------------------------------------------------------+
//| This formulation was first formulated in                                                |
//|                                                                                         |
//| J.B. Gao, J. Hu, W.W. Tung, Facilitating joint chaos and fractal analysis of biosignals |
//| through nonlinear adaptive filtering.  PLoS ONE PLoS ONE 6(9): e24331.                  |
//| doi:10.1371/journal.pone.0024331                                                        |
//+-----------------------------------------------------------------------------------------+
/**
 * �������t�B�b�g 
 * size - �E�C���h�E�T�C�Y
 * order - ����
 * 
 * �E�C���h�E�T�C�Y�͊�ł���A�n�[�t�T�C�Y�͂O�D�T���|���ď�������؂�̂Ă����ɂȂ�B
 * �Ⴆ�΁A�E�C���h�E�T�C�Y���X�̏ꍇ�ł̓n�[�t�T�C�Y�͂S�ɂȂ�B
 * 
 */
CTrend::CTrend( const unsigned int size, const unsigned int order) :
	m_size(to_size(size)),
	m_half(to_half(m_size)),
	m_order(order)
{
	
	m_filter = create_filter();
}


/**
 * �������t�B�b�g���s�Ȃ��B
 * y - ���f�[�^
 * trend - ���ʕԋp�p
 */
bool CTrend::fit(const std::vector<double>& y , std::vector<double>& trend)
{
	// �E�C���h�E�T�C�Y�{�n�[�t�T�C�Y �����Ă͂Ȃ�Ȃ��B
	if (y.size() != m_size + m_half) return false;
	//
	unsigned int step = m_size - 1;
	// std::vector ���� cv::mat�ɕϊ�
	cv::Mat1d data(y);
    // �����ȏ�d�Ȃ�悤�ɗ�����炵���f�[�^�����
	cv::Mat1d data1 = data.rowRange(0, m_size).t();
	cv::Mat1d data2 = data.rowRange(m_half, m_half + m_size).t();
	cv::Mat1d prev_trend = data1 * m_filter;
	cv::Mat1d next_trend = data2 * m_filter;
    // �E�C���h�E�T�C�Y�F�T�A�n�[�t�T�C�Y�F�Q�� [0, 1, 2, 3, 4, 5, 6]�Ƃ����f�[�^������ꍇ�B
	// data1->[0, 1, 2, 3, 4]
	// data2->      [2, 3, 4, 5, 6]
    // �̂悤�ɂȂ�B[2,3,4] �̕������d�Ȃ�̂ŕ��������s�Ȃ��B
	trend = stitch_trend(prev_trend, next_trend);
	data1.release();
	data2.release();
	prev_trend.release();
	next_trend.release();
	data.release();
	return true;
}
/**
 * �X�e�b�`�g�����h
 */
std::vector<double> CTrend::stitch_trend(const cv::Mat1d & trend1, const cv::Mat1d & trend2)
{

	std::vector<double> res;
	res.reserve(m_size-1);
	// stitch
	for (unsigned int i = 1; i <= m_half; i++)
	{
		// �d�Ȃ镔�����������ĕ���������B
		unsigned int xi = m_half + i; 
		double w = double(i) / m_half;
		double v1 = trend1(0, xi) * (1.0 - w);
		double v2 = trend2(0, i) * w;
		res.push_back(v1 + v2);
	}

	// push 
	for (unsigned int i = m_half + 1; i < m_size; i++)
	{
		// ���[�̏d�Ȃ�Ȃ������͂��̂܂܃Z�b�g����B���̉�ŏ����̃f�[�^�ƍ��������B
		res.push_back(trend2(0, i));
	}

	return res;
}


unsigned int CTrend::to_size(const unsigned int sz)
{
	return unsigned int(sz*0.5) * 2 + 1;
}

unsigned int CTrend::to_half(const unsigned int sz)
{

	return unsigned int((sz - 1) * 0.5);
}

cv::Mat1d CTrend::create_filter(void)
{
	int x = -1 * int((m_size - 1)*0.5);

	cv::Mat1d A(m_size, m_order + 1);
	for (unsigned int m = 0; m < m_size; m++)
	{
		for (unsigned int n = 0; n <= m_order; n++)
		{
			A(m, n) = (n == 0) ? 1 : pow(x, n);
		}
		x++;
	}
	return  A * ((A.t() * A).inv() * A.t());
}

