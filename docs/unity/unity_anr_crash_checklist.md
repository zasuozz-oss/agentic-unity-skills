# Unity ANR & Crash Checklist

## 🔴 Crash — Null Reference & Memory

- [ ] **[CRITICAL]** NullReferenceException không được catch
  - `GetComponent`, `FindObjectOfType` trả về null mà không kiểm tra
- [ ] **[CRITICAL]** Destroy object nhưng vẫn reference sau đó
  - Dùng destroyed object trong callback, coroutine, hoặc event
- [ ] **[CRITICAL]** Out of memory do texture/audio không unload
  - `Resources.Load` mà không gọi `Resources.UnloadUnusedAssets`
- [ ] **[CRITICAL]** Stack overflow do đệ quy vô hạn
  - `Update` gọi function tự gọi lại, hoặc event loop circular
- [ ] **[HIGH]** Array / List index out of range
  - Không check bounds trước khi access element
- [ ] **[HIGH]** Coroutine chạy trên destroyed object
  - Không kiểm tra `object != null` trong yield loop

---

## 🟡 ANR — Main Thread Blocking

- [ ] **[CRITICAL]** Heavy computation trong `Update()`
  - Pathfinding, sorting lớn, JSON parse chạy mỗi frame
- [ ] **[CRITICAL]** Synchronous IO trong main thread
  - `File.ReadAllText`, `PlayerPrefs.Save` gọi trong gameplay
- [ ] **[CRITICAL]** WWW / UnityWebRequest synchronous wait
  - `while (!www.isDone) {}` block main thread
- [ ] **[HIGH]** Physics raycast số lượng lớn mỗi frame
  - Batch raycast hoặc dùng layer mask để giảm tải
- [ ] **[HIGH]** Scene load synchronous (`LoadScene` không Async)
  - Dùng `LoadSceneAsync` + loading screen thay thế
- [ ] **[HIGH]** Instantiate số lượng lớn trong một frame
  - Dùng Object Pooling, chia nhỏ qua nhiều frame

---

## 🔵 Memory Leak & GC Spike

- [ ] **[CRITICAL]** Event/delegate không unsubscribe `OnDestroy`
  - `event += handler` mà thiếu `event -= handler` khi object bị hủy
- [ ] **[CRITICAL]** Static list/dictionary giữ reference object
  - Object bị `Destroy` nhưng vẫn còn trong static collection
- [ ] **[HIGH]** `new object()` trong `Update()` mỗi frame
  - `new Vector3`, `new List`, `new WaitForSeconds` tạo GC pressure
- [ ] **[HIGH]** String concatenation trong `Update()`
  - Dùng `StringBuilder` hoặc `string.Format` thay thế
- [ ] **[HIGH]** Coroutine `yield return new WaitForSeconds()` trong loop
  - Cache `WaitForSeconds` vào biến, dùng lại
- [ ] **[MEDIUM]** `Texture2D` không được Dispose sau khi dùng
  - Gọi `Destroy(texture)` đúng lifecycle

---

## 🟢 Performance — Frame Drop

- [ ] **[HIGH]** `Find`/`FindObjectOfType` gọi trong `Update()`
  - Cache kết quả vào biến trong `Start()` hoặc `Awake()`
- [ ] **[HIGH]** `GetComponent()` lặp lại không cache
  - Gán vào private field trong `Awake()`
- [ ] **[HIGH]** `Camera.main` gọi trong `Update()`
  - `Camera.main` là `FindObjectOfType` — cache vào biến
- [ ] **[HIGH]** `SendMessage` / `BroadcastMessage` thay vì direct call
  - Dùng interface, UnityEvent, hoặc direct reference
- [ ] **[MEDIUM]** Overdraw cao — quá nhiều transparent layer
  - Kiểm tra Overdraw mode trong Scene view
- [ ] **[MEDIUM]** Draw call không được batching
  - Enable GPU Instancing, Static Batching cho object tĩnh

---

## 🟣 Lifecycle & Singleton Issues

- [ ] **[CRITICAL]** Singleton không check `DontDestroyOnLoad` đúng cách
  - Tạo duplicate instance khi reload scene
- [ ] **[HIGH]** `Awake()` phụ thuộc thứ tự khởi tạo giữa các object
  - Dùng Script Execution Order hoặc lazy initialization
- [ ] **[HIGH]** `OnDisable` không dọn dẹp coroutine và timer
  - `StopAllCoroutines()` trong `OnDisable` nếu script bị disable
- [ ] **[HIGH]** `Application.Quit` không cleanup đúng
  - Lưu data trong `OnApplicationPause` thay vì chỉ `OnApplicationQuit`
- [ ] **[MEDIUM]** Thread không được abort khi application quit
  - Dùng `CancellationToken`, tránh `Thread.Abort()`
