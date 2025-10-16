package com.example.analysis;

import java.util.*;
import java.util.concurrent.*;
import java.io.*;

/**
 * Performans metriklerini test etmek için örnek kodlar
 * CodeQL ile tespit edilecek performans sorunları
 */
public class PerformanceMetrics {

    // PERFORMANS SORUNU 1: Uzun süren Runnable - Nested loops
    public Runnable heavyTask1 = new Runnable() {
        @Override
        public void run() {
            // O(n³) complexity - ÇOK KÖTÜ!
            for (int i = 0; i < 1000; i++) {
                for (int j = 0; j < 1000; j++) {
                    for (int k = 0; k < 1000; k++) {
                        int result = i * j * k; // 1 milyar iterasyon!
                    }
                }
            }
        }
    };

    // PERFORMANS SORUNU 2: Runnable içinde I/O işlemi
    public Runnable ioHeavyTask = () -> {
        try {
            // Her çalıştığında dosya okuyor!
            for (int i = 0; i < 100; i++) {
                BufferedReader reader = new BufferedReader(new FileReader("/tmp/data.txt"));
                String line = reader.readLine();
                // Stream kapatılmıyor + loop içinde I/O
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    };

    // PERFORMANS SORUNU 3: Runnable içinde senkron veritabanı çağrısı
    public Runnable databaseHeavyTask = new Runnable() {
        @Override
        public void run() {
            // Loop içinde veritabanı sorgusu
            for (int i = 0; i < 100; i++) {
                try {
                    Thread.sleep(50); // DB çağrısını simüle ediyor
                    // Gerçek kodda: executeQuery("SELECT * FROM large_table WHERE id = " + i);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    };

    // PERFORMANS SORUNU 4: Runnable içinde memory-intensive işlem
    public Runnable memoryHeavyTask = () -> {
        List<byte[]> memoryWaste = new ArrayList<>();
        for (int i = 0; i < 1000; i++) {
            // Her iterasyonda 1MB allocation - Toplam 1GB!
            memoryWaste.add(new byte[1024 * 1024]);
        }
        // memoryWaste kullanılmıyor ve clear edilmiyor!
    };

    // PERFORMANS SORUNU 5: Recursive method with no memoization
    public int fibonacci(int n) {
        if (n <= 1) return n;
        // O(2^n) complexity - n=40 için 1+ milyar çağrı
        return fibonacci(n - 1) + fibonacci(n - 2);
    }

    // PERFORMANS SORUNU 6: Thread pool olmadan her seferinde yeni thread
    public void processItems(List<String> items) {
        for (String item : items) {
            // Her item için yeni thread - Thread creation overhead
            new Thread(() -> {
                processItem(item);
            }).start();
        }
    }

    // PERFORMANS SORUNU 7: Synchronized method içinde ağır işlem
    public synchronized void heavySynchronizedMethod() {
        // Lock tutarken ağır işlem - Diğer thread'ler bekliyor
        for (int i = 0; i < 1000000; i++) {
            Math.pow(i, 2);
        }
        try {
            Thread.sleep(1000); // 1 saniye lock tutulur!
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    // PERFORMANS SORUNU 8: N+1 Query problemi simülasyonu
    public void loadUsersWithOrders() {
        List<Integer> userIds = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

        // İlk sorgu: Kullanıcıları getir
        for (Integer userId : userIds) {
            // Her kullanıcı için ayrı sorgu - N+1 problem!
            List<String> orders = getOrdersForUser(userId);
            // Tek sorguda tümü getirilmeli: SELECT * FROM orders WHERE user_id IN (...)
        }
    }

    // PERFORMANS SORUNU 9: Reflection kullanımı loop içinde
    public void reflectionInLoop(List<Object> objects) throws Exception {
        for (Object obj : objects) {
            // Her iterasyonda reflection - Çok yavaş!
            Class<?> clazz = obj.getClass();
            java.lang.reflect.Method method = clazz.getMethod("toString");
            method.invoke(obj);
        }
    }

    // PERFORMANS SORUNU 10: Regular expression compilation in loop
    public List<String> filterEmails(List<String> inputs) {
        List<String> emails = new ArrayList<>();
        for (String input : inputs) {
            // Her iterasyonda regex compile ediliyor!
            if (input.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
                emails.add(input);
            }
        }
        return emails;
    }

    // İYİ ÖRNEK: Thread pool kullanımı
    private ExecutorService executorService = Executors.newFixedThreadPool(10);

    public void processItemsEfficiently(List<String> items) {
        for (String item : items) {
            executorService.submit(() -> processItem(item));
        }
    }

    // İYİ ÖRNEK: Memoization ile fibonacci
    private Map<Integer, Integer> fibCache = new HashMap<>();

    public int fibonacciMemoized(int n) {
        if (n <= 1) return n;
        if (fibCache.containsKey(n)) return fibCache.get(n);

        int result = fibonacciMemoized(n - 1) + fibonacciMemoized(n - 2);
        fibCache.put(n, result);
        return result;
    }

    // İYİ ÖRNEK: Compiled pattern
    private static final java.util.regex.Pattern EMAIL_PATTERN =
        java.util.regex.Pattern.compile("^[A-Za-z0-9+_.-]+@(.+)$");

    public List<String> filterEmailsEfficiently(List<String> inputs) {
        List<String> emails = new ArrayList<>();
        for (String input : inputs) {
            if (EMAIL_PATTERN.matcher(input).matches()) {
                emails.add(input);
            }
        }
        return emails;
    }

    // PERFORMANS SORUNU 11: Busy waiting
    public void waitForCondition() {
        boolean ready = false;
        // CPU'yu boşa harcıyor - wait/notify veya CountDownLatch kullan
        while (!ready) {
            // Busy waiting - CPU %100
        }
    }

    // PERFORMANS SORUNU 12: ArrayList yerine LinkedList (random access için)
    public void inefficientListAccess() {
        LinkedList<Integer> list = new LinkedList<>();
        for (int i = 0; i < 10000; i++) {
            list.add(i);
        }

        // LinkedList'te get(i) → O(n), ArrayList'te O(1)
        for (int i = 0; i < list.size(); i++) {
            Integer value = list.get(i); // Her erişim O(n) - Toplam O(n²)
        }
    }

    // PERFORMANS SORUNU 13: Unnecessary autoboxing in tight loop
    public long sumWithBoxing() {
        List<Integer> numbers = new ArrayList<>();
        for (int i = 0; i < 1000000; i++) {
            numbers.add(i); // Autoboxing - 1M Integer nesnesi
        }

        Integer sum = 0; // Wrapper
        for (Integer num : numbers) {
            sum += num; // Boxing/unboxing
        }
        return sum;
    }

    // Helper methods
    private void processItem(String item) {
        try {
            Thread.sleep(100);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    private List<String> getOrdersForUser(Integer userId) {
        // DB çağrısı simülasyonu
        return Arrays.asList("Order1", "Order2");
    }

    public static void main(String[] args) throws Exception {
        PerformanceMetrics pm = new PerformanceMetrics();

        System.out.println("=== Kötü Örnekler ===");

        // Uyarı: Bu çok yavaş!
        long start = System.currentTimeMillis();
        // pm.heavyTask1.run(); // Bu çalıştırılırsa ~1 milyar iterasyon
        System.out.println("Heavy task (skipped) would take: ~minutes");

        // Fibonacci karşılaştırma
        start = System.currentTimeMillis();
        int result1 = pm.fibonacci(30); // Yavaş
        long time1 = System.currentTimeMillis() - start;

        start = System.currentTimeMillis();
        int result2 = pm.fibonacciMemoized(30); // Hızlı
        long time2 = System.currentTimeMillis() - start;

        System.out.println("Fibonacci(30) without memoization: " + time1 + "ms");
        System.out.println("Fibonacci(30) with memoization: " + time2 + "ms");
        System.out.println("Speedup: " + (time1 / (time2 + 1)) + "x");
    }
}
