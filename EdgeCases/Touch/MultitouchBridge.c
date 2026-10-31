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
} mt;

static CFArrayRef devices;
static MTFrameCallback registered;

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
    if (!mt.createList || !mt.isBuiltIn || !mt.registerCallback || !mt.unregisterCallback || !mt.start || !mt.stop) {
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
