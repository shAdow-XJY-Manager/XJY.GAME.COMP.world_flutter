final Map<String, String> _memory = {};
String? readValue(String key) => _memory[key];
bool writeValue(String key, String value) { _memory[key] = value; return true; }
void navigate(String path) {}
void tone(int kind) {}

void watchSuspension(void Function() callback) {}
void unwatchSuspension() {}
