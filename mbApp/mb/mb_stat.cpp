#include <iostream>
#include <fstream>
#include "mb.h"
#include <cstring>

MB_DECLARE(e, 64000);
// TODO set via cmd line options
std::size_t skipFirstNSamples = 0;

// TODO command line options
int main(int argc, char** argv)
{
    // norm hack
    bool normalizeOnly = false;
    if (argc == 3 && strcmp(argv[2],"-n")==0)
    {
        argc = 2;
        normalizeOnly = true;
    }

    
    if (argc != 2)
    {
        std::cerr << "usage: " << argv[0] << " <mb CSV file>" << std::endl;
        return -1;
    }
    
    char * fileName = argv[1];
    
    std::ifstream in(fileName);
    if (in.is_open())
    {
        MB_CSV_IMPORT(e, in);
        in.close();

        if (normalizeOnly)
        {
            MB_NORMALIZE(e);
            MB_PRINT(e, std::cout);
        }
        else
            MB_STATS(e, skipFirstNSamples, std::cout);
    }
    else
    {
        std::cerr << "failed to open a file " << fileName << ", skipping..." << std::endl;
        return -1;
    }
    
    return 0;
}

