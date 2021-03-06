#ifndef NATIVE_EXTENSION_GRAB_H
#define NATIVE_EXTENSION_GRAB_H

#include <nan.h>

using namespace v8;

class MacNotification : public Nan::ObjectWrap {
  public:
    static NAN_MODULE_INIT(Init);

  private:
    explicit MacNotification(Nan::Utf8String *id,
      Nan::Utf8String *title,
      Nan::Utf8String *body,
      Nan::Utf8String *icon,
      Nan::Utf8String *soundName,
      bool canReply);
    ~MacNotification();
    
    static Nan::Utf8String* StringFromObjectOrNull(Local<Object> object, const char *key);
    static void RegisterDelegateFromOptions(Local<Object> options);

    static NAN_METHOD(New);
    static NAN_METHOD(Close);
    static NAN_GETTER(GetId);
    static NAN_GETTER(GetTitle);
    static NAN_GETTER(GetBody);
    static NAN_GETTER(GetIcon);
    static NAN_GETTER(GetSoundName);
    static NAN_GETTER(GetCanReply);
    static NAN_GETTER(GetBundleId);
    
    static Nan::Persistent<Function> constructor;

    Nan::Utf8String *_id, *_title, *_body, *_icon, *_soundName;
    bool _canReply;
};

#endif
