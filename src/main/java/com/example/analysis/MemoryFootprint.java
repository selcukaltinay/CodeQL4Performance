package com.example.analysis;

import java.util.*;
import java.util.concurrent.*;
import java.util.stream.*;
import java.io.*;
import java.nio.ByteBuffer;

/**
 * Memory footprint ve ağır işlem analizi için örnekler
 * CodeQL ile tespit edilecek memory ve CPU sorunları
 */
public class MemoryFootprint {

    // MEMORY SORUNU 1: Büyük koleksiyon - unbounded growth
    private static List<byte[]> dataCache = new ArrayList<>();

    public void cacheData(byte[] data) {
        // Hiç temizlenmeyen cache - Memory leak!
        dataCache.add(data);
        // 1000 çağrıda 1MB * 1000 = 1GB memory!
    }

    // MEMORY SORUNU 2: String interning abuse
    public void processUserInput(String input) {
        // Her input için yeni String intern - PermGen/Metaspace dolması
        String interned = input.intern();
        // 1M farklı string = PermGen overflow
    }

    // MEMORY SORUNU 3: Large array allocation in loop
    public void processImages(int count) {
        List<BufferedImage> images = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            // Her iterasyonda büyük array allocation
            byte[] imageData = new byte[10 * 1024 * 1024]; // 10MB
            images.add(createImage(imageData));
            // 100 resim = 1GB heap usage
        }
        // images.clear() çağrılmıyor!
    }

    // MEMORY SORUNU 4: Deep object graph - recursive references
    private Map<String, Object> complexData = new HashMap<>();

    public Map<String, Object> buildComplexStructure(int depth) {
        if (depth > 0) {
            Map<String, Object> nested = new HashMap<>();
            nested.put("data", new byte[1024 * 1024]); // 1MB
            nested.put("child", buildComplexStructure(depth - 1));
            complexData.put("level_" + depth, nested);
        }
        return complexData;
        // Depth 100 = 100MB sadece bu structureda
    }

    // CPU SORUNU 1: Complex mathematical computation
    public double heavyMathOperation(double[] data) {
        double result = 0;
        // O(n²) matematik işlemi
        for (int i = 0; i < data.length; i++) {
            for (int j = 0; j < data.length; j++) {
                // Pahalı matematiksel işlemler
                result += Math.pow(Math.sin(data[i]), 2) *
                         Math.pow(Math.cos(data[j]), 2) *
                         Math.sqrt(Math.abs(data[i] - data[j]));
            }
        }
        return result;
    }

    // CPU SORUNU 2: Cryptographic operations without caching
    public String hashPassword(String password) throws Exception {
        // Her çağrıda yeni MessageDigest instance
        java.security.MessageDigest md =
            java.security.MessageDigest.getInstance("SHA-256");

        // Iterative hashing - CPU intensive
        byte[] hash = password.getBytes();
        for (int i = 0; i < 10000; i++) {  // PBKDF2 benzeri
            hash = md.digest(hash);
        }
        return Base64.getEncoder().encodeToString(hash);
    }

    // MEMORY SORUNU 5: Stream not closed causing file descriptor leak
    public String readLargeFile(String path) throws IOException {
        StringBuilder content = new StringBuilder();
        BufferedReader reader = new BufferedReader(
            new FileReader(path));

        String line;
        while ((line = reader.readLine()) != null) {
            content.append(line);
        }
        // reader.close() yok! - File descriptor leak
        return content.toString();
    }

    // CPU SORUNU 3: Serialization/Deserialization in hot path
    public byte[] serializeObject(Object obj) throws IOException {
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        ObjectOutputStream oos = new ObjectOutputStream(bos);
        oos.writeObject(obj); // CPU intensive
        oos.close();
        return bos.toByteArray();
    }

    // MEMORY SORUNU 6: Duplicate strings not using flyweight
    public List<String> loadUsernames(int count) {
        List<String> usernames = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            // Aynı string'i tekrar tekrar oluştur
            usernames.add(new String("admin")); // Her biri ayrı object!
        }
        // 1M kullanıcı için gereksiz memory
        return usernames;
    }

    // CPU SORUNU 4: XML/JSON parsing in loop
    public void processJsonDocuments(List<String> jsonStrings) {
        for (String json : jsonStrings) {
            // Her iterasyonda parser oluştur - Pahalı!
            // Gerçek kodda: Gson gson = new Gson();
            // Map<String, Object> data = gson.fromJson(json, Map.class);
            // Simülasyon için comment
            System.out.println("Processing: " + json);
            // Parser reuse edilmeli
        }
    }

    // MEMORY SORUNU 7: StringBuilder capacity not set
    public String buildLargeString(int size) {
        StringBuilder sb = new StringBuilder(); // Default: 16 chars
        for (int i = 0; i < size; i++) {
            sb.append("data"); // Sürekli resize - memory churn
        }
        // new StringBuilder(size * 4) kullanılmalı
        return sb.toString();
    }

    // CPU SORUNU 5: Regular expression backtracking
    public boolean validateComplexPattern(String input) {
        // Catastrophic backtracking riski - O(2^n)
        return input.matches("(a+)+b");
        // Input: "aaaaaaaaaaaaaaaaaaaaaaaac" = exponential time!
    }

    // MEMORY SORUNU 8: Autoboxing in array
    public void calculateStats(int count) {
        List<Integer> numbers = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            numbers.add(i); // Her biri Integer object - heap pollution
        }
        // Primitive int[] kullanılmalı - 4x daha az memory
    }

    // CPU SORUNU 6: Sort in hot loop
    public void processOrderedData(List<String>[] dataSets) {
        for (List<String> dataSet : dataSets) {
            // Her iterasyonda sort - O(n log n)
            Collections.sort(dataSet);
            String first = dataSet.get(0);
            // Sorting dışarı alınabilir veya min-heap kullanılabilir
        }
    }

    // MEMORY SORUNU 9: ThreadLocal not removed
    private static ThreadLocal<byte[]> threadLocalBuffer = ThreadLocal.withInitial(() ->
        new byte[1024 * 1024]); // 1MB per thread

    public void processWithBuffer(byte[] data) {
        byte[] buffer = threadLocalBuffer.get();
        // İşlem yap
        System.arraycopy(data, 0, buffer, 0, Math.min(data.length, buffer.length));
        // threadLocalBuffer.remove() yok! - Thread pool'da memory leak
    }

    // CPU SORUNU 7: Clone karmaşık object deep copy
    public Object deepClone(Object obj) throws Exception {
        // Serialization ile clone - ÇOK YAVAŞ
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        ObjectOutputStream oos = new ObjectOutputStream(bos);
        oos.writeObject(obj);
        oos.close();

        ByteArrayInputStream bis = new ByteArrayInputStream(bos.toByteArray());
        ObjectInputStream ois = new ObjectInputStream(bis);
        return ois.readObject();
    }

    // MEMORY SORUNU 10: HashMap default size
    public Map<String, String> loadLargeDataset(int expectedSize) {
        // Default capacity: 16 - Sürekli resize
        Map<String, String> map = new HashMap<>();
        for (int i = 0; i < expectedSize; i++) {
            map.put("key_" + i, "value_" + i);
            // Her resize'da rehash - CPU + memory churn
        }
        // new HashMap<>(expectedSize) kullan
        return map;
    }

    // CPU SORUNU 8: Date formatting in loop
    public List<String> formatDates(List<Date> dates) {
        List<String> formatted = new ArrayList<>();
        for (Date date : dates) {
            // SimpleDateFormat her iterasyonda - Thread-unsafe + yavaş
            java.text.SimpleDateFormat sdf =
                new java.text.SimpleDateFormat("yyyy-MM-dd");
            formatted.add(sdf.format(date));
        }
        // DateTimeFormatter reuse edilmeli (thread-safe)
        return formatted;
    }

    // MEMORY SORUNU 11: Cached regex patterns not static
    public boolean matchesEmail(String input) {
        // Her çağrıda compile - Memory waste
        java.util.regex.Pattern pattern =
            java.util.regex.Pattern.compile("^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,6}$");
        return pattern.matcher(input).matches();
        // static final Pattern kullan
    }

    // CPU SORUNU 9: Stream operations creating intermediate collections
    public List<Integer> processNumbers(List<Integer> numbers) {
        return numbers.stream()
            .map(n -> n * 2)
            .filter(n -> n > 100)
            .sorted()  // Full sort - O(n log n)
            .limit(10) // Sadece 10 tane - sort gereksiz!
            .collect(Collectors.toList());
        // limit önce yapılmalı veya heap kullanılmalı
    }

    // MEMORY SORUNU 12: Substrings holding reference to original
    private List<String> cachedTokens = new ArrayList<>();

    public void tokenizeAndCache(String largeText) {
        String[] tokens = largeText.split(" ");
        for (String token : tokens) {
            // Java 6/7'de substring tüm string'i tutar
            cachedTokens.add(token.substring(0, Math.min(10, token.length())));
        }
        // new String(token.substring(...)) kullan
    }

    // CPU SORUNU 10: Exception for control flow
    public Integer parseIntSafe(String value) {
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            // Exception throwing pahalı - Stack trace generation
            return null;
        }
        // Regex pre-validation yapılmalı
    }

    // İYİ ÖRNEK: Object pooling
    private static final Queue<ByteBuffer> byteBufferPool = new LinkedBlockingQueue<>();

    static {
        for (int i = 0; i < 10; i++) {
            byteBufferPool.offer(ByteBuffer.allocateDirect(1024 * 1024));
        }
    }

    public void processWithPooledBuffer(byte[] data) {
        ByteBuffer buffer = byteBufferPool.poll();
        if (buffer != null) {
            try {
                buffer.clear();
                buffer.put(data);
                // Process
            } finally {
                byteBufferPool.offer(buffer); // Return to pool
            }
        }
    }

    // İYİ ÖRNEK: Lazy initialization
    private static class Holder {
        static final ExpensiveResource INSTANCE = new ExpensiveResource();
    }

    public static ExpensiveResource getInstance() {
        return Holder.INSTANCE; // Thread-safe, efficient
    }

    // Helper classes
    static class BufferedImage {
        byte[] data;
        BufferedImage(byte[] data) { this.data = data; }
    }

    static class ExpensiveResource {
        ExpensiveResource() { /* Heavy initialization */ }
    }

    private BufferedImage createImage(byte[] data) {
        return new BufferedImage(data);
    }

    public static void main(String[] args) throws Exception {
        MemoryFootprint mf = new MemoryFootprint();

        System.out.println("=== Memory Footprint Analizi ===");

        // Memory kullanımı ölç
        Runtime runtime = Runtime.getRuntime();
        long memBefore = runtime.totalMemory() - runtime.freeMemory();

        // Kötü örnek: Large allocation
        mf.processImages(10); // 10 * 10MB = 100MB

        long memAfter = runtime.totalMemory() - runtime.freeMemory();
        System.out.println("Memory kullanımı: " +
            (memAfter - memBefore) / (1024 * 1024) + " MB");

        // CPU testi
        long start = System.currentTimeMillis();
        double[] data = new double[1000];
        for (int i = 0; i < 1000; i++) data[i] = i;

        double result = mf.heavyMathOperation(data);
        long time = System.currentTimeMillis() - start;

        System.out.println("Heavy math operation: " + time + "ms");
    }
}
