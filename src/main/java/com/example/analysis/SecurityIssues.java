package com.example.analysis;

import java.sql.*;
import java.io.*;
import java.util.*;

/**
 * Bu sınıf CodeQL'in tespit edebileceği güvenlik ve performans sorunları içerir
 */
public class SecurityIssues {

    // GÜVENLIK SORUNU 1: SQL Injection
    public List<String> getUserData(Connection conn, String userId) throws SQLException {
        List<String> results = new ArrayList<>();

        // SORUN: Kullanıcı girdisi doğrudan SQL'e ekleniyor
        String query = "SELECT * FROM users WHERE id = '" + userId + "'";
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery(query);

        while (rs.next()) {
            results.add(rs.getString("name"));
        }
        return results;
    }

    // GÜVENLIK SORUNU 2: Path Traversal
    public String readUserFile(String filename) throws IOException {
        // SORUN: Kullanıcı girdisi doğrudan dosya yolunda kullanılıyor
        File file = new File("/var/data/" + filename);
        BufferedReader reader = new BufferedReader(new FileReader(file));
        return reader.readLine();
    }

    // PERFORMANS SORUNU 1: Inefficient String Concatenation
    public String buildLargeString(int count) {
        String result = "";
        for (int i = 0; i < count; i++) {
            result = result + i + ",";  // Her iterasyonda yeni String nesnesi
        }
        return result;
    }

    // PERFORMANS SORUNU 2: Unnecessary Boxing in Loop
    public long calculateSum(int max) {
        Long sum = 0L;  // Wrapper sınıfı kullanımı
        for (int i = 0; i < max; i++) {
            sum = sum + i;  // Her iterasyonda boxing/unboxing
        }
        return sum;
    }

    // GÜVENLIK SORUNU 3: Hardcoded Credentials
    private static final String PASSWORD = "admin123";
    private static final String API_KEY = "sk-1234567890abcdef";

    public boolean authenticate(String username, String password) {
        return PASSWORD.equals(password);
    }

    // PERFORMANS SORUNU 3: Inefficient Collection Search
    public boolean findUser(List<String> users, String target) {
        // SORUN: List'te linear search yerine Set kullanılmalı
        for (String user : users) {
            if (user.equals(target)) {
                return true;
            }
        }
        return false;
    }

    // GÜVENLIK SORUNU 4: Weak Random Number Generator
    public int generateSecureToken() {
        Random random = new Random();  // SORUN: SecureRandom kullanılmalı
        return random.nextInt();
    }

    // PERFORMANS SORUNU 4: Resource Leak
    public String readFile(String path) throws IOException {
        FileInputStream fis = new FileInputStream(path);
        BufferedReader reader = new BufferedReader(new InputStreamReader(fis));
        // SORUN: Stream kapatılmıyor - try-with-resources kullanılmalı
        return reader.readLine();
    }

    // GÜVENLIK SORUNU 5: Command Injection
    public void executeCommand(String userInput) throws IOException {
        // SORUN: Kullanıcı girdisi doğrudan komutta kullanılıyor
        Runtime.getRuntime().exec("ping " + userInput);
    }

    // PERFORMANS SORUNU 5: Inefficient Exception Handling
    public int parseInteger(String value) {
        try {
            return Integer.parseInt(value);
        } catch (Exception e) {
            // SORUN: Genel Exception yakalama ve boş işlem
            return 0;
        }
    }

    // GÜVENLIK SORUNU 6: Insecure Deserialization
    public Object deserializeObject(byte[] data) throws Exception {
        ByteArrayInputStream bis = new ByteArrayInputStream(data);
        ObjectInputStream ois = new ObjectInputStream(bis);
        // SORUN: Güvenilmeyen kaynaktan deserialize
        return ois.readObject();
    }

    // PERFORMANS SORUNU 6: Synchronization on String
    private String lock = "mylock";

    public void synchronizedMethod() {
        synchronized (lock) {  // SORUN: String üzerinde synchronization
            // kritik bölge
        }
    }

    // GÜVENLIK SORUNU 7: Information Exposure
    public void logError(Exception e, String username, String password) {
        System.out.println("Error for user: " + username);
        System.out.println("Password: " + password);  // SORUN: Şifre loglanıyor
        e.printStackTrace();
    }

    public static void main(String[] args) throws Exception {
        SecurityIssues demo = new SecurityIssues();

        // Test kodları
        System.out.println(demo.buildLargeString(100));
        System.out.println(demo.calculateSum(1000));
    }
}
