```js
emcc encrypt.c \
  -O3 \
  -s WASM=1 \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s EXPORTED_FUNCTIONS='["_check_input"]' \
  -s EXPORTED_RUNTIME_METHODS='["cwrap","ccall"]' \
  -o index.js
```
