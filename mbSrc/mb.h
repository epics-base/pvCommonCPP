#ifndef _MB_H_
#define _MB_H_

#include <shareLib.h>

#ifdef WITH_MICROBENCH

#include <string>
#include <vector>

#ifndef vxWorks
#  include <inttypes.h>
#endif

#include <iostream>

#include <epicsVersion.h>

#include <boost/atomic.hpp>

static class MBMutexInitializer {
  public:
    MBMutexInitializer ();
    ~MBMutexInitializer ();
} mbStaticMutexInitializer; // Note object here in the header.

struct MBPoint
{
    std::ptrdiff_t id;
    uint8_t stage;
    uint64_t time;
    
    MBPoint() {}
    MBPoint(std::ptrdiff_t _id, uint8_t _stage) : id(_id), stage(_stage) {}
};

struct MBEntity;

epicsShareFunc void MBEntityRegister(MBEntity *e);

typedef std::vector<MBPoint> MBPointType;

struct MBEntity
{
    std::string name;
    MBPointType points;
    boost::atomic<std::size_t> pos;
    boost::atomic<std::ptrdiff_t> auto_id;

    MBEntity(const std::string &name_, std::size_t size) : name(name_)
    {
        // init vector at the beginning
        points.resize(size);
        pos.store(0);
        auto_id.store(0);
        
        MBEntityRegister(this);
    }
};

epicsShareFunc uint64_t MBTime();

epicsShareFunc void MBPointAdd(MBEntity &e, std::ptrdiff_t id, uint8_t stage);

epicsShareFunc void MBCSVExport(MBEntity &e, uint8_t stageOnly, std::size_t skipFirstNSamples, std::ostream &o);
epicsShareFunc void MBCSVImport(MBEntity &e, std::istream &i);

epicsShareFunc void MBStats(MBEntity &e, uint8_t stageOnly, std::size_t skipFirstNSamples, std::ostream &o);

epicsShareFunc void MBNormalize(MBEntity &e);


#define MB_NAME(NAME) g_MB_##NAME

#define MB_DECLARE(NAME, SIZE) MBEntity MB_NAME(NAME)(#NAME, SIZE) 
#define MB_DECLARE_EXTERN(NAME) epicsShareFunc MBEntity MB_NAME(NAME)

#define MB_POINT_ID(NAME, STAGE, STAGE_DESC, ID) MBPointAdd(MB_NAME(NAME), ID, STAGE)

#define MB_INC_AUTO_ID(NAME) MB_NAME(NAME).auto_id++
#define MB_POINT(NAME, STAGE, STAGE_DESC) MBPointAdd(MB_NAME(NAME), MB_NAME(NAME).auto_id, STAGE)
#define MB_POINT_CONDITIONAL(NAME, STAGE, STAGE_DESC, COND) if (COND) MBPointAdd(MB_NAME(NAME), MB_NAME(NAME).auto_id, STAGE)

#define MB_NORMALIZE(NAME) MBNormalize(MB_NAME(NAME))

#define MB_STATS(NAME, STREAM) MBStats(MB_NAME(NAME), 0, 0, STREAM)
#define MB_STATS_OPT(NAME, STAGE_ONLY, SKIP_FIRST_N_SAMPLES, STREAM) MBStats(MB_NAME(NAME), STAGE_ONLY, SKIP_FIRST_N_SAMPLES, STREAM)

#define MB_CSV_EXPORT(NAME, STREAM) MBCSVExport(MB_NAME(NAME), 0, 0, STREAM)
#define MB_CSV_EXPORT_OPT(NAME, STAGE_ONLY, SKIP_FIRST_N_SAMPLES, STREAM) MBCSVExport(MB_NAME(NAME), STAGE_ONLY, SKIP_FIRST_N_SAMPLES, STREAM)
#define MB_CSV_IMPORT(NAME, STREAM) MBCSVImport(MB_NAME(NAME), STREAM)

#define MB_PRINT(NAME, STREAM) MB_CSV_EXPORT(NAME, STREAM)
#define MB_PRINT_OPT(NAME, STAGE_ONLY, SKIP_FIRST_N_SAMPLES, STREAM) MB_CSV_EXPORT_OPT(NAME, STAGE_ONLY, SKIP_FIRST_N_SAMPLES, STREAM)

#define MB_INIT MBInit()

#endif // WITH_MICROBENCH

epicsShareFunc void MBInit();

#endif
