import 'dart:js_interop';
@JS('frequency.read') external JSString? _read(JSString key);
@JS('frequency.write') external JSBoolean _write(JSString key, JSString value);
@JS('frequency.navigate') external void _navigate(JSString path);
@JS('frequency.tone') external void _tone(JSNumber kind);
String? readValue(String key) => _read(key.toJS)?.toDart;
bool writeValue(String key, String value) => _write(key.toJS, value.toJS).toDart;
void navigate(String path) => _navigate(path.toJS);
void tone(int kind) => _tone(kind.toJS);

@JS('frequency.watch') external void _watch(JSFunction callback);
@JS('frequency.unwatch') external void _unwatch();
void watchSuspension(void Function() callback) { try { _watch(callback.toJS); } catch (_) {} }
void unwatchSuspension() { try { _unwatch(); } catch (_) {} }
