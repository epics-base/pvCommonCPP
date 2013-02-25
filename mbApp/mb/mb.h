#ifndef _MB_H_
#define _MB_H_

#include <string>
#include <vector>
#include <stdint.h>

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
    intptr_t id;
    uint8_t stage;
    uint64_t time;
    
    MBPoint() {}
    MBPoint(intptr_t _id, uint8_t _stage) : id(_id), stage(_stage) {}
};

struct MBEntity;

extern void MBEntityRegister(MBEntity *e);

typedef std::vector<MBPoint> MBPointType;

struct MBEntity
{
    std::string name;
    MBPointType points;
    boost::atomic<std::size_t> pos;
    boost::atomic<intptr_t> auto_id;

    MBEntity(const std::string &name_, std::size_t size) : name(name_)
    {
        // init vector at the beginning
        points.resize(size);
        pos.store(0);
        auto_id.store(0);
        
        MBEntityRegister(this);
    }
};

extern uint64_t MBTime();

extern void MBPointAdd(MBEntity &e, intptr_t id, uint8_t stage);

extern void MBCSVExport(MBEntity &e, std::ostream &o);
extern void MBCSVImport(MBEntity &e, std::istream &i);

extern void MBStats(MBEntity &e, std::ostream &o);

extern void MBNormalize(MBEntity &e);


extern void MBInit();

#if PV_MB

#define MB_NAME(NAME) g_MB_##NAME

#define MB_DECLARE(NAME, SIZE) MBEntity MB_NAME(NAME)(#NAME, SIZE) 
#define MB_DECLARE_EXTERN(NAME) extern MBEntity MB_NAME(NAME)

#define MB_POINT_ID(NAME, ID, STAGE) MBPointAdd(MB_NAME(NAME), ID, STAGE)

#define MB_INC_AUTO_ID(NAME) ATOMIC_GET_AND_INCREMENT(MB_NAME(NAME).auto_id)
#define MB_POINT(NAME, STAGE) MBPointAdd(MB_NAME(NAME), MB_NAME(NAME).auto_id, STAGE)
#define MB_POINT_CONDITIONAL(NAME, STAGE, COND) if (COND) MBPointAdd(MB_NAME(NAME), MB_NAME(NAME).auto_id, STAGE)

#define MB_NORMALIZE(NAME) MBNormalize(MB_NAME(NAME))

#define MB_STATS(NAME, STREAM) MBStats(MB_NAME(NAME), STREAM)

#define MB_CSV_EXPORT(NAME, STREAM) MBCSVExport(MB_NAME(NAME), STREAM)
#define MB_CSV_IMPORT(NAME, STREAM) MBCSVImport(MB_NAME(NAME), STREAM)

#define MB_PRINT(NAME, STREAM) MB_CSV_EXPORT(NAME, STREAM)

#define MB_INIT MBInit()


#else

#define MB_DECLARE(NAME, SIZE) 
#define MB_DECLARE_EXTERN(NAME)

#define MB_POINT_ID(NAME, ID, STAGE)

#define MB_INC_AUTO_ID(NAME)
#define MB_POINT(NAME, STAGE)

#define MB_POINT_CONDITIONAL(NAME, STAGE, COND)

#define MB_NORMALIZE(NAME)

#define MB_STATS(NAME, STREAM)

#define MB_CSV_EXPORT(NAME, STREAM)
#define MB_CSV_IMPORT(NAME, STREAM)

#define MB_PRINT(NAME, STREAM)

#define MB_INIT

#endif

#endif
