#include "notification_center_delegate.h"

static NSMutableDictionary<NSString*, NotificationCenterDelegate*>* delegateTable = nil;

@implementation NotificationCenterDelegate

uv_loop_t *defaultLoop = uv_default_loop();
uv_async_t async;

/**
 * This handler runs in the V8 context as a result of `uv_async_send`. Here we
 * retrieve our event information and invoke the saved callback.
 */
static void AsyncSendHandler(uv_async_t *handle) {
  Nan::HandleScope scope;
  NotificationActivationInfo *info = static_cast<NotificationActivationInfo *>(handle->data);

  v8::Local<v8::Value> argv[2] = {
    Nan::New(info->isReply),
    Nan::New(info->response).ToLocalChecked()
  };

  NSLog(@"AsyncSendHandler: %s", [info->id cStringUsingEncoding:NSASCIIStringEncoding]);

  info->callback->Call(2, argv);
}

/**
 * We save off the JavaScript callback here and initialize the libuv event
 * loop, which is needed in order to invoke the callback.
 */
- (id)initWithActivationCallback:(Nan::Callback *)onActivation andId:(NSString *)id
{
  if (!delegateTable) {
    delegateTable = [NSMutableDictionary dictionaryWithCapacity: 1];
  }

  if (self = [super init]) {
    OnActivation = onActivation;
    Id = id;
    uv_async_init(defaultLoop, &async, (uv_async_cb)AsyncSendHandler);
    [delegateTable setObject: self forKey: Id];
    NSLog(@"initWithActivationCallback: %s", [id cStringUsingEncoding:NSASCIIStringEncoding]);
  }

  return self;
}

/**
 * Occurs when the user activates a notification by clicking it or replying.
 */
- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification
{
  Info.isReply = notification.activationType == NSUserNotificationActivationTypeReplied;
  Info.callback = OnActivation;
  Info.id = notification.identifier;

  if (Info.isReply) {
    Info.response = strdup(notification.response.string.UTF8String);
  } else {
    Info.response = "";
  }

  // Stash a pointer to the activation information and push it onto the libuv
  // event loop. Note that the info must be class-local otherwise it'll be
  // garbage collected before the event is handled.
  async.data = &Info;
  uv_async_send(&async);
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
  return YES;
}

@end


@implementation NotificationCenterDispatchDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification {
  NSLog(@"shouldPresentNotification: %s", [notification.identifier cStringUsingEncoding:NSASCIIStringEncoding]);
  NotificationCenterDelegate* d = [delegateTable objectForKey: notification.identifier];

  if (!d) {
    return NO;
  }

  return [d userNotificationCenter: center shouldPresentNotification: notification];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification {
  NSLog(@"didActivateNotification: %s", [notification.identifier cStringUsingEncoding:NSASCIIStringEncoding]);

  NotificationCenterDelegate* d = [delegateTable objectForKey: notification.identifier];

  if (!d) {
    return;
  }

  [[delegateTable objectForKey: notification.identifier] userNotificationCenter: center didActivateNotification: notification];
  [delegateTable removeObjectForKey: notification.identifier];
}

@end
