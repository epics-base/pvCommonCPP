#include <string>
#include <iostream>

#ifdef vxWorks
#  include <boost/tr1/memory.hpp>
#else
#  include <tr1/memory>
#endif

#include <testMain.h>

MAIN(testShared)
{
    std::tr1::shared_ptr<double> spd(new double);
    *spd = 1.23456789;

    std::cout << "Apparently it works..." << std::endl;

    return 0;
}
