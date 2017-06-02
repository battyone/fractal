#include "afa.h"
//+-----------------------------------------------------------------------------------------+
//| This formulation was first formulated in                                                |
//|                                                                                         |
//| J.B. Gao, J. Hu, W.W. Tung, Facilitating joint chaos and fractal analysis of biosignals |
//| through nonlinear adaptive filtering.  PLoS ONE PLoS ONE 6(9): e24331.                  |
//| doi:10.1371/journal.pone.0024331                                                        |
//+-----------------------------------------------------------------------------------------+

EXPORT CAfa * __stdcall Create(	const unsigned int length,	 const unsigned int order)
{
	return new CAfa(length, 1u, order);
}

EXPORT void __stdcall Destroy(CAfa * instance)
{
	delete instance;
}

EXPORT int __stdcall Push(CAfa * instance, const int x, const double y, const time_t t0, const time_t t1)
{
	return instance->push(x, y, t0, t1);
}

EXPORT double __stdcall Calculate(CAfa * instance)
{
	return instance->calculate();
}

CAfa::CAfa(const unsigned int length,const double step,const unsigned int order) :
	m_length(validate_length(length)),
	m_step(validate_step(step)),
	m_order(validate_order(order)),
	m_series(CSeries(m_length + 1))
{
	// �E�C���h�E�T�C�Y�̏�����
	int imax = int(std::round(std::log2(m_length)));
	int sz = int((imax - 2) / step) + 1;
	for (double m = 2; m < imax; m += m_step)
		{
		unsigned int w = int(round(pow(2, m) + 1));
		if ((w % 2) == 0) w += 1u;
		// �Z�O�����g�̒ǉ�
		m_segments.emplace_back(unsigned int((w-1)*0.5));
		// �g�����h�t�B���^�̒ǉ�
		m_filters.emplace_back(w, m_order);
	}
	// �L���b�V���̏�����
	for (auto it = m_segments.begin(); it != m_segments.end(); it++)
	{
		
		m_cache.insert(std::make_pair(*it, CCache(*it, m_length)));

	}
}


int CAfa::push(const int x, const double y, const time_t t0, const time_t t1)
{
	int result = 0;
	try
	{
		result = m_series.push(x, y, t0, t1);

	}
	catch (...)
	{
		return -9999;
	}
    // �V�K�o�[�̈ȊO�͉������Ȃ��B
	if (!m_series.is_adding())return -1;
    // �X�P�[�������[�v
	std::deque<double> series = m_series.get_series();
	for (unsigned int i = 0; i < m_segments.size(); i++)
	{
		unsigned int step = m_segments[i];	// �n�[�t�T�C�Y
		unsigned int w = step * 2 + 1;		// �E�C���h�E�T�C�Y
		unsigned int len = step * 3 + 1;	// �E�C���h�E�T�C�Y�{�n�[�t�T�C�Y
		unsigned int sz = series.size();
		
		if (sz - 1 < len) continue;	//�T�C�Y������Ȃ��ꍇ�X�L�b�v
		// �v�Z�Ɏg�p����f�[�^�� deque ���� vector �ɃR�s�[
		int offset = sz - len - 1;
		std::vector<double> data;
		std::copy(series.cbegin() + offset, series.cend() - 1, std::back_inserter(data));
		std::vector <double> trend;
		double v1 = 0.0;
		double v2 = 0.0;
		// �������t�B�b�g
		if (m_filters[i].fit(data, trend)) {
			// �c����Βl�a�����߂�B
			volatility(data, trend, step, v1, v2);
		}

		// �L���b�V���ɒǉ�
		m_cache[step].set(x - step, v1);
		m_cache[step].set(x, v2);
		
	}
	return result;

}

double CAfa::calculate()
{
	// �����̈�O�̃C���f�b�N�X
	int x = m_series.prev_x();
	if (x == -1) return -1.0;
	// �X�P�[�����O�w�������߂�B
	std::vector<Stats> fq;
	for (unsigned int i = 0; i < m_segments.size(); i++)
	{
		unsigned int step = m_segments[i];
		unsigned int w = step * 2 + 1;
		// �c����Βl�a�̕��ς����߂�B
		double v = m_cache[step].calc_fractal(x);
		fq.emplace_back(1, log2(w), log2(v));
	}
	// �X���[�v�����߂�B
	Stats stat = std::accumulate(fq.begin(), fq.end(), Stats());
	double slope = stat.slope();
	return (isnan(slope)) ? -1.0 : slope;
}
void CAfa::volatility(std::vector<double> &y, std::vector<double> &y_hat, const unsigned int step, double &v1,double &v2)
{
	unsigned int sz = step*2;
	unsigned int from_y = y.size() - sz;
	unsigned int from_y_hat = y_hat.size() - sz;

	v1 = 0.0;
	for (unsigned int i = 0; i < step; i++)
	{
		v1 += abs(y[from_y + i] - y_hat[from_y_hat + i]);
	}
//	std::cout << "1 v1:" <<v1 << std::endl;

	v2 = 0.0;
	for (unsigned int i = step; i < sz; i++)
	{
		v2 += abs(y[from_y + i] - y_hat[from_y_hat + i]);
	}
//	std::cout << "2 v2:" << v2 << std::endl;

}

bool CAfa::get_results(const unsigned int idx, double &y)
{
	if (m_results.size() <= idx) return false;
	y = m_results[idx];
	return true;
}


unsigned int CAfa::validate_length(const unsigned int len)
{
	unsigned int l = int(pow(2, int(log2(len))));
	return std::max(16u, std::min(1024u, l));
}

double CAfa::validate_step(const double step)
{
	double tmp = int(step * 2.0)*0.5;
	return std::min(2.0, std::max(0.5, tmp));
}
unsigned int  CAfa::validate_order(const unsigned int order)
{
	return 1u;
}


