#define MB_KERNEL_ENGINE_DLL
#include "MobileClientKernel.h"
#include "MCKernel.h"

MC_KERNEL_ENGINE IMCKernel *GetMCKernel()
{
	return CMCKernel::GetInstance();
}