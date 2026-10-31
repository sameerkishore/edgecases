// A thin bridge to Apple's private MultitouchSupport framework, loaded at runtime with dlopen.
// The struct layout matches what the framework has delivered since OS X 10.5 (see MiddleClick and
// OpenMultitouchSupport); it isn't documented, so check it first if touches look wrong after an update.
#pragma once
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef struct { float x, y; } MTPoint;
typedef struct { MTPoint position, velocity; } MTVector;

typedef enum : int32_t {
    MTTouchStateNotTracking = 0,
    MTTouchStateStartInRange = 1,
    MTTouchStateHoverInRange = 2,
    MTTouchStateMakeTouch = 3,
    MTTouchStateTouching = 4,
    MTTouchStateBreakTouch = 5,
    MTTouchStateLingerInRange = 6,
    MTTouchStateOutOfRange = 7,
} MTTouchState;

typedef struct {
    int32_t frame;
    double timestamp;
    int32_t identifier;
    MTTouchState state;
    int32_t fingerID;
    int32_t handID;
    MTVector normalized;   // 0…1, origin at the bottom left
    float size;
    int32_t field9;
    float angle;
    float majorAxis;
    float minorAxis;
    MTVector absolute;     // millimetres
    int32_t field14;
    int32_t field15;
    float density;
} MTTouch;

typedef void *MTDeviceRef;
typedef void (*MTFrameCallback)(MTDeviceRef device, const MTTouch *touches, size_t count, double timestamp, size_t frame);

/// Starts delivering frames from the built-in trackpad to `callback`, on the framework's own thread.
/// Returns the number of devices started, or -1 if the framework couldn't be loaded.
int ECMultitouchStart(MTFrameCallback callback);

/// Stops every device started by ECMultitouchStart.
void ECMultitouchStop(void);

/// Plays one of the built-in trackpad's haptic waveforms. Opens the actuator on first use.
/// Returns false if there's no actuator to play it on.
bool ECHapticActuate(int32_t actuationID);
