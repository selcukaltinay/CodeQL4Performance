# 📊 Performans Metrikleri ve CodeQL Analizi

Bu doküman, Java uygulamalarında performans sorunlarını tespit etmek için CodeQL sorgularını ve metrikleri açıklar.

---

## 🎯 Tespit Edilen Performans Sorunları

### 1. Uzun Süren Runnable'lar 🔴

**Sorgu:** [HeavyRunnableDetection.ql](.codeql/queries/HeavyRunnableDetection.ql)

**Tespit Edilen Sorunlar:**

#### a) Nested Loops (O(n³) veya daha kötü)
```java
// ❌ KÖTÜ - ~1 milyar iterasyon
public Runnable heavyTask = new Runnable() {
    public void run() {
        for (int i = 0; i < 1000; i++) {
            for (int j = 0; j < 1000; j++) {
                for (int k = 0; k < 1000; k++) {
                    int result = i * j * k;
                }
            }
        }
    }
};
```

**Metrikler:**
- **Complexity:** O(n³) = 1,000,000,000 iterasyon
- **Tahmini Süre:** 10+ saniye (CPU'ya bağlı)
- **Thread Pool Etkisi:** Tüm thread'leri bloke eder

**Çözüm:**
```java
// ✅ İYİ - Algoritmayı optimize et
// Veya paralel hale getir
ExecutorService executor = Executors.newWorkStealingPool();
```

---

#### b) I/O İşlemleri Loop İçinde
```java
// ❌ KÖTÜ - Her iterasyonda dosya açma
public Runnable ioHeavyTask = () -> {
    for (int i = 0; i < 100; i++) {
        BufferedReader reader = new BufferedReader(new FileReader("/tmp/data.txt"));
        String line = reader.readLine();
    }
};
```

**Metrikler:**
- **I/O Calls:** 100 dosya açma işlemi
- **Tahmini Süre:** 1-5 saniye (disk I/O'ya bağlı)
- **Resource Leak:** File descriptors kapatılmıyor

**Çözüm:**
```java
// ✅ İYİ - Loop dışında oku, cache'le
Path path = Paths.get("/tmp/data.txt");
List<String> lines = Files.readAllLines(path);
for (String line : lines) {
    // Process
}
```

---

#### c) Blocking Operations
```java
// ❌ KÖTÜ - Thread sleep in loop
for (int i = 0; i < 100; i++) {
    Thread.sleep(50);  // Toplam 5 saniye!
}
```

**Metrikler:**
- **Blocking Time:** 5000ms
- **Thread Utilization:** %0 (thread bekliyor)

**Çözüm:**
```java
// ✅ İYİ - Async/non-blocking
CompletableFuture.runAsync(() -> {
    // Non-blocking işlem
});
```

---

### 2. Nested Loop Complexity 🟠

**Sorgu:** [NestedLoopComplexity.ql](.codeql/queries/NestedLoopComplexity.ql)

**Tespit Edilen Desenler:**

| Loop Depth | Complexity | 100 eleman için | 1000 eleman için |
|------------|------------|-----------------|------------------|
| 1 seviye | O(n) | 100 | 1,000 |
| 2 seviye | O(n²) | 10,000 | 1,000,000 |
| 3 seviye | O(n³) | 1,000,000 | 1,000,000,000 |
| 4 seviye | O(n⁴) | 100,000,000 | 10¹² (çalışmaz!) |

**Örnek Tespit:**
```java
// Tespit edildi: 3 seviye nested loop
for (int i = 0; i < 1000; i++) {           // 1000x
    for (int j = 0; j < 1000; j++) {       // 1000x
        for (int k = 0; k < 1000; k++) {   // 1000x
            // Toplam: 1,000,000,000 iterasyon!
        }
    }
}
```

**CodeQL Çıktısı:**
```
PERFORMANS UYARISI: 3 seviye iç içe loop tespit edildi.
Algoritma karmaşıklığı: O(n³).
Büyük iterasyon aralığı tespit edildi.
→ Algoritma optimizasyonu gerekli.
```

---

### 3. Pahalı İşlemler Loop İçinde ⚠️

**Sorgu:** [ExpensiveOperationsInLoop.ql](.codeql/queries/ExpensiveOperationsInLoop.ql)

#### a) Reflection in Loop
```java
// ❌ KÖTÜ - Reflection ~100x daha yavaş
for (Object obj : objects) {
    Method m = obj.getClass().getMethod("toString");
    m.invoke(obj);
}
```

**Metrikler:**
- **Overhead:** ~100-1000x normal method call'a göre
- **GC Pressure:** Her getMethod çağrısı object allocation

**Çözüm:**
```java
// ✅ İYİ - Loop dışında reflection
Method m = MyClass.class.getMethod("toString");
for (Object obj : objects) {
    m.invoke(obj);
}
```

---

#### b) Regex Compilation in Loop
```java
// ❌ KÖTÜ - Her iterasyonda regex compile
for (String input : inputs) {
    if (input.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
        emails.add(input);
    }
}
```

**Metrikler:**
- **Compilation Cost:** ~1000 CPU cycles per regex
- **100 item için:** ~100,000 cycles waste

**Çözüm:**
```java
// ✅ İYİ - Compile once
private static final Pattern EMAIL =
    Pattern.compile("^[A-Za-z0-9+_.-]+@(.+)$");

for (String input : inputs) {
    if (EMAIL.matcher(input).matches()) {
        emails.add(input);
    }
}
```

**Performans Kazancı:** ~50-100x

---

#### c) Database Query in Loop (N+1 Problem)
```java
// ❌ KÖTÜ - N+1 query problem
for (Integer userId : userIds) {  // 10 kullanıcı
    List<Order> orders = getOrdersForUser(userId);  // Her biri 1 query
}
// Toplam: 1 + 10 = 11 query
```

**Metrikler:**
- **Query Count:** N+1 (11 query)
- **Network Roundtrips:** 11x
- **Tahmini Süre:** 11 * 50ms = 550ms

**Çözüm:**
```java
// ✅ İYİ - Tek query ile
List<Order> allOrders = getOrdersForUsers(userIds);
// SELECT * FROM orders WHERE user_id IN (1,2,3,...,10)
// Toplam: 1 query, ~50ms
```

**Performans Kazancı:** 11x daha hızlı

---

### 4. Synchronized Heavy Operations 🔴

**Sorgu:** [SynchronizedHeavyOperation.ql](.codeql/queries/SynchronizedHeavyOperation.ql)

```java
// ❌ KÖTÜ - Lock tutarken ağır işlem
public synchronized void heavyMethod() {
    for (int i = 0; i < 1000000; i++) {
        Math.pow(i, 2);
    }
    Thread.sleep(1000);  // 1 saniye lock!
}
```

**Metrikler:**
- **Lock Duration:** ~1 saniye
- **Thread Contention:** Diğer thread'ler bekliyor
- **Throughput:** Sıfır (parallelism yok)

**Çözüm:**
```java
// ✅ İYİ - Minimal lock scope
public void efficientMethod() {
    // Ağır işlem lock dışında
    double[] results = new double[1000000];
    for (int i = 0; i < 1000000; i++) {
        results[i] = Math.pow(i, 2);
    }

    // Sadece shared state güncellerken lock
    synchronized(this) {
        this.results = results;
    }
}
```

---

### 5. Ineffective Recursion 📈

**Sorgu:** [IneffectiveRecursion.ql](.codeql/queries/IneffectiveRecursion.ql)

```java
// ❌ KÖTÜ - Exponential complexity
public int fibonacci(int n) {
    if (n <= 1) return n;
    return fibonacci(n-1) + fibonacci(n-2);
}
```

**Metrikler:**

| n | Recursive Calls | Tahmini Süre |
|---|-----------------|--------------|
| 10 | 177 | < 1ms |
| 20 | 21,891 | 10ms |
| 30 | 2,692,537 | 1 saniye |
| 40 | 331,160,281 | 2+ dakika |

**Complexity:** O(2^n)

**Çözüm 1: Memoization**
```java
// ✅ İYİ - O(n) with memoization
private Map<Integer, Integer> cache = new HashMap<>();

public int fibonacciMemo(int n) {
    if (n <= 1) return n;
    if (cache.containsKey(n)) return cache.get(n);

    int result = fibonacciMemo(n-1) + fibonacciMemo(n-2);
    cache.put(n, result);
    return result;
}
```

**Çözüm 2: Iterative**
```java
// ✅ DAHA İYİ - O(n), O(1) space
public int fibonacciIterative(int n) {
    if (n <= 1) return n;
    int a = 0, b = 1;
    for (int i = 2; i <= n; i++) {
        int temp = a + b;
        a = b;
        b = temp;
    }
    return b;
}
```

**Performans Karşılaştırma (n=40):**
- Recursive: ~2 dakika
- Memoization: < 1ms
- Iterative: < 1ms

**Kazanç:** ~120,000x daha hızlı!

---

## 📊 Performans Metrikleri Özeti

### Tespit Edilen Sorunlar (PerformanceMetrics.java)

| # | Sorun | Konum | Complexity | Tahmini Etki |
|---|-------|-------|------------|--------------|
| 1 | Triple nested loop | Line 16-23 | O(n³) | 🔴 Kritik |
| 2 | I/O in loop | Line 28-36 | O(n*IO) | 🔴 Yüksek |
| 3 | Sleep in loop | Line 42-52 | O(n*time) | 🟠 Orta |
| 4 | Memory allocation loop | Line 56-62 | O(n*mem) | 🔴 Yüksek |
| 5 | Fibonacci without memo | Line 65-69 | O(2^n) | 🔴 Kritik |
| 6 | Thread creation in loop | Line 73-78 | O(n*thread) | 🔴 Yüksek |
| 7 | Heavy synchronized | Line 82-90 | Lock contention | 🟠 Orta |
| 8 | N+1 Query | Line 94-101 | O(n) queries | 🔴 Yüksek |
| 9 | Reflection in loop | Line 105-111 | O(n*reflection) | 🟠 Orta |
| 10 | Regex compilation loop | Line 115-122 | O(n*compile) | 🟠 Orta |
| 11 | Busy waiting | Line 167-172 | CPU waste | 🔴 Kritik |
| 12 | LinkedList random access | Line 176-184 | O(n²) | 🟠 Orta |
| 13 | Boxing in loop | Line 188-197 | GC pressure | 🟡 Düşük |

---

## 🎯 CodeQL Sorgularının Verdiği Metrikler

### 1. HeavyRunnableDetection.ql
**Çıktı Örneği:**
```
Bu Runnable ağır işlem içeriyor:
- nested loops (depth=3)
- I/O işlemleri
- blocking işlemler
- loop içinde method çağrıları
```

### 2. NestedLoopComplexity.ql
**Çıktı Örneği:**
```
PERFORMANS UYARISI: 3 seviye iç içe loop tespit edildi.
Algoritma karmaşıklığı: O(n³).
Büyük iterasyon aralığı tespit edildi.
Loop içinde memory allocation var!
→ Algoritma optimizasyonu gerekli.
```

### 3. ExpensiveOperationsInLoop.ql
**Çıktı Örneği:**
```
PERFORMANS: Loop içinde Reflection tespit edildi.
Bu işlem loop dışına alınmalı veya cache'lenmelidir.
```

```
PERFORMANS: Loop içinde Regex compilation tespit edildi.
Bu işlem loop dışına alınmalı veya cache'lenmelidir.
```

```
PERFORMANS: Loop içinde Veritabanı sorgusu tespit edildi.
Bu işlem loop dışına alınmalı veya cache'lenmelidir.
```

### 4. SynchronizedHeavyOperation.ql
**Çıktı Örneği:**
```
PERFORMANS UYARISI: Synchronized method/block içinde
blocking I/O veya sleep çağrısı var.
Lock süresi minimize edilmeli.
İşlemi lock dışına alın veya finer-grained locking kullanın.
```

### 5. IneffectiveRecursion.ql
**Çıktı Örneği:**
```
PERFORMANS: Recursive method memoization kullanmıyor ve
2 recursive çağrı yapıyor.
Bu exponential time complexity (O(2^n)) anlamına gelir.
Memoization ekleyin veya iterative versiyona çevirin.
İkili recursive çağrı tespit edildi (örn: fibonacci pattern).
```

---

## 🚀 GitHub Actions ile Çalıştırma

Workflow dosyası zaten [.github/workflows/codeql-analysis.yml](.github/workflows/codeql-analysis.yml) içinde.

Push sonrası otomatik olarak:
1. Proje derlenir
2. CodeQL veritabanı oluşturulur
3. **Tüm özel performans sorguları** çalıştırılır
4. Sonuçlar **Security → Code scanning** tab'inde görüntülenir

---

## 📈 Performans İyileştirme Önceliği

### 🔴 Kritik (Hemen Düzelt)
1. ✅ O(n³) nested loops → Algoritma optimizasyonu
2. ✅ O(2^n) recursion → Memoization ekle
3. ✅ I/O in loop → Loop dışına al
4. ✅ N+1 queries → Batch query kullan
5. ✅ Busy waiting → wait/notify kullan

### 🟠 Yüksek (Bir Sonraki Sprint)
6. ✅ Thread creation in loop → Thread pool kullan
7. ✅ Reflection in loop → Cache method references
8. ✅ Regex in loop → Pattern compile once
9. ✅ Synchronized heavy ops → Lock scope minimize et

### 🟡 Orta (Backlog)
10. ✅ LinkedList random access → ArrayList kullan
11. ✅ Boxing in loop → Primitive types
12. ✅ Sleep in loop → Async pattern

---

## 🛠️ Lokal Test

```bash
# Projeyi derle
mvn clean compile

# CodeQL database oluştur (lokal kurulumda)
codeql database create java-db --language=java --command="mvn compile"

# Performans sorgularını çalıştır
codeql database analyze java-db .codeql/queries/ \
  --format=sarif-latest \
  --output=performance-results.sarif

# Sonuçları görüntüle
code performance-results.sarif
```

---

## 📚 Kaynaklar

- **CodeQL Performance Queries:** [.codeql/queries/](.codeql/queries/)
- **Örnek Kod:** [PerformanceMetrics.java](src/main/java/com/example/analysis/PerformanceMetrics.java)
- **GitHub Repo:** https://github.com/selcukaltinay/CodeQL4Performance

---

**Son Güncelleme:** 2025-10-16
**Durum:** ✅ 5 özel performans sorgusu aktif
