#include "MultitouchBridge.h"
#include <CoreFoundation/CoreFoundation.h>
#include <dlfcn.h>

static struct {
    CFArrayRef (*createList)(void);
    bool (*isBuiltIn)(MTDeviceRef);
    void (*registerCallback)(MTDeviceRef, MTFrameCallback);
    void (*unregisterCallback)(MTDeviceRef, MTFrameCallback);
    int32_t (*start)(MTDeviceRef, int32_t);
    void (*stop)(MTDeviceRef);
    int32_t (*getDeviceID)(MTDeviceRef, uint64_t *);
    CFTypeRef (*actuatorCreate)(uint64_t);
    int32_t (*actuatorOpen)(CFTypeRef);
    int32_t (*actuatorClose)(CFTypeRef);
    int32_t (*actuatorActuate)(CFTypeRef, int32_t, uint32_t, float, float);
} mt;

static CFArrayRef devices;
static MTFrameCallback registered;
static CFTypeRef actuator;

static bool load(void) {
    static void *handle;
    if (handle) return true;
    void *h = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_NOW);
    if (!h) return false;
    mt.createList = dlsym(h, "MTDeviceCreateList");
    mt.isBuiltIn = dlsym(h, "MTDeviceIsBuiltIn");
    mt.registerCallback = dlsym(h, "MTRegisterContactFrameCallback");
    mt.unregisterCallback = dlsym(h, "MTUnregisterContactFrameCallback");
    mt.start = dlsym(h, "MTDeviceStart");
    mt.stop = dlsym(h, "MTDeviceStop");
    mt.getDeviceID = dlsym(h, "MTDeviceGetDeviceID");
    mt.actuatorCreate = dlsym(h, "MTActuatorCreateFromDeviceID");
    mt.actuatorOpen = dlsym(h, "MTActuatorOpen");
    mt.actuatorClose = dlsym(h, "MTActuatorClose");
    mt.actuatorActuate = dlsym(h, "MTActuatorActuate");
    if (!mt.createList || !mt.isBuiltIn || !mt.registerCallback || !mt.unregisterCallback || !mt.start || !mt.stop
        || !mt.getDeviceID || !mt.actuatorCreate || !mt.actuatorOpen || !mt.actuatorClose || !mt.actuatorActuate) {
        dlclose(h);
        return false;
    }
    handle = h;
    return true;
}

int ECMultitouchStart(MTFrameCallback callback) {
    if (!load()) return -1;
    ECMultitouchStop();
    devices = mt.createList();
    if (!devices) return 0;
    registered = callback;
    int started = 0;
    for (CFIndex i = 0; i < CFArrayGetCount(devices); i++) {
        MTDeviceRef device = (MTDeviceRef)CFArrayGetValueAtIndex(devices, i);
        if (!mt.isBuiltIn(device)) continue;
        mt.registerCallback(device, callback);
        if (mt.start(device, 0) == 0) started++;
    }
    return started;
}

void ECMultitouchStop(void) {
    if (actuator) {
        mt.actuatorClose(actuator);
        CFRelease(actuator);
        actuator = NULL;
    }
    if (!devices) return;
    for (CFIndex i = 0; i < CFArrayGetCount(devices); i++) {
        MTDeviceRef device = (MTDeviceRef)CFArrayGetValueAtIndex(devices, i);
        if (!mt.isBuiltIn(device)) continue;
        mt.unregisterCallback(device, registered);
        mt.stop(device);
    }
    CFRelease(devices);
    devices = NULL;
}

bool ECHapticActuate(int32_t actuationID) {
    if (!actuator) {
        if (!devices) return false;
        for (CFIndex i = 0; i < CFArrayGetCount(devices) && !actuator; i++) {
            MTDeviceRef device = (MTDeviceRef)CFArrayGetValueAtIndex(devices, i);
            uint64_t deviceID = 0;
            if (!mt.isBuiltIn(device) || mt.getDeviceID(device, &deviceID) != 0) continue;
            CFTypeRef candidate = mt.actuatorCreate(deviceID);
            if (!candidate) continue;
            if (mt.actuatorOpen(candidate) == 0) {
                actuator = candidate;
            } else {
                CFRelease(candidate);
            }
        }
        if (!actuator) return false;
    }
    return mt.actuatorActuate(actuator, actuationID, 0, 0, 0) == 0;
}
